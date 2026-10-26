#!/usr/bin/env node
// Simulador do Baru: percorre o build web do app como uma pessoa faria,
// tela a tela, e guarda capturas, sequências de quadros e o console.
//
// O relógio da página é controlado (Playwright `page.clock`, pausado depois
// de cada carga): o tempo do app só anda quando o script manda. Assim as sequências de quadros mostram o
// estado da animação em instantes exatos (ex.: a cada 100 ms), sem depender
// da velocidade de renderização da máquina — num Chromium headless com WebGL
// por software a home roda a ~10 quadros/s em DPR 2, o que tornaria qualquer
// captura em tempo real enganosa.
//
// Uso: ver README.md ao lado.
'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');
const { chromium } = require('playwright');

// ---------------------------------------------------------------- opções
function opcoes(argv) {
  const o = {
    url: 'http://127.0.0.1:8765/index.html',
    saida: path.resolve('simulador-saida'),
    largura: 412, altura: 892, dpr: 2,
    etapas: null, // null = todas
    perfil: null, // pasta do perfil do navegador; null = nova e vazia
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i], v = argv[i + 1];
    if (a === '--url') { o.url = v; i++; }
    else if (a === '--saida') { o.saida = path.resolve(v); i++; }
    else if (a === '--largura') { o.largura = +v; i++; }
    else if (a === '--altura') { o.altura = +v; i++; }
    else if (a === '--dpr') { o.dpr = +v; i++; }
    else if (a === '--etapas') { o.etapas = v.split(','); i++; }
    else if (a === '--perfil') { o.perfil = path.resolve(v); i++; }
  }
  return o;
}

// ---------------------------------------------------------------- sessão
class Sim {
  constructor(o) {
    this.o = o;
    this.n = 0; // contador de capturas
    this.diario = [];
    this.console = [];
    fs.mkdirSync(o.saida, { recursive: true });
    fs.mkdirSync(path.join(o.saida, 'quadros'), { recursive: true });
    fs.writeFileSync(path.join(o.saida, 'jornada.log'), '');
  }

  async abre({ limpa = true } = {}) {
    const perfil = this.o.perfil || fs.mkdtempSync(path.join(os.tmpdir(), 'baru-sim-'));
    if (limpa && this.o.perfil) fs.rmSync(perfil, { recursive: true, force: true });
    this.perfil = perfil;
    this.ctx = await chromium.launchPersistentContext(perfil, {
      viewport: { width: this.o.largura, height: this.o.altura },
      deviceScaleFactor: this.o.dpr,
    });
    this.page = this.ctx.pages()[0] || await this.ctx.newPage();
    this.page.on('console', m => {
      const t = m.text();
      if (/GPU stall|WebGL|GroupMarkerNotSet|service worker|script> tag/i.test(t)) return;
      this.console.push(`[${this.etapa || '-'}] ${m.type()}: ${t}`);
    });
    // Os sons são arquivos .wav: cada pedido mostra que o app tentou tocar um.
    this.page.on('request', r => { if (/\.(wav|mp3|ogg)(\?|$)/.test(r.url())) this.anota('som pedido: ' + r.url().split('/').pop()); });
    this.page.on('pageerror', e => this.console.push(`[${this.etapa || '-'}] pageerror: ${e.message}`));
    await this.page.clock.install();
    await this.carrega();
  }

  // Carrega (ou recarrega) a página e espera o Flutter desenhar.
  async carrega(url = this.o.url) {
    await this.page.goto(url);
    await this.pausa();
    await this.espera(6500, 100);
    await this.ligaSemantica();
  }

  async recarrega() {
    await this.page.reload();
    await this.pausa();
    await this.espera(6500, 100);
    await this.ligaSemantica();
  }

  // Congela o relógio da página: daqui em diante o tempo do app só anda
  // pelo `espera`/`quadros`. Sem isto o relógio falso também corre com o
  // tempo real, e uma captura lenta "come" segundos da sessão.
  async pausa() {
    const agora = await this.page.evaluate(() => Date.now());
    await this.page.clock.pauseAt(agora + 20);
  }

  async ligaSemantica() {
    const ph = await this.page.$('flt-semantics-placeholder');
    if (ph) { await ph.dispatchEvent('click'); await this.espera(600); }
  }

  // Faz o relógio do app andar `ms`, em fatias, dando tempo real à pintura.
  // `fastForward` salta o tempo e dispara cada timer (e o próximo quadro) no
  // máximo uma vez por fatia: o app desenha um quadro por fatia, não todos.
  async espera(ms, fatia = 100) {
    let feito = 0;
    while (feito < ms) {
      const d = Math.min(fatia, ms - feito);
      await this.page.clock.fastForward(d);
      await this.page.waitForTimeout(25);
      feito += d;
    }
    await this.page.waitForTimeout(80);
  }

  // Lista os nós de semântica visíveis: "papel|rótulo|x,y wxh".
  async nos() {
    return this.page.$$eval('flt-semantics-host flt-semantics', els => {
      const out = [];
      for (const e of els) {
        const r = e.getBoundingClientRect(); if (r.width === 0 || r.height === 0) continue;
        const role = e.getAttribute('role') || '';
        let t = (e.getAttribute('aria-label') || '').trim();
        if (!t) t = [...e.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent).join('').trim();
        if (!t) { const sp = e.querySelector(':scope > span'); if (sp) t = sp.textContent.trim(); }
        const inp = e.querySelector(':scope > input, :scope > textarea');
        if (!t && !role && !inp) continue;
        out.push(`${role || '-'}${inp ? '[campo]' : ''}|${t.replace(/\s*\n\s*/g, ' / ').slice(0, 140)}|${Math.round(r.x)},${Math.round(r.y)} ${Math.round(r.width)}x${Math.round(r.height)}`);
      }
      return out;
    });
  }

  // Acha o nó cujo rótulo casa com `re`. Prefere o menor (mais específico)
  // e o que está dentro da tela.
  async acha(re, { idx = 0 } = {}) {
    const src = re instanceof RegExp ? re.source : String(re);
    const flags = re instanceof RegExp ? re.flags : 'i';
    const H = this.o.altura;
    const rs = await this.page.$$eval('flt-semantics-host flt-semantics', (els, [s, f, H]) => {
      const rx = new RegExp(s, f); const out = [];
      // Com a barra de abas na tela, o que fica atrás dela não é tocável.
      const barra = els.some(e => /^Habitat\s+Habitat$/.test((e.getAttribute('aria-label') || e.textContent || '').trim()));
      for (const e of els) {
        const r = e.getBoundingClientRect(); if (r.width === 0 || r.height === 0) continue;
        let t = (e.getAttribute('aria-label') || '').trim();
        if (!t) t = [...e.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent).join('').trim();
        if (!t) { const sp = e.querySelector(':scope > span'); if (sp) t = sp.textContent.trim(); }
        if (t && rx.test(t)) out.push({ x: r.x + r.width / 2, y: r.y + r.height / 2, t: t.slice(0, 80), a: r.width * r.height, fora: r.y + r.height / 2 < 0 || r.y + r.height / 2 > H || (r.y + r.height / 2 > H - (barra ? 95 : 100) && !/^(Habitat|Trilha|Missões|Ajustes)\s/.test(t) && r.y > H * 0.5 && r.height < 120) });
      }
      out.sort((a, b) => (a.fora - b.fora) || (a.a - b.a));
      return out;
    }, [src, flags, H]);
    return rs[Math.min(idx, rs.length - 1)] || null;
  }

  async tem(re) { return !!(await this.acha(re)); }

  // Rola até o nó aparecer inteiro na tela e devolve onde ele está.
  async mostra(re, { idx = 0, rola = true } = {}) {
    let alvo = await this.acha(re, { idx });
    // Listas do Flutter só constroem o que está perto da tela: procura rolando.
    for (let i = 0; !alvo && rola && i < 8; i++) { await this.rola(500); alvo = await this.acha(re, { idx }); }
    for (let i = 0; !alvo && rola && i < 12; i++) { await this.rola(-500); alvo = await this.acha(re, { idx }); }
    if (!alvo) throw new Error('não achei na tela: ' + re);
    for (let i = 0; alvo.fora && rola && i < 8; i++) {
      await this.rola(alvo.y > this.o.altura / 2 ? 400 : -400);
      alvo = await this.acha(re, { idx });
      if (!alvo) throw new Error('sumiu ao rolar: ' + re);
    }
    return alvo;
  }

  // Toca no nó. Se estiver fora da tela, rola até ele antes.
  async toca(re, { idx = 0, espera = 900, rola = true } = {}) {
    const alvo = await this.mostra(re, { idx, rola });
    await this.page.mouse.click(alvo.x, alvo.y);
    await this.espera(espera);
    this.anota(`tocou "${alvo.t.replace(/\n/g, ' / ')}"`);
    return alvo;
  }

  // Com a semântica ligada, um clique num nó de semântica vira a *ação* de
  // tocar desse nó (o que um leitor de tela faria), e não um toque de dedo
  // no desenho. Para gestos que dependem do ponto exato (cavar a toca,
  // arrastar), desliga temporariamente a captura de cliques pela semântica.
  async comDedo(fn) {
    await this.page.addStyleTag({ content: 'flt-semantics-host, flt-semantics-host * { pointer-events: none !important; }' }).catch(() => {});
    try { return await fn(); }
    finally {
      await this.page.evaluate(() => { for (const s of [...document.querySelectorAll('style')]) if (s.textContent.includes('flt-semantics-host, flt-semantics-host *')) s.remove(); }).catch(() => {});
    }
  }

  async tocaXY(x, y, espera = 900) {
    await this.page.mouse.click(x, y);
    await this.espera(espera);
    this.anota(`tocou em ${x},${y}`);
  }

  async rola(dy, x = this.o.largura / 2, y = this.o.altura / 2) {
    await this.page.mouse.move(x, y);
    await this.page.mouse.wheel(0, dy);
    await this.espera(500);
  }

  // Arrasta devagar de (x1,y1) a (x2,y2), em `passos`, com o relógio andando.
  async arrasta(x1, y1, x2, y2, passos = 12, msPorPasso = 40) {
    await this.page.mouse.move(x1, y1);
    await this.page.mouse.down();
    for (let i = 1; i <= passos; i++) {
      await this.page.mouse.move(x1 + (x2 - x1) * i / passos, y1 + (y2 - y1) * i / passos);
      await this.espera(msPorPasso, msPorPasso);
    }
    await this.page.mouse.up();
  }

  // O "voltar" do sistema na web é o voltar do navegador. Se ele sair do
  // app (histórico acabou), registra e volta para o app.
  async voltar(espera = 1200) {
    const antes = this.rota();
    await this.page.goBack().catch(() => {});
    if (!this.page.url().startsWith(this.o.url.split('#')[0])) {
      this.anota(`voltar do navegador em ${antes} SAIU DO APP (${this.page.url() || 'vazio'}); avançando de volta`);
      await this.page.goForward().catch(() => {});
      if (!this.page.url().startsWith(this.o.url.split('#')[0])) await this.page.goto(this.o.url);
      await this.pausa();
      await this.espera(6500, 100);
      await this.ligaSemantica();
      return;
    }
    await this.espera(espera);
    this.anota(`voltar do navegador ${antes} → ${this.rota()}`);
  }

  rota() { const u = this.page.url(); const i = u.indexOf('#'); return i < 0 ? '/' : u.slice(i + 1); }

  anota(s) {
    const l = `[${this.etapa || '-'}] ${s}`;
    this.diario.push(l);
    try { fs.appendFileSync(path.join(this.o.saida, 'jornada.log'), l + '\n'); } catch (_) {}
  }

  nome(n) { this.n++; return `${String(this.n).padStart(3, '0')}-${n}`; }

  // Captura a tela inteira.
  async foto(n, { completa = false } = {}) {
    const f = path.join(this.o.saida, this.nome(n) + '.png');
    await this.page.screenshot({ path: f, fullPage: completa });
    this.anota(`foto ${path.basename(f)} (rota ${this.rota()})`);
    try { const l = '    ' + (await this.nos()).join('\n    '); this.diario.push(l); fs.appendFileSync(path.join(this.o.saida, 'jornada.log'), l + '\n'); } catch (_) {}
    return f;
  }

  // Grava `total` quadros a cada `passo` ms do relógio do app e monta uma
  // tira. `acao` (opcional) dispara a animação logo antes do 1º quadro.
  async quadros(n, { total = 12, passo = 100, acao = null, recorte = null, colunas = 6, escala = 0.5 } = {}) {
    const dir = path.join(this.o.saida, 'quadros', this.nome(n));
    fs.mkdirSync(dir, { recursive: true });
    const lista = [];
    if (acao) await acao();
    for (let i = 0; i < total; i++) {
      const f = path.join(dir, `q${String(i).padStart(2, '0')}-${i * passo}ms.png`);
      await this.page.screenshot({ path: f, clip: recorte || undefined, scale: 'css' });
      lista.push(f);
      await this.page.clock.fastForward(passo);
      await this.page.waitForTimeout(90);
    }
    const tira = dir + '.png';
    monta(lista, tira, { colunas, escala, passo });
    this.anota(`quadros ${path.basename(tira)}: ${total} × ${passo} ms`);
    return { dir, tira, lista };
  }

  // Rola a tela inteira capturando cada página (para telas longas).
  async fotoRolando(n, { paginas = 6, dy = 600 } = {}) {
    const fs_ = [];
    for (let i = 0; i < paginas; i++) {
      fs_.push(await this.foto(`${n}-p${i}`));
      const antes = JSON.stringify(await this.nos());
      await this.rola(dy);
      if (JSON.stringify(await this.nos()) === antes) break;
    }
    await this.rola(-dy * paginas * 2);
    return fs_;
  }

  async etapaDe(nome, fn) {
    if (this.o.etapas && !this.o.etapas.includes(nome)) return;
    this.etapa = nome;
    const t0 = Date.now();
    try { await fn(); this.anota(`ok (${((Date.now() - t0) / 1000).toFixed(1)} s reais)`); }
    catch (e) {
      this.anota('FALHOU: ' + e.message);
      this.falhas = (this.falhas || []).concat(nome);
      try { await this.foto('falha-' + nome); this.anota((await this.nos()).join('\n    ')); } catch (_) {}
    }
  }

  async fecha() {
    fs.writeFileSync(path.join(this.o.saida, 'console.log'), this.console.join('\n') + '\n');
    await this.ctx.close();
  }
}

// Monta uma tira (grade) de quadros com o tempo de cada um, usando PIL.
function monta(lista, saida, { colunas = 6, escala = 0.5, passo = 100 } = {}) {
  const py = `
import sys, json
from PIL import Image, ImageDraw
fs, out, cols, esc, passo = json.loads(sys.argv[1])
ims = [Image.open(f).convert('RGB') for f in fs]
w, h = ims[0].size
tw, th = int(w*esc), int(h*esc)
rows = (len(ims)+cols-1)//cols
m = Image.new('RGB', (tw*cols, (th+16)*rows), 'white')
d = ImageDraw.Draw(m)
for i, im in enumerate(ims):
    x, y = (i%cols)*tw, (i//cols)*(th+16)
    m.paste(im.resize((tw, th)), (x, y+16))
    d.text((x+4, y+2), '%d ms' % (i*passo), fill=(200,0,0))
m.save(out, optimize=True)
`;
  try { execFileSync('python3', ['-c', py, JSON.stringify([lista, saida, colunas, escala, passo])]); }
  catch (e) { console.error('montagem falhou (python3 + PIL?):', e.message); }
}

module.exports = { Sim, opcoes, monta };

// ---------------------------------------------------------------- jornada
if (require.main === module) {
  const jornada = require('./jornada.js');
  (async () => {
    const sim = new Sim(opcoes(process.argv.slice(2)));
    await sim.abre();
    try { await jornada(sim); }
    finally { await sim.fecha(); }
    console.log('pronto:', sim.o.saida);
  })();
}

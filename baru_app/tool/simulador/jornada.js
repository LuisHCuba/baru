// A jornada que o simulador percorre. Cada etapa é independente: se uma
// falhar, a captura de falha e os nós da tela vão para o jornada.log e a
// próxima segue do ponto em que o app ficou.
'use strict';

// "Colher agora" é o botão da cena "Missão cumprida!".
const CENA_BOTAO = /^(Continuar|Ver no habitat|Colher agora)$/;
const TOCA = /Tem algo enterrado|Toque na terra/;

// Passa pelas cenas de conquista que estiverem na frente (raiz, crescimento,
// nível, marco da trilha, toca de cavar), fotografando cada uma e gravando
// quadros da saída de uma e da entrada da próxima.
async function passaCenas(sim, rotulo, max = 8) {
  const vistas = [];
  const W = sim.o.largura, H = sim.o.altura;
  for (let i = 0; i < max; i++) {
    // As cenas esperam a tela de resultado terminar a parte dela (~2 s):
    // espera até 5 s por uma cena antes de concluir que não há nenhuma.
    let nos = [];
    for (let t = 0; t < 10; t++) {
      await sim.espera(500);
      nos = await sim.nos();
      const temCena = nos.some(n => TOCA.test(n) || /^button\|Continuar\|/.test(n) || /^button\|Ver no habitat\|/.test(n) || /^button\|Colher agora\|/.test(n) || (/^button\|.+\|0,0 (\d+)x(\d+)$/.test(n) && +n.match(/(\d+)x(\d+)$/)[1] >= W - 2 && +n.match(/(\d+)x(\d+)$/)[2] >= H - 2));
      if (temCena) break;
    }
    // Toca das missões ("Tem algo enterrado aqui").
    if (nos.some(n => TOCA.test(n))) {
      await sim.foto(`${rotulo}-toca`);
      // O monte de terra fica abaixo do texto da toca, no centro.
      const c = { x: W / 2, y: H * 0.59 };
      await sim.quadros(`${rotulo}-toca-cavando`, {
        total: 24, passo: 100,
        acao: async () => sim.comDedo(async () => { for (let k = 0; k < 3; k++) { await sim.page.mouse.click(c.x, c.y); await sim.espera(250, 50); } }),
      });
      vistas.push('toca');
      continue;
    }
    // Celebração de conquista (nível, marco): um botão do tamanho da tela.
    // Fechada, é uma toca a cavar (sem botão nem dica); aberta, fecha no toque.
    const cel = nos.find(n => { const m = n.match(/^button\|(.+)\|0,0 (\d+)x(\d+)$/); return m && +m[2] >= W - 2 && +m[3] >= H - 2; });
    const b = await sim.acha(CENA_BOTAO);
    if (cel && !b) {
      const titulo = cel.split('|')[1];
      vistas.push(titulo);
      await sim.foto(`${rotulo}-celebracao${i}`);
      await sim.quadros(`${rotulo}-celebracao${i}-cavando`, {
        total: 30, passo: 100, colunas: 6,
        acao: async () => sim.comDedo(async () => { for (let k = 0; k < 3; k++) { await sim.page.mouse.click(W / 2, H / 2 + 40); await sim.espera(300, 50); } }),
      });
      await sim.foto(`${rotulo}-celebracao${i}-aberta`);
      await sim.quadros(`${rotulo}-celebracao${i}-fecha`, { total: 10, passo: 100, acao: async () => sim.page.mouse.click(W / 2, H * 0.2) });
      continue;
    }
    if (!b) break;
    const titulo = (nos.find(n => /^group\|.{4,}/.test(n)) || '').split('|')[1] || '?';
    vistas.push(titulo);
    await sim.foto(`${rotulo}-cena${i}`);
    await sim.quadros(`${rotulo}-cena${i}-sai`, { total: 18, passo: 100, acao: async () => sim.page.mouse.click(b.x, b.y) });
  }
  sim.anota(`cenas vistas: ${JSON.stringify(vistas)}`);
  return vistas;
}

// Onde está a cena do habitat na home: {x, y, w, h} em px CSS.
async function habitat(sim) {
  await sim.rola(-3000);
  const n = (await sim.nos()).find(l => { const m = l.match(/\|(-?\d+),(-?\d+) (\d+)x(\d+)$/); return l.startsWith('button') && m && +m[4] > 200 && +m[3] > 200; });
  if (!n) return { x: 20, y: 69, w: sim.o.largura - 40, h: 372 };
  const m = n.match(/\|(-?\d+),(-?\d+) (\d+)x(\d+)$/);
  return { x: +m[1], y: +m[2], w: +m[3], h: +m[4] };
}

// Carinho: arrasta devagar de um lado a outro sobre o bicho, gravando quadros
// durante o gesto (não só depois).
async function carinho(sim, cx, cy, rec, nome) {
  const dir = require('path').join(sim.o.saida, 'quadros', sim.nome(nome));
  require('fs').mkdirSync(dir, { recursive: true });
  const lista = [];
  await sim.page.mouse.move(cx - 40, cy - 10);
  await sim.page.mouse.down();
  for (let i = 0; i < 24; i++) {
    const fase = (i % 8) / 8;
    await sim.page.mouse.move(cx - 40 + 80 * (fase < 0.5 ? fase * 2 : 2 - fase * 2), cy - 10 + 4 * Math.sin(i));
    await sim.page.clock.fastForward(60);
    await sim.page.waitForTimeout(60);
    if (i % 2 === 0) { const f = require('path').join(dir, `q${String(i).padStart(2, '0')}-${i * 60}ms.png`); await sim.page.screenshot({ path: f, clip: rec, scale: 'css' }); lista.push(f); }
  }
  await sim.page.mouse.up();
  for (let i = 0; i < 6; i++) { await sim.page.clock.fastForward(150); await sim.page.waitForTimeout(80); const f = require('path').join(dir, `r${i}-solto-${(i + 1) * 150}ms.png`); await sim.page.screenshot({ path: f, clip: rec, scale: 'css' }); lista.push(f); }
  require('./simula.js').monta(lista, dir + '.png', { colunas: 6, escala: 0.6, passo: 120 });
  sim.anota(`carinho gravado: ${lista.length} quadros`);
}

async function irParaHome(sim) {
  if (await sim.tem(/^Pronto$/)) await sim.toca(/^Pronto$/, { espera: 800 });
  for (let i = 0; i < 4 && sim.rota() !== '/'; i++) {
    if (await sim.tem(/^Habitat\s/)) { await sim.toca(/^Habitat\s/, { espera: 1000 }); break; }
    await sim.voltar();
  }
  if (sim.rota() !== '/') { await sim.page.goto(sim.o.url.split('#')[0] + '#/'); await sim.espera(1500); }
}

async function escolheDuracao(sim, rx) {
  await sim.toca(rx, { espera: 500 });
}

// Começa uma sessão na home (já na duração escolhida).
async function comecaSessao(sim, rotulo) {
  await irParaHome(sim);
  const a = await sim.mostra(/^Começar foco$/);
  await sim.quadros(`${rotulo}-entra`, { total: 10, passo: 80, acao: async () => sim.page.mouse.click(a.x, a.y) });
}

async function concluiSessao(sim, rotulo, minutos) {
  // Relógio rápido do build: 1 "minuto" = 1 s.
  await sim.espera(minutos * 1000 - 3500, 250);
  await sim.foto(`${rotulo}-quase-fim`);
  await sim.quadros(`${rotulo}-fim-e-resultado`, { total: 48, passo: 125, colunas: 8, escala: 0.4 });
}

module.exports = async function jornada(sim) {
  const curta = !!process.env.SIM_CURTA; // só os trechos-chave (larguras menores)

  // ------------------------------------------------------------ onboarding
  await sim.etapaDe('onboarding', async () => {
    await sim.foto('onb-idioma');
    await sim.toca(/^English/, { espera: 700 });
    await sim.foto('onb-idioma-en');
    await sim.toca(/^Português/, { espera: 700 });
    await sim.quadros('onb-idioma-para-promessa', { total: 8, passo: 80, acao: async () => { const c = await sim.acha(/^Continuar$/); await sim.page.mouse.click(c.x, c.y); } });
    await sim.foto('onb-promessa');
    await sim.voltar();
    await sim.foto('onb-promessa-apos-voltar');
    if (await sim.tem(/^Continuar$/)) await sim.toca(/^Continuar$/);
    // A promessa trocou "Começar foco" por "Continuar".
    await sim.toca(/^Continuar$|^Começar foco$/);
    // quiz: 6 perguntas; escolher já avança. Responde o que estiver na tela
    // (o recarregar e o voltar podem mudar a pergunta atual).
    const escolhas = [/^Terra/, /^De manhã cedo/, /^Água quente/, /^Redes sociais/, /^Perto da natureza/, /^Mais foco/];
    const qualPergunta = async () => { const n = (await sim.nos()).find(x => /^-\|\d\/6\|/.test(x)); return n ? +n.split('|')[1].split('/')[0] : 0; };
    let fez = { voltarUma: false, recarregou: false, voltarNav: false, quadros: false };
    for (let passo = 0; passo < 16 && !(await sim.tem(/^Ver seu animal/)); passo++) {
      const k = await qualPergunta();
      if (!k) break;
      await sim.foto(`onb-quiz-${k}`);
      const e = escolhas[k - 1];
      if (k === 2 && !fez.quadros) {
        fez.quadros = true;
        const c = await sim.acha(e);
        await sim.quadros('onb-quiz-avanca', { total: 8, passo: 80, acao: async () => sim.page.mouse.click(c.x, c.y) });
        continue;
      }
      await sim.toca(e);
      if (k === 3 && !fez.voltarUma) { fez.voltarUma = true; await sim.toca(/^Voltar uma/); await sim.foto('onb-quiz-voltou-uma'); continue; }
      if (k === 3 && !fez.recarregou) { fez.recarregou = true; await sim.recarrega(); await sim.foto('onb-quiz-apos-recarregar'); continue; }
      if (k === 4 && !fez.voltarNav) { fez.voltarNav = true; await sim.voltar(); await sim.foto('onb-quiz-apos-voltar-navegador'); continue; }
    }
    await sim.foto('onb-quiz-fim');
    const ver = await sim.acha(/^Ver seu animal/);
    await sim.quadros('onb-revelacao-entra', { total: 16, passo: 100, acao: async () => sim.page.mouse.click(ver.x, ver.y) });
    await sim.foto('onb-revelacao');
    await sim.fotoRolando('onb-revelacao-rolada', { paginas: 3, dy: 500 });
    await sim.toca(/^Pinguim/);
    await sim.foto('onb-revelacao-toque-bloqueada');
    await sim.toca(/^Coruja/);
    await sim.foto('onb-revelacao-coruja');
    await sim.toca(/^Tartaruga/);
    await sim.foto('onb-revelacao-tartaruga');
    await sim.toca(/^Capivara/);
    await sim.toca(/^Fêmea/);
    await sim.toca(/^Pelagem 3/);
    const campo = await sim.page.$('flt-semantics-host input');
    if (campo) {
      await campo.click(); await sim.espera(300);
      await sim.page.keyboard.press('Control+A');
      await sim.page.keyboard.type('Pipoca de Milho Doce do Sítio', { delay: 20 }); // > 18 caracteres
      await sim.espera(400);
      await sim.foto('onb-nome-longo');
      await sim.page.keyboard.press('Control+A');
      await sim.page.keyboard.type('Pipoca', { delay: 20 });
      await sim.page.keyboard.press('Enter');
      await sim.espera(400);
    } else sim.anota('campo de nome não encontrado');
    await sim.foto('onb-revelacao-escolhida');
    await sim.toca(/^Prazer em conhecer/);
    await sim.foto('onb-meta');
    await sim.toca(/^6h/);
    await sim.foto('onb-meta-6h');
    await sim.toca(/^Usar esta meta/);
    await sim.foto('onb-permissao-1');
    await sim.toca(/^Agora não/);
    await sim.foto('onb-permissao-2');
    await sim.toca(/^Notificações/);
    await sim.foto('onb-permissao-2-pedida');
    const fim = await sim.acha(/^Concluir/);
    await sim.quadros('onb-entra-na-home', { total: 16, passo: 100, acao: async () => sim.page.mouse.click(fim.x, fim.y) });
    await passaCenas(sim, 'onb-fim');
    await sim.foto('home-primeira-vez');
  });
  if ((sim.falhas || []).includes('onboarding')) { sim.anota('onboarding falhou: jornada interrompida'); return; }

  // ------------------------------------------------------------ home
  await sim.etapaDe('home', async () => {
    await sim.fotoRolando('home', { paginas: 5, dy: 600 });
    // A cena do habitat é o maior botão do topo da home; o bicho fica a ~62%
    // da altura dela.
    const cena = await habitat(sim);
    const cx = cena.x + cena.w / 2, cy = cena.y + cena.h * 0.62;
    const rec = { x: Math.max(0, cena.x), y: Math.max(0, cena.y), width: Math.min(cena.w, sim.o.largura), height: cena.h };
    await sim.quadros('home-toque-no-bicho', { total: 14, passo: 80, recorte: rec, acao: async () => sim.page.mouse.click(cx, cy) });
    // carinho: arrastar devagar sobre o bicho, gravando durante
    await carinho(sim, cx, cy, rec, 'home-carinho');
    await sim.quadros('home-carinho-solta', { total: 12, passo: 100, recorte: rec });
    // chips de duração
    await escolheDuracao(sim, /^Livre\s/);
    await sim.foto('home-livre');
    await escolheDuracao(sim, /^90min\s/);
    await escolheDuracao(sim, /^25min\s/);
    // folhas, raiz, relatório, tempo, missões, loja — cada um com o voltar
    for (const [rx, nome] of [[/^\d+$/, 'folhas'], [/^Raiz de \d+ dia/, 'raiz'], [/relatório de hoje/, 'relatorio'], [/^\d+min de /, 'tempo'], [/^Missões\s+\d+\/\d+/, 'missoes-resumo'], [/^faltam \d+ folhas para/, 'loja']]) {
      try {
        await irParaHome(sim);
        await sim.toca(rx, { espera: 1100 });
        if (sim.rota() === '/') { sim.anota(`detalhe ${nome}: o toque não abriu outra tela`); await sim.foto(`detalhe-${nome}-nao-abriu`); continue; }
        await sim.fotoRolando(`detalhe-${nome}`, { paginas: 3, dy: 650 });
        await sim.voltar();
        await sim.foto(`detalhe-${nome}-apos-voltar`);
      } catch (e) { sim.anota(`detalhe ${nome}: ${e.message}`); }
    }
  });

  // ------------------------------------------------------------ 1ª sessão
  await sim.etapaDe('sessao-1', async () => {
    await irParaHome(sim);
    await escolheDuracao(sim, /^25min\s/);
    await comecaSessao(sim, 's1');
    await sim.foto('s1-sessao-inicio');
    await sim.espera(4000, 250);
    await sim.foto('s1-sessao-4s');
    await concluiSessao(sim, 's1', 25);
    await sim.foto('s1-resultado-ou-cena');
    await passaCenas(sim, 's1');
    await sim.quadros('s1-resultado-missoes', { total: 20, passo: 150 });
    await sim.fotoRolando('s1-resultado-final', { paginas: 2, dy: 500 });
    if (await sim.tem(/^Compartilhar o habitat/)) {
      await sim.toca(/^Compartilhar o habitat/, { espera: 1200 });
      await sim.foto('s1-compartilhar');
      if (await sim.tem(/^Pronto$/)) await sim.toca(/^Pronto$/, { espera: 900 });
      await sim.foto('s1-compartilhar-fechado');
    }
    if (await sim.tem(/^Voltar ao habitat/)) {
      const v = await sim.acha(/^Voltar ao habitat/);
      await sim.quadros('s1-volta-ao-habitat', { total: 10, passo: 100, acao: async () => sim.page.mouse.click(v.x, v.y) });
    }
    await passaCenas(sim, 's1-home');
    await sim.foto('s1-home-depois');
  });

  // ------------------------------------------------------------ desistir
  await sim.etapaDe('desistencia', async () => {
    const relogio = async () => { const n = (await sim.nos()).find(x => /^-\|\d\d:\d\d/.test(x)); return n ? n.split('|')[1] : '?'; };
    await comecaSessao(sim, 's2');
    await sim.espera(3000, 250);
    await sim.foto('s2-sessao-3s');
    sim.anota('relógio antes de desistir/recarregar: ' + await relogio());
    await sim.toca(/^Desistir/);
    await sim.foto('s2-confirma-desistir');
    await sim.toca(/^Ficar com ele/);
    await sim.foto('s2-ficou');
    sim.anota('relógio antes de recarregar: ' + await relogio());
    await sim.recarrega();
    await sim.foto('s2-apos-recarregar-na-sessao');
    sim.anota('relógio depois de recarregar (6,5 s depois): ' + await relogio() + ' rota ' + sim.rota());
    await sim.voltar();
    await sim.foto('s2-voltar-do-navegador-na-sessao');
    if (sim.rota() !== '/sessao') {
      sim.anota('o voltar saiu da sessão sem perguntar; voltando por endereço');
      await sim.page.goto(sim.o.url + '#/sessao'); await sim.espera(1500);
      await sim.foto('s2-de-volta-a-sessao');
    }
    await sim.toca(/^Desistir/);
    const sair = await sim.acha(/^Sair mesmo assim/);
    await sim.quadros('s2-sai', { total: 12, passo: 100, acao: async () => sim.page.mouse.click(sair.x, sair.y) });
    await sim.foto('s2-desistencia');
    await passaCenas(sim, 's2');
    if (await sim.tem(/^Voltar ao habitat|^Voltar$/)) await sim.toca(/^Voltar ao habitat|^Voltar$/, { espera: 1200 });
    await irParaHome(sim);
    await sim.foto('s2-home-apos-desistir');
  });

  if (curta) return;

  // ------------------------------------------------------------ 50 min
  await sim.etapaDe('sessao-50', async () => {
    await irParaHome(sim);
    await escolheDuracao(sim, /^50min\s/);
    await comecaSessao(sim, 's3');
    await concluiSessao(sim, 's3', 50);
    await passaCenas(sim, 's3');
    await sim.quadros('s3-resultado-missoes', { total: 24, passo: 150 });
    await sim.foto('s3-resultado-final');
    if (await sim.tem(/^Voltar ao habitat/)) await sim.toca(/^Voltar ao habitat/, { espera: 1200 });
    await passaCenas(sim, 's3-home');
    await sim.foto('s3-home');
  });

  // ------------------------------------------------------------ missões
  await sim.etapaDe('missoes', async () => {
    await irParaHome(sim);
    await sim.toca(/^Missões\s/, { espera: 1200 });
    await sim.fotoRolando('missoes', { paginas: 4, dy: 650 });
    if (await sim.tem(/^Colher as \d+ de uma vez|Colher/)) {
      const c = await sim.acha(/^Colher as \d+ de uma vez|^Colher/);
      await sim.quadros('missoes-colher-toca', { total: 10, passo: 100, acao: async () => sim.page.mouse.click(c.x, c.y) });
      await passaCenas(sim, 'missoes-colher');
      await sim.quadros('missoes-colhidas', { total: 16, passo: 120 });
      await sim.fotoRolando('missoes-depois', { paginas: 3, dy: 650 });
    } else {
      // colher uma a uma, se houver
      const p = await sim.acha(/PRONTAS PARA COLHER/);
      sim.anota('sem "Colher todas"; prontas: ' + !!p);
    }
    await sim.voltar();
    await sim.foto('missoes-apos-voltar');
  });

  // ------------------------------------------------------------ loja
  await sim.etapaDe('loja', async () => {
    await irParaHome(sim);
    await sim.toca(/^faltam \d+ folhas para|^Vitórias-régias|para a loja|^Habitat$|^Loja/, { espera: 1200 }).catch(async () => { await sim.page.goto(sim.o.url + '#/loja'); await sim.espera(1500); });
    await sim.foto('loja');
    // Tocar no cartão de um item que dá para levar já compra (sem
    // confirmação); a cena da compra abre por cima.
    const item = await sim.mostra(/^Vitórias-régias/).catch(() => null);
    if (item) {
      await sim.quadros('loja-compra', { total: 30, passo: 100, colunas: 6, acao: async () => sim.page.mouse.click(item.x, item.y) });
      await sim.foto('loja-compra-celebrada');
      if (await sim.tem(/^Ver no habitat/)) {
        const v = await sim.acha(/^Ver no habitat/);
        await sim.quadros('loja-ver-no-habitat', { total: 14, passo: 100, acao: async () => sim.page.mouse.click(v.x, v.y) });
      }
      await sim.foto('loja-depois-da-compra');
    } else sim.anota('item Vitórias-régias não encontrado');
    await irParaHome(sim);
    await sim.foto('home-com-item');
    await sim.page.goto(sim.o.url + '#/loja'); await sim.espera(1500);
    if (await sim.tem(/^Meus itens/)) { await sim.toca(/^Meus itens/); await sim.foto('loja-meus-itens'); }
    // recarregar dentro da loja
    await sim.recarrega();
    await sim.foto('loja-apos-recarregar');
  });

  // ------------------------------------------------------------ mais sessões (crescimento)
  await sim.etapaDe('crescimento', async () => {
    for (let k = 4; k <= 6; k++) {
      await irParaHome(sim);
      await escolheDuracao(sim, /^25min\s/);
      await comecaSessao(sim, `s${k}`);
      await sim.espera(25000 - 2000, 250);
      await sim.quadros(`s${k}-fim`, { total: 32, passo: 150, colunas: 8, escala: 0.4 });
      const vistas = await passaCenas(sim, `s${k}`);
      if (await sim.tem(/^Voltar ao habitat/)) await sim.toca(/^Voltar ao habitat/, { espera: 1200 });
      await passaCenas(sim, `s${k}-home`);
      await sim.foto(`s${k}-home`);
      sim.anota(`sessão ${k}: cenas ${JSON.stringify(vistas)}`);
    }
  });

  // ------------------------------------------------------------ abas
  await sim.etapaDe('abas', async () => {
    for (const aba of ['Trilha', 'Missões', 'Ajustes']) {
      await irParaHome(sim);
      await sim.toca(new RegExp('^' + aba + '\\s'), { espera: 400 });
      await sim.quadros(`aba-${aba}-entra`, { total: 6, passo: 80 });
      await sim.fotoRolando(`aba-${aba}`, { paginas: 6, dy: 650 });
      await sim.voltar();
      await sim.foto(`aba-${aba}-apos-voltar`);
    }
    // trilha: tocar um passo bloqueado
    await sim.toca(/^Trilha\s/, { espera: 1000 });
    try { await sim.toca(/sessões de foco|nível 3/i, { espera: 900 }); await sim.foto('trilha-toque-no-passo'); await sim.voltar(); } catch (e) { sim.anota('trilha: ' + e.message); }
  });

  // ------------------------------------------------------------ ajustes e telas de detalhe
  await sim.etapaDe('ajustes', async () => {
    await irParaHome(sim);
    await sim.toca(/^Ajustes\s/, { espera: 1000 });
    for (const [rx, nome] of [[/^Sobre outros apps/, 'sobreposicao'], [/^Sua conta|Gerenciar/, 'conta'], [/^Seu animal interior/, 'especie'], [/^Pelagem/, 'pelagem'], [/^Meta de tempo de tela/, 'meta'], [/^Duração da sessão/, 'duracao'], [/^Idioma/, 'idioma'], [/^Política de privacidade/, 'privacidade']]) {
      try {
        if (!(await sim.tem(/^Ajustes$/))) { await irParaHome(sim); await sim.toca(/^Ajustes\s/, { espera: 1000 }); }
        await sim.toca(rx, { espera: 1100 });
        await sim.fotoRolando(`ajustes-${nome}`, { paginas: 3, dy: 650 });
        await sim.voltar();
        await sim.foto(`ajustes-${nome}-apos-voltar`);
      } catch (e) { sim.anota(`ajustes ${nome}: ${e.message}`); }
    }
    // paywall por endereço (não há entrada visível sem cobrança na loja)
    await sim.page.goto(sim.o.url + '#/assinatura'); await sim.espera(1800);
    await sim.fotoRolando('paywall', { paginas: 2, dy: 600 });
    await sim.voltar();
    await sim.foto('paywall-apos-voltar');
    // tempo de tela, sequência, relatório e folhas por endereço
    for (const r of ['tempo', 'sequencia', 'relatorio', 'folhas', 'sobreposicao', 'conta']) {
      await sim.page.goto(sim.o.url + '#/' + r); await sim.espera(1800);
      await sim.fotoRolando(`endereco-${r}`, { paginas: 3, dy: 650 });
    }
  });

  // ------------------------------------------------------------ voltar em pontos delicados
  await sim.etapaDe('voltar', async () => {
    await irParaHome(sim);
    await escolheDuracao(sim, /^25min\s/);
    await comecaSessao(sim, 'sv');
    await sim.espera(25000, 250);
    await passaCenas(sim, 'sv');
    await sim.foto('sv-resultado');
    if (await sim.tem(/^Compartilhar o habitat/)) {
      await sim.toca(/^Compartilhar o habitat/, { espera: 1200 });
      await sim.foto('sv-folha-aberta');
      await sim.voltar();
      await sim.foto('sv-folha-apos-voltar');
      if (await sim.tem(/^Pronto$/)) await sim.toca(/^Pronto$/, { espera: 900 });
    }
    await sim.foto('sv-depois');
    await sim.voltar();
    await sim.foto('sv-depois-2o-voltar');
    await irParaHome(sim);
    await sim.voltar();
    await sim.foto('sv-voltar-na-home');
  });

  // ------------------------------------------------------------ idioma
  await sim.etapaDe('idioma', async () => {
    await sim.page.goto(sim.o.url + '#/ajustes'); await sim.espera(1500);
    for (const l of [/^中文|^Chinês|^zh/, /^English/, /^Português/]) {
      try {
        await sim.toca(/^Idioma|^Language|^语言/, { espera: 900 });
        await sim.toca(l, { espera: 900 });
        await sim.foto('idioma-' + l.source.replace(/[^a-zA-Z]/g, '').slice(0, 10));
        await sim.page.goto(sim.o.url + '#/'); await sim.espera(1500);
        await sim.foto('idioma-home-' + l.source.replace(/[^a-zA-Z]/g, '').slice(0, 10));
        await sim.page.goto(sim.o.url + '#/ajustes'); await sim.espera(1500);
      } catch (e) { sim.anota('idioma: ' + e.message); }
    }
  });
};

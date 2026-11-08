#!/usr/bin/env python3
"""Medidas de aceite das bocas (laudo 30, R2 a R6; lote BOCAS).

Lê build/visemas/ — gerado por `CAPTURAS=1 flutter test test/visemas_test.dart`
— e imprime, por espécie, o que o laudo pede em número:

- altura do vão (px, ×3) por visema, na ordem X A B C D E F; aceite: X ≈ A
  < B < C < D, E entre B e C + 10 %, F < E;
- largura do D ≤ 0,62·w; distância do nariz ao topo do vão ≥ 6 px em todos;
- F com largura ≤ 60 % da de B; E com razão altura/largura ≥ 0,7;
- D com língua e B com linha de dentes (onde a espécie tem);
- nos bicos (coruja, pinguim): diferença de máscara ≥ 15 % entre X e D e vão
  ≥ 12 px na base (quanto a ponta da mandíbula de baixo desce);
- `semBoca`: o quadro inteiro menos a região da boca é idêntico ao quadro
  com a boca X (a diferença fica dentro da caixa da boca).

E monta duas folhas de contato: build/visemas/folha.jpg (9 espécies × 7
visemas, humor contente) e build/visemas/folha-humores.jpg (lontra e raposa:
5 humores + susto + festa × 7 visemas).

Uso: python3 test/boca_medidas.py [build/visemas]
Sai com código 1 se algum aceite falhar.

Como o vão é medido: a camada de boca (`boca-<visema>.png`, só o que mudou
entre o quadro com boca e o corpo sem boca) tem a parede do traço do lábio
em volta do vão, 0,95 unidade para fora. A máscara de alfa da camada erodida
por esse tanto é o interior geométrico — cavidade, língua e dentes —, sem
depender da cor da cavidade, que em pelagens escuras quase não difere da do
traço. Dos componentes conexos que sobram, descartam-se os claros e soltos
(os dentinhos do buldogue fora do vão) e fica o maior; a caixa do vão é a
dos pixels não claros dele (a cavidade mais a língua), para a linha de dentes
não entrar na altura. Nos bicos a cor não separa vão de bico (o do pinguim é
quase tinta): mede-se quanto a silhueta do bico cresce na coluna do meio.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAIZ = sys.argv[1] if len(sys.argv) > 1 else 'build/visemas'
VIS = ['x', 'a', 'b', 'c', 'd', 'e', 'f']
ESP = ['capybara', 'otter', 'tortoise', 'owl', 'axolotl', 'penguin', 'cat', 'fox', 'frenchie']
NOME = dict(capybara='Baru (capivara)', otter='Rio (lontra)', tortoise='Toco (tartaruga)',
            owl='Nina (coruja)', axolotl='Lume (axolote)', penguin='Nino (pinguim)',
            cat='Mel (gata)', fox='Faísca (raposa)', frenchie='Bolota (buldogue)')
HUMORES = ['contente', 'radiante', 'neutro', 'sono', 'saudade', 'susto', 'festa']

try:
    FONTE = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 18)
    FONTE_B = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 26)
except Exception:  # noqa: BLE001 — sem a fonte do sistema, a padrão serve
    FONTE = FONTE_B = ImageFont.load_default()

falhas = []


def ok(cond, texto):
    """Imprime o resultado de um aceite e o anota se falhou."""
    print(f'    {"OK  " if cond else "FALHA"} {texto}')
    if not cond:
        falhas.append(texto)
    return cond


def rgba(caminho):
    return np.asarray(Image.open(caminho).convert('RGBA')).astype(int)


def erode(mascara, r):
    if r <= 0:
        return mascara
    im = Image.fromarray((mascara * 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.MinFilter(2 * r + 1))) > 127


def componentes(mascara):
    """Componentes conexos (8 vizinhos): lista de arrays (n, 2) de (y, x)."""
    h, w = mascara.shape
    visto = np.zeros((h, w), bool)
    saida = []
    for y0, x0 in zip(*np.nonzero(mascara)):
        if visto[y0, x0]:
            continue
        visto[y0, x0] = True
        pilha = [(y0, x0)]
        pontos = []
        while pilha:
            y, x = pilha.pop()
            pontos.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and mascara[yy, xx] and not visto[yy, xx]:
                        visto[yy, xx] = True
                        pilha.append((yy, xx))
        saida.append(np.array(pontos))
    return saida


def caixa_do_vao(camada, escala):
    """(x0, y0, x1, y1) do vão em px do recorte, ou None se a boca está fechada.
    Devolve também os pixels (ys, xs) do vão, para a medida na coluna do meio."""
    alfa = camada[..., 3] > 128
    nucleo = erode(alfa, max(1, int(round(0.95 * escala))))
    claro = camada[..., :3].sum(-1) > 620
    melhor = None
    for pts in componentes(nucleo):
        ys, xs = pts[:, 0], pts[:, 1]
        if claro[ys, xs].mean() > 0.6:
            continue  # dente solto, fora do vão
        escuro = ~claro[ys, xs]
        if not escuro.any():
            continue
        if melhor is None or len(pts) > melhor[0]:
            melhor = (len(pts), ys[escuro], xs[escuro])
    if melhor is None:
        return None, None
    _, ys, xs = melhor
    return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1), (ys, xs)


def conta_rosa(camada, caixa=None, sob_agua=False):
    """Pixels de língua: mais vermelho que verde e que azul. Sob a água o
    limiar afrouxa: o axolote fala com a boca sob a linha d'água do habitat,
    e o tom da água leva o rosa (242,162,124) a (170,144,113); fora dela o
    limiar estrito separa a língua do bico creme da coruja (217,199,154).
    Dentro da caixa do vão, se houver, para o pelo das bordas não contar."""
    r, g, b, a = (camada[..., i] for i in range(4))
    rosa = (a > 128) & (r > 150) & (r - b > 45) & (r - g > (15 if sob_agua else 40))
    if caixa is not None:
        x0, y0, x1, y1 = caixa
        m = np.zeros_like(rosa)
        m[y0:y1, x0:x1] = True
        rosa &= m
    return int(rosa.sum())


def conta_claro(camada):
    return int(((camada[..., 3] > 128) & (camada[..., :3].sum(-1) > 620)).sum())


def mascara_no_quadro(sp, v, anc, quadro):
    """A máscara de alfa da camada de boca posta de volta no quadro inteiro."""
    cam = rgba(f'{RAIZ}/{sp}/boca-{v}.png')
    x0, y0, x1, y1 = anc['capturas'][f'boca-{v}']['recorte']
    m = np.zeros((quadro[1], quadro[0]), bool)
    m[y0:y1, x0:x1] = cam[..., 3] > 128
    return m


def mede_boca(sp, anc):
    e = anc['especie']
    w, hmax, folga = e['w'], e['hMax'], e['folgaNariz']
    alt, larg, topo, caixa = {}, {}, {}, {}
    escala = None
    for v in VIS:
        a = anc['capturas'][f'boca-{v}']
        escala = a['escala']
        cam = rgba(f'{RAIZ}/{sp}/boca-{v}.png')
        c, pixels = caixa_do_vao(cam, escala)
        caixa[v] = c
        if c is None:
            alt[v], larg[v], topo[v] = 0, 0, None
        else:
            alt[v], larg[v] = c[3] - c[1], c[2] - c[0]
            # O topo do vão na coluna do meio (±2 px), que é onde o nariz
            # está: os cantos de um sorriso sobem, e são outra medida.
            ys, xs = pixels
            meio = a['p'][0] - a['recorte'][0]
            no_meio = ys[abs(xs - meio) <= 2]
            topo[v] = (no_meio.min() if len(no_meio) else c[1]) + a['recorte'][1]
    print(f'  w={w} hMax={hmax} escala={escala:.2f} px/u')
    print('    altura do vão (px) X A B C D E F: ' + ' '.join(str(alt[v]) for v in VIS))
    print('    largura do vão (px) X A B C D E F: ' + ' '.join(str(larg[v]) for v in VIS))
    # X e A são linhas (1,9 e 2,4 de traço): o que sobra da erosão é resto
    # de borda, até 3 px.
    ok(abs(alt['x'] - alt['a']) <= 3 and alt['a'] < alt['b'] < alt['c'] < alt['d'],
       f'ordem X≈A < B < C < D: {alt["x"]} ≈ {alt["a"]} < {alt["b"]} < {alt["c"]} < {alt["d"]}')
    ok(alt['b'] < alt['e'] <= alt['c'] * 1.10 + 1,
       f'E entre B e C+10 %: {alt["b"]} < {alt["e"]} ≤ {alt["c"] * 1.10 + 1:.1f}')
    ok(alt['f'] < alt['e'], f'F < E: {alt["f"]} < {alt["e"]}')
    lim = 0.62 * w * escala
    ok(larg['d'] <= lim + 1, f'largura do D: {larg["d"]} px ≤ 0,62·w = {lim:.1f} px (+1 de borda)')
    p = anc['capturas']['boca-d']['p']
    nariz = p[1] - folga * escala
    dist = min(topo[v] - nariz for v in VIS if topo[v] is not None)
    if folga < 50:
        ok(dist >= 6, f'nariz → topo do vão: {dist:.1f} px ≥ 6 (mínimo entre os visemas abertos)')
    else:
        print(f'    —    nariz → topo do vão: sem nariz desenhado ({dist:.1f} px da linha de referência)')
    ok(larg['f'] <= 0.6 * larg['b'], f'largura F/B: {larg["f"]}/{larg["b"]} = {larg["f"] / max(1, larg["b"]):.2f} ≤ 0,60')
    razao = alt['e'] / max(1, larg['e'])
    ok(razao >= 0.7, f'E altura/largura: {alt["e"]}/{larg["e"]} = {razao:.2f} ≥ 0,7')
    rosa = conta_rosa(rgba(f'{RAIZ}/{sp}/boca-d.png'), caixa['d'], sob_agua=sp == 'axolotl')
    if e['temLingua']:
        ok(rosa > 0, f'D com língua: {rosa} px rosa no vão')
    else:
        ok(rosa == 0, f'D sem língua (a espécie não mostra): {rosa} px rosa no vão')
    claros = conta_claro(rgba(f'{RAIZ}/{sp}/boca-b.png'))
    if e['temDentes']:
        ok(claros > 0, f'B com linha de dentes: {claros} px claros')
    else:
        print(f'    —    B sem dentes (a espécie não mostra): {claros} px claros')


def mede_bico(sp, anc):
    e = anc['especie']
    quadro = anc['quadro']
    p = anc['capturas']['boca-d']['p']
    escala = anc['capturas']['boca-d']['escala']
    print(f'  bico: w={e["w"]} hMax={e["hMax"]} escala={escala:.2f} px/u')
    mx = mascara_no_quadro(sp, 'x', anc, quadro)
    col = int(round(p[0]))

    def extensao(m):
        ys = np.nonzero(m[:, col])[0]
        return (ys.max() - ys.min() + 1) if len(ys) else 0

    base = extensao(mx)
    desce = {v: extensao(mascara_no_quadro(sp, v, anc, quadro)) - base for v in VIS}
    print('    descida da mandíbula no meio (px) X A B C D E F: ' + ' '.join(str(desce[v]) for v in VIS))
    md = mascara_no_quadro(sp, 'd', anc, quadro)
    dif = (mx ^ md).sum() / max(1, mx.sum())
    ok(dif >= 0.15, f'máscara X × D: {dif * 100:.0f} % de diferença ≥ 15 %')
    ok(desce['d'] >= 12, f'vão na base em D: {desce["d"]} px ≥ 12')
    ok(desce['x'] == 0 and desce['a'] == 0 and 0 < desce['b'] < desce['c'] <= desce['d'],
       f'ordem X = A = 0 < B < C ≤ D: {desce["x"]} {desce["a"]} {desce["b"]} {desce["c"]} {desce["d"]}')
    ok(abs(desce['e'] - desce['c']) <= 2 + 0.07 * desce['d'] and abs(desce['f'] - desce['c']) <= 1,
       f'E e F viram C no bico: E={desce["e"]} F={desce["f"]} C={desce["c"]}')
    rosa = conta_rosa(rgba(f'{RAIZ}/{sp}/boca-d.png'))
    if e['temLingua']:
        ok(rosa > 0, f'D com língua (pinguim): {rosa} px rosa')
    else:
        ok(rosa == 0, f'D sem língua (coruja): {rosa} px rosa')


def mede_sem_boca(sp, anc):
    e = anc['especie']
    a = anc['capturas']['contente-x']
    p, esc = a['p'], a['escala']
    com = rgba(f'{RAIZ}/{sp}/contente-x.png')
    sem = rgba(f'{RAIZ}/{sp}/corpo-x.png')
    dif = (com != sem).any(-1)
    ys, xs = np.nonzero(dif)
    w, hmax = e['w'], e['hMax']
    cx0, cx1 = p[0] - (0.55 * w + 2) * esc, p[0] + (0.55 * w + 2) * esc
    cy0, cy1 = p[1] - (0.5 * w + 2) * esc, p[1] + (max(hmax, 0.4 * w) + 4) * esc
    dentro = len(xs) > 0 and xs.min() >= cx0 and xs.max() <= cx1 and ys.min() >= cy0 and ys.max() <= cy1
    caixa = f'[{xs.min()},{ys.min()}..{xs.max()},{ys.max()}]' if len(xs) else 'vazia'
    ok(dentro, f'semBoca: a diferença para o quadro X fica na caixa da boca ({len(xs)} px, {caixa}; '
               f'caixa [{cx0:.0f},{cy0:.0f}..{cx1:.0f},{cy1:.0f}])')


def rosto(im):
    w, h = im.size
    return im.crop((int(w * 0.18), int(h * 0.02), int(w * 0.82), int(h * 0.62)))


def grade(celulas, cols, cw, ch, titulo, fundo=(246, 240, 228)):
    linhas = (len(celulas) + cols - 1) // cols
    W, H = cols * cw, 50 + linhas * (ch + 26)
    out = Image.new('RGB', (W, H), fundo)
    d = ImageDraw.Draw(out)
    d.text((10, 10), titulo, fill=(40, 30, 20), font=FONTE_B)
    for k, (rotulo, im) in enumerate(celulas):
        x, y = (k % cols) * cw, 50 + (k // cols) * (ch + 26)
        im = im.convert('RGBA')
        im.thumbnail((cw - 6, ch - 6))
        base = Image.new('RGB', (cw - 6, ch - 6), (255, 255, 255))
        base.paste(im, ((cw - 6 - im.width) // 2, (ch - 6 - im.height) // 2), im)
        out.paste(base, (x + 3, y))
        d.rectangle([x + 3, y, x + cw - 3, y + ch - 6], outline=(200, 190, 170))
        d.text((x + 6, y + ch - 4), rotulo, fill=(60, 45, 30), font=FONTE)
    return out


def folhas(especies):
    cel = []
    for sp in especies:
        for v in VIS:
            cel.append((f'{sp} {v.upper()}', rosto(Image.open(f'{RAIZ}/{sp}/contente-{v}.png'))))
    grade(cel, 7, 230, 210, 'Visemas X A B C D E F · humor contente · 9 espécies').save(f'{RAIZ}/folha.jpg', quality=88)
    cel = []
    for sp in [s for s in ('otter', 'fox') if s in especies]:
        for h in HUMORES:
            for v in VIS:
                cel.append((f'{sp} {h} {v.upper()}', rosto(Image.open(f'{RAIZ}/{sp}/{h}-{v}.png'))))
    if cel:
        grade(cel, 7, 230, 210, 'Lontra e raposa · 5 humores + susto + festa × 7 visemas').save(f'{RAIZ}/folha-humores.jpg', quality=88)


def main():
    anc = json.load(open(f'{RAIZ}/ancoras.json'))
    especies = [s for s in ESP if s in anc]
    for sp in especies:
        print(f'{NOME[sp]} [{sp}]')
        if anc[sp]['especie']['bico']:
            mede_bico(sp, anc[sp])
        else:
            mede_boca(sp, anc[sp])
        mede_sem_boca(sp, anc[sp])
    folhas(especies)
    print(f'folhas: {RAIZ}/folha.jpg' + (f', {RAIZ}/folha-humores.jpg' if os.path.exists(f'{RAIZ}/folha-humores.jpg') else ''))
    if falhas:
        print(f'\n{len(falhas)} aceite(s) falharam:')
        for f in falhas:
            print('  -', f)
        sys.exit(1)
    print('\ntodos os aceites passaram')


if __name__ == '__main__':
    main()

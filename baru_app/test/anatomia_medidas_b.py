#!/usr/bin/env python3
"""Medidas de anatomia da Nina, do Lume e do Nino (lote "anatomia", laudo 32).

Lê as capturas de
  CAPTURAS=1 ESPECIES=owl,axolotl,penguin flutter test test/atlas_novelinha_test.dart
(`build/atlas/<espécie>/<estado>.png`, 1040 × 880, 4 px por unidade) e, se
existirem, as de `test/atlas_anim24_test.dart` (`build/atlas_anim24/`), e
imprime os números dos critérios de aceite do laudo 32 e dos achados
NINA/LUME/NINO de anatomia:

  coruja   pernas visíveis ÷ altura da figura (R4: ≥ 16 %); branco convexo
           sob o bico (NINA-02: nenhum); contraste olho × disco (R13: ≥ 3),
           sobrancelha × disco (≥ 2), bico × disco (NINA-15: ≥ 2); pintas
           claras na cabeça/asas (NINA-15: ≥ 15); ΔE pelagem 0 × #847262
           (R13: ≤ 12).
  axolote  pares de guelras detectáveis por cor (3); contraste haste e
           filamento × as 6 pelagens (R5: ≥ 2,3); ΔE cabeça × haste
           (LUME-15: ≥ 20); membros visíveis fora d'água (LUME-06: 4).
  pinguim  largura das duas faixas do peito (R8: 5 u) e vão entre elas
           (NINO-12: ≥ 12 u); contraste faixa × peito (≥ 4,5 : 1, R8/NINO-10
           pedem ≥ 7); mesmo hex para faixa da cabeça e barriga; perfil de
           largura sem vale cabeça → peito (R8: nenhum mínimo local > 3 %);
           ΔE pelagem 0 × #293342 (R8: ≤ 10); largura da silhueta
           (NINO-09: ≥ 108 u); estágios com md5 distintos.
  turma    IoU entre as silhuetas das três espécies (≤ 0,70) e o teste do
           preto: diferença entre silhuetas (1 − IoU, ≥ 30 %).

Com `--folha <saida.jpg> <antes>`, monta a folha antes/depois (contente,
susto, festa, anda/voa/nada q6, estágios).

Uso: python3 test/anatomia_medidas_b.py [build/atlas] [--anim build/atlas_anim24]
                                        [--folha build/atlas/anatomia_nln.jpg build/atlas_antes]
"""
import colorsys
import hashlib
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

ESP = ('owl', 'axolotl', 'penguin')
PX = 4.0  # px por unidade na novelinha (260 × 220 a ×4)

# Paletas (tokens.dart) e cores fixas do pet.dart, para as contas de cor.
SUPERFICIE = '#FAF1E3'
TINTA = '#3E2F23'
PELAGEM_CORUJA = ['#8A7461', '#7A5E45', '#B89773', '#6E6358', '#8C7B6B', '#C2A585']
PELAGEM_AXOLOTE = ['#E39BA8', '#D98795', '#EEB3BD', '#C97C93', '#E8A9AE', '#F2C6CB']
PELAGEM_PINGUIM = ['#253143', '#1D2636', '#648697', '#2D3A48', '#5A7E90', '#7C9AA8']
OLHO_CORUJA = '#F2C94C'
SOBRANCELHA = '#F3EDE3'
BICO_CORUJA = '#BDB48C'
GUELRA_HASTE = '#9C2E39'
GUELRA_FIO = '#982C38'
FAIXA_PINGUIM = '#1D2636'
PEITO_PINGUIM = '#EEF3F8'


# --- cor -------------------------------------------------------------------

def rgb(c):
    return tuple(int(c[i:i + 2], 16) / 255 for i in (1, 3, 5))


def hexa(t):
    return '#%02X%02X%02X' % tuple(round(x * 255) for x in t)


def lerp(a, b, t):
    return hexa(tuple(x + (y - x) * t for x, y in zip(rgb(a), rgb(b))))


def luminancia(c):
    r, g, b = [(x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4)
               for x in rgb(c)]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contraste(a, b):
    la, lb = sorted([luminancia(a), luminancia(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


def lab(c):
    r, g, b = [(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4)
               for x in rgb(c)]
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = (0.2126 * r + 0.7152 * g + 0.0722 * b)
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116
    fx, fy, fz = f(x), f(y), f(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def delta_e(a, b):
    return math.dist(lab(a), lab(b))


# --- imagem ----------------------------------------------------------------

def abre(caminho):
    return np.asarray(Image.open(caminho).convert('RGBA')).astype(np.int32)


def mascara(q, limiar=100):
    return q[..., 3] > limiar


def bbox(m):
    ys, xs = np.nonzero(m)
    return ys.min(), ys.max(), xs.min(), xs.max()


def hsv(q):
    rgbn = q[..., :3] / 255.0
    mx = rgbn.max(axis=-1)
    mn = rgbn.min(axis=-1)
    d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-9), 0)
    r, g, b = rgbn[..., 0], rgbn[..., 1], rgbn[..., 2]
    h = np.zeros_like(mx)
    dd = np.where(d == 0, 1, d)
    h = np.where(mx == r, ((g - b) / dd) % 6, h)
    h = np.where(mx == g, (b - r) / dd + 2, h)
    h = np.where(mx == b, (r - g) / dd + 4, h)
    h = (h * 60) % 360
    return h, s, mx


def componentes(m):
    """Componentes conexos (4-vizinhos) de uma máscara booleana: lista de
    (área, cy, cx)."""
    vis = np.zeros_like(m, dtype=bool)
    saida = []
    hh, ww = m.shape
    ys, xs = np.nonzero(m)
    for y0, x0 in zip(ys, xs):
        if vis[y0, x0]:
            continue
        pilha = [(y0, x0)]
        vis[y0, x0] = True
        n, sy, sx = 0, 0, 0
        while pilha:
            y, x = pilha.pop()
            n += 1
            sy += y
            sx += x
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < hh and 0 <= xx < ww and m[yy, xx] and not vis[yy, xx]:
                    vis[yy, xx] = True
                    pilha.append((yy, xx))
        saida.append((n, sy / n, sx / n))
    return saida


def larguras(m):
    return m.sum(axis=1)


# --- coruja ----------------------------------------------------------------

def mede_coruja(pasta):
    q = abre(os.path.join(pasta, 'owl', 'boca-contente-0.png'))
    m = mascara(q)
    y0, y1, x0, x1 = bbox(m)
    altura = y1 - y0 + 1
    w = larguras(m)
    maxw = w[y0:y1 + 1].max()
    # Pernas: as linhas de baixo em que a máscara é estreita (< 50 % da
    # largura máxima; os dedos abertos chegam a 43 %), contadas de baixo
    # para cima até o corpo.
    pernas = 0
    for y in range(y1, y0, -1):
        if w[y] < 0.5 * maxw:
            pernas += 1
        else:
            break
    print(f'coruja  pernas visíveis {pernas} px = {pernas / PX:.1f} u; altura '
          f'{altura / PX:.1f} u → {100 * pernas / altura:.1f} % (aceite ≥ 16 %)')

    # Branco convexo sob o bico (NINA-02): componentes muito claros, abaixo
    # do centro da cabeça e estreitos; "pontas acima do meio" = sorriso.
    h, s, v = hsv(q)
    branco = m & (v > 0.88) & (s < 0.12)
    # Só abaixo dos olhos (a linha mais baixa do amarelo): as sobrancelhas
    # ficam de fora.
    amarelo = m & (h >= 38) & (h <= 56) & (s >= 0.45) & (v >= 0.45)
    abaixo_dos_olhos = np.nonzero(amarelo.any(axis=1))[0].max()
    sorrisos = 0
    for n, yc, xc in componentes(branco):
        if n < 60 or yc < abaixo_dos_olhos or yc > y0 + altura * 0.6:
            continue
        ys, xs = np.nonzero(branco)
        sel = np.abs(ys - yc) < 60
        sel &= np.abs(xs - xc) < 120
        if sel.sum() == 0:
            continue
        xs_c, ys_c = xs[sel], ys[sel]
        esq = ys_c[xs_c == xs_c.min()].mean()
        dir_ = ys_c[xs_c == xs_c.max()].mean()
        meio = ys_c[np.abs(xs_c - (xs_c.min() + xs_c.max()) / 2) < 3].mean()
        if (esq + dir_) / 2 < meio - 1 and n > 200:
            sorrisos += 1
            print(f'        branco convexo: área {n}, centro ({xc:.0f}, {yc:.0f}), '
                  f'pontas {esq:.0f}/{dir_:.0f} meio {meio:.0f}')
    print(f'coruja  componentes brancos com pontas acima do meio sob o bico: '
          f'{sorrisos} (aceite 0)')

    disco = lerp(PELAGEM_CORUJA[0], TINTA, 0.14)
    print(f'coruja  contraste olho×disco {contraste(OLHO_CORUJA, disco):.2f} (≥ 3); '
          f'sobrancelha×disco {contraste(SOBRANCELHA, disco):.2f} (≥ 2); '
          f'bico×disco {contraste(BICO_CORUJA, disco):.2f} (≥ 2)')
    print(f'coruja  ΔE pelagem 0 × #847262 = {delta_e(PELAGEM_CORUJA[0], "#847262"):.1f} (≤ 12)')

    # Pintas claras: componentes pequenos e claros sobre o pardo.
    pintas = [c for c in componentes(m & (v > 0.78) & (s < 0.22))
              if 20 <= c[0] <= 260]
    print(f'coruja  pintas claras pequenas visíveis: {len(pintas)} (≥ 15)')


# --- axolote ---------------------------------------------------------------

def mede_axolote(pasta):
    q = abre(os.path.join(pasta, 'axolotl', 'boca-contente-0.png'))
    m = mascara(q)
    h, s, v = hsv(q)
    # Guelra: vermelho-sangue (matiz 340–360 ou 0–12, saturação ≥ 0,45).
    verm = m & ((h >= 340) | (h <= 12)) & (s >= 0.45) & (v < 0.9)
    y0, y1, x0, x1 = bbox(m)
    cx = (x0 + x1) / 2
    # Os ramos de um lado se tocam pela pluma: conta-se por coluna, o número
    # de corridas vermelhas numa vertical a 30–60 u do centro (o máximo).
    pares = []
    for lado in (-1, 1):
        melhor = 0
        for du in range(30, 62, 2):
            x = int(cx + lado * du * PX)
            col = verm[:, x]
            corridas = 0
            dentro = False
            for v_ in col:
                if v_ and not dentro:
                    corridas += 1
                dentro = bool(v_)
            melhor = max(melhor, corridas)
        pares.append(melhor)
    print(f'axolote ramos de guelra por coluna: {pares[0]} à esquerda, '
          f'{pares[1]} à direita → {min(pares)} pares (aceite 3); '
          f'{int(verm.sum())} px vermelhos')
    cs = [contraste(GUELRA_HASTE, p) for p in PELAGEM_AXOLOTE]
    cf = [contraste(GUELRA_FIO, p) for p in PELAGEM_AXOLOTE]
    print(f'axolote contraste haste × pelagens min {min(cs):.2f}, filamento min '
          f'{min(cf):.2f} (R5: ≥ 2,3)')
    print(f'axolote ΔE cabeça × haste = {delta_e(PELAGEM_AXOLOTE[0], GUELRA_HASTE):.1f} (≥ 20)')
    # Membros fora d'água: componentes escuros abaixo do meio do corpo
    # (pose-carregado).
    qc = abre(os.path.join(pasta, 'axolotl', 'pose-carregado.png'))
    mc = mascara(qc)
    hc, sc, vc = hsv(qc)
    y0, y1, x0, x1 = bbox(mc)
    escuro = mc & (vc < 0.72) & (sc < 0.5)
    escuro[: int(y0 + (y1 - y0) * 0.45)] = False
    membros = [c for c in componentes(escuro) if c[0] >= 100]
    print(f'axolote membros escuros visíveis sob o corpo (carregado): {len(membros)} (aceite 4)')


# --- pinguim ---------------------------------------------------------------

def mede_pinguim(pasta):
    q = abre(os.path.join(pasta, 'penguin', 'boca-contente-0.png'))
    m = mascara(q)
    h, s, v = hsv(q)
    y0, y1, x0, x1 = bbox(m)
    cx = int((x0 + x1) / 2)
    # Coluna central: corridas escuras dentro da barriga clara.
    col = v[:, cx]
    dentro = m[:, cx]
    faixas = []
    claro = False
    y = y0
    while y <= y1:
        if dentro[y] and col[y] > 0.8:
            claro = True
        if claro and dentro[y] and col[y] < 0.4:
            ini = y
            while y <= y1 and col[y] < 0.4:
                y += 1
            faixas.append((ini, y - 1))
            claro = False
            continue
        y += 1
    larg = [(b - a + 1) / PX for a, b in faixas]
    vao = (faixas[1][0] - faixas[0][1] - 1) / PX if len(faixas) >= 2 else math.nan
    print(f'pinguim faixas do peito na coluna central: {len(faixas)}; larguras '
          f'{[round(x, 1) for x in larg]} u (R8: 5); vão {vao:.1f} u (≥ 12)')
    if faixas:
        a, b = faixas[0]
        cf = hexa(tuple(q[(a + b) // 2, cx, :3] / 255))
        yp = (faixas[0][1] + faixas[1][0]) // 2 if len(faixas) > 1 else b + 20
        cp = hexa(tuple(q[yp, cx, :3] / 255))
        print(f'pinguim contraste faixa {cf} × peito {cp} medido = {contraste(cf, cp):.1f} : 1 '
              f'(≥ 4,5); de projeto {contraste(FAIXA_PINGUIM, PEITO_PINGUIM):.1f}')
    # Perfil de largura, do topo até a linha mais larga: mínimos locais.
    w = larguras(m).astype(float)
    ymax = y0 + int(np.argmax(w[y0:y1 + 1]))
    perfil = w[y0:ymax + 1]
    suave = np.convolve(perfil, np.ones(9) / 9, mode='same')
    pior = 0.0
    for i in range(8, len(suave) - 8):
        esq = suave[:i].max()
        if esq > 0:
            pior = max(pior, (esq - suave[i]) / esq)
    print(f'pinguim vale no perfil cabeça → peito: {100 * pior:.1f} % (R8: nenhum > 3 %)')
    print(f'pinguim largura da silhueta {(x1 - x0 + 1) / PX:.0f} u (NINO-09: ≥ 108)')
    print(f'pinguim ΔE pelagem 0 × #293342 = {delta_e(PELAGEM_PINGUIM[0], "#293342"):.1f} (≤ 10)')
    rosa = m & (h >= 345) | (h <= 15)
    rosa &= m & (s >= 0.18) & (s <= 0.5) & (v > 0.8)
    print(f'pinguim pixels de pele rosa em volta do olho: {int(rosa.sum())}')
    md5s = set()
    for e in ('inicio', 'filhote', 'jovem', 'adulto', 'pleno'):
        arq = os.path.join(pasta, 'penguin', f'estagio-{e}.png')
        md5s.add(hashlib.md5(open(arq, 'rb').read()).hexdigest())
    print(f'pinguim estágios com desenho distinto: {len(md5s)} de 5')


# --- turma -----------------------------------------------------------------

def normaliza(m, lado=200):
    y0, y1, x0, x1 = bbox(m)
    im = Image.fromarray((m[y0:y1 + 1, x0:x1 + 1] * 255).astype(np.uint8))
    return np.asarray(im.resize((lado, lado), Image.BILINEAR)) > 127


def mede_turma(pasta):
    ms = {}
    for sp in ESP:
        ms[sp] = mascara(abre(os.path.join(pasta, sp, 'boca-contente-0.png')))
    for i, a in enumerate(ESP):
        for b in ESP[i + 1:]:
            inter = (ms[a] & ms[b]).sum()
            uni = (ms[a] | ms[b]).sum()
            na, nb = normaliza(ms[a]), normaliza(ms[b])
            iou_n = (na & nb).sum() / (na | nb).sum()
            print(f'turma   IoU {a} × {b}: no quadro {inter / uni:.2f}, normalizado '
                  f'{iou_n:.2f} (≤ 0,70); teste do preto: diferença '
                  f'{100 * (1 - inter / uni):.0f} % (≥ 30 %)')


# --- folha -----------------------------------------------------------------

def folha(depois, antes, anim, anim_antes, saida):
    W, H = 260, 220
    colunas = [
        ('contente', 'atlas', 'boca-contente-0'),
        ('susto', 'atlas', 'susto-0'),
        ('festa', 'atlas', 'festa-0'),
        ('anda q6', 'anim', 'anda-{sp}/6'),
        ('voa/nada q6', 'anim', '{ciclo}-{sp}/6'),
        ('ovo', 'atlas', 'estagio-inicio'),
        ('filhote', 'atlas', 'estagio-filhote'),
        ('jovem', 'atlas', 'estagio-jovem'),
        ('adulto', 'atlas', 'estagio-adulto'),
        ('pleno', 'atlas', 'estagio-pleno'),
    ]
    fundo = (236, 228, 214)
    im = Image.new('RGB', (90 + W * len(colunas), 24 + H * len(ESP) * 2), fundo)
    d = ImageDraw.Draw(im)
    for j, (nome, _, _) in enumerate(colunas):
        d.text((96 + j * W, 6), nome, fill=(60, 50, 40))
    for i, sp in enumerate(ESP):
        ciclo = 'voa' if sp == 'owl' else 'nada'
        for k, (rotulo, p_atlas, p_anim) in enumerate(
                (('antes', antes, anim_antes), ('depois', depois, anim))):
            y = 24 + (i * 2 + k) * H
            d.text((6, y + 6), f'{sp}\n{rotulo}', fill=(60, 50, 40))
            for j, (_, fonte, padrao) in enumerate(colunas):
                base = p_atlas if fonte == 'atlas' else p_anim
                if not base:
                    continue
                nome = padrao.format(sp=sp, ciclo=ciclo)
                arq = os.path.join(base, sp, nome + '.png') if fonte == 'atlas' \
                    else os.path.join(base, nome + '.png')
                if not os.path.exists(arq):
                    continue
                q = Image.open(arq).convert('RGBA').resize((W, H), Image.LANCZOS)
                fundo_q = Image.new('RGBA', (W, H), fundo + (255,))
                fundo_q.alpha_composite(q)
                im.paste(fundo_q.convert('RGB'), (90 + j * W, y))
    im.save(saida, quality=88)
    print('folha', saida, im.size)


def main():
    args = sys.argv[1:]
    pasta = 'build/atlas'
    anim = None
    folha_args = None
    i = 0
    while i < len(args):
        if args[i] == '--anim':
            anim = args[i + 1]
            i += 2
        elif args[i] == '--folha':
            folha_args = (args[i + 1], args[i + 2])
            i += 3
        else:
            pasta = args[i]
            i += 1
    print(f'# {pasta}')
    mede_coruja(pasta)
    mede_axolote(pasta)
    mede_pinguim(pasta)
    mede_turma(pasta)
    if folha_args:
        saida, antes = folha_args
        anim_antes = os.path.join(os.path.dirname(antes.rstrip('/')),
                                  'atlas_antes_anim24')
        folha(pasta, antes, anim, anim_antes if os.path.isdir(anim_antes) else None,
              saida)


if __name__ == '__main__':
    main()

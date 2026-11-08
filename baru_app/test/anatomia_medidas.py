#!/usr/bin/env python3
"""Medidas do lote "anatomia" (laudo 31 R5–R7, R9, R10) sobre as capturas do
atlas de `atlas_novelinha_test.dart` (e, se houver, de `atlas_anim24_test`).

Uso: python3 test/anatomia_medidas.py [build/atlas] [build/atlas_antes]

Lê `<pasta>/<espécie>/<quadro>.png` (caixa 260 × 220 a 4×: 1 unidade = 4 px)
e imprime, por espécie, as medidas de aceite:

- capivara: orelha/cabeça ≤ 0,11; corpo largura/altura ≥ 1,3; IoU da
  silhueta com a lontra ≤ 0,70;
- lontra: base da cauda ≥ 0,30 da largura do corpo e cauda num componente
  só; mancha clara queixo+garganta+peito com luminância ≥ 1,8× o dorso,
  num componente só que cruza a linha cabeça/corpo; bigodes com contraste
  ≥ 3 : 1 sobre o pelo;
- tracajá: com `pescoco = −1` o centroide da cabeça (esclera) desloca ≥ 14 u
  em x e ≥ 8 u para baixo; casco largura/altura ≥ 1,6; manchas × cabeça
  contraste ≥ 4,5 : 1; olhos a ≥ 0,60 da largura da cabeça.

Também monta `<pasta>/anatomia_abc.jpg`: antes/depois por espécie (contente,
susto, festa, anda q6, nada q6, filhote, jovem, pleno).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

BASE = sys.argv[1] if len(sys.argv) > 1 else 'build/atlas'
ANTES = sys.argv[2] if len(sys.argv) > 2 else 'build/atlas_antes'
U = 4.0  # px por unidade do desenho

SUPERFICIE = (0xFA, 0xF1, 0xE3)
TINTA = (0x3E, 0x2F, 0x23)
BRANCO = (255, 255, 255)
# pelagem[0] de cada espécie (tokens.dart) — o atlas usa coat 0 e humor
# contente, cujo pelo é a cor da pelagem sem mistura.
PELO = {
    'capybara': (0xB0, 0x7A, 0x4E),
    'otter': (0x5E, 0x4A, 0x40),
    'tortoise': (0x56, 0x62, 0x41),
}
FRIO = {
    'capybara': (0x3B, 0x2A, 0x3A),
    'otter': (0x2B, 0x2F, 0x3A),
    'tortoise': (0x2F, 0x3A, 0x33),
}


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def paleta(sp):
    pelo = PELO[sp]
    p = {
        'pelo': pelo,
        'sombra': lerp(pelo, TINTA, 0.30),
        'sombraForte': lerp(pelo, TINTA, 0.46),
        'claro': lerp(pelo, SUPERFICIE, 0.30),
        'barriga': lerp(pelo, SUPERFICIE, 0.26),
        'sombraFria': lerp(pelo, FRIO[sp], 0.35),
    }
    if sp == 'otter':
        p['garganta'] = lerp(p['claro'], (0xC9, 0xA9, 0x91), 0.5)
        p['labio'] = lerp(p['claro'], (0xE1, 0xB7, 0x9C), 0.6)
    if sp == 'tortoise':
        casco = lerp(p['sombra'], (0x6E, 0x6A, 0x55), 0.45)
        p['casco'] = casco
        p['borda'] = lerp(casco, (0xB4, 0xAC, 0x8F), 0.5)
        p['vertebral'] = lerp(casco, SUPERFICIE, 0.14)
        p['plastrao'] = lerp(p['barriga'], (0xD9, 0xC2, 0x7A), 0.75)
        p['mancha'] = (0xF7, 0xD9, 0x6A)
    return p


def carrega(pasta, sp, nome):
    return np.asarray(Image.open(f'{pasta}/{sp}/{nome}.png').convert('RGBA')).astype(np.int32)


def silhueta(im):
    return im[:, :, 3] > 40


def perto(im, cor, tol=14):
    d = np.abs(im[:, :, :3] - np.array(cor)).max(axis=2)
    return (d <= tol) & (im[:, :, 3] > 200)


def caixa(mask):
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def luminancia(rgb):
    """Luminância relativa (WCAG) de uma cor 0..255."""
    c = np.asarray(rgb, dtype=float) / 255
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def contraste(a, b):
    la, lb = luminancia(a), luminancia(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def mediana_cor(im, mask):
    px = im[:, :, :3][mask]
    return tuple(np.median(px, axis=0)) if len(px) else (0, 0, 0)


def alinha(a, b):
    ca, cb = caixa(silhueta(a)), caixa(silhueta(b))
    w = max(ca[2] - ca[0], cb[2] - cb[0])
    h = max(ca[3] - ca[1], cb[3] - cb[1])

    def rec(im, c):
        out = np.zeros((h, w), bool)
        sub = silhueta(im)[c[1]:c[3], c[0]:c[2]]
        x0 = (w - sub.shape[1]) // 2
        out[:sub.shape[0], x0:x0 + sub.shape[1]] = sub
        return out
    return rec(a, ca), rec(b, cb)


def iou(a, b):
    sa, sb = alinha(a, b)
    return (sa & sb).sum() / (sa | sb).sum()


def componentes(mask):
    lab, n = ndimage.label(mask)
    return lab, n


def maior_componente(mask):
    lab, n = componentes(mask)
    if n == 0:
        return mask
    tam = ndimage.sum(mask, lab, range(1, n + 1))
    return lab == (int(np.argmax(tam)) + 1)


# --- capivara ---------------------------------------------------------------

def mede_capivara(pasta):
    sp = 'capybara'
    p = paleta(sp)
    im = carrega(pasta, sp, 'boca-contente-0')
    sil = silhueta(im)
    x0, y0, x1, y1 = caixa(sil)
    alt = y1 - y0
    larguras = sil.sum(axis=1)
    # Cabeça: o terço de cima da silhueta. Largura = maior linha nele.
    cabeca_rows = slice(y0, y0 + int(alt * 0.4))
    cabeca_w = larguras[cabeca_rows].max()
    # Orelha: a cor `sombra` no quarto de cima (patas usam `sombraFria`).
    orelhas = perto(im, p['sombra'], 10)
    orelhas[y0 + int(alt * 0.3):, :] = False
    orelhas = ndimage.binary_opening(orelhas, iterations=2)
    lab, n = componentes(orelhas)
    larg_orelha = 0
    for i in range(1, n + 1):
        c = caixa(lab == i)
        if c and (c[2] - c[0]) * (c[3] - c[1]) > 40:
            larg_orelha = max(larg_orelha, c[2] - c[0])
    # Corpo: as linhas abaixo da cabeça em que a silhueta passa da largura
    # da cabeça (o barril é mais largo que o bloco da cabeça).
    rows = np.where(larguras > cabeca_w + 4 * U)[0]
    rows = rows[rows > y0 + alt * 0.3]
    if len(rows):
        corpo_top = rows.min()
        # Sem os pés: a última linha larga.
        corpo_w = larguras[corpo_top:].max()
        corpo_h = y1 - corpo_top
    else:
        corpo_w, corpo_h = 0, 1
    return {
        'orelha_sobre_cabeca': round(larg_orelha / cabeca_w, 3),
        'corpo_largura_sobre_altura': round(corpo_w / corpo_h, 2),
        'cabeca_w_u': round(cabeca_w / U, 1),
        'orelha_w_u': round(larg_orelha / U, 1),
    }


# --- lontra -----------------------------------------------------------------

def mede_lontra(pasta):
    sp = 'otter'
    p = paleta(sp)
    im = carrega(pasta, sp, 'boca-contente-0')
    sil = silhueta(im)
    x0, y0, x1, y1 = caixa(sil)
    alt = y1 - y0
    # Centro pela cabeça (simétrica): a cauda puxa a caixa para a direita.
    topo = sil[y0:y0 + int(alt * 0.25)]
    xs = np.where(topo.any(axis=0))[0]
    cx = (xs.min() + xs.max()) / 2
    # Linha cabeça/corpo: a linha mais estreita da silhueta entre 25 % e
    # 55 % da altura (o "pescoço" entre a cabeça chata e o corpo).
    larguras = sil.sum(axis=1)
    faixa = slice(y0 + int(alt * 0.25), y0 + int(alt * 0.55))
    pescoco_y = y0 + int(alt * 0.25) + int(np.argmin(larguras[faixa]))

    # Corpo: largura pela metade esquerda (a cauda sai pela direita).
    corpo_rows = sil[pescoco_y:y1 - int(8 * U)]
    esq = np.array([np.where(r)[0].min() if r.any() else cx for r in corpo_rows])
    corpo_w = 2 * (cx - esq.min())

    # Cauda: cor `sombraForte` abaixo da cabeça e à direita do centro.
    cauda = perto(im, p['sombraForte'], 12)
    cauda[:pescoco_y + int(4 * U), :] = False
    cauda[:, :int(cx)] = False
    cauda = ndimage.binary_opening(cauda, iterations=1)
    lab, n = componentes(cauda)
    cauda = maior_componente(cauda)
    runs = cauda.sum(axis=1)
    base_cauda = runs.max()

    # Mancha clara: garganta + peito (`garganta`) e lábio (`labio`).
    clara = perto(im, p['garganta'], 12) | perto(im, p['labio'], 12)
    clara = ndimage.binary_opening(clara, iterations=2)
    clara = maior_componente(clara)
    c = caixa(clara)
    cruza = c is not None and c[1] < pescoco_y < c[3]
    lum_clara = luminancia(mediana_cor(im, clara))
    dorso = perto(im, p['pelo'], 8)
    lum_dorso = luminancia(mediana_cor(im, dorso))

    # Bigodes: a coluna 33 u à esquerda do centro, entre o focinho (24 u) e
    # a borda da cabeça (41 u), na faixa da cabeça: o pixel mais claro é o
    # bigode (claro sobre o pelo escuro).
    melhor = 1.0
    for dx in (31, 33, 35, 37):
        col = int(cx - dx * U)
        faixa_y = slice(y0, pescoco_y)
        px = im[faixa_y, col, :3]
        a = im[faixa_y, col, 3]
        px = px[a > 200]
        if len(px) == 0:
            continue
        lum = luminancia(px)
        melhor = max(melhor, (lum.max() + 0.05) / (lum_dorso + 0.05))

    return {
        'base_cauda_sobre_corpo': round(base_cauda / corpo_w, 3),
        'cauda_componentes': int(n),
        'clara_sobre_dorso': round(lum_clara / lum_dorso, 2),
        'clara_cruza_cabeca_corpo': bool(cruza),
        'bigode_contraste': round(melhor, 2),
        'corpo_w_u': round(corpo_w / U, 1),
        'base_cauda_u': round(base_cauda / U, 1),
    }


# --- tracajá ----------------------------------------------------------------

def centro_da_esclera(im):
    branco = perto(im, BRANCO, 18) | perto(im, SUPERFICIE, 18)
    branco = ndimage.binary_opening(branco, iterations=2)
    ys, xs = np.where(branco)
    return xs.mean(), ys.mean(), branco


def mede_tracaja(pasta):
    sp = 'tortoise'
    p = paleta(sp)
    im = carrega(pasta, sp, 'boca-contente-0')
    rec = carrega(pasta, sp, 'pose-pescoco-recolhe')
    cx0, cy0, esclera = centro_da_esclera(im)
    cx1, cy1, _ = centro_da_esclera(rec)

    casco = np.zeros(im.shape[:2], bool)
    for k in ('casco', 'borda', 'vertebral', 'plastrao'):
        casco |= perto(im, p[k], 12)
    # A pele da cabeça fica a poucos tons do casco: só o que está abaixo
    # dos olhos + 30 u (o casco começa 35 u abaixo da linha dos olhos).
    casco[:int(cy0 + 30 * U), :] = False
    casco = maior_componente(ndimage.binary_opening(casco, iterations=2))
    c = caixa(casco)
    casco_w, casco_h = c[2] - c[0], c[3] - c[1]

    manchas = perto(im, p['mancha'], 14)
    cabeca = perto(im, p['pelo'], 8)
    cabeca[c[1] + int(6 * U):, :] = False  # só acima do casco
    contr = contraste(mediana_cor(im, manchas), mediana_cor(im, cabeca))

    # Olhos laterais: distância entre os centros das escleras sobre a
    # largura da cabeça (linhas da cabeça acima do casco).
    lab, n = componentes(esclera)
    centros = sorted(ndimage.center_of_mass(esclera, lab, range(1, n + 1)), key=lambda o: o[1])
    dist_olhos = centros[-1][1] - centros[0][1] if n >= 2 else 0
    sil = silhueta(im)
    sil[c[1] + int(2 * U):, :] = False
    cabeca_w = sil.sum(axis=1).max()

    return {
        'recolhe_dx_u': round(abs(cx1 - cx0) / U, 1),
        'recolhe_dy_u': round((cy1 - cy0) / U, 1),
        'casco_largura_sobre_altura': round(casco_w / casco_h, 2),
        'mancha_x_cabeca_contraste': round(float(contr), 2),
        'olhos_sobre_cabeca': round(dist_olhos / cabeca_w, 2),
        'casco_u': f'{casco_w / U:.0f}x{casco_h / U:.0f}',
    }


# --- folha antes/depois -------------------------------------------------------

def anim24(base):
    """A pasta de `atlas_anim24_test` que corresponde à do atlas."""
    return f'{BASE}_anim24_antes' if base == ANTES else f'{BASE}_anim24'


def folha(saida):
    especies = ['capybara', 'otter', 'tortoise']
    colunas = [
        ('contente', lambda b, sp: f'{b}/{sp}/boca-contente-0.png'),
        ('susto', lambda b, sp: f'{b}/{sp}/susto-10.png'),
        ('festa', lambda b, sp: f'{b}/{sp}/festa-10.png'),
        ('anda q6', lambda b, sp: f'{anim24(b)}/anda-{sp}/6.png'),
        ('nada q6', lambda b, sp: f'{b}/{sp}/agua-25.png'),
        ('filhote', lambda b, sp: f'{b}/{sp}/estagio-filhote.png'),
        ('jovem', lambda b, sp: f'{b}/{sp}/estagio-jovem.png'),
        ('pleno', lambda b, sp: f'{b}/{sp}/estagio-pleno.png'),
    ]
    cw, ch = 260, 220
    img = Image.new('RGB', (cw * len(colunas) + 90, ch * len(especies) * 2 + 24), 'white')
    d = ImageDraw.Draw(img)
    for j, (nome, _) in enumerate(colunas):
        d.text((90 + j * cw + 8, 6), nome, fill='black')
    for i, sp in enumerate(especies):
        for k, base in enumerate((ANTES, BASE)):
            y = 24 + (i * 2 + k) * ch
            d.text((6, y + 8), f'{sp}\n{"antes" if k == 0 else "depois"}', fill='black')
            for j, (_, f) in enumerate(colunas):
                caminho = f(base, sp)
                if not os.path.exists(caminho):
                    continue
                q = Image.open(caminho).convert('RGBA')
                q.thumbnail((cw, ch))
                img.paste(q, (90 + j * cw, y), q)
    img.save(saida, quality=85)
    return saida


def main():
    res = {
        'capybara': mede_capivara(BASE),
        'otter': mede_lontra(BASE),
        'tortoise': mede_tracaja(BASE),
    }
    cap = carrega(BASE, 'capybara', 'boca-contente-0')
    lon = carrega(BASE, 'otter', 'boca-contente-0')
    res['capybara']['iou_com_lontra'] = round(float(iou(cap, lon)), 3)
    aceite = {
        'capybara.orelha_sobre_cabeca <= 0.11': res['capybara']['orelha_sobre_cabeca'] <= 0.11,
        'capybara.corpo_largura_sobre_altura >= 1.3': res['capybara']['corpo_largura_sobre_altura'] >= 1.3,
        'capybara.iou_com_lontra <= 0.70': res['capybara']['iou_com_lontra'] <= 0.70,
        'otter.base_cauda_sobre_corpo >= 0.30': res['otter']['base_cauda_sobre_corpo'] >= 0.30,
        'otter.cauda_componentes == 1': res['otter']['cauda_componentes'] == 1,
        'otter.clara_sobre_dorso >= 1.8': res['otter']['clara_sobre_dorso'] >= 1.8,
        'otter.clara_cruza_cabeca_corpo': res['otter']['clara_cruza_cabeca_corpo'],
        'otter.bigode_contraste >= 3': res['otter']['bigode_contraste'] >= 3,
        'tortoise.recolhe_dx_u >= 14': res['tortoise']['recolhe_dx_u'] >= 14,
        'tortoise.recolhe_dy_u >= 8': res['tortoise']['recolhe_dy_u'] >= 8,
        'tortoise.casco_largura_sobre_altura >= 1.6': res['tortoise']['casco_largura_sobre_altura'] >= 1.6,
        'tortoise.mancha_x_cabeca_contraste >= 4.5': res['tortoise']['mancha_x_cabeca_contraste'] >= 4.5,
        'tortoise.olhos_sobre_cabeca >= 0.60': res['tortoise']['olhos_sobre_cabeca'] >= 0.60,
    }
    print(json.dumps(res, indent=2, ensure_ascii=False))
    for k, v in aceite.items():
        print(('OK   ' if v else 'FALHA'), k)
    if os.path.isdir(ANTES):
        print('folha:', folha(f'{BASE}/anatomia_abc.jpg'))
    return 0 if all(aceite.values()) else 1


if __name__ == '__main__':
    sys.exit(main())

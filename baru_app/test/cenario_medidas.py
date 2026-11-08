#!/usr/bin/env python3
"""Medidas do cenário (laudo 35, achados CEN-*) sobre as capturas de
`cenario_nov_test.dart` em `build/cenario_nov/`.

    python3 test/cenario_medidas.py [build/cenario_nov] [build/cenario_nov_antes]

Imprime, por período: cor média do céu alto e baixo (hex), ΔE entre os
períodos, luminância média da noite em relação ao dia e pontos de luz,
contraste do pelo da capivara com o chão, número de bandas de valor nas
chapadas, água (matiz e ΔL) e se a lanterna tem apoio. Com a segunda pasta,
monta `folha.jpg` (antes × depois) na primeira.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

PASTA = sys.argv[1] if len(sys.argv) > 1 else 'build/cenario_nov'
ANTES = sys.argv[2] if len(sys.argv) > 2 else None
PERIODOS = ['amanhecer', 'dia', 'entardecer', 'noite']
PELO = '#8A5344'
PELO_DOMINANTE = '#B07A4E'


def hexa(rgb):
    r, g, b = [int(round(float(v))) for v in rgb[:3]]
    return '#%02X%02X%02X' % (r, g, b)


def de_hexa(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


def linear(c):
    c = np.asarray(c, dtype=float) / 255.0
    return np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def luminancia(rgb):
    lin = linear(rgb)
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


def contraste(a, b):
    la, lb = luminancia(a), luminancia(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def lab(rgb):
    lin = linear(rgb)
    m = np.array([[0.4124, 0.3576, 0.1805],
                  [0.2126, 0.7152, 0.0722],
                  [0.0193, 0.1192, 0.9505]])
    xyz = lin @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.array([116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2])])


def delta_e(a, b):
    return float(np.linalg.norm(lab(a) - lab(b)))


def matiz(rgb):
    r, g, b = [float(v) / 255 for v in rgb[:3]]
    mx, mn = max(r, g, b), min(r, g, b)
    if mx == mn:
        return 0.0
    d = mx - mn
    if mx == r:
        h = (g - b) / d % 6
    elif mx == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    return h * 60


def carrega(nome, pasta=PASTA):
    im = Image.open(os.path.join(pasta, nome)).convert('RGBA')
    return np.asarray(im).astype(float)


def composto(periodo, pasta=PASTA):
    f = Image.open(os.path.join(pasta, f'fundo-{periodo}.png')).convert('RGBA')
    fr = Image.open(os.path.join(pasta, f'frente-{periodo}.png')).convert('RGBA')
    f.alpha_composite(fr)
    return f


def mediana(img, x0, x1, y0, y1):
    rec = img[int(y0):int(y1), int(x0):int(x1), :3].reshape(-1, 3)
    return np.median(rec, axis=0)


def media(img, x0, x1, y0, y1):
    rec = img[int(y0):int(y1), int(x0):int(x1), :3].reshape(-1, 3)
    return rec.mean(axis=0)


def bandas_de_valor(img, x, y0, y1):
    """Quantos patamares de luminância distintos há na coluna [x] entre
    y0 e y1 (passos ≥ 0,03 entre patamares de ≥ 6 px)."""
    col = luminancia(img[int(y0):int(y1), int(x), :3])
    patamares = []
    atual = [col[0]]
    for v in col[1:]:
        if abs(v - np.mean(atual)) < 0.012:
            atual.append(v)
        else:
            if len(atual) >= 6:
                patamares.append(float(np.mean(atual)))
            atual = [v]
    if len(atual) >= 6:
        patamares.append(float(np.mean(atual)))
    distintos = []
    for p in patamares:
        if all(abs(p - d) >= 0.03 for d in distintos):
            distintos.append(p)
    return distintos


def lanterna(img, geo):
    """Acha o balão laranja e procura, perto dele, o poste: a maior tira
    vertical de madeira; depois confere o braço que liga o poste à coluna
    do balão e o fio entre o braço e o balão (CEN-01)."""
    rgb = img[..., :3]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    H, W = rgb.shape[:2]
    laranja = (r > 180) & (g > 70) & (g < 170) & (b < 110) & (r - b > 90)
    laranja[: int(H * 0.58)] = False  # o sol baixo também é laranja
    ys, xs = np.nonzero(laranja)
    if len(xs) < 200:
        return None, 'balão não encontrado'
    cx, cy = int(np.median(xs)), int(np.median(ys))
    sel = (np.abs(xs - cx) < 150) & (np.abs(ys - cy) < 150)
    xs, ys = xs[sel], ys[sel]
    topo = int(ys.min())
    cx = int(np.median(xs))
    madeira = ((r >= 100) & (r <= 185) & (g >= 70) & (g <= 150) & (b >= 40) & (b <= 120)
               & (r - b >= 40) & (r - g >= 15))
    y0 = max(0, topo - 400)
    y1 = min(H, int(geo['linhaDagua'] * H) + 150)
    melhor = (0, None, None, None)
    for x in range(max(1, cx - 200), min(W - 1, cx + 200)):
        col = madeira[y0:y1, x - 1:x + 2].any(axis=1)
        run = 0
        for i, v in enumerate(col):
            if v:
                run += 1
                if run > melhor[0]:
                    melhor = (run, x, y0 + i - run + 1, y0 + i)
            else:
                run = 0
    run, px, ya, yb = melhor
    if run < 300:
        return None, f'nenhum poste vertical perto do balão (maior tira de madeira: {run} px)'
    faixa = madeira[ya:ya + 40, min(cx, px):max(cx, px) + 1].any(axis=0)
    braco = float(faixa.mean())
    col = rgb[ya + 40:max(ya + 41, topo - 20), cx - 3:cx + 4]
    fio = int((col.sum(axis=2) < 420).any(axis=1).sum())
    return dict(balao=(cx, topo), poste_x=int(px), poste_de=int(ya), poste_ate=int(yb),
                poste_altura=int(run), braco=braco, fio_px=fio,
                linha_dagua=int(geo['linhaDagua'] * H)), None


def astro(img, periodo, geo):
    """O centro do sol/lua: o aglomerado mais claro (ou mais laranja) no céu."""
    rgb = img[..., :3]
    h = img.shape[0]
    ceu = rgb[: int(h * 0.6)]
    if periodo == 'noite':
        m = (ceu.min(axis=2) > 200)
    elif periodo == 'dia':
        m = (ceu[..., 0] > 240) & (ceu[..., 1] > 190) & (ceu[..., 2] < 150)
    else:
        m = (ceu[..., 0] > 235) & (ceu[..., 1] < 175) & (ceu[..., 2] < 110)
    ys, xs = np.nonzero(m)
    if len(xs) < 50:
        return None
    # Tira pontos isolados (estrelas): fica com a vizinhança da mediana.
    cx, cy = np.median(xs), np.median(ys)
    sel = (np.abs(xs - cx) < 200) & (np.abs(ys - cy) < 200)
    return float(np.mean(xs[sel])), float(np.mean(ys[sel]))




def conta_estrelas(img):
    rgb = img[..., :3]
    h = rgb.shape[0]
    lum = luminancia(rgb[: int(h * 0.45)])
    claro = lum > 0.35
    # Componentes conexos simples (4-vizinhança), sem scipy.
    vis = np.zeros_like(claro, dtype=bool)
    n = 0
    ys, xs = np.nonzero(claro)
    for y0, x0 in zip(ys, xs):
        if vis[y0, x0]:
            continue
        pilha = [(y0, x0)]
        vis[y0, x0] = True
        tam = 0
        sy = sx = 0
        while pilha:
            y, x = pilha.pop()
            tam += 1
            sy += y
            sx += x
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < claro.shape[0] and 0 <= xx < claro.shape[1] and claro[yy, xx] and not vis[yy, xx]:
                    vis[yy, xx] = True
                    pilha.append((yy, xx))
        if 2 <= tam <= 400:
            cy, cx = sy // tam, sx // tam
            y0_, y1_ = max(0, cy - 12), min(lum.shape[0], cy + 13)
            x0_, x1_ = max(0, cx - 12), min(lum.shape[1], cx + 13)
            viz = np.median(lum[y0_:y1_, x0_:x1_])
            if (lum[cy, cx] + 0.05) / (viz + 0.05) > 3:
                n += 1
    return n


def main():
    geo = json.load(open(os.path.join(PASTA, 'geometria.json')))
    W, H = None, None
    ceus = {}
    chaos = {}
    lums = {}
    print(f'== medidas em {PASTA} ==')
    for p in PERIODOS:
        img = carrega(f'fundo-{p}.png')
        H, W = img.shape[:2]
        alto = media(img, 0, W, 0, H * 0.02)
        baixo = mediana(img, W * 0.2, W * 0.45, H * 0.36, H * 0.385)
        ceus[p] = (alto, baixo)
        chao_y = geo['chao'] * H
        chao = media(img, W * 0.05, W * 0.55, chao_y - 70, chao_y - 10)
        chaos[p] = chao
        lums[p] = float(luminancia(img[..., :3]).mean())
        c1 = contraste(de_hexa(PELO), chao)
        c2 = contraste(de_hexa(PELO_DOMINANTE), chao)
        bandas = bandas_de_valor(img, W * 0.3, H * 0.4, geo['horizonte'] * H + 60)
        print(f'[{p}] céu alto {hexa(alto)}  céu baixo {hexa(baixo)}  '
              f'chão {hexa(chao)} (L {luminancia(chao):.3f})  '
              f'contraste pelo {PELO}×chão {c1:.2f}:1  {PELO_DOMINANTE}×chão {c2:.2f}:1  '
              f'bandas no horizonte {len(bandas)} {[round(b, 3) for b in bandas]}  '
              f'L média {lums[p]:.3f}')
        # Água: matiz e ΔL entre o alto e o fundo da lagoa.
        beira_x = geo['beira'] * W
        agua_topo = media(img, beira_x + 300, W - 60, geo['linhaDagua'] * H - 60, geo['linhaDagua'] * H - 30)
        agua_fundo = media(img, beira_x + 300, W - 60, H * 0.97, H * 0.995)
        print(f'    água: alto {hexa(agua_topo)} (H {matiz(agua_topo):.0f}°, L {luminancia(agua_topo):.3f})  '
              f'fundo {hexa(agua_fundo)} (L {luminancia(agua_fundo):.3f})  ΔL {abs(luminancia(agua_topo) - luminancia(agua_fundo)):.3f}')
        lan, erro = lanterna(img, geo)
        a = astro(img, p, geo)
        if lan:
            d = None
            if a:
                d = ((a[0] - lan['balao'][0]) ** 2 + (a[1] - lan['balao'][1] - 60) ** 2) ** 0.5 / 3
            ok = lan['poste_altura'] >= 300 and lan['braco'] > 0.8 and lan['fio_px'] > 0
            print(f'    lanterna: balão topo {lan["balao"]}  poste x={lan["poste_x"]} de y={lan["poste_de"]} a '
                  f'{lan["poste_ate"]} ({lan["poste_altura"]} px; linha d\'água y={lan["linha_dagua"]})  '
                  f'braço contínuo {lan["braco"]:.0%}  fio {lan["fio_px"]} px  → apoio {"OK" if ok else "FALHA"}'
                  + (f'; distância astro–balão {d:.0f} px (em 1600)' if d else ''))
        else:
            print(f'    lanterna: {erro}')
        if a:
            print(f'    astro em ({a[0] / 3:.0f}, {a[1] / 3:.0f}) de 1600×900 → y = {a[1] / H:.2f} da altura')
        if p == 'noite':
            cx, cy = int(a[0]), int(a[1])
            centro = img[cy, cx, :3]
            print(f'    lua: pixel central {hexa(centro)}  estrelas com contraste > 3:1: {conta_estrelas(img)}')
            # luar na água: coluna sob a lua, dentro da lagoa.
            col = luminancia(img[int(geo["linhaDagua"] * H):H, cx - 60:cx + 60, :3])
            viz = luminancia(img[int(geo["linhaDagua"] * H):H, cx + 200:cx + 320, :3])
            print(f'    luar na água: L máx. sob a lua {col.max():.3f}  água ao lado (mediana) {np.median(viz):.3f}')
            claros = (luminancia(img[..., :3]) > 0.8).sum()
            print(f'    pontos de luz (L > 0,8): {claros} px')
    print()
    print(f'ΔE céu alto dia×entardecer {delta_e(ceus["dia"][0], ceus["entardecer"][0]):.1f} (≥ 20)  '
          f'dia×noite {delta_e(ceus["dia"][0], ceus["noite"][0]):.1f} (≥ 40)  '
          f'amanhecer×entardecer {delta_e(ceus["amanhecer"][0], ceus["entardecer"][0]):.1f} (≥ 30)')
    print(f'ΔE céu baixo dia×entardecer {delta_e(ceus["dia"][1], ceus["entardecer"][1]):.1f}  '
          f'dia×noite {delta_e(ceus["dia"][1], ceus["noite"][1]):.1f}')
    print(f'luminância média noite/dia: {lums["noite"] / lums["dia"]:.3f} (≤ 0,2)')
    for p in PERIODOS:
        img = carrega(f'fundo-{p}.png')
        # Chapada × céu logo acima da crista.
        x = int(W * 0.3)
        col = img[int(H * 0.3):int(geo['horizonte'] * H), x, :3]
        lum = luminancia(col)
        # A primeira queda de luminância ≥ 0,03 de cima para baixo é a crista.
        for i in range(10, len(lum) - 10):
            if abs(lum[i + 5] - lum[i - 5]) > 0.03:
                ceu = col[i - 12]
                chap = col[i + 12]
                print(f'[{p}] ΔE(chapada, céu) na coluna x=0,3w: {delta_e(chap, ceu):.1f} '
                      f'(céu {hexa(ceu)}, chapada {hexa(chap)})')
                break

    if ANTES and os.path.isdir(ANTES):
        folha(ANTES, PASTA)


def folha(antes, depois):
    cel = (800, 450)
    f = Image.new('RGB', (cel[0] * 2 + 30, (cel[1] + 30) * 4 + 10), 'white')
    d = ImageDraw.Draw(f)
    for i, p in enumerate(PERIODOS):
        y = 10 + i * (cel[1] + 30)
        for j, pasta in enumerate((antes, depois)):
            x = 10 + j * (cel[0] + 10)
            try:
                im = composto(p, pasta).convert('RGB').resize(cel, Image.LANCZOS)
                f.paste(im, (x, y + 20))
            except FileNotFoundError:
                pass
            d.text((x, y + 4), f'{"antes" if j == 0 else "depois"} — {p}', fill='black')
    saida = os.path.join(depois, 'folha.jpg')
    f.save(saida, quality=88)
    print(f'folha: {saida}')


if __name__ == '__main__':
    main()

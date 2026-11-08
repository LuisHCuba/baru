#!/usr/bin/env python3
"""Medidas do lote "anatomia: Mel, Faísca e Bolota" (laudo 33) sobre as
capturas de `atlas_novelinha_test.dart`.

Uso:
    CAPTURAS=1 ESPECIES=cat,fox,frenchie flutter test test/atlas_novelinha_test.dart
    python3 test/anatomia_medidas_c.py [build/atlas] [build/atlas_antes]

Medidas (no quadro `boca-contente-0`, salvo nota):
- raposa: altura visível da orelha (ponta → topo do crânio) / altura da
  cabeça (topo do crânio → pescoço): ≥ 0,55 (laudo 33 §1.3); ponta branca
  da cauda presente (≥ 300 px quase brancos na metade direita, abaixo da
  linha dos olhos);
- gata: largura do focinho (região `claro` sob os olhos) / largura da
  cabeça (laudo: pequeno, ≤ 0,45); contraste bigode × pelo ≥ 3 : 1 (WCAG);
  bigodes saindo da silhueta da cabeça (≥ 12 px de cada lado);
- buldogue: largura do peito / largura da cabeça (laudo: "peito largo",
  ≥ 1,1);
- IoU das silhuetas entre as três espécies, alinhadas pelo centro da caixa
  (laudo 06; ≤ 0,70).
Também monta `anatomia_mfb.jpg` (antes × depois) na pasta das capturas.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

BASE = sys.argv[1] if len(sys.argv) > 1 else 'build/atlas'
ANTES = sys.argv[2] if len(sys.argv) > 2 else 'build/atlas_antes'
QUADROS = ['boca-contente-0', 'boca-saudade-0', 'estagio-filhote', 'estagio-jovem', 'pose-deita']


def carrega(base, sp, nome):
    return np.asarray(Image.open(f'{base}/{sp}/{nome}.png').convert('RGBA')).astype(np.int32)


def silhueta(im):
    return im[:, :, 3] > 40


def lum(rgb):
    c = np.asarray(rgb, dtype=float) / 255
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def contraste(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def cor_dominante(im, mask):
    px = im[:, :, :3][mask]
    q = (px // 8) * 8
    vals, counts = np.unique(q, axis=0, return_counts=True)
    return vals[counts.argmax()]


def larguras(mask):
    """Pixels cheios da silhueta por linha. Contagem, e não o vão entre as
    bordas: na linha das pontas das orelhas o vão é a cabeça inteira e a
    contagem é quase zero — e é a contagem que diz onde o crânio começa."""
    return mask.sum(axis=1).astype(int)


def caixa(mask):
    ys, xs = np.where(mask)
    return xs.min(), ys.min(), xs.max(), ys.max()


def iou(a, b):
    """Alinha pelo centro da caixa e compara."""
    def recorta(m):
        x0, y0, x1, y1 = caixa(m)
        return m[y0:y1 + 1, x0:x1 + 1]
    ra, rb = recorta(a), recorta(b)
    h = max(ra.shape[0], rb.shape[0])
    w = max(ra.shape[1], rb.shape[1])
    def centra(m):
        out = np.zeros((h, w), dtype=bool)
        oy, ox = (h - m.shape[0]) // 2, (w - m.shape[1]) // 2
        out[oy:oy + m.shape[0], ox:ox + m.shape[1]] = m
        return out
    ca, cb = centra(ra), centra(rb)
    return (ca & cb).sum() / (ca | cb).sum()


def orelha_sobre_cabeca_raposa(im):
    """Topo da orelha → topo do crânio (linha em que a largura passa de 70 %
    da largura máxima da cabeça), dividido pela altura da cabeça (topo do
    crânio → queixo, onde a largura volta a crescer para o corpo)."""
    m = silhueta(im)
    w = larguras(m)
    x0, y0, x1, y1 = caixa(m)
    # Região da cabeça: as linhas até a metade da altura da silhueta.
    meio = (y0 + y1) // 2
    wmax = w[y0:meio].max()
    # O topo do crânio: a primeira linha em que a silhueta é um bloco só
    # (acima dele as duas orelhas são dois blocos com o vão entre elas).
    def blocos(row):
        return int(((row[1:] != row[:-1]) & row[1:]).sum() + (1 if row[0] else 0))
    topo_cranio = next(
        y for y in range(y0, meio) if blocos(m[y]) == 1 and w[y] >= 0.3 * wmax
    )
    # O queixo é o pescoço: a linha mais estreita entre a linha mais cheia
    # da cabeça e a linha mais cheia do corpo (que vem abaixo dela).
    h = y1 - y0
    cheia_cabeca = int(np.argmax(w[topo_cranio:topo_cranio + int(0.33 * h)])) + topo_cranio
    cheia_corpo = int(np.argmax(w[cheia_cabeca + 10:y1])) + cheia_cabeca + 10
    queixo = int(np.argmin(w[cheia_cabeca:cheia_corpo])) + cheia_cabeca
    return (topo_cranio - y0) / (queixo - topo_cranio), (y0, topo_cranio, queixo)


def focinho_da_gata(im):
    """Largura da mancha `claro` sob os olhos (as almofadas dos bigodes)
    sobre a largura da cabeça."""
    m = silhueta(im)
    x0, y0, x1, y1 = caixa(m)
    w = larguras(m)
    meio = (y0 + y1) // 2
    pelo = cor_dominante(im, m)
    # Linhas da cabeça: entre o topo do crânio e a metade.
    wmax = w[y0:meio].max()
    topo = next(y for y in range(y0, meio) if w[y] >= 0.7 * wmax)
    cab = np.zeros_like(m)
    cab[topo:meio] = m[topo:meio]
    rgb = im[:, :, :3]
    # Mais claro que o pelo em ≥ 25 de luminância média e não branco (esclera).
    media = rgb.mean(axis=2)
    claro = cab & (media > pelo.mean() + 22) & (media < 225) & (im[:, :, 3] > 200)
    # Só a faixa central (|x − cx| < 25 % da largura da cabeça) e abaixo da
    # linha dos olhos (metade inferior da cabeça).
    cx = (x0 + x1) // 2
    ys, xs = np.where(claro)
    sel = (abs(xs - cx) < 0.3 * wmax) & (ys > topo + 0.45 * (meio - topo))
    if not sel.any():
        return 0.0, wmax
    return (xs[sel].max() - xs[sel].min() + 1) / wmax, wmax


def bigodes_da_gata(im):
    """Pixels fora da silhueta "cheia" da cabeça na altura dos bigodes
    (fios finos) e o contraste da cor deles com o pelo."""
    m = silhueta(im)
    x0, y0, x1, y1 = caixa(m)
    w = larguras(m)
    meio = (y0 + y1) // 2
    pelo = cor_dominante(im, m)
    opaco = im[:, :, 3] > 200
    # Linhas em que a silhueta tem "fios": a largura total (alpha > 40) passa
    # a largura dos pixels opacos contíguos ao centro em ≥ 12 px de um lado.
    cx = (x0 + x1) // 2
    wmax = w[y0:meio].max()
    topo = next(y for y in range(y0, meio) if w[y] >= 0.7 * wmax)
    melhor = 0
    cor = None
    # Só do lado esquerdo (a cauda sai pela direita), abaixo das orelhas e
    # acima do queixo (a sombra borrada do queixo também passa de alpha 40).
    # Na janela 0,4–0,8 da altura da cabeça: acima disso as orelhas, dos
    # dois lados do crânio, contariam como "fora".
    for y in range(int(topo + 0.4 * (meio - topo)), int(topo + 0.8 * (meio - topo))):
        if not opaco[y, cx]:
            continue
        xs = np.where(opaco[y])[0]
        if len(xs) == 0:
            continue
        # Bloco central contíguo (a cabeça).
        esq = cx
        while esq - 1 >= 0 and opaco[y, esq - 1]:
            esq -= 1
        dir_ = cx
        while dir_ + 1 < m.shape[1] and opaco[y, dir_ + 1]:
            dir_ += 1
        fora = np.where(m[y])[0]
        lado = esq - fora.min()
        if lado > melhor:
            melhor = lado
            # A cor do fio: o pixel mais opaco fora do bloco, à esquerda.
            cand = [x for x in fora if x < esq - 2]
            if cand:
                x = max(cand, key=lambda x: im[y, x, 3])
                cor = im[y, x, :3]
    c = contraste(cor, pelo) if cor is not None else 0.0
    return melhor, c, pelo, cor


def peito_sobre_cabeca(im):
    m = silhueta(im)
    w = larguras(m)
    x0, y0, x1, y1 = caixa(m)
    h = y1 - y0
    cab = w[int(y0 + 0.25 * h):int(y0 + 0.5 * h)].max()
    peito = w[int(y0 + 0.55 * h):int(y0 + 0.9 * h)].max()
    return peito / cab, cab, peito


def ponta_branca(im):
    m = silhueta(im)
    x0, y0, x1, y1 = caixa(m)
    rgb = im[:, :, :3]
    branco = (rgb.min(axis=2) > 215) & (im[:, :, 3] > 200)
    cx = (x0 + x1) // 2
    branco[:, :cx + 40] = False
    branco[:int(y0 + 0.35 * (y1 - y0))] = False
    return int(branco.sum())


def folha(saida):
    linhas = []
    for sp in ['cat', 'fox', 'frenchie']:
        for base in [ANTES, BASE]:
            ims = []
            for q in QUADROS:
                p = f'{base}/{sp}/{q}.png'
                ims.append(Image.open(p).convert('RGBA') if os.path.exists(p) else None)
            linhas.append((sp, 'antes' if base == ANTES else 'depois', ims))
    w, h = next(i for _, _, ims in linhas for i in ims if i).size
    esc = 0.5
    cw, ch = int(w * esc), int(h * esc)
    out = Image.new('RGB', (cw * len(QUADROS) + 90, ch * len(linhas)), (237, 227, 210))
    d = ImageDraw.Draw(out)
    for i, (sp, rot, ims) in enumerate(linhas):
        d.text((6, i * ch + 8), f'{sp}\n{rot}', fill=(62, 47, 35))
        for j, im in enumerate(ims):
            if im is None:
                continue
            im = im.resize((cw, ch))
            out.paste(im, (90 + j * cw, i * ch), im)
    out.convert('RGB').save(saida, quality=88)


def main():
    ok = True
    for rot, base in [('ANTES', ANTES), ('DEPOIS', BASE)]:
        if not os.path.isdir(base):
            continue
        print(f'--- {rot} ({base})')
        fox = carrega(base, 'fox', 'boca-contente-0')
        cat = carrega(base, 'cat', 'boca-contente-0')
        fr = carrega(base, 'frenchie', 'boca-contente-0')

        r, _ = orelha_sobre_cabeca_raposa(fox)
        print(f'raposa  orelha visível/cabeça = {r:.2f}  (≥ 0,55; laudo 33 §1.3)')
        pb = ponta_branca(fox)
        print(f'raposa  ponta branca da cauda = {pb} px  (≥ 300)')

        f, wcab = focinho_da_gata(cat)
        print(f'gata    focinho/cabeça        = {f:.2f}  (≤ 0,45; cabeça {wcab} px)')
        fora, c, pelo, cor = bigodes_da_gata(cat)
        print(f'gata    bigode fora da cabeça = {fora} px  (≥ 12); contraste bigode×pelo = {c:.2f}:1  (≥ 3)'
              f'  pelo={tuple(int(v) for v in pelo)} bigode={None if cor is None else tuple(int(v) for v in cor)}')

        p, cab, peito = peito_sobre_cabeca(fr)
        print(f'buldogue peito/cabeça         = {p:.2f}  (≥ 1,1; cabeça {cab}, peito {peito})')

        s = {'cat': silhueta(cat), 'fox': silhueta(fox), 'frenchie': silhueta(fr)}
        pares = [('cat', 'fox'), ('cat', 'frenchie'), ('fox', 'frenchie')]
        ious = {f'{a}×{b}': iou(s[a], s[b]) for a, b in pares}
        print('IoU     ' + '  '.join(f'{k} {v:.3f}' for k, v in ious.items()) + '  (≤ 0,70)')
        if rot == 'DEPOIS':
            ok &= r >= 0.55 and pb >= 300 and f <= 0.45 and fora >= 12 and c >= 3 and p >= 1.1
            ok &= max(ious.values()) <= 0.70
    saida = f'{BASE}/anatomia_mfb.jpg'
    folha(saida)
    print(f'folha: {saida}')
    print('OK' if ok else 'FALHOU')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()

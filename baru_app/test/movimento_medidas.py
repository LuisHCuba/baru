#!/usr/bin/env python3
"""Medidas dos ciclos de movimento (lote "movimento", auditoria rodada 1).

Lê as folhas capturadas por `CAPTURAS=1 flutter test test/atlas_anim24_test.dart`
(`build/atlas_anim24/<ciclo>-<especie>/<q>.png`) e pelo
`test/atlas_vida_test.dart` (`build/atlas_vida/vida-<especie>-0/<q>.png`) e
imprime, por espécie e ciclo, os números dos critérios de aceite do laudo 34
e dos achados MOV-*:

  anda/corre/nada/voa/brinca (24 quadros)
    pataV      deslocamento vertical máximo do ponto mais baixo de cada lado
               (esq | dir), em px — a pata LEVANTA (aceite ≥ 10 % da altura
               do corpo para quem saltita);
    pataH      deslocamento horizontal do centroide da pata plantada
               (≤ 4 px: a pata não desliza);
    corpoH     variação da altura da máscara (máx/mín − 1), em % (≤ 6 % no
               andar: squash & stretch com volume, não balão);
    salto      maior diferença entre quadros vizinhos ÷ média (≤ 2: senoide
               suave, sem tranco);
    emenda     diferença 23→0 ÷ média dos vizinhos (≤ 1: o laço fecha);
    cabeca     atraso, em quadros, do pico da cabeça (topo da máscara) em
               relação ao pico do corpo (base da barriga) — 1–2 quadros;
    topo       curso vertical do topo da máscara em px (cabeça sobe/desce);
    rola       amplitude do ângulo do eixo principal da máscara (graus):
               o gingado/rolagem lateral;
    metades    diferença média de alfa entre o quadro i e i+12 (≥ 20/255:
               as duas metades do ciclo não são iguais).

  vida-<sp>-0 (120 quadros)
    emenda     diferença 119→0 ÷ média do laço (≤ 2);
    piscadas   grupos de quadros com o olho fechando (duração 3–5 quadros
               a 24 fps ≈ 5–9 a 30 fps), lidos de piscas.json;
    respira    amplitude do topo da máscara (px) fora das piscadas.

Uso: python3 test/movimento_medidas.py [build/atlas_anim24] [build/atlas_vida]
"""
import json
import math
import os
import re
import sys

import numpy as np
from PIL import Image

CICLOS = ('anda', 'corre', 'nada', 'voa', 'brinca')
ESPECIES = ('capybara', 'otter', 'tortoise', 'owl', 'axolotl', 'penguin',
            'cat', 'fox', 'frenchie')


def quadros(pasta):
    arqs = sorted((f for f in os.listdir(pasta) if f.endswith('.png')),
                  key=lambda f: int(f[:-4]))
    return [np.asarray(Image.open(os.path.join(pasta, f)).convert('RGBA'))
            for f in arqs]


def mascara(q, limiar=100):
    # 100 e não 40: a poeira da corrida (alfa ≤ 82) e os anéis da água ficam
    # fora, senão viram "pata" na linha do chão.
    return q[..., 3] > limiar


def bbox(m):
    ys, xs = np.nonzero(m)
    if len(ys) == 0:
        return None
    return ys.min(), ys.max(), xs.min(), xs.max()


def mais_baixo(m, x0, x1):
    """Linha mais baixa da máscara entre as colunas x0..x1 (ou nan)."""
    sub = m[:, x0:x1]
    ys = np.nonzero(sub.any(axis=1))[0]
    return float(ys.max()) if len(ys) else math.nan


def centroide_da_base(m, x0, x1, linhas=6):
    """Centroide x das `linhas` mais baixas da máscara entre x0..x1."""
    sub = m[:, x0:x1]
    ys = np.nonzero(sub.any(axis=1))[0]
    if not len(ys):
        return math.nan
    base = sub[ys.max() - linhas + 1: ys.max() + 1]
    yy, xx = np.nonzero(base)
    return float(xx.mean()) + x0


def angulo_principal(m):
    ys, xs = np.nonzero(m)
    if len(xs) < 10:
        return 0.0
    x = xs - xs.mean()
    y = ys - ys.mean()
    cxx, cyy, cxy = (x * x).mean(), (y * y).mean(), (x * y).mean()
    # Ângulo do eixo de maior variância em relação à vertical (graus).
    ang = 0.5 * math.atan2(2 * cxy, cxx - cyy)
    vertical = ang - math.pi / 2
    while vertical > math.pi / 2:
        vertical -= math.pi
    while vertical < -math.pi / 2:
        vertical += math.pi
    return math.degrees(vertical)


def diff(a, b):
    """Diferença média de alfa entre dois quadros (0..255)."""
    return float(np.abs(a[..., 3].astype(int) - b[..., 3].astype(int)).mean())


def atraso_circular(i_cabeca, i_corpo, n):
    d = (i_cabeca - i_corpo) % n
    return d if d <= n // 2 else d - n


def mede_ciclo(pasta):
    qs = quadros(pasta)
    n = len(qs)
    ms = [mascara(q) for q in qs]
    caixas = [bbox(m) for m in ms]
    if any(c is None for c in caixas):
        return None
    h, w = ms[0].shape
    cx = w // 2
    topos = np.array([c[0] for c in caixas], float)
    # A pata de cada lado: o ponto mais baixo do terço externo da máscara.
    esq = np.array([mais_baixo(m, 0, cx - 8) for m in ms])
    dir_ = np.array([mais_baixo(m, cx + 8, w) for m in ms])
    barriga = np.array([mais_baixo(m, cx - 8, cx + 8) for m in ms])
    # A altura do CORPO: do topo da cabeça à base da barriga (faixa central),
    # sem as patas — elas levantam, e a caixa inteira encurtaria com isso.
    alturas = barriga - topos
    pata_v = (np.nanmax(esq) - np.nanmin(esq), np.nanmax(dir_) - np.nanmin(dir_))
    # Pata plantada: os quadros em que aquele lado está a ≤ 2 px do seu ponto
    # mais baixo; o centroide dela não deve andar de lado.
    def deslize(lado):
        plantada = lado >= np.nanmax(lado) - 2
        xs = [centroide_da_base(m, 0, cx - 8) if lado is esq
              else centroide_da_base(m, cx + 8, w)
              for m, p in zip(ms, plantada) if p]
        xs = [x for x in xs if not math.isnan(x)]
        return (max(xs) - min(xs)) if len(xs) > 1 else 0.0
    pata_h = (deslize(esq), deslize(dir_))
    diffs = np.array([diff(qs[i], qs[(i + 1) % n]) for i in range(n)])
    vizinhos = diffs[:-1]
    media = vizinhos.mean() if vizinhos.mean() > 0 else 1e-9
    emenda = diffs[-1] / media
    # A emenda contra os passos vizinhos dela (22→23 e 0→1): é o que diz se
    # o quadro 23→0 tem um pulo em relação ao movimento local.
    emenda_viz = diffs[-1] / max(1e-9, (diffs[-2] + diffs[0]) / 2)
    salto = vizinhos.max() / media
    # Pico da cabeça (topo mais alto = y mínimo) e do corpo (barriga mais
    # alta = y mínimo), nas duas metades.
    atrasos = []
    for ini in (0, n // 2):
        fim = ini + n // 2
        ic = ini + int(np.argmin(topos[ini:fim]))
        ib = ini + int(np.nanargmin(barriga[ini:fim]))
        atrasos.append(atraso_circular(ic, ib, n))
    angulos = np.array([angulo_principal(m) for m in ms])
    rola = angulos.max() - angulos.min()
    metades = np.mean([diff(qs[i], qs[(i + n // 2) % n]) for i in range(n // 2)])
    borda = min(topos.min(), h - 1 - max(c[1] for c in caixas),
                min(c[2] for c in caixas), w - 1 - max(c[3] for c in caixas))
    return dict(
        n=n,
        pataV=pata_v,
        pataH=pata_h,
        corpoH=(alturas.max() / alturas.min() - 1) * 100,
        alturaMedia=alturas.mean(),
        salto=salto,
        emenda=emenda,
        emendaViz=emenda_viz,
        cabeca=atrasos,
        topo=topos.max() - topos.min(),
        rola=rola,
        metades=metades,
        borda=borda,
        diffMedia=media,
    )


def mede_vida(pasta, piscas):
    qs = quadros(pasta)
    n = len(qs)
    ms = [mascara(q) for q in qs]
    caixas = [bbox(m) for m in ms]
    diffs = np.array([diff(qs[i], qs[(i + 1) % n]) for i in range(n)])
    media = diffs[:-1].mean()
    emenda = diffs[-1] / media if media > 0 else math.nan
    grupos = []
    for q in piscas:
        if grupos and q == grupos[-1][-1] + 1:
            grupos[-1].append(q)
        else:
            grupos.append([q])
    fechados = set(piscas)
    topos = np.array([c[0] for i, c in enumerate(caixas) if i not in fechados], float)
    bases = np.array([c[1] for c in caixas], float)
    pops = int((diffs[:-1] > 3 * media).sum()) if media > 0 else 0
    return dict(
        n=n,
        emenda=emenda,
        diffMedia=media,
        piscadas=[(g[0], len(g)) for g in grupos],
        respira=topos.max() - topos.min() if len(topos) else math.nan,
        baseY=bases.max() - bases.min(),
        pops=pops,
    )


def fmt(v):
    if isinstance(v, (tuple, list)):
        return '/'.join(fmt(x) for x in v)
    if isinstance(v, float):
        return f'{v:.1f}'
    return str(v)


def main():
    anim = sys.argv[1] if len(sys.argv) > 1 else 'build/atlas_anim24'
    vida = sys.argv[2] if len(sys.argv) > 2 else 'build/atlas_vida'
    if os.path.isdir(anim):
        print(f'== {anim} ==')
        print('ciclo-especie      n  pataV(e/d)  pataH(e/d) corpoH%  salto emenda e.viz cabeca(q) topo  rola° metades borda')
        for ciclo in CICLOS:
            for sp in ESPECIES:
                pasta = os.path.join(anim, f'{ciclo}-{sp}')
                if not os.path.isdir(pasta):
                    continue
                m = mede_ciclo(pasta)
                if m is None:
                    print(f'{ciclo}-{sp}: quadro vazio')
                    continue
                print(f"{ciclo + '-' + sp:18} {m['n']:2d}  {fmt(m['pataV']):>10}  {fmt(m['pataH']):>10} "
                      f"{m['corpoH']:6.1f}  {m['salto']:5.2f}  {m['emenda']:5.2f} {m['emendaViz']:5.2f}  {fmt(m['cabeca']):>7}  "
                      f"{m['topo']:4.0f}  {m['rola']:5.1f}  {m['metades']:6.1f}  {m['borda']:4.0f}")
    if os.path.isdir(vida):
        print(f'\n== {vida} ==')
        piscas = {}
        arq = os.path.join(vida, 'piscas.json')
        if os.path.exists(arq):
            txt = open(arq).read()
            # O arquivo é um Map.toString() do Dart: {otter: [1, 2], ...}
            for nome, lista in re.findall(r'(\w+): \[([^\]]*)\]', txt):
                piscas[nome] = [int(x) for x in lista.split(',') if x.strip()]
        print('vida-especie     n  emenda(119→0 ÷ média) diffMedia  piscadas(início,dur)  respira(px) baseY(px) pops(>3×)')
        for sp in ESPECIES:
            pasta = os.path.join(vida, f'vida-{sp}-0')
            if not os.path.isdir(pasta):
                continue
            m = mede_vida(pasta, piscas.get(sp, []))
            print(f"vida-{sp:10} {m['n']:3d}  {m['emenda']:6.2f}               {m['diffMedia']:6.2f}   "
                  f"{m['piscadas']!s:22} {m['respira']:5.1f}  {m['baseY']:5.1f}  {m['pops']}")


if __name__ == '__main__':
    main()

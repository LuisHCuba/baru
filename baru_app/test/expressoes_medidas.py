#!/usr/bin/env python3
"""Medidas do lote "expressões" sobre as capturas de `expressoes_test.dart`.

Uso: python3 test/expressoes_medidas.py [build/expressoes]

Por espécie:
- susto × contente, alinhados pela caixa: % de pixels diferentes na caixa da
  cabeça (≥ 20 %); relação largura/altura do corpo muda ≥ 8 % com a área da
  silhueta variando < 3 % (laudo 31 R3);
- festa-pico × radiante: ≥ 15 % de pixels diferentes (laudo 31 R4);
- festa-seq: pulo em ≥ 3 quadros consecutivos; área no pouso ≥ 97 % da de
  repouso; agachada (achata > 0,1) antes de decolar;
- susto-seq: agachada antes do estirão (achata > 0,1 por ≥ 2 quadros antes
  de susto > 0,5);
- meia piscada: íris visível com largura ≈ altura (±10 %), nenhum segmento
  reto escuro maior que a íris atravessando o olho, esclera com a mesma
  largura do olho aberto.
Também monta `folha.jpg` (9 espécies × quadros fixos) e `sequencias.jpg`
(lontra e capivara, susto-seq e festa-seq) e resume as piscadas de 30 s.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

BASE = sys.argv[1] if len(sys.argv) > 1 else 'build/expressoes'
ESPECIES = ['capybara', 'otter', 'tortoise', 'owl', 'axolotl', 'penguin', 'cat', 'fox', 'frenchie']
FIXOS = ['contente', 'susto', 'espanto', 'grito', 'riso-aberto', 'riso-fechado',
         'festa-pico', 'festa-pouso', 'meiapisca', 'olhar-esq', 'olhar-dir', 'olhar-cima', 'olhar-baixo']


def carrega(sp, nome):
    return np.asarray(Image.open(f'{BASE}/{sp}/{nome}.png').convert('RGBA')).astype(np.int32)


def silhueta(im):
    return im[:, :, 3] > 40


def caixa(mask):
    ys, xs = np.where(mask)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def alinha(a, b):
    """Recorta a e b pela caixa da silhueta e devolve os dois com o mesmo
    tamanho, alinhados pelo topo-centro."""
    ca, cb = caixa(silhueta(a)), caixa(silhueta(b))
    w = max(ca[2] - ca[0], cb[2] - cb[0])
    h = max(ca[3] - ca[1], cb[3] - cb[1])

    def rec(im, c):
        out = np.zeros((h, w, 4), np.int32)
        sub = im[c[1]:c[3], c[0]:c[2]]
        x0 = (w - sub.shape[1]) // 2
        out[:sub.shape[0], x0:x0 + sub.shape[1]] = sub
        return out
    return rec(a, ca), rec(b, cb)


def diferentes(a, b, regiao=None):
    d = np.abs(a - b).max(axis=2) > 40
    uniao = silhueta(a) | silhueta(b)
    if regiao is not None:
        d, uniao = d & regiao, uniao & regiao
    return 100.0 * d.sum() / max(1, uniao.sum())


def caixa_da_cabeca(a):
    """O terço-e-pouco de cima da silhueta: onde moram olhos, boca e orelhas."""
    s = silhueta(a)
    c = caixa(s)
    alt = c[3] - c[1]
    reg = np.zeros_like(s)
    reg[c[1]:c[1] + int(alt * 0.46), c[0]:c[2]] = True
    return reg


def olhos(im):
    """As caixas dos dois olhos: componentes de esclera creme (ou amarelo na
    coruja) na metade de cima."""
    r, g, b, a = [im[:, :, i] for i in range(4)]
    creme = (a > 200) & (r >= 246) & (g >= 236) & (b >= 218)
    amarelo = (a > 200) & (r > 225) & (g > 180) & (g < 215) & (b < 110)
    m = creme | amarelo
    m[int(m.shape[0] * 0.6):] = False
    # componentes por rotulagem simples (flood fill)
    rotulos = np.zeros(m.shape, np.int32)
    comps = []
    ys, xs = np.where(m)
    pilha = []
    k = 0
    for y, x in zip(ys, xs):
        if rotulos[y, x]:
            continue
        k += 1
        pilha.append((y, x))
        rotulos[y, x] = k
        pts = []
        while pilha:
            cy, cx = pilha.pop()
            pts.append((cy, cx))
            for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                if 0 <= ny < m.shape[0] and 0 <= nx < m.shape[1] and m[ny, nx] and not rotulos[ny, nx]:
                    rotulos[ny, nx] = k
                    pilha.append((ny, nx))
        if len(pts) > 150:
            p = np.array(pts)
            comps.append((len(pts), p[:, 1].min(), p[:, 0].min(), p[:, 1].max() + 1, p[:, 0].max() + 1))
    comps.sort(reverse=True)
    return [c[1:] for c in comps[:2]]


def iris_mask(im, cx0, cy0, cx1, cy1, pelo):
    """Íris (tinta ou âmbar) dentro da caixa, descontando a cor do pelo (a
    pálpebra) — no pelo escuro da lontra ela fica a 58 da tinta."""
    sub = im[cy0:cy1, cx0:cx1]
    r, g, b, a = [sub[:, :, i] for i in range(4)]
    tinta = np.sqrt((r - 0x3E) ** 2 + (g - 0x2F) ** 2 + (b - 0x23) ** 2) < 60
    ambar = (np.sqrt((r - 0xD9) ** 2 + (g - 0xA4) ** 2 + (b - 0x41) ** 2) < 45) | \
            (np.sqrt((r - 0xD7) ** 2 + (g - 0x9A) ** 2 + (b - 0x3C) ** 2) < 45)
    depelo = np.sqrt((r - pelo[0]) ** 2 + (g - pelo[1]) ** 2 + (b - pelo[2]) ** 2) < 28
    m = (tinta | ambar) & (a > 200) & ~depelo
    return m, tinta & (a > 200) & ~depelo


def largura_do_corpo(im):
    """A largura do tronco sem cauda nem orelha: o percentil 90 da maior
    corrida contígua de cada linha da silhueta (a cauda da gata e da raposa
    só encosta no corpo por poucas linhas)."""
    s = silhueta(im)
    corridas = []
    for linha in s:
        melhor, atual = 0, 0
        for v in linha:
            atual = atual + 1 if v else 0
            melhor = max(melhor, atual)
        if melhor:
            corridas.append(melhor)
    return float(np.percentile(corridas, 90))


def mede_meiapisca(sp):
    aberto, meio = carrega(sp, 'contente'), carrega(sp, 'meiapisca')
    saida = []
    for (x0, y0, x1, y1) in olhos(aberto):
        larg_aberta = x1 - x0
        # esclera visível na meia piscada dentro da mesma caixa (com folga)
        f = 4
        sub = meio[y0 - f:y1 + f, x0 - f:x1 + f]
        r, g, b, a = [sub[:, :, i] for i in range(4)]
        creme = (a > 200) & (((r >= 246) & (g >= 236) & (b >= 218)) | ((r > 225) & (g > 180) & (g < 215) & (b < 110)))
        xs = np.where(creme.any(axis=0))[0]
        larg_meia = (xs.max() - xs.min() + 1) if len(xs) else 0
        # a íris: o que, dentro do círculo do olho aberto, não é esclera nem
        # pálpebra (a cor da pálpebra é lida no topo do olho da meia piscada,
        # que ela cobre) nem o pelo em volta.
        cx, cy = (x1 - x0) / 2 + f, (y1 - y0) / 2 + f
        raio = (x1 - x0) / 2
        yy, xx = np.mgrid[0:sub.shape[0], 0:sub.shape[1]]
        dentro = (xx - cx) ** 2 + (yy - cy) ** 2 <= (raio - 1) ** 2
        palpebra = sub[int(cy - raio + 4), int(cx), :3]
        pelo = aberto[max(0, y0 - 8), (x0 + x1) // 2, :3]
        dist = lambda c: np.sqrt(((sub[:, :, :3] - c) ** 2).sum(axis=2))
        branco = (r > 235) & (g > 235) & (b > 235)
        tinta = np.sqrt((r - 0x3E) ** 2 + (g - 0x2F) ** 2 + (b - 0x23) ** 2) < 60
        ambar = (np.sqrt((r - 0xD9) ** 2 + (g - 0xA4) ** 2 + (b - 0x41) ** 2) < 40) | \
                (np.sqrt((r - 0xD7) ** 2 + (g - 0x9A) ** 2 + (b - 0x3C) ** 2) < 40)
        im_ = dentro & (a > 200) & ~creme & ~branco & (tinta | ambar) & (dist(palpebra) > 24) & (dist(pelo) > 24)
        tinta = im_ & tinta
        # a íris é o componente escuro dentro do círculo do olho: tira a
        # linha dos cílios (≤ 5 px) exigindo colunas e linhas com ≥ 6 px
        colunas = im_.sum(axis=0)
        cols = np.where(colunas >= 6)[0]
        linhas = im_.sum(axis=1)
        lins = np.where(linhas >= 6)[0]
        if len(cols) == 0 or len(lins) == 0:
            saida.append(dict(iris='sem íris visível'))
            continue
        iw = cols.max() - cols.min() + 1
        ih = lins.max() - lins.min() + 1
        # maior corrida horizontal de tinta numa linha
        corrida = 0
        for linha in tinta:
            atual = 0
            for v in linha:
                atual = atual + 1 if v else 0
                corrida = max(corrida, atual)
        saida.append(dict(esclera_aberta=int(larg_aberta), esclera_meia=int(larg_meia),
                          iris_w=int(iw), iris_h=int(ih), razao=round(iw / ih, 2),
                          corrida_max=int(corrida), limite_corrida=int(max(10, 1.15 * ih))))
    return saida


def mede_sequencia(sp):
    log = json.load(open(f'{BASE}/{sp}/seq.json'))
    out = {}
    # festa: pulo e pouso
    festa = log['festa-seq']
    alturas = [q['altura'] for q in festa]
    no_ar = [a > 0.5 for a in alturas]
    melhor, atual = 0, 0
    for v in no_ar:
        atual = atual + 1 if v else 0
        melhor = max(melhor, atual)
    # agachada antes de decolar: achata > 0,1 no quadro anterior ao primeiro no ar
    decola = [i for i in range(1, len(no_ar)) if no_ar[i] and not no_ar[i - 1]]
    agacha = [festa[i - 1]['achata'] > 0.1 or (i >= 2 and festa[i - 2]['achata'] > 0.1) for i in decola]
    # área da silhueta: repouso (quadro 0 da susto-seq, antes do susto) × pouso
    repouso = silhueta(carrega(sp, 'susto-seq/0')).sum()
    pousos = [i for i in range(1, len(no_ar)) if not no_ar[i] and no_ar[i - 1]]
    areas = [silhueta(carrega(sp, f'festa-seq/{i}')).sum() / repouso * 100 for i in pousos]
    out['festa'] = dict(quadros_no_ar_seguidos=melhor, decolagens=len(decola),
                        agachada_antes=agacha, area_no_pouso_pct=[round(a, 1) for a in areas],
                        fracao_no_ar_pct=round(100 * sum(no_ar) / len(no_ar), 1))
    # susto: agachada antes do estirão
    susto = log['susto-seq']
    primeiro = next((i for i, q in enumerate(susto) if q['susto'] > 0.5), None)
    antes = sum(1 for q in susto[:primeiro] if q['achata'] > 0.1) if primeiro is not None else 0
    out['susto'] = dict(estirao_no_quadro=primeiro, quadros_agachado_antes=antes,
                        achata_max_antes=round(max([q['achata'] for q in susto[:primeiro]] or [0]), 2))
    grito = log['grito-seq']
    out['grito'] = dict(quadros_cheios=sum(1 for q in grito if q['grito'] >= 0.99),
                        estica_antes=sum(1 for q in grito[:3] if q['achata'] < -0.05))
    riso = log['riso-seq']
    out['riso'] = dict(min=round(min(q['riso'] for q in riso[3:28]), 2), max=round(max(q['riso'] for q in riso), 2))
    return out


def piscadas():
    p = json.load(open(f'{BASE}/piscadas.json'))
    out = {}
    for sp, serie in p.items():
        grupos, atual = [], []
        for i, v in enumerate(serie):
            if v > 0.15:
                atual.append(i)
            elif atual:
                grupos.append(atual)
                atual = []
        duracoes = [len(g) for g in grupos]
        inicios = [g[0] for g in grupos]
        intervalos = [(b - a) / 30 for a, b in zip(inicios, inicios[1:])]
        out[sp] = dict(piscadas_em_30s=len(grupos), duracao_quadros=duracoes,
                       intervalo_min_s=round(min(intervalos), 2) if intervalos else None,
                       mediana_s=round(float(np.median(intervalos)), 2) if intervalos else None)
    return out


def folha(nomes, caminho, esp=ESPECIES, escala=0.5):
    tiles = []
    for sp in esp:
        linha = []
        for n in nomes:
            im = Image.open(f'{BASE}/{sp}/{n}.png').convert('RGBA')
            bb = im.getbbox()
            fundo = Image.new('RGBA', im.size, (255, 255, 255, 255))
            fundo.alpha_composite(im)
            linha.append(fundo.convert('RGB').crop(bb))
        tiles.append(linha)
    w = max(t.width for l in tiles for t in l) + 8
    h = max(t.height for l in tiles for t in l) + 20
    folha = Image.new('RGB', (w * len(nomes), h * len(esp)), (255, 255, 255))
    d = ImageDraw.Draw(folha)
    for i, linha in enumerate(tiles):
        for j, t in enumerate(linha):
            x, y = j * w, i * h
            folha.paste(t, (x + (w - t.width) // 2, y + 20 + (h - 20 - t.height) // 2))
            d.text((x + 3, y + 3), f'{esp[i]} {nomes[j]}', fill=(0, 0, 0))
    folha = folha.resize((int(folha.width * escala), int(folha.height * escala)))
    folha.save(caminho, quality=85)
    return folha.size


def main():
    rel = {}
    for sp in ESPECIES:
        if not os.path.isdir(f'{BASE}/{sp}'):
            continue
        r = {}
        c, s = carrega(sp, 'contente'), carrega(sp, 'susto')
        ca, sa = alinha(c, s)
        r['susto_cabeca_pct'] = round(diferentes(ca, sa, caixa_da_cabeca(ca)), 1)
        cc, cs = caixa(silhueta(c)), caixa(silhueta(s))
        rc = largura_do_corpo(c) / (cc[3] - cc[1])
        rs = largura_do_corpo(s) / (cs[3] - cs[1])
        r['susto_razao_wh_pct'] = round(100 * abs(rs - rc) / rc, 1)
        r['susto_area_pct'] = round(100 * (silhueta(s).sum() / silhueta(c).sum() - 1), 1)
        rad, pico = carrega(sp, 'radiante'), carrega(sp, 'festa-pico')
        ra, pa = alinha(rad, pico)
        r['festa_pico_x_radiante_pct'] = round(diferentes(ra, pa), 1)
        r['meiapisca'] = mede_meiapisca(sp)
        r['sequencias'] = mede_sequencia(sp)
        rel[sp] = r
        print(f'== {sp}')
        for k, v in r.items():
            print(f'  {k}: {v}')
    rel['piscadas'] = piscadas()
    print('== piscadas (30 s)', rel['piscadas'])
    print('folha.jpg', folha(FIXOS, f'{BASE}/folha.jpg'))
    seq = [f'susto-seq/{i}' for i in range(0, 30, 2)] + [f'festa-seq/{i}' for i in range(0, 30, 2)]
    print('sequencias.jpg', folha(seq, f'{BASE}/sequencias.jpg', esp=['otter', 'capybara'], escala=0.4))
    json.dump(rel, open(f'{BASE}/medidas.json', 'w'), indent=1, ensure_ascii=False)


if __name__ == '__main__':
    main()

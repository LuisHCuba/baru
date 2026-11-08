#!/usr/bin/env python3
"""Folhas de contato do atlas (build/atlas, build/atlas_anim24, build/atlas_vida) por espécie, para auditoria visual.
Uso: python3 test/atlas_folhas.py [build] [saída]  → <saída>/<espécie>/{bocas,estados,ciclos,vida}.jpg + indice.md"""
import glob, os, re, sys
from PIL import Image, ImageDraw, ImageFont

BUILD = sys.argv[1] if len(sys.argv) > 1 else 'build'
OUT = sys.argv[2] if len(sys.argv) > 2 else f'{BUILD}/atlas_folhas'
ESP = ['capybara', 'otter', 'tortoise', 'owl', 'axolotl', 'penguin', 'cat', 'fox', 'frenchie']
NOME = dict(capybara='Baru (capivara)', otter='Rio (lontra)', tortoise='Toco (tartaruga)', owl='Nina (coruja)', axolotl='Lume (axolote)',
            penguin='Nino (pinguim)', cat='Mel (gata)', fox='Faísca (raposa)', frenchie='Bolota (buldogue)')
try:
    FONT = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 22)
    FONT_B = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 30)
except Exception:
    FONT = FONT_B = ImageFont.load_default()


def grade(celulas, cols, cw, ch, titulo, fundo=(246, 240, 228)):
    """celulas: [(rotulo, Image)]; cada célula cw×ch mais o rótulo."""
    rows = (len(celulas) + cols - 1) // cols
    W, H = cols * cw, 60 + rows * (ch + 30)
    out = Image.new('RGB', (W, H), fundo); d = ImageDraw.Draw(out)
    d.text((12, 12), titulo, fill=(40, 30, 20), font=FONT_B)
    for k, (rot, im) in enumerate(celulas):
        x, y = (k % cols) * cw, 60 + (k // cols) * (ch + 30)
        im = im.convert('RGBA'); im.thumbnail((cw - 8, ch - 8))
        cel = Image.new('RGBA', (cw - 8, ch - 8), (255, 255, 255, 0))
        cel.alpha_composite(im, ((cw - 8 - im.width) // 2, (ch - 8 - im.height) // 2))
        base = Image.new('RGB', cel.size, (255, 255, 255)); base.paste(cel, mask=cel.split()[3]); out.paste(base, (x + 4, y))
        d.rectangle([x + 4, y, x + cw - 4, y + ch - 8], outline=(200, 190, 170))
        d.text((x + 8, y + ch - 4), rot, fill=(60, 45, 30), font=FONT)
    return out


def abre(p): return Image.open(p)


def rosto(im):  # recorte da cabeça: 60% de cima, centro
    w, h = im.size; return im.crop((int(w * 0.18), int(h * 0.02), int(w * 0.82), int(h * 0.62)))


os.makedirs(OUT, exist_ok=True)
indice = ['# Atlas da turma do Baru (folhas de contato)\n']
for sp in ESP:
    A = f'{BUILD}/atlas/{sp}'
    if not os.path.isdir(A): continue
    os.makedirs(f'{OUT}/{sp}', exist_ok=True)
    # 1. bocas: 5 humores × 6 níveis, + susto e festa × 3 (recorte do rosto)
    cel = []
    for h in ['contente', 'radiante', 'neutro', 'sono', 'saudade']:
        for b in [0, 2, 4, 6, 8, 10]:
            p = f'{A}/boca-{h}-{b}.png'
            if os.path.exists(p): cel.append((f'{h} boca {b/10:.1f}', rosto(abre(p))))
    for k in ['susto-0', 'susto-5', 'susto-10', 'festa-0', 'festa-5', 'festa-10']:
        p = f'{A}/{k}.png'
        if os.path.exists(p): cel.append((k, rosto(abre(p))))
    grade(cel, 6, 330, 300, f'{NOME[sp]} · BOCAS por humor e abertura (0 a 1), susto e festa').save(f'{OUT}/{sp}/bocas.jpg', quality=88)
    # 2. estados: o resto do atlas
    cel = []
    for p in sorted(glob.glob(f'{A}/*.png')):
        n = os.path.basename(p)[:-4]
        if n.startswith('boca-') or n.startswith('susto') or n.startswith('festa'): continue
        cel.append((n, abre(p)))
    grade(cel, 8, 260, 240, f'{NOME[sp]} · ESTADOS: piscada, olhar, virada, cabeça, poses, água, estágios, fôlego').save(f'{OUT}/{sp}/estados.jpg', quality=88)
    # 3. ciclos (anim24): cada ciclo numa linha, 12 de 24 quadros
    cel = []; linhas = []
    for c in sorted(glob.glob(f'{BUILD}/atlas_anim24/*-{sp}')):
        nome = os.path.basename(c).replace(f'-{sp}', '')
        qs = sorted(glob.glob(f'{c}/*.png'), key=lambda q: (0, int(os.path.basename(q)[:-4])) if os.path.basename(q)[:-4].isdigit() else (1, os.path.basename(q)))
        passo = max(1, len(qs) // 12)
        linhas.append(nome)
        for q in qs[::passo][:12]: cel.append((f'{nome} q{os.path.basename(q)[:-4]}', abre(q)))
    if cel: grade(cel, 12, 200, 190, f'{NOME[sp]} · CICLOS (12 de 24 quadros por linha): {", ".join(linhas)}').save(f'{OUT}/{sp}/ciclos.jpg', quality=88)
    # 4. vida: laço de 120 quadros (boca 0 e boca 2), a cada 5 quadros
    cel = []
    for nivel in ['0', '2']:
        V = f'{BUILD}/atlas_vida/vida-{sp}-{nivel}'
        if not os.path.isdir(V): continue
        for i in range(0, 120, 5): cel.append((f'vida b{nivel} q{i} ({i/30:.1f}s)', abre(f'{V}/{i}.png')))
    for extra in ['vida-tortoise_enc-0', 'vida-tortoise_dorme-0', 'lado-owl-0', 'cima-owl-0']:
        V = f'{BUILD}/atlas_vida/{extra}'
        if sp in extra and os.path.isdir(V):
            qs = sorted(glob.glob(f'{V}/*.png'), key=lambda q: (0, int(os.path.basename(q)[:-4])) if os.path.basename(q)[:-4].isdigit() else (1, os.path.basename(q)))
            for q in qs[::max(1, len(qs) // 12)][:12]: cel.append((f'{extra} q{os.path.basename(q)[:-4]}', abre(q)))
    if cel: grade(cel, 12, 200, 190, f'{NOME[sp]} · VIDA (motor de vida, 4 s a 30 fps, a cada 5 quadros; boca 0 e boca 0,85)').save(f'{OUT}/{sp}/vida.jpg', quality=88)
    indice.append(f'- {NOME[sp]}: {OUT}/{sp}/bocas.jpg, estados.jpg, ciclos.jpg, vida.jpg (quadros soltos em {A}/, {BUILD}/atlas_anim24/*-{sp}/, {BUILD}/atlas_vida/vida-{sp}-*/)')
    print(sp, 'ok')
# cenário
C = f'{BUILD}/cenario_nov'
if os.path.isdir(C):
    cel = [(n, abre(f'{C}/{n}.png')) for n in ['fundo-amanhecer', 'fundo-dia', 'fundo-entardecer', 'fundo-noite', 'frente-amanhecer', 'frente-dia', 'frente-entardecer', 'frente-noite'] if os.path.exists(f'{C}/{n}.png')]
    grade(cel, 4, 640, 380, 'CENÁRIO do app · fundo e frente nos 4 períodos').save(f'{OUT}/cenario.jpg', quality=88)
    cel = [(os.path.basename(p)[:-4], abre(p)) for p in sorted(glob.glob(f'{C}/pecas/*.png'))]
    if cel: grade(cel, 6, 330, 260, 'OBJETOS de cena (loja)').save(f'{OUT}/pecas.jpg', quality=88)
    indice.append(f'- Cenário: {OUT}/cenario.jpg e {OUT}/pecas.jpg (originais 4800×2700 em {C}/)')
open(f'{OUT}/indice.md', 'w').write('\n'.join(indice) + '\n')
print('folhas em', OUT)

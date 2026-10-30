"""Junta os quadros de test/animacoes_site_test.dart em folhas para o site.

Cada sequência (anda-raposa, voa-coruja...) vira uma tira horizontal em
WebP, recortada pela caixa que cabe em todos os quadros dela — assim o
bicho não pula de lugar entre um quadro e outro. As fases de crescimento
viram imagens soltas. Um `animacoes.json` diz ao site quantos quadros e
que proporção cada tira tem.

    python3 tool/folhas_do_site.py <saida>   # ex.: ../../baru.lhcx/site/assets/anim
"""
import json
import os
import sys

from PIL import Image

ORIGEM = 'build/animacoes_site'


def caixa(imagens):
    caixas = [im.getbbox() for im in imagens if im.getbbox()]
    return (min(c[0] for c in caixas), min(c[1] for c in caixas),
            max(c[2] for c in caixas), max(c[3] for c in caixas))


def main(saida):
    os.makedirs(saida, exist_ok=True)
    manifesto = {}
    for pasta in sorted(os.listdir(ORIGEM)):
        caminho = os.path.join(ORIGEM, pasta)
        nomes = sorted(os.listdir(caminho), key=lambda n: (len(n), n))
        imagens = [Image.open(os.path.join(caminho, n)).convert('RGBA') for n in nomes]
        if pasta.startswith('fase-'):
            # Fases: recorte comum às cinco, para crescerem no mesmo chão.
            x0, y0, x1, y1 = caixa(imagens)
            for nome, im in zip(nomes, imagens):
                im.crop((x0, y0, x1, y1)).save(
                    os.path.join(saida, f"{pasta}-{nome[:-4]}.webp"), 'WEBP', quality=84, method=4)
            manifesto[pasta] = {'w': x1 - x0, 'h': y1 - y0}
            continue
        x0, y0, x1, y1 = caixa(imagens)
        # Um respiro de 2 px para a borda do traço não cortar.
        x0, y0, x1, y1 = max(0, x0 - 2), max(0, y0 - 2), x1 + 2, y1 + 2
        w, h = x1 - x0, y1 - y0
        tira = Image.new('RGBA', (w * len(imagens), h), (0, 0, 0, 0))
        for i, im in enumerate(imagens):
            tira.paste(im.crop((x0, y0, x1, y1)), (i * w, 0))
        tira.save(os.path.join(saida, f'{pasta}.webp'), 'WEBP', quality=80, method=4)
        # Densidade da folha: o quadro do teste tem 260 unidades de largura.
        d = round(imagens[0].width / 260, 2)
        manifesto[pasta] = {'n': len(imagens), 'w': w, 'h': h, 'd': d}
    with open(os.path.join(saida, 'animacoes.json'), 'w') as f:
        json.dump(manifesto, f, indent=1, sort_keys=True)


if __name__ == '__main__':
    main(sys.argv[1])

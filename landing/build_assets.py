#!/usr/bin/env python3
"""Gera os assets da landing a partir da evidencia visual do app.

As imagens vivem em docs/evidence/<data>/ e sao PNGs rasterizados da arvore de
widgets. Aqui elas viram WebP redimensionado, para a pagina carregar leve.

    python3 landing/build_assets.py
"""
import pathlib
from PIL import Image

RAIZ = pathlib.Path(__file__).resolve().parent.parent
FONTE = RAIZ / "docs" / "evidence" / "2026-08-27"
DESTINO = RAIZ / "landing" / "assets"

# arquivo -> largura maxima na pagina (px, ja em 2x para telas retina)
IMAGENS = {
    "home.png": 620,
    "tempo-com-dados.png": 620,
    "tempo-sem-permissao.png": 620,
    "trilha-andamento.png": 620,
    "missoes.png": 620,
    "tela-loja.png": 620,
    "tela-sequencia.png": 620,
    "habitat-amanhecer.png": 744,
    "habitat-entardecer.png": 744,
    "habitat-noite.png": 744,
    "pet-swim.png": 400,
    "pet-graze.png": 400,
    "pet-nap.png": 400,
    "pet-idle.png": 400,
    "especie-capybara.png": 400,
    "especie-otter.png": 400,
    "especie-tortoise.png": 400,
    "especie-owl.png": 400,
}


def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    total = 0
    for nome, largura in IMAGENS.items():
        origem = FONTE / nome
        img = Image.open(origem).convert("RGBA")
        if img.width > largura:
            altura = round(img.height * largura / img.width)
            img = img.resize((largura, altura), Image.LANCZOS)
        saida = DESTINO / (origem.stem + ".webp")
        img.save(saida, "WEBP", quality=84, method=6)
        total += saida.stat().st_size
        print(f"{saida.name:34} {img.width}x{img.height}  {saida.stat().st_size/1024:6.1f} KB")
    print(f"\n{len(IMAGENS)} arquivos, {total/1024:.1f} KB no total")


if __name__ == "__main__":
    main()

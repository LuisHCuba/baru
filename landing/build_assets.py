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
    "habitat-amanhecer.png": 744,
    "habitat-entardecer.png": 744,
    "habitat-noite.png": 744,
}


ESPECIES = ["capybara", "otter", "tortoise", "owl", "axolotl", "penguin", "cat", "fox"]
HUMORES = ["radiant", "content", "sleepy", "missing"]


def _bandas(perfil):
    """Intervalos contíguos com conteúdo num perfil booleano."""
    b, ini = [], None
    for i, x in enumerate(perfil):
        if x and ini is None:
            ini = i
        if not x and ini is not None:
            b.append((ini, i))
            ini = None
    if ini is not None:
        b.append((ini, len(perfil)))
    return b


def corta_sprites() -> int:
    """Corta folha-especies.png (8 espécies × 4 humores, fundo transparente)
    em sprites individuais numa moldura comum, ancorados nos pés, para a
    troca de espécie/humor na página não pular."""
    im = Image.open(FONTE / "folha-especies.png").convert("RGBA")
    alfa = im.getchannel("A")
    px = alfa.load()
    w, h = im.size
    linhas = _bandas([any(px[x, y] for x in range(w)) for y in range(h)])
    colunas = _bandas([any(px[x, y] for y in range(h)) for x in range(w)])
    assert len(linhas) == 8 and len(colunas) == 4, (len(linhas), len(colunas))

    recortes = {}
    for r, (y0, y1) in enumerate(linhas):
        for c, (x0, x1) in enumerate(colunas):
            cel = im.crop((x0, y0, x1, y1))
            recortes[(ESPECIES[r], HUMORES[c])] = cel.crop(cel.getbbox())

    cw = max(s.width for s in recortes.values()) + 16
    ch = max(s.height for s in recortes.values()) + 8
    total = 0
    for (esp, humor), sp in recortes.items():
        tela = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        tela.paste(sp, ((cw - sp.width) // 2, ch - sp.height), sp)
        saida = DESTINO / f"pet-{esp}-{humor}.webp"
        tela.save(saida, "WEBP", quality=88, method=6, exact=False)
        total += saida.stat().st_size
    print(f"{len(recortes)} sprites {cw}x{ch}, {total/1024:.0f} KB")
    return total


def gera_favicon() -> None:
    """Favicon a partir da própria capivara, sobre o verde da marca.

    Fundo verde e não creme porque no 16x16 o marrom do bicho some contra
    um fundo claro — testado ampliando as três variantes."""
    pet = Image.open(DESTINO / "pet-capybara-content.webp").convert("RGBA")
    bb = pet.getbbox()
    # a cabeça vai do topo das orelhas até um pouco abaixo do focinho
    cabeca = pet.crop((bb[0], bb[1], bb[2], bb[1] + 165))
    cabeca = cabeca.crop(cabeca.getbbox())

    def icone(lado: int) -> Image.Image:
        tela = Image.new("RGBA", (lado, lado), (66, 129, 48, 255))
        escala = (lado * 0.80) / cabeca.width
        c = cabeca.resize(
            (max(1, round(cabeca.width * escala)), max(1, round(cabeca.height * escala))),
            Image.LANCZOS,
        )
        tela.paste(c, ((lado - c.width) // 2, (lado - c.height) // 2), c)
        return tela

    grande = icone(180)
    grande.convert("RGB").save(DESTINO / "apple-touch-icon.png")
    # .ico com os três tamanhos que os navegadores pedem
    icone(48).save(
        DESTINO / "favicon.ico",
        sizes=[(16, 16), (32, 32), (48, 48)],
    )
    print("favicon.ico (16/32/48) e apple-touch-icon.png 180x180")


def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    corta_sprites()
    gera_favicon()
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

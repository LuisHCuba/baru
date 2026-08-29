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


# A ordem tem de ser a de `Species` em lib/models.dart: a folha e uma grade e
# o corte le por posicao, entao trocar dois nomes de lugar troca os dois
# bichos de nome no site inteiro. Bicho novo entra no fim, como no enum.
ESPECIES = [
    "capybara",
    "otter",
    "tortoise",
    "owl",
    "axolotl",
    "penguin",
    "cat",
    "fox",
    "frenchie",
]
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
    """Corta folha-especies.png (uma linha por espécie × 4 humores, fundo
    transparente) em sprites individuais numa moldura comum, ancorados nos
    pés, para a troca de espécie/humor na página não pular."""
    im = Image.open(FONTE / "folha-especies.png").convert("RGBA")
    alfa = im.getchannel("A")
    px = alfa.load()
    w, h = im.size
    linhas = _bandas([any(px[x, y] for x in range(w)) for y in range(h)])
    colunas = _bandas([any(px[x, y] for y in range(h)) for x in range(w)])
    # Conferido contra ESPECIES, e nao contra um 8 escrito a mao: o numero de
    # bichos mudou uma vez e vai mudar de novo. Se a folha estiver velha (o
    # app ganhou uma especie e ninguem rodou o evidencia_test de novo), a
    # conta nao bate e o build para aqui — em vez de cortar tudo deslocado em
    # uma linha e renomear todo mundo em silencio.
    assert len(linhas) == len(ESPECIES) and len(colunas) == len(HUMORES), (
        f"folha com {len(linhas)}x{len(colunas)}, esperado "
        f"{len(ESPECIES)}x{len(HUMORES)} — regere com "
        f"`flutter test test/evidencia_test.dart`"
    )

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


def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    corta_sprites()
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

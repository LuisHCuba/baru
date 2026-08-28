#!/usr/bin/env python3
"""Gera uma versão de arquivo único da landing, com as imagens embutidas.

Serve para publicar em qualquer lugar que aceite um HTML solto (Artifact,
anexo, e-mail interno) sem carregar a pasta de assets junto.

    python3 landing/build_artifact.py            -> landing/dist/baru-landing.html
    python3 landing/build_artifact.py --corpo    -> só o miolo, sem <html>/<head>
"""
import base64
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent
PAGINA = RAIZ / "index.html"
SAIDA = RAIZ / "dist" / "baru-landing.html"


TIPOS = {".webp": "image/webp", ".png": "image/png", ".ico": "image/x-icon"}


def embute(html: str) -> str:
    """Troca cada src/href de assets/ por data: URI, favicon incluído."""

    def troca(m):
        atributo, caminho = m.group(1), m.group(2)
        arquivo = RAIZ / caminho
        tipo = TIPOS[arquivo.suffix]
        dado = base64.b64encode(arquivo.read_bytes()).decode()
        return f'{atributo}="data:{tipo};base64,{dado}"'

    return re.sub(r'(src|href)="(assets/[^"]+\.(?:webp|png|ico))"', troca, html)


def mapa_de_sprites() -> str:
    """window.BARU_SPRITES: os 32 sprites que a página monta por JS.

    Sem isto o arquivo único fica com os pets quebrados — a troca de
    espécie referencia assets/pet-<id>-<humor>.webp, que não existe ao
    lado de um HTML solto."""
    pares = {}
    for arquivo in sorted((RAIZ / "assets").glob("pet-*-*.webp")):
        dado = base64.b64encode(arquivo.read_bytes()).decode()
        pares[arquivo.stem[len("pet-"):]] = "data:image/webp;base64," + dado
    corpo = ",".join(f'"{k}":"{v}"' for k, v in pares.items())
    print(f"{len(pares)} sprites no mapa")
    return f"<script>window.BARU_SPRITES={{{corpo}}};</script>\n"


def so_o_corpo(html: str) -> str:
    """Devolve título + fontes + estilo + miolo do body, sem o esqueleto."""
    titulo = re.search(r"<title>.*?</title>", html, re.S).group(0)
    fontes = re.search(r'<link rel="stylesheet" href="https://fonts[^>]*>', html).group(0)
    estilo = re.search(r"<style>.*?</style>", html, re.S).group(0)
    corpo = re.search(r"<body>(.*)</body>", html, re.S).group(1)
    return f"{titulo}\n{fontes}\n{estilo}\n{corpo}"


def main() -> None:
    html = embute(PAGINA.read_text(encoding="utf-8"))
    html = html.replace("<script>", mapa_de_sprites() + "<script>", 1)
    # Com as imagens já embutidas não há rede para adiar: o lazy só atrasa a
    # decodificação e faz o crossfade do habitat piscar no primeiro ciclo.
    html = html.replace(' loading="lazy"', "")
    if "--corpo" in sys.argv:
        html = so_o_corpo(html)
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(html, encoding="utf-8")
    print(f"{SAIDA.relative_to(RAIZ.parent)} — {SAIDA.stat().st_size/1024:.0f} KB")


if __name__ == "__main__":
    main()

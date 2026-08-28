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


def embute(html: str) -> str:
    def troca(m):
        caminho = RAIZ / m.group(1)
        dado = base64.b64encode(caminho.read_bytes()).decode()
        return f'src="data:image/webp;base64,{dado}"'

    return re.sub(r'src="(assets/[^"]+\.webp)"', troca, html)


def so_o_corpo(html: str) -> str:
    """Devolve título + fontes + estilo + miolo do body, sem o esqueleto."""
    titulo = re.search(r"<title>.*?</title>", html, re.S).group(0)
    fontes = re.search(r'<link rel="stylesheet" href="https://fonts[^>]*>', html).group(0)
    estilo = re.search(r"<style>.*?</style>", html, re.S).group(0)
    corpo = re.search(r"<body>(.*)</body>", html, re.S).group(1)
    return f"{titulo}\n{fontes}\n{estilo}\n{corpo}"


def main() -> None:
    html = embute(PAGINA.read_text(encoding="utf-8"))
    if "--corpo" in sys.argv:
        html = so_o_corpo(html)
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(html, encoding="utf-8")
    print(f"{SAIDA.relative_to(RAIZ.parent)} — {SAIDA.stat().st_size/1024:.0f} KB")


if __name__ == "__main__":
    main()

"""Confere os limites da Play nos textos de ficha.md (nome 30, curta 80, completa 4000)."""
import re, pathlib, sys
texto = (pathlib.Path(__file__).parent / 'ficha.md').read_text(encoding='utf-8')
limites = {'nome': 30, 'curta': 80, 'completa': 4000}
ok = True
for campo, lang, corpo in re.findall(r'<!-- (nome|curta|completa):(\w+) -->\n(.*?)\n<!-- /\1:\2 -->', texto, re.S):
    n = len(corpo)
    passou = n <= limites[campo]
    ok &= passou
    print(f'{lang} {campo:9} {n:5}/{limites[campo]} {"ok" if passou else "PASSOU DO LIMITE"}')
sys.exit(0 if ok else 1)

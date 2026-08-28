# Landing page do Baru

Página única de divulgação, em português. Sem framework, sem build de
JavaScript: um `index.html` com o CSS embutido e as imagens ao lado.

```
landing/
├── index.html          a página
├── assets/*.webp       capturas reais do app (geradas, não versione à mão)
├── build_assets.py     docs/evidence/ -> assets/ (redimensiona e converte)
├── build_artifact.py   index.html -> dist/, com as imagens embutidas
└── dist/               arquivo único para publicar em qualquer lugar
```

## Rodar localmente

```
python3 -m http.server -d landing 8000
# http://localhost:8000
```

## Publicar

Qualquer host de arquivo estático serve — GitHub Pages, Netlify, Vercel,
Cloudflare Pages, um bucket. Suba `index.html` e a pasta `assets/`.

Para um arquivo só, sem pasta de assets (anexo, e-mail, ferramenta que aceita
um HTML solto):

```
python3 landing/build_artifact.py           # documento completo
python3 landing/build_artifact.py --corpo   # sem <html>/<head>, para embutir
```

## Ligar a lista de espera

Por padrão **não há formulário**: a página mostra "em breve" nas lojas. Um
campo que engole o e-mail de alguém sem destino é pior que nenhum campo.

Para ligar, preencha **um** dos dois no topo do `<script>` em `index.html`:

```js
var LISTA_ESPERA = { endpoint: "", email: "" };
```

| Campo | O que faz |
|---|---|
| `endpoint` | URL que aceita `POST` com JSON `{email}` — Formspree, uma Edge Function do Supabase, seu backend. O formulário envia e confirma na própria página. |
| `email` | Endereço de contato. O formulário abre o cliente de e-mail com a mensagem pronta. |

Com `endpoint` preenchido, ele ganha precedência.

## Atualizar as capturas

As imagens vêm de `docs/evidence/<data>/`, que é gerado por
`baru_app/test/evidencia_test.dart`. Depois de regerar a evidência:

```
cd baru_app && flutter test test/evidencia_test.dart
cd .. && python3 landing/build_assets.py
```

A data da pasta está fixada em `build_assets.py` (`FONTE`) — troque quando
houver uma evidência mais nova.

## Decisões de conteúdo

- Todo número na página vem de `docs/PRODUCT.md`, que é o contrato de
  produto. Se uma regra mudar lá, muda aqui.
- Todas as imagens são capturas reais da árvore de widgets. Nenhuma arte de
  divulgação, nenhum mockup fantasiado.
- O seletor de hora do dia mostra três momentos: amanhecer, entardecer e
  noite. `habitat-dia.png` ficou de fora porque é quase idêntico ao
  amanhecer (diferença média de 8,7 em 255 por canal) — a troca parecia
  quebrada.
- A página não afirma que o app está nas lojas, porque não está.

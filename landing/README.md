# Landing page do Baru

Página única de divulgação, em português. Sem framework, sem build de
JavaScript: um `index.html` com o CSS embutido e as imagens ao lado.

```
landing/
├── index.html          a página
├── assets/*.webp       capturas e sprites reais do app (gerados)
├── build_assets.py     docs/evidence/ -> assets/: redimensiona as telas e
│                       corta folha-especies.png em 36 sprites (9 espécies
│                       × 4 humores), ancorados nos pés numa moldura comum
├── build_artifact.py   index.html -> dist/, com as imagens embutidas
└── dist/               arquivo único para publicar em qualquer lugar
```

A página é interativa: dá para escolher qualquer um dos 9 companheiros
(a escolha se propaga para os humores e para o fechamento), fazer carinho
no bicho — três toques em 3 s soltam a chuva de corações, a mesma regra do
app — e o habitat troca de hora sozinho. Tudo em vanilla JS, animações só
de transform/opacity, imagens abaixo da dobra com `loading="lazy"`.

## Rodar localmente

```
python3 -m http.server -d landing 8000
# http://localhost:8000
```

## Publicar

Qualquer host de arquivo estático serve — GitHub Pages, Netlify, Vercel,
Cloudflare Pages, um bucket. Suba `index.html` e a pasta `assets/`.

Para um arquivo só, sem pasta de assets (anexo, e-mail, ferramenta que aceita
um HTML solto). O build embute as imagens **e** injeta `window.BARU_SPRITES`
com os 36 sprites — a página monta o caminho do pet por JS, e sem esse mapa
a troca de espécie quebra no HTML solto:

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

- A página é **tema claro único, de propósito**: referência comercial à la
  Duolingo (fundo branco, verde vivo, botões com borda inferior, bordas
  claras). O aconchego de tons quentes/escuros fica para dentro do app.
- Todo número na página vem de `docs/PRODUCT.md`, que é o contrato de
  produto. Se uma regra mudar lá, muda aqui.
- Todas as imagens são capturas reais da árvore de widgets. Nenhuma arte de
  divulgação, nenhum mockup fantasiado.
- O ciclo de hora do dia mostra três momentos: amanhecer, entardecer e
  noite. `habitat-dia.png` ficou de fora porque é quase idêntico ao
  amanhecer (diferença média de 8,7 em 255 por canal) — a troca parecia
  quebrada.
- Os nomes e humores dos 9 companheiros vêm do código do app
  (`lib/models.dart` e o catálogo pt de `lib/l10n.dart`), incluindo as
  legendas de humor, palavra por palavra — com os marcadores `{p}`/`{P}`
  resolvidos como o app faz em `comPronome`, senão Nina, Mel e Faísca
  apareciam com "Ele te esperou".
- A paleta passa em WCAG AA em todos os pares de texto medidos. O verde de
  ação é `#428130` porque `#58A445` dava só 3,08:1 com o texto branco do
  CTA principal.
- A página não afirma que o app está nas lojas, porque não está.

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

O formulário grava em `public.baru_waitlist` no Supabase. Dois passos:

**1. Aplique a migração** (uma vez, por um humano com acesso ao projeto):

```
cd baru_app
supabase db push
```

Ou cole `baru_app/supabase/migrations/20260828100000_baru_waitlist.sql` no
SQL Editor.

**2. Defina a chave anon como variável de ambiente no Netlify**, em
Site settings → Environment variables:

```
SUPABASE_ANON_KEY = <a chave publishable/anon do Dashboard → Settings → API>
```

Depois é só um novo deploy. O `netlify.toml` na raiz roda
`node landing/injeta-config.js`, que troca o `anonKey: ""` do `index.html`
pela chave — assim ela nunca entra no repositório.

O script recusa o build se você colar por engano a `service_role` ou uma
`sb_secret_`: publicar essa chave seria acesso total ao banco. Sem a
variável definida, o build passa normalmente e o formulário só fica
escondido.

Para rodar o mesmo passo localmente:

```
SUPABASE_ANON_KEY=... node landing/injeta-config.js
python3 -m http.server -d landing 8000
```

### Por que a chave pode ir para o HTML publicado

A chave anon é feita para viver no cliente; ela já viaja dentro do app
mobile. Quem protege a lista é o banco, não o segredo da chave:

| Camada | O que faz |
|---|---|
| RLS ligada, **zero policies** | `anon` e `authenticated` não leem, não inserem e não apagam a tabela por PostgREST |
| `baru_waitlist_entrar`, SECURITY DEFINER | única porta de entrada; só insere |
| Resposta constante | e-mail novo e e-mail repetido devolvem o mesmo `ok`, então ninguém descobre quem já se cadastrou |
| Freio por IP | 5 cadastros por hora vindos do mesmo `x-forwarded-for` |
| Isca no formulário | campo escondido que só robô preenche |

Para **ler** a lista, use o dashboard do Supabase (Table Editor) ou a
`service_role` — nunca a chave anon.

O comportamento foi verificado num Postgres 16 local com os papéis `anon` e
`authenticated`: inserção pela função funciona, `select`/`insert`/`delete`
diretos são negados, e-mail repetido não vaza, e a sexta tentativa do mesmo
IP em uma hora é barrada.

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

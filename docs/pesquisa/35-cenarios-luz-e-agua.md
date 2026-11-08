# 35 — Cenários, luz e água: uma lagoa do Cerrado em vetor chapado

Data: 08/11/2026 · Escopo: o mundo da home (`pinta_mundo.dart`, `mundo.dart`,
`habitat.dart`, `arte_dos_itens.dart`), o que o bicho faz na água
(`pet.dart`) e as quatro folhas de cenário que a série usa
(`novelinha-ep1/assets/img/app/fundo-*.webp`, `frente-*.webp`, 4800×2700)
montadas pelo `b4.js` em 1080×1920. Cobre: a paisagem real do Cerrado e como
se estiliza um bioma; paleta por hora do dia (com hex); céu, sol, lua,
estrelas, vagalumes, lanterna; água (linha, reflexo, ondulação, respingo,
entrada e saída, profundidade vista de dentro); paralaxe e camadas;
composição vertical e zona segura; contraste bicho × fundo; detalhes vivos
de fundo e sua frequência. Não reabre: painter procedural como fonte única
(a arte da série é só a do app); chaves das espécies.

Convenções (as dos laudos 05, 21 e 30):

- **[Fato]**: afirmação com fonte externa, lida em 08/11/2026; o link está
  na seção "Fontes".
- **[App]**: observação do código ou das imagens, com arquivo:linha.
- **[Opinião]**: inferência ou valor de partida meu, sem fonte, para afinar
  no aparelho. Quando um número é **derivado** de um fato (ex.: cm → px),
  digo de onde veio.

Avança em relação aos laudos anteriores: o 03 (§1.3, §4.10) pediu "camadas
fixas, escala fixa, assinatura por habitat, SVG em camadas" e o 05 (R9,
§6.2) pediu itens desenhados e transição de luz de 2 s. Nenhum dos dois
descreve **o que é uma lagoa do Cerrado**, **que cor o céu tem às 18h**, **o
que a água faz quando um bicho entra**, **onde o horizonte cai num vídeo
vertical** nem **por que a noite do app não tem luz própria**. Este laudo faz
isso, com número, e aponta o que está errado nas quatro imagens que a série
usa hoje.

---

## Resumo em 12 linhas

1. **A paralaxe do app já é boa** (8 frações: 0,03 astro · 0,04 estrelas ·
   0,1 nuvens · 0,2 chapadas · 0,45 colinas · 0,72 árvores · 1,0 chão · 1,25
   capim; `pinta_mundo.dart:65-181,537`), no mesmo espírito do exemplo de 5
   camadas da Godot (0,1→0,7) e da regra 1/3–2/3–1 [Fato]. **A série joga
   isso fora**: achata tudo em 2 imagens (`fundo`, `frente`; `b4.js:135-152`)
   e só a câmera faz zoom. O ganho barato é exportar 5 camadas e movê-las
   com `cx` em frações.
2. **A cena não é um lugar do Cerrado.** A lagoa de um Cerrado de chapada é
   uma **vereda**: fundo de vale raso (100–300 m de largura) com uma **faixa de
   buritis** (palmeira ereta de até 25 m, leque de folhas no ápice, numa
   faixa estreita de 15–45 m no fundo brejoso), campo úmido graminoso no
   meio e cerrado nas bordas
   [Fato, Embrapa]. Hoje: 6 árvores-pirulito iguais, zero buriti, colinas em
   semicírculo num bioma de relevo "plano a suave-ondulado" [Fato].
3. **A luz do app não obedece à hora.** O sol fica no mesmo x (0,78 w) e a
   30 % da altura acima do horizonte **no entardecer** (`:77-82`;
   `astroAlto` 0,16), quando a hora dourada é o sol a **±6° do horizonte**
   [Fato]. Sol e lua nascem e se põem no mesmo canto. O céu do dia é creme
   (#F4E6CB→#FAF1E3), sem nenhuma cor fria em toda a paleta.
4. **A noite não tem luz própria.** A lua (`#E8E6F2`) não se reflete na água;
   a lanterna tem halo (`arte_dos_itens.dart:902-911`) mas não ilumina nada;
   os vagalumes ficam **no céu, na altura das nuvens** (ancorados ao topo:
   `habitat.dart:797,830`); a grama continua verde-saturado sob 20 % de véu
   (`sombraAmbiente 0x33`); o bicho **não recebe tinta nenhuma** da hora
   (nada em `mundo.dart` passa `luz` ao `PetView` além da cor da água,
   `:603-605`). Pelo efeito Purkinje, de noite o vermelho escurece primeiro e
   tudo vai ao azul-verde dessaturado [Fato].
5. **A lanterna pende do nada**: corda nasce em y = 8 do palco
   (`models.dart:277`), palco ancorado pelo topo (`habitat.dart:830`); na
   captura ela começa a 4 % do topo do quadro, no céu, e cobre o sol/lua.
6. **A água é uma faixa sem vida**: 16 tracinhos brancos de 10–28 px
   (`:445-457`), contraste de luminância água × grama de **1,35:1**
   (#C9DCC0 × #A6C28C), margem de lá reta, sem reflexo da margem, do céu, da
   lua ou dos juncos, sem raso→fundo.
7. O que "está dentro d'água" exige, com fonte: corpo cortado na linha
   (feito, `pet.dart:2566-2585`), parte submersa **comprimida a 0,75 e
   deslocada** (profundidade aparente = 1/1,33) [Fato], anéis que nascem no
   corpo e se afastam (velocidade mínima de fase 23 cm/s, λ 1,7 cm) [Fato],
   **esteira em V de 39°** quando nada, independente da velocidade, "até
   patos" [Fato], coroa + jato de retorno + gotas no respingo [Fato], bolhas
   embaixo (feito).
8. Visto de dentro, o mundo de cima cabe numa **janela de Snell de ~97°**,
   fora dela é escuro/espelho do fundo, o brilho cai a zero na borda, ondas
   distorcem, turbidez vela [Fato]; a água absorve o **vermelho primeiro**
   [Fato] → embaixo é ciano-verde, nunca o bege da areia.
9. **Vídeo vertical**: a legenda está em y = 1440–1680 (`b4.html:18-20`),
   dentro dos **35 % inferiores** que o Reels cobre com legenda/CTA
   (672 px) e dos 20 % inferiores do TikTok [Fato]. O plano aberto
   (`z = 0,40`, `cy = 700`) deixa **29 % do topo e 26 % do pé em cor
   chapada** porque a captura é 16:9 (1600×900 lógicos @3).
10. **Regra de silhueta**: Gurney manda decidir cada forma como clara ou
    escura e agrupar valores; Hilda usa contraste como guia do olho porque a
    animação é mínima [Fato]. Critério: luminância bicho × fundo atrás dele
    ≥ 2:1 nas 4 horas (a medir nas 36 capturas `home-*`; o caso crítico é
    o Toco, verde sobre grama).
11. **Detalhes vivos**: ação secundária "enfatiza, não tira atenção" [Fato].
    Hoje 70 tufos + 18 juncos + 6 árvores + 16 brilhos oscilam em seno
    contínuo e independente (períodos 4,5–10 s). Proposta: **um campo de
    vento** com rajadas a cada 6–12 s propagando-se em x, e **um evento por
    8–15 s** (pássaro, peixe, folha) — nunca dois ao mesmo tempo.
12. Prioridade: R1 sol/lua e paleta por hora (alta, P) → R2 noite com luz
    própria (alta, M) → R3 lanterna e vagalumes no chão (alta, P) → R4 água
    com reflexo e margem (alta, M) → R5 entrada/saída e nado (alta, M) → R6
    composição vertical e legenda (alta, P) → R7 vereda com buritis e
    chapadas (média, M) → R8 camadas na série (média, M) → R9 vento e
    eventos (média, M) → R10 tinta da hora no bicho (média, P) → R11 fundo
    da lagoa por dentro (baixa, M) → R12 estação seca/chuva (baixa, P).

---

## 1. O que o app faz hoje [App]

### 1.1 Geometria e camadas (`mundo.dart:49-105`, `pinta_mundo.dart:42-186`)

| Camada | Fator da câmera | Onde / tamanho | Linhas |
|---|---|---|---|
| Céu | 0 (fixo) | degradê vertical de 2 cores com 3 paradas `[0, 0.5, 1]` → a **metade de baixo é chapada** | `pinta_mundo.dart:51-60` |
| Estrelas (só à noite) | 0,04 | 60, raio 0,6–1,8 px, só nos 42 % superiores de h, alfa 0,35 ± 0,35 em seno de 0,8–1,8 rad/s (período 3,5–7,9 s) | `:62-74` |
| Astro | 0,03 | r = 30 + halo r = 64; `x = 0,78 w`; `y = h·(0,09 + (1 − astroAlto)·0,16)` | `:76-82` |
| Nuvens | 0,1 | 6, largura 90–200 px, andam 4–9 px/s, y em 10–32 % de h; à noite alfa 0,10 | `:84-96` |
| Chapadas | 0,2 | uma faixa, base 0,53 h, altura 0,09 h, topo reto + encosta (`_chapadas`) | `:98-115, 211-245` |
| Colinas | 0,45 | semicírculos (`silhuetaDeColina`), base horizonte + 0,04 h, altura 0,06–0,12 h | `:117-143` |
| Árvores de baru | 0,72 | 6, altura 0,15 h × (0,7–1,25), copa = 5 círculos, tronco bézier, balanço `sin(t·0,6)·altura·0,01` | `:145-175, 247-291` |
| Chão, toca, trilha, lagoa, juncos, tufos | 1,0 | ver 1.2 | `:177-181, 293-501` |
| Capim da frente | 1,25 | talos 3–5,5 px, altura 3,5–8,5 % de `visivel`, balanço ±4 px; **só à esquerda da beira** | `:508-559` |

Alturas em fração de `visivel` (a parte da tela acima do painel):
horizonte 0,69 · pés 0,86 · lâmina d'água 0,905 (`mundo.dart:76-80`). O
mundo tem 2,6 telas de largura; a lagoa é o 30 % final (`ZonasDoMundo`,
`mundo.dart:34-43`).

Na captura usada pela série (`cenario_nov_test.dart:138`, `pixelRatio: 3`
sobre `_tela = 1600×900` lógicos, `:32-33` → 4800×2700; câmera em
`beira − 0,58·largura`, `:65`) o horizonte cai em y ≈ 1863 (69 %), o topo
da água (`linhaDagua − 40·e`) em ≈ 2200 (82 %) e a lâmina em ≈ 2443
(90 %); o bicho mede 894 px (33 % da altura).

### 1.2 O chão e a lagoa (`_chao`, `pinta_mundo.dart:293-501`)

- Campo: degradê `grama → gramaFunda`, onde `grama = lerp(colina, #8DB06A,
  0,55)` ≈ **#A6C28C** e `gramaFunda ≈ #82A46D` (`:297-322`). Manchas
  elípticas 16–24 % de alfa como "perspectiva" (`:324-350`).
- Trilha de terra: bézier com desvios de 4–22 px numa largura de milhares
  de px → na captura vira uma **faixa reta** clara em y ≈ 88 % (`:352-361`;
  visível em `fundo-dia.webp` à esquerda).
- Lagoa: caminho de `beira − 40` até a borda direita, margem de lá em
  `lineTo(largura, topoDaAgua − 6)` → **linha reta**; degradê `agua →
  funda` de cima para baixo; margem de areia = o mesmo caminho deslocado
  (−10, −6) (`:420-444`).
- "Reflexos": 16 traços horizontais de 10–28 px, 2 px, cor `luz.brilho`,
  oscilando ±6 px (`:445-457`). Nenhum reflexo de céu, lua, lanterna,
  juncos, árvore ou margem.
- Juncos: 18 linhas de 3 px, 18–35 un., balanço ±2 px (`:458-472`).
- Tufos: 70 × 3 traços, balanço `sin(t·1,4 + x/40)·2·s`; flor a cada 5
  (rosa #E9A0C4 / creme #FFF4C9) (`:474-500`).
- Véu da hora por cima de tudo: `sombraAmbiente` (noite `0x33232033` = 20 %;
  entardecer 8 %; amanhecer 5 %; dia 0) (`:183-185`).

### 1.3 As quatro luzes (`habitat.dart:233-300`)

| Período (`models.dart:61-67`) | céu alto → baixo | astro / halo | água / funda | colina | areia | brilho | véu | `astroAlto` |
|---|---|---|---|---|---|---|---|---|
| amanhecer 5–9 h | #F6D9B0 → #F9E9CF | #FFC98A / 33 % #FFB870 | #CFDCC4 / #B5C8A8 | #CBD6B4 | #E8D5B4 | 40 % #FFF3E0 | 5 % | 0,22 |
| dia 9–17 h | **#F4E6CB → #FAF1E3** | #FFD79A / 27 % #EF8354 | #C9DCC0 / #AECBA3 | #C5D8B6 | #E9D6B6 | 53 % branco | 0 | 0,86 |
| entardecer 17–20 h | #F3C9A0 → #F9DFC0 | #FF9E5E / 40 % #EF8354 | #C2CFAE / #A6B896 | #B9C6A2 | #E0C39C | 47 % #FFD9A8 | 8 % | 0,16 |
| noite 20–5 h | #4A4763 → #7A7189 | #E8E6F2 / 27 % #CFD6F0 | #5B6B63 / #47554F | #5E6660 | #8A7E6E | 33 % #D6DCF5 | 20 % | 0,74 |

Leituras diretas da tabela:

- **Não há azul em nenhum período.** O céu de dia é creme; a noite é um
  cinza-lilás (#4A4763: luminância relativa ≈ 0,07) **mais claro** embaixo
  (#7A7189) sem nenhuma fonte de luz no horizonte que justifique.
- O sol do **entardecer** fica em `y = h·(0,09 + 0,84·0,16) = 0,22 h`, e o
  horizonte das chapadas está em 0,53 h: o sol "se pondo" está a **31 % da
  altura acima do horizonte**. No **amanhecer**, idem (0,21 h), **no mesmo
  x**. Nasce e se põe no mesmo canto e nunca toca a linha.
- A `lagoa` tem `forca: 0` de propósito (`habitat.dart:75-85`): a cena da
  home é exatamente a tabela acima, sem tinta de habitat.

### 1.4 Itens pendurados do céu (`habitat.dart:797-850`, `models.dart:276-470`)

`_doCeu = {lantern, varal_de_luzes, nuvens, vagalumes, neve}` ancora pelo
`topCenter` da caixa das peças (`:829-830`). O palco dos itens é um
retângulo de 372×296 un. escalado, posto **sobre a lagoa** com o topo em
`linhaDagua + 118·k·0,55 − 296·k` (`mundo.dart:490-499`). A lanterna tem a
corda em `y = 8` (`models.dart:277`); logo a corda nasce no topo do palco e
**não está presa a nada**. Na captura `fundo-*.webp` ela começa a **4 % do
topo do quadro**, no meio do céu, e o halo cobre sol e lua (x = 0,70 w).

Os vagalumes são 5 pontos em `y = 52–88` do mesmo palco (`models.dart:464-
468`) → ficam na faixa das nuvens (visível em `fundo-noite.webp`: três
pontos a y ≈ 24–34 % do quadro, acima das chapadas). `_lampiao` desenha um
halo radial de raio 1,5× o corpo com alfa 0,45 pulsando a 5 ciclos/fase
(`arte_dos_itens.dart:902-911`), mas o halo **não toca o chão, a água nem
o bicho**: é um disco solto.

### 1.5 O bicho na água (`pet.dart:2278, 2566-2585, 6232-6340`)

Está certo, e vale manter:

- A lâmina é em coordenadas do widget, não do corpo (`:2273-2278`): "água
  que sobe e desce junto com o bicho não é água, é adesivo".
- Recorte do corpo na linha (`clipRect`) + tinta da água por cima da parte
  submersa com `BlendMode.srcATop` e degradê de 22 px (`:2566-2585,
  6232-6250`); menisco só na largura do corpo (`_lamina`, `:6316-6340`).
- `_rastro`: 3 anéis elípticos (150×19, 112×14, 76×10 un.) presos ao ciclo
  da braçada, gotas de um lado por braçada, 3 bolhas subindo (`:6255-6313`).

O que falta (ver §2.4 e R5): a parte submersa não é comprimida nem
deslocada; os anéis são elipses concêntricas centradas no corpo que
**não se afastam** além de 30 %; não há esteira em V; não há respingo de
entrada (coroa, jato, gotas em queda) nem saída (água escorrendo, pelo
molhado); nada do que o bicho faz chega ao `FundoDoMundo` (a lagoa não sabe
que tem alguém dentro).

### 1.6 A série (`b4.js:133-157, 260-278, 337-339`; `b4.html:18-20`)

- `MX = −1667, MY = −315, MW = 3840, MH = 2160`: a captura 4800×2700 entra a
  **0,8×** num mundo de 1080×1920; acima de `y = −315` um retângulo de céu
  chapado (`#E6BD96` entardecer, `#413F59` noite), abaixo de `y = 1842`
  retângulos de chão/água chapados (`chao(...)`, `:146-147`).
- Duas camadas da arte do app (`fundo`, `frente`) + um recorte de água
  desenhado à mão no SVG (`aguaFrente`, `:149-151`). **Nenhuma paralaxe**:
  tudo se move junto com `cx`.
- Plano aberto `ABERTO = [780, 700, 0,40]` (`:260`): o quadro mostra
  4800 px de altura do mundo; a imagem ocupa de 29 % a 74 % do quadro; o
  horizonte cai em **60 %**; **29 % do topo e 26 % do pé são cor chapada**.
- Entardecer → noite por *crossfade* de opacidade das quatro imagens em
  1,8 s (`:337-339`) — correto como técnica (sem soma de camadas), mas a
  única coisa que muda é a imagem: nenhuma luz nova aparece.
- Legenda: `.fala{top:1440px}` com chip de 60 px + texto de 74 px em até 2
  linhas (`b4.html:18-20`) → ocupa **y = 1440–1680 (75–87,5 % do quadro)**.

### 1.7 Leitura das quatro imagens (Read em 08/11/2026)

`fundo-dia.webp`, `fundo-entardecer.webp`, `fundo-noite.webp`,
`frente-dia.webp` (4800×2700, vistas inteiras):

1. **Lanterna pendurada do céu** (as três `fundo-*`): corda vertical do
   topo do quadro até o balão, a x ≈ 0,71 w; sobre ela, o sol (dia e
   entardecer) ou a lua (noite) a x ≈ 0,75 w — o astro fica **atrás** do halo
   da lanterna. No entardecer o sol está escondido pela nuvem e pela
   lanterna ao mesmo tempo.
2. **Mesma composição nos três horários**: as nuvens estão nos mesmos
   lugares; só a cor muda. Nada "acontece" entre 14 h e 22 h.
3. **Noite sem noite**: grama #7E9A63-ish e copas verdes, areia clara,
   deque de madeira na mesma cor do dia; estrelas de 1–2 px num céu que
   clareia para o horizonte; três vagalumes no céu; a lua sem reflexo;
   tracinhos brancos na água iguais aos do dia. O único escuro de verdade é a
   boca da toca.
4. **Água**: faixa verde-acinzentada quase da mesma luminância da grama;
   margem de lá reta em y ≈ 82 %; os anéis dos pés do deque são elipses
   estáticas; não há raso claro junto à margem nem fundo escuro; os 18
   juncos ficam **em cima** da linha da margem, sem reflexo.
5. **Chapadas e colinas**: as chapadas (trapézios de topo reto, mais claras
   que as colinas) lêem bem como Cerrado; as colinas em semicírculo na frente
   delas lêem como "desenho de criança de morro", não como campo de chapada.
   Não há nada entre as árvores (0,72) e o chão (1,0): a margem de lá da
   lagoa não tem vegetação de vereda.
6. **Árvores**: seis cópias de um mesmo desenho (copa = 3 círculos + 2
   claros). Nenhuma assinatura de baru (copa densa arredondada, sim; mas
   tronco fino demais e sem a escala de 25 m: a árvore maior mede 208 px
   lógicos = 0,23 da altura visível (`pinta_mundo.dart:169`, `h = 621/0,56`)
   e o bicho 298 px = 0,33 (150 un. × escala 1,99, `mundo.dart:56-62`) →
   **a árvore tem 0,7 capivara de altura**).
7. **Trilha** = faixa horizontal clara com bordas retas, de x = 0 a 0,47 w.
8. **`frente-dia.webp`**: só talos de capim num único verde (#7E9A63),
   altura 3–8 % do quadro, parando em x = 0,70 w; do lado da lagoa não há
   nada que emoldure.
9. Nenhuma sombra projetada em lugar nenhum (deque, árvores, lanterna,
   juncos); nenhuma indicação de direção da luz em nenhum horário.

---

## 2. O que as fontes dizem

### 2.1 A paisagem real: Cerrado de chapada com lagoa = vereda

- **[Fato]** O Cerrado ocupa o Planalto Central; 48,66 % da área está em
  latossolos de relevo **plano a suave-ondulado**. Clima Aw: chuvas de
  set/out a mar/abr (pico dez–fev), seca de abr/mai a set/out; "veranico" em
  janeiro. Máximas típicas 24–33 °C. Muitas árvores têm **casca grossa e
  suberosa** (contra fogo e calor). Espécies citadas: baru, pequi, buriti,
  ipês. ~800 espécies arbóreas. (Wikipédia pt, "Cerrado")
- **[Fato]** Fisionomias (RBGE, Edimburgo): *campo limpo* = só camada
  herbácea; *campo sujo* = com arbustos; *campo cerrado* = parque, árvores
  espaçadas; *cerrado sensu stricto* = savana arbórea densa com dossel
  aberto e **camada considerável de gramíneas**; *cerradão* = floresta de
  árvores de **7–12 m**, dossel fechado, que no tipo mesotrófico **perde as
  folhas na seca**. Camada herbácea do campo limpo ≈ **60 cm** (Wikipédia pt).
- **[Fato]** **Vereda** (Embrapa, "VI.3 Veredas", livro *Águas Emendadas*):
  ocorre "em áreas próximas às nascentes e nos fundos dos vales", solo
  saturado a maior parte do ano, **três zonas**: *borda* (solo mais seco,
  campo com arbustos e pequenas árvores isoladas), *meio* (alagamento
  sazonal, herbáceo-subarbustivo) e *fundo* ("solo permanentemente saturado
  com água, brejoso, onde ocorrem os buritis, muitos arbustos e arvoretas").
  Dois estratos: um
  herbáceo-graminoide que "ocupa a maior parte de sua área" e um
  arbóreo-arbustivo. A Vereda Grande tem ~6 km de extensão e **fundo de vale
  de 100 a 300 m de largura**; faixas de buritizal "estreitas" (15–45 m nos
  exemplos). Podem ser abundantes "em todas as chapadas do Brasil Central".
- **[Fato]** **Buriti** (*Mauritia flexuosa*): "palmeira ereta, de porte
  arbóreo com altura de até 25 metros, que apresenta folhas grandes em
  formato de leque que se destacam no ápice de seu caule"; frutos que
  "lembram a pele de cobra", polpa amarelada; frutifica jun–out (Embrapa).
  Tronco até 70 cm; cresce "em e perto de pântanos"; pode formar populações
  muito densas (Wikipédia en).
- **[Fato]** **Baru** (*Dipteryx alata*): até **25 m**, tronco até 70 cm,
  **copa densa e arredondada**, folhas compostas de 6–12 folíolos
  "verde-intenso", **perenifólia**, flores pequenas esverdeadas out–jan,
  fruto lenhoso castanho que amadurece set–out (Wikipédia pt).
- **[Fato]** Vereda (Wikipédia pt): terreno "suavemente inclinado e úmido",
  mantém umidade na seca, "refúgio de fauna e fonte de água para animais".
- **[Fato]** **Capivara**: olhos e orelhas "perto do topo da cabeça",
  permitem ver o entorno "quase submersa"; prende a respiração **até 5
  min**; pés levemente palmados; 106–134 cm de comprimento, 50–62 cm de
  altura; descansa em terra de manhã, **fica na água no começo da tarde
  quente**, pasta do fim da tarde até o amanhecer (Wikipédia en).
- **[Fato]** **Lontra neotropical**: dedos totalmente palmados, cauda longa
  e larga, pelagem castanho-acinzentada escura mais clara no focinho e
  garganta, **diurna**, prefere rios de água clara e corrente; 36–66 cm +
  cauda 37–84 cm (Wikipédia en).

**O que isso diz para a cena [Opinião, derivada]**: a "lagoa" do Baru deve
ser lida como vereda: **uma fila de buritis na margem de lá** (fustes
finos e altos, leques no topo, sem copa contínua), **campo úmido** baixo
(60 cm → joelho da capivara) entre a água e o cerrado, **barus** só na parte
alta e seca (borda/colina), chapadas de topo reto no horizonte, e **sem
colinas redondas**. Escala: buriti 25 m ≈ 20 capivaras de altura (0,6 m);
no quadro, com a capivara a 0,16 h, um buriti inteiro não cabe — o que cabe
é o **fuste** cortado pelo topo, e os leques só nos planos abertos.

### 2.2 Como estúdios estilizam um lugar real

- **[Fato]** Bluey (Catriona Drummond, diretora de arte da 1ª temporada):
  cor e luz devem ser "a simplified and slightly more vivid representation
  of the light in Brisbane", luz que "pinta tudo de dourado" com "sombras
  azul-elétricas" nos telhados; **"Always err towards more colourful
  choices with lighting"**; **"Do not use black lineart"** (contorno na cor
  do objeto afetada pela luz); **"Avoid neutral shadow tones. When in doubt,
  bump it cooler, or warmer than the local object"** (teste: sombra azulada
  na cerca funciona melhor que cinza); fundos "super simple"; "big,
  friendly, rounded rectangles"; "Keep objects cute, simplified and chunky,
  with doll house proportions"; "The majority of Bluey camera staging is
  straight ahead and very flat"; perspectiva de 2 pontos disfarçada de 1
  para ter chão largo; evitar objetos que bloqueiem os personagens; ela
  admite que não sabia desenhar árvores e usou "Bluey's very simple style to
  hide this fact", o que ficou "hard baked into the Bluey style" (Substack
  cap. 1 e 2; It's Nice That).
- **[Fato]** Hilda (Mercury Filmworks, Toon Boom): "the end goal when
  animating Hilda is for it to appear drawn all by the same hand"; fundos
  desenhados e coloridos como os personagens; paletas específicas; **como a
  animação é minimalista, o contraste guia o olhar** ("very important in
  Hilda"); "we approached lighting as part of the posing process" — luz
  aplicada aos rigs como etapa manual de direção de arte; *scene keys* fixam
  luz, encenação, cor e câmera antes de animar.
- **[Fato]** Alto's Odyssey (Harry Nesbitt): "a more minimalist,
  impressionistic approach"; reduzir aos componentes mais simples pede que
  o jogador "fill in the blanks"; "keeping things simple also makes it much
  more manageable" para equipe pequena; biomas "transition seamlessly into
  one another"; o estilo "had to be chipped away at slowly". (Não li nada
  sobre o ciclo de dia/noite deles: a página oficial só diz "dynamic
  lighting and weather".)
- **[Fato]** Rio (Blue Sky, CGW): Saldanha "wanted the city to look from
  afar like you're there"; calçadão e paralelepípedos **procedurais**;
  plantas crescem por regra "só em superfícies horizontais"; o diretor de
  fotografia brasileiro (Renato Falco) orientou o layout para parecer
  filmado ao vivo. Não achei fonte legível sobre a paleta.
- **[Fato]** Puffin Rock: Cartoon Saloon + Dog Ears; Lily Bernard indicada
  ao Annie por design de produção ("The First Snow"); pré-escolar; 47
  episódios (Wikipédia). A entrevista da AWN sobre o visual devolveu 403 e
  não foi lida — não afirmo nada sobre a técnica deles.
- **[Fato]** Câmera multiplano (Disney, 1937, *The Old Mill*): até **7
  planos** de vidro; "quanto mais distante da câmera, mais lenta a camada";
  variação: fundo e frente em direções opostas dá rotação (Wikipédia).
- **Não li**: Turma da Mônica, Irmão do Jorel (o TCC da UFMG está fora da
  rede permitida), Tainá, Hey Duggee, Pocoyo, Octonauts. Não faço
  afirmações sobre eles.

### 2.3 Luz por hora do dia

- **[Fato]** Hora dourada = sol de **+6° a 0°**; hora azul = **0° a −6°**
  (alguns autores: −4°); medido perpendicular ao horizonte. Perto do
  horizonte a luz direta atravessa ~10× mais atmosfera (≈1000 → ≈10 000
  g/cm²) e **perde o azul**: sol e objetos iluminados ficam
  progressivamente vermelhos **enquanto o azul do céu ganha saturação**;
  após o pôr, nuvens do oeste dão uma componente vermelha difusa e "a mistura
  de vermelho e azul gera roxos"; a hora azul é "quase monocromática"; **luz
  artificial (postes, janelas) só passa a contar na hora azul**; as sombras
  ganham detalhe porque a luz ambiente as preenche; "no nascer, tudo na
  ordem inversa" (Wrotniak).
- **[Fato]** Efeito Purkinje: em pouca luz a sensibilidade do olho vai para
  o azul (pico escotópico ≈ **500–507 nm** contra ≈ 555 nm fotópico); "o
  vermelho parece mais escuro em relação às outras cores à medida que a luz
  diminui"; o gerânio vermelho que brilha ao sol fica preto no crepúsculo
  enquanto folhas verdes e pétalas azuis ficam relativamente claras; em
  visão escotópica é praticamente preto e branco (Wikipédia).
- **[Fato]** Luar real ≈ **4000 K** (branco-quente); parece azul **por
  causa do Purkinje**; o azul da noite no cinema é convenção reconhecida
  pelo público (PremiumBeat).
- **[Fato]** Vagalumes: *Photinus pyralis* voa subindo em "J" com luz
  amarela sustentada, 20h30–21h30; *P. macdermotti* flash duplo com 1,5–2 s
  entre os dois e 4–5 s de pausa; *P. brimleyi* flashes únicos a 10 s ou
  mais, **fêmeas no chão**; *P. carolinus* 5–8 flashes e 8–10 s de escuro;
  *Photuris* branco "como flash de câmera"; *Phausis* azul-pálido contínuo
  30–40 s (NPS, Great Smoky Mountains). No Cerrado: larvas de *Pyrearinus
  termitilluminans* acendem **cupinzeiros** (verde), *Mastinomorphus*
  laranja; >2000 espécies estimadas no Brasil, 500 catalogadas; declínio
  forte desde os anos 1990 e a iluminação artificial é uma das causas
  (Agência FAPESP, 2010). Nenhuma das duas fontes dá altura de voo em
  metros; a do NPS põe fêmeas no chão e machos subindo de baixo.

**Paleta proposta por hora** [Opinião, derivada dos fatos acima; hex para
afinar no aparelho]. Mantém a identidade "papel quente" do app no dia, mas
introduz **uma cor fria por período** (regra do Bluey) e põe o sol onde a
física põe:

| Período | céu zênite → horizonte | astro (y) | grama perto / longe | água superfície / funda | sombras | véu |
|---|---|---|---|---|---|---|
| amanhecer | #A9BDD3 → #F7CFA6 (leste) | #FFD9A0 **no horizonte**, x = 0,15 w | #8FAE78 / #AFC3A4 (névoa) | #CBD6CF / #6F8A7E | frias, longas, #6C7A96 a 25 % | névoa branca 8 % na vereda |
| dia | #6FAFDC → #D7EBF4 | #FFF4CC pequeno (r 22), x = 0,55 w, y = 0,06 h, halo ≤ 10 % | #8FBF6A / #6E9E52 | #9CC6D2 (reflete céu) / #4F7A82 | curtas, #4E7A5A a 20 % | 0 |
| entardecer | #6B6FA8 → #E88A6A → #FFC98A | #FF9A52 **tocando o horizonte**, x = 0,85 w, r 36 | #A6A75C / #8B8F6B (quente) | faixa laranja #F2B07A junto à margem de lá / #3F4F5A | longas, roxas #5E4A6E a 30 % | #7A4A3A 8 % multiply |
| noite | #0F1A33 → #2B3F63 | lua #F2F0E6, r 26, halo #9FB3D6 15 %, x = 0,40 w, y = 0,10 h | #2F4A3A / #273D3A (dessaturado) | #152436 + trilha da lua #C9D6E6 30 % | — | véu azul #1B2A4A 30 % **antes** das luzes quentes |

Regra que une a tabela: **a cor fria é o céu de dia, a sombra de tarde e o
véu de noite; a cor quente é o sol, as luzes artificiais e o reflexo
deles**. Nada fica cinza neutro (Bluey).

### 2.4 Água

- **[Fato]** Cor da água: pura, absorve o vermelho; em dezenas de metros
  absorve tudo; "em oceanos vermelho, laranja e amarelo são absorvidos,
  restando verde, ciano e azul"; **verde = algas em suspensão**, **marrom =
  taninos/compostos orgânicos**, avermelhado = silte; a cor aparente da
  superfície é mistura de **reflexo do céu (depende do ângulo)** com a luz
  que volta das profundezas (Wikipédia, "Color of water"). NOAA: luz
  "significativa" raramente passa de 200 m; zona eufótica 0–200 m.
- **[Fato]** Refração: profundidade aparente ≈ **1/1,33 ≈ 0,75** da real
  (um objeto a 1 m parece a 0,75 m); a parte submersa de um bastão "parece
  deslocada para cima" e ele parece quebrado na linha d'água; com o ângulo
  tendendo a rasante, a reflexão aumenta (Wikipédia, "Refraction").
- **[Fato]** Janela de Snell: de dentro da água, **todo o hemisfério de
  cima cabe num cone de ~96–97°** (180° comprimidos), como olho de peixe;
  fora dele, "totalmente escuro ou o reflexo de objetos submersos" (reflexão
  interna total); **o brilho cai a zero na borda**; ondulações distorcem ou
  desfazem a imagem; turbidez a vela com luz espalhada (Wikipédia).
- **[Fato]** Ondas capilares: comprimento crítico **λm = 1,7 cm**,
  velocidade de fase **mínima 23 cm/s**; ondas bem menores que λm são de
  tensão superficial, bem maiores são de gravidade; "ao cair uma pedra ou
  gota, as ondulações se propagam para fora de um círculo em expansão";
  nas de gravidade a velocidade de grupo é metade da de fase (as cristas
  nascem atrás do grupo e morrem na frente) (Wikipédia).
- **[Fato]** Esteira de Kelvin: meio-ângulo **arcsin(1/3) ≈ 19,47°**, V
  total ≈ **39°**, **independente da velocidade e do tamanho** numa faixa
  ampla — "patos e cisnes" produzem o mesmo V; dentro do V há ondas
  transversais em arco; a velocidade maior estreita um segundo V de ondas
  divergentes (Wikipédia).
- **[Fato]** Respingo: uma gota ao bater forma uma **coroa (corona)**
  simétrica (fotos de Edgerton); há um **"back-jet"** (jato de retorno) e
  gotas aéreas secundárias; regido por Reynolds e Weber; Worthington (1908)
  foi o primeiro a fotografar (Wikipédia, "Splash"). Gilland, *Elemental
  Magic*: "animating special effects is essentially animating energy";
  fatores "water density, force, gravity, viscosity, after splash";
  "remove details and yet keep things realistic" (resenha Parka Blogs — o
  livro em si não foi lido).
- **[Fato]** Princípios Disney (Thomas & Johnston 1981, via Wikipédia):
  *follow through* = partes soltas continuam depois que o corpo para;
  *overlapping action* = partes se movem em ritmos diferentes; *slow
  in/out* = mais quadros no início e no fim.

**Tradução para px [Opinião, derivada]**: se a capivara (106–134 cm) mede
~180 un. no desenho, **1 cm ≈ 1,5 un.** Então: anel novo a cada 0,45 s
(≈ 2 braçadas/s não; 1 por braçada), **expandindo a 35–60 un./s** (23–40
cm/s), espaçamento entre anéis ≥ 3 un. (λm), vida de 1,8 s com alfa
0,35 → 0; esteira: duas linhas a ±19,5° da direção do nado nascendo no
focinho, com 2–3 arcos transversais entre elas; parte submersa desenhada
com `scale(1, 0,75)` a partir da linha d'água e deslocada 3 un. para o
lado contrário ao olhar ("bastão quebrado"); respingo de entrada: 1 quadro
de coroa (anel de 6–8 gotas a 0,4 do corpo de altura) → jato central
subindo por 4–6 quadros a 30 qps até 0,6 corpo → gotas caindo por 10–14
quadros com gravidade → anéis. Saída: 6–10 quadros de água escorrendo do
ventre (3–5 gotas, *follow through*) + faixa de pelo molhado 15 % mais
escura por 2 s.

### 2.5 Paralaxe, camadas e composição vertical

- **[Fato]** Godot, exemplo oficial de 5 camadas: céu 0,1 · nuvens altas
  0,2 · nuvens baixas 0,3 · colinas 0,5 · floresta 0,7 (todas 1 em y);
  `scroll_scale` < 1 afasta, > 1 aproxima; a textura precisa ser ≥ viewport
  e repetir sem emenda; zoom para fora quebra o efeito se a arte for
  pequena. K-State: camada do jogador 1, trás 2/3 e 1/3; "camadas à frente
  do jogador rolam mais rápido e são maiores".
- **[Fato]** Regra dos terços: horizonte na linha superior ou inferior,
  "não no meio", para não ficar estático; Smith (1797) propunha 2/3 de céu
  ou 2/3 de terra (Wikipédia). (Ressalva da própria fonte: um estudo de
  2014 achou pouco efeito em grandes coleções.)
- **[Fato]** Zonas seguras 1080×1920 (House of Marketers): **Reels — 14 %
  no topo (≈269 px), 35 % embaixo (≈672 px), 6 % de cada lado (≈65 px)**,
  área central ≈ 1010×1280; **TikTok — evitar 10 % no topo, 20 % embaixo
  (≈384 px) e a coluna direita dos ícones**; Stories — legendas a 10–12 %
  da base, logo acima da barra. (Fonte de agência, não oficial; os px são
  cálculos a partir das porcentagens.)

### 2.6 Contraste e silhueta

- **[Fato]** Gurney, "Cure for middle value mumbling": o vício de "misturar
  todas as cores em tons médios"; cura: "Define all the shapes as either
  white or black", "Let one black area run into another", não desenhar
  contorno nem meio-tom; "as decisões de agrupamento de valores são a chave
  da boa composição tonal".
- **[Fato]** Hilda: contraste "very important" porque a animação é
  minimalista — é ele que leva o olho.
- **[Fato]** Bluey: contorno na cor do objeto, sombras sempre mais frias ou
  mais quentes que o local.

### 2.7 Detalhes vivos e frequência

- **[Fato]** Ação secundária: "the important thing about secondary actions
  is that they emphasize, rather than take attention away from the main
  action"; se distraem, tiram-se (Thomas & Johnston via Wikipédia).
- **[Fato]** Alto's: minimalismo pede que o espectador "preencha as
  lacunas".
- **[Fato]** Capivara entra na água no começo da tarde quente e pasta do
  fim da tarde ao amanhecer; vagalumes aparecem **20h30–21h30** e depois
  (NPS); buriti frutifica jun–out; baru floresce out–jan e frutifica set–out;
  chuva out–mar, seca abr–set. Isto dá um **calendário** para o fundo, não
  só um relógio.

---

## 3. Proposta: a lagoa como lugar, em camadas e por hora

### 3.1 Camadas (app e série)

| # | Camada | Fator x | Conteúdo | Muda com a hora |
|---|---|---|---|---|
| 0 | céu | 0 | degradê de **4 paradas** (zênite, meio, horizonte, linha) | tudo |
| 1 | astros | 0,03 | sol **ou** lua, cada um no seu lado; estrelas (noite); Via Láctea opcional | posição e cor |
| 2 | nuvens altas / baixas | 0,15 / 0,3 | 3 + 3, deriva 2–6 px/s, **cor pela hora** (laranja embaixo no entardecer) | cor e alfa |
| 3 | chapadas | 0,2 | topo reto; **2 fiadas** (longe lerp 0,65 com o céu; perto 0,4) | névoa |
| 4 | **margem de lá: buritizal** | 0,5 | 5–7 fustes finos, leques no topo que não se tocam; cerrado baixo atrás | silhueta + reflexo |
| 5 | barus | 0,72 | 3 árvores **2,5× o bicho**, copa densa, tronco com casca grossa | sombra projetada |
| 6 | chão + lagoa | 1,0 | campo úmido, margem com raso claro, água com **reflexo invertido** das camadas 1, 4 e 5 | reflexo e luz |
| 7 | eventos | 1,0 | pássaro, peixe, folha, libélula | horário |
| 8 | capim da frente | 1,25 | talos **em 2 tons** à esquerda; **lírios/juncos cortados** à direita | tinta da hora |

Na série, exportar **5 PNGs** (céu+astros, chapadas, buritizal, chão+lagoa,
frente) e mover com `translate((cx − 540)·(1 − fator))` dentro do `cam`
(`b4.js:333`); as camadas 0–3 ganham 15 % de largura extra para o
deslocamento não mostrar borda (regra Godot: textura ≥ viewport).

### 3.2 O que a água faz **por causa** de cada coisa (uma tabela para o `_chao`)

| Coisa sobre/na água | O que a água mostra | Números de partida |
|---|---|---|
| sol/lua | trilha vertical de reflexo sob o astro, largura = 0,6 do disco, quebrada em 6–10 traços horizontais que oscilam | alfa 0,30 lua / 0,45 sol baixo; só quando `astro.y` < horizonte + 0,1 h |
| buritis e barus da margem de lá | silhueta **invertida** a partir da linha, altura 0,8 da real, alfa 0,35, 3 px mais escura que a água | parte em 4–6 segmentos horizontais deslocados ±2 px (ondulação) |
| lanterna | mancha quente radial no chão/água (raio 3× o balão) + reflexo invertido pulsando junto | #FFB866, alfa 0,35 no pico; sombra da própria haste |
| vagalumes | ponto de reflexo de 1 px sob cada um quando voa sobre a água | alfa = 0,5 × a do vagalume |
| juncos | reflexo invertido curto (0,5 da altura) | alfa 0,3 |
| bicho boiando | anéis saindo + V de 39° ao nadar + corpo comprimido 0,75 | §2.4 |
| vento | 2–3 **faixas** de textura (não traços soltos) que atravessam a lagoa quando a rajada passa | 1 px mais claras, 40–120 px de comprimento, velocidade da rajada |
| raso junto à margem | faixa 6–10 px mais clara (areia vista através) + linha de margem 1 px mais clara (menisco) | `agua` lerp areia 0,35 |

### 3.3 Hora como estado contínuo, não 4 fatias

`LuzDaCena` vira uma função de `horaDecimal` que **interpola entre 8
chaves** (5, 6, 8, 12, 16, 17.5, 19, 21 h) em vez de 4 constantes, e a
posição do astro vem de `elevacao(hora)`: nasce (x = 0,12 w) às 6h e se põe
(x = 0,88 w) às 18h; `y = horizonte − sin(elev)·0,45 h`. A transição de 2 s
que o laudo 05 pede (§6.2) passa a ser gratuita. [Opinião; o ângulo real
varia com a estação — nascente 6h/18h é o Cerrado no equinócio.]

---

## 4. Recomendações priorizadas

Formato: **o que mudar · onde · aceite · prioridade · fonte**.

### R1 — Sol e lua no lugar certo, e uma cor fria por período (alta, P)

- **O que**: `astroAlto` passa a determinar y **a partir do horizonte**
  (`y = horizonteDoCeu − astroAlto·0,45 h`), com `astroAlto` 0,02 no
  entardecer (disco tocando a linha, r 36, halo 0,5 → #FF9A52), 0,08 no
  amanhecer (do lado oposto: `x = 0,15 w`), 0,95 no dia (r 22, halo ≤ 10 %),
  lua a `x = 0,40 w`. Céu com 4 paradas (`stops [0, 0.35, 0.8, 1]`), e a
  paleta da tabela de §2.3 (dia com zênite #6FAFDC; entardecer com faixa
  roxa #6B6FA8 no alto).
- **Onde**: `pinta_mundo.dart:51-82`; `habitat.dart:233-300` (`LuzDaCena.de`).
- **Aceite**: nas capturas `home-*-entardecer.png` o centro do sol fica a
  ≤ 0,03 h da linha das chapadas; em `-amanhecer` o sol está no terço
  esquerdo; em `-dia` nenhum pixel do céu tem `R > B`; nenhum período tem o
  astro atrás de um item.
- **Fonte**: hora dourada ±6° e ordem inversa no nascer (Wrotniak); "err
  towards more colourful choices" e "bump it cooler or warmer" (Bluey).

### R2 — Noite com luz própria (alta, M)

- **O que**: (a) véu azul #1B2A4A a 30 % (multiply) **antes** de desenhar as
  luzes; (b) grama/copas/areia dessaturadas 40 % e 35 % mais escuras (o
  verde fica relativamente claro, o vermelho/laranja escurece — Purkinje);
  (c) lua com **trilha de reflexo** na água; (d) estrelas: 120 pontos, só
  3–5 "piscam" (±10 % de alfa, não ±35 %), os outros fixos; faixa leitosa
  diagonal opcional (alfa 6 %); (e) o céu **escurece para o horizonte** só
  se houver luz lá (cidade); sem cidade, o horizonte é um azul **um pouco**
  mais claro (#2B3F63) e o zênite o mais escuro (#0F1A33); (f) toda luz
  quente (lanterna, fogueira, varal, vagalume) pinta um disco no chão/água
  com `BlendMode.plus` limitado a 35 % e tem reflexo invertido na água.
- **Onde**: `pinta_mundo.dart:62-74` (estrelas), `:183-185` (véu → mover
  para antes dos itens, ou aplicar como `ColorFilter` no `Stack` de
  `mundo.dart:540-575`), `:445-457` (trilha da lua no lugar dos 16 traços),
  `arte_dos_itens.dart:886-990` (luz no chão + reflexo).
- **Aceite**: em `home-*-noite.png`, (1) a luminância média do campo cai
  para ≤ 45 % da do dia, (2) a saturação média (HSV) do campo cai ≥ 40 %
  em relação ao dia, (3) existe um reflexo da lua na água alinhado em x com
  a lua (± 0,02 w), (4) a lanterna tem um disco de luz quente no chão com
  raio ≥ 2× o balão, (5) **nenhum** pixel da grama tem saturação acima de
  45 %.
- **Fonte**: Purkinje (Wikipédia); luar 4000 K percebido azul (PremiumBeat);
  luz artificial só conta na hora azul (Wrotniak); "Avoid neutral shadow
  tones" (Bluey).

### R3 — Lanterna presa a algo; vagalumes no capim (alta, P)

- **O que**: retirar `lantern`, `varal_de_luzes` e `vagalumes` de `_doCeu`
  (deixar só `nuvens` e `neve`). A lanterna ganha uma **haste** (poste
  torto de 1,8× a altura do bicho fincado na margem, ou pendurada num galho
  de baru da camada 5) — a corda termina num ponto desenhado. Os vagalumes
  ficam entre `chao − 0,12 h` e `chao + 0,02 h` (do capim à cabeça do bicho),
  5–9 pontos, cada um com ciclo próprio: **flash de 0,4–0,8 s, intervalo
  2–6 s** (não seno contínuo), subindo em "J" de 20–40 px durante o flash;
  cor amarelo-verde #D9FF6A (Photinus) ou verde #9CFF8A fixo em 1–2 pontos
  no chão (cupinzeiro). Só existem das 20h30 em diante.
- **Onde**: `habitat.dart:797` (`_doCeu`), `models.dart:276-279, 463-468`
  (peças), `arte_dos_itens.dart:886-990` (`_lampiao`, `_vagalumes`),
  `mundo.dart:490-499` (palco: o topo não pode mais ser "o céu").
- **Aceite**: em qualquer captura com a lanterna, há um pixel de haste/galho
  contínuo entre a corda e o chão ou uma árvore; nenhum vagalume acima da
  linha das chapadas; num vídeo de 10 s, cada vagalume apaga por completo
  pelo menos 1 vez e fica aceso ≤ 0,8 s por vez.
- **Fonte**: padrões de flash (NPS); fêmeas no chão, machos subindo (NPS);
  cupinzeiros luminosos no Cerrado (FAPESP); "objetos não bloqueiam os
  personagens" e "doll house proportions" (Bluey).

### R4 — Água com margem, raso, reflexo e vida (alta, M)

- **O que**: (a) margem de lá **curva** (bézier com 3 lóbulos) e 1 px de
  menisco claro; (b) faixa de raso (areia através da água, lerp 0,35) de
  6–10 px junto às duas margens; (c) degradê de cima para baixo com 3
  paradas: reflexo do céu (lerp `ceuBaixo` 0,5) → `agua` → `funda`
  (verde-marrom: lagoa de vereda tem alga e tanino, não azul); (d) **reflexos
  invertidos** dos buritis, juncos, lanterna e astro (tabela §3.2) cortados
  em 4–6 segmentos que deslizam ±2 px em contrafase; (e) os 16 traços viram
  **2–3 faixas de vento** que só aparecem com a rajada (R9); (f) contraste
  água × grama ≥ 1,8:1 de dia (hoje 1,35:1).
- **Onde**: `pinta_mundo.dart:420-472`; `habitat.dart:233-300` (`agua`,
  `aguaFunda`, `brilho`).
- **Aceite**: contraste de luminância (fórmula WCAG) entre a cor média da
  água e a da grama ≥ 1,8:1 em `dia`; em `-noite` existe um reflexo
  invertido para cada junco (contagem = 18) e para a lua; a linha da margem
  de lá não é um segmento reto por mais de 25 % da largura da lagoa.
- **Fonte**: cor da água (reflexo do céu por ângulo; algas verde; tanino
  marrom) (Wikipédia "Color of water"); reflexão cresce em ângulo rasante
  (Wikipédia "Refraction"); contraste como guia (Hilda); valores agrupados
  (Gurney).

### R5 — Entrar, nadar e sair da água com física legível (alta, M)

- **O que**: no `PetView`: (a) parte submersa com `canvas.scale(1, 0,75)`
  a partir da linha e deslocamento horizontal de 3 un. (bastão quebrado);
  (b) `_rastro`: anéis que **nascem no contorno do corpo e se afastam** a
  35–60 un./s até 2,2× a largura, alfa 0,35 → 0 em 1,8 s, novo anel a cada
  braçada; (c) ao nadar com `velocidade > 0`, **esteira em V de 39°**
  (duas linhas de 2 px a ±19,5° da direção, do focinho para trás, 1,6× o
  comprimento do corpo) com 2–3 arcos transversais entre elas; (d) entrada:
  antecipação 4–6 q (agacha) → impacto: **coroa** de 6–8 gotas a 0,4 do
  corpo de altura (1–2 q) → **jato central** 4–6 q até 0,6 do corpo → gotas
  caindo 10–14 q com gravidade → 3 anéis grandes; (e) saída: 3–5 gotas
  escorrendo do ventre por 6–10 q (*follow through*), faixa de pelo molhado
  15 % mais escura que some em 2 s; (f) o `FundoDoMundo` recebe
  `perturbacoes: List<(x, t0)>` e desenha os anéis **na lagoa**, não só no
  widget do bicho, para que o deque e os juncos balancem no reflexo.
- **Onde**: `pet.dart:2566-2585` (recorte), `:6255-6313` (`_rastro`),
  `motor_de_vida.dart`/`episodios.dart` (fases da entrada e saída),
  `pinta_mundo.dart:420-457` (anéis no mundo), `mundo.dart:399-410`
  (`_trocaDeLugar` dispara a perturbação).
- **Aceite**: folha de quadros de "pula na água" com ≥ 24 quadros a 30 qps
  em que o quadro de impacto tem ≥ 6 gotas acima da linha e o quadro +5 tem
  um jato central mais alto que as gotas; em "nada para a direita", as duas
  linhas da esteira medem 39° ± 3° entre si (medido na imagem); o anel mais
  velho tem diâmetro ≥ 2× a largura do corpo antes de sumir; a parte
  submersa do Baru tem altura ≤ 0,78 da que teria fora d'água.
- **Fonte**: profundidade aparente 0,75 e bastão quebrado (Wikipédia
  "Refraction"); 23 cm/s, λm 1,7 cm, círculo em expansão (Wikipédia
  "Capillary wave"); 19,47°, "patos e cisnes" (Wikipédia "Kelvin wake");
  coroa, back-jet, gotas (Wikipédia "Splash"); "animating energy", after
  splash (Gilland via Parka); follow through / overlapping (Thomas &
  Johnston); capivara quase submersa com olhos e orelhas no topo da cabeça,
  até 5 min (Wikipédia).

### R6 — Composição vertical e legenda fora da zona do app de vídeo (alta, P)

- **O que**: (a) capturar o cenário **em 9:16** (720×1280 lógicos @3 =
  2160×3840) com a mesma `GeometriaDoMundo`, para que o céu ocupe o topo e
  o capim o pé do quadro em vez de retângulos chapados; (b) no plano aberto,
  horizonte na linha dos terços: **62 %** nos planos de chão/água, **38 %**
  nos planos de céu (noite com lua/vagalumes); nunca 50 %; (c) legenda
  movida para **y = 1100–1240** (chip + 2 linhas terminando acima de 1248
  = 65 % do quadro) e com 65 px de margem lateral; cabeças dos bichos entre
  y = 300 e 1200 nos closes; nada essencial na coluna direita de 120 px.
- **Onde**: `gera/app_capturas/cenario_nov_test.dart:117-140`; `b4.js:134`
  (`MX/MY/MW/MH`), `:260` (`ABERTO`), `b4.html:18` (`.fala{top}`).
- **Aceite**: nenhum pixel de legenda com `y > 1248`; no plano aberto, ≤ 5 %
  do quadro é cor chapada sem conteúdo; o horizonte do plano aberto está
  em 0,62 ± 0,04 ou 0,38 ± 0,04 da altura.
- **Fonte**: zonas seguras Reels 14/35/6 % e TikTok 10/20 % + coluna direita
  (House of Marketers); regra dos terços para o horizonte (Wikipédia).

### R7 — A lagoa é uma vereda: buritis, campo úmido, chapadas; sem colinas redondas (média, M)

- **O que**: (a) nova camada 0,5 com **5–7 buritis** na margem de lá
  (fuste 4–6 px, altura 0,35–0,5 h cortada pelo topo nos planos fechados,
  leque de 7–9 folhas rígidas no ápice, sem copa contínua), em dois tons
  (frente/trás); (b) trocar as colinas em semicírculo por **campo ondulado
  de 0,02–0,04 h** com 2–3 arbustos (cerrado ralo) e uma segunda fiada de
  chapadas; (c) barus a **2,5× o bicho**, 3 em vez de 6, copa densa de
  silhueta irregular (não 3 círculos), tronco com 2 tons (casca grossa);
  (d) faixa de campo úmido (60 cm → 0,5 da altura da capivara) entre a
  trilha e a água, com tufos mais altos que os do campo seco; (e) trilha de
  terra com bordas irregulares e largura variável.
- **Onde**: `pinta_mundo.dart:117-175` (colinas → campo e buritizal),
  `:247-291` (`_arvoreDeBaru`), `:352-361` (trilha), `:474-500` (tufos);
  `arte_dos_itens.dart` ganha `_buriti` reutilizável.
- **Aceite**: teste de 10 pessoas com a captura de dia: ≥ 7 dizem "palmeira"
  ao apontar a margem de lá; a árvore mais alta ≥ 2,2× a altura do bicho na
  mesma captura; nenhuma silhueta de colina com curvatura constante
  (semicírculo) no horizonte próximo.
- **Fonte**: vereda em três zonas, buriti 25 m em leque em faixa estreita, fundo
  100–300 m (Embrapa); relevo plano a suave-ondulado (Wikipédia pt); baru
  25 m, copa densa arredondada, perenifólia (Wikipédia pt); "escala fixa:
  árvore = 2,5× o bicho" já era pedido do laudo 03 §4.10.

### R8 — Paralaxe na série (média, M)

- **O que**: exportar as 5 camadas de §3.1 e, no `desenha(tt)`, deslocar
  cada `<image>` por `(cx − cx0)·(1 − fator)` e, com zoom `z`, escalar as
  camadas de trás por `1 + (1 − fator)·(z − 1)·0,3` para a profundidade
  reagir ao zoom (a Godot avisa que zoom sem arte maior quebra o efeito);
  nos *chicotes* a frente anda 25 % mais que o chão.
- **Onde**: `b4.js:135-152` (camadas), `:321-333` (câmera), `gera/`
  (exportação por camada: `cenario_nov_test.dart` ganha um parâmetro
  `camada`).
- **Aceite**: num chicote de 400 px de `cx`, a chapada se desloca ≤ 80 px e
  o capim da frente ≥ 500 px, medidos entre o primeiro e o último quadro.
- **Fonte**: Godot (0,1→0,7; textura ≥ viewport; zoom), K-State (1/3, 2/3,
  1; frente mais rápida e maior), multiplano (Wikipédia).

### R9 — Um campo de vento e um evento por vez (média, M)

- **O que**: (a) um único `vento(t, x)` = base 0,15 + rajada (envelope
  ataque 1,5 s / decaimento 3 s, a cada 6–12 s, sorteada) propagando-se em
  x a 300 px/s; capim, tufos, juncos, buritis (só os leques), nuvens (só
  velocidade) e faixas na água leem **o mesmo campo** com atraso por x e
  amplitude por camada (capim 1,0; tufos 0,6; juncos 0,8; leque 0,4; copa de
  baru 0,15); (b) fila de **eventos** com um só ativo: pássaro atravessando
  (3–4 s, 2 quadros de asa, a 0,25–0,45 h), peixe pulando na lagoa (0,6 s +
  anéis), folha caindo do baru (4 s, zigue-zague), libélula sobre os juncos
  (5 s), capivara/lontra reais nunca — intervalo entre eventos 8–15 s, e
  **nenhum evento enquanto o bicho fala ou reage** (`motor_de_vida` em
  episódio ≠ ócio); (c) na seca (abr–set) a rajada vem com 2–3 pontos de
  poeira dourada.
- **Onde**: `pinta_mundo.dart:256, 454, 466, 485, 550` (os cinco `sin(t·…)`
  independentes viram leituras de `vento`); `mundo.dart` (fila de eventos,
  ao lado do `_camera`/`_tempo`); `motor_de_vida.dart` (flag "em cena").
- **Aceite**: num vídeo de 60 s da home em ócio, contam-se 4–7 eventos e
  nunca 2 sobrepostos; num vídeo de 10 s, existe ≥ 1 trecho de ≥ 2 s em que
  o capim está quase parado (amplitude < 1 px) e ≥ 1 rajada em que o capim
  da esquerda se move ≥ 0,5 s antes do da direita.
- **Fonte**: ação secundária "enfatiza, não distrai" (Thomas & Johnston);
  "fill in the blanks" (Nesbitt); horários da capivara e dos vagalumes para
  o calendário dos eventos (Wikipédia, NPS).

### R10 — Tinta da hora no bicho e nos itens (média, P)

- **O que**: um `ColorFilter.matrix` por período aplicado ao `PetView` e
  aos itens (noite: dessatura 35 %, multiplica por #B8C4DC; entardecer:
  multiplica por #FFD9B0 a 30 %; amanhecer: #E6DCE8 a 20 %; dia: nenhum),
  mantendo a silhueta ≥ 2:1 contra o fundo atrás dele (se cair abaixo,
  clarear a borda do bicho com `luz` 1 px).
- **Onde**: `mundo.dart:575-625` (o `PetView` dentro do `Stack`),
  `habitat.dart:1234` (a vitrine já faz o véu — unificar).
- **Aceite**: em `home-*-noite.png`, a saturação média do bicho é ≤ 70 % da
  de `home-*.png`; contraste de luminância bicho × média do fundo numa
  faixa de 20 px ao redor da silhueta ≥ 2:1 nos 4 períodos e 9 espécies
  (36 capturas).
- **Fonte**: "drawn by the same hand", luz como parte da pose (Hilda);
  Purkinje; valores agrupados e silhueta (Gurney).

### R11 — O fundo da lagoa visto de dentro (Lume, Nino, Rio) (baixa, M)

- **O que**: cena "embaixo d'água" para quem mergulha: céu/mundo de cima
  dentro de um **disco de ~97°** (elipse de 0,9 w × 0,35 h no topo, borda
  esfumada a zero), fora dele água escura espelhando o fundo; 3–4 feixes de
  luz diagonais (alfa 8 %) que oscilam com a lâmina; tinta ciano-verde
  (#3F6F6B → #1E3A3A) — nunca bege, porque o vermelho some primeiro; fundo
  de areia + 2–3 pedras + talos de junco vistos de baixo; bolhas 2–4 px
  subindo; `vida` e `episodios` passam a ter "mergulho" com entrada (coroa
  vista de baixo = anel de bolhas) e saída.
- **Onde**: nova função `_fundoDaLagoa` em `pinta_mundo.dart`;
  `episodios.dart`; `pet.dart` (pose de mergulho já existe: `mergulha`,
  `:2098-2110`).
- **Aceite**: a captura tem um disco claro no topo cujo brilho na borda é
  ≤ 10 % do centro; nenhum pixel fora do disco tem `R > G`; o bicho na
  água tem contraste ≥ 2:1 contra a água.
- **Fonte**: janela de Snell 96–97°, borda a zero, fora escuro/espelho
  (Wikipédia); vermelho absorvido primeiro (Wikipédia "Color of water");
  zona eufótica (NOAA).

### R12 — Estação seca e chuvosa (baixa, P)

- **O que**: dois conjuntos de cor do campo e do céu por **mês**: seca
  (abr–set) grama palha #C9B67A/#A69A5C, céu mais pálido no horizonte
  (poeira), 1–2 nuvens; chuva (out–mar) grama #8FBF6A, nuvens 5–6 e mais
  altas, lagoa 10 % mais alta (a `linhaDagua` sobe 0,01 h); baru com
  frutos castanhos set–out; buriti com cachos jun–out. O cenário "chuva" da
  loja continua existindo por cima.
- **Onde**: `habitat.dart:233` (`LuzDaCena.de` ganha `mes`), `pinta_mundo.dart:297-302`.
- **Aceite**: capturas de julho e de janeiro diferem na cor média do campo
  em ≥ 25 ° de matiz (HSV).
- **Fonte**: estações do Cerrado (Wikipédia pt); perda de folhas na seca
  (RBGE); fenologia do baru e do buriti (Wikipédia pt, Embrapa).
  [Opinião]: as cores da palha são minhas; a regra de que a seca
  amarela o campo não foi lida em fonte — confirmar com foto antes de fixar.

---

## 5. O que não fazer

1. **Não pintar a noite escurecendo tudo com um véu cinza.** Véu neutro é
   exatamente o "neutral shadow tone" que Bluey proíbe; a noite é azul-verde
   dessaturada com luzes quentes (Purkinje, Wrotniak).
2. **Não dar vida à água com traços brancos aleatórios.** Reflexo é imagem
   invertida de algo; brilho sem fonte é ruído. O que a água mostra tem de
   ter causa (§3.2).
3. **Não animar cada tufo com um seno próprio.** Vento é um campo; 70
   osciladores independentes lêem como gelatina, não como brisa; e ação
   secundária nunca pode competir com o bicho.
4. **Não ancorar item nenhum "no céu".** O topo do palco não é um lugar.
5. **Não fazer sol e lua no mesmo canto, nem o sol pondo-se a 30 % do céu.**
6. **Não trocar a identidade creme/quente do app por um céu azul-Windows.**
   A cor fria entra como **contraponto** (zênite, sombras, véu), não como
   base; "slightly more vivid", não saturado.
7. **Não desenhar vitória-régia, coqueiro ou pinheiro na lagoa do
   Cerrado.** A assinatura é buriti + campo úmido + chapada; o resto é
   habitat de outra etapa da trilha.
8. **Não pôr legenda abaixo de y = 1248 nem elementos essenciais na coluna
   direita de 120 px.**
9. **Não mexer na `lagoa` com `forca ≠ 0`** para resolver cor: a luz da hora
   (R1/R2) resolve; `forca` é para os outros habitats.
10. **Não usar vídeo gerado por IA, foto ou pintura** para o cenário: a
    regra é arte do app; tudo acima é desenhável em `CustomPainter`.

---

## 6. Fontes (lidas em 08/11/2026)

Paisagem e biologia

1. RBGE, "Cerrado vegetation structure" — https://cerrado.rbge.org.uk/cerrado/vegetation.php
2. Wikipédia pt, "Cerrado" — https://pt.wikipedia.org/wiki/Cerrado
3. Wikipédia pt, "Dipteryx alata" (baru) — https://pt.wikipedia.org/wiki/Dipteryx_alata
4. Wikipedia en, "Mauritia flexuosa" (buriti) — https://en.wikipedia.org/wiki/Mauritia_flexuosa
5. Embrapa Cerrados, "VI.3 Veredas", em *Águas Emendadas* (PDF) — https://www.infoteca.cnptia.embrapa.br/infoteca/bitstream/doc/1176629/1/VI.3-Veredas.pdf
6. Wikipédia pt, "Vereda (cerrado)" — https://pt.wikipedia.org/wiki/Vereda_(cerrado)
7. Wikipedia en, "Capybara" — https://en.wikipedia.org/wiki/Capybara
8. Wikipedia en, "Neotropical otter" — https://en.wikipedia.org/wiki/Neotropical_otter
9. NPS, Great Smoky Mountains, "Firefly Flash Patterns" — https://www.nps.gov/grsm/learn/nature/firefly-flash-patterns.htm
10. Agência FAPESP, "Luzes de alerta" (vagalumes do Cerrado) — https://agencia.fapesp.br/index.php/luzes-de-alerta/12138

Estúdios e estilo

11. Catriona Drummond, "Creating Bluey: Tales from the Art Director — Chapter 1" — https://goodsniff.substack.com/p/creating-bluey-tales-from-the-art
12. Catriona Drummond, "Creating Bluey — Chapter 2" (regras de cor, luz, perspectiva) — https://goodsniff.substack.com/p/creating-bluey-tales-from-the-art-891
13. It's Nice That, "How we built Bluey's world" — https://www.itsnicethat.com/features/how-we-built-bluey-s-world-cartoon-background-scenery-art-director-catriona-drummond-animation-090725
14. Toon Boom, "Mercury Filmworks on the craft and magic behind Hilda" — https://www.toonboom.com/mercury-filmworks-on-the-craft-and-magic-behind-hilda
15. Pocket Gamer, "Interview: a closer look at Team Alto's stunning sequel Alto's Odyssey" — https://www.pocketgamer.com/altos-odyssey/interview-a-closer-look-at-team-altos-stunning-sequel-altos-odyssey
16. Computer Graphics World, "Stepping Out" (Rio, 2011) — https://www.cgw.com/Publications/CGW/2011/Volume-34-Issue-4-April-2011-/Stepping-Out.aspx
17. Wikipedia en, "Puffin Rock" — https://en.wikipedia.org/wiki/Puffin_Rock
18. Wikipedia en, "Multiplane camera" — https://en.wikipedia.org/wiki/Multiplane_camera
19. Wikipedia en, "Twelve basic principles of animation" — https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation
20. Parka Blogs, resenha de *Elemental Magic* (Joseph Gilland) — https://www.parkablogs.com/node/1783
21. James Gurney, "Cure for Middle Value Mumbling" — https://gurneyjourney.blogspot.com/2011/04/cure-for-middle-value-mumbling.html

Luz e cor

22. J. Andrzej Wrotniak, "The Magic Hours" — https://mikeeckman.com/wrotniak/photo/bytes/magic-hr.html
23. Wikipedia en, "Purkinje effect" — https://en.wikipedia.org/wiki/Purkinje_effect
24. PremiumBeat, "Why color grade moonlight blue" — https://www.premiumbeat.com/blog/why-color-grade-moonlight-blue/
25. Wikipedia en, "Color of water" — https://en.wikipedia.org/wiki/Color_of_water
26. NOAA Ocean Service, "How far does light travel in the ocean?" — https://oceanservice.noaa.gov/facts/light_travel.html

Água e física

27. Wikipedia en, "Refraction" (profundidade aparente, bastão quebrado) — https://en.wikipedia.org/wiki/Refraction
28. Wikipedia en, "Snell's window" — https://en.wikipedia.org/wiki/Snell%27s_window
29. Wikipedia en, "Capillary wave" — https://en.wikipedia.org/wiki/Capillary_wave
30. Wikipedia en, "Kelvin wake pattern" — https://en.wikipedia.org/wiki/Kelvin_wake_pattern
31. Wikipedia en, "Splash (fluid mechanics)" — https://en.wikipedia.org/wiki/Splash_(fluid_mechanics)

Paralaxe e composição

32. Godot Engine docs, "2D Parallax" — https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html
33. Kansas State CIS 580, "Parallax Scrolling" — https://textbooks.cs.ksu.edu/cis580/08-spritebatch-transforms/04-parallax-scrolling/
34. House of Marketers, "Guide to safe zones: TikTok, Facebook, Instagram Stories & Reels" — https://houseofmarketers.com/guide-to-safe-zones-tiktok-facebook-instagram-stories-reels/
35. Wikipedia en, "Rule of thirds" — https://en.wikipedia.org/wiki/Rule_of_thirds

Tentadas e não lidas (registro): AWN "Puffin Rock returns" (HTTP 403);
Gurney "Two Values" (HTTP 503); Animation Magazine "Brazilian Rhapsody:
Blue Sky's Rio" (HTTP 403); TCC UFMG sobre Irmão do Jorel (host
`eba.ufmg.br` fora da rede permitida da sessão). Resultados de busca que
não abri (por exemplo tabelas de hex de "paleta de pôr do sol" em blogs de
design) não foram usados como fonte.

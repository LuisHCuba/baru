# 30 — Bocas e lip-sync em desenho 2D de bichos

Data: 08/11/2026 · Escopo: a boca dos 9 bichos no `CustomPainter` do app
(`pet.dart`, `motor_de_vida.dart`) e na montagem da série "A turma do Baru"
(`novelinha-ep1/assets/b4.js`, `gera/`). Cobre conjuntos de visemas,
gradação de abertura, relação boca–nariz–focinheira, regras de tempo,
grito/riso/espanto/fala baixa e um sistema de boca para as 9 espécies.
Não reabre: painter procedural como fonte única; chaves das espécies.

Convenções (as dos laudos 05 e 21):

- **[Fato]**: afirmação com fonte externa, lida na data acima; o link está
  na seção "Fontes".
- **[App]**: observação do código ou das capturas, com arquivo:linha.
- **[Opinião]**: inferência ou valor de partida meu, sem fonte, para afinar
  no aparelho.

Avança em relação aos laudos anteriores: o 05 e o 21 citam "20+ visemas do
Duolingo" e o 03 propõe uma boca por humor; nenhum descreve formatos,
gradação, tempo ou mapeamento de pt-BR. Este laudo faz isso.

---

## Resumo em 12 linhas

1. **A "boca dupla" da Rio é um bug de montagem, não de desenho**: o quadro
   capturado do app já tem a boca aberta no focinho, e o `b4.js` desenha por
   cima uma segunda boca em SVG (elipse escura + língua) quando `grito > 0,08`
   (`b4.js:66,106-111`). As duas aparecem juntas em todo grito. Reproduzi (ver §1.5).
2. **A boca do app é binária.** `_boca` abre uma única meia-elipse de 9
   unidades de altura para qualquer `boca > 0,3` (`pet.dart:6076-6097`). Os 6
   "níveis" capturados para a série são **2 desenhos** (0 e 0,2 fechados; 0,4
   a 1,0 idênticos). Não há largura, interior escuro, língua nem dentes.
3. Toda a animação limitada usa **6 a 10 formatos** (Preston Blair 10; Rhubarb
   6+3; Papagayo 10; Harmony 8; Character Animator 12+2), e "estilos simples
   passam com 5 ou 6" [Fato]. Duolingo tem 20+ por personagem, mas com
   animadores humanos; não é o nosso caso.
4. As regras de tempo são consistentes entre fontes: boca **1–2 quadros antes
   do som** (40–80 ms), **nenhum formato por menos de 2 quadros**, M/B/P
   fechado por ≥ 2 quadros, vogal segura, consoante breve, fechar **2–3 quadros
   depois** do fim da frase, não voltar ao repouso entre palavras coladas.
5. "Mouth flapping" vem de bater a cada sílaba com um único formato aberto —
   exatamente o que `nv = round(abre·1,4·5)` faz hoje com a amplitude.
6. Bicho com focinho **abre para baixo** (só a mandíbula move; o lábio
   superior e o nariz ficam). Bico não faz "O": a mandíbula inferior gira. O
   buldogue abre **atrás do beiço**: o escuro fica entre os lobos.
7. Proposta: 5 parâmetros contínuos (`abertura 0..1`, `largura −1..1`,
   `canto −1..1`, `lingua 0..1`, `dentes 0..1`) e **7 formatos** nomeados
   (X, A, B, C, D, E, F) definidos por valores desses parâmetros, por espécie.
8. pt-BR cabe em 6 formatos de vogal: a→D, é/ê→C, i→B, ó/ô→E, u→F, nasais =
   vogal oral mais fechada em 15 %; **"m/n" de fim de sílaba não fecha a boca**
   (é nasalização, não bilabial).
9. O motor da série já tem tempo por palavra (whisper) e envelope a 30 qps;
   falta a trilha de visemas: letras → fonemas → formatos distribuídos no
   intervalo da palavra, com as regras do item 4; a amplitude só modula a
   abertura (0,6–1,0) e detecta acento.
10. Grito = abertura 1, mais alto que largo, olhos apertados, cabeça para
    trás; riso = pulso 4–6 Hz com cantos para cima e olhos fechando; fala
    baixa/tímida = abertura ≤ 0,5, cantos caídos, volta ao repouso entre
    palavras; espanto = "o" pequeno segurado 6–8 quadros antes de falar.
11. Folhas da série: trocar "6 níveis de amplitude × humor" por "7 visemas ×
    humor"; para os laços de vida (120 quadros), **camada de boca com âncora
    exportada pelo painter**, compondo no lugar da boca, nunca por cima.
12. Critérios de aceite medíveis: bocas distintas por nível (altura monótona),
    folga ≥ 2 unidades entre nariz e lábio superior em todas as espécies,
    nenhum visema < 2 quadros, ≤ 8 trocas/s, uma única boca por quadro
    (componente conexo) no auditor.

---

## 1. O que o app faz hoje [App]

### 1.1 A função `_boca` (`pet.dart:6073-6147`)

- Decisão binária de abertura (`6075-6080`): aberta se `bocejo > 0,3` ou
  `carinho > 0,4` ou `mastiga > 0,30` ou `vida.boca > 0,3`. O valor contínuo
  `vida.boca` (0..1, `motor_de_vida.dart:191-192`) vira um bit.
- Forma aberta (`6085-6097`): `Rect.fromCenter(o + (0,2), w·0,8, 9)`;
  `drawArc(r, 0, π, useCenter: true)` preenchido com
  `lerp(acento #EF8354, tinta #3E2F23, 0,4)` ≈ `#A86140`; contorno só no arco
  inferior (`useCenter: false`), traço 1,9 de `sombraForte`. Consequências:
  - **altura fixa de 9 unidades** para todas as espécies e aberturas (na
    lontra, cabeça 78×62, isso é 14,5 % da altura da cabeça; na capivara,
    94×74, 12 %);
  - o topo é a **corda reta** da meia-elipse, sem contorno: a boca aberta é
    um "D" deitado com o lado reto para cima, não uma boca que o maxilar
    inferior abriu;
  - interior em cor chapada, **sem cavidade escura, sem língua, sem dentes**;
  - a mesma forma para carinho, bocejo, mastigação, zurro e fala.
- Formas fechadas por humor (`6101-6146`): radiante arco `w × 0,72w`
  (0,18..π−0,36); contente arco `0,8w × 0,5w`; neutro linha `0,6w`; sono arco
  `0,5w × 6`; saudade arco invertido `0,46w × 0,26w` deslocado 5 para baixo.
  São 5 desenhos fechados, nenhum aberto além da meia-elipse.
- O buldogue passa `cor` própria (`5035-5040`) porque sobre a focinheira
  escura o traço sumia e "sobravam dois dentinhos brancos flutuando".

### 1.2 Onde cada espécie põe a boca (centro, largura `w`, referência do nariz)

| Espécie | `_boca(o, w)` | Linha | Nariz/focinheira (y de baixo) | Folga nariz→topo da boca aberta |
|---|---|---|---|---|
| Capivara | (0,27), 26 | 2975 | focinheira (0,12) 26×15 → 19,5 | 5,0 |
| Lontra | (0,19), 20 | 3097 | focinheira (0,6) 19×13 → 12,5 | 4,0 |
| Tartaruga | (0,16), 24 | 3278 | narinas em (±6, 6) | ~6 |
| Axolote | (0,14), 22 | 3759 | sem nariz desenhado | — |
| Gata | (0,17), 20 | 4163 | nariz em coração, ponta y = 12,5 | 2,0 |
| Raposa | (0,19), 20 | 4373 | nariz (0,9) 13×10 → 14 | 2,5 |
| Buldogue | (0,30), 30 | 5035 | nariz (0,14) 27×17 → 22,5; filtro 22→27; lobos do beiço 17,5→42,5 | 5,0 (mas 0,5 até o fim do filtro) |
| Coruja | bico próprio | 3610-3619 | — | — |
| Pinguim | bico próprio | 3939-3964 | — | — |

A boca aberta ocupa `y ∈ [o.y − 2,5, o.y + 6,5]`: **cresce 2,5 para cima e 6,5
para baixo** a partir da linha do lábio. Na gata e no buldogue a folga até o
nariz fica em 2 unidades; qualquer aumento de altura "para cima" encosta no
nariz. É o que empurra o pedido de abrir só para baixo (§2.2).

### 1.3 Bicos

- **Coruja** (`3610-3619`): triângulo (−6,7)(6,7)(0, 19 + 3·max(mastiga, boca))
  em `#D9C79A`. "Abrir" é esticar a ponta 3 unidades (25 % da altura do bico).
  Não há mandíbula inferior nem cavidade.
- **Pinguim** (`3939-3964`): bico triângulo (−6,5)(6,5)(0,17) com faixa clara
  em y = 12; se aberto (mesmo limiar binário), um triângulo interno
  (−4,5,11)(4,5,11)(0,18,5) em `lerp(terracotaDaArte #C25A26, tinta, 0,35)` ≈
  `#944B25`. O "aberto" é um remendo dentro do bico fechado: o contorno
  externo não muda.

### 1.4 Buldogue (`4957-5107`)

Focinheira 56×26 rasa, dois lobos de beiço 33×25 centrados em (±16, 30), nariz
27×17 em (0,14), filtro de 22 a 27, `_boca` em (0,30) com `w = 30`, dois
dentinhos 5,6×6 em (±4,4, 34) **depois** da boca, língua (só radiante ou
`gosto > 0,5`) em (0, 35 + 4·quanto), 19 × (9 + 14·quanto). Boa ordem de
camadas; mas a boca aberta é a mesma meia-elipse das outras espécies, e o
escuro dela aparece **entre** os lobos sem lábio inferior que desça.

### 1.5 O motor de vida e o que chega ao painter

- `_boca` do motor (`motor_de_vida.dart:490`), zerado por episódio (`1074`),
  entregue em `SaidaDaVida.boca` (`1423`). Quem escreve nele:
  `episodios.dart:786` (alisar: `0,25 + 0,3·|sin 16t|`), `805` (zurro: `0,6 +
  0,4·|sin 22t|` quando `e > 0,4`), `840` (respirar na superfície: um pulso
  seno de 0,5 s). Ou seja, o motor produz valores contínuos e ritmos (`|sin
  16t|` e `|sin 22t|` ≈ 5,1 e 7,0 aberturas/s), e o painter os achata em 1
  bit em 0,3.
- Não existe `largura`, `canto`, `lingua` nem `dentes` em `SaidaDaVida`
  (`170-260`).

### 1.6 A série: capturas e o `b4.js`

- Captura (`gera/app_capturas/nov_ep4_test.dart:35`): para cada humor, 6
  quadros com `SaidaDaVida(boca: i/5)` = 0; 0,2; 0,4; 0,6; 0,8; 1,0, mais 1
  piscada = 7 por humor; susto e festa com 6 níveis cada (`38-39`). Total 40
  quadros. **Confirmado nas folhas** (`assets/img/app/bicho-*.webp`, folha de
  contato montada em `otter_niveis.png` e `outros_niveis.png` no scratchpad):
  níveis 0 e 1 são o mesmo desenho fechado; 2, 3, 4 e 5 são o mesmo desenho
  aberto, nas 6 espécies capturadas. **6 níveis = 2 bocas.**
- Laços de vida (`47-51`): 120 quadros × 3 bocas `[0, 0,4, 0,85]`; 0,4 e 0,85
  são a mesma boca.
- Envelope (`gera/prep_cenas.py:62-64`): RMS em janelas de 1/30 s → dB →
  normaliza entre o percentil 20 e o 97 com piso de −6 dB → `clip` →
  suavização de 3 pontos `[0,25 0,5 0,25]`. Resultado: durante a fala o
  envelope fica entre 0,7 e 0,98 e cai a 0,1–0,5 nos vales entre sílabas
  (ver `dados/b4_env.js`, fala `n1`).
- Escolha do quadro (`b4.js:98`): `nv = min(5, round(abre·1,4·5))` →
  `nv ≥ 2` (boca aberta) sempre que `abre ≥ 0,21`. Com o envelope acima, a
  boca fica aberta ~85 % do tempo de fala e só fecha nos vales: **bate a cada
  sílaba com um único desenho aberto** — a definição de "flapping". Nos laços
  de vida (`b4.js:90`): `round(abre·1,5·2)`, mesma coisa com 2 desenhos.
- **A boca dupla** (`b4.js:66` e `106-111`): `this.grito` é um `<g>` com uma
  elipse `#4A2418` e uma língua `#E57F78`, posicionado em coordenadas fixas da
  folha `[266, 216]` com `ry = 6 + 27·gab` e `rx = 30·(0,55 + 0,25·gab)`.
  `Erio` liga `e.grito = cl(ab·1,8)` com `susto = 1` durante "Quem é você?!"
  (`b4.js:222`), e o quadro escolhido é `28 + nv` — **que já tem a boca
  aberta do app**. Montei a composição com PIL (`otter_grito_duplo.png` no
  scratchpad): a boca do app fica no focinho e a elipse do SVG no queixo/peito.
  É literalmente "a Rio ganha duas bocas". O mesmo overlay existe só para a
  lontra (`GR = { otter: ... }`), por isso só ela sofre.
- Balanço do corpo pela fala (`b4.js:96` e `104`): `translate(−2,5 %·A·fala)`,
  `rotate(sin(7,3·t)·2,5°·fala)`, `scaleY(1 + 3 %·fala)`. O corpo inteiro
  gira a 1,2 Hz enquanto fala, independente de acento. Piscada é suprimida
  durante a fala (`b4.js:89`), o que está certo.
- Palavras (`gera/palavras4.py`, `prep_cenas.py`): `faster-whisper medium`,
  `word_timestamps=True`, `initial_prompt` com o texto do roteiro, alinhado
  ao texto por `difflib`; palavras não casadas recebem o intervalo dividido
  igualmente. O resultado `F3[id].w = [[início, fim, palavra]]` **só alimenta
  as legendas** (`b4.js:303-311`); a boca ignora o texto.
- Já existe um protótipo de largura por espectro na série anterior
  (`gera/boca.py:33-42`): razão entre as bandas 1800–3800 Hz e 250–1000 Hz
  dá `larg ∈ [−1, 1]` ("mais agudo = boca larga e/i; mais grave = redonda
  o/u"), com ataque 0,85 e decaimento 0,55 por quadro. **Não é usado nos
  episódios do Baru.**

---

## 2. O que as fontes dizem

### 2.1 Conjuntos de visemas em animação limitada

- [Fato] **Preston Blair, série de 10 fonemas** (reprodução de Gary C.
  Martin): (1) A·I, (2) E, (3) O, (4) U, (5) C·D·G·K·N·R·S·Th·Y·Z, (6) F·V,
  (7) L, (8) M·B·P, (9) W·Q, (10) repouso. Servem "para o bloqueio inicial da
  maioria das sequências de diálogo"; são deliberadamente neutros e pedem
  assimetria e personalidade por cima. Frameo apresenta a versão de 9
  (funde W·Q em U) e diz que "estilos mais simples passam com cinco ou seis",
  tipicamente fundindo E com A·I e descartando L·Th.
- [Fato] **Rhubarb Lip Sync**: 6 básicos obrigatórios e 3 opcionais.
  A = fechada, para P, B, M (quase igual a X, com leve pressão); B =
  "ligeiramente aberta com dentes cerrados", maioria das consoantes e o "EE";
  C = "aberta", vogais EH/AE, e **intermediária entre A/B e D**; D = "bem
  aberta", AA de "father"; E = "ligeiramente arredondada", AO/ER,
  intermediária entre C/D e F, "não deve abrir mais que C"; F = "lábios
  franzidos", UW/OW/W; G = dentes de cima no lábio de baixo (F, V); H = L
  longo com língua atrás dos dentes, "aberta pelo menos como C, não como D";
  X = repouso, lábios fechados relaxados. A última linha da saída é sempre
  boca fechada. Há um reconhecedor `phonetic`, "independente de idioma",
  para gravações que não são em inglês (menos preciso que o PocketSphinx).
- [Fato] **Papagayo** (Lost Marble): a pessoa digita o texto, arrasta cada
  palavra sobre a forma de onda, e o programa reparte os fonemas; exporta
  "quadro + nome da boca" para Moho e Blender. O conjunto padrão é o de
  Preston Blair: AI, E, etc, FV, L, MBP, O, U, WQ, rest (10).
- [Fato] **Toon Boom Harmony**, 8 letras arbitrárias: A = m, b, p, h; B =
  s, d, j, i, k, t; C = e, a; D = A, E (abertas); E = o; F = u, oo; G = f,
  ph; X = silêncio. O "Detect" marca uma letra por célula de som e o "Map"
  liga a letra a um desenho; o programa não cria os desenhos.
- [Fato] **Adobe Character Animator**: grupo "Mouth" com Neutral, Smile e
  Surprised (sem áudio) e 11 visemas por áudio: Ah, D, Ee, F, L, M, Oh, R,
  S, Uh, W-Oo. O artigo da Adobe Research sobre lip-sync ao vivo usa esses
  **12 visemas** (com Silent) e nota que o Harmony automático usa 8 (mapeia
  S→D, L→D, Uh→Ah, R→W-Oo). O mesmo artigo descreve o "Voice Animator" de
  animação limitada japonesa com **apenas 3 bocas (fechada, meio aberta,
  aberta)**.
- [Fato] **Duolingo**: "20+ bocas desenhadas para todo mundo", cada um dos
  dez personagens com o seu conjunto refletindo personalidade; a sincronia
  é por palavra e por fonema, gerada por uma "fábrica" com auditoria; no
  Rive, os estados de boca ficam **separados** dos estados de pose e rodam
  ao mesmo tempo; se a pessoa termina o exercício antes, o personagem para
  de falar.
- [Fato] **Tamanhos típicos em jogos** (MocapOnline): só amplitude → maxilar;
  conjuntos simplificados de 5–6 em chat de voz; "mínimo viável 6–8"; 15–20
  em produções AAA com misturas de coarticulação.
- [Fato] **Thimbleweed Park** (Ron Gilbert): sem dados de lip-sync a boca é
  sorteada com pesos; cabeça em 2 posições (normal 80 %, erguida 20 %);
  camadas separadas de cabeça, corpo e boca para falar enquanto anda; sem
  lip-sync em diálogo só de texto "porque cada um lê numa velocidade".
- [Fato] **"Conducting Cartoon Consonants"** (Georgia Southern, 2020): o
  mouth chart arquetípico é "linguisticamente impreciso" e isso é parte da
  causa do "flapping"; propõe chart baseado no IPA, "ainda simplificado para
  animação limitada".

**Subconjunto para bicho com focinho, bico e focinheira.** Nenhuma fonte dá
um chart "de bicho"; o que elas dão são regras de adaptação:

- [Fato] The Rookies (lipsync para antropomórficos): "humanos só movem o
  maxilar inferior"; o superior só em exagero. A boca do cão "Peanut" é parte
  grande da forma da cabeça, então o autor manteve um sorriso estático
  durante a atuação do corpo e tratou a boca depois. Mesmo som pode precisar
  de desenho diferente conforme a expressão; não copie e cole. Vogais abrem,
  P/B fecham, S junta os dentes. "A língua se move rápido demais para ser
  intercalada: não compensa animar." Entre palavras os lábios ficam
  "ligeiramente abertos, mesmo em silêncio". Bigode que cobre o lábio
  superior (gnomo Loris) teve que ser animado junto.
- [Fato] Aves: 52 espécies de 16 famílias vocalizam **de bico fechado**,
  inflando o esôfago ou bolsa traqueal; o som sai pela cavidade inflada e
  pela pele do pescoço, com fundamental mais baixa do que o tamanho do corpo
  prevê (Riede et al., *Evolution* 2016; corujas não estão na lista). O
  pinguim no "ecstatic display" fica de pés afastados, ergue a cabeça
  **apontando o bico para cima**, abre as asas, o peito sobe numa inspiração
  e então vem o zurro (CalAcademy). A coruja-buraqueira faz "coo-coooo"
  repetido duas vezes, chatter, chirp e scream; recebeu o apelido de "howdy
  bird" por parecer acenar com a cabeça (Audubon); balança a cabeça quando
  agitada e expande a mancha branca do queixo (Wikipedia).
- [Fato] Tartaruga: sem dentes, "bico" de queratina nas bordas das
  mandíbulas; algumas filtram deslizando com boca e garganta abertas
  (Wikipedia). Axolote: sem pálpebras, "dentes vestigiais quase invisíveis",
  captura por sucção abocanhando (Wikipedia). Capivara: late, chia, assobia
  (pelo nariz), bufa e ronrona; mastiga para a frente e para trás, não de
  lado (Wikipedia). Gato (Moelk, 1944): três classes de boca — fechada
  (ronrono, trinado), **aberta e fechando aos poucos** (miado, uivo), aberta
  e tensa numa posição (rosnado, bufo, chattering) (Wikipedia). Cão: o lábio
  superior é o "flew"; em buldogues ele é tão grande que o lábio inferior
  "é difícil de ver sem puxar a pele" (Pawleaks).
- [Fato] Desenho infantil vetorial: Hey Duggee nasceu de "formas geométricas
  básicas, só que desta vez com olhos e bocas"; detalhe extra "confunde";
  "reuso não é palavrão" (Grant Orchard, Cartoon Brew). Bluey é animado em
  CelAction2D (Wikipedia); a bíblia visual pede "fofo, simplificado e
  chunky", sem linha preta (linhas na cor do objeto) e sombras nunca neutras
  (diretor de arte, Substack).

### 2.2 Como a boca abre em gradação; língua, dentes, interior; boca × nariz

- [Fato] Keith Lango: "acerte as aberturas e os fechamentos primeiro e
  construa em cima" dá "mais de 75 %" do lip-sync; o maxilar **gira**, não
  desliza; "os dentes de cima não se movem"; não segure uma boca parada —
  desloque-a um pouco durante a pausa; bochechas e nariz se mexem ao falar e
  ligam a boca aos olhos; "não tenha medo de ir ao extremo": sons mais altos
  ganham bocas mais largas.
- [Fato] Brian Lemay: escolha a emoção **antes** das posições de boca, porque
  a expressão muda o formato; dê a cada personagem um estilo de boca próprio.
- [Fato] Thomas & Johnston (via artigo dos 12 princípios): squash & stretch
  vale para "a musculatura de um rosto humano" (pp. 47–51); expressão facial
  passa despercebida durante um movimento grande — ponha-a no começo e no
  fim do movimento (p. 64); exagero é "a realidade numa forma mais extrema",
  com contenção (pp. 65–66).
- [Fato] Rhubarb define ordem de abertura: X ≈ A < B < C < D, com E entre C e
  F e "E nunca mais aberta que C"; C e E são as intermediárias obrigatórias.
  É uma escala de **altura** (A→D) cruzada com uma de **arredondamento**
  (C→E→F), ou seja, dois eixos: abertura e largura.
- [Fato] Formantes (Wikipedia): F1 sobe com a abertura (a ≈ 850 Hz, i ≈ 240,
  u ≈ 250); F2 sobe com a anterioridade (i ≈ 2400, a ≈ 1610, u ≈ 595);
  arredondar os lábios baixa os formantes. Sustenta o `boca.py` atual: razão
  aguda/grave ≈ largura; energia ≈ abertura.
- [Opinião, apoiada em Rookies + Lango] "Boca dupla" e "boca que briga com o
  nariz" têm a mesma raiz: a boca aberta é desenhada **em cima** de outra
  coisa em vez de **substituir** a linha do lábio e crescer para baixo. A
  camada de boca do Thimbleweed e os estados de boca do Duolingo trocam a
  boca; não somam.

### 2.3 Regras de tempo

| Regra | Valor | Fonte |
|---|---|---|
| Boca antes do som | ≥ 2 quadros a 24 qps; 6–8 quadros numa vogal ou consoante muito enfatizada | Nordberg / Animation Apprentice |
| idem | "1–2 quadros a 24 qps, ou 40–80 ms"; animadores "nunca mostram um visema por menos de 2 quadros" | Adobe Research, lip-sync ao vivo 2D |
| idem | 1–2 quadros, "diretriz, não regra"; às vezes sincronia exata | The Rookies |
| Nunca depois do som | "NEVER HAVE THE DRAWING AFTER THE SOUND"; fechadas e franzidas no quadro do som ou 1 antes; ≥ 2 quadros na tela | Brian Lemay |
| M/B/P e F | "M e F por 2 quadros"; não vá de bem aberta a fechada em 1 quadro; não faça aberta-fechada-aberta em 3 quadros; língua ≤ 2 quadros | Keith Lango |
| Vogal × consoante | "segure vogais, estale consoantes, volte ao repouso entre frases"; a 12 qps cada boca ≥ 2 quadros | Frameo |
| Fim de frase | boca fechada 2–3 quadros **depois** do fim da onda (faixa 1–6); se o último som é M/B, perto do fim real; não use "espera + intercalado" juntos | Animator Island |
| Entre palavras | lábios ligeiramente abertos, mesmo em silêncio | The Rookies |
| Não bater tudo | "interprete como um impressionista": sons fracos somem ("you hafta get" perde o "ooo", o "ah" e o "G") | Keith Lango |
| Acentos | caem nas vogais; não abuse na mesma cena; antecipação de cabeça 4–6 quadros antes do diálogo; em close só de olhos, começar ≥ 4 quadros antes da palavra acentuada; "quanto maior o acento, mais cedo"; evite balanço de cabeça excessivo (Mrs. Brisby em *NIMH*) | Brian Lemay |
| Estilo | animadores diferem: dois dos quatro usam o visema Silent "bem menos", preferindo não voltar ao neutro; um faz menos trocas, "estilo mais suave e menos articulado" | Adobe Research |
| Filtro de ruído | previsões a 100 Hz filtradas para 24 qps; uma troca só vale se segurar 3 previsões (30 ms); "não deixamos um visema mudar depois de um único quadro" | Adobe Research |

**pt-BR → formatos.**

- [Fato] Vogais orais do português brasileiro: /a ɐ e ɛ i o ɔ u/; nasais
  /ɐ̃ ẽ ĩ õ ũ/, só /õ ũ/ arredondadas; átonas finais reduzem a /a i u/; /t d/
  viram [tʃ dʒ] antes de /i/ (Wikipedia, fonologia do português). A nasal se
  escreve com m/n de fim de sílaba — não é oclusão bilabial.
- [Fato] De Martino (Unicamp, 2005) definiu "visemas dependentes do contexto
  fonético para o português do Brasil"; o estudo de 2018 que o revisita com
  captura de movimento usou 102 gravações (81 paroxítonas de duas sílabas, 21
  monossílabos) e define o visema de cada som como "o quadro de maior
  deslocamento dos pontos em relação ao repouso" (Chinelatto & Costa, PIBIC).
  Uma matéria do Jornal da Unicamp fala em 29 visemas; não consegui ler o
  PDF (503), fica como indicação.
- [Fato] Tempo por palavra: o Whisper puro dá timestamps "por enunciado",
  "com erro de vários segundos"; o WhisperX alinha a transcrição ao áudio com
  wav2vec2 (alinhamento forçado), precisa de um modelo por idioma, e
  palavras com numerais ou símbolos "não recebem tempo" (README). O
  reconhecedor `phonetic` do Rhubarb é independente de idioma (README).

### 2.4 Grito, riso, espanto, fala baixa, fala tímida

- [Fato] Lango: sons mais altos e de mais energia → bocas mais largas; "não
  tenha medo de ir ao extremo". Lemay: acentos nas vogais; cabeça antecipa
  4–6 quadros; corpo e mãos acentuam quando a boca não se vê.
- [Fato] Thomas & Johnston: a expressão lê no começo e no fim do movimento,
  não durante; exagero com contenção.
- [Fato] Biologia que vira regra de desenho: o gato **abre e vai fechando**
  no miado (vogal longa que termina fechada); rosnado e bufo são "boca
  tensa, parada numa posição" (Moelk). O pinguim ergue a cabeça, abre as
  asas e **enche o peito antes** de zurrar (CalAcademy): o grito tem
  antecipação no corpo. Aves de bico fechado produzem sons **mais graves**
  inflando a garganta (Riede): fala baixa e "hmm" podem ser de bico fechado
  com o pescoço enchendo, sem abrir nada. A coruja-buraqueira balança a
  cabeça e abre a mancha do queixo quando agitada: o "espanto" dela é
  cabeça, não bico.
- [Fato] Duolingo (via laudo 24): "expressões exageradas pareciam erradas"
  — contenção, citando Chuck Jones.

---

## 3. Proposta: um sistema de boca para as 9 espécies

### 3.1 Parâmetros (contínuos, em `SaidaDaVida` e `QuadroFixo`)

| Parâmetro | Faixa | O que faz no desenho |
|---|---|---|
| `abertura` | 0..1 | altura do vão: a **mandíbula desce** `hMax·abertura`; o lábio superior sobe no máximo 1 unidade (Lango: dentes de cima não movem) |
| `largura` | −1..1 | −1 = redonda/franzida (u), 0 = neutra, +1 = esticada (i); largura = `w·(0,55 + 0,25·abertura)·(1 + 0,3·largura)` |
| `canto` | −1..1 | cantos para baixo/cima; soma ao humor (radiante +0,6, saudade −0,4) |
| `lingua` | 0..1 | aparece só com `abertura > 0,45`; elipse `0,5·largura × 0,2·altura` no fundo do vão, `lerp(acento, superficie, 0,28)` (a cor que o buldogue já usa) |
| `dentes` | 0..1 | linha clara `superficie` de 1,2 de espessura no topo do vão (formato B) nas espécies com dente visível: gata, raposa, buldogue (os dois dentinhos já existem), capivara (incisivos, 2 retângulos 3×4 no centro) |

Interior do vão: `lerp(tinta #3E2F23, pelo, 0,25)` (cavidade, não terracota
chapada). Contorno: o mesmo traço de 1,9 do lábio, **inclusive no topo** —
o lábio superior é uma linha, a corda reta some.

### 3.2 Os 7 formatos (valores dos parâmetros)

| Formato | Sons (pt-BR) | `abertura` | `largura` | `lingua` | `dentes` | Observação |
|---|---|---|---|---|---|---|
| **X** repouso | pausa ≥ 150 ms, fim de frase | 0 | 0 | 0 | 0 | a boca do humor atual (`6101-6146`) |
| **A** fechada apertada | p, b, m (início de sílaba) | 0 | 0 | 0 | 0 | linha 2,4 de espessura, 0,7w; segurar ≥ 2 quadros |
| **B** fresta | i, í, s, z, t, d, n, l, r, ch, j, k, g, f, v | 0,15 | +0,6 | 0 | 1 | escuro de 2 unidades + linha de dentes; "EE" e consoantes |
| **C** meio aberta | é, ê, ẽ, e átono | 0,45 | +0,2 | 0 | 0 | a intermediária obrigatória (Rhubarb C) |
| **D** aberta | a, á, ã, â | 0,85–1 | 0 | 1 | 0 | única com língua; altura máxima |
| **E** redonda | ó, ô, õ, ou | 0,5 | −0,5 | 0 | 0 | **elipse inteira**, não meia; nunca mais alta que C+10 % |
| **F** bico | u, ú, ũ, w (qu-, gu-) | 0,3 | −1 | 0 | 0 | pequena e redonda |

Ditongos: "ão" = D→F, "ei" = C→B, "ou" = E (uma só), "ai" = D→B; só mostram
as duas se a palavra durar ≥ 4 quadros; senão, a primeira. Nasais = vogal
oral com `abertura` 15 % menor (o véu desce, a boca abre menos) [Opinião].

Alturas máximas (`hMax`) por espécie, em unidades do painter, derivadas da
cabeça e da folga do nariz do §1.2 [Opinião, para afinar]: capivara 14, lontra
12, tartaruga 12, axolote 14 (boca larga, sem nariz: `largura` +0,3 de
base), gata 9, raposa 10, buldogue 12 (atrás do beiço), coruja 8 (bico),
pinguim 10 (bico). Em todas, o topo do vão fica **≥ 2 unidades abaixo** do
nariz ou focinheira em qualquer abertura.

### 3.3 Bicos

- A mandíbula inferior é uma peça própria que **gira** em torno da
  comissura (base do bico): coruja 0..25°, pinguim 0..30°, com
  `abertura`. A superior fica. O vão é escuro (`lerp(tinta, bico, 0,3)`), com
  a língua (pequena, rosa) só no pinguim em D (zurro).
- Formatos para bico: X/A = fechado; B = fresta 1 unidade; C = 12°; D = 25–30°;
  E e F **não existem**: mapeiam para C com `largura` ignorada (bico não
  arredonda). "Fala baixa" da coruja = bico fechado + pescoço estufando
  (`achata` −0,15) [Fato: vocalização de bico fechado].
- Zurro do pinguim (episódio `zurro`, `episodios.dart:800-806`): já tem
  cabeça −7 e `achata −0,35`; acrescentar: peito +8 % por 0,4 s **antes** da
  boca abrir (inspiração), asas abertas, bico em D apontando para cima.

### 3.4 Buldogue

Mandíbula inferior = lábio inferior + dentinhos descem juntos com
`abertura·10`; o vão escuro aparece **entre os lobos do beiço**, que não
mudam (o flew cobre); língua dentro do vão em D (diferente da língua de fora
do radiante, que continua só de alegria). A linha do lábio em X segue sendo
o traço com `cor` própria (`5039`).

### 3.5 Humor e emoção sobre a boca

| Situação | `abertura` | `largura` | `canto` | Resto do rosto/corpo |
|---|---|---|---|---|
| Grito ("!" + envelope > 0,9) | 1,0 | −0,3 (mais alta que larga) | 0 | olhos apertam 0,3, sobrancelha sobe, cabeça para trás 6 u, corpo estica +3 % por 2 quadros **antes**; segura ≥ 6 quadros |
| Riso ("haha", "rs", "kkk") | pulso 0,5↔0,9 a 4–6 Hz | +0,4 | +0,8 | olhos fechando 0,6 (Duchenne), cabeça para trás 4 u, corpo quica 2 u no mesmo ritmo |
| Espanto (susto) | 0,6 | −0,6 ("o") | 0 | sobrancelhas no alto, pupila menor; segurar 6–8 quadros antes de qualquer fala; coruja: cabeça balança em vez de abrir o bico |
| Fala baixa ("(baixo)" no roteiro, humor sono) | teto 0,5 | −0,2 | 0 | cabeça baixa 2 u; volta a X entre palavras; D vira C |
| Fala tímida (humor saudade) | teto 0,45 | 0 | −0,3 | olhar desvia 0,4 para baixo; mais A/X; cantos caídos |
| Contente/radiante | normal | +0,2 | +0,3 / +0,6 | bochechas (já existem) |

### 3.6 Como o motor da série escolhe o formato

Entrada por fala: `F3[id].w` (palavras com início e fim, whisper) + `ENV[id]`
(envelope 30 qps) + texto do roteiro. Saída: trilha `[quadro, formato,
abertura, largura, canto]` por personagem, a 30 qps.

1. **Letras → fonemas → formatos** por palavra (regras pt-BR do §3.2; 25
   regras bastam: dígrafos ch/lh/nh/qu/gu, "x", "c/ç/g" antes de e/i, nasais
   com m/n de coda, ditongos, "r" final, "s" final → B).
2. **Distribuição no tempo**: vogais recebem 60 % da duração da palavra,
   consoantes 40 %, proporcionalmente; consoante com menos de 2 quadros
   (67 ms) é absorvida pela vogal seguinte ("impressionista"); p/b/m
   recebem **sempre** 2 quadros de A, mesmo roubando da vogal.
3. **Antecipação**: a trilha inteira anda **2 quadros para trás** (67 ms);
   em palavra com "!" ou envelope de pico > 0,9, 4 quadros.
4. **Fim de frase**: X entra 2–3 quadros depois do fim do áudio (3 se a fala
   termina em vogal, 1 se termina em m/n/p/b). Pausa entre palavras < 150 ms:
   fica em B com `abertura` 0,1, não em X.
5. **Amplitude só modula**: `abertura_final = abertura_formato × (0,6 +
   0,4·env)`; `ataque = clip(Δenv·3)` dispara aceno de cabeça de ≤ 3° que
   começa 4 quadros **antes** do pico, no máximo 1 por palavra. O balanço
   contínuo de `b4.js:96/104` sai.
6. **Filtro**: nenhum formato por menos de 2 quadros; nunca D→A em 1 quadro
   (passa por C); nunca A→D→A em 3 quadros; no máximo 8 trocas por segundo
   (fundir as menores).
7. **Grito**: só pelo formato D com `abertura` 1 e `largura` −0,3 vindo da
   captura do app (`QuadroFixo(vida: SaidaDaVida(boca: 1, largura: −0,3,
   susto: 1))`). O `this.grito` em SVG morre.

Exemplo, "Quem é você?!" (r2: Quem 0,14–0,28 s; é 0,28–0,48; você 0,48–0,96):
`k`→B 2q, `ẽ`→C 2q (nasal, sem fechar no "m"), `é`→D 5q (acento, env 0,9),
`v`→B 2q, `o`→E 3q, `s`→B 2q, `ê`→C 6q com abertura 1,0 (grito, "!"), X
em +3q. Tudo deslocado −4 quadros (grito). 8 trocas em 0,9 s.

### 3.7 Folhas e camada de boca

- Quadros fixos (`nov_ep4_test.dart:34-39`): por humor, 7 visemas (X A B C D
  E F) + 1 piscada = 8; 4 humores = 32; susto e festa com 7 cada = 46; cabe
  em 8 colunas × 6 linhas (48). `b4.js:98` passa a indexar por visema, não
  por `nv`.
- Laços de vida (120 quadros): capturar **uma** vez com boca X e `semBoca:
  true` (o painter não desenha a boca), e o painter **exporta a âncora** da
  boca por quadro (centro, escala `_cabecaDoEstagio`, giro de
  `_posicionaCabeca`, deslocamento `_rosto`) num JSON; a série compõe a boca
  do visema (capturada à parte, 7 por espécie × humor, fundo transparente) na
  âncora. É a camada de boca do Thimbleweed e o estado de boca do Duolingo:
  **substitui**, não sobrepõe.

---

## 4. Recomendações priorizadas

Formato: o que mudar · onde · aceite verificável · prioridade · fonte.

**R1. Matar a boca dupla.** Remover `this.grito` (`b4.js:66, 92, 106-111`) e
`e.grito` (`b4.js:222`); o grito passa a ser um quadro do app com boca D
(§3.6 item 7). Enquanto o app não tiver a boca nova, usar o quadro `28 + 5`
(susto, aberta) **sem** overlay. · Aceite: no render de `r2`, cada quadro tem
**um único** componente conexo de pixels na faixa de cor da boca (escuro
`#3E2F23`–`#4A2418` e rosa `#E57F78`) dentro da caixa da cabeça da Rio; o
`gera/auditor.py` ganha essa checagem e passa. · **Alta** · [App §1.6; Rookies;
Duolingo (estados de boca substituem)].

**R2. Gradação contínua e cavidade.** Em `_boca` (`pet.dart:6073-6098`):
trocar o bit `aberta` por `abertura = max(bocejo, carinho·0,6, mastiga,
vida.boca)`; altura `hMax(espécie)·abertura`, crescendo só para baixo a
partir da linha do lábio; interior `lerp(tinta, pelo, 0,25)`; contorno no
topo; língua em `abertura > 0,45`; dentes conforme §3.1. · Aceite: nas
capturas `bicho-*/0..5`, a altura da caixa da boca (pixels escuros do vão, a
×3) é **estritamente crescente** nos 6 níveis, com passo ≥ 3 px, nas 7
espécies de focinho; o topo da caixa fica a ≥ 6 px (2 u × 3) abaixo do pixel
mais baixo do nariz/focinheira. · **Alta** · [Rhubarb (ordem A<B<C<D); Lango
(maxilar gira, dentes de cima fixos); Rookies (só o maxilar inferior)].

**R3. Parâmetros e formatos nomeados.** Adicionar `largura`, `canto`,
`lingua`, `dentes` a `SaidaDaVida` (`motor_de_vida.dart:170-260`) e a
`QuadroFixo` (`pet.dart:1616`); `enum Visema {x, a, b, c, d, e, f}` com a
tabela §3.2 como `const` por espécie (`_bocaDa(especie)`), e um construtor
`QuadroFixo.visema(Visema)`. · Aceite: teste de widget captura os 7 visemas
da lontra e da gata e compara com golden; `largura` de F é ≤ 60 % da de B;
E é uma elipse fechada (razão altura/largura ≥ 0,7), D tem língua, B tem
linha de dentes. · **Alta** · [Preston Blair/Papagayo (10→7); Frameo ("5–6
bastam"); Character Animator (Smile/Surprised separados = `canto`)].

**R4. Âncoras por espécie com folga do nariz.** Tabela `_bocaDa(especie)` com
`o`, `w`, `hMax`, `folgaNariz`, `temDentes`, `temLingua`; `_boca` recebe a
tabela em vez de `(o, w)` soltos (`2975, 3097, 3278, 3759, 4163, 4373,
5035`). Gata e raposa: descer o centro da boca 1,5 u (17→18,5; 19→20,5) para
caber o D. · Aceite: para `abertura = 1`, a distância vertical entre o pixel
mais baixo do nariz e o mais alto do vão é ≥ 6 px (×3) nas 7 espécies; a
boca aberta não ultrapassa a base da cabeça (bolha) em nenhuma. · **Alta** ·
[App §1.2; Lango; Rookies].

**R5. Bicos com mandíbula.** Coruja (`3610-3619`) e pinguim (`3939-3964`):
separar mandíbula inferior que gira 0..25° / 0..30° com `abertura`; vão
escuro; E/F → C. Zurro do pinguim com inspiração antes (§3.3). · Aceite: em
`abertura = 1` o vão entre mandíbulas mede ≥ 4 u na base (12 px ×3) e o
contorno externo do bico muda (diferença de máscara ≥ 15 % da área do bico);
em `abertura = 0` as duas máscaras (antes/depois) coincidem. No episódio
`zurro`, o peito sobe ≥ 0,3 s antes do primeiro quadro de bico aberto (log do
motor). · **Alta** · [CalAcademy (display: bico para cima, peito enche);
Riede (bico fechado = som grave); Rookies (beak: in-betweens necessários)].

**R6. Buldogue atrás do beiço.** `_focinhoDoBuldogue` (`4957-5071`): lábio
inferior + dentinhos descem `abertura·10`; vão escuro entre os lobos; língua
interna em D; a língua de fora continua só radiante. · Aceite: em
`abertura = 1`, os dois dentinhos continuam visíveis (≥ 20 px brancos ×3
cada) sobre o vão escuro; o vão não sai da faixa x ∈ [−12, 12]; os lobos do
beiço não mudam de máscara. · **Média** · [Pawleaks (flew cobre o lábio de
baixo); App 5041-5066].

**R7. Trilha de visemas no motor da série.** Novo `gera/visemas.py`:
`texto + F3 + ENV → dados/<ep>_visemas.js`, com as regras §3.6 (1–6);
`b4.js` indexa a folha pelo visema e usa `ENV` só para modular `abertura` e
disparar acenos. · Aceite (automático, no próprio script): nenhum visema com
duração < 2 quadros; ≤ 8 trocas/s em qualquer janela de 1 s; para 100 % dos
p/b/m iniciais há um A de ≥ 2 quadros; a trilha começa ≥ 2 quadros antes do
primeiro quadro com `ENV > 0,2`; X entra 2–3 quadros depois do último quadro
com `ENV > 0,2`. Aceite visual: 10 s de `n1` e `f3` lado a lado com o render
atual, julgados por 3 pessoas; o novo vence em ≥ 2 de 3. · **Alta** ·
[Nordberg; Lango; Lemay; Frameo; Animator Island; Adobe Research (≥ 2
quadros, 40–80 ms de antecipação); Papagayo (palavra → fonemas)].

**R8. Folhas por visema e camada de boca ancorada.** `nov_ep4_test.dart`:
46 quadros fixos por espécie (§3.7); laços de vida capturados com
`semBoca: true` + JSON de âncoras exportado pelo painter; `folhas_app.py`
monta `boca-<esp>-<humor>.webp` com fundo transparente; `b4.js` compõe na
âncora. · Aceite: para 10 quadros aleatórios do laço, a composição
(base + boca na âncora) difere da captura completa do mesmo visema em ≤ 1 %
dos pixels (auditor compara); nunca há dois vãos escuros no mesmo quadro. ·
**Média** · [Thimbleweed (camadas cabeça/corpo/boca); Duolingo (estados de
boca em paralelo); Hey Duggee (reuso)].

**R9. Emoção na boca e no resto do rosto.** Tabela §3.5 implementada no
motor (`episodios.dart`) e no painter: grito, riso, espanto, baixa, tímida;
riso e grito com antecipação no corpo. · Aceite: capturas `grito-*` têm razão
altura/largura do vão > 1,0 e olhos com `fecha ≥ 0,3`; `riso-*` têm razão <
0,5 e `canto > 0,6`; `espanto-*` têm vão com razão entre 0,8 e 1,2 e largura
≤ 50 % de D; `baixa-*` nunca mostram D (altura ≤ 50 % de hMax). · **Média** ·
[Lango (extremos); Lemay (acentos, antecipação 4–6 q); Thomas & Johnston
(expressão no começo/fim; exagero com contenção); Moelk (miado abre e fecha;
rosnado tenso); CalAcademy].

**R10. Acentos de cabeça no lugar do balanço contínuo.** Em `b4.js:96, 104`,
retirar `rotate(sin(7,3t)·2,5°·fala)` e `translate(−2,5 %)` por fala; usar o
`aceno` do envelope (já calculado em `boca.py:55-57`): ≤ 3°, começa 4 quadros
antes do pico, ≤ 1 por palavra, decai em 8 quadros. · Aceite: durante a fala
o sinal da rotação da cabeça troca ≤ 2 vezes por segundo (hoje: 2,3 por
segundo contínuas); nenhuma rotação > 3°. · **Baixa** · [Lemay (antecipação;
"evite balanço excessivo"); Lango (deslocar a boca na pausa, não o corpo)].

**R11. Fala no app pelo balão de texto.** Quando o balão da home
(`pet.dart:338`) mostra um texto, gerar a trilha de visemas pelo texto
(§3.6 item 1) com 140 ms por sílaba (variando ±20 % com ruído), sem áudio,
e parar no fim da digitação; sem áudio, nunca D cheio (teto 0,8). · Aceite:
o balão de 12 sílabas fala por 1,5–2,0 s; `abertura` volta a 0 no quadro em
que a última letra aparece; nenhum visema < 4 quadros a 60 qps. · **Baixa** ·
[Thimbleweed (sem lip-sync em texto puro: cada um lê numa velocidade — por
isso a fala é curta e termina com a digitação); Frameo].

**R12. Tempo fonético de verdade.** Substituir o tempo por palavra do
`faster-whisper` por alinhamento forçado (WhisperX com modelo wav2vec2 de
português) ou pelo `rhubarb -r phonetic` como segunda fonte; comparar.
· Aceite: em 20 palavras sorteadas de `b4`, o início da vogal tônica medido
à mão (Audacity) difere do automático em ≤ 40 ms na mediana; o auditor
reporta a mediana. · **Baixa** · [WhisperX README; Rhubarb README].

---

## 5. O que não fazer

- **Não** multiplicar níveis de amplitude (6 → 12) sem desenhos distintos:
  continua sendo 2 bocas. Nem o contrário: 20+ visemas à la Duolingo sem
  animador para desenhá-los.
- **Não** sobrepor boca em SVG, PNG ou qualquer camada **por cima** de um
  quadro que já tem boca. Camada de boca só com `semBoca` na base.
- **Não** animar cada letra. Sons fracos somem; consoantes curtas viram a
  vogal vizinha; p/b/m e vogais acentuadas são o que se vê.
- **Não** mover o lábio superior, o nariz ou a focinheira ao abrir. A boca
  cresce para baixo. Bigode da gata e da lontra pode acompanhar 1 u.
- **Não** fazer bico em "O" ou "u" (E/F): bico abre em cunha; redondo é lábio.
- **Não** fechar a boca no "m/n" de fim de sílaba ("quem", "bem", "com").
- **Não** voltar ao repouso entre palavras coladas (< 150 ms); nem segurar a
  boca aberta parada por mais de 6 quadros sem variar 5–10 % a abertura.
- **Não** balançar o corpo inteiro a cada quadro de fala; acento é de cabeça,
  antes da vogal, e poucas vezes por frase.
- **Não** mostrar a língua em todo quadro aberto; só em D (e na língua de
  fora do buldogue radiante, que é outra coisa).
- **Não** tratar a cor do vão como terracota chapada; o interior é escuro,
  o rosa é a língua.

---

## 6. Fontes (lidas em 08/11/2026)

1. Rhubarb Lip Sync, README (formatos A–H, X; reconhecedor `phonetic`) —
   <https://github.com/DanielSWolf/rhubarb-lip-sync> e
   <https://raw.githubusercontent.com/DanielSWolf/rhubarb-lip-sync/master/README.adoc>
2. Duolingo Blog, "How we animate our World Characters' mouths" (visemas,
   20+ bocas, estados separados no Rive) —
   <https://blog.duolingo.com/world-character-visemes/>
3. Gary C. Martin, "Preston Blair phoneme series" (10 formatos) —
   <http://www.garycmartin.com/mouth_shapes.html>
4. Frameo, "Animation mouth chart" (9 formatos; regra "segure vogais, estale
   consoantes"; 5–6 bastam) — <https://frameo.ai/en/learn/animation-mouth-chart>
5. Papagayo, Lost Marble (texto → palavras arrastadas → fonemas; export) —
   <https://www.lostmarble.com/papagayo/> e
   <https://4232.tuxfamily.org/using-papagayo/>
6. Toon Boom Harmony 22, "Animating lip-sync" (8 letras e sons) —
   <https://docs.toonboom.com/help/harmony-22/premium/cut-out-animation/animate-lip-sync.html>
7. Adobe, "Lip sync mouth shapes" (Character Animator: Neutral, Smile,
   Surprised + 11 visemas) —
   <https://www.adobe.com/learn/adobe-character-animator/web/lip-sync-mouth-shapes>
8. Aneja & Li (Adobe Research), "Real-Time Lip Sync for Live 2D Animation",
   arXiv 1910.08685 (12 visemas; "nunca menos de 2 quadros"; 1–2 quadros /
   40–80 ms de antecipação; Voice Animator com 3 bocas; estilos de
   animadores) — <https://arxiv.org/abs/1910.08685> (PDF lido)
9. Cliff Nordberg / Alexander Williams, Animation Apprentice, "Why lipsync
   should be two frames ahead" — <https://animationapprentice.blogspot.com/2022/04/why-lipsync-should-be-two-frames-ahead.html>
10. Keith Lango, "Principles for lip sync animation" (reprodução) —
    <https://animationhelper.blogspot.com/2010/02/principles-for-lip-sync-animation-keith.html>
11. Brian Lemay, "Lip Synchronization" e "14 steps to successful lip sync
    breakdown" — <https://brianlemay.com/Pages/animationschool/animation/lipsyncbook/lipsync.html>
    e <https://brianlemay.com/Pages/animationschool/animation/lipsyncbook/breaking.html>
12. The Rookies, "A brief journey into lipsync for anthropomorphic
    characters" — <https://www.therookies.co/blog/breakdowns/tips-for-students-a-brief-journey-into-lipsync-for-anthropomorphic-characters>
13. Animator Island, "A lip-sync must-know for limited style animation"
    (fechar 2–3 quadros depois) — <https://www.animatorisland.com/a-lip-sync-must-know-for-limited-style-animation/>
14. Georgia Southern, "Conducting Cartoon Consonants: Using Phonetics to
    Improve Lip-Sync Animation" (resumo) —
    <https://digitalcommons.georgiasouthern.edu/curio-symposium/2020/2020/22>
15. Ron Gilbert, Thimbleweed Park blog, "Walking and Talking" —
    <https://blog.thimbleweedpark.com/walktalk.html>
16. Moho, tutorial 5.2 "Lip sync" (camada switch por fonema, dados externos) —
    <https://www.lostmarble.com/moho/manual/tut05/02/index.html>
17. MocapOnline, "Lip Sync Animation for Games" (amplitude → maxilar; 5–6 /
    6–8 / 15–20) — <https://mocaponline.com/blogs/mocap-news/lip-sync-animation-guide>
18. Wikipedia, "Twelve basic principles of animation" (Thomas & Johnston,
    páginas citadas) — <https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation>
19. Cartoon Brew, entrevista com Grant Orchard (Hey Duggee) —
    <https://www.cartoonbrew.com/?p=149069>
20. Good Sniff (Substack), "Creating Bluey: tales from the art director, ch. 2"
    — <https://goodsniff.substack.com/p/creating-bluey-tales-from-the-art-891>;
    Wikipedia, "Bluey (2018 TV series)" (CelAction2D) —
    <https://en.wikipedia.org/wiki/Bluey_(2018_TV_series)>
21. Riede, Eliason et al., "Coos, booms, and hoots: the evolution of
    closed-mouth vocal behavior in birds", *Evolution* 70(8), 2016 —
    <https://academic.oup.com/evolut/article/70/8/1734/6851892>
22. California Academy of Sciences, "Common penguin behaviors" (ecstatic
    display) — <https://www.calacademy.org/explore-science/common-penguin-behaviors>
23. Audubon, "Burrowing Owl" (voz, "howdy bird") —
    <https://www.audubon.org/field-guide/bird/burrowing-owl>;
    Wikipedia, "Burrowing owl" (balanço de cabeça, mancha do queixo) —
    <https://en.wikipedia.org/wiki/Burrowing_owl>
24. Wikipedia, "Cat communication" (classes de boca de Moelk 1944) —
    <https://en.wikipedia.org/wiki/Cat_communication>
25. Wikipedia, "Capybara", "Axolotl", "Turtle" (vocalização, dentes, bico de
    queratina, sucção) — <https://en.wikipedia.org/wiki/Capybara>,
    <https://en.wikipedia.org/wiki/Axolotl>, <https://en.wikipedia.org/wiki/Turtle>
26. Pawleaks, "Do dogs have lips?" (flews, buldogue) —
    <https://pawleaks.com/do-dogs-have-lips/>
27. Wikipedia, "Portuguese phonology" (vogais orais e nasais, redução,
    [tʃ dʒ]) — <https://en.wikipedia.org/wiki/Portuguese_phonology>
28. Wikipedia, "Formant" (F1/F2 × abertura/anterioridade; valores) —
    <https://en.wikipedia.org/wiki/Formant>
29. Chinelatto & Costa, "Tecnologia de captura de movimento facial aplicada ao
    estudo de padrões articulatórios da fala", Rev. PIBIC Unicamp 2018 (revisita
    De Martino 2005) — <https://econtents.sbu.unicamp.br/eventos/index.php/pibic/article/download/1017/1088/5441> (PDF lido)
30. WhisperX, README (alinhamento forçado, limites) —
    <https://github.com/m-bain/whisperx>

Não lidas (acesso negado ou indisponível na data, ficam como indicação):
tese de De Martino 2005 (core.ac.uk, 403); Jornal da Unicamp sobre os 29
visemas (503); Adobe helpx sobre visemas (403); "Voice Animator" (Furukawa et
al., ACE 2017, Springer, pago); fórum Spine sobre bico (não carregou).
Capturas de apoio no scratchpad desta sessão: `otter_niveis.png`,
`outros_niveis.png`, `otter_grito_duplo.png`.

# Laudo 31 — Anatomia, apelo e expressão: capivara (Baru), lontra (Rio) e tracajá (Toco)

Pesquisa para desenho vetorial chapado infantil. Novembro de 2026. Avança
sobre o laudo 06 (biologia, estágios, itens) e sobre 24/25 (motor de
movimento): aqui o assunto é **a forma do bicho e a cara dele** — silhueta,
proporção, orelha, focinho, bigode, cauda, casco, pescoço, cor — e as três
poses em que o dono reclamou: **fala (boca), susto e festa**.

**Legenda** (a mesma do laudo 06)

- **[F]** fato com fonte (número entre colchetes remete à seção "Fontes");
- **[O]** observação do app, com `arquivo:linha` ou imagem que eu abri/medi;
- **[I]** inferência minha, sem fonte que a prove.

**O que eu medi (reproduzível).** Abri as folhas de quadros
`novelinha-ep1/assets/img/app/bicho-{capybara,otter,tortoise}.webp`
(8 × 5 quadros de 543 × 428 px, geradas por
`gera/app_capturas/novelinha_quadros_test.dart`), recortei quadros com
Python/PIL e comparei pixel a pixel (diferença RGBA > 60, alinhando pela caixa
da silhueta). Medi cores reais nas fotos de capa dos artigos da Wikipédia das
três espécies (Wikimedia Commons, 960 px, mediana-corte em 5 cores por região)
[24]. Todas as fontes foram lidas em **2026-11-08**.

---

## 0. Resumo em 12 linhas

1. [O] **A fala tem só duas bocas.** A folha captura 6 níveis de abertura
   (`boca: i/5`), mas `_boca` só sabe "fechada" e "aberta" (`pet.dart:6076-6098`):
   os quadros nv0 = nv1 e nv2 = nv3 = nv4 = nv5 são **pixel a pixel idênticos**
   (diferença: nenhuma). A boca aberta é uma meia-elipse de **altura fixa 9 px**,
   seja "a" ou "u".
2. [O] **As "duas bocas" da Rio são um defeito da novelinha, não do app:**
   `b4.js:66` cria uma elipse `grito` e `b4.js:106-111` desenha essa elipse
   **por cima** do quadro do app em (266, 216), que já tem a boca pintada.
   Resultado: boca do painter + boca do JS, uma embaixo da outra.
3. [O] **O susto é um adesivo esticado.** Nas folhas, "susto" = o quadro
   "contente" esticado 9% na vertical e 5% mais estreito (caixa 372 → 405 px
   de altura; `pet.dart:2497-2498`), **sem nenhuma mudança no rosto**. No
   tracajá nem isso: 3,7% dos pixels. [F] Susto, em animação, é antecipação +
   mudança de silhueta [14].
4. [O] **A festa é brilho e bochecha**: "radiante" × "festa" diferem em 3,9%
   (capivara), 8,4% (lontra), 4,9% (tracajá) dos pixels. O corpo não comemora.
5. [F] **O esquema de bebê é o que faz "fofo"**: cabeça grande, testa alta,
   olhos grandes e **baixos** na cabeça, nariz e boca **sempre pequenos**,
   orelhas pequenas, **sem pescoço** (Preston Blair, 1947 [12]; Borgi 2014 [13]).
   O app já acerta cabeça, olho e pescoço; **erra a orelha da capivara (17% da
   largura da cabeça)** e a boca aberta (80% da largura da boca, 9 px de altura).
6. [F] **Capivara**: focinho **pesado e rombudo**, olhos e orelhas **no alto**,
   corpo de barril, patas da frente **mais curtas** que as de trás, pelo longo,
   grosso e **ralo**, castanho-avermelhado no dorso e amarelo-pardo no ventre
   [1][2]. [O] O app tem cabeça-bloco com focinho **raso** (faixa clara 74 × 44
   com nariz-botão de 26 × 15), orelhas de urso e corpo quase redondo (92 × 80).
7. [F] **Lontra**: cabeça **pequena e chata**, olhos pequenos e altos, orelhas
   curtas e redondas, **pescoço mais grosso que a cabeça**, focinho largo com
   **lábio superior, queixo e ponta do focinho branco-prateados**, garganta
   mais clara, cauda **larga e grossa na base**, afinando, com mais de 1/3 do
   comprimento [3][4][5]. [O] O app tem cabeça oval, garganta da cor do dorso,
   3 bigodes a 50% de alfa e **cauda-espinho** (base de 16 px, ponta em
   agulha) que sai de trás, para o lado.
8. [F] **Tracajá**: casco oval preto ou marrom, **pouco abaulado**, quilha baixa
   nos escudos 2–3, plastrão **amarelo**, manchas **amarelas** na cabeça (mais
   vivas no jovem) e **pescoço que dobra de lado** sob a borda do casco, nunca
   para trás [8][9]. [O] O app recolhe o pescoço **para baixo/para trás**
   (`pet.dart:3142-3147`, `3241`), desenha o pescoço em `claro` (a cabeça real é
   escura) e a cabeça é uma bola de 66 × 60.
9. [F] **Como nadam**: a capivara boia **só com olhos e narinas de fora** e
   fica até 5 min submersa [2]; a lontra de rio **rema só com as patas de trás**,
   alternadas, e **ondula o corpo e a cauda** quando submersa [6][7]; a
   tartaruga de água doce **rema** com a pata da frente de um lado **em fase com
   a de trás do lado oposto**, a 2,29 ciclos/s (*Trachemys*) [10]. [O] O app
   usa a mesma elipse de remada para os três (`_pata`, `pet.dart:5853-5865`),
   só nas patas da frente.
10. [F] Para a boca falar, o mercado usa **6 formas mínimas** (Rhubarb A–F
    [17]), 8 (Toon Boom [18]), 10 (Preston Blair/Papagayo), 11 (Adobe [19]) ou
    20+ (Duolingo [20]). Regras: abrir no **vogal**, fechar na consoante, segurar
    M/B/P por **≥ 2 quadros**, nunca abrir-fechar-abrir em 3 quadros [21].
    Com formas, o motor não precisa de fonema: só de **abertura** (0–1) e
    **arredondamento** (0–1).
11. [F] Em desenho infantil vetorial: **círculos** lêem como amigável, "sem
    canto duro"; **sem linha preta** de contorno, contorno na cor do objeto;
    sombra **colorida**, nunca neutra (Bluey [15]); começar nas formas
    geométricas e só então somar detalhe; gradiente em **um** personagem só
    (Hey Duggee [16]).
12. Recomendações: **R1 boca com gradação e 4 formas**, **R2 uma boca só na
    novelinha**, **R3 susto com rosto e silhueta**, **R4 festa no corpo**, e
    depois a assinatura de cada espécie (R5 capivara, R6 lontra, R7 tracajá),
    nado por espécie (R8), cores medidas (R9). Aceites por imagem e por número.

---

## 1. O que o app faz hoje

### 1.1 A construção comum (`pet.dart`)

| Peça | O que é | Onde |
|---|---|---|
| Olho | Esclera (círculo `r`), íris `0,50r` (0,56 feliz; 0,58 triste), pupila na íris, 2 brilhos (0,20r e 0,10r), piscada por escala vertical, pálpebra espelhada, sobrancelha "pidona" só na saudade | `_olho`, `pet.dart:5921-6046` |
| Boca | Traço 1,9 px em `sombraForte`. `aberta` é **booleano**: `bocejo > 0,3 ∨ carinho > 0,4 ∨ mastiga > 0,30 ∨ vida.boca > 0,3`. Aberta = meia-elipse de **largura 0,8·w e altura fixa 9 px**, cheia com `lerp(acento, tinta, 0,4)`. Fechada = 5 arcos por humor (radiante w × 0,72w; contente 0,8w × 0,5w; neutro reta 0,6w; sono 0,5w × 6; saudade 0,46w × 0,26w invertida) | `_boca`, `pet.dart:6073-6147` |
| Abertura da boca | `SaidaDaVida.boca` é 0..1 contínuo ("a boca ou o bico abertos sem comida") | `motor_de_vida.dart:183-192` |
| Bochecha | Oval 14 × 8 em `acento` a 24% (+20% no carinho), só quando `feliz` | `_bochecha`, `pet.dart:6180-6188` |
| Bigodes | 3 cúbicas por lado, 19 px, 1,2 px de traço, `sombraForte` a **50%** | `_bigodes`, `pet.dart:6192-6212` |
| Orelha | Oval `w × h` em `sombra` + concha 0,52 | `_orelhaRedonda`, `pet.dart:5888-5910` |
| Pata | Bolha `w × h` + 3 risquinhos de dedo; nadando, descreve **elipse 7 × 9 px**, meio ciclo defasada da outra, recolhida 9 px | `_pata`, `pet.dart:5828-5882` |
| Susto | Só `achata` negativo: o **corpo inteiro estica** (`vida.susto * 0,9`) | `pet.dart:2497-2498` |
| Festa | Tremor senoidal `sin(ciclo·π·14)·0,7·vida.festa` no corpo; na folha, humor radiante + brilhos | `pet.dart:2509`; `novelinha_quadros_test.dart:46` |

### 1.2 Capivara — `_capivara` (`pet.dart:2882-2988`)

- Corpo: bolha **92 × 80** centrada em (0, 18) → quase redondo (1,15 : 1).
- Patas da frente: 27 × 17 em (±23, 51), as únicas visíveis.
- Cabeça: `RRect` **94 × 74**, cantos 34/26, centro (0, 2), deslocada −30.
- Orelhas: 16 × 14 em (±40, −19) → **17% da largura da cabeça**.
- Focinho: faixa clara 74 × 44 **na metade de baixo** (centro y = 27);
  "focinheira" 26 × 15 em (0, 12); boca em (0, 27), w = 26.
- Olhos: r = 7,5 em (±26, −13), 55% da largura da cabeça entre eles.
- Bochecha em (±34, 18) quando feliz.
- Sem textura de pelo, sem narinas desenhadas (a focinheira é um botão).

### 1.3 Lontra — `_lontra` (`pet.dart:2994-3126`)

- Cauda: duas cúbicas de (26, 34)/(26, 50) até a ponta (78, 6): **base de 16 px**
  (24% da largura do corpo), ponta em agulha, sai **para a direita, atrás**.
- Corpo: bolha **66 × 90** (pera em pé); patinhas 16 × 13 em (±20, 50).
- Cabeça: bolha **78 × 62**, deslocada −34; orelhas 11 × 9 em (±31, −16).
- Máscara clara 50 × 34 em (0, 14); focinheira 19 × 13 em (0, 6); boca (0, 19)
  w = 20; olhos r = 7,5 em (±21, −12); bigodes em (±22, 12).
- Garganta e peito: **mesma cor do dorso** (a barriga clara começa no corpo).
- Comendo: comida em (0, 30) entre dois ovais de pata 13 × 10 (`3104-3118`).

### 1.4 Tartaruga — `_tartaruga` (`pet.dart:3135-3288`)

- Patas: 25 × 22 em (±47, 52), só as da frente.
- Casco: bolha **102 × 78** em (0, 26), cor `lerp(sombra, #6B5334, 0,32)`;
  fileira central 62 × 60 mais clara; 2 arcos e 7 riscos de escudo em
  `tintaA(0,32)` 2,6 px; plastrão 68 × 42 em `barriga` (y = 54).
- Pescoço: trapézio de 34 px de largura e `38 + 1,34·estica` de comprimento,
  **em `claro`**; `estica = boia·2,4 + carinho·7 + (nadando ? 11 : 0) +
  vida.pescoco·9` (`3142-3147`): recolher = **descer em linha reta**.
- Cabeça: bolha **66 × 60**; listra vermelha em x 22..32 (`3263-3272`);
  narinas (±6, 6); boca (0, 16) w = 24; olhos r = 7 em (±14, −9), **41%** da
  largura da cabeça entre eles.

### 1.5 O que a novelinha faz com isso (`assets/b4.js`)

- Quadro estático: `nv = round(abre·1,4·5)` limitado a 5 → **6 níveis** de boca,
  quadro `humor·7 + nv` (`b4.js:98-99`). Como `_boca` é booleana, só existem
  **2 desenhos** entre os 6 (medido: nv0 ≡ nv1, nv2 ≡ nv3 ≡ nv4 ≡ nv5).
- Quadro vivo: 3 folhas `vida-<esp>-{0,1,2}` escolhidas por
  `round(abre·1,5)` (`b4.js:90`); níveis 1 e 2 são a mesma boca.
- **`grito`** (`b4.js:66`, `106-111`): elipse `#4A2418` + língua `#E57F78`
  desenhadas por cima do quadro, só para `otter`, em (266, 216), quando
  `e.grito > 0,08`. O quadro por baixo **já tem boca** → duas bocas.
- Susto e festa usam os quadros 28–33 e 34–39 da folha, que são os descritos
  no §0 (itens 3 e 4).

### 1.6 Medidas das folhas atuais (capturas de 543 × 428)

| Espécie | silhueta w/h | contente × susto (alinhado) | caixa contente → susto | radiante × festa | fala nv2 × nv5 |
|---|---|---|---|---|---|
| capivara | 0,77 | 27,7% | 288 × 372 → 272 × 405 | 3,9% | **0,0%** |
| lontra | 0,97 | 39,9% | 359 × 372 → 328 × 406 | 8,4% | **0,0%** |
| tracajá | 0,93 | 3,7% | 358 × 386 → 358 × 386 | 4,9% | **0,0%** |

[O] Os 27–40% do susto são o **corpo inteiro reescalado** (mais alto, mais
estreito), não uma pose: rosto, orelha, boca e patas ficam iguais. O tracajá
não estica (não tem `achata` ligado ao susto na mesma medida) e fica em 3,7%.

---

## 2. O que as fontes dizem

### 2.1 O que faz um bicho ler como "fofo" sem perder a espécie

- [F] Preston Blair, *Advanced Animation* (1947), prancha "The Cute Character"
  [12]: "**head large in relation to the body**"; "**high forehead is very
  important**"; "eyes spaced **low** on head — usually large and wide apart";
  "**noses–mouth are always small**"; "ears are small in relation to adult
  size"; "**no neck — head joins on to body directly**"; "tummy bulges — looks
  well-fed"; "fat legs — short and tapering down into small feet"; "cuteness
  is based on the basic proportions of a baby + expressions of **shyness or
  coyness**". Na prancha do esquilo: "as in cute characters, head is large —
  important are the two front teeth" (o traço da espécie fica).
- [F] Borgi et al. 2014 [13]: esquema de bebê = testa alta e saliente, olhos
  grandes, nariz e boca pequenos, cara redonda, cabeça grande. Em crianças de
  3–6 anos, as versões "mais bebê" foram julgadas mais fofas em humano, cão e
  gato; **os olhos recebem 46% das fixações e 47% do tempo de olhar**; em cão e
  gato, mais atenção aos olhos e menos à boca do que em humanos.
- [F] Thomas & Johnston, *The Illusion of Life* (1981), via [14]: *appeal* é
  "o que seria carisma num ator"; *solid drawing* condena os **"twins"**
  (lados esquerdo e direito espelhados, "sem vida"); *squash and stretch*
  **preserva o volume** (esticou, afina); *anticipation* prepara a ação
  (dobrar o joelho antes de pular); *staging* é "apresentar a ideia de modo
  completo e inconfundível"; *exaggeration* porque a cópia exata "parece
  estática e sem graça".
- [F] Bluey (Ludo Studio, direção de arte Catriona Drummond) [15]: círculos
  "redondos, amigáveis, suaves — **sem canto duro**"; triângulos "evocam dor";
  quadrados "firmes"; horizontais calmas, verticais despertas, diagonais
  desequilibradas. "**Não usar line-art preta**": o contorno é colorido pelo
  objeto e pela luz. "**Evitar tons neutros de sombra**": a sombra é mais fria
  ou mais quente que o objeto. "Sempre errar para o mais colorido". Objetos
  "fofos, simplificados e **chunky**, com proporções de casa de boneca". Gags
  caninas literais, não; "nods" sutis ao cachorro, sim.
- [F] Hey Duggee (Grant Orchard, Studio AKA) [16]: começou com "formas
  geométricas básicas" e "jogou uns olhos e bocas"; "**sem contorno e sem
  efeitos** além do que o Flash faz"; "**começar simples e depois somar**";
  Duggee é "o único com gradiente" e, por ser o mais detalhado, "mover as
  feições um pouco o tira do modelo"; com seis personagens no quadro, detalhe
  "congestiona e confunde as crianças".

### 2.2 Boca que fala (o que o mercado desenha)

- [F] Rhubarb Lip Sync [17]: **6 formas mínimas** A (fechada, lábios
  pressionados: P B M), B (entreaberta, dentes juntos: a maioria das
  consoantes e "ii"), C (aberta: "é", "a" de *bat*; também o meio-caminho
  entre A/B e D), D (**bem aberta**: "a" de *father*), E (**pouco arredondada**:
  "ó", "er"; meio-caminho entre C/D e F; "nunca mais aberta que C"), F
  (**bico**: "u", "ou", "w"). Opcionais: G (dente no lábio: F V), H (língua: L),
  X (repouso: "quase igual a A, lábios relaxados").
- [F] Toon Boom Harmony [18]: 8 posições A (m b p h), B (s d j i k t), C (e a),
  D (A E), E (o), F (u oo), G (f ph), X (silêncio). As letras "**não**
  correspondem ao som".
- [F] Adobe Character Animator [19]: 3 bocas mudas (Neutral, Smile, Surprised)
  + **11 visemas** (Ah, D, Ee, F, L, M, Oh, R, S, Uh, W-Oo); "Neutral é a que
  todo boneco com boca precisa ter".
- [F] Duolingo [20]: "um conjunto de **20+ bocas** desenhado para todos", com
  um *viseme chart* por personagem; **estados de boca separados dos estados de
  corpo**, rodando ao mesmo tempo na máquina de estados; critério de projeto:
  "**believability** quando animado".
- [F] Regras de sincronismo (Alexander Williams, Animation Apprentice [21]):
  "abrir a mandíbula nas **vogais**, fechar nas consoantes"; **não animar
  todo fonema** ("chattery"); uma boca que "fecha, abre e fecha em **3
  quadros** lê como erro"; segurar **M, B, P por ≥ 2 quadros**; conferir "as
  larguras (ee) contra as estreitas (oo)"; usar espelho.
- [F] Personagem com focinho (The Rookies [22]): "**humanos só movem a
  mandíbula de baixo**"; mover a de cima "só para exagero, e não abusar"; a
  boca "é elemento-chave da silhueta da cabeça"; sons acentuados são "os
  *highlights* da palavra"; desenhar a boca "**1 ou 2 quadros antes** do
  áudio"; entre palavras os lábios podem ficar entreabertos.

### 2.3 Capivara (*Hydrochoerus hydrochaeris*)

- [F] Forma [1][2]: "corpo em **barril**", "parece um porquinho-da-índia
  grande", **sem cauda**; "focinho **pesado e rombudo**"; "olhos e orelhas
  **pequenas** no **alto** da cabeça, o que a deixa alerta quase submersa";
  "olhos, orelhas e narinas **no topo** da cabeça"; "**patas da frente mais
  curtas** que as de trás"; unhas "fortes, como cascos"; 4 dedos na frente, 3
  atrás, pouco palmados; pegada em estrela.
- [F] Pelo e cor [1][2]: "pelo **longo, grosso e ralo**" (ajuda a secar);
  "**castanho-avermelhado a acinzentado** em cima, **amarelo-pardo** embaixo";
  "algum preto na cara, nos membros e na garupa". Macho tem o *morrillo*
  (glândula nua no alto do focinho) [1] — o laudo 06 já decidiu não desenhar.
- [F] Movimento [2]: "nadadora forte", corpo "só um pouco mais denso que a
  água"; **escondida, boia só com narinas e olhos de fora**; até **5 min**
  submersa; pasta capim "vigiando o tempo todo"; o latido do adulto manda o
  grupo para a água. Deitada: "a maior parte do corpo no chão" (etograma JZAR,
  já no laudo 06 §2.1).
- [F] Muybridge, *Animal Locomotion* (1887), prancha 746 "Capybara walking",
  9 quadros [23]: referência pública do **andar** real, de perfil (não descreve
  o passo; serve de modelo para o ciclo de 4 tempos do laudo 24).
- [O] Cor medida na foto de capa (Pantanal, luz de fim de tarde) [24]: dorso
  **#8A5344** (33%), #73453B, #613529, luz #AF865D; cabeça #79523E, #917055,
  #A8866E; ventre na sombra #602815, #421C10. A paleta do app
  (`tokens.dart:135-142`: #B07A4E, #8F5F3A, #C98A5B, #9C6B47, #D9A87C,
  #7A5133) é **mais amarela e mais clara**; o tom mais próximo do real é o
  último (#7A5133).

### 2.4 Lontra-neotropical (*Lontra longicaudis*)

- [F] Cabeça [3][4]: "**pequena e chata**, com olhos pequenos e orelhas curtas
  e redondas"; crânio "longo e chato"; "focinho curto e **largo**, tudo
  arredondado"; "**pescoço mais grosso que a cabeça**"; "olhos **altos** na
  cabeça"; rinário "preto, sem pelo"; "**numerosas** vibrissas longas e
  fortes".
- [F] Cor [3][4][5]: pelo "curto, denso, liso, **castanho-acinzentado
  lustroso**", mais claro nos flancos; ventre pardo-claro a creme; "**garganta e
  lábios muito mais claros**, creme ou branco em alguns"; "**lábio superior,
  mandíbula e ponta do focinho branco-prateados a amarelados**".
- [F] Cauda [3][4][5]: "longa, **larga e bem grossa na base**, afinando até a
  ponta", "cilíndrica", "mais de 1/3 do corpo"; corpo 36–66 cm, cauda 37–84 cm.
  Patas "curtas e grossas", traseiras maiores, **5 dedos palmados até a ponta**,
  com garras.
- [F] Movimento [3][6][7]: "**galope corcunda**, cabeça e cauda baixas, dorso
  arqueado alto"; mergulhos de 20–30 s; presa pequena comida **na água**, a
  grande levada à margem. Nado (lontra-de-rio, mesmo gênero): "as **patas de
  trás** dão a propulsão, as da frente só remam" [6]; cauda "altamente
  muscular, achatada, até 40% do comprimento", "movimento **ondulante**"
  propulsor, 13 km/h; corpo "torce, vira, **rola** e mergulha" [6]; usa
  "ocasionalmente o polegar e as patas da frente para **segurar** a presa"
  [6]. Fish 1994 (via [7]): lontras de rio "nadam com **batidas alternadas das
  patas traseiras apenas**" (paddling pélvico alternado) e "**não usam as da
  frente** para propulsão"; "a cauda dá empuxo no retorno"; "*Lutra* **ondula
  principalmente sob a água**", com o tronco rígido na superfície.
- [F] Sons [5]: assobios, *hums* e guinchos.
- [O] Cor medida (foto molhada ao sol) [24]: cabeça/dorso **#584744** (33%),
  #73584F, #3D322E, reflexo #936F60; **garganta #90776B / #C9A991**, reflexo
  #D2DACE; focinho #A77E6B e **lábio #E1B79C**. A paleta do app
  (`tokens.dart:145-152`: #6E4B33 … #9C7A5E) é **mais quente** (chocolate) que
  o cinza-castanho real; não há cor de garganta.

### 2.5 Tracajá (*Podocnemis unifilis*)

- [F] Forma [8][9]: "casco oval **preto ou marrom**", "levemente abaulado, com
  uma crista central (quilha)", "quilhas **baixas** nos escudos 2 e 3";
  plastrão "**amarelo**, às vezes com marcas escuras"; até 45 cm e 8 kg; fêmea
  até 2× o macho; "**manchas amarelas** nos lados da cabeça", "mais vivas nos
  jovens, somem com a idade"; um barbilhão no queixo (*unifilis*).
- [F] Pescoço [8][9]: "**não consegue puxar a cabeça para trás**; dobra o
  pescoço **de lado** e encaixa a cabeça **sob a borda do casco**".
- [F] Rotina [8][11]: mais ativo "**meio da manhã e tarde**"; na lagoa de
  Parintins, **assoalha (toma sol) sobretudo das 11h às 15h** e nada mais cedo
  e no fim da tarde; filtra partículas na superfície (neustofagia).
- [F] Nado [10]: tartarugas de água doce **remam**: "movimento anteroposterior
  dos membros com golpe de força e de recuperação distintos"; "a pata da frente
  de um lado se move **em fase com a de trás do lado oposto**"; fore e
  hindlimbs contribuem; frequência de **2,29 ± 0,04 ciclos/s** em *Trachemys
  scripta* (1,78–2,29 nas espécies medidas). Tartarugas marinhas **batem**
  (dorsoventral, síncrono) — o que **não** se deve copiar.
- [O] Cor medida (fêmea adulta de zoológico, manchas apagadas, casco
  empoeirado) [24]: casco **#79745F**, #99968F, #ACAAA2; cabeça #5D5950,
  #34332B, #857858. Para as manchas do jovem não medi foto: mantenho o
  **#F2C94C** do laudo 06. A paleta do app (`tokens.dart:155-162`, oliva) é
  **mais verde** que o real; a cabeça real é **cinza-escura/oliva-escura**.

---

## 3. Avaliação do desenho atual, traço a traço

### 3.1 O que vale para os três

| # | Observação [O] | Por que é fraco [F] | Onde |
|---|---|---|---|
| G1 | Boca aberta = meia-elipse **0,8·w × 9 px**, para qualquer `boca > 0,3`. | Blair: "boca **sempre pequena**" no fofo [12]; Rhubarb/Toon Boom/Adobe: a fala precisa de ao menos 6–8 formas, com "E nunca mais aberta que C" [17][18][19]; Borgi: a boca pesa pouco no olhar, então ela pode ser pequena sem perder leitura [13]. | `_boca`, `pet.dart:6084-6098` |
| G2 | Nenhuma forma arredondada ("u", "ô"): a boca só varia em altura. | F (bico) e E (pouco arredondada) são 2 das 6 formas mínimas [17]. | idem |
| G3 | Susto = reescala uniforme (+9% altura, −5% largura) do corpo inteiro, rosto igual. | *Anticipation* e silhueta: "a ideia tem de ser inconfundível" [14]; "twins" e simetria denunciam o procedural (laudo 24). | `pet.dart:2497-2498` |
| G4 | Festa = radiante + brilhos + bochecha (3,9–8,4% dos pixels). | Exagero: "a cópia exata parece estática" [14]; Bluey: ação no corpo, não no efeito [15]. | `pet.dart:2509`; folha 34–39 |
| G5 | Mesma remada elíptica 7 × 9 px, só patas da frente, nas 3 espécies. | Capivara boia "só com olhos e narinas" [2]; lontra rema **só com as de trás** e ondula [6][7]; tartaruga rema em diagonal, frente de um lado + trás do outro [10]. | `_pata`, `pet.dart:5853-5865` |
| G6 | Contorno em `sombraForte` (certo: não é preto); sombra do queixo e da água são **neutras** (tom escurecido do próprio pelo). | Bluey: sombra **mais fria ou mais quente** que o objeto, nunca neutra [15]. | `_sombraDoQueixo`, `_tomDaAgua` (`pet.dart:6221`) |

### 3.2 Capivara (Baru)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Silhueta | Cabeça-bloco 94 × 74 sobre corpo 92 × 80 (1,15 : 1); w/h da figura 0,77 | Barril **mais largo que alto**, patas da frente curtas, sem pescoço [1][2] | Fraco: lê como urso/hamster sentado (06 §2.2 já disse); o corpo precisa ser **mais largo que alto** |
| Orelha | 16 × 14 em (±40, −19) = **17%** da largura da cabeça, arredondada | "orelhas **pequenas**", "no alto" [1][2]; na foto [24] a orelha tem ≈ 6% do comprimento da cabeça; Blair: "orelhas pequenas" no fofo [12] | **Errado**: é o traço que mais estraga a espécie. Alvo ≤ 10% |
| Focinho | Faixa clara 74 × 44 na metade de baixo + botão 26 × 15; **sem narinas** | "**pesado e rombudo**": é a parte mais funda da cabeça; **narinas no topo** [1][2] | Fraco: o focinho é raso e o nariz é de ursinho. Precisa de **bloco rombudo** com duas narinas no alto |
| Olhos | r 7,5 em (±26, −13): altos, 55% afastados | "olhos pequenos, **altos e laterais**" [1][2]; Blair: "grandes e bem afastados" no fofo [12] | Certo: manter grandes (fofura) e altos (espécie); subir 2 px e afastar para ±30 |
| Pelo | Liso | "longo, grosso e **ralo**" [1][2] | Fraco: 4–6 traços no topo da cabeça e na garupa bastam (Hey Duggee: detalhe mínimo [16]) |
| Cor | #B07A4E padrão | dorso #8A5344, ventre amarelo-pardo [1][24] | Meio: a paleta está amarela demais; o ventre certo (mais claro e mais amarelo) já existe como `barriga` |
| Nado | Corpo afunda, cabeça inteira de fora, remada das patas da frente | "só narinas e olhos de fora" [2] | Fraco: falta a pose-assinatura (olhos, orelhas e narinas na linha d'água) |
| Susto | Reescala | Alerta: fica em pé, parada, e corre para a água ao latido [2] | Fraco: nem orelha, nem olho, nem boca mudam |
| Festa | Brilhos | Corpo pesado: comemora **com pouco pulo** e muita água (chafurda) [2] | Meio: a capivara "radiante" é serena (03 §tabela); a festa deve ser **respingo**, não salto |

### 3.3 Lontra (Rio)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Cabeça | Bolha 78 × 62 (1,26 : 1) | "pequena e **chata**", crânio "longo e chato", olhos **altos** [3][4] | Fraco: achatar para ≈ 1,45 : 1 e subir os olhos |
| Pescoço | Cabeça colada ao corpo (fofo, certo) | "**mais grosso que a cabeça**" [3][4] | Certo para o fofo; o pescoço grosso vira **garganta clara larga** (abaixo) |
| Garganta | Cor do dorso | "garganta e lábios **muito mais claros**, creme ou branco" [4]; lábio **#E1B79C**, garganta **#C9A991** [24] | **Errado**: é o traço que separa lontra de capivara à distância (06 §3.3 já apontou; aqui fica a cor e a geometria) |
| Focinho | Máscara 50 × 34 + focinheira 19 × 13 | "largo e curto", rinário "preto, sem pelo"; lábio superior **prateado** [3][4] | Meio: a máscara é boa; o lábio superior precisa ser a parte mais clara |
| Bigodes | 3 por lado, 19 px, **50% de alfa**, cor escura | "**numerosas** vibrissas longas e fortes" [4]; "longos, rígidos" [6] | Fraco: somem na home (06). Devem ser **claros** (#E1B79C), 4–5 por lado, ≥ 24 px, 85–100% de alfa |
| Cauda | Base 16 px (24% do corpo), agulha, sai atrás para a direita | "**grossa na base**, afina", 1/3 a 40% do comprimento, "achatada", é o propulsor [3][4][6] | **Errado**: vão branco na base (06), espinho de rato. Base ≥ 30% da largura do corpo, cônica, **enrolando à frente** dos pés quando sentada |
| Patas | Patinhas 16 × 13 | "curtas e grossas", 5 dedos palmados, garras [4] | Meio: 3 risquinhos ok; patas da frente ligeiramente maiores (segurar comida) |
| Cor | #6E4B33 (chocolate) | "castanho-**acinzentado** lustroso" [3]; medido #584744 [24] | Meio: esfriar a paleta; manter a variante mais clara (#9C7A5E) para contraste |
| Comer | Comida entre 2 ovais em (0, 30) | "usa ocasionalmente polegar e patas da frente para segurar" [6] | Certo (laudo 24); falta só a cabeça baixar até a comida (mandíbula de baixo mexe [22]) |
| Nado | Remada das patas da frente | Propulsão **só das traseiras**, alternadas; cauda ondula; tronco rígido na superfície, ondula submersa [6][7] | **Errado** no mecanismo: as patas da frente devem ficar **juntas ao peito**; a cauda e a linha do dorso é que se movem |
| Susto | Reescala | "torce, vira, rola" [6]; alarme vocal "hahh" (06) | Fraco: a lontra assustada **encolhe o pescoço e arrepia os bigodes**; a cauda sobe |

### 3.4 Tracajá (Toco)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Casco | Bolha 102 × 78 (1,31 : 1), cúpula; plastrão `barriga` | "oval, **levemente** abaulado", quilha **baixa** nos escudos 2–3, plastrão **amarelo** [8][9] | Fraco: visto de frente lê "babador sobre saco" (06 §4.3). Casco mais **largo e baixo** (≥ 1,5 : 1), borda marginal visível, plastrão amarelo |
| Cabeça | Bola 66 × 60; olhos a 41% de distância | Cabeça achatada, focinho em ponta, olhos **laterais**, manchas amarelas, 1 barbilhão [8][9] | Fraco: "bola verde com dois olhos" (06); a decisão de trocar a listra por manchas já está tomada (00-SINTESE); aqui entra a **forma** |
| Pescoço | Trapézio 34 px em `claro`; recolhe **descendo em reta** (`estica` negativo) | Pescoço **escuro** como a cabeça; recolhe **dobrando de lado** sob a borda [8][9] | **Errado**: o gesto de espécie é o lateral (06 §4.5 pediu; o código não faz). A cor `claro` cria um "pescoço de boneco" |
| Patas | 25 × 22 blobs, 3 riscos | Palmadas, com unhas; na água **remam** em diagonal [10] | Fraco: faltam as **traseiras** (visíveis atrás do casco) e a cadência 2 ciclos/s |
| Cor | #6F7D4A (oliva) | Casco preto/marrom, cabeça cinza-escura; medidos #79745F / #5D5950 [8][24] | Meio: oliva mais escuro e mais cinza no casco; o verde-claro vai para o reflexo d'água, não para a pele |
| Sol | Não existe pose | Assoalha das 11h às 15h, mais ativo meio da manhã e tarde [8][11] | Falta: a pose "tronco ao sol" (06 §4.5, sem fonte então; **agora com fonte**) nos períodos "dia" do `pinta_mundo` |
| Susto | 3,7% (nada) | Sinal de estresse em réptil é **esconder a cabeça** (Warwick 2018, laudo 06) | Fraco: o susto do tracajá é a **dobra lateral rápida** (300 ms) — e só no susto, nunca na saudade (06) |

---

## 4. Recomendações priorizadas

Formato: **o que mudar · onde · aceite verificável · prioridade · fonte**.
As medidas são em unidades do painter (cabeça da capivara = 94 de largura).

### R1 — Boca com gradação contínua e quatro formas (alta)

**O que mudar.** Trocar o booleano `aberta` por dois contínuos:
`abre = max(bocejo, carinho·0,8, mastiga, vida.boca)` (0–1) e um novo
`SaidaDaVida.bocaRedonda` (0–1). Desenhar a boca como **uma** forma
parametrizada (sem trocar de desenho):

| Faixa de `abre` | Forma (Rhubarb) | Geometria |
|---|---|---|
| 0–0,10 | X/A fechada | arco do humor atual |
| 0,10–0,35 | B/C entreaberta | elipse `w·(0,55 − 0,15·redonda) × w·(0,10 + 0,6·abre)` |
| 0,35–0,75 | C/D aberta | mesma fórmula; interior `lerp(acento, tinta, 0,4)`; **língua** oval `0,45·w × 0,18·w` em `#E57F78` quando `abre > 0,5` |
| 0,75–1,0 | D bem aberta | altura máxima `0,55·w`; largura **nunca** acima de `0,62·w` (boca pequena [12]) |
| `redonda > 0,5` | E/F | largura cai para `0,32·w`, cantos arredondados (bico), altura `0,35·w` |

A mandíbula de baixo é a única que desce: o topo da boca fica fixo em `o.dy`
e a elipse cresce **para baixo** [22]. Com `abre > 0,5`, o queixo (bolha da
cabeça) desce `3 + 4·abre` px e a bochecha sobe 1 px (o "accent" da vogal
[21]). **Onde.** `_boca` (`pet.dart:6073-6147`); `SaidaDaVida`
(`motor_de_vida.dart:183-192`), `MotorDeVida._boca` (`:490`, `:1074`,
`:1423`); captura em `novelinha_quadros_test.dart:40,45-46` (manter `i/5`);
`b4.js:90,98` já suportam 6 níveis. Para a fala por TTS da novelinha, o JS
pode mandar `redonda` a partir do envelope de energia grave (sem fonema) [I].
**Aceite.** (a) Na folha nova, os 6 quadros `fala-<esp>-contente-{0..5}` são
**6 imagens distintas** (diferença > 0 entre vizinhos) e a **altura da
abertura é monótona crescente** (medir a caixa do interior `acento`:
≈ 0, 3, 6, 9, 12, 14 px na captura de 543 px → proporcional); (b) largura da
boca aberta ≤ 0,62·w em todos; (c) existe um quadro "redondo" com largura ≤
0,35·w; (d) nos vídeos de teste da novelinha, nenhuma sequência fecha-abre-fecha
em ≤ 3 quadros a 30 qps (verificar com o script que lê `ENV`) [21].
**Fontes.** [17][18][19][21][22][12].

### R2 — Uma boca só na novelinha (alta)

**O que mudar.** Apagar o `grito` (`b4.js:66`, `:92`, `:106-111`) e a tabela
`GR`. O "grito" passa a ser `abre = 1, redonda = 0,3` no quadro do app (R1),
com `sq` (achata) e o tremor que já existem em `b4.js:96,104`. Se a Rio
precisar de língua, ela vem do painter (R1), nunca de uma elipse por cima.
**Onde.** `assets/b4.js`. **Aceite.** Em todos os quadros do episódio onde
`falando("rio")`, o recorte da região da boca (x 230–300, y 200–250 do quadro
de 543) contém **um único** componente conexo de cor de interior
(`#4A2418`/`lerp(acento,tinta)`), contado com PIL; hoje há dois.
**Fontes.** [O] `b4.js`; [22] (a boca é parte da silhueta da cabeça, não um
adesivo).

### R3 — Susto com rosto e silhueta, por espécie (alta)

**O que mudar.** Manter o estica (`achata` negativo) mas **no corpo só**, com
volume preservado (altura +9% → largura −9%, não −5%) [14], e somar o rosto:
olhos **1,25·r** com íris **0,30·r** (pupila encolhe), pálpebra de cima some,
sobrancelhas sobem `0,4·r` (sem a curva pidona), boca **E/F** pequena
(`abre 0,45, redonda 1`), bochechas desligadas, orelhas giram +0,35 rad para
cima e tremem (já existe `pose.orelha`). Antecipação de **2 quadros** (67 ms a
30 qps) de agachada (−4% altura) antes do estica [14]. Por espécie:

- **Capivara**: corpo não salta; congela, orelhas para cima, olhar para fora da
  cena; se estiver na água, afunda até a linha dos olhos (R8) [2].
- **Lontra**: pescoço some (cabeça desce 6 px), bigodes para a frente (+0,3 rad)
  e a **cauda levanta** rígida, ponta 20 px acima do normal [6].
- **Tracajá**: cabeça **dobra de lado** sob a borda em 300 ms (R7, geometria
  lateral), patas recolhem 10 px sob o casco; sem olhos arregalados (olho
  pequeno, lateral): a leitura vem da cabeça sumindo [8][9].

**Onde.** `pet.dart:2497-2498` (achata), `_olho` (novo parâmetro `susto`),
`_boca` (R1), `_lontra` cauda (`:3003-3024`), `_tartaruga` `estica`
(`:3142-3147`); captura `novelinha_quadros_test.dart:45`.
**Aceite.** Na folha nova, `susto-<esp>-0` × `contente-0` **alinhados pela
caixa**: ≥ 20% dos pixels diferentes **dentro da caixa da cabeça** (hoje 0%);
e a relação largura/altura da caixa do corpo muda ≥ 8% com volume mantido
(área da silhueta varia < 3%). Teste de 5 s com 10 pessoas: ≥ 8 dizem "levou
um susto" sem legenda.
**Fontes.** [14][2][6][8][9][22].

### R4 — Festa no corpo, não no brilho (alta)

**O que mudar.** A festa (`vida.festa`) vira um ciclo de **0,5 s** com
antecipação, pulo e pouso (squash) por espécie:

- **Capivara**: pulo baixo (6 px) com **respingo** d'água de 2 gotas por lado
  quando na água; orelhas tremem; boca D aberta 0,6 com olhos fechados em arco
  feliz (o arco já existe em `_olho`, `pet.dart:5932-5941`).
- **Lontra**: pulo em **arco** (12 px) com corpo em "C" (deformador: tronco
  verga 8°), cauda chicoteia (balanço × 2), patas da frente no peito.
- **Tracajá**: as quatro patas saem do chão 4 px e o pescoço estica ao máximo
  (`estica = 14`), cabeça balança ±6° (sem pulo alto: é pesado).

Os brilhos (`celebracao`) continuam, mas só **depois** do pouso (120 ms).
**Onde.** `pet.dart:2509` (festa), `deformador.dart` (verga), `_capivara`,
`_lontra`, `_tartaruga`; captura `novelinha_quadros_test.dart:46`.
**Aceite.** `festa-<esp>-0` × `radiante-0` alinhados: ≥ 15% dos pixels
diferentes (hoje 3,9–8,4%); numa filmagem de 1 s a 30 qps, a caixa da
silhueta muda de altura em ≥ 3 quadros consecutivos (há pulo), e a área
da silhueta no pouso é ≥ 97% da área em repouso (volume).
**Fontes.** [14] (squash/stretch, exagero), [6] (lontra "torce, vira, rola"),
[2] (capivara na água).

### R5 — Capivara com cara de capivara (alta)

**O que mudar.** Em `_capivara`:

1. Orelhas **10 × 9** em (±41, −27), giro ±0,55 rad, com a base **dentro** do
   contorno (hoje 16 × 14): passa de 17% para **≈ 11%** da largura da cabeça.
2. Focinho **rombudo**: a faixa clara vira um bloco `RRect 70 × 52` com cantos
   28 em baixo e 14 em cima, centro (0, 22), e a cabeça ganha **1,06×** de
   largura embaixo (`_bolha base 1,06`) para o focinho ser a parte mais funda.
   Focinheira = **duas narinas** `_narina` em (±9, 2) no **topo** do bloco,
   sem o botão de 26 × 15.
3. Olhos em (±30, −15), r 7,5 (mantém o olho grande do fofo).
4. Corpo **104 × 74** (mais largo que alto), patas da frente 24 × 14 em
   (±26, 54), e patas de trás insinuadas como dois ovais 30 × 12 em (±36, 58)
   atrás das da frente (patas da frente mais curtas [1]).
5. Pelo: 5 traços de 6–9 px no topo da cabeça e 4 na garupa, cor
   `lerp(pelo, #613529, 0,6)` a 60% de alfa, 1,4 px.
6. Bochecha fica (Bluey: círculo amigável), mas 12 × 7 e 3 px mais alta.

**Onde.** `pet.dart:2882-2988`; `_narina` (`:6048`). **Aceite.** Golden
`pet_capybara_contente.png`: (a) largura da orelha / largura da cabeça ≤ 0,11;
(b) a caixa do bloco do focinho ocupa ≥ 60% da altura da cabeça abaixo da
linha dos olhos; (c) IoU da silhueta capivara × lontra (método do laudo 06)
**≤ 0,70** (hoje 0,83); (d) relação largura/altura do corpo ≥ 1,3.
**Fontes.** [1][2][12][24].

### R6 — Lontra: garganta clara, bigodes visíveis, cauda de verdade (alta)

**O que mudar.** Em `_lontra`:

1. **Garganta**: bolha `claro` 44 × 40 centrada em (0, 22) na cabeça, unida à
   barriga do corpo (uma só mancha do queixo ao peito), cor
   `lerp(claro, #C9A991, 0,5)`; lábio superior/queixo em `#E1B79C` (a máscara
   atual 50 × 34 vira a parte de cima dessa mancha).
2. **Bigodes**: 5 por lado, 24–28 px, 1,3 px, cor `#E1B79C` a 0,9 de alfa,
   saindo do bloco do focinho em (±18, 8..16); seguem `respiro` como hoje.
3. **Cabeça** 82 × 56 (1,46 : 1) com `topo 0,92`; olhos em (±22, −14).
4. **Cauda**: base de **22 px** (33% do corpo) saindo de (12, 44), curva em S
   que passa **na frente** da pata direita e termina em (46, 64) com ponta de
   4 px; cor `sombraForte`; na água, passa para trás e a ponta sobe/desce
   ±12 px no compasso da remada (já ligado em `balanca`).
5. Corpo 62 × 92 (ligeiramente mais estreito; a lontra é "longa e baixa", e
   sentada fica uma pera alta — mantém).
6. Paleta: esfriar `pelagemLontra[0]` para `#5E4A40` e `[1]` para `#4A3A33`;
   manter `#9C7A5E` como "clara". Variantes persistidas ficam nos mesmos
   índices (sem migração).

**Onde.** `pet.dart:2994-3126`, `_bigodes` (`:6192`), `tokens.dart:145-152`.
**Aceite.** Golden: (a) na home a 280 px de largura, os bigodes têm contraste
≥ 3 : 1 com o pelo (medir luminância); (b) largura da base da cauda ≥ 0,30 da
largura do corpo e sem vão branco (componente conexo único); (c) existe uma
região de luminância ≥ 1,8× a do dorso cobrindo queixo + garganta + peito;
(d) IoU lontra × capivara ≤ 0,70.
**Fontes.** [3][4][5][6][24].

### R7 — Tracajá: pescoço que dobra de lado, casco baixo, patas traseiras (alta)

**O que mudar.** Em `_tartaruga` (a troca listra → manchas já foi decidida;
isto é a forma):

1. **Retração lateral**: `vida.pescoco < 0` passa a mover a cabeça em
   `x = lado · 16 · |pescoco|`, `y = +10 · |pescoco|` (desce até a borda) e
   gira −0,35 rad; o pescoço vira uma curva em "S" de 30 px de largura que
   acompanha. `lado` sorteado por episódio. O recolher em linha reta some.
   Tempo: 300 ms para dobrar, 1 s para voltar (06 §4.5).
2. **Casco** 118 × 70 (1,69 : 1), `topo 0,86`, com borda marginal de 6 px em
   `lerp(casco, #B4AC8F, 0,5)` e **quilha**: um traço central de 2 px do topo até
   30% da altura. Plastrão `#D9C27A` (amarelo), 72 × 30 em (0, 58).
3. **Cabeça** 70 × 52 com focinho em ponta (`_bolha base 0,8` e um triângulo
   suave de 14 px no queixo); olhos **r 6,5** em (±22, −8) (laterais); 1
   barbilhão (traço 4 px) sob o queixo. Pescoço na cor do `pelo`, não `claro`.
4. **Patas traseiras**: 2 `_pata` 22 × 16 em (±50, 62) **atrás** do casco; na
   água, remam com `rema` de sinal **oposto** à pata da frente do mesmo lado
   (frente-esquerda em fase com trás-direita) e ciclo de **2 por segundo**
   (`pose.ciclo` × 2) [10].
5. **Tronco ao sol**: nova intenção `aquecer` no motor, só entre 11h e 15h do
   relógio do mundo (`pinta_mundo` período "dia"): 4 patas esticadas para fora
   (`desloca ±8`), pescoço `estica = 12`, olhos fechados 60% do tempo, 5 s.

**Onde.** `pet.dart:3135-3288`; `motor_de_vida.dart` (nova intenção; `pescoco`
já existe); `pinta_mundo.dart` (hora do dia). **Aceite.** Golden com
`pescoco = −1`: o centroide da cabeça desloca ≥ 14 px no eixo x em relação a
`pescoco = 0` e fica ≥ 8 px abaixo; relação largura/altura do casco ≥ 1,6;
na folha `vida-tortoise`, patas traseiras visíveis em ≥ 90% dos quadros; na
captura de nado, a pata frente-esquerda e a trás-direita têm fase igual
(diferença de fase < 0,1 ciclo).
**Fontes.** [8][9][10][11][24].

### R8 — Nado por espécie (média)

**O que mudar.** `_pata(rema)` ganha `modoDeNado` por espécie:

- **Capivara** (`afunda`): linha d'água na altura **dos olhos − 3 px**; só
  orelhas, olhos e as duas narinas de fora; patas invisíveis; o corpo é uma
  elipse 110 × 20 rente à superfície (dorso); 1 bolha a cada 2 s [2].
- **Lontra**: patas da frente **paradas junto ao peito**; propulsão = ondulação
  do dorso (deformador: onda vertical de 4 px, 1,5 Hz, da cabeça à cauda) e
  cauda com amplitude 2× a de hoje; submersa (mergulho de pesca, 06), amplitude
  dobra [6][7].
- **Tracajá**: remada diagonal de R7, cabeça 11 px de fora (já existe).

**Onde.** `_pata` (`pet.dart:5853-5865`), `_capivara`/`_lontra`/`_tartaruga`,
`deformador.dart`. **Aceite.** Captura `nada-<esp>`: capivara com fração da
cabeça acima da linha d'água entre 25% e 35% (medir caixa); lontra com patas
da frente com deslocamento < 2 px entre quadros e ponta da cauda com amplitude
≥ 20 px; tracajá como em R7.
**Fontes.** [2][6][7][10].

### R9 — Cores a partir de foto, com sombra colorida (média)

**O que mudar.** Sem mexer nos índices persistidos (`check coat 0..8`), ajustar
os valores e **acrescentar** uma 7ª entrada "real" por espécie:

| Espécie | entrada nova | garganta/ventre | sombra (fria) |
|---|---|---|---|
| capivara | `#8A5344` | `#C9A27A` | `lerp(pelo, #3B2A3A, 0,35)` |
| lontra | `#584744` | `#C9A991` (garganta), lábio `#E1B79C` | `lerp(pelo, #2B2F3A, 0,35)` |
| tracajá | casco `#6E6A55`, pele `#5D5950` | plastrão `#D9C27A`, manchas `#F2C94C` | `lerp(pelo, #2F3A33, 0,35)` |

`_sombraDoQueixo` e `_tomDaAgua` passam a usar a sombra fria, não o pelo
escurecido. O estilo chapado pede saturação um pouco acima da foto (Bluey:
"errar para o mais colorido") — por isso os valores acima estão +8% de
saturação sobre o medido [I].
**Onde.** `tokens.dart:135-162`; `pet.dart` `_sombraDoQueixo`, `:6221`.
**Aceite.** ΔE (CIE76) entre a entrada nova e a mediana medida na foto de
referência ≤ 12; a sombra do queixo tem matiz (H em HSL) ≥ 15° diferente do
pelo; contraste manchas × cabeça do tracajá ≥ 4,5 : 1.
**Fontes.** [24][1][3][8][15].

### R10 — Olhos: manter grandes, acertar a posição por espécie (média)

**O que mudar.** Não reduzir os olhos (Borgi: 46% das fixações [13]; Blair:
"grandes e bem afastados" [12]). Mas a **posição** é da espécie: capivara e
lontra **altos** na cabeça (terço superior, [1][3]); tracajá **lateral**
(R7). Na fala, os olhos acompanham o "accent": `abre > 0,6` → olho 1,05·r e
sobrancelha sobe 1 px por 2 quadros [21][22].
**Onde.** `_olho` e as chamadas em `:2982`, `:3120`, `:3282`. **Aceite.**
Golden: centro do olho a ≤ 32% da altura da cabeça a partir do topo (capivara e
lontra); distância entre olhos ≥ 0,60 da largura da cabeça (tracajá).
**Fontes.** [12][13][1][3].

### R11 — Silhueta assimétrica no repouso (média)

**O que mudar.** Evitar os "twins" [14]: nas poses de repouso e nas 3
assinaturas (susto, festa, fala), uma orelha 0,1 rad diferente da outra, a
cauda da lontra sempre para um lado, o pescoço do tracajá com 3° de giro, a
cabeça da capivara com `_cabecaGiro` mínimo de 0,08.
**Onde.** `_posicionaCabeca` (`pet.dart:2743`), `_orelhaRedonda`. **Aceite.**
Espelhar o golden e diferenciar: ≥ 6% dos pixels diferentes entre o quadro e
o seu espelho (hoje a lontra parada é quase simétrica, tirando a cauda).
**Fontes.** [14]; laudo 24 (simetria denuncia o procedural).

### R12 — Andar da capivara com referência (baixa)

**O que mudar.** Usar a prancha 746 de Muybridge [23] como gabarito do ciclo
de 4 tempos do laudo 24 para a capivara: patas da frente curtas, dorso quase
reto, cabeça baixa. **Onde.** `motor_de_vida.dart` (gingado). **Aceite.**
Filmagem a 30 qps: cabeça sobe/desce ≤ 3 px por passo (anda "pesado"), 2,0–2,4
passos/s. **Fontes.** [23][1].

---

## 5. O que não fazer

- **Não** desenhar o "grito" por cima do quadro na novelinha (`b4.js:66`):
  toda boca vem do painter (R2). Qualquer sobreposição vira "duas bocas".
- **Não** trocar o desenho da boca por quadros discretos (6 PNGs de boca):
  a forma é paramétrica e contínua; a gradação é o que falta, não a troca.
- **Não** abrir a boca acima de 0,62·w nem mover a mandíbula de cima [12][22].
- **Não** animar todo fonema do TTS; nunca fecha-abre-fecha em 3 quadros;
  M/B/P seguram 2 quadros [21].
- **Não** copiar a lontra-marinha (boiar de costas com pedra no peito): já
  vetado no laudo 06; a Rio rola e nada de costas por 1 s, só.
- **Não** fazer o tracajá recolher a cabeça **para trás** (isso é cágado de
  outra família) nem esconder a cabeça na saudade (estresse, Warwick 2018,
  laudo 06); a dobra lateral é só susto e sono.
- **Não** dar ao tracajá nado de tartaruga marinha (batida síncrona das
  patas da frente) [10].
- **Não** desenhar *morrillo* na capivara (06) nem orelhas acima de 11% da
  cabeça (R5).
- **Não** usar contorno preto nem sombra neutra [15]; **não** pôr gradiente
  em todos (Hey Duggee: um só [16]); **não** somar textura além dos 5–9 traços
  de pelo da capivara (detalhe congestiona [16]).
- **Não** reduzir os olhos para "ficar mais real": a fofura mora neles [13].
- **Não** reabrir Rive nem trocar chaves de espécie (decisões da síntese).

---

## 6. Fontes (todas lidas em 2026-11-08)

1. San Diego Zoo Wildlife Alliance Library — *Capybara Fact Sheet: Physical
   Characteristics*. <https://ielc.libguides.com/sdzg/factsheets/capybaras/characteristics>
2. Animal Diversity Web — *Hydrochoerus hydrochaeris*.
   <https://animaldiversity.org/accounts/Hydrochoerus_hydrochaeris/>
3. Animal Diversity Web — *Lontra longicaudis*.
   <https://animaldiversity.org/accounts/Lontra_longicaudis/>
4. OtterJoy — *Appearance and Anatomy of the Neotropical Otter*.
   <https://otterjoy.com/otterinfo/lontra/longicaudis/longicaudis_anatomy.html>
5. Wikipedia — *Neotropical otter*. <https://en.wikipedia.org/wiki/Neotropical_otter>
6. Smithsonian's National Zoo — *North American river otter*.
   <https://nationalzoo.si.edu/animals/north-american-river-otter>
7. Thewissen, J. G. M. & Fish, F. E. (1997). *Locomotor evolution in the
   earliest cetaceans*. Paleobiology 23(4). PDF lido por `pdftotext`:
   <https://rcremote.wcupa.edu/sciences-mathematics/biology/fFish/documents/1997PB-Ambulocetus.pdf>
   (resume Fish 1994, *J. Mammalogy* 75:989-997, sobre o nado da lontra de rio).
8. Beardsley Zoo — *Yellow Spotted Amazon River Turtle (Podocnemis unifilis)*.
   <https://www.beardsleyzoo.org/yellow-spotted-amazon-river-turtle.html>
9. Wikipedia — *Yellow-spotted river turtle*.
   <https://en.wikipedia.org/wiki/Yellow-spotted_river_turtle>
10. Rivera, A. R. V., Rivera, G. & Blob, R. W. (2013). *Forelimb kinematics
    during swimming in the pig-nosed turtle… rowing versus flapping*. J. Exp.
    Biol. 216:668-680. <https://pmc.ncbi.nlm.nih.gov/articles/PMC3561774>
11. Oliveira, A. M. V. (2026). *Ecologia do tracajá (Podocnemis unifilis) em
    uma lagoa urbana impactada no município de Parintins, Amazonas*. TCC,
    UEA. <https://ri.uea.edu.br/handle/riuea/8616>
12. Blair, Preston (1947). *Advanced Animation* — prancha "The Cute
    Character" (texto OCR). <https://archive.org/details/advancedanimation>
13. Borgi, M. et al. (2014). *Baby schema in human and animal faces induces
    cuteness perception and gaze allocation in children*. Front. Psychol.
    5:411. <https://www.frontiersin.org/articles/10.3389/fpsyg.2014.00411/full>
14. Wikipedia — *Twelve basic principles of animation* (Thomas & Johnston,
    *The Illusion of Life*, 1981).
    <https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation>
15. It's Nice That — *How we built Bluey's world* (Catriona Drummond, Ludo
    Studio). <https://www.itsnicethat.com/features/how-we-built-bluey-s-world-cartoon-background-scenery-art-director-catriona-drummond-animation-090725>
16. Cartoon Brew — *Interview: 'Hey Duggee' creator Grant Orchard*.
    <https://www.cartoonbrew.com/?p=149069>
17. Rhubarb Lip Sync — README (formas A–H, X).
    <https://github.com/DanielSWolf/rhubarb-lip-sync>
18. Toon Boom Harmony 20 — *About Lip-sync*.
    <https://docs.toonboom.com/help/harmony-20/premium/sound/about-lip-sync.html>
19. Adobe — *Character Animator: lip sync mouth shapes*.
    <https://www.adobe.com/learn/adobe-character-animator/web/lip-sync-mouth-shapes>
20. Duolingo Blog — *How we built visemes for the World Characters*.
    <https://blog.duolingo.com/world-character-visemes>
21. Animation Apprentice (Alexander Williams) — *The secret of animating
    lipsync*. <https://animationapprentice.blogspot.com/2020/10/the-secret-of-animating-lipsync.html>
22. The Rookies — *A brief journey into lipsync for anthropomorphic
    characters*. <https://www.therookies.co/blog/breakdowns/tips-for-students-a-brief-journey-into-lipsync-for-anthropomorphic-characters>
23. Wikimedia Commons — Muybridge, *Animal Locomotion* (1887), prancha 746
    "Capybara walking", 9 quadros.
    <https://commons.wikimedia.org/wiki/File:Capybara_walking_(rbm-QP301M8-1887-746).jpg>
24. Fotos medidas (Wikimedia Commons, 960 px): `Capybaracropped.jpg`;
    `Lontra_longicaudis_4.jpeg`; `Podocnemis_unifilis_in_Zoo_Krefeld_(2).JPG`
    (capas dos artigos da Wikipédia em inglês das três espécies).

**Vistos só no trecho do resultado de busca (não lidos; não sustentam
nenhuma recomendação):** levantamento *Zoologia* 2011 com 14.138 tracajás
assoalhando em troncos e pedras no Peru; o conjunto de 10 bocas Preston
Blair/Papagayo (fóruns Blender/Lost Marble); Pocoyo (fundo branco por
decisão de foco, sem fonte primária); Puffin Rock (não achei o método de
desenho). O PDF de *Advanced Animation* no Animation Resources e o Scribd de
*Cartoon Animation* não abriram.

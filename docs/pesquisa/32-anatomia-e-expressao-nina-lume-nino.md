# Laudo 32 — Anatomia, apelo e expressão: coruja-buraqueira (Nina), axolote (Lume) e pinguim-de-magalhães (Nino)

Pesquisa para desenho vetorial chapado infantil. Novembro de 2026. Avança
sobre o laudo 07 (biologia, estágios, itens, sons) e sobre o 31 (que fixou o
método de medir e a gradação da boca para capivara, lontra e tracajá): aqui
o assunto é **a forma e a cara das três espécies de "bico e guelra"** —
o que faz ler a espécie, como o **bico abre** (bico não é boca), como a
coruja **pisca, gira e inclina** a cabeça, como o axolote **sorri** e como o
pinguim **ginga** — e o que no desenho atual está errado ou fraco, com fonte.

**Legenda** (a mesma dos laudos 06 e 31)

- **[F]** fato com fonte (número entre colchetes remete à seção "Fontes";
  `[31-n]` e `[07-x]` remetem às fontes dos laudos 31 e 07);
- **[O]** observação do app, com `arquivo:linha` ou imagem que eu abri/medi;
- **[I]** inferência minha, sem fonte que a prove.

**O que eu medi (reproduzível).** Abri as folhas de quadros
`novelinha-ep1/assets/img/app/bicho-owl.webp` (8 × 5 quadros de 543 × 436)
e `bicho-axolotl.webp` (8 × 5 de 544 × 538), geradas por
`gera/app_capturas/novelinha_quadros_test.dart` (ordem: 4 humores × [6 níveis
de boca + 1 piscada] = quadros 0–27; susto 28–33; festa 34–39). Não existe
folha do pinguim: o Nino foi lido só no código. Recortei quadros com
Python/PIL e comparei pixel a pixel (diferença RGBA > 60, alinhando pela
caixa da silhueta). Medi cores em quatro fotos do Wikimedia Commons (capas
dos artigos da Wikipédia; mediana-corte em 4 cores por região) [33]. Todas
as fontes foram lidas em **2026-11-08**.

---

## 0. Resumo em 12 linhas

1. [O] **O bico não fala.** Na Nina, "falar" é a ponta do triângulo descer
   **3 unidades** (`pet.dart:3625`): entre boca 0 e boca 1 mudam **156 px**
   de uma figura de ~70 mil (0,2%). No Nino é um segundo triângulo escuro que
   aparece quando `boca > 0,3` (`pet.dart:3962-3974`): **booleano**. Nenhum
   dos dois tem mandíbula de baixo — e é a de baixo que abre [3].
2. [O] **O queixo branco da Nina lê como boca.** É um arco de 28 × 10
   convexo para baixo, logo sob o bico (`pet.dart:3604-3611`): na folha
   (imagem ampliada) parece um **sorriso branco debaixo de um nariz**. Na
   buraqueira real a mancha é uma **faixa horizontal** na garganta, fechada
   por um **colar escuro** [8][9].
3. [O] **A Nina pisca errado e olha errado.** A piscada é `scale(1, 1−f)`
   centrado no olho (`pet.dart:5954-5957`): fecha simétrico de cima e de
   baixo. [F] Coruja pisca **com a pálpebra de cima** (24 de 28 espécies
   medidas) e dorme com a de baixo [1][2]. E a íris desliza 3 px com o olhar
   (`:2695-2701`): [F] o olho da coruja é um **tubo fixo** no crânio — ela
   move a **cabeça**, não o olho [2][6][7].
4. [O] **A fala do Lume é a mesma boca binária do laudo 31**: nv0 = nv1,
   nv2 = nv3 = nv4 = nv5 (0 px de diferença); a boca aberta é uma meia-elipse
   de 17,6 × 9 numa cabeça de 86. [F] O axolote tem uma boca **larga** que
   "sorri" por anatomia [12]; medi na foto: a linha da boca cobre ≈ 0,85 da
   largura da cabeça [33]. No app, o sorriso tem 17,6 (**20%**).
5. [O] **As guelras somem na cor**: `lerp(pelo, acento, 0,34)` = #E7938B sobre
   pelo #E39BA8, contraste **1,06 : 1**. [F] Na foto do leucístico, a guelra
   (#5E3529–#75573F) contrasta **4,1–6,4 : 1** com o corpo (#D2CCAF) [33]; é
   "vermelha" porque é **sangue** nos filamentos [10][12].
6. [O] **Susto e festa não existem nas duas folhas**: festa-0 ≡ radiante-0
   (1 px na coruja, 10 px no axolote); susto = a figura inteira reescalada
   (coruja −9% × +8%; axolote +7% de altura **sem** estreitar), rosto igual.
7. [F] **Buraqueira**: pernas longas (tarso 43 mm num bicho de 19–25 cm
   [8]) para **correr atrás da presa** [5][9]; olhos amarelos, sobrancelha
   branca larga, cabeça redonda **sem tufos**, disco achatado [5][8][9];
   bico cinza-claro a amarelado [8][9]; gira a cabeça **até 270°** [2][7];
   balança a cabeça (paralaxe) para medir distância, mais nos jovens [6][7];
   relaxada = plumagem **fofa e solta**; alarmada = **magra e alta**, penas
   coladas [4].
8. [F] **Axolote**: cabeça larga, olhos **sem pálpebra**, 3 pares de hastes
   branquiais com filamentos, barbatana da nuca à cloaca, patas finas [10];
   nada como **enguia** (onda que cresce da cabeça à ponta da cauda, velocidade
   regulada pela **frequência**, eficiência máxima acima de 2,5 comprimentos/s)
   [14]; sobe para **engolir ar** e volta ao fundo [13]; cor de cativeiro:
   **rosa ou branco** [12]; selvagem: pardo-oliva com pintas douradas [10].
9. [F] **Pinguim-de-magalhães**: cabeça preta com **faixa branca** do olho à
   garganta, **duas faixas** pretas (a de baixo em ferradura), bico **preto**,
   olho **castanho-escuro**, lores/pálpebra/anel ocular **rosa**, pés
   enegrecidos (malhados no jovem) [16][17]; anda **ereto, passos curtos,
   nadadeiras abertas para equilibrar** [17]; o gingado é um **pêndulo
   lateral** que recupera até 80% da energia (velocidade lateral oscila 3× a
   longitudinal) [19]; nada a ~2 m/s batendo as nadadeiras a **2,2–2,6 Hz**
   (bicho de 4–5 kg) [20]; zurra como jumento [18].
10. [F] **Bico em desenho**: "um par de pirâmides de três lados", de cima e
    de baixo; a forma "**u**" sai da pirâmide e trata o bico "como lábios
    moles" [24]; bico "não tem lábios", é "duas massas de queratina batendo",
    por isso **menos formas e mais corpo** [25]; o Pato do Pocoyo **dobra** o
    bico quando desapontado e **gira** quando perde a paciência [28]; o Pingu
    **vira o bico num megafone** no "noot noot" [29].
11. [F] **Sincronismo** (Williams): "a boca abre nas vogais e fecha em B, M,
    P, F, T, V"; "**não abra duas vezes**" (FOR-TUNE = 2 posições); "**pop** na
    vogal, sem intervalos; amortece **depois** do acento"; a primeira vogal
    bate mais forte; acento visual **2 quadros antes** do som; ≥ 2 quadros
    para ler uma boca fechada; "o fundo do rosto estica e comprime" [22].
12. Recomendações: **R1 bico de duas mandíbulas com gradação** (Nina e Nino),
    **R2 piscada de cima e olho fixo** (Nina), **R3 garganta e colar** no lugar
    do "sorriso branco", **R4 pernas e postura** (magra/fofa), **R5 guelras com
    contraste e tique** (Lume), **R6 boca larga do axolote**, **R7 Lume no
    fundo**, **R8 Nino em pino, cores medidas**, **R9 zurro/exibição**,
    **R10 gingado**, **R11 nado sincrônico**, **R12 susto e festa por espécie**.

---

## 1. O que o app faz hoje

### 1.1 Peças comuns (`pet.dart`, `motor_de_vida.dart`)

| Peça | O que é | Onde |
|---|---|---|
| Olho (coruja) | Esclera **amarela** #F2C94C, íris `Cores.tinta` com 0,42r (0,50r triste), 2 brilhos; pálpebra neutra/triste mais fina e clara (`lerp(pelo, superficie, 0,35)`), subindo 0,30r | `_olho`, `pet.dart:5959-5977`, `6016-6024` |
| Olho (axolote, pinguim) | Esclera `superficie` (quase branca), íris 0,50–0,58r, brilhos | `pet.dart:5960-5988` |
| Piscar | `canvas.scale(1, (1−f))` **centrado no olho** → fecha de cima **e** de baixo ao mesmo tempo; fechado (f > 0,94) = arco de traço 2,2 | `pet.dart:5942-5957` |
| Olhar | A íris desliza `olhar · 3 px` (+2,2 no pasto), **em todas as espécies, a coruja inclusive** | `_olhoDesvio`, `pet.dart:2695-2701` |
| Virada do rosto | O rosto desliza `virada·8,5 px` e encurta 14% na horizontal | `_rosto`, `_encurtaRosto`, `pet.dart:2729-2736` |
| Inclinação por humor | radiante −0,05 rad, sono 0,06, saudade 0,12 | `_inclinaDoHumor`, `pet.dart:2858-2864` |
| Abertura da boca/bico | `SaidaDaVida.boca` 0..1 contínuo | `motor_de_vida.dart:183-192` |
| Boca (`_boca`) | Booleano `aberta` (bocejo > 0,3 ∨ carinho > 0,4 ∨ mastiga > 0,3 ∨ boca > 0,3); aberta = meia-elipse 0,8·w × **9 fixo**; fechada = 5 arcos por humor | `pet.dart:6083-6158` (já descrito no laudo 31 §1.1) |
| Susto | `achata` negativo: corpo inteiro estica | `pet.dart:2497-2498` (laudo 31) |
| Festa | tremor senoidal no corpo + humor radiante + brilhos | `pet.dart:2509` |

### 1.2 Coruja — `_coruja` (`pet.dart:3424-3635`)

- Pernas: 2 linhas de 4,2 px em #CDBB9C de y 30 a 52 (**22 unidades**), 3
  dedos em cúbicas até y 59; recolhem 9 no voo (`3437-3461`).
- Asas de voo (`_asasDeVoo`, `3311-3420`): ciclo de batida com descida de
  força e subida dobrada — já bom (laudo 24).
- Corpo: bolha **90 × 84** em (0, −6) (`3466-3471`); barriga 60 × 60 com 3
  fileiras de arcos 17 × 12 como "penas" (`3483-3496`); asas dobradas como
  duas cúbicas em `sombraForte` com 3 riscos (`3502-3527`).
- Cabeça: bolha **84 × 68** deslocada −28, giro `_cabecaGiro · 0,8`, pescoço 32
  (`3533-3545`); 7 pintas r 1,9 em `claro` (`3550-3561`); **dois discos**
  ovais 42 × 44 em (±19, 3) (`3570-3577`).
- Sobrancelhas brancas: duas pás de (±4, −11) a (±34, −10), a ponta de dentro
  sobe 7 na saudade e 2,8 no sono (`3586-3603`).
- **Queixo branco**: arco (−14, 20)→(14, 20) com controle em (0, 30): **28 de
  largura, 10 de altura, convexo para baixo** (`3604-3611`).
- Olhos: r **9** em (±19, 2), `coruja: true`, sem sobrancelha de tristeza
  (`3614-3615`).
- Bico: triângulo (−6, 7), (6, 7), (0, 19 + max(mastiga, boca) · 3), cor
  #D9C79A (`3618-3628`): **12 de largura, 12 a 15 de altura**; nenhuma
  mandíbula separada, nenhum interior.
- Bochecha em (±34, 17) quando feliz (`3631`).

### 1.3 Axolote — `_axolote` (`pet.dart:3641-3777`)

- Cauda: duas cúbicas de (16, 30) a (82 + varre, 22) com barbatana clara
  (`3654-3666`); varre = `cauda · 6`.
- Patas 16 × 12 em (±20, 49) que **remam** (`3668-3687`).
- Corpo 82 × 71 em (0, 20) + barriga 56 × 55 (`3689-3704`).
- Cabeça: translate −28, giro 0,9, pescoço 36 (`3708-3712`); bolha **86 × 73**
  (`3759-3765`).
- Guelras (`3718-3757`): 3 ramos por lado, haste 4,2 px na cor
  `lerp(pelo, acento, 0,34)` (pelagem 0: **#E7938B** sobre pelo #E39BA8),
  filamentos 2,6 px em `lerp(guelra, superficie, 0,18)`, **3/3/4/6/7** por
  estágio, 7,5 de comprimento; `abana` = `cauda · 0,8` (ou `pernas · 1,2`
  nadando).
- Boca: `_boca` em (0, 14), **w = 22** (`3768`) → contente = arco 17,6 × 11;
  aberta = meia-elipse 17,6 × 9 (`6096-6108`).
- Bochechas (±30, 6); olhos r 7,5 em (±20, −6) com **esclera branca e piscada**
  como os mamíferos (`3769-3772`).

### 1.4 Pinguim — `_pinguim` (`pet.dart:3787-3980`)

- Pés 20 × 13 em `lerp(sombraForte, tinta, 0,35)` com 3 manchas #D9A5A3; na
  água viram leme (`3797-3817`) — certo (laudo 07).
- Corpo **90 × 91** em (0, 12) (`3819-3823`); barriga 60 × 82 quase branca
  (`3828-3834`); 2 faixas de 4,5 px só a partir do adulto (`3838-3853`).
- Nadadeiras: cúbicas coladas ao corpo; na água **alternam** (`alterna =
  lado`, `3862-3891`): "uma subindo enquanto a outra desce".
- Cabeça: bolha **72 × 60** deslocada −34 (`3895-3904`): cabeça e corpo são
  **duas bolas com pescoço** (o perfil de largura tem um vale entre 72 e 90).
- Faixa branca em C (`3915-3926`); pele rosa oval 7 × 5 (10 × 7 no pleno) em
  (±8, 2) (`3930-3937`); olhos r 7 em (±15, −3) com **esclera branca**
  (`3942-3943`).
- Bico: triângulo (−6, 5), (6, 5), (0, 17) em `lerp(sombraForte, tinta, 0,55)`
  + risco claro em y 12 (`3947-3961`); "aberto" = **segundo triângulo**
  (−4,5, 11), (4,5, 11), (0, 18,5) em `lerp(terracotaDaArte, tinta, 0,35)`
  quando `boca > 0,3` (`3962-3974`). Booleano; nada se move.

### 1.5 Medidas das folhas atuais

| Medida | Coruja (quadro 543 × 436) | Axolote (544 × 538) |
|---|---|---|
| Silhueta contente-0 | 270 × 370 (w/h 0,73) | 484 × 470 (inclui guelras e cauda) |
| Cabeça / corpo (largura) | 252 / 270 = **0,93** | — |
| Olho | ⌀ 52 px = **21%** da cabeça; pupila ⌀ 22 (42%); centros a 114 px (45%) | — |
| Bico | 34 × 32 px = **13%** da largura da cabeça; em boca = 1: 34 × 43 (+11 px na ponta) | — |
| Pernas visíveis | 47 linhas com largura < 60 px = **12,7%** da altura (+ 30 px de pés) | — |
| fala nv0 → nv1 / nv0 → nv2 / nv0 → nv5 (px que mudam) | 26 / 50 / **156** (0,2% da figura) | **0** / 360 / 360 (0,4%, numa caixa de 126 × 30; nv2 ≡ nv5) |
| pisca × contente | 11,3% | 3,5% |
| susto-0 × contente-0 | caixa 270 × 370 → **246 × 401**; olhos 166 × 52 → 152 × 56 (rosto reescala junto) | 484 × 470 → **484 × 504** (+7% de altura, largura igual) |
| festa-0 × radiante-0 | **1 px** | **10 px** |

[O] Conclusão das medidas: nas duas espécies o "falar" é invisível (≤ 0,4%
dos pixels), a festa **não existe** no quadro e o susto é o mesmo adesivo
esticado do laudo 31 — no axolote nem o volume se preserva.

---

## 2. O que as fontes dizem

### 2.1 Bico: anatomia e como o desenho faz bico falar

- [F] Owl Pages, "Owl Beak or Bill" [3]: "todas as corujas têm um bico
  curto, curvo, virado para baixo e **em gancho** na ponta"; "o bico é curvo
  para baixo **para deixar o campo de visão livre**"; "**a mandíbula de baixo é
  articulada e faz a maior parte do trabalho**"; a de cima tem "uma faixa
  estreita de tecido flexível que funciona como dobradiça, deixando o bico
  **girar um pouco para cima**" — "possivelmente comunicação visual"; as bordas
  "se sobrepõem como tesoura"; narinas na base, na cera; corujas "ofegam"
  pelo bico entreaberto (*gular fluttering*) para esfriar.
- [F] Dermot O'Connor, *2D Animation: Tips and Tricks*, "Bird beaks" [24]: "um
  bico pode ser pensado como **um par de pirâmides de três lados**, uma forma
  muito simples" — "a metade de cima em verde, a de baixo em azul"; "podemos
  desenhar formas que **saem** disso quando preciso": "primeiro, a forma
  **ooo**, que trata o bico duro como lábios moles" (para assobiar).
- [F] Gabriel Hastings, *Acting for Animation: Lip Sync* (gaivota) [25]:
  "bicos **não têm lábios** e são essencialmente dois blocos de queratina
  batendo um no outro quando o pássaro 'fala'"; "você fica preso num ponto e
  tem de usar poses mais generalizadas"; de lado "parece alguém falando pelo
  canto da boca"; o bico "não envolve as palavras de um jeito satisfatório";
  solução: "fazer o personagem **atuar mais com o corpo**" (Don Bluth); lição:
  "**animei demais** o lip sync… menos teria sido mais"; "eu estava focando
  em fazer a boca sincronizar, não em fazer o personagem atuar".
- [F] Pocoyo (Wikipédia) [28]: o Pato "**dobra o bico num ângulo** quando
  desapontado ou chocado" e "perde a paciência com o **bico girando
  rapidamente**"; o bico é o órgão de expressão de um personagem sem boca.
- [F] Pingu (Wikipédia) [29]: o "noot noot" vem "acompanhado de **virar o bico
  numa forma de megafone**"; a fala é um grammelot inventado ("Penguinese").
- [F] Preston Blair, *Advanced Animation*, prancha da coruja [23]: "esboços
  de uma **coruja** para mostrar como a **asa** de um pássaro pode ser tratada:
  pode ser reta ou, em outros momentos, assumir **todas as características de
  uma mão, com as penas como dedos**".
- [F] Puffin Rock (Cartoon Saloon, Lorraine Lordan) [30]: "abordagem **muito
  naturalista**" — os bichos não são desenhados nem movidos como gente;
  "**nenhum dos nossos personagens tem mãos**", o que "cria desafios de design";
  "nunca deixamos você em perigo por muito tempo, porque o público é novo".
- [F] Duolingo, "Reshaping Duo" [26]: "se a forma geral não é atraente, os
  detalhes dentro dela não conseguem complementá-la" — quase todo o trabalho
  foi na **silhueta**; só no fim "adicionamos movimento e deixamos ele escolher
  o melhor ângulo, **um leve três-quartos**". Visemas [27]: "cada personagem
  precisou do seu próprio conjunto de formas por visema, seguindo sua
  personalidade"; "o mais crítico foi garantir que os visemas parecessem
  **críveis quando animados**"; "estados separados só para a boca", rodando
  junto com os do corpo.
- [F] Richard Williams, *The Animator's Survival Kit* (pp. 293, 304–307) [22]:
  "todas as nossas bocas **abrem nas vogais** A, E, I, O, U e **fecham nas
  consoantes** B, M, P, F, T, V"; "para ler essas posições precisamos de **pelo
  menos dois quadros**"; "para diálogo nítido, **pop** na vogal — sem
  intermediários; **não amorteça entrando**; amortece **de volta, depois do
  acento**: bate forte, depois suaviza"; "bata a **primeira vogal** mais forte
  que a segunda"; "não ease na vogal a partir do W com vários desenhos — fica
  mole"; "e não esqueça de **distender o rosto — esticar**: um defeito comum é
  o **fundo do rosto** não esticar e comprimir o bastante"; "a chave do lip
  sync é a **sensação da palavra**, não as letras"; "selecione o importante e
  evite **bater a boca** animando cada coisinha"; "FOR-TUNE: **não abra duas
  vezes**; use 2 posições"; "frasear: a gente **borra** de uma forma de palavra
  para outra, como na música"; "acento visual **2 quadros antes** do som";
  "você precisa de **pelo menos 6 quadros** para registrar um acento"; "acento
  duro **recua, quica de volta**; acento suave continua".
- [O] O que isso dá para um bico: a única parte móvel é a **mandíbula de
  baixo** (cunha), a de cima pode "girar um pouco para cima" no grito; as
  formas de vogal cabem em **4**: fechado, entreaberto (cunha curta), aberto
  (cunha + interior escuro + língua), **"u"** (as duas metades se projetam e
  afinam, o único momento em que o bico "vira lábio"); e o acento vai para o
  **corpo** (cabeça, peito, asas) [24][25][22] [I na síntese].

### 2.2 Coruja-buraqueira (*Athene cunicularia*)

- [F] Forma [5][8][9]: 19–25 cm, 150 g, envergadura 50–60 cm; "**pernas
  longas**", "fica de pé, alta sobre as pernas, **tarsos levemente
  emplumados**", tarso **43,4 mm** [8]; "cabeça redonda", **sem tufos**, "disco
  facial achatado" [9]; "olhos **amarelo-vivos**" [5]; "**sobrancelha branca
  larga**", "sobrancelhas brancas muito marcadas, testa parda riscada de pontos
  brancos" [8]; "manchas brancas no queixo" que ela **expande e exibe** ao
  balançar a cabeça quando agitada [9]; "garganta branca; abaixo dos discos
  um **colar preto** separa a garganta do peito e sobe até os olhos" [8];
  "bico **cinza-claro, às vezes amarelado**, com cera cinza" [8]; "bico amarelo-
  escuro ou cinza conforme a subespécie" [9]; dorso "pardo-acinzentado,
  fortemente manchado de branco"; peito "pardo com manchas brancas", barriga
  "branca com barras pardas horizontais"; cauda **curta**, "mostra pouco da
  cauda" [8]; jovem: menos pintas, barriga sem barras [5][8].
- [F] Pernas e caça [5][9]: "prefere caçar a pé, **andando, pulando ou
  correndo** atrás da presa"; "evoluiu pernas mais longas que outras corujas,
  o que a deixa **arrancar em corrida**… não muito diferente do papa-léguas"
  [9]; "crepuscular, mas caça a qualquer hora" [5]; ativa de dia, evitando
  o calor do meio-dia [9].
- [F] Olho e piscar [1][2]: "o olho é um **tubo alongado**, não uma bola",
  "preso por anéis escleróticos: a coruja **não move os olhos**, só olha para a
  frente"; "gira a cabeça **até 270°**"; campo de 110°, 70° binocular; "**três
  pálpebras**: a de cima fecha **quando pisca**, a de baixo **quando dorme**, e
  a membrana nictitante fecha em diagonal, de dentro para fora" [2]. Morris &
  Parsons (2023, *Animals*) [1]: "corujas e bacuraus **piscam com a pálpebra
  de cima**" (24 de 28 espécies de Strigiformes); piscadas "rápidas e breves",
  "raramente mais de um ou dois segundos"; espécies noturnas piscam **menos**;
  no corujão (Blount) as piscadas eram "**muitas vezes unilaterais**"; na
  sonolência as duas pálpebras fecham juntas ("sinérgico").
- [F] Cabeça que balança e inclina [6][7][4]: "a coruja não consegue mover os
  olhos nas órbitas, então move **a cabeça inteira, de modo um tanto
  exagerado**"; o balanço "para cima e para baixo, para os lados e **virando a
  cabeça completamente de lado**" cria **paralaxe de movimento** para medir
  distância e localizar som; "**muito mais exagerado nos jovens**" [6]; "depois
  de alguns balanços, raramente erra a presa" [7]; "muitas espécies balançam e
  serpenteiam a cabeça como se curiosas — é para melhorar a noção
  tridimensional do que veem" [4].
- [F] Linguagem corporal [4]: "**relaxada, a plumagem é solta e fofa**"; "se
  alarmada, fica **magra, penas coladas ao corpo**" (tufos de pé, onde há);
  ameaça: "penas eriçadas para parecer maior, cabeça baixa, asas abertas
  apontando para baixo", estalos de língua; corujinhas (*Athene noctua*)
  "**balançam o corpo** para cima e para baixo quando alertas" (gênero da
  buraqueira).
- [F] Inclinar a cabeça é lido como fofo [32]: participantes pedidos a deixar
  fotos de filhotes "as mais fofas possíveis" "**consistentemente** colocaram a
  cabeça inclinada" (White & Varakin 2017); "filhotes **e** cães adultos foram
  julgados mais fofos **inclinando a cabeça**" (Amry et al. 2018).
- [O] Cor medida (foto em luz difusa, com céu azul contaminando as bordas)
  [33]: coroa **#847262** / #9E8F7E, pintas #CAB9A9, sombra #493A2F; disco
  #918476 / #716358; sobrancelha+queixo **#DBCCBB**; peito #877755 / #908264;
  dorso #71665C / #473D37; bico **#86826B** / #989377 (cinza-oliva); íris
  **#9D9058** (amarelo-oliva na sombra) com pupila #0E070C. A paleta do app
  (`tokens.dart:165-172`: #9C7A5E…#C2A585) é **mais quente e mais clara** que o
  pardo-acinzentado medido; o bico #D9C79A é creme, o real é cinza-oliva.

### 2.3 Axolote (*Ambystoma mexicanum*)

- [F] Forma [10][11][12]: "cabeça **larga** e olhos **sem pálpebra**"; "três
  pares de hastes branquiais externas (rami) nascem atrás da cabeça", "cada
  haste forrada de filamentos (fímbrias)"; "barbatana caudal de **atrás da
  cabeça até a cloaca**"; "membros pouco desenvolvidos, dedos longos e finos";
  "dentes vestigiais quase invisíveis"; 23 cm é o comum, > 30 cm é raro [10];
  "cabeça grande com olhos **bem separados**", guelras "proeminentes, em ramos",
  "filamentos plumosos", cauda "bem desenvolvida, **de enguia**", cabeça 40–46
  mm, cauda 97–120 mm [11]; "guelras plumosas brotando da cabeça **como uma
  juba**"; "**sorriso permanente de Mona Lisa**"; selvagem "cinza-pardo";
  cativeiro "**rosa ou branco**", "corpo branco e guelras rosa" [12].
- [F] Cores [10]: selvagem "**pardo ou canela com pintas douradas e fundo
  oliva**"; leucístico "corpo rosa-pálido, olhos **pretos**"; xântico cinza;
  albino "rosa-pálido ou branco, olhos vermelhos"; melanístico "preto ou
  azul-escuro".
- [F] Movimento [13][14]: "sobem à superfície de vez em quando, dão um **gole
  rápido de ar** e **descem logo ao fundo**" [13]; D'Août, Aerts & De Vree
  [14]: "modo de nado **ondulatório, anguiliforme** (de enguia)"; "a velocidade
  é **regulada pela frequência**, o comprimento de onda é constante"; "a
  amplitude da onda é **mínima logo atrás da cabeça** e cresce até o **máximo
  na ponta da cauda**"; eficiência "máxima em alta velocidade (> 2,5
  comprimentos de corpo/s)", 0,67; passada 0,38 comprimentos por ciclo. (O
  adulto mais **anda** no fundo do que nada [07-SDZG-comp].)
- [F] Minecraft [15]: cinco cores "rosa (leucístico, 'Lucy'), pardo, dourado,
  ciano e azul"; animações "andando em terra", "nadando", "parado no fundo";
  "fingir de morto: cai no chão por 200 ticks (10 s)". Referência de desenho
  infantil de massa: o bicho lê pela **cabeça larga + guelras + cauda**, com
  olhos minúsculos.
- [O] Cor medida [33]: leucístico (foto cremosa, balanço de branco quente):
  corpo **#D2CCAF** / #DAD4BB; guelras **#5E3529 / #75573F / #92725F**;
  olhos #1E170D com anel #A9AB96. Selvagem: dorso #2F431E / #475A36 / #767E54;
  cabeça #84864E; guelras #1C220E; anel do olho #8C9677. Contraste guelra ×
  corpo: **6,4 : 1** (leucístico) e **4,3 : 1** (selvagem) — contra **1,06 : 1**
  no app. A linha da boca, na foto do leucístico, vai de debaixo de um olho
  até depois do outro: ≈ **0,85 da largura da cabeça** (a olho, ±0,05).

### 2.4 Pinguim-de-magalhães (*Spheniscus magellanicus*)

- [F] Padrão [16][17][18]: "dorso preto, ventre branco; **duas faixas pretas**
  entre a cabeça e o peito, a de baixo em **ferradura invertida**"; "cabeça
  preta com **borda branca larga** que sai de trás do olho e se junta na
  garganta"; "adulto reprodutor com **mancha rosa no olho**"; jovem "cinza-
  azulado, peito cinza-azulado mais claro"; pés "malhados no jovem, **todos
  pretos por volta dos 10 anos**" [16]; "o **bico forte é preto**"; "lores,
  pálpebra superior e anel ocular **rosa**"; "olhos **castanho-escuros**";
  "pernas e pés **enegrecidos**"; 68–76 cm, 4,6–4,9 kg [17]; "áreas carnosas
  sem pena no rosto; uma ou duas faixas pretas no peito" (gênero) [18].
- [F] Andar [17][19]: "anda **ereto, com passos curtos** por causa das pernas
  curtas, **mantendo as nadadeiras abertas para equilibrar**" [17]; Griffin &
  Kram (Nature, 2000) [19]: "as flutuações de velocidade **lateral** foram
  quase **três vezes** as longitudinais"; a ~0,5 m/s "a energia cinética lateral
  respondeu por ~30% das flutuações"; "recuperaram **até 80%** da energia
  mecânica" como pêndulo invertido — "o gingado **conserva** energia; andar é
  caro porque as **pernas curtas** exigem força rápida".
- [F] Tobogã [21] (fonte fraca, vídeo de rei-pinguim na areia das Malvinas):
  "na **areia** os pinguins afundam e não avançam rápido; decidiram que é mais
  rápido **deslizar**". Para o magalhães continua **sem fonte** (laudo 07); no
  Nino o tobogã é estilização [I].
- [F] Nado [20][17]: Sato et al. 2010 [20]: cruzeiro **1,8–2,3 m/s** em todas
  as espécies; frequência dominante de batida **2,18 Hz (gentoo, 5,5 kg),
  2,33 (adélia, 4,7 kg), 2,56 (barbicha, 4,0 kg)**, 3,5 Hz no pinguim-azul de
  1,1 kg; expoente −0,29 com a massa; empuxo "para a frente e para baixo"
  ao longo do ciclo; "**planam** até a superfície com a flutuabilidade" (o
  magalhães, 4,6–4,9 kg, cai na faixa 2,2–2,4 Hz [I]); "nadadeiras como
  remos, **20–25 km/h**"; mergulha < 50 m, até 90–100 m [17].
- [F] Voz e exibição [17][18]: "zurro **como jumento** quando procura par"
  [18]; "**estica o pescoço, aponta o bico para cima e abre as nadadeiras**
  enquanto zurra", "pode repetir por uma hora ou mais"; a colônia "responde
  até virar um clamor" [17].
- [O] Cor medida (foto em terra, luz difusa) [33]: cabeça **#2C3342** /
  #4F5768; faixa branca #FCFEFE; dorso **#293342** / #5A595D; nadadeira
  #1B2433 / #333D4C; ventre #D3DAE4 / #B4BBC4 (sombra); faixa do peito
  **#1E2635**; bico #3F4149 / #747982 / #9E9FA4 (faixa clara); olho #1C1319;
  pés #786B5C / #8E8170 (sujos de terra). O preto real é um **ardósia
  azul-escuro** (#1E2635–#293342), não #000; a paleta do app (`tokens.dart:
  185-192`: #4E6E7E…#7C9AA8) é **2 a 3 tons mais clara** que o medido.

### 2.5 Fofura e expressão sem boca de mamífero

- [F] Blair [31-12]: "nariz e boca **sempre pequenos**", "testa alta", "olhos
  grandes e **baixos**", "sem pescoço". Borgi [31-13]: olhos recebem 46% das
  fixações; em bichos, **menos atenção à boca** do que em humanos → a boca (ou
  o bico) pode ser pequena sem perder leitura.
- [F] Inclinar a cabeça = mais fofo [32] (§2.2). Silhueta primeiro, detalhe
  depois [26]; naturalismo sem mãos [30]; o bico como órgão de emoção (dobra,
  gira, vira megafone) [28][29].

---

## 3. Avaliação do desenho atual, traço a traço

### 3.1 O que vale para os três

| # | Observação [O] | Por que é fraco [F] | Onde |
|---|---|---|---|
| G1 | Bico: um triângulo (Nina: ponta desce 3; Nino: 2º triângulo booleano). Sem mandíbula de baixo, sem interior, sem forma "u". | A mandíbula de baixo "faz a maior parte do trabalho" [3]; bico = duas pirâmides, só a forma "u" sai delas [24]; "não abra duas vezes", "pop na vogal", "fundo do rosto estica" [22]. | `pet.dart:3618-3628`, `3947-3974` |
| G2 | Lume: boca binária 17,6 × 9 (laudo 31 G1/G2). | idem laudo 31. | `_boca` |
| G3 | festa-0 ≡ radiante-0 (1 e 10 px). | Exagero e *staging* [31-14]; o acento vai para o corpo [25]. | `pet.dart:2509` |
| G4 | susto = reescala do todo; no axolote só altura. | *Squash & stretch* preserva volume [31-14]; coruja alarmada fica **magra e alta** (penas coladas), não "esticada com rosto igual" [4]. | `pet.dart:2497-2498` |
| G5 | Olho com esclera branca no axolote e no pinguim; piscada simétrica em todos. | Axolote **sem pálpebra** [10]; pinguim de olho **castanho-escuro** e anel rosa [17]; coruja pisca pela pálpebra **de cima** [1][2]. | `_olho` |

### 3.2 Coruja (Nina)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Bico | Triângulo 12 × 12–15 (13% da cabeça), creme #D9C79A; "fala" = ponta +3 | Curto, em gancho, cinza-claro/amarelado [3][8]; mandíbula de baixo articulada [3] | **Errado como mecanismo**, tamanho ok (Blair: pequeno). Precisa de 2 metades, gancho e cor cinza-oliva |
| Queixo branco | Arco 28 × 10 convexo **para baixo** sob o bico | Mancha branca na **garganta**, exibida ao balançar; **colar escuro** abaixo [8][9] | **Errado**: lê como sorriso ("duas bocas" da Nina). Virar faixa + colar |
| Olho | r 9 (21% da cabeça), amarelo #F2C94C, pupila 42%; íris desliza com o olhar; pisca fechando de cima e de baixo | Amarelo-vivo [5]; **fixo** no crânio [2]; pisca pela pálpebra **de cima**, dorme com a de baixo [1][2]; piscadas às vezes de um olho só [1] | Cor e tamanho **certos**; movimento **errado** em dois pontos (R2) |
| Cabeça | Giro `_cabecaGiro·0,8`; inclina 0,06–0,12 rad por humor; rosto desliza 8,5 px | Gira até 270°, balança e inclina para medir distância; "exagerado" [2][6][7]; inclinar = fofo [32] | Fraco: a cabeça é o órgão de expressão da coruja e hoje é a mesma cabeça de mamífero (R3) |
| Pernas | 22 unidades (12,7% da altura visível) | Tarso 43 mm em 19–25 cm (≈ 18–22%); corre atrás da presa [8][9] | Fraco: alongar e **usar** (corrida, salto, pé no montinho) |
| Postura | Corpo 90 × 84 fixo | Relaxada **fofa**; alarmada **magra e alta** [4] | Fraco: nenhuma mudança de volume de pena (R4) |
| Disco/sobrancelha | 2 discos + pás brancas | "sobrancelha branca larga", disco achatado, colar preto [8][9] | Certo em espírito; falta o colar |
| Cor | #9C7A5E (quente) | #847262 / #71665C (pardo-acinzentado) [33] | Meio: esfriar a 1ª pelagem |

### 3.3 Axolote (Lume)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Boca | Sorriso 17,6 (20% da cabeça); aberta 17,6 × 9 | "Sorriso permanente" [12]; linha ≈ 0,85 da cabeça [33]; abre por **sucção** baixando o assoalho [07-Sucção] | **Errado na escala**: o sorriso é a marca e está minúsculo (R6) |
| Guelras | #E7938B sobre #E39BA8 (1,06 : 1); 3 ramos com 3–7 fios de 7,5 | Vermelho de sangue, 4–6 : 1 de contraste [33][10][12]; "juba" [12] | **Errado na cor** (R5); forma certa (07 R5 cumprido) |
| Olhos | r 7,5, esclera branca, piscam | **Sem pálpebra** [10]; leucístico de olho **preto** [10]; pequenos e bem separados [11] | Fraco: manter grandes (fofo) mas escurecer e **não piscar** (R5) |
| Cabeça/corpo | Cabeça 86 × 73 sobre corpo 82 × 71; na folha a cabeça fica **fora d'água** | Cabeça larga e chata; vive no **fundo** [07-SDZG-comp]; sobe só para o gole de ar [13] | Fraco: "banheira" (07 R5 pediu corpo todo submerso; a folha mostra o contrário) (R7) |
| Nado | Patas remam (`rema`) | Anguiliforme: onda cresce da cabeça à cauda, patas junto ao corpo [14] | Errado: as patas não remam; a cauda e o tronco ondulam (R7) |
| Susto/festa | +7% de altura; festa = nada | "Finge de morto" (Minecraft) [15]; valsa de corte [07-SDZG-repro] | Falta tudo (R12) |
| Cor | #E39BA8 (rosa) | Cativeiro "rosa ou branco" [12] | **Certo**: manter o rosa; é o morfo que a criança conhece |

### 3.4 Pinguim (Nino)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Silhueta | Cabeça 72 × 60 + corpo 90 × 91 com vale de pescoço | Corpo em gota contínua; anda ereto com nadadeiras abertas [17] | Fraco (07 R6 já pediu pino; não foi feito) (R8) |
| Bico | Triângulo 12 × 12 + triângulo escuro booleano | Bico **preto**, forte, com faixa clara [17][33]; zurra com bico **para cima** [17] | Errado como mecanismo (R1); cor ok |
| Olho | Esclera branca r 7; pele rosa oval ao lado | Olho **castanho-escuro**; anel ocular, pálpebra e lores **rosa** [17] | Fraco: o branco do olho é de mamífero; o rosa tem de **cercar** o olho (R8) |
| Nado | Nadadeiras **alternam** | Batida **bilateral**, 2,2–2,6 Hz, com planeio [20] | **Errado**: pinguim não alterna as asas (R11) |
| Andar | `passo` desloca os pés ±1,4 | Gingado lateral 3× maior que o avanço, nadadeiras abertas [17][19] | Fraco: falta o **balanço do tronco** (R10) |
| Cor | #4E6E7E | #1E2635–#293342 [33] | Meio: escurecer a 1ª pelagem |
| Festa | brilhos | Exibição extática: bico ao céu, nadadeiras erguidas, zurro [17][07-CalAcademy] | Falta (R9) |

---

## 4. Recomendações priorizadas

Formato: **o que mudar · onde · aceite verificável · prioridade · fonte**.
Medidas em unidades do painter (cabeça da coruja = 84 de largura; na folha,
1 unidade ≈ 3 px).

### R1 — Bico de duas mandíbulas, com gradação, para Nina e Nino (alta)

**O que mudar.** Criar `_bico(canvas, o, w, h, {abre, redonda, grito, cor,
gancho})` usado pelas duas espécies no lugar dos triângulos:

| Peça | Geometria |
|---|---|
| Mandíbula de cima | Triângulo (−w/2, 0), (w/2, 0), (0, h) com `gancho`: ponta curvada 0,12·h para dentro (coruja) ou reta (pinguim); **fixa**, só gira −0,15 rad·`grito` (o "swivel" real [3]) |
| Mandíbula de baixo | Triângulo mais curto (0,8·w × 0,7·h) ancorado na base em (0, 0,25·h); **gira para baixo** `0,55 rad · abre` em torno da base — o único eixo que se move [3][24] |
| Interior | Entre as duas, quando `abre > 0,12`: polígono escuro `lerp(tinta, acento, 0,25)`; língua oval 0,35·w × 0,2·h em #E57F78 quando `abre > 0,55` |
| Forma "u" | `redonda > 0,5`: as duas metades se projetam (+0,3·h) e afinam (largura × 0,65) com cantos arredondados — o único caso em que o bico "vira lábio" [24] |
| Grito/zurro | `grito`: bico × 1,3, `abre = 0,9`, a cabeça gira −0,6 rad (bico para o céu) [17][29] |

Tamanho: Nina `w = 13, h = 16` (≈ 15% da cabeça; Blair: pequeno [31-12]),
cor `#8E8A70` (cinza-oliva medido [33], não creme); Nino `w = 14, h = 17`,
cor `#3F4149` com risco claro #9E9FA4 (mantém). Gradação: `abre = max(bocejo,
carinho·0,8, mastiga, vida.boca)` contínuo, sem limiar 0,3. Ritmo (motor e
`b4.js`): pop na vogal, fecha nas consoantes B/M/P/F/T/V por ≥ 2 quadros, sem
abrir duas vezes numa palavra, acento visual 2 quadros antes do som [22].
**Onde.** `_coruja` (`pet.dart:3618-3628`), `_pinguim` (`3947-3974`), novo
`_bico`; `SaidaDaVida.bocaRedonda` (laudo 31 R1) reaproveitado; captura
`novelinha_quadros_test.dart:40` (incluir `Species.penguin` e `axolotl` na
lista da linha 37).
**Aceite.** (a) Folhas novas `fala-owl-*` e `fala-penguin-*`: os 6 quadros
são **6 imagens distintas**, e a **altura da abertura** (caixa do interior
escuro) cresce monotonicamente: ≈ 0, 2, 4, 6, 8, 9 unidades (×3 na captura);
(b) a caixa da mandíbula de cima **não muda** entre nv0 e nv5 (±1 px), salvo
no grito; (c) existe um quadro "u" com largura ≤ 0,7 da largura do bico em
repouso; (d) o bico da Nina tem largura ≤ 0,16 da cabeça; (e) nos vídeos de
teste, nenhuma sequência fecha-abre-fecha em ≤ 3 quadros a 30 qps.
**Fontes.** [3][24][25][22][29][17][31-12].

### R2 — Olho de coruja: pisca de cima, dorme de baixo, não desliza (alta)

**O que mudar.** Em `_olho` com `coruja: true`: (1) **piscada** = uma pálpebra
na cor do disco (`lerp(pelo, superficie, 0,35)`) que **desce do topo**:
recortar pelo círculo do olho e pintar o retângulo de `o.dy − r` até
`o.dy − r + 2r·f`; sem `canvas.scale`; (2) **sono/sonolento** (`fechamento`
vindo de `Mood.sleepy` ou do episódio dormir) = pálpebra **de baixo** subindo
(retângulo de `o.dy + r − 2r·f` até `o.dy + r`), e os dois juntos só quando
`f > 0,94` (o "sinérgico" da sonolência [1]); (3) a cada 4 piscadas, **uma
só de um olho** (sorteio no motor, `_piscaAgora`), 120 ms [1]; (4)
`_olhoDesvio` = **zero** para `Species.owl`; a íris fica concêntrica, e o
olhar vai inteiro para a cabeça (R3) [2][6]. Intervalo mediano de piscada da
Nina igual ao das outras: corujas noturnas piscam menos [1], mas a
buraqueira é diurna-crepuscular [5][9].
**Onde.** `_olho` (`pet.dart:5942-5957`, `5969-5971`), `MotorDeVida._piscar`
(`motor_de_vida.dart:584-590`, `1483-1488`).
**Aceite.** Golden `pisca-owl-contente` com `pisca = 0,5`: a borda **inferior**
da região amarela fica na mesma linha (±1 px) do quadro aberto e a borda
superior desce ≥ 0,9r; com `Mood.sleepy` e `fechamento 0,5`, o inverso; numa
captura de 60 s de ócio, ≥ 1 piscada unilateral; centroide da pupila em
relação ao centro do olho varia ≤ 0,5 px em qualquer quadro com `olhar ≠ 0`.
**Fontes.** [1][2][6][7].

### R3 — A cabeça é a expressão: giro, balanço e inclinação da Nina (alta)

**O que mudar.** Para `Species.owl`: (1) a **virada** inteira na cabeça —
`_rosto` passa de `virada·8,5` para `virada·14` e `_encurtaRosto` de 0,14
para 0,24 (a cabeça "gira", os discos encurtam como num três-quartos [26]);
(2) **inclinação curiosa**: novo gesto de cabeça no motor (`_cabecaGesto`)
que tomba 0,30 rad (≈ 17°) para o lado do `inclinaParaOLado` por 0,6–1,2 s
quando chega som, toque ou borboleta — é o gesto que lê como fofo [32];
(3) **balanço de paralaxe**: antes de pular/caçar e no "alerta", 2 ciclos de
sobe-desce de 4 unidades em 0,6 s, com a cabeça (não o corpo) [6][7];
(4) **nuca**: 1 vez a cada ~90 s de ócio, a cabeça gira 180° em 350 ms
(mostra a nuca lisa com as pintas), fica 0,8 s e volta — o "270°" é real
[2][7], 180° basta para o desenho [I]. Inclinação por humor da Nina ×1,5
(saudade 0,18 rad).
**Onde.** `pet.dart:2729-2736` (por espécie), `_cabecaGiro` (`2810-2820`),
`motor_de_vida.dart` (gesto de cabeça, `610-617`, `1432-1470`; episódios).
**Aceite.** Em 2 min de ócio gravados a 30 qps: ≥ 3 inclinações ≥ 0,25 rad
mantidas ≥ 15 quadros; ≥ 1 giro de nuca; no quadro de virada máxima, a
distância entre os centros dos olhos cai ≥ 20% em relação ao frontal (hoje
14%). Teste de 5 s com 10 pessoas: ≥ 8 dizem "ela está curiosa/prestando
atenção" na inclinação.
**Fontes.** [2][6][7][32][26][4].

### R4 — Garganta, colar, pernas e postura magra/fofa (alta)

**O que mudar.** Em `_coruja`: (1) trocar o arco do queixo (`3604-3611`) por
uma **faixa de garganta** branca `RRect 40 × 7` em (0, 24), cantos 3,5, que
**cresce para 46 × 9 no balanço de cabeça** (a buraqueira "expande e exibe" a
mancha [9]); (2) **colar escuro**: traço 3 px em `sombraForte` de (−30, 30)
a (30, 30) curvando para cima nas pontas até (±36, 14) [8]; (3) pernas de
**30** unidades (y 30 → 60, dedos até 67), com um anel claro de "tarso
emplumado" 8 × 5 em y 34 [8]; a cabeça sobe 4 e o corpo 6 para manter o
quadro; (4) **postura**: `Mood.radiant`/`content` em repouso = penas **fofas**
(corpo × 1,04 largura, barriga × 1,06); alerta/susto = **magra e alta** (corpo
× 0,88 largura, × 1,10 altura, asas coladas, pintas somem) [4]; (5) correr:
quando `corre`, as pernas alternam em 4 tempos e o corpo inclina 0,2 rad para
a frente, cabeça fixa (o papa-léguas de pena [9]).
**Onde.** `pet.dart:3437-3461`, `3466-3471`, `3604-3611`; `motor_de_vida.dart`
(intenção `corre`).
**Aceite.** Golden `pet_owl_contente`: pernas visíveis ≥ 16% da altura da
figura (hoje 12,7%); nenhum componente branco **convexo para baixo** sob o
bico (a mancha é um RRect com relação largura/altura ≥ 4); `susto-owl-0` ×
`contente-0`: caixa do corpo com largura ≤ 0,90 e altura ≥ 1,08 da de repouso
**e** caixa da cabeça com largura entre 0,97 e 1,03 (hoje a cabeça reescala
junto); área da silhueta ±4%.
**Fontes.** [4][8][9][5].

### R5 — Guelras de sangue, com tique, e olho sem pálpebra (alta)

**O que mudar.** Em `_axolote`: (1) cores fixas, não derivadas do pelo:
haste **#A8333F**, filamentos **#C2404F**, ponta dos filamentos #E07A86
(brilho), 1 px de contorno `lerp(haste, tinta, 0,3)`; (2) filamentos **mais
longos** (10) e **9** por ramo no pleno, curvando para a ponta (a "juba" [12]);
(3) **tique de guelra** no lugar da piscada: a cada 4–8 s, os 3 ramos de um
lado dobram para trás 0,4 rad em 120 ms e voltam em 300 ms (sorteado por
lado); na água, ondulação contínua ±0,08 rad a 0,5 Hz; (4) **olho**: sem
piscada (`fechamento` ignorado fora do sono), íris **#2B2118** com 0,62r e
esclera **rosa-clara** `lerp(pelo, superficie, 0,55)` em vez de branco (o
leucístico tem olho preto [10]); no sono, mantém a estilização do arco
(decisão do 07), mas o corpo deita no fundo e as guelras caem 0,3 rad.
**Onde.** `pet.dart:3718-3757`, `3771-3772`; `_olho` (novo `semPalpebra`);
`motor_de_vida.dart` (`_piscar` por espécie).
**Aceite.** Contraste WCAG haste/filamento × pelo ≥ **2,3 : 1** em todas as 6
pelagens (hoje 1,06); na folha `vida-axolotl`, ≥ 1 quadro a cada 240 com os
ramos de um lado deslocados ≥ 6 px; `pisca-axolotl-*` ≡ `fala-axolotl-*-0`
(0 px: não pisca); luminância da esclera ≤ 0,9× a da `superficie`.
**Fontes.** [10][12][33][1] (ausência de pálpebra), [15].

### R6 — A boca larga do axolote (alta)

**O que mudar.** `_boca` ganha um perfil por espécie (`PerfilDeBoca.axolote`):
`w = 54` (0,63 da cabeça; hoje 22), linha quase reta com **cantos erguidos**:
arco de altura 0,10·w (contente) e 0,16·w (radiante), traço 2,2 px em
`lerp(pelo, tinta, 0,5)`; neutro = reta; saudade = cantos retos (não virada
para baixo: a espécie não "faz bico"). **Abertura** (R1 do laudo 31 vale, com
a geometria daqui): a mandíbula de baixo **desce** mantendo a largura — a
cabeça inteira ganha um "queixo" que cai `6 + 10·abre` unidades (a sucção
baixa o assoalho [07-Sucção]), interior `lerp(acento, tinta, 0,4)` ocupando
0,55·w × (2 + 14·abre), **sem** ultrapassar 0,6·w de largura [31-12]; a forma
"u" vira um **O** pequeno de 0,22·w (o gole de ar, R7). Bochechas sobem 2 com
`abre > 0,5`.
**Onde.** `_boca` (`pet.dart:6083-6158`), `_axolote` (`3768`); captura com
`Species.axolotl`.
**Aceite.** Golden contente: largura do traço da boca ≥ 0,60 da largura da
cabeça (hoje 0,20); 6 quadros `fala-axolotl-contente-*` distintos com altura
do interior monótona (≈ 0, 3, 6, 9, 12, 14 unidades); a largura da boca
aberta varia ≤ 5% entre nv1 e nv5; teste de 2 s a 120 px com 10 pessoas: ≥ 7
dizem "axolote" (hoje o 07 dizia "bicho rosa com folhas").
**Fontes.** [12][33][10][31-12][22].

### R7 — Lume no fundo, nado de enguia, gole de ar (alta)

**O que mudar.** (1) Na home e no ócio aquático, a **linha d'água passa
acima da ponta das guelras** (≥ 6 unidades): cabeça e corpo submersos, com
o tom da água (`_tomDaAgua`) sobre o bicho inteiro e um reflexo claro de 2 px
no topo da cabeça; (2) **andar no fundo**: as patas alternam em 4 tempos
(diagonal: frente-esquerda com trás-direita), 1,2 passos/s, corpo reto; a
cauda arrasta com onda de 2 unidades; (3) **nadar**: patas **coladas** ao
corpo, onda no deformador com amplitude 1 unidade atrás da cabeça e **8 na
ponta da cauda**, frequência 2,5 Hz no "corre" e 1,2 no passeio (velocidade
regulada pela frequência [14]); (4) **gole de ar**: episódio a cada 60–120 s:
sobe em 0,8 s, a cabeça rompe a linha d'água por 0,4 s com a boca em "O"
(R6), uma bolha, desce em 1,2 s [13].
**Onde.** `_axolote` (`pet.dart:3668-3687`, `3647-3649`), `pinta_mundo.dart`
(linha d'água), `deformador.dart`, `motor_de_vida.dart` (episódio).
**Aceite.** Captura da home (`home-axolotl.png`): caixa da cabeça inteira
abaixo da linha d'água em ≥ 95% dos quadros de 60 s; na captura `nada-
axolotl`, patas com deslocamento < 2 px/quadro e ponta da cauda com amplitude
≥ 20 px; em 5 min, 3–5 goles de ar.
**Fontes.** [13][14][07-SDZG-comp][12].

### R8 — Nino em pino, com as cores do magalhães (alta)

**O que mudar.** (1) Cabeça e corpo num **só `Path`** (gota): largura 72 no
topo da cabeça, 90 no peito, sem vale — o perfil de largura é monótono até o
peito; (2) olho: íris **#2A1E1A** com 0,70r, esclera `lerp(claro, #2A1E1A,
0,15)` (quase não aparece), e a pele rosa vira **anel** de 2 px em #E7A3A0 ao
redor do olho + lores (oval 7 × 5 entre olho e bico), #EE8E8B no pleno [17];
(3) paleta: `pelagemPinguim[0]` → **#263142**, `[1]` → #1E2635, `[3]` →
#2E3A47, mantendo os índices (as claras ficam como "jovem/azul"); barriga
**#EEF3F8**; faixas em #1E2635 com 5 px; bico #3F4149 + faixa #9E9FA4; pés
`lerp(#3A3330, #D9A5A3, mancha)`; (4) nadadeiras em repouso **abertas 0,12
rad** (equilíbrio [17]), não coladas.
**Onde.** `_pinguim` (`pet.dart:3819-3823`, `3895-3904`, `3930-3943`),
`tokens.dart:185-192`.
**Aceite.** Golden: o perfil de largura por linha não tem mínimo local > 3%
entre o topo da cabeça e o peito; ΔE (CIE76) entre `pelagemPinguim[0]` e
#293342 ≤ 10; o anel rosa cerca ≥ 270° do olho; nenhum branco de esclera com
área > 15% do olho.
**Fontes.** [16][17][33][07-CES].

### R9 — Zurro e exibição extática como festa e grito do Nino (alta)

**O que mudar.** `vida.festa` e `grito` no pinguim = **exibição extática**:
antecipação 3 quadros (cabeça baixa 4, nadadeiras fecham), depois cabeça
gira −0,6 rad (bico ao céu), bico `abre 0,9` (R1), nadadeiras sobem 1,1 rad
e **tremem** ±0,06 rad a 8 Hz, peito estufa (corpo × 1,06 largura no peito),
pés afastados +4; segura 0,8 s; solta com recuo (acento duro quica [22]). Na
novelinha, o som é o zurro em volume baixo (laudo 07 §3.5).
**Onde.** `pet.dart:2509` (festa por espécie), `_pinguim` nadadeiras
(`3862-3891`), `b4.js` (grito do painter, não sobreposto — laudo 31 R2).
**Aceite.** `festa-penguin-0` × `radiante-0` ≥ 25% de pixels diferentes
(hoje: sem folha; nas outras duas, 0%); no quadro de pico, a ponta do bico
fica acima do topo da cabeça.
**Fontes.** [17][18][22][07-CalAcademy].

### R10 — Gingado de verdade (média)

**O que mudar.** No andar do Nino: o tronco **rola** ±0,14 rad (≈ 8°) no
compasso dos passos, o centro de massa desloca ±3 unidades para o lado do pé
de apoio, a cabeça contra-rola 50% (fica mais reta que o tronco), as
nadadeiras ficam abertas 0,25 rad e **balançam em oposição** ao rolo; passos
curtos (deslocamento do pé 6, cadência 1,8 passos/s), sem bob vertical maior
que 2 (a energia vai para o lado, não para cima [19]). Tobogã (estilização):
no `corre`, após 0,6 s, o corpo deita (rotação 1,4 rad), nadadeiras empurram
alternadas a 2 Hz e os pés chutam — 1,5 s, depois levanta; só em areia/neve
de cena, nunca na água.
**Onde.** `motor_de_vida.dart` (gingado por espécie; laudo 24 ciclo de 4
tempos), `_pinguim` (`3797-3817`).
**Aceite.** Filmagem de 2 s a 30 qps: amplitude lateral do centroide ≥ 2,5×
a amplitude vertical; ângulo do tronco oscila ≥ 12° pico a pico; a cabeça
oscila ≤ 60% do tronco.
**Fontes.** [19][17][21].

### R11 — Nado "voando": nadadeiras juntas, com planeio (média)

**O que mudar.** Trocar `alterna = lado` por batida **bilateral**: as duas
nadadeiras descem juntas (golpe de força, 45% do ciclo) e sobem juntas, a
**2,3 Hz**; vistas de frente, descem **para fora e para baixo** (rotação 0,9
rad no ombro) e sobem recolhendo (0,5 rad), para não ler "dar de ombros";
o corpo inclina 0,25 rad para a frente e **plana** 0,8 s a cada 3 ciclos
(nadadeiras paradas em V aberto) [20]; os pés seguem como leme (já há).
**Onde.** `_pinguim` (`pet.dart:3862-3891`), `motor_de_vida.dart` (ciclo de
nado por espécie).
**Aceite.** Na captura `nada-penguin`, a diferença de fase entre as duas
nadadeiras é < 0,05 ciclo; frequência 2,0–2,6 Hz; ≥ 25% dos quadros em
planeio (nadadeiras com deslocamento < 1 px entre quadros).
**Fontes.** [20][17][07-CES].

### R12 — Susto e festa com corpo, por espécie (média)

**O que mudar.** (Complementa R3/R4 do laudo 31, que tratou das outras três.)

- **Nina**: susto = postura magra e alta (R4) + balanço de paralaxe (R3) +
  olhos **sem** pálpebra, pupila 0,30r; festa = 3 batidas de asa dobrada
  (`asa` × 3) com pulinho de 6 e bob de cabeça — a Nina não zurra nem salta
  alto.
- **Lume**: susto = **"fingir de morto"** suave: cai 6 unidades, guelras para
  trás 0,5 rad, cauda enrola, 1,0 s parado, olhos abertos [15]; festa =
  **valsa**: o corpo gira 360° em 0,8 s (deformador: três-quartos → costas →
  frente) com guelras abertas e cauda em onda [07-SDZG-repro].
- **Nino**: susto = recua 4, nadadeiras abertas 0,9 rad, bico fechado,
  cabeça encolhe 3; festa = R9.

**Onde.** `pet.dart:2497-2509`, cada `_espécie`, `deformador.dart`.
**Aceite.** `festa-<esp>-0` × `radiante-0` ≥ 20% de pixels diferentes (hoje 0
e 0); `susto-<esp>-0` × `contente-0` alinhados: ≥ 20% diferentes **dentro da
caixa da cabeça** depois de descontar a reescala; área da silhueta ±4%.
**Fontes.** [4][15][22][31-14][07-SDZG-repro].

### R13 — Cores medidas da Nina (baixa)

**O que mudar.** `pelagemCoruja[0]` → **#8A7461** (entre #847262 e #9E8F7E
medidos, +8% de saturação pelo chapado [31-15]), `[3]` → #6E6358; pintas
`#D9CCBB`; sobrancelha/garganta `#F3EDE3`; bico `#8E8A70`; pernas `#CFC4AE`;
olho mantém **#F2C94C** (o amarelo-vivo é a marca [5]); colar `#4A3B31`.
**Onde.** `tokens.dart:165-172`, `pet.dart:3438`, `3627`.
**Aceite.** ΔE (CIE76) entre a pelagem 0 e #847262 ≤ 12; contraste
sobrancelha × disco ≥ 2 : 1; contraste olho × disco ≥ 3 : 1.
**Fontes.** [33][5][8][31-15].

---

## 5. O que não fazer

- **Não** desenhar boca dentro do bico (lábios, dentes, língua de mamífero):
  bico "não tem lábios" [25]; só a forma "u" sai da pirâmide [24]. Nada de
  elipse por cima do quadro na novelinha (laudo 31 R2).
- **Não** mover a mandíbula de cima para abrir: ela só "gira um pouco para
  cima" no grito [3].
- **Não** deixar a íris da Nina deslizar com o olhar [2][6] nem piscar
  fechando de baixo para cima [1][2].
- **Não** manter o arco branco convexo sob o bico: é lido como sorriso (a
  "segunda boca" da Nina) [O]; a mancha real é faixa de garganta com colar [8][9].
- **Não** dar à Nina o bico enorme do Duo (é buraqueira: bico curto [3][8]);
  largura ≤ 0,16 da cabeça (R1).
- **Não** reduzir os olhos "para ficar real" [31-13]; mas **não** dar esclera
  branca ao axolote nem ao pinguim [10][17].
- **Não** piscar o Lume (sem pálpebra [10]); o sono fica como estilização
  decidida no 07, com o corpo contando a história.
- **Não** usar "guelra para a frente = estresse" (crença de fórum, laudo 07).
- **Não** trocar o rosa do Lume por oliva "realista": o rosa é o morfo de
  cativeiro que a criança conhece [12] e já está decidido (07).
- **Não** desenhar o Lume de pé com a cabeça fora d'água (07; R7).
- **Não** alternar as nadadeiras do Nino no nado [20]; **não** remar com os
  pés (07).
- **Não** usar laranja no bico ou nos pés do Nino [16][17]; **não** usar preto
  #000 — o preto do magalhães é ardósia #1E2635–#293342 [33].
- **Não** fazer tobogã no gelo nem em água: o Nino vive em praia e toca; o
  tobogã é estilização e fica na areia [21][07-WHOI].
- **Não** girar a cabeça da Nina 270° como gag de terror; 180° de nuca
  bastam [I] e o balanço/inclinação são o grosso [6][7].
- **Não** animar todo fonema do TTS; **não** abrir o bico duas vezes na mesma
  palavra; B/M/P/F/T/V fecham por ≥ 2 quadros [22].
- **Não** reabrir Rive nem trocar chaves de espécie (síntese).

---

## 6. Fontes (todas lidas em 2026-11-08)

1. Morris, J. G. L. & Parsons, J. J. (2023). *The Various Ways in Which
   Birds Blink*. Animals 13(23):3656.
   <https://pmc.ncbi.nlm.nih.gov/articles/PMC10705787/>
2. The Owl Pages — Deane Lewis, *Owl Eyes & Vision*.
   <https://www.owlpages.com/owls/articles.php?a=5>
3. The Owl Pages — Deane Lewis, *Owl Beak or Bill*.
   <https://www.owlpages.com/owls/articles.php?a=8>
4. World of Owls — *Behaviour* (mesmo texto em The Owl Pages, *Behaviour of
   Owls*, `articles.php?a=2`). <https://worldofowls.com/behaviour/>
5. Owl Research Institute — *Burrowing Owl*.
   <https://owlresearchinstitute.org/burrowing-owl>
6. Owl Research Institute — *The better to see you with: motion parallax in
   young owls*.
   <https://www.owlresearchinstitute.org/single-post/motion-parallax-in-owls>
7. Audubon / BirdNote — *Why Do Owls Bob Their Heads?*
   <https://www.audubon.org/magazine/why-do-owls-bob-their-heads>
8. oiseaux.net — *Burrowing Owl* (ficha morfológica).
   <https://oiseaux.net/birds/burrowing.owl.html>
9. Wikipedia — *Burrowing owl* (seção Description; HTML lido e filtrado).
   <https://en.wikipedia.org/wiki/Burrowing_owl>
10. Wikipedia — *Axolotl* (Description, morfos).
    <https://en.wikipedia.org/wiki/Axolotl>
11. San Diego Zoo Wildlife Alliance Library — *Axolotl Fact Sheet:
    Characteristics*.
    <https://ielc.libguides.com/sdzg/factsheets/axolotl/characteristics>
12. National Geographic — *Axolotl*.
    <https://www.nationalgeographic.com/animals/amphibians/facts/axolotl>
13. Axolotl.org — *Biology*. <https://www.axolotl.org/biology.htm>
14. D'Août, K., Aerts, P. & De Vree, F. *Swimming kinematics in the axolotl
    (Ambystoma mexicanum): do they reflect the same mechanism as in fishes?*
    Resumo, Third Belgian Congress of Zoology (PDF lido por `pdftotext`).
    <https://www.vliz.be/imisdocs/publications/358121.pdf>
15. Minecraft Wiki — *Axolotl*. <https://minecraft.wiki/w/Axolotl>
16. Wikipedia — *Magellanic penguin* (Description).
    <https://en.wikipedia.org/wiki/Magellanic_penguin>
17. oiseaux-birds.com — *Magellanic Penguin* (ficha).
    <https://oiseaux-birds.com/card-magellanic-penguin.html>
18. SeaWorld — *Magellanic Penguin* (Animal facts).
    <https://seaworld.org/animals/facts/birds/magellanic-penguin/>
19. Griffin, T. M. & Kram, R. (2000). *Penguin waddling is not wasteful*.
    Nature 408:929 (PDF lido por `pdftotext`).
    <https://spot.colorado.edu/~kram/penguins.pdf>
20. Sato, K. et al. (2010). *Scaling of swim speed and stroke frequency in
    geometrically similar penguins*. Proc. R. Soc. B 277:707–714.
    <https://pmc.ncbi.nlm.nih.gov/articles/PMC2842743/>
21. A-Z Animals — *Penguins outpace sea lion in surprise beach showdown*
    (rei-pinguins deslizando na areia; fonte fraca, só para o tobogã).
    <https://a-z-animals.com/articles/penguins-outpace-sea-lion-in-surprise-beach-showdown/>
22. Williams, Richard. *The Animator's Survival Kit* — pp. 293 (acentos),
    304–307 (diálogo), texto OCR. <https://archive.org/details/taskav-01>
23. Blair, Preston. *Advanced Animation* — prancha da coruja ("a bird's wing
    can be handled… as a hand with the feathers as fingers"), texto OCR.
    <https://archive.org/details/advancedanimation>
24. O'Connor, Dermot. *2D Animation: Tips and Tricks* — "Bird beaks"
    (LinkedIn Learning; transcrição parcial, o resto é pago).
    <https://www.linkedin.com/learning/2d-animation-tips-and-tricks/bird-beaks>
25. Hastings, Gabriel. *Acting for Animation: Lip Sync* (relato de animar o
    bico de uma gaivota).
    <https://gabrielhastingsanimationbloguk.wordpress.com/acting-for-animation-lip-sync/>
26. Duolingo Blog — Greg Hartman, *Reshaping Duo*.
    <https://blog.duolingo.com/reshaping-duo/>
27. Duolingo Blog — *How we built visemes for the World Characters* (relida
    com foco em bico: o post não trata do Duo).
    <https://blog.duolingo.com/world-character-visemes/>
28. Wikipedia — *Pocoyo* (Pato: bico que dobra e gira).
    <https://en.wikipedia.org/wiki/Pocoyo>
29. Wikipedia — *Pingu* (bico-megafone do "noot noot").
    <https://en.wikipedia.org/wiki/Pingu>
30. Animation Scoop — *Interview: Puffin Rock and the New Friends & 25 years
    of Cartoon Saloon* (Lorraine Lordan, Jeremy Purcell).
    <https://www.animationscoop.com/interview-puffin-rock-and-the-new-friends-and-25-years-of-cartoon-saloon/>
31. Wikipedia — *Octonauts* (Peso; origem Meomi; pouco sobre desenho).
    <https://en.wikipedia.org/wiki/Octonauts>
32. Buckley, C. et al. (2025). *What Does That Head Tilt Mean?* Animals
    15(21):3179 — cita White & Varakin (2017) e Amry et al. (2018) sobre
    inclinação e fofura. <https://pmc.ncbi.nlm.nih.gov/articles/PMC12609352/>
33. Fotos medidas (Wikimedia Commons, capas dos artigos da Wikipédia):
    `Southern_burrowing_owl_(Athene_cunicularia_cunicularia)_Colonia.jpg`
    (1280 px); `MagellanicPenguin.jpg` (1280 px); `Axolotl_ganz.jpg`
    (selvagem, 2178 px); `AxolotlBE.jpg` (leucístico, 960 px). Script:
    mediana-corte em 4 cores por região retangular (PIL).

Fontes dos laudos anteriores usadas aqui: [31-12] Blair, *The Cute
Character*; [31-13] Borgi 2014; [31-14] 12 princípios; [31-15] Bluey;
[31-17] Rhubarb; [31-22] The Rookies; [07-SDZG-comp/repro] fichas SDZWA do
axolote; [07-Sucção] Biology Open 2025; [07-CalAcademy]; [07-CES]; [07-WHOI].

**Vistos só no trecho do resultado de busca (não lidos; não sustentam
nenhuma recomendação):** Cornell All About Birds (ID e Life History da
buraqueira, 403 hoje; o 07 já os leu); AmphibiaWeb *Ambystoma mexicanum*
(503); Britannica *Penguin: natural history* (403); Adobe Animate, *Auto
Lip-Sync* com exemplo de coruja (403); entrevista de Tomm Moore sobre Puffin
Rock (403); pôsteres da EKU (White & Varakin 2017; Amry 2018), citados via
[32]; páginas de criadores sobre a cor das guelras (capilares) — a cor foi
medida na foto [33] em vez disso; SICB (andar do axolote).

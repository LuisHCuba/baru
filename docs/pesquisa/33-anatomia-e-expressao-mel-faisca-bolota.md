# Laudo 33 — Anatomia, apelo e expressão: gata (Mel), raposa (Faísca) e buldogue francês (Bolota)

Pesquisa para desenho vetorial chapado infantil. Novembro de 2026. Avança
sobre o laudo 08 (biologia, estágios, itens, sons) e sobre 24/25/30/31
(motor de movimento, bocas): aqui o assunto é **o que faz cada um ler como
a sua espécie e ainda ser fofo** — orelha, pupila, bigode, focinho, cauda,
dobra, língua, cor — e **como cada um mexe** (a gata se espreguiça, se lambe
e pula; a raposa escuta e mergulha de focinho; o buldogue anda plantado e
põe a língua para fora). O laudo 08 avaliou a versão anterior do desenho;
boa parte do que ele pediu (R4, R5, R6) **já foi feita** no código, e este
laudo parte do desenho **atual**.

**Legenda** (a mesma dos laudos 06, 08 e 31)

- **[F]** fato com fonte (número entre colchetes remete à seção "Fontes");
- **[O]** observação do app, com `arquivo:linha` ou imagem que eu abri/medi;
- **[I]** inferência minha, sem fonte que a prove.

**O que eu medi (reproduzível).** Li `_gata` (`pet.dart:3986-4182`),
`_raposa` (`4192-4392`), `_buldogue` e as funções dele (`4503-5172`), os
helpers `_olho`, `_boca`, `_bigodes` (`5931-6223`), o repertório por espécie
(`pet.dart:986-1057`), o bote e o passo no motor (`motor_de_vida.dart:1207-1290`,
`1827-1852`) e o episódio `alisar` (`episodios.dart:782-790`). Abri a folha
`novelinha-ep1/assets/img/app/bicho-fox.webp` (8 × 5 quadros de 543 × 428),
`corre-fox.webp`, `anda-fox.webp` e as artes de humor
`landing/assets/pet-{cat,frenchie}-*.webp` (369 × 299) — **não existe folha
da gata nem do buldogue** nas capturas da novelinha
(`novelinha_quadros_test.dart:36` só captura capivara, lontra, tartaruga e
coruja). Comparei quadros da raposa pixel a pixel (diferença RGBA > 60,
alinhando pela caixa da silhueta). Medi cores em quatro fotos do Wikimedia
Commons (960 px, median-cut em 4 cores por região) [22]. Todas as fontes
foram lidas em **2026-11-08**.

---

## 0. Resumo em 12 linhas

1. [O] **Os três têm o mesmo olho, a mesma boca e o mesmo bigode de todo o
   elenco.** `_olho` desenha pupila **redonda** `0,50r` em `tinta` nas 9
   espécies (`pet.dart:5977`); não há íris colorida, nem fenda vertical na
   gata, nem pupila oval na raposa. [F] A gata tem pupila em **fenda
   vertical** que varia **135 vezes** de área; é o traço dos predadores de
   emboscada baixos [9]. A raposa tem pupila "oval, vertical" [3].
2. [O] **Os bigodes da gata não saem da cara**: 3 fios de 19 px a partir de
   x = ±19, ponta em x = 38 numa cabeça de meia-largura 41 (`pet.dart:4159`,
   `6203-6223`), a 50% de alfa. [F] O bigode real chega "à largura do corpo"
   e **se inclina para a frente no bote** [10]; na ficha de dor felina, bigode
   "solto e curvo" é bem-estar; "reto e apontado para a frente" é dor [8].
3. [O] **A boca da raposa tem 2 desenhos** (nv0 ≡ nv1, nv2 ≡ nv5: diferença
   0,03% e 0,14%), **o susto é o quadro "contente" esticado** (+8% de altura,
   −7% de largura, caixa 353 × 393 → 327 × 426) e a **festa = radiante +
   brilhos** (0,0% dentro da silhueta). Isso é o que o laudo 31 já achou
   para capivara, lontra e tracajá; vale igual para a Faísca.
4. [O] **A raposa dá o bote do gato.** `JeitoDeCacar` é o mesmo para
   `cat` e `fox` (`pet.dart:989-993`): agacha, rebola a traseira a 20 rad/s e
   pula **para a frente** (`motor_de_vida.dart:1838-1851`). [F] A raposa
   "assume a postura, salta **para cima** e mergulha **de cabeça**"; o pico do
   salto fica 50–60 cm acima da neve e o focinho entra quase na vertical, a
   até 4 m/s [4]; ela "dirige no ar com a cauda" e pousa até 5 m adiante [3].
5. [O] **O buldogue anda aos saltinhos** (`_saltita` inclui `frenchie`,
   `pet.dart:2771-2777`; `JeitoDeCacar(velocidade: 58, saltita: true)`,
   `:1001-1002`). [F] O padrão da raça pede passo "com alcance e impulso,
   desimpedido, livre e vigoroso", em **quatro trilhas, a da frente mais
   larga que a de trás** [1]. O "rolar" ("loose-jointed, shuffling, sidewise
   motion") é do **buldogue inglês** [2], outra raça.
6. [O] **A gata "se lambe" sem pata**: `Episodio.alisar` só vira a cabeça
   0,16 para o lado, desce 5 px e abre/fecha a boca a 16 rad/s
   (`episodios.dart:782-790`). [F] A gata passa **30 a 50% do dia** se
   lambendo [12]: é o gesto mais frequente dela e hoje não se lê.
7. [F] **O que lê como gata**: orelha triangular ereta e **para a frente**,
   bigode solto, pupila pequena, cauda **em pé com a ponta curva** ao se
   aproximar, "tremendo" na saudação; piscada lenta; amassar antes de dormir;
   espreguiçar = relaxada [5][6][7]. [O] O app já tem cauda por humor com
   gancho (`pet.dart:3997-4023`), o "M" da testa (`4132-4140`), orelha que
   abre para os lados e a piscada lenta — **faltam** a pupila, o bigode, a
   boca "ω" com filtro e os gestos de corpo (lamber, espreguiçar).
8. [F] **O que lê como raposa**: orelhas grandes (7,7–12,5 cm num corpo de
   45–90 cm) **com o dorso preto**, focinho **estreito** de perfil côncavo,
   **branco** no queixo, lábios, garganta, peito e **ponta da cauda**, **preto**
   nas patas, íris âmbar [3]. [O] O app já tem ponta branca, babador, meias
   e focinho em V; **mas** a ponta escura da orelha é um lobo **na frente**
   (não o dorso), o nariz fica no **topo** do V (`pet.dart:4371-4377`, y = 9)
   com a boca 10 px abaixo, e a metade de baixo da cara é branca de orelha a
   orelha (`4346-4356`).
9. [F] **O que lê como buldogue francês**: "cabeça quadrada com orelhas de
   morcego e dorso arqueado"; orelha "larga na base, alongada, **topo
   redondo**, alta, não muito junta"; olhos "escuros, bem afastados, **baixos
   no crânio, o mais longe possível das orelhas**, redondos", "**sem branco do
   olho à vista** olhando para a frente"; "stop" com "sulco entre os olhos" e
   "rugas pesadas formando um **rolo macio** sobre o nariz extremamente
   curto"; beiços "cobrindo dentes e língua, **que não aparecem com a boca
   fechada**"; "pernas da frente curtas, grossas, **bem afastadas**"; sem
   cauda visível [1]. [O] O desenho atual acerta orelha, rolo, beiço, pera
   invertida e pernas afastadas; erra o **olho** (alto, muito branco, pupila
   pequena) e mostra os **dentes sempre** (`pet.dart:5060-5075`).
10. [F] **Língua e ofego**: o cão ofega a **5,33 ± 0,7 ciclos/s**, que é a
    frequência de ressonância do sistema respiratório dele (5,28 Hz) [14]; em
    repouso respira 18–34 vezes/min [15]. [O] A língua do Bolota só aparece
    no radiante e balança com a respiração (`pet.dart:5089-5117`).
11. [F] Em desenho infantil vetorial: formas "geométricas e simples", rigs
    "intencionalmente limitados" (Bluey [19]); "nada de piada literal de
    cachorro, só acenos" e "sem line-art preta" (Bluey [18]); quanto mais
    detalhado o personagem, mais "sair do modelo" ao mexer uma feição (Hey
    Duggee [20]); sem diálogo, "tudo depende da linguagem corporal", que "em
    animais é universal" (Simon's Cat [21]); o próprio Preston Blair manda
    "fazer um ciclo de **corrida deste buldogue**" e "desenhar este cão em
    outras posições" a partir de uma fórmula de massas redondas [16].
12. Recomendações: **R1 olho felino**, **R2 bigode e boca "ω" da gata**,
    **R3 gestos de corpo da gata**, **R4 bote de raposa**, **R5 cara de
    raposa**, **R6 passo plantado do buldogue + ofego**, **R7 olho e boca do
    buldogue pelo padrão**, depois cauda da gata (R8), humor sem "cara de
    dor" (R9), cores medidas (R10), miado (R11), folhas da novelinha (R12).

---

## 1. O que o app faz hoje

### 1.1 O que os três dividem com o resto do elenco (`pet.dart`)

| Peça | O que é | Onde |
|---|---|---|
| Olho | Esclera círculo `r` em `superficie`; **íris = pupila**: um círculo `0,50r` (0,56 feliz; 0,58 triste) em `Cores.tinta`; 2 brilhos; sem cor de íris, sem fenda. Igual nas 9 espécies (a coruja só troca o fundo) | `_olho`, `5931-6056` |
| Boca | Booleana: aberta = meia-elipse `0,8w × 9`; fechada = 5 arcos por humor. Nada por espécie, fora a cor no buldogue | `_boca`, `6083-6158` |
| Bigodes | 3 cúbicas de 19 px, traço 1,2, `sombraForte` a 50% | `_bigodes`, `6203-6223` |
| Bochecha | Oval 14 × 8 em `acento` a 24% | `_bochecha`, `6191-6199` |
| Cochilo | Corpo gira −0,16 rad e desce `_afundaDeitado = 20`; **nenhuma pose própria** para gata, raposa ou buldogue | `2430`, `2781` |
| Passo | `_saltita` = capivara, **gata, raposa, buldogue**, lontra, coruja: cada passo é um arco de 7 (12 correndo), com achata/estica de borracha | `2771-2777`; `motor_de_vida.dart:1224-1244` |
| Gestos ociosos | `espreguica, sacode, olhaEmVolta, coca, fareja, saltinho` — os mesmos para todos | `50-58` |
| Caça | `cat` e `fox`: `espreita 0,8 s, velocidade 50, saltita`; `frenchie`: `velocidade 58, saltita` | `989-1005` |
| Repertório | gata: `piscadaLenta, amassar, alisar, sonhoDePatinhas`; raposa: `escutar, sonhoDePatinhas`; buldogue: `inclinarCabeca, sonhoDePatinhas` | `1040-1050` |
| Piscar | mediana 4,6 s (gata, raposa, coruja), 3,0 s (buldogue) | `1053-1056` |
| Bote | ao chegar a 70 px da bola: `achata 0,8`, `reverencia 0,9`, quadril e `rebola = sin(20t)` por 0,8 s, depois `pula(260)` com `vx` até a bola | `motor_de_vida.dart:1827-1852` |
| `alisar` | cabeça vira `0,16·lado`, desce 5; boca `0,25 + 0,3·|sin 16t|`; olhos meio fechados; 1,6–6 s | `episodios.dart:384-386`, `782-790` |

### 1.2 Gata — `_gata` (`pet.dart:3986-4182`)

- Cauda: traço de **11 px** na cor do pelo, de (26, 40) até a ponta por humor
  (`3997-4003`): radiante (52, −34) com gancho 1,0; contente (60, −14) 0,5;
  neutro (64, 4) 0,2; sono (40, 52) e saudade (46, 50) sem gancho; anéis de
  3 px em `sombra` a 70% a cada 13 px da metade para a ponta. Balança com
  `pose.cauda` (ou `pernas × 1,5` brincando).
- Patas 16 × 12 em (±19, 49). Corpo bolha **80 × 70** em (0, 20); barriga
  `claro` 54 × 53.
- Cabeça bolha **82 × 69**, deslocada −28. Orelhas (`4077-4116`): triângulo
  com base em y = −14 (x 14..34 → **20 de base**) e ponta em (27, −50) →
  **36 de altura = 52% da altura da cabeça, 44% da largura**; concha
  `lerp(sombra, acento, 0,30)`; giro por humor −0,04 / 0 / 0,10 / 0,30 /
  **0,40 rad (23°)** para os lados; tremor `pose.orelha × 0,6`.
- "M" da testa (5 segmentos, traço 2,8 a 60%) e 2 listras por têmpora.
- Focinheira `claro` 34 × 20 em (0, 15). Bigodes em (±19, 11). Nariz em
  coração **8 × 7** `#D67F74` de y 5,8 a 12,5. Boca em (0, **17**), w = 20:
  **4,5 px de vão** entre nariz e boca, sem filtro. Olhos r 7,5 em (±19, −6):
  38 entre centros = **46% da largura da cabeça**. Bochechas em (±30, 12).

### 1.3 Raposa — `_raposa` (`pet.dart:4192-4392`)

- Cauda em pluma (`4213-4234`): de (18, 44) a (74, 2 + ergue), `ergue` por
  humor −12 / 0 / 4 / 12 / 16; barriga da cauda em `sombra`; **ponta branca =
  disco r 16** em `_brancoDaRaposa` (`lerp(superficie, pelo, 0,06)`).
- Patas 16 × 12 em `sombraForte` (as "meias"). Corpo bolha 78 × 70; babador
  branco de (−24, −6) a (0, 50).
- Cabeça bolha **80 × 66** em (0, 3). Orelhas (`4293-4328`): base x 14..38
  (**24**), ponta (30, −48) → **38 de altura = 58% da cabeça**; três camadas:
  pelo, concha `claro`, **ponta `sombraForte` desenhada na face da frente**
  (`4318-4326`); giro −0,05 / 0 / 0,12 / 0,38 / **0,48 rad (27°)**.
- Máscara branca (`4346-4356`): de y 7 até 40 em **toda a largura** (−42..42),
  com o V entre os olhos. Focinho em V branco de y 6 a 28, 32 de largura.
  **Nariz 13 × 10 em (0, 9)** — no **topo** do V; boca em (0, **19**), w 20,
  a meio caminho do V. Olhos r 7,5 em (±19, −4), pupila redonda. **Sem
  bigodes, sem pernas** (só patas), sem faixa escura do olho ao nariz.

### 1.4 Buldogue — `_buldogue` (`pet.dart:4503-5172`)

- Tronco em pera invertida (`4548-4556`): ombro ±53 em y 13, cintura ±30
  em y 54. Pernas 21 × 42 em (±31, 39), topo quase reto, deslocam
  `passo × 0,9`. Patas 27 × 15 em (±31, 55). Peito 46 × 58. Vinco do ombro
  por `_dobraDaPele` (0,7).
- Cabeça (`4705-4713`): ±46 no topo, **±48 na bochecha**, y −21..46
  (**96 × 67**). Orelha de morcego (`4771-4822`): base **34** (x 12..46),
  altura **49**, calota larga; `tomba` 0 / 0,05 / 0,18 / 0,58 / **0,82 rad
  (47°)** e 0,62 no cochilo, encolhe 20% ao tombar.
- Olhos r **8,6** em (±27, **2**): 54 entre centros = 56% da largura; esclera
  branca cheia com pupila `0,50r` — **o maior anel branco do elenco**.
- Nariz 27 × 17 em (0, 14) com narinas em vírgula; "corda" 40 × 12 em
  (0, 2); focinheira 56 × 26 em (0, 27) rasa; beiços 33 × 25 em (±16, 30);
  filtro de y 22 a 27; boca em (0, 30), w 30, em `tinta`; **dentinhos 5,6 × 6
  em (±4,4, 34) sempre visíveis** a partir do estágio jovem (`5060-5075`);
  língua 19 × (9 + 14·quanto) só no radiante ou `gosto > 0,5`, oscilando
  `respiro × 1,6` (`5089-5117`); sobrancelhas por humor (dentro, fora):
  radiante (−3,5, −3), contente (−1,5, −1,5), neutro (0, 0), sono (1,5, 3),
  saudade (**−5,5, 2,5**) (`5129-5149`). Máscara do fulvo até ±31, y −6..42.
- Sem cauda (decisão explícita, `4437-4439`). Sem `rema` (não nada).

### 1.5 O que a folha da raposa mostra (`bicho-fox.webp`, medido)

| Par de quadros | Diferença | Leitura |
|---|---|---|
| fala contente nv0 × nv1 | **0,03%** | mesma boca fechada |
| fala contente nv1 × nv2 | 0,79% | a boca abre |
| fala contente nv2 × nv5 | **0,14%** | mesma boca aberta (binária) |
| susto-0 × contente-0, alinhados | 14,6% (21% na cabeça) | é o **estica**: caixa 353 × 393 → 327 × 426 (w/h 0,90 → 0,77); orelhas e cara alongadas, expressão igual |
| festa-0 × radiante-0, alinhados | 0,0% dentro da silhueta | só brilhos fora dela (caixa 542 × 423 por causa das estrelas) |

`corre-fox.webp` (24 quadros) e `anda-fox.webp` (20): a raposa corre e anda
**aos saltinhos de frente**, com a cauda chicoteando — nenhum quadro mostra
o dorso flexionando nem as pernas; não há vista de perfil.

---

## 2. O que as fontes dizem

### 2.1 Desenho infantil vetorial: o que os estúdios fazem

- [F] Bluey, guia do diretor de arte [18]: círculos "amigáveis e suaves",
  triângulos "afiados e agressivos", quadrados "firmes"; "**não usar line-art
  preta**", colorir o contorno "relativo ao objeto e à luz"; "evitar tons
  neutros de sombra", "sempre errar para o mais colorido"; objetos "fofos,
  simplificados e *chunky*"; na bíblia de estilo: "**nada de piada literal de
  cachorro** — pequenos acenos ao fato de serem cães, sim; nada 'na cara'".
- [F] Bluey, Annecy 2023 [19]: "sendo um show de recorte (*cutout*), os
  personagens precisavam ser **geométricos e simples**"; "os rigs foram
  **intencionalmente limitados**, o que os torna muito eficientes"; "as
  crianças sentem mais as cenas quando a animação é ótima".
- [F] Hey Duggee [20]: começaram com "formas geométricas básicas" e "jogaram
  uns olhos e bocas"; Duggee, o mais detalhado, "é o pior de animar: basta
  mover um pouco as feições para ele sair completamente do modelo";
  detalhe demais com seis personagens "congestiona e confunde as crianças".
- [F] Simon's Cat [21]: "não tem diálogo, então depende muito da **linguagem
  corporal**"; "linguagem corporal, em animais pelo menos, é **universal** e
  entendida em qualquer lugar do mundo"; o gato nasceu do gato real do
  autor (Hugh); vocabulário = "ruídos, ações e linguagem corporal".
- [F] Preston Blair [16]: personagens construídos de "**formas arredondadas**"
  porque animam melhor e fazem *follow-through*; "estude a fórmula básica e
  **desenhe este cão em outras posições**"; "faça um ciclo de **corrida deste
  buldogue**" (remete aos "movimentos da figura de quatro patas"); fórmula
  do fofo: "testa alta", "olhos baixos na cabeça, grandes e afastados",
  "nariz e boca sempre pequenos", "orelhas pequenas", "sem pescoço",
  "**corpo em pera**", "*sway back*".
- [F] Muybridge, *Animal Locomotion* (1887) [17]: pranchas 716 ("gata
  andando → galopando"), **717** ("gata trotando → galopando", 16,7 × 40,7 cm,
  domínio público) e 720 (galope): a referência pública para o andar, o trote
  e o galope da gata de perfil.

### 2.2 Gata (*Felis catus*)

- [F] **Pupila** [9]: fendas verticais são dos "predadores de emboscada
  ativos dia e noite"; a pupila da gata varia **135 vezes** de área entre
  contraída e dilatada (humano: 15); entre 65 predadores de emboscada de olho
  frontal, 44 têm pupila vertical e 82% desses têm ombro abaixo de 42 cm —
  a fenda é dos bichos **baixos**; a fenda "maximiza os dois sinais" de
  distância (disparidade e desfoque).
- [F] **Bigodes** [10]: crescem em grade, "mais curtos na frente, mais longos
  atrás"; há bigodes também acima dos olhos, no queixo e **no carpo**; "se
  estendem mais ou menos à **largura do corpo**"; "**se curvam para a frente
  quando o gato dá o bote**"; a gata não "varre" os bigodes como o rato, mas
  os move com músculos na base (bocejando, joga-os para a frente).
- [F] **Anatomia** [11]: cada orelha é movida por **15 músculos** em quatro
  grupos, independentes uma da outra; "a maioria dos gatos tem orelha reta e
  triangular"; coluna com 7 cervicais, **13 torácicas, 7 lombares** (mais que
  o humano), cauda com 19 a 23 vértebras, "muito flexível"; anda **sobre os
  dedos** (digitígrada), 5 dedos na frente e 4 atrás; o dorso "curva para
  cima" e "oscila ao longo da linha vertebral"; pele solta, scruff.
- [F] **Sinais** (Cats Protection [5]): relaxada = "orelhas para a frente e
  **arredondadas**", "bigodes relaxados, junto à cara", piscada lenta, cauda
  erguida; curiosa = "orelhas para a frente e **pontudas**, pupilas pequenas,
  bigodes apontados para a frente"; ansiosa = "**uma** orelha virada de lado,
  pupilas grandes"; deprimida = "orelhas para a frente mas **caídas**, olhos
  abertos olhando para baixo, bigodes caídos"; estressada = orelhas de lado
  ou para trás, pelo arrepiado, "lamber os lábios demais".
- [F] **Sinais** (RSPCA [6]): feliz em pé = "cauda **erguida com a ponta
  curva**"; sentada = "cauda solta, afastada do corpo"; "**boca fechada**";
  deitada de barriga para cima = conforto; preocupada = "orelhas um pouco
  giradas de lado", "pupilas dilatadas", cauda "enfiada no corpo"; brava =
  "boca **aberta e tensa**, dentes à mostra", orelhas "achatadas ou baixas e
  para o lado", "pata da frente ligeiramente erguida"; marcando = "cauda em
  pé e **tremendo**".
- [F] **Comunicação** (Wikipedia, citando Moelk e outros [7]): o **miado** é
  dos "sons produzidos com a boca **primeiro aberta e depois fechada
  gradualmente**"; existe o "miado mudo" (abre a boca sem som); **ronronar e
  trinado são de boca fechada**; o chilrear (*chirp*) é com a boca "tensa e
  parada"; cauda vertical = emoção positiva, "**tremendo**" ao cumprimentar =
  felicidade extrema; meio-erguida = menos prazer; "balanço lento e
  preguiçoso" = relaxada; "ponta que treme" = caça, alerta ou brincadeira;
  orelhas eretas = alerta, "achatadas" = defesa; amassar "costuma preceder o
  sono"; espreguiçar = relaxada; dorso arqueado + pelo em pé + corpo de lado
  = medo/agressão.
- [F] **Cara de dor** (Feline Grimace Scale [8], 5 unidades, 0–2): **0** =
  orelhas para a frente, olhos abertos, focinho relaxado (**redondo**),
  bigodes **soltos e curvos**, cabeça **acima** da linha dos ombros; **2** =
  orelhas **achatadas e giradas para fora**, olhos **apertados**, focinho
  tenso (**elíptico**), bigodes **retos e apontados para a frente**, cabeça
  **abaixo** dos ombros ou virada para baixo; total ≥ 4/10 = analgesia.
  [I] É a lista do que a "saudade" e o "sono" **não** podem parecer.
- [F] **Lamber** [12]: a gata passa "**entre 30 e 50% do dia** se limpando".
- [O] **Cores** (foto de gata laranja-e-branca, folhas secas [22]): flanco
  **#C18B54** (29%), #CD9E67, claro #DBB180, listra **#97633B**; testa com o
  "M" #BB804E / #A56A3C / listra #804621; peito branco **#E1E6EA** / #FEFDFC;
  nariz **#A76D54** (rosa-tijolo), borda #D6C1B7; olho verde-amarelo #B09775
  / #9D7956; orelha interna #9F654D com rosa #B5917F. A paleta do app
  (`tokens.dart:195-202`: #C9964F, #A97D3E, #DCB176…) é **mais amarela e
  mais saturada**; o nariz do app (#D67F74) é mais rosa que o real.

### 2.3 Raposa-vermelha (*Vulpes vulpes*)

- [F] **Forma** [3]: corpo 45–90 cm, cauda 30–55,5 cm (**≈ 62–70%** do
  corpo), **orelhas 7,7–12,5 cm**, ombro 35–50 cm, 2,2–14 kg; "muito mais
  leve de osso" que um cão do mesmo tamanho; crânio com "focinho **mais
  estreito**" e "perfil **côncavo**"; pupilas "**ovais, verticais**"; olhos
  azuis ao nascer, **âmbar** a partir das 4–5 semanas.
- [F] **Cor** [3]: branco no **queixo, lábios inferiores e superiores,
  garganta, frente do peito e ponta da cauda**; preto nas **patas** e no
  **dorso das orelhas** ("preto ou castanho-avermelhado"); membros
  superiores ruivos; parte de baixo da cauda cinza-pálida; mancha preta na
  base da cauda (glândula).
- [F] **Movimento** [3]: trote a 6–13 km/h, **máximo 50 km/h**, passada de
  25–35 cm; salta cercas de **2 m**; no bote em roedores "localiza a presa
  pelo **som**, salta **alto** por cima dela, **dirige no ar com a cauda** e
  pousa no alvo a até **5 m**".
- [F] **Mergulho na neve** [4]: a raposa "assume a postura, salta para cima
  e **mergulha de cabeça**"; altura máxima do salto "**50 a 60 cm acima da
  neve**"; impacto "**até 4 m/s**"; a cabeça entra "quase na vertical", o
  **focinho primeiro**, e depois as patas da frente empurram o corpo para
  baixo; o "focinho fino e estreito" é o que permite o gesto (um focinho 25%
  mais curto dobra o impulso de impacto); audição mais sensível entre **2 e
  10 kHz**, ouve a presa "sob vários pés de neve".
- [F] **Voz** [3]: 12 sons de adulto e 8 de filhote; o *gekkering* é "um
  chocalhar gutural, parecido com uma catraca".
- [O] **Cores** (foto na neve, luz difusa [22]): dorso **#995329** (33%),
  #904C25, #7B3F1F, flanco #A86232; focinho ruivo #AC703D / #BC824E; bochecha
  branca-cinza **#C4C0AE** / #DDDAC8; garganta no limite ruivo/branco
  #884420 / #ADA99A; **meia preta #191919**; cauda (este indivíduo tem cauda
  escura) #4A3424, ponta #9C8C6F na sombra; **íris #AF683B / #CF8E56**
  (âmbar); nariz #232121. A paleta do app (`tokens.dart:205-212`: #C4663D,
  #A85330, #D8845C…) é **mais alaranjada e mais clara** que o dorso real,
  que é um ruivo-queimado; e o app não tem cinza-creme para a bochecha.

### 2.4 Buldogue francês

- [F] **Padrão AKC** [1] (frases exatas): "cão ativo, inteligente, musculoso,
  **de osso pesado**, pelo liso, **compacto**"; "as marcas da raça são a
  **cabeça quadrada com orelhas de morcego** e o **dorso arqueado**"; "expressão
  alerta, curiosa e interessada"; cabeça "grande e quadrada"; olhos "escuros,
  castanhos ou quase pretos, **bem afastados, baixos no crânio, o mais longe
  possível das orelhas**, redondos, de tamanho moderado, nem fundos nem
  saltados"; "**sem haw e sem branco do olho à vista** olhando para a frente";
  orelha "de morcego: **larga na base, alongada, topo redondo**, alta na
  cabeça mas **não muito junta**, ereta, com a abertura para a frente"; "topo
  do crânio **plano** entre as orelhas; testa não plana, **levemente
  arredondada**"; focinho "largo, fundo e bem recuado; músculos da bochecha
  bem desenvolvidos"; "stop bem definido, causando um **sulco** entre os
  olhos, com **rugas pesadas formando um rolo macio** sobre o nariz
  extremamente curto"; "narinas largas com uma **linha bem definida** entre
  elas"; nariz preto; beiços "pretos, grossos e largos, **pendendo sobre a
  mandíbula** dos lados, encontrando o lábio inferior na frente e **cobrindo
  dentes e língua, que não se veem com a boca fechada**"; mandíbula "funda,
  quadrada, larga, **prognata** e bem virada para cima"; pescoço "grosso e
  bem arqueado com **pele solta na garganta**"; dorso "arqueado (*roach*)…
  lombo **mais alto que o ombro**"; peito "largo, fundo e cheio"; cauda
  "reta ou em parafuso, curta, **baixa**"; "pernas da frente curtas, grossas,
  retas, musculosas e **bem afastadas**"; "pernas de trás **mais longas** que as
  da frente"; pele "macia e solta, sobretudo na cabeça e nos ombros, formando
  rugas"; cores aceitas "branco, creme, fulvo (do claro ao **fulvo-vermelho**)"
  com "tigrado, pied, **máscara preta**, sombreado preto, marcas brancas";
  desqualificam "preto sólido, preto-e-castanho, preto-e-branco, **azul**,
  azul-fulvo, fígado e merle"; passo: "**quatro trilhas**, com a trilha da
  frente **mais larga** que a de trás; alcance e impulso; **desimpedido, livre
  e vigoroso**"; temperamento "afetuoso, ativo, alerta e brincalhão, mas não
  excessivamente agitado"; até 28 lb (12,7 kg).
- [F] **O "rolar" é do buldogue inglês** [2]: "estilo e porte peculiares,
  **passo solto nas juntas, arrastado, de movimento lateral**, dando o
  característico '*roll*'"; o inglês tem "papada com duas dobras soltas e
  pendentes", "cabeça e cara cobertas de rugas pesadas", mandíbula "muito
  larga, quadrada e prognata".
- [F] **Sinais de cão** (RSPCA [13]): feliz/relaxado = "boca **aberta e
  relaxada**", orelhas naturais, cauda abanando; convite a brincar =
  "**traseiro erguido**", cauda alta abanando, latido animado; preocupado =
  "orelhas **coladas para trás**", cauda "enfiada", bocejo, lamber os lábios,
  cabeça baixa ou virada, "**pata da frente erguida** (sentado)"; bravo = nariz
  "franzido e rígido", lábios para trás com dentes, pupilas grandes.
- [F] **Ofego** [14]: cães ofegam a **5,33 ± 0,7 ciclos/s**, igual à
  frequência natural do sistema respiratório deles (5,28 ± 0,3 Hz); "a
  impraticabilidade de ofegar em outras frequências é demonstrada por
  cálculo". [F] Em repouso: **18–34 respirações/min**, 70–120 batimentos/min
  [15]. (O laudo 08 já trouxe o alerta: para o braquicefálico, ruído
  respiratório é sintoma; o ofego aqui é **curto, mudo e só depois de
  correr**.)
- [O] **Cores** (foto de fulvo com máscara ao sol forte [22]): fulvo ao sol
  **#D69653** / #EEB572 (estourado), ombro em meia-luz **#BE9068** / #EBBD8C;
  máscara **#5F4A44** → #34231E; orelha interna rosa **#F6C9B9** / #CD9887 /
  #B88272; peito branco na sombra #C4B0A4; nariz **#241A1A**. (Foto de tigrado
  ofegando [22]: língua #A8899A na sombra — um rosa-malva; corpo tigrado
  #3B4138 / #20251E com verde refletido da grama.) A paleta do app
  (`tokens.dart:227-234`: fulvo #CBA274, fulvo escuro #A9773F) está **mais
  bege e menos laranja** que o fulvo real; a língua do app
  (`lerp(acento, superficie, 0,28)`) é mais clara e mais fria que a real.

---

## 3. Avaliação do desenho atual, traço a traço

### 3.1 O que vale para os três

| # | Observação [O] | Por que é fraco [F] | Onde |
|---|---|---|---|
| G1 | Pupila redonda `0,50r` em `tinta`, sem íris, nas 3 espécies. | Gata: fenda vertical que **dilata 135×** [9]; raposa: pupila "oval vertical" e íris **âmbar** [3]; buldogue: olho "escuro… **sem branco à vista**" [1]. O olho é 46% do olhar da criança (Borgi, laudo 31) e aqui ele não diz a espécie. | `_olho`, `5931-6056` |
| G2 | Boca binária (0,03% / 0,14% entre níveis na raposa). | Laudos 30 e 31 (R1) já trataram; vale igual para os três. | `_boca` |
| G3 | Susto = estica do corpo; festa = brilhos. | Laudo 31 (R3, R4); medido aqui para a raposa (§1.5). | `2497-2509` |
| G4 | Cochilo = corpo girado −0,16 e 20 px mais baixo, nas 3 espécies. | Gata "amassa antes de dormir" e **enrola** [7]; raposa de cauda sobre o nariz (laudo 08); buldogue em esfinge (08 R7). Sem pose, "sonolento" vira "sentado de olho fechado". | `2430`, `2781` |
| G5 | Mesmos 6 gestos ociosos para todos (`espreguica`, `coca`, `fareja`…). | Simon's Cat: tudo é linguagem corporal [21]; Bluey: "acenos" à espécie [18]. O que diferencia os três é **como** se espreguiçam, lambem e andam, e isso não existe. | `50-58` |
| G6 | Os três andam e correm **aos saltinhos** de frente. | Gata e raposa **trotam** (Muybridge 717 [17]; raposa trota a 6–13 km/h [3]); buldogue tem passo "livre e vigoroso" de **osso pesado** [1], não de coelho. | `2771-2777`, `989-1005` |

### 3.2 Gata (Mel)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Orelha | Triângulo 20 de base × 36 de altura (52% da cabeça), ponta fina, concha rosada; gira para os lados até 0,40 rad; treme | "Reta e triangular" [11]; relaxada = "para a frente e **arredondada**"; curiosa = "para a frente e **pontuda**"; ansiosa = "**uma** de lado" [5]; dor = "achatada e girada **para fora**" [8] | **Bom** na forma. Falta a diferença **relaxada × curiosa** (ponta arredondada × pontuda) e a "uma orelha de lado" da atenção; e 0,40 rad para fora na saudade encosta no AU2 do FGS (R9) |
| Pupila/íris | Círculo escuro 0,5r | Fenda vertical, 135× de dilatação [9]; "pupilas pequenas" = relaxada/curiosa, "grandes" = ansiosa [5] | **Errado**: é o traço que mais diz "gata" no close e o que dá o "olho de caça" no bote (R1) |
| Bigodes | 3 fios de 19 px, **dentro** do contorno (ponta x 38 < 41), 50% de alfa | À "largura do corpo" [10]; "junto à cara" relaxada, "para a frente" curiosa/bote [5][10]; "soltos e curvos" = sem dor [8] | **Errado**: não se vê na home; sem leitura de humor (R2) |
| Nariz e boca | Coração 8 × 7 rosa; boca a 4,5 px, sem filtro; 5 arcos genéricos | Focinho "redondo" = relaxado, "elíptico" = dor [8]; miado = abre e fecha **gradualmente**; ronronar de boca **fechada** [7]; feliz = "boca fechada" [6] | Fraco: falta o "ω" (filtro + dois arcos) que é a assinatura felina em vetor; a boca aberta genérica não tem gradação (R2, R11) |
| Cauda | Traço 11 na cor do pelo, anéis, gancho por humor; balanço por `pose.cauda` | "Erguida com a ponta curva" = feliz [6]; "**tremendo**" = saudação [6][7]; "ponta que treme" = caça [7]; "balanço lento" = relaxada [7] | **Bom** (08 R6 feito). Faltam os **3 ritmos** (tremor de saudação, *twitch* de ponta, balanço lento) (R8) |
| Corpo e patas | Bolha 80 × 70, patas 16 × 12, sem pernas; sentada sempre | Digitígrada, coluna de 13 + 7 vértebras "muito flexível", dorso que "curva para cima" [11]; espreguiçar = relaxada [7]; 30–50% do dia lambendo [12] | Fraco: o corpo não faz nada felino: nem arco, nem espreguiça frente-baixa, nem pata na cara (R3) |
| Marcas | "M" da testa, listras das têmporas, anéis | Foto: "M", listras no flanco, peito e patas brancos [22] | Bom. [I] Uma pelagem **laranja-e-branca** (peito e patas brancos) daria a Mel mais contraste na home |
| Cor | #C9964F, nariz #D67F74 | flanco #C18B54, listra #97633B, nariz #A76D54, peito #E1E6EA [22] | Meio: o pelo está mais amarelo; o nariz rosa-doce funciona no fofo, mas um tijolo (#B8775E) lê mais gata (R10) |

### 3.3 Raposa (Faísca)

| Traço | App hoje [O] | Real [F] | Veredito |
|---|---|---|---|
| Orelha | Base 24 × altura 38 (58% da cabeça); concha clara; **ponta escura na face da frente**; gira até 0,48 rad | Orelhas 7,7–12,5 cm, **dorso preto** [3]; na foto, o preto só aparece **de trás/da ponta**, a concha é creme [22] | Meio: tamanho certo; o escuro deveria ser o **dorso** (aparecer quando a orelha gira de lado) e não um lobo frontal (R5) |
| Focinho | V branco de y 6 a 28; **nariz no topo do V** (y 9), boca em y 19 | Focinho "**mais estreito**", perfil côncavo [3]; "fino e estreito" é o que permite mergulhar [4]; o nariz é a **ponta** do focinho | Fraco: de frente o nariz precisa estar no **terço inferior** da cara, com o V branco em volta e a boca logo abaixo (R5) |
| Máscara | Branco de y 7 a 40 em toda a largura + babador até y 50 | Branco em queixo, lábios, garganta, peito [3]; **bochecha cinza-creme** #C4C0AE, **faixa escura do olho ao nariz** na foto [22] | Meio: o branco está certo onde está, mas sem a faixa escura e sem o cinza da bochecha a cara vira "panda" claro (R5) |
| Olho | Redondo, pupila círculo | "Oval, vertical"; íris âmbar [3]; #CF8E56 [22] | **Errado** (R1/R5) |
| Pernas | Só patas 16 × 12 em `sombraForte` | Meias pretas até o "joelho" [3][22]; "muito mais leve de osso" [3] | Fraco: sem perna a meia some; o corpo bolha é o de um urso (R5) |
| Cauda | Pluma com ponta branca r 16; `ergue` por humor | 62–70% do corpo, ponta branca [3]; "dirige no ar com a cauda" [3] | **Bom** (08 R5 feito). Falta a cauda **ereta no ar** durante o bote (R4) |
| Bote | O do gato: agacha, rebola, salta **para a frente** até a bola | "Salta para cima e mergulha de cabeça"; pico 50–60 cm; focinho entra na vertical [4]; pousa a até 5 m [3] | **Errado** no gesto: é o movimento mais reconhecível da espécie e o app usa o felino (R4) |
| Escutar | `Episodio.escutar` gira as orelhas | "Localiza a presa pelo som" [3]; pico 2–10 kHz [4] | Bom: é a antecipação natural do bote (R4) |
| Cor | #C4663D | dorso #995329, flanco #A86232, meia #191919, bochecha #C4C0AE [22] | Meio: mais laranja que o real; sem cinza-creme (R10) |
| Bigodes | Nenhum | Tem, mas curtos e escuros; nos desenhos infantis quase nunca aparecem [I] | Certo manter sem |

### 3.4 Buldogue (Bolota)

| Traço | App hoje [O] | Padrão/real [F] | Veredito |
|---|---|---|---|
| Orelha | Base 34 (35% da cabeça), altura 49, calota larga; tomba até 0,82 rad; concha escura | "Larga na base, alongada, **topo redondo**, alta, **não muito junta**" [1]; concha **rosa** #F6C9B9 na foto [22] | **Bom**. [I] A concha em `lerp(sombraForte, acento, 0,28)` sai marrom; a real é rosa-pele |
| Olho | r 8,6 em y 2, **alto**; esclera cheia, pupila 0,5r | "**Baixos** no crânio, o mais longe possível das orelhas", "**sem branco do olho à vista**" [1]; íris escura | **Errado**: o anel branco grande é olho de desenho genérico; o padrão pede olho escuro e cheio (R7) |
| Stop, rolo, rugas | Sulco, rolo 40 × 12, testa vincada por humor, `_dobraDaPele` | "Sulco entre os olhos, rugas pesadas formando **rolo macio**" [1]; "pele solta… formando rugas" | **Bom**, é o melhor pedaço do elenco |
| Beiço e dentes | Dois lobos 33 × 25; **dentinhos sempre à mostra** | Beiços "cobrindo dentes e língua, **que não se veem com a boca fechada**" [1] | Meio: o prognatismo lê a raça, mas o padrão diz que o dente não aparece de boca fechada. [I] Mostrar só com a boca aberta ou no sorriso radiante (R7) |
| Língua | Só radiante; balança com a respiração | Feliz = "boca aberta e relaxada" [13]; ofego a 5,3 Hz [14] | Meio: falta o ofego **curto** pós-corrida e a língua no "contente" com carinho (R6) |
| Corpo e pernas | Pera invertida ±53 → ±30; pernas 21 × 42 bem afastadas | "Peito largo", "pernas da frente curtas, grossas, bem afastadas", "**lombo mais alto que o ombro**", "de trás mais longas" [1] | **Bom** de frente. [I] O *roach back* só apareceria de perfil; a novelinha não tem perfil (R12) |
| Passo | Saltinhos de 7 px, achata/estica de borracha | "Quatro trilhas, frente mais larga; alcance e impulso; livre e vigoroso" [1]; **não** é o "rolar arrastado" do inglês [2] | **Errado**: cão de osso pesado não quica como a lontra; a leitura de frente é o **rolamento de ombro** sobre a base larga (R6) |
| Sinais | Orelha + sobrancelha por humor; `inclinarCabeca` | "Traseiro erguido" = brincar; "pata da frente erguida" = preocupado [13] | Bom. Faltam o *play bow* e a pata erguida (R7) |
| Cor | #CBA274 fulvo | #D69653 / #BE9068, máscara #5F4A44, orelha #F6C9B9 [22]; azul e preto **desqualificam** [1] | Meio: fulvo mais laranja; comentário de `tokens.dart` sobre o padrão continua errado (08 R13) (R10) |

---

## 4. Recomendações priorizadas

Formato: **o que mudar · onde · aceite verificável · prioridade · fonte**.
Medidas em unidades do painter (cabeça da gata = 82 de largura; capturas da
novelinha a 3× = 543 px de quadro).

### R1 — Olho felino e olho de raposa: íris colorida + pupila por espécie (alta)

**O que mudar.** `_olho` ganha `estilo: EstiloDoOlho {redondo, fenda, oval,
cheio}` e `dilata` (0–1, do motor). Gata (`fenda`): íris disco `0,66r` em
`#9DB36A` (verde) ou `#D9A441` (âmbar) por pelagem; pupila **elipse
vertical** de largura `r·(0,14 + 0,56·dilata)` e altura `0,92r`, em `tinta`;
brilho grande sobre a pupila. `dilata` = 0,15 no contente/neutro (pupila
pequena = relaxada [5]), 0,6 na saudade e no escuro do habitat (noite),
**1,0** no susto e no bote (Banks: 135× [9]; Cats Protection: pupila grande =
ansiosa/brincadeira [5]). Raposa (`oval`): íris `0,66r` em `#CF8E56` [22],
pupila elipse 2 : 1 (largura `0,30r + 0,25r·dilata`, altura `0,8r`).
Buldogue (`cheio`): íris `0,78r` em `#3A2A22`, pupila `0,45r`, esclera só
como aro (padrão: "sem branco à vista" [1]); na saudade a pupila sobe
(olhar pidão, já existe) e a esclera aparece **embaixo** (é o "olho
marejado", não o "whale eye"). Piscada lenta da gata: pálpebra a 0,6 com a
fenda ainda visível.
**Onde.** `_olho` (`pet.dart:5931-6056`); chamadas em `4176-4177`, `4386-4387`,
`4755-4756`; `SaidaDaVida` (novo `dilata`), `motor_de_vida.dart` (susto, bote,
noite). **Aceite.** Golden `pet_cat_contente`: o componente escuro da pupila
tem altura/largura **≥ 3,0**; golden `cat_susto`: ≤ 1,3; a íris tem ΔE ≥ 25
em relação a `tinta`. Raposa: pupila com razão entre 1,6 e 2,4 e matiz da
íris entre 20° e 40° (HSL). Buldogue: esclera visível ≤ 30% da área do olho
no contente. **Fontes.** [9][3][1][5][22].

### R2 — Gata: bigodes que saem da cara e boca "ω" com filtro (alta)

**O que mudar.** `_bigodes` ganha `n`, `comprimento`, `cor`, `inclina`: na
gata 4 fios por lado, comprimento **34–38** (ponta em x ≥ 53, fora da
meia-largura 41 — "largura do corpo" [10]), espaçados 3 px, traço 1,3, cor
`#F4EBDD` a 85% nas pelagens escuras e `sombraForte` a 70% nas claras; em
repouso **caem** 0,12 rad (FGS 0: "soltos e curvos" [8]); `inclina` =
**+0,35 rad para a frente** na espreita/bote e no `escutar` ("se curvam para
a frente no bote" [10]; "apontados para a frente" = curiosa [5]); na saudade
e no sono, −0,2 rad (caídos: "deprimida = bigodes caídos" [5]) — nunca retos
para a frente nesses dois (seria AU "whiskers" 2 do FGS [8]). A boca: do
nariz desce o **filtro** (traço 1,2, 4 px) até a junção de dois arcos de raio
5 com os cantos 1 px acima (o "ω"); a abertura (laudo 31, R1) cresce **a
partir da junção**, para baixo, com o nariz e o filtro fixos. **Onde.**
`_bigodes` (`6203-6223`), `_gata` (`4159-4173`), `episodios.dart` (`escutar`,
bote). **Aceite.** Golden contente: ≥ 12 px de bigode **fora** da silhueta da
cabeça de cada lado (medir máscara alfa); na home a 280 px de largura os
bigodes têm contraste ≥ 3 : 1 com o pelo; no `cat_saudade` e `cat_sono` o
ângulo médio dos 4 fios é ≤ 0 (horizontal ou caindo); no `cat_bote` ≥ +0,25
rad; no contente, nariz + filtro + boca formam **um** componente conexo de
traço. **Fontes.** [10][5][8][6].

### R3 — Gata: três gestos de corpo (lamber, espreguiçar, rosquinha) (alta)

**O que mudar.** (a) **Lamber** substitui o `alisar` atual na gata: a pata
dianteira do lado sorteado sobe em arco até a bochecha (de (19, 49) a
(26, 2) em 0,25 s), a cabeça inclina 0,25 rad para o lado oposto e desce 4
px, a língua (oval 6 × 5 `#E57F78`) aparece 3 vezes a 2 Hz sobre a pata, e
depois a pata passa **por trás da orelha** (2 ciclos de 0,45 s, orelha
dobra 0,3 rad e volta); total 2,5–4 s; peso no sorteio de episódios **2×**
o dos outros (30–50% do dia [12]). (b) **Espreguiçar felino**: frente baixa e
traseiro alto: cabeça desce 10 px e avança 6, corpo escala (1,18, 0,86) com
volume preservado por 0,6 s, patas dianteiras esticadas 10 px à frente,
cauda em pé; depois o contrário (traseiro baixa, dorso **arqueia** 6 px —
"curva o dorso para cima" [11]); 1,4 s; dispara ao acordar (já há o gatilho
em `motor_de_vida.dart:1676-1679`). (c) **Rosquinha** no cochilo: corpo
elipse 92 × 46 em (0, 36), cabeça 0,9× apoiada no flanco direito (centro
(−22, 22), giro −0,35), cauda contornando a frente e fechando o círculo sob
o queixo, orelhas relaxadas 0,2 rad; **amassar** 3 vezes antes de deitar
("costuma preceder o sono" [7]; `Episodio.amassar` já existe).
**Onde.** `episodios.dart:782-790` (ramificar por espécie), `_gata` (pata
levantada, língua, pose de rosquinha), `GestoOcioso.espreguica` por espécie.
**Aceite.** Filmagem de 3 min de ocioso a 30 qps: ≥ 3 lambidas com a caixa
da pata acima da linha dos olhos (y da pata < y do olho) por ≥ 10 quadros;
na espreguiça a caixa do corpo fica ≥ 1,15× mais larga **e** ≥ 0,88× mais
baixa que em repouso por ≥ 15 quadros, com área ± 3%; golden `cat_cochilo`:
altura da caixa ≤ 70% da do ocioso e a cauda cruza a frente do corpo.
**Fontes.** [12][11][7][21].

### R4 — Raposa: bote de raposa, não de gato (alta)

**O que mudar.** `JeitoDeCacar` ganha `mergulhaDeFocinho: true` para `fox`
e o ramo do bote (`motor_de_vida.dart:1827-1852`) vira três fases: (1)
**escuta**: 0,8 s parada, as duas orelhas giram para o alvo (já há
`escutar`), cabeça inclina 0,2 rad para um lado e depois para o outro
(2 × 0,3 s), bigode nenhum, corpo não rebola (o rebolado é do gato); (2)
**salto**: `pula(340)` — o pico ≥ 0,9× a altura da silhueta (50–60 cm para
um ombro de 35–50 cm [4]) — com `vx` para pousar a 60–120 px à frente; no ar
o deformador gira o corpo até **−1,2 rad** no ápice (focinho para baixo,
"mergulha de cabeça" [4]) e a cauda sobe **ereta** acima da linha do dorso
(+30 px na ponta: "dirige no ar com a cauda" [3]); (3) **pouso de focinho**:
cabeça abaixo da linha das patas por 0,3 s (9 quadros), traseiro no alto,
cauda em pé, 3 tufos de capim (`_poeira` verde) saindo do ponto de impacto;
levanta a cabeça com ou sem a folha (sucesso sorteado 50%). O susto da
raposa (laudo 31 R3) reaproveita a fase 1: orelhas giram, corpo congela.
**Onde.** `motor_de_vida.dart:1827-1852`, `deformador.dart` (rotação do
corpo no ar), `_raposa` (cauda no ar), `pet.dart:989-993`. **Aceite.** Na
captura do bote a 30 qps: altura máxima do centroide do corpo ≥ 0,9× a
altura da silhueta parada; no ápice, o ângulo do segmento cabeça→corpo ≤
−60° em relação à horizontal (focinho abaixo do corpo); ≥ 8 quadros com o
centroide da cabeça abaixo do centroide das patas; a gata, no mesmo teste,
continua com pico ≤ 0,5× e sem rotação (os dois botes são distintos).
**Fontes.** [4][3][21].

### R5 — Raposa: nariz na ponta, dorso preto da orelha, pernas, bochecha cinza (alta)

**O que mudar.** Em `_raposa`: (1) o V do focinho desce e afina: de y 4 a
**32**, largura 30 em cima e 10 na ponta; **nariz 12 × 9 em (0, 24)** (terço
inferior da cabeça, que vai de −30 a 36), boca em (0, 30) w 16 (pequena
[16]); (2) **faixa escura** do canto interno do olho ao nariz, traço 3 px em
`lerp(pelo, tinta, 0,35)` a 60% (foto [22]); (3) a bochecha deixa de ser
branca: de y 7 a 40 passa a `#C4C0AE` (cinza-creme [22]) e o **branco** fica
só no queixo, lábio e garganta (bolha 36 × 22 em (0, 30)) ligado ao babador;
(4) a orelha perde o lobo escuro frontal: a concha fica `claro`, e o
**dorso** `sombraForte` é um recorte de 6 px na borda externa que **cresce com
o giro** (`abre`): a 0,48 rad o dorso aparece como uma faixa de 14 px
("orelha de avião" mostra a parte de trás); (5) **pernas**: duas colunas
12 × 22 em (±19, 36) em `sombraForte` (meias [3]) atrás das patas, visíveis
no ocioso e no bote; (6) corpo 72 × 72 (`topo 0,92`): a raposa é "muito
mais leve de osso" que um cão [3] e hoje tem o corpo da gata. **Onde.**
`pet.dart:4236-4392`. **Aceite.** Golden `fox_contente`: centro do nariz a
≥ 0,75 da altura da cabeça a partir do topo (hoje ≈ 0,59); região `#C4C0AE`
com ≥ 300 px² entre olho e queixo; golden `fox_saudade`: faixa `sombraForte`
na borda externa de cada orelha com ≥ 60 px²; IoU da silhueta raposa × gata
(método do laudo 06) ≤ 0,72; teste de 5 s com 10 pessoas: ≥ 8 dizem
"raposa". **Fontes.** [3][4][22][16].

### R6 — Buldogue: passo plantado com rolamento de ombro, e ofego curto (alta)

**O que mudar.** `_saltita` e `JeitoDeCacar` passam a `saltita: false` para
`frenchie`; o gingado de frente ganha parâmetros por espécie: amplitude
lateral **0,09 rad** (2× os 0,045 de `motor_de_vida.dart:1274`), cadência
**2,2 passos/s** andando e 3,2 correndo, quique vertical ≤ 3 px (osso
pesado [1]), e as **pernas** 21 × 42 alternam: a de apoio desce 2 px e a
livre sobe 6 px e avança 5 (hoje só `desloca`); a cabeça pende 2 px para o
lado do apoio (o "rolamento" que se lê de frente numa base larga: "trilha
da frente mais larga" [1]). Nada de "arrastar de lado" (isso é o inglês
[2]). Depois de correr > 2 s (`_correndo`): **ofego** de 2–3 s: `boca 0,45`,
língua para fora, oscilando **5,3 Hz** [14] com ±2 px, peito +1 px na mesma
frequência; nunca no cochilo, nunca na saudade, sem som de chiado (laudo
08). A língua também aparece no contente a partir de `gosto > 0,3` ("boca
aberta e relaxada" = feliz [13]).
**Onde.** `pet.dart:2771-2777`, `1001-1002`; `motor_de_vida.dart:1207-1290`
(parâmetros por `jeito`); `_buldogueCorpo` (`4620-4656`); `_linguaDoBuldogue`
(`5089-5117`). **Aceite.** Filmagem a 30 qps andando: deslocamento vertical
do centroide ≤ 4 px por passo (sem arco de salto) e rolamento do corpo
≥ 0,08 rad de pico; as duas pernas têm fases opostas (correlação ≤ −0,8);
após 2 s de corrida, a ponta da língua tem 4,5–6 ciclos/s por ≥ 1,5 s e o
episódio termina em ≤ 3 s. **Fontes.** [1][2][14][13].

### R7 — Buldogue: olho e boca pelo padrão, play bow e pata erguida (média)

**O que mudar.** (1) Olhos descem de y 2 para **y 7** e vão a ±28 ("baixos,
o mais longe possível das orelhas" [1]); íris cheia (R1); (2) **dentinhos só
com a boca aberta** (`abre > 0,15`) ou no sorriso radiante — de boca fechada
os beiços cobrem ("não se veem com a boca fechada" [1]); (3) **play bow** ao
tocar no radiante: peito desce 8 px, traseiro sobe 6 (escala do tronco
(1,04, 0,90) com pivô na cintura), patas dianteiras avançam 6, 0,5 s, cauda
não há — o quadril "rebola" ±3 px (laudo 08); (4) **pata erguida** na
saudade, sentado: a pata dianteira do lado sorteado sobe 5 px por 1,2 s a
cada 8–12 s ("pata da frente erguida" = preocupado/pedindo [13]); (5) concha
da orelha em `lerp(pelo, #F6C9B9, 0,55)` (rosa-pele [22]) nas pelagens
claras; (6) corrigir o comentário de `tokens.dart:214-234` (azul e preto
desqualificam [1]) — como escolha de produto podem ficar, mas sem afirmar o
padrão. **Onde.** `_buldogueCabeca` (`4755-4756`), `_focinhoDoBuldogue`
(`5060-5075`), `_buldogueCorpo`, `episodios.dart` (novo `playBow`,
`pataErguida`), `tokens.dart`. **Aceite.** Golden contente: centro do olho a
≥ 42% da altura da cabeça a partir do topo (hoje 34%); nenhum pixel
`superficie` na região dos dentes com a boca fechada; captura do play bow:
topo da caixa do corpo 6 ± 2 px mais baixo e base igual, por ≥ 12 quadros;
na saudade, 3 min: ≥ 10 quadros consecutivos com uma pata ≥ 4 px acima da
outra. **Fontes.** [1][13][22].

### R8 — Gata: os três ritmos da cauda (média)

**O que mudar.** A forma por humor fica; somam-se ritmos: (a) **tremor de
saudação** ao abrir o app ou ao tocar, com a cauda em pé: 12 Hz, ±2 px em
toda a cauda, 0,8 s ("em pé e tremendo" [6][7]); (b) ***twitch* de ponta**
na espreita e na brincadeira: só os 30% finais, 3 Hz, ±4 px ("ponta que
treme" = caça/brincadeira [7]); (c) **balanço lento** no contente/neutro:
0,25 Hz, ±6 px na ponta ("balanço lento e preguiçoso" [7]); (d) no sono e
na saudade: amplitude 0, cauda enrolada nos pés. **Onde.** `_gata`
(`3991-4023`), `motor_de_vida.dart` (`_cauda`, eventos de chegada).
**Aceite.** Captura a 30 qps: FFT do y da ponta da cauda tem pico entre 10 e
14 Hz na saudação (≥ 20 quadros), entre 2,5 e 3,5 Hz na espreita, ≤ 0,5 Hz
no contente; no cochilo, amplitude ≤ 1 px. **Fontes.** [6][7].

### R9 — Humor sem "cara de dor": régua do FGS para gata e raposa (média)

**O que mudar.** Usar a ficha de dor felina [8] como **lista negativa** da
saudade e do sono: orelhas abertas para os lados no máximo **0,35 rad** e
**nunca giradas para fora** (hoje gata 0,40, raposa 0,48 — reduzir), olhos
abertos (já), focinheira **redonda** (nunca achatar a bolha 34 × 20 na
saudade), bigodes caídos e curvos (R2), **cabeça na linha dos ombros**
(`_cabecaDesce` ≤ 2 px na saudade; o "olhar para baixo" vem só da pupila).
Na raposa, o mesmo com a orelha a 0,38 rad. **Onde.** `pet.dart:4068-4076`,
`4284-4292`, `_cabecaDesce`. **Aceite.** Três pessoas pontuam os goldens
`cat_saudade`, `cat_sono`, `fox_saudade` com a ficha FGS: total ≤ 2/10 em
todos (nenhuma unidade = 2). **Fontes.** [8][5].

### R10 — Cores medidas nas fotos, sombra fria (média)

**O que mudar.** Sem mexer nos índices persistidos, ajustar e acrescentar a
7ª entrada "real" por espécie:

| Espécie | entrada nova (pelo) | outros | sombra (fria) |
|---|---|---|---|
| gata | `#C18B54`; listras/anéis `#97633B`; claro `#DBB180` | nariz `#B8775E`; peito/patas brancos `#E1E6EA` (pelagem laranja-e-branca nova); íris `#9DB36A`/`#D9A441` | `lerp(pelo, #3B2A3A, 0,35)` |
| raposa | `#995329`; flanco `#A86232`; claro `#BC824E` | bochecha `#C4C0AE`; branco `#ECE9E0`; meias e dorso da orelha `#191919`; íris `#CF8E56`; nariz `#232121` | `lerp(pelo, #2B2F3A, 0,35)` |
| buldogue | fulvo `#D69653`; meia-luz `#BE9068` | máscara `#5F4A44`; orelha interna `#F6C9B9`; língua `#D98B96`; nariz `#241A1A`; peito branco `#F1E8E0` | `lerp(pelo, #3A2F3A, 0,35)` |

Valores com +8% de saturação sobre o medido (Bluey: "errar para o mais
colorido" [18]) [I]. `_sombraDoQueixo` passa a usar a sombra fria. **Onde.**
`tokens.dart:195-234`; `pet.dart` `_sombraDoQueixo`. **Aceite.** ΔE (CIE76)
entre a entrada nova e a mediana medida ≤ 12; matiz da sombra do queixo
≥ 15° diferente do pelo; contraste bigode × pelo ≥ 3 : 1 (R2). **Fontes.**
[22][18][1].

### R11 — Gata: miado que abre e fecha devagar; ronronar de boca fechada (média)

**O que mudar.** Novo episódio `miar` (gata, saudação e saudade-ao-voltar):
boca abre para `abre 0,5, redonda 0,6` (laudo 31 R1) em **80 ms** e fecha
**gradualmente em 450 ms** enquanto o som toca ("boca primeiro aberta e
depois fechada gradualmente" [7]); cabeça sobe 2 px e os olhos semicerram
0,2. **Miado mudo** (abre 0,35 por 0,4 s, sem som) como gesto de pedido na
saudade [7]. O **ronronar** (afago, `carinho > 0,4`) **nunca abre a boca**
(`pose.carinho > 0,4` deixa de ser condição de `aberta` em `_boca:6087-6091`
para a gata; a vibração vai para o háptico/bochecha). **Onde.**
`episodios.dart`, `_boca`, `som_service`. **Aceite.** Captura do miado a
30 qps: a altura da abertura tem **um** pico em ≤ 3 quadros após o início e
decai monotonicamente por ≥ 12 quadros; no afago da gata, 0 quadros com
boca aberta. **Fontes.** [7][6].

### R12 — Novelinha: folhas dos três e boca por espécie (baixa)

**O que mudar.** `novelinha_quadros_test.dart:36` passa a capturar também
`cat`, `fox` e `frenchie` (hoje não há folha da Mel nem do Bolota); as
orientações de boca por espécie do laudo 30 §3.4 (buldogue abre **atrás do
beiço**; gata boca pequena em "ω"; raposa abre o V para baixo) entram no
mesmo passe de R1 do laudo 31. Como a novelinha é só de frente, o *roach
back* do buldogue e o galope de dorso flexionado da gata (Muybridge 717
[17]) ficam para uma eventual vista de perfil — **não** fazer agora.
**Onde.** `gera/app_capturas/novelinha_quadros_test.dart`, `b4.js`.
**Aceite.** Existem `bicho-{cat,frenchie}.webp` com 40 quadros cada e os 6
níveis de fala distintos (laudo 31 R1-a). **Fontes.** [17]; laudo 30.

---

## 5. O que não fazer

- **Não** achatar as orelhas da gata ou da raposa para trás nem girá-las
  para fora na saudade: é medo/agressão [5][6] e unidade 2 da ficha de dor
  [8]. Para os lados, no máximo 0,35 rad (R9).
- **Não** dar ao buldogue francês o "rolar arrastado": é do buldogue
  **inglês** [2]; o francês anda "livre e vigoroso" [1]. E **não** fazê-lo
  quicar como lontra (R6).
- **Não** ofegar no sono, na saudade ou por mais de 3 s, e nunca com som de
  chiado: para o braquicefálico, ruído respiratório é sintoma (laudo 08;
  padrão [1]). O ofego é só o pós-corrida, mudo, a 5,3 Hz [14].
- **Não** mostrar os dentes do buldogue de boca fechada [1]; **não** pôr
  cauda nele (decisão do código, `pet.dart:4437-4439`, e padrão: "curta,
  baixa" [1]).
- **Não** usar o bote do gato na raposa nem o mergulho da raposa na gata: o
  gato **rebola e salta para a frente**; a raposa **escuta, salta para cima e
  cai de focinho** [4] (R4).
- **Não** dar pupila em fenda à raposa (é oval [3]) nem ao buldogue (é
  olho escuro cheio [1]); a fenda é só da gata [9].
- **Não** desenhar a língua da gata para fora como no cão: a gata feliz
  está de "boca fechada" [6]; a língua aparece só na lambida (R3).
- **Não** abrir a boca da gata no ronronar/afago: ronronar é de boca
  fechada [7] (R11).
- **Não** pôr bigodes longos na raposa nem no buldogue: em desenho infantil
  a raposa lê pelo focinho e pela cauda, o buldogue pelo beiço [I].
- **Não** fazer "piada literal" de espécie (gata no teclado, cão com osso
  na boca o tempo todo): Bluey pede "acenos", não gags "na cara" [18].
- **Não** somar detalhe ao buldogue (já é o mais detalhado): quanto mais
  feição, mais fácil "sair do modelo" ao mexer [20]. As rugas atuais são o
  teto.
- **Não** contornar com preto nem sombrear com cinza neutro [18].
- **Não** reabrir Rive nem trocar chaves de espécie (síntese); **não**
  desenhar vista de perfil só para o *roach back* (R12).

---

## 6. Fontes (todas lidas em 2026-11-08)

1. American Kennel Club — *Official Standard of the French Bulldog*
   (aprovado 10/04/2018). PDF lido por `pdftotext`.
   <https://images.akc.org/pdf/breeds/standards/FrenchBulldog.pdf>
2. American Kennel Club — *Official Standard of the Bulldog* (padrão do
   buldogue inglês; seção "Gait"). PDF lido por `pdftotext`.
   <https://images.akc.org/pdf/breeds/standards/Bulldog.pdf>
3. Wikipedia — *Red fox* (seções Description, Behaviour, Vocalisations).
   <https://en.wikipedia.org/wiki/Red_fox>
4. PMC 11087747 (2024) — estudo do mergulho na neve ("mousing") de raposas
   vermelhas e árticas, com análise de vídeo e crânios impressos em 3D
   (altura do salto, velocidade de impacto, papel do focinho).
   <https://pmc.ncbi.nlm.nih.gov/articles/PMC11087747>
5. Cats Protection — *Cat body language*.
   <https://www.cats.org.uk/help-and-advice/cat-behaviour/cat-body-language>
6. RSPCA (UK) — *Understanding cat behaviour / body language*.
   <https://www.rspca.org.uk/adviceandwelfare/pets/cats/behaviour/understanding>
7. Wikipedia — *Cat communication* (cita Moelk 1944, Bradshaw e outros).
   <https://en.wikipedia.org/wiki/Cat_communication>
8. Evangelista, M. C. et al. (2019). *Facial expressions of pain in cats:
   the development and validation of a Feline Grimace Scale*. Sci Rep
   9:19128 — ficha oficial (Université de Montréal, versão em alemão),
   PDF lido por `pdftotext`.
   <https://www.felinegrimacescale.com/_files/ugd/103d43_677c41d104fa44c59f8acf29d2046863.pdf>
9. EurekAlert / UC Berkeley — release de Banks, M. S. et al. (2015), *Why
   do animal eyes have pupils of different shapes?*, Science Advances.
   <https://www.eurekalert.org/news-releases/632799>
10. Wikipedia — *Whiskers* (vibrissas: grade, comprimento, bote).
    <https://en.wikipedia.org/wiki/Whiskers>
11. Wikipedia — *Cat anatomy* (orelha, coluna, cauda, patas).
    <https://en.wikipedia.org/wiki/Cat_anatomy>
12. Cornell Feline Health Center — *Cats That Lick Too Much*.
    <https://www.vet.cornell.edu/departments-centers-and-institutes/cornell-feline-health-center/health-information/feline-health-topics/cats-lick-too-much>
13. RSPCA (UK) — *Understanding dog behaviour / body language*.
    <https://www.rspca.org.uk/adviceandwelfare/pets/dogs/behaviour/understanding>
14. Improbable Research — *The impracticality of panting at other
    frequencies* (resumo de Crawford, E. C. 1962, *Mechanical aspects of
    panting in dogs*, J. Appl. Physiol. 17:249-251).
    <https://improbable.com/2025/07/17/the-impracticality-of-panting-at-other-frequencies/>
15. Merck Veterinary Manual — *Description and Physical Characteristics of
    Dogs* (valores fisiológicos normais).
    <https://www.merckvetmanual.com/dog-owners/description-and-physical-characteristics-of-dogs/description-and-physical-characteristics-of-dogs>
16. Blair, Preston (1947). *Advanced Animation* — texto OCR (fórmula do cão,
    ciclo do buldogue, "the cute character").
    <https://archive.org/stream/advancedanimation/Advanced%20Animation_djvu.txt>
17. Wellcome Collection — Muybridge, E., *Animal Locomotion* (1887), prancha
    717 "Cat; trotting; change to galloping" (domínio público).
    <https://wellcomecollection.org/works/an4bpesp>
18. Goodsniff (Substack) — *Creating Bluey: Tales from the Art Director,
    Chapter 2* (linguagem de formas, bíblia de estilo).
    <https://goodsniff.substack.com/p/creating-bluey-tales-from-the-art-891>
19. Laughing Place — *Annecy 2023 Recap: The Story Behind "Bluey" with Joe
    Brumm, Richard Jeffery, and Mark Paterson*.
    <https://www.laughingplace.com/w/articles/2023/06/15/annecy-2023-recap-the-story-behind-bluey-with-joe-brumm-richard-jeffery-and-mark-paterson/>
20. Cartoon Brew — *Interview: 'Hey Duggee' creator Grant Orchard*.
    <https://www.cartoonbrew.com/?p=149069>
21. Skwigly — *Interview: Simon Tofield – The Man Behind Simon's Cat*.
    <https://skwigly.co.uk/simons-cat>
22. Fotos medidas (Wikimedia Commons, 960 px, via `Special:FilePath`):
    `Vulpes_vulpes_ssp_fulvus.jpg` (raposa na neve);
    `Orange_tabby_cat_sitting_on_fallen_leaves-Hisashi-01A.jpg` (gata
    laranja-e-branca); `A_French_Bulldog.jpg` (fulvo com máscara, ao sol);
    `2008-07-28_Dog_at_Frolick_Field.jpg` (tigrado ofegando, capa do artigo
    *French Bulldog* da Wikipédia em inglês).

**Vistos só no resultado de busca (não lidos; não sustentam nenhuma
recomendação):** Harris & Steudel 2002 (*J. Exp. Biol.* 205:3877, salto da
gata: a página não abriu); o original de Crawford 1962 (só o resumo via
[14]); a entrevista da Meomi (Octonauts) no Creative Bloq (403); os
tutoriais de gata e raposa do Envato Tuts+ (403); a entrevista de García
Carsí (Pocoyo) em *Con A de Animación*; as afirmações populares de "o gato
salta 5–6 vezes o próprio tamanho" (sem fonte primária); a Feline Grimace
Scale em inglês na Nature (exigiu cookie; usei a ficha oficial [8]).

# 34 — Movimento: ciclos de andar/correr/nadar/voar, princípios e timing

Tema: o movimento dos nove bichos vistos de frente/três quartos — os 12
princípios com números, ciclos por tipo de locomoção, o que torna um laço de
24 quadros convincente e o que o denuncia, o ocioso de 1 s, e as reações
(susto, festa, medo) sem "pop".

Marcações: **[App]** = lido no código ou medido nas folhas; **[Fato]** = o que
a fonte diz; **[Opinião]** = dedução nossa a partir dos fatos. Fontes lidas em
08/11/2026, listadas no fim. Este laudo avança sobre o 21 (molas, ruído,
sacadas, piscar) e o 24 (gingado de frente): não repete o que está lá; usa
como ponto de partida que o motor já tem molas, ruído e sacadas.

## Resumo em 12 linhas

1. **[App]** As folhas `corre-fox.webp` e `anda-otter.webp` (24 quadros) são
   um pogo: o corpo inteiro sobe 49 px (raposa, 20 % do quadro) e 38 px
   (lontra, 18 %) e desce; as duas metades do laço são iguais salvo a pata
   (diferença média de alfa 9,8/255 na raposa); cauda, orelhas, olhar, boca e
   cabeça não mudam em nenhum quadro; no ápice a cabeça sai do quadro (topo = 0)
   e no pouso a lontra é cortada embaixo e dos dois lados.
2. **[App]** O pouso é um único quadro de achatamento 0,9 exatamente no
   contato (a 12 q por passo: 0,15 → **0,90** → 0,36; a lontra alarga 15 % num
   quadro de 62 ms e volta), a raposa desce 20 px no último quadro, e o
   estirão máximo (−0,55) cai no ápice, onde a velocidade é zero — o
   contrário do que o peso pede.
3. **[App]** Cadências: a lontra saltita 3,2 vezes/s andando e 5,8 correndo; o
   site toca a corrida a 2,1 passos/s (11 quadros por passo a 24 fps, tempo de
   *andar* na tabela de Williams) e ainda soma um quique de 5,4 Hz por cima.
4. **[App]** As folhas de vida (120 quadros) tocam em pingue-pongue: a piscada
   invertida abre rápido e fecha devagar (o contrário do real: fechar 76 ms,
   abrir 438 ms) e a cabeça passa a liderar o olho.
5. **[App]** `pula()` agacha e decola no mesmo quadro; o susto achata e estica
   ao mesmo tempo; a festa é um pogo contínuo a cada 0,5–0,65 s sem agachar.
6. **[Fato]** Williams: 12 quadros por passo é andar natural (2 passos/s), 8 é
   andar cartoon/corrida lenta (3/s), 6 é corrida (4/s), 4 é corrida muito
   rápida (6/s); o peso desce logo depois do contato e sobe depois da passagem.
7. **[Fato]** Vista de frente: a pelve cai do lado do pé da frente, os ombros
   contra-inclinam, a cabeça "arrasta atrás" da troca de peso, o pé livre faz
   um arco; 9 quadros por passo é o tempo que "funciona melhor".
8. **[Fato]** Piscada de animação: 8 quadros, 2 fechados, com ease nas duas
   pontas, pálpebras defasadas 1 quadro; piscar em toda virada de cabeça e
   toda troca de direção do olhar.
9. **[Fato]** Transição sem pop: o Spine mistura poses por 0,1 s de padrão,
   0,2 s andar→pular, 0,4 s pular→andar, 0 s para golpe. Follow-through:
   atrasar cada segmento (tronco, pescoço, cabeça) "um par de quadros".
10. **[Fato]** Biologia: o pinguim oscila de lado com flutuação de velocidade
    lateral ~3× a ântero-posterior; a tartaruga para no meio do andar e não
    recupera energia (não quica); a lontra rema com as duas patas traseiras
    *juntas* e a cauda ondula para cima e para baixo; o axolote ondula de lado
    com amplitude zero atrás da cabeça e máxima na ponta; a coruja bate asa a
    ~6 Hz e a buraqueira anda, saltita e corre no chão.
11. **Recomendações altas**: R1 alternar os lados do laço (pelve, ombro,
    cabeça, cauda), R2 squash de 2–3 quadros depois do contato, sem corte do quadro,
    R3 tabela de cadências por espécie, R4 fim do pingue-pongue, R5 antecipação
    antes de decolar (festa, susto), R6 crossfade de 4–8 quadros no `b4.js`.
12. O que não fazer: pingue-pongue de qualquer coisa que tenha direção
    (piscada, sacada, passo); ciclos de 24 quadros tocados a 16 fps; o quique
    extra em JS por cima de uma folha que já quica; squash de um quadro só.

---

## 1. O que o app faz hoje [App]

### 1.1 O passo (`motor_de_vida.dart`)

- `_andar` (`motor_de_vida.dart:639-673`): velocidade-base por espécie
  (`JeitoDeCacar.velocidade`, `pet.dart:989-1004`: 44 u/s padrão, lontra 58,
  pinguim 30, tartaruga 12), ×1,8 correndo, ×2,4 voando, ×0,8 nadando; freio
  140 u/s², aceleração 220 u/s². Quem saltita avança no ar e quase para no
  chão (`avanco = 0,25 + 1,5·sin²`, linha 663-665). A fase do passo cresce
  `|vx|·dt/36` (linha 672): um ciclo (dois passos) a cada 36 unidades.
- Cadências que isso dá (calculadas): capivara/gata/raposa/buldogue/coruja
  **2,44 passos/s** andando e **4,4** correndo; lontra **3,2** e **5,8**;
  pinguim 1,67; tartaruga 0,67.
- O quadro do passo (`_passo`, linhas 1215-1296): intensidade entra com
  `exp(-dt·9)` (≈ 110 ms); `sobeNoPasso` = arco de 7 u (12 correndo) para quem
  saltita e `(1-cos 2φ)/2 · 3` (8 correndo) para quem ginga; `_elastico`
  sobe de 0 a 0,9 em `s > 0,9`, cai de 0,9 a 0 em `s < 0,14` (a 12 q por
  passo: 0,15 → **0,90** → 0,36, um pico de um quadro no contato) e vai a
  −0,55 em `s = 0,5`, o ápice (linhas 1232-1245); no pouso `_achata.empurra(2,5)`, cauda ±5 e 25 % de
  chance de orelha (1250-1255); `gingado = onda·0,045` rad (**2,6°**) só para
  quem não saltita (linha 1270); `pende` 0,03 rad andando (1,7°) e +0,07
  correndo (1273); patas: `arco·(1,0 | 0,35)` alternando por salto (1278-1285).
- O pintor (`pet.dart:5848-5860`): a pata "no ar" de quem saltita vai
  `+Offset(noAr·3, noAr·6)` — **para baixo** 6 unidades ("pendurada"); de quem
  ginga, `−8` (para cima). O gingado gira pelo pé de apoio a ±22 unidades
  (`pet.dart:2387-2392`). O deformador (`deformador.dart:407-452`) verga 11,
  achata `h·14`, quadril `base²·4`, ondula 6.
- A cabeça persegue o apoio com `Mola2(f 3,2; ζ 0,42)` e atraso limitado a
  ±6/±7 (`motor_de_vida.dart:608`, `1352-1362`). Virada: `Mola2(f 1,6;
  ζ 0,72)` (linha 578); pupila `f 11; ζ 0,88` (572); cauda `Mola(f 3; ζ 0,35)`
  (601); achata `f 4; ζ 0,95` (600); susto `f 2,6; ζ 0,5` (634).

### 1.2 Salto, festa, susto

- `pula(v)` (`motor_de_vida.dart:987-992`): `_achata.empurra(5)` e `_vy = v`
  **no mesmo quadro** — o agachar e a decolagem são simultâneos; a mola de
  achatar (f 4 Hz) só chega ao pico ~60 ms depois, quando o corpo já subiu.
  Gravidade 900 u/s² (linha 680): v = 220–290 dá 0,49–0,64 s de voo.
- Festa (`1727-1733`): pula a cada **0,5–0,65 s** com v 220–290 → o corpo
  está no ar 75–100 % do tempo: um pogo sem pausa, sem agachar, sem rebolar
  entre saltos (o rebolado está no pintor, `pet.dart:2515`, 7 voltas por
  ciclo de 7 s ≈ 1 Hz, e só se vê quando ele está no chão).
- Susto (`796-800`): `_susto.fixa(1)` (estica de uma vez) **e**
  `_achata.empurra(4)` (achata) **e** `pula(240)` no mesmo quadro — a
  antecipação para baixo e o estirão para cima se anulam em parte.
- Reverência, quadril e rebolado são zerados a cada quadro pelos episódios e
  suavizados com `exp(-dt·12)` (≈ 80 ms, 95 % em 250 ms) e o quadril com
  `exp(-dt·30)` (**33 ms**, linhas 1262-1268): dois quadros a 60 Hz.

### 1.3 Piscar, olhar, gestos de cabeça

- Piscar (`1535-1575`): fecha 80 ms, segura 30, abre 170 (total 280 ms;
  abrir = 2,1× fechar); lenta 220/300/400; dupla em 12 %; intervalo
  lognormal(mediana 3,5 s; σ 0,55) limitado a 1–12 s. Piscar junto de sacada
  grande em **40 %** dos casos (`1511`).
- Sacadas (`1492-1520`): fixação lognormal(1,1 s; σ 0,5) em disco de 0,14;
  cabeça vai atrás (`_cabeca f 1,8; ζ 0,7`).
- Gestos de cabeça (`_gestosDeCabeca`): 4 tipos, 1,1–2,6 s, a cada 3–8 s,
  entram e saem por `sin(uπ)`.
- Respiração (`1035-1053`): período 3,2 s ×(1 ± 0,2 ruído) = **18,8/min**,
  fundura 0,8 ± 0,22; descansando ×1,3.

### 1.4 Nado e voo

- Remada: `_ritmoRemada` 0,9–1,5 s por braçada (`episodios.dart:308`), 3–7
  braçadas por episódio; boiar a 2,6 s. O corpo "ondula" de lado
  (`deformador.dart:431-432`, onda lateral que sobe do quadril, amplitude 6)
  **para todas as espécies**; as patas remam **alternadas** em meio ciclo
  (`pet.dart:5862`: `rema < 0 ? 0 : 0,5`).
- Voo da coruja (`episodios.dart:880-900`): batida de 0,26 s na decolagem,
  0,24 pairando, 0,36 cruzando (2,8–4,2 Hz); planeio 0,8–1,4 s; altitude 80–115;
  descida pela mola `f 0,9; ζ 0,8` (≈ 1 s); no toque `_achata.empurra(9)`.
  A asa (`pet.dart:3311-3360`): descida em 58 % do ciclo, de +0,95 rad a
  −0,62 rad, ponta atrasada 0,26/−0,5, asa encolhe 42 % na subida.

### 1.5 A série: `passoNa` e a classe `Bicho`

- `passoNa` (`novelinha_anim24_test.dart:54-91`) replica a conta do passo com
  intensidade 1, **mas só o passo**: `cauda`, `cabecaAtraso`, `pisca`,
  `cabecaGiro`, orelha ficam no padrão (0). Olhar e virada fixos (0,8 / 0,7).
  24 quadros por ciclo (linha 132), 16 para pastar (170).
- `b4.js:111-114`: as folhas de ação tocam `fr = floor((t·vel mod per)/per·n)`
  com `per = 1,5 s` (3 s para respirar/dormir): 24 quadros em 1,5 s =
  **16 fps**, 1,33 passos/s andando; correndo `vel 1,6` → 25,6 fps e
  **2,13 passos/s** (0,47 s por passo = 11 quadros a 24 fps).
- `b4.js:200`: a corrida da raposa soma `y − |sin(17t)|·28`: um quique de
  **5,4 Hz** por cima da folha, que já quica a 2,1 Hz. Dois quiques
  incomensuráveis = tremor.
- `b4.js:88`: as folhas de vida (120 quadros) tocam em **pingue-pongue**
  (`n2 = 2n − 2 = 238` a 30 fps, volta de 7,9 s). Troca de pose
  (`parado`/`anda`/`corre`/`respira`) é `display: inline/none` sem mistura e a
  folha nova começa do quadro que o relógio global apontar (linha 114).
- `b4.js:51` `piscaEm`: fechado por 0,13 s com um único desenho (`m·7+6`),
  sem meio-fechado antes nem depois; intervalo uniforme 2,6–4,4 s. `b4.js:94-95`: respiração `1 + sin(2,4t)·0,012`
  (período 2,6 s, 1,2 % de escala) e balanço `sin(1,7t)·1,2°`.

### 1.6 Medições das folhas (`assets/img/app/`, 08/11/2026)

`corre-fox.webp` 24 × 272×243; `anda-otter.webp` 24 × 181×206. Caixa por
quadro (lontra: alfa > 40; raposa: só o pelo laranja, alfa > 200, para
excluir os brilhos cor-de-rosa e a poeira, que são fixos):

| | raposa (corre) | lontra (anda) |
|---|---|---|
| curso vertical do topo | 49 px (20 % do quadro) | 38 px (18 %) |
| topo no ápice | **0** (cortada) | **0** (cortada) |
| pouso | 1 quadro; largura 177→**188** (+6 %); o topo desce **20 px** no último quadro | 1 quadro; largura 157→**180** (+15 %), cortada embaixo (205/206) e dos lados (0 e 180/181) |
| Δtopo quadro a quadro | −16,−13,−8,−6,−4,−2,+1,+4,+5,+8,+11,**+20** | −13,−10,−6,−5,−3,−1,+1,+2,+5,+5,+8,**+17** |
| metade 2 vs metade 1 | diferença média de alfa 0→9,8/255 (só a pata) | 0→18/255 (só a pata) |
| cauda, orelha, olhar, boca, inclinação da cabeça | fixos nos 24 quadros | fixos nos 24 quadros |

Leitura: a subida é mais rápida que a descida (bom), mas a descida termina
num degrau de 17–20 px num quadro de 62 ms, e o achatamento é um pico de um
quadro (0,15 → 0,90 → 0,36) exatamente no contato, sem o "down" de 2–3 q
depois dele; o estirão máximo está no ápice, onde o corpo está parado; nada
além do corpo inteiro se move; a silhueta não alterna de lado entre os dois
passos; e o quadro foi capturado pequeno demais para o salto.

---

## 2. O que as fontes dizem

### 2.1 Timing do andar e da corrida (24 fps)

- **[Fato]** Williams, *The Animator's Survival Kit* p. 109 (via resumo lido
  [F1]): 4 quadros por passo = corrida muito rápida (6 passos/s); 6 = corrida
  ou andar muito rápido (4/s); 8 = corrida lenta ou andar "cartoon" (3/s);
  **12 = andar natural, "march time" (2/s)**; 16 = passeio (⅔ s por passo);
  20 = idoso/cansado; 24 = passo lento (1/s); 32 = muito lento. "People walk
  on 12's". O peso **desce logo depois do contato e sobe depois da
  passagem**; "it's the up and down position of your masses that gives you
  the feeling of weight"; sem o sobe-desce o corpo "flutua". Calcanhar fica
  no chão "até o último momento possível". Ken Harris: "A walk is a process
  of falling over and catching yourself just in time." E o aviso: "Cycles are
  mechanical and look just like what they are — cycles."
- **[Fato]** Corrida: "usually 12-16 frames per cycle for a run compared to 24
  frames per cycle for a walk"; o corpo "leans forwards more during a run";
  Williams: "at least 3 frames are needed for the legs to cycle"; Blair
  desenha meio ciclo (um passo) e espelha [F2].
- **[Fato]** Ciclo de 24 quadros: contatos em 0, 12 e 24; passagem, descida e
  subida a 3 quadros uma da outra; quadril **mais baixo no down** (o joelho
  da frente dobra para absorver o peso) e **mais alto na passagem/up**; o pé
  "deve levantar, avançar em arco e voltar ao chão"; o "balanço da cabeça" é
  passe secundário [F3].
- **[Fato]** O breakdown "usually is not in the exact middle between two
  extremes": deslocado produz arco [F5].

### 2.2 Vista de frente e três quartos

- **[Fato]** "Most walking cycles work best at 9 frames per step = 18 frame
  cycle"; de frente a massa "moves up and down as it does in the side view";
  **a pelve desce do lado do pé que está à frente**; o escorço é
  principalmente na panturrilha; o pé precisa de três desenhos (chapado,
  levantado mostrando a sola de cima, virado mostrando a sola) [F4].
- **[Fato]** "Tilt hips so that passing side is low"; "counter tilt in the
  hips by tilting shoulders in the opposite direction"; "tilt the head as if
  it is dragging behind the body's weight shift" [F5].
- **[Fato]** "The arms, hips, torso, and head must move together" para o andar
  parecer natural; as quatro chaves são contato da frente, primeira passagem,
  contato de trás, segunda passagem — **o ciclo alterna lados** [F6].

### 2.3 Marchas de quadrúpedes e aves (biologia)

- **[Fato]** Duty factor > 50 % é andar, < 50 % é corrida; sequências
  **laterais** são "most common in mammals"; marchas assimétricas (galope,
  bound) têm fase suspensa; a transição acontece onde o custo de andar rápido
  passa o de correr devagar [F7].
- **[Fato]** Raposa/coiote: o **trote de registro direto** é "the normal
  travelling gait of our foxes and coyotes" (a traseira pisa onde a dianteira
  pisou); o *side trot* é mais rápido, "when the animal has a destination in
  mind"; o *lope* deixa o padrão 1-2-1 e é mais rápido que qualquer trote;
  galope é o mais rápido [F8].
- **[Fato]** Capivara: herbívoro semiaquático "classified as cursorial (having
  limbs adapted for running)", que os autores propõem reclassificar como
  "cursorial-swimming/diving"; natação apoiada por membrana interdigital [F16].
- **[Fato]** Buldogue francês na esteira: andar 0,6–0,8 m/s, trote 1,1–1,7 m/s;
  "femoral abduction (> 40°) and external rotation (> 30°) during walk and
  trot" (noutro trecho, até 30°): pata traseira aberta e virada para fora
  [F11].
- **[Fato]** Pinguim-imperador a 0,54 m/s: "the fluctuations in lateral
  velocity were nearly three times those in the fore–aft direction"; a energia
  cinética lateral é ~30 % das flutuações totais; recuperação de energia até
  80 % (pêndulo invertido), máxima a ~0,5 m/s; o custo alto vem das pernas
  curtas, não do gingado [F9].
- **[Fato]** Tartarugas (*Trachemys*, *Chelydra*, *Apalone*): "tend to pause
  when walking and do not appear to tire rapidly"; sem velocidade preferida;
  "poor mean levels of energy recovery", nunca os níveis de quadrúpedes
  cursoriais; custo mecânico 2–4× o de outros terrestres [F10]. Ou seja: **não
  quica**, arrasta e para.
- **[Fato]** Coruja-buraqueira: "walk, hop and run in search of insects";
  paira ("hovering above the ground in search of prey"); "long legs and a
  short tail"; 127–255 g, 19–25 cm, envergadura 53–61 cm; gira a cabeça 270°
  [F12]. Coruja boobook em túnel de vento: batida média **~6 Hz**, ciclo em
  quatro fases (upstroke, transição, downstroke, transição); ângulo de ataque
  na raiz 5–18° no downstroke; Strouhal 0,35–0,37 [F13].
- **[Fato]** Lontra: "propelled themselves with simultaneous strokes of the
  hind feet"; a cauda achatada dorsoventralmente ondula, "a traveling wave was
  produced in the tail" que viaja **mais rápido que o corpo**; a onda também
  percorre a cauda no recovery; empuxo o ciclo inteiro [F14].
- **[Fato]** Axolote: nado "undulatory, anguilliform (eel-like)"; "swimming
  speed was found to be frequency-regulated, while the wavelength appeared to
  be constant"; "the amplitude of the propulsive wave is minimal just
  posteriorly to the head and increases considerably to reach a maximum at the
  tail tip"; eficiência máxima acima de 2,5 comprimentos/s; 0,38 comprimento
  por ciclo [F15].
- **[Fato]** Respiração em repouso: gato 16–40/min, cão 18–34/min (Merck,
  *Dukes' Physiology*) [F17] — períodos de 1,5–3,75 s.

### 2.4 Piscar, virada de cabeça, *take*

- **[Fato]** Piscada voluntária humana a 600 fps: 572 ± 25 ms no total;
  **fechar 76 ms, fechado 58 ms, abrir 438 ms**; velocidade de pico 243 mm/s
  fechando contra 157 abrindo — fecha rápido, abre devagar [F18].
- **[Fato]** Regra de animação: "A standard blink is usually about 8 frames,
  with the lids closed for about 2 frames", com ease-in/out nas pontas;
  "offset the eye lids by one frame"; "always add a blink on a head turn";
  piscar "every time they change eye direction"; personagens piscam "much
  more often than you might think"; um toque nas sobrancelhas para a piscada
  não ficar dura [F19].
- **[Fato]** *Take* (Lemay): hold inicial animado (ciclo de 48 quadros); "an
  anticipation down"; "a slight anticipation to the right in preparation for
  the big head turn to the left"; a virada rápida com **um só intervalo "on
  twos"** (≈ 4 quadros) porque "the action is fast and the distance great";
  "a downward arc to the path of action, otherwise the head turn will look
  flat"; o take final "pop directly into this position without the strobed
  inbetween to make it hit harder"; tremor = "alternate between the two
  extreme positions to create the stagger take effect" [F20].

### 2.5 Salto, pouso, follow-through, *moving hold*

- **[Fato]** Para coluna, pescoço e cabeça, "offset each section by a couple
  of frames"; no pouso "have them slam down in a couple frames to help add
  some weight"; *moving hold*: copiar a pose "another ten frames ahead" com um
  pequeno movimento que continua a direção; o espaçamento "should be more
  bunched at the peak of the jump"; subida e descida simétricas no tempo [F21].

### 2.6 Transições, laços, mistura

- **[Fato]** Spine: `setDefaultMix(0.1)`; `walk→jump 0.2`, `jump→walk 0.4`,
  `jump→run 0.25`, `walk→shoot 0`; a animação anterior "will be mixed out over
  the mix duration" com `alpha` entre a pose atual (0) e a nova (1) [F22].
  Isto é: 2–10 quadros a 24 fps, mais longo para voltar ao chão, zero para um
  golpe.
- **[Fato]** Pingue-pongue sem travar nas pontas: duplicar a sequência,
  "remove the first and last frame" da cópia, inverter e emendar — senão os
  quadros de virada aparecem duas vezes [F23]. (O `b4.js:88` já evita o
  quadro duplicado com `2n − 2`; o problema restante é a direção, §3 R4.)
- **[Fato]** Rosen (GDC 2014): "interactive and fluid animations using very
  few key frames"; "we really need animation and code to work more closely
  together" [F24]. Rain World: nas asas do abutre as pontas são movidas por
  código e o resto por juntas; em Grow Home as pernas são forçadas por código
  [F25].

### 2.7 Referências de desenho infantil

- **[Fato]** *Hey Duggee* (Grant Orchard): feito no Flash "using the
  pre-defined symbols as much as possible"; "no outlines and no effects
  outside of what Flash could do"; personagens são formas geométricas com
  olhos e boca, com todo detalhe "extra" removido porque seis personagens
  costumam estar em cena; "'reuse' isn't a dirty word on the show"; Duggee é o
  mais difícil de animar porque pequenas mudanças de posição das feições o
  tiram do modelo; a meta é as crianças assistirem "de pé, perto da TV" [F26].
  **[Opinião]** Para o Baru: a vida vem do timing e da alternância de poses
  simples, não de mais detalhe; reaproveitar ciclos é prática de estúdio,
  desde que o ciclo seja bom.

---

## 3. Recomendações priorizadas

Unidades: "u" = unidade do desenho (corpo ≈ 120 u de altura, pés em `_pes`);
"q" = quadro a 24 fps salvo indicação. Critérios de aceite são medidos nas
folhas (caixa de alfa por quadro, como em §1.6) ou em números do motor com
semente fixa (`MotorDeVida(semente:)`, `dt = 1/24`).

### R1 — O laço alterna de lado: pelve, ombros, cabeça, cauda (alta)

- **O que mudar.** Cada passo tem um lado. No passo *k* (par/ímpar), o corpo
  rola **±4°** pelo pé de apoio (hoje 0° para quem saltita, 2,6° para quem
  ginga), a pelve desce **3 u do lado do pé da frente** (quadril `±1` no
  deformador, hoje `passada` sem lado para os saltitantes), os ombros/cabeça
  contra-inclinam **−2°**, a cabeça chega **2 q depois** do corpo (manter
  `_cabecaSegue`, mas o alvo recebe o rolamento), e a cauda balança para o
  lado oposto ao do passo com atraso de 2–3 q (`_cauda.empurra` já existe no
  pouso; passar a ser ±1 alternado por `saltoPar`, não sorteado).
- **Onde.** `motor_de_vida.dart:1270` (`gingado` passa a valer para `saltita`,
  sinal por `saltoPar`), `1278-1285` (patas), `1250-1255` (cauda alternada),
  `pet.dart:2512-2521` (quadril com lado), `novelinha_anim24_test.dart:54-91`
  (`passoNa` ganha `gingado`, `cauda`, `cabecaAtraso` com o mesmo sinal
  alternado).
- **Aceite.** Na folha de 24 q, diferença média de alfa entre o quadro *i* e
  *i+12* ≥ 20/255 (hoje 9,8 raposa, 18 lontra); o centroide horizontal do alfa
  do quadro 6 e do 18 difere ≥ 3 px; a ponta da cauda muda de x ≥ 10 px entre
  os quadros 6 e 18.
- **Fontes.** F4 (pelve cai do lado do pé da frente), F5 (quadril baixo na
  passagem, ombros contra, cabeça arrasta), F6 (as 4 chaves alternam lados),
  F1 (peso desce depois do contato, sobe depois da passagem).

### R2 — Squash de 2–3 quadros depois do contato, estirão na decolagem, sem cortar o quadro (alta)

- **O que mudar.** Trocar o pico de um quadro de `_elastico` no contato por
  um pulso de 3 q que **começa no contato e tem o máximo 1 q depois** (+0,6),
  decaindo a zero em mais 2 q (fórmula de partida:
  `0,6·exp(−((s−0,08)/0,06)²)`); estirão **−0,35 logo após a decolagem** (`s`
  0,15–0,35) e −0,2 na queda (`s` 0,7–0,9); **no ápice ≈ 0** (hoje −0,55, o
  máximo, onde o corpo está parado); largura cresce no máximo **+10 %** (hoje
  +15 % num quadro). O corpo nunca sai da caixa de captura: aumentar
  `_tamanho` da captura para 300×260 ou reduzir `sobeNoPasso` de 7 para 5 u
  andando (12 → 9 correndo).
- **Onde.** `motor_de_vida.dart:1232-1245` e `passoNa`
  (`novelinha_anim24_test.dart:62-69`); `novelinha_anim24_test.dart:37`
  (`_tamanho`).
- **Aceite.** Na folha: a largura máxima ocorre **1 q depois** do quadro de
  topo mais baixo (não no mesmo) e é ≤ 1,10× a mínima; a largura fica acima
  de 1,03× a mínima por 2–3 q, não 1; o quadro do ápice tem largura dentro de
  ±2 % da mínima; |Δtopo| ≤ 14 px entre quadros consecutivos; topo ≥ 4 px e
  fundo ≤ H−4 px em todos os 24 quadros.
- **Fontes.** F3 (down = joelho dobra para absorver; passagem/up = ponto
  alto), F21 ("slam down in a couple frames"; espaçamento junto no ápice), F1
  (sem sobe-desce o corpo flutua — mas é *movimento*, não parada).

### R3 — Tabela de cadências por espécie, uma só, usada pelo app e pela série (alta)

- **O que mudar.** Fixar passos/s por espécie e modo, e derivar `velocidade`
  e o divisor de `_faseDoPasso` dela (hoje 36 u por ciclo para todos), para o
  tempo bater com a tabela de Williams e com a biologia:

| espécie | andar (passos/s) | q/passo a 24 fps | correr/fugir | referência |
|---|---|---|---|---|
| capivara | 2,0 (saltito) | 12 | 3,5 (galope curto) | F1 "12's"; F16 cursorial |
| lontra | 2,4 | 10 | 4,0 | F1 8–6 q = corrida |
| gata | 2,0 | 12 | 4,0 (disparada) | F7 lateral; F1 |
| raposa | 2,2 (trote) | 11 | 4,0 (lope) | F8 trote é a marcha normal |
| buldogue | 1,8 (bamboleio) | 13 | 3,0 | F11 0,6–0,8 m/s andar, 1,1–1,7 trote |
| pinguim | 1,8 (gingado) | 13 | 2,5 | F9 0,5 m/s, lateral 3× |
| tartaruga | 0,6 | 40 | 1,0 | F10 lenta, para no meio |
| coruja (chão) | 2,5 (corridinha) | 10 | saltos | F12 walk, hop, run |
| axolote (fundo) | 0,8 | 30 | — | F15 (só nada rápido) |

  Na série: a corrida da raposa a **≥ 3,5 passos/s** (`vel ≥ 2,6` com
  `per = 1,5`, ou melhor, `per` por pose: corre 0,55 s, anda 1,0 s), e
  **remover** o `|sin(17t)|·28` de `b4.js:200` — o quique vem da folha.
  Tocar cada folha no ritmo de captura (24 q em 1,0 s = 24 fps) ou capturar
  30 q para 30 fps, para cada quadro aparecer uma vez só.
- **Onde.** `pet.dart:989-1004` (`JeitoDeCacar`), `motor_de_vida.dart:672`,
  `b4.js:112` (`per`), `b4.js:200`.
- **Aceite.** Filmagem a 30 fps do app: número de contatos em 5 s dentro de
  ±15 % da tabela; no `b4.js`, `render()` quadro a quadro: a altura do corpo
  da raposa tem **um** mínimo por passo (hoje dois ritmos sobrepostos).
- **Fontes.** F1, F2, F7, F8, F9, F10, F11, F12.

### R4 — Fim do pingue-pongue nas folhas de vida (alta)

- **O que mudar.** Capturar a vida como laço **para a frente**: rodar
  `MotorDeVida` com semente fixa por 240 q (8 s a 30 fps), com a fase da
  respiração inteira no fim (`periodoRespiro` múltiplo), última sacada de
  volta ao centro antes de t = 7,5 s, e sem piscada nos 8 últimos quadros; no
  `b4.js`, tocar `fr = floor(t·30) % n` e, na costura, **crossfade de 8 q**
  entre os 8 últimos e os 8 primeiros (duas cópias do `<image>` com opacidade
  cruzada). Enquanto a captura não muda: tocar para a frente e aceitar o
  corte, que é menos visível que a piscada ao contrário.
- **Onde.** `b4.js:88`; teste de captura das folhas `vida-*` (em
  `gera/app_capturas/nov_vida*_test.dart`).
- **Aceite.** Em toda piscada da folha tocada em ordem, o número de quadros
  com olho < 50 % aberto antes do quadro fechado ≤ 2 e depois ≥ 3; o olho
  salta e a cabeça vem depois (centro da pupila muda ≥ 2 px antes de o
  contorno da cabeça mudar); topo da caixa do quadro 239 difere do quadro 0
  em ≤ 1 px.
- **Fontes.** F18 (fechar 76 ms, abrir 438 ms: a piscada tem direção), F19
  (8 q, 2 fechados, ease nas pontas), F23 (costura de laço), F1 ("cycles look
  like cycles").

### R5 — Antecipação antes de decolar: salto, festa, susto (alta)

- **O que mudar.** `pula()` passa a agendar: **t0** agachar (`_achata.alvo =
  +0,3`, pernas encolhem, cabeça desce 3 u) por **5 q (≈ 200 ms)** para salto
  espontâneo e **3 q** para reação ao toque; **t0+5q** decolar com estirão
  −0,35 por 2 q; no ar `achata` segue `−|vy|/500·0,35` (já existe); pouso =
  squash +0,4 em 2 q, recuperação 6 q. Festa: 2–3 saltos (intervalo 0,9–1,1
  s, com o agachar entre eles), depois **0,8–1,2 s rebolando no chão** (quadril
  ±1 a 3 Hz, orelhas/cauda em overlapping), repete. Susto: ordem obrigatória
  — 3 q de achatar (+0,25, olhos arregalados: `pisca` −0,15 se houver, orelhas
  para trás), 2 q de estirão (−0,6) com o pulinho, depois tremor: `_susto`
  com ζ 0,25 alternando ±0,08 por 4 ciclos (o *stagger* de Lemay), cauda e
  orelhas 2 q atrás.
- **Onde.** `motor_de_vida.dart:987-992` (`pula`), `1727-1733` (festa),
  `796-800` (susto), `pet.dart:2505-2507`.
- **Aceite.** Log por quadro (semente fixa): `achata > 0,2` em ≥ 3 q
  consecutivos **antes** de `_noChao = false`; `achata < −0,3` em ≥ 2 q depois
  da decolagem; na festa, fração de tempo no ar entre 35 % e 55 % (hoje
  75–100 %); no susto, o primeiro extremo é positivo (achata) e o segundo
  negativo (estica), com ≥ 2 q entre eles.
- **Fontes.** F20 (anticipation down; pop direto no take; stagger), F21
  (pouso em 2 q, segmentos defasados), F1 (peso = massas subindo e descendo),
  laudo 21 §1 (ζ e overshoot) para os valores de mola.

### R6 — Transição entre poses na série: crossfade de 4–8 q e fase contínua (alta)

- **O que mudar.** Em `Bicho.render`, trocar o `display` seco por dois `<svg>`
  de folha com `opacity` cruzada por **0,2 s** (andar→parado 0,25 s;
  parado→andar 0,15 s; susto 0 s — um *take* entra seco), e escolher o quadro
  inicial da folha nova pela **fase**: ao sair de `anda`, parar num quadro de
  contato (0 ou 12); ao entrar em `corre` a partir de `anda`, manter a fase do
  passo (`fr_novo = fr_velho`). Guardar `fase` por bicho em vez de ler o
  relógio global.
- **Onde.** `b4.js:69-72`, `111-114`.
- **Aceite.** Render quadro a quadro a 30 fps: em nenhuma troca de pose o
  topo da caixa do bicho muda > 10 px entre dois quadros consecutivos (exceto
  pouso de salto); a opacidade das duas folhas soma 1 durante a mistura.
- **Fontes.** F22 (mix 0,1–0,4 s; 0 para golpe), F21 (moving hold: nunca
  congelar).

### R7 — Pata livre sobe num arco e a pata de apoio fica chapada (média)

- **O que mudar.** Para quem saltita, a pata "no ar" sobe **−8 u** (hoje +6,
  pendurada) e avança +4 u num arco (`y = −8·sin(πu)`), encolhendo 20 % na
  altura (escorço da panturrilha); a pata de apoio fica no chão e alarga 10 %
  no contato. Três desenhos de pé por espécie: chapado, levantado (sola de
  cima) e virado (sola) — para a capivara/lontra basta chapado e levantado.
- **Onde.** `pet.dart:5848-5860`; `_pata` das espécies em `pet.dart`.
- **Aceite.** No quadro de passagem (6 e 18), o ponto mais baixo do alfa da
  pata livre fica ≥ 8 px acima do da pata de apoio (à densidade 1,5: ≥ 12 px).
- **Fontes.** F3 (o pé levanta, faz arco, pousa), F4 (escorço, três
  desenhos de pé), F1 (calcanhar no chão até o último momento).

### R8 — Piscada: 8 q, pálpebras defasadas, 100 % nas viradas (média)

- **O que mudar.** No app: abrir 170 → **210 ms** (fecha 80 / segura 40 /
  abre 210 ≈ 8 q a 24 fps), a pálpebra do olho que vai na direção da virada
  fecha 1 q antes; `_piscaAgora` em **100 %** das sacadas > 0,35 e no início
  de todo gesto de cabeça dos tipos 1 e 3 (hoje 40 % e nenhum); a piscada
  começa 1 q **antes** do salto do olho (antecipação), com um toque de 1 u
  nas sobrancelhas. Na série: `piscaEm` passa a 4 quadros (meio fechado,
  fechado, fechado, meio aberto) a 30 fps, nunca um quadro só.
- **Onde.** `motor_de_vida.dart:1511`, `1551-1553`, `_gestosDeCabeca`;
  `b4.js:51` e o atlas de rostos (`bicho-*.webp`, quadro `m·7+6`).
- **Aceite.** Log: toda sacada > 0,35 tem `pisca > 0,5` dentro de ±3 q; na
  série, toda piscada passa por ≥ 1 desenho de olho meio-fechado antes e
  depois do fechado (3 desenhos no atlas, não 1).
- **Fontes.** F19, F18, F20 (hold inicial animado = o olho vivo).

### R9 — Virada de cabeça em 8 q com antecipação contrária e arco para baixo (média)

- **O que mudar.** `_virada`: `f 1,6; ζ 0,72` → **`f 3,0; ζ 0,55; r −0,4`**
  (anticipa 1–2 q para o lado oposto, chega em ≈ 8 q, passa 5 % e assenta);
  a trajetória da cabeça desce **2 u no meio** da virada (arco para baixo) e
  volta; a cabeça gira 1 q depois do olho e o corpo (`verga`) 2 q depois da
  cabeça.
- **Onde.** `motor_de_vida.dart:578`, `1163-1175`, `pet.dart:2499-2503`.
- **Aceite.** Resposta a um degrau de olhar 0 → 0,7 (log por quadro): `virada`
  cruza −0,02 nos 2 primeiros q, atinge 90 % em ≤ 9 q, overshoot ≤ 8 %; a
  altura da cabeça tem um mínimo entre os q 3 e 6.
- **Fontes.** F20 (antecipação contrária, arco para baixo, um intervalo on
  twos), F19 (piscar na virada), F5 (cabeça arrasta atrás do peso).

### R10 — Nado por espécie: lontra vertical com patas juntas, axolote lateral crescendo até a ponta (média)

- **O que mudar.** Lontra (e capivara, quando mergulha): as patas traseiras
  remam **simultâneas** (tirar o `+0,5` de fase em `pet.dart:5862` para a
  lontra), a onda do corpo é **vertical** (dorso sobe e desce 4 u, cauda
  chicoteia para cima 2–3 q depois) e viaja de frente para trás; braçada 0,9 s.
  Axolote: onda **lateral** (S), amplitude 0 atrás da cabeça → **máxima na
  ponta da cauda** (hoje máxima no meio do corpo, `deformador.dart:432`,
  `0,35 + 0,65·(1 − |h − 0,5|)`), comprimento de onda ≈ 1 corpo, e a
  velocidade vem só da **frequência** (0,8 Hz boiando, 2,5 Hz fugindo), não
  da amplitude. Tartaruga e pinguim: patas remam alternadas (não há fonte
  lida sobre o nado deles; manter).
- **Onde.** `pet.dart:5862`, `deformador.dart:431-440`, `episodios.dart:308`.
- **Aceite.** Na folha de nado do axolote, a amplitude lateral do alfa na
  faixa da cauda (último quinto) é ≥ 3× a da faixa logo atrás da cabeça; na
  da lontra, as duas patas traseiras têm o mesmo y em todos os quadros.
- **Fontes.** F14 (patas traseiras simultâneas; cauda dorsoventral; onda mais
  rápida que o corpo), F15 (anguiliforme; frequência regula a velocidade;
  amplitude mínima atrás da cabeça e máxima na ponta).

### R11 — Pinguim ginga de verdade, tartaruga arrasta e para, buldogue bamboleia aberto (média)

- **O que mudar.** Pinguim: rolamento **±7°** pelo pé de apoio (hoje 2,6°),
  deslocamento lateral do centro de ±3 u, quase sem sobe-desce (1 u), cabeça
  contra-inclinada 1 q atrás, nadadeiras abrindo 10° no lado do pé livre;
  1,8 passos/s. Tartaruga: **sem** `sobeNoPasso` e sem `_elastico` (zero),
  cabeça avança 3 u no apoio e recua na passagem, e **pausa de 0,5–2 s a cada
  3–6 passos** (duração lognormal) com o olhar varrendo. Buldogue: patas
  traseiras abertas (abdução 30–40°: apoio 1,3× mais largo que o das
  dianteiras), rolamento ±5° e quadril ±1 — o "bamboleio" é o rolamento com
  pouco sobe-desce, não um salto menor.
- **Onde.** `motor_de_vida.dart:1226-1230` (`sobeNoPasso` por espécie),
  `1270` (gingado por espécie), episódios de passeio da tartaruga em
  `episodios.dart`; patas do buldogue em `_buldogue` (`pet.dart`).
- **Aceite.** Pinguim: o centroide horizontal do alfa oscila ≥ 3× o vertical
  no laço (hoje o vertical domina); tartaruga: topo da caixa varia ≤ 2 px em
  24 q e há ≥ 1 pausa ≥ 0,5 s em 10 s de filmagem; buldogue: distância entre
  patas traseiras ≥ 1,3× a das dianteiras no quadro de contato.
- **Fontes.** F9 (lateral ≈ 3× ântero-posterior; 0,5 m/s), F10 (pausa; não
  recupera energia), F11 (abdução > 40°/30°, rotação externa > 30°).

### R12 — Coruja: batida mais rápida, decolagem e pouso com flare (baixa)

- **O que mudar.** Batida de cruzeiro 0,36 s (2,8 Hz) → **0,25 s (4 Hz, 6 q
  por batida)**, decolagem 0,2 s (5 Hz); planeio só depois de ≥ 4 batidas.
  Pouso: nos últimos 0,3 s, asas altas (θ 1,15 rad já existe no `freio`),
  pernas longas estendidas **+10 u para baixo** e corpo inclinado −12°, duas
  meias-batidas rápidas (0,15 s) e squash +0,4 no toque com as asas fechando
  4 q **depois** do corpo (overlapping). No chão, ela **anda, saltita e corre**
  (F12): a corridinha de 2,5 passos/s em vez de saltos de mascote.
- **Onde.** `episodios.dart:892-897`, `pet.dart:3311-3360`,
  `motor_de_vida.dart:1316-1323`.
- **Aceite.** Filmagem a 30 fps: 4 ± 0,5 batidas/s em cruzeiro; no pouso, o
  ponto mais baixo das pernas fica ≥ 8 u abaixo do corpo por ≥ 4 q antes do
  toque; as asas atingem o repouso ≥ 4 q depois de `_noChao`.
- **Fontes.** F13 (~6 Hz real; quatro fases), F12 (walk, hop, run; pernas
  longas), F21 (segmentos defasados). **[Opinião]** 4 Hz em vez de 6: a 24
  fps, 6 Hz são 4 q por batida e a asa vira borrão; 6 q por batida ainda lê
  como "rápido".

### R13 — Ocioso de 1 s: o que muda e o que não muda (baixa)

- **O que mudar.** Em qualquer segundo parado devem mudar, com amplitudes
  legíveis e relógios independentes (o motor já tem a estrutura, laudo 21/22):
  respiração **2,5–3,5 s** de período (18–24/min, dentro de cão 18–34 e gato
  16–40) com 2,5 % da altura do tronco; troca de apoio de pé a cada 4–8 s
  (3 u de deslocamento do quadril, 20 q de duração); 1 sacada (já); 1 piscada
  a cada ~3,5 s (já); cauda numa onda lenta de 2–3 s; e **nenhum** quadro
  igual ao anterior (moving hold). O que **não** muda em 1 s: a direção do
  corpo, a boca (fora da fala), a pose dos membros.
- **Onde.** `motor_de_vida.dart:417-423`, `1035-1053`; `pet.dart:2512-2516`
  (troca de apoio a `pose.ciclo`, hoje amplitude 0,3 e período 7 s).
- **Aceite.** Em 60 quadros consecutivos a 60 Hz, nenhum par de quadros
  idênticos (hash do `SaidaDaVida`); em 10 s, ≥ 1 troca de apoio com
  deslocamento horizontal do centroide ≥ 2 px.
- **Fontes.** F17 (frequência respiratória), F21 (moving hold de 10 q), F20
  (hold inicial animado em ciclo), F19 (piscar mais do que se pensa).

### R14 — Capturar o motor real, não a fórmula `passoNa` (média)

- **O que mudar.** As folhas da série saem do `MotorDeVida` com semente fixa,
  `dt = 1/24`, velocidade forçada (`alvoX` longe, `podeAndar`), gravando os 24
  (ou 30) quadros de **um ciclo depois de 1,5 s de aquecimento** (intensidade
  já em 1, cabeça atrasada, cauda, orelhas e piscar já vivos). `passoNa` fica
  só como teste de regressão numérica. Cada folha leva no `animacoes.json` a
  cadência de captura (`fps`) e o quadro de contato (`contato: [0, 12]`) para
  o `b4.js` tocar no ritmo certo e trocar de pose na fase certa (R6).
- **Onde.** `novelinha_anim24_test.dart:54-91`, `112-165`; `tool/folhas_do_site.py`;
  `b4.js:111-114`.
- **Aceite.** Na folha nova, ≥ 4 regiões (corpo, cauda, orelha, olho) mudam
  entre os quadros 0 e 6 (hoje só o corpo); R1 e R2 passam.
- **Fontes.** F24/F25 (animação e código juntos; poucas chaves, interpolação
  viva), F26 (reaproveitar ciclos é prática — se o ciclo for bom).

---

## 4. O que não fazer

- **Não tocar em pingue-pongue** nada que tenha direção: piscada (fecha rápido,
  abre devagar — F18/F19), sacada (olho antes da cabeça), passo (contato →
  down → passagem → up), respiração com suspiro. Pingue-pongue serve para
  pêndulos simétricos, e mesmo assim com os quadros de virada removidos (F23).
- **Não somar um quique em JS por cima de uma folha que já quica**
  (`b4.js:200`): dois ritmos não comensuráveis são tremor, não energia.
- **Não tocar 24 quadros a 16 fps** nem a 25,6 fps num render de 30 fps: os
  quadros se repetem em padrão 1-2-2-1 e o olho vê o solavanco. Capturar na
  taxa de exibição.
- **Não concentrar o squash num único quadro no contato** nem pôr o estirão
  máximo no ápice: o peso desce *depois* do contato e sobe *depois* da
  passagem (F1); o estirão acompanha a velocidade, e no ápice ela é zero.
- **Não decolar no mesmo quadro em que agacha** (`pula`, susto): sem 3–5 q de
  antecipação o salto lê como teleporte (F20, F21).
- **Não espelhar o ciclo inteiro para o segundo passo** sem trocar o lado da
  pelve, do ombro, da cabeça e da cauda: dá o pogo das folhas atuais (F4, F5,
  F6).
- **Não fazer a tartaruga quicar** nem ter velocidade "preferida" constante:
  ela arrasta e para (F10). Não fazer o pinguim subir e descer: ele vai de
  lado (F9).
- **Não deixar o corpo sair do quadro de captura** (topo 0, lados 0/180): toda
  folha com alfa encostado na borda é descarte automático.
- **Não aumentar o detalhe para "dar vida"** (mais pelos, mais sombras): a
  vida está no timing e na alternância de poses simples (F26); um bicho com
  cauda, orelha e cabeça que se mexem em 2–3 q de atraso parece mais vivo que
  um bicho detalhado e rígido.
- **Não reabrir** Rive/rig externo nem as chaves das espécies (decisões
  tomadas, 00-SINTESE).

---

## 5. Fontes (lidas em 08/11/2026)

Animação (livros, tutoriais de escola, estúdios):

- F1 — Resumo de estudante de *The Animator's Survival Kit* (R. Williams,
  2001), tabela de tempos p. 109 e poses do andar pp. 102–115:
  <https://s184753.blogspot.com/2019/01/more-research-animators-survival-kit.html>
  (secundária; os números são os do livro conforme o resumo)
- F2 — Ulster University, *Animation Strategies: Regular Run Cycle* (cita
  Williams 2001 e Blair 1994):
  <https://blogs.ulster.ac.uk/scottmoore/?p=1864>
- F3 — GarageFarm, *Walk Cycle: Easy Steps to Animate Walking Animation*:
  <https://garagefarm.net/blog/walk-cycle-easy-steps-to-animate-walking-animation-for-beginners>
- F4 — *Animating a Walk Cycle from Front View*:
  <https://gaming-animation.blogspot.com/2012/05/walk-cycle-front-view.html>
- F5 — Pushing Poses, *Basic Walk Cycle, part 2* (passagens de Williams):
  <https://pushingposes.blogspot.com/2008/03/basic-walk-cycle-part-2.html>
- F6 — Wikipedia, *Walk cycle*: <https://en.wikipedia.org/wiki/Walk_cycle>
- F19 — Animation Apprentice, *How to avoid zombie eyes* (piscada 8 q, 2
  fechados, defasagem, piscar na virada):
  <https://animationapprentice.blogspot.com/2024/04/how-to-avoid-zombie-eyes.html>
- F20 — Brian Lemay, *Take keys* (antecipação, virada, stagger):
  <https://brianlemay.com/Pages/animationschool/animation/2ndsemesteranimation/05Take/takekeys.html>
- F21 — CAVE Academy, princípios aplicados ao salto (overlapping por "couple
  of frames", pouso em 2 q, moving hold 10 q): <https://caveacademy.com/?p=10622>
- F26 — Cartoon Brew, entrevista com Grant Orchard (*Hey Duggee*):
  <https://www.cartoonbrew.com/?p=149069>

Ferramentas e jogos:

- F22 — Esoteric Software, *Spine Runtimes: Applying animations* (mix
  durations): <https://esotericsoftware.com/spine-applying-animations>
- F23 — Adobe Community, *How to do a loop that bounces (pingpong)*:
  <https://community.adobe.com/questions-540/how-to-do-a-loop-that-bounces-pingpong-after-hitting-end-144038>
- F24 — Game Developer / GDC 2014, D. Rosen, *An Indie Approach to Procedural
  Animation* (descrição da sessão):
  <https://www.gamedeveloper.com/design/video-an-indie-approach-to-procedural-animation>
  e <https://www.gameanim.com/?p=15568>
- F25 — Alan Zucconi, *An Introduction to Procedural Animations* (Rain World,
  Grow Home): <https://www.alanzucconi.com/2017/04/17/procedural-animations/>

Biologia e biomecânica:

- F7 — Wikipedia, *Gait* (duty factor, sequências laterais, marchas
  assimétricas): <https://en.wikipedia.org/wiki/Gait>
- F8 — PEI Untamed, *Canine gaits* (raposa/coiote: trote de registro direto,
  side trot, lope): <https://www.pei-untamed.com/post/canine-gaits>
- F9 — Griffin & Kram, *Penguin waddling is not wasteful*, Nature 408 (2000):
  <https://spot.colorado.edu/~kram/penguins.pdf>
- F10 — Sellers, Rose, Crossley & Codd, *Inferring cost of transport from
  whole-body kinematics in three sympatric turtle species*:
  <https://cronfa.swansea.ac.uk/Record/cronfa54311>
- F11 — *In vivo kinematics of the patella in French bulldogs* (esteira, andar
  e trote), BMC Vet Res 2021: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7881552>
- F12 — Animal Diversity Web, *Athene cunicularia* (coruja-buraqueira):
  <https://animaldiversity.org/accounts/Athene_cunicularia/>
- F13 — Ben-Gida et al., *Unique flow features of the silent southern Boobook
  owl wake during flapping flight* (arXiv 1804.08772):
  <https://arxiv.org/abs/1804.08772>
- F14 — Duff & Fish, SICB, *Swimming kinematics of the giant river otter*
  (resumo): <https://sicb.org/?p=35027>
- F15 — D'Août, Aerts & De Vree, *Kinematics of steady swimming in the axolotl*
  (Belgian Congress of Zoology, 1993):
  <https://www.vliz.be/imisdocs/publications/358121.pdf>
- F16 — *Anatomical adaptations of the capybara locomotor apparatus*,
  Braz. J. Vet. Res. Anim. Sci. (USP):
  <https://revistas.usp.br/bjvras/article/download/172323/168610>
- F17 — Merck Veterinary Manual, *Resting respiratory rates*:
  <https://www.merckvetmanual.com/multimedia/table/resting-respiratory-rates>
- F18 — Kwon et al., *High-speed camera characterization of voluntary eye
  blinking kinematics*, J. R. Soc. Interface (2013):
  <https://pmc.ncbi.nlm.nih.gov/articles/PMC4043155>

Material interno medido:

- `/home/user/lhcx/video/hf/novelinha-ep1/assets/img/app/corre-fox.webp` e
  `anda-otter.webp` (caixas de alfa por quadro, §1.6);
  `/home/user/baru/baru_app/lib/widgets/vida/motor_de_vida.dart`,
  `episodios.dart`, `deformador.dart`; `/home/user/baru/baru_app/lib/widgets/pet.dart`;
  `/home/user/lhcx/video/hf/novelinha-ep1/gera/app_capturas/novelinha_anim24_test.dart`;
  `/home/user/lhcx/video/hf/novelinha-ep1/assets/b4.js`.

Não lidas (tentativas falharam em 08/11: 503/403/redirecionamento): Monmouth
*Movement: Walk Cycle*; Toon Boom *Four-legged walk cycle* e *Head turn*;
Tuts+ *walking from the front view*; Pixar in a Box. Os números de Williams
vêm de F1/F2/F5, que o citam; vale conferir no livro (pp. 102–115).

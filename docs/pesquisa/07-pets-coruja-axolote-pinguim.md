# Laudo 07: Coruja (Nina), Axolote (Lume) e Pinguim (Nino)

Pesquisa dedicada às três espécies, com crescimento visível, jornada própria,
visual, voz e itens. Outubro de 2026.

**Legenda usada em todo o laudo**

- **[F]** fato com fonte (link na seção 9; † = lido só pelo resumo da busca,
  sem abrir a página inteira. Conferir antes de usar em texto público).
- **[A]** observação do app (arquivo:linha ou imagem que eu abri).
- **[I]** inferência ou opinião minha.

**Limites desta pesquisa.** O WikiAves devolveu 403 e o PDF do Scolaro (1987)
redirecionou para fora. A cota de buscas web da sessão acabou antes de eu
procurar uma fonte para o pinguim-de-magalhães que "dá pedrinha de presente" e
para posturas de sono de pinguim, então essas duas coisas **não** entram como
fato. Nada aqui foi gerado no ElevenLabs. A seção 1.5 e as seguintes trazem
só os prompts.

---

## 0. Resumo executivo

1. **Os três bichos não crescem.** Não existe estágio de vida em lugar nenhum
   (`pet.dart`, `progressao.dart`, `models.dart`) [A]. O pedido do dono ("a
   coruja começa em um ovo") pede um sistema novo: **contador de sessões por
   espécie, 5 estágios, piso que nunca desce, cena de transição**. Ver §0.2.
2. **O humor "sentindo falta" lê como bravo nas três espécies, e o motivo é um
   bug de espelhamento.** A sobrancelha e a pálpebra triste são desenhadas com
   a mesma inclinação nos dois olhos (`pet.dart:3605-3625`). Assim, um olho fica
   triste e o outro fica zangado. Dá para ver nos três PNGs `*-saudade.png` [A].
3. **A lágrima cai fora do rosto.** `_pingo` usa uma posição fixa no quadro
   (`pet.dart:3998`, 30% da largura). Na coruja ela cai na lateral do corpo, no
   axolote cai na guelra, e nos dois lê como gota de suor [A].
4. **O axolote não tem cauda** (`pet.dart:2071-2158`) [A]. A barbatana da
   cauda, que vai de trás da cabeça até a cloaca, é traço definidor da espécie
   [F Wiki-Axolotl]. As guelras estão desenhadas como pétalas lisas. As de
   verdade são três pares de ramos com filamentos plumosos [F Wiki-Axolotl;
   SDZG-carac].
5. **O pinguim parece um passarinho genérico.** Tem bico e pés laranja, cabeça
   e corpo em duas bolas empilhadas, e na pose "contente" não tem boca [A].
   Proposta: virar **pinguim-de-magalhães**, a espécie que chega à costa
   brasileira [F Wiki-Magellanic; Bem Paraná†]. Ele tem duas faixas pretas no
   peito, que o juvenil **não tem** [F CES]. Isso entrega de graça um estágio
   de crescimento "extremamente visível".
6. **A coruja tem tufos de corujão.** Coruja-buraqueira e suindara, as duas mais
   conhecidas no Brasil, **não têm tufos** [F Wiki-BUOW; PMSP-suindara]. Proposta:
   Nina vira **coruja-buraqueira**. Ela vive no chão, numa toca, é ativa de dia
   e tem olho amarelo, sobrancelha branca e perna comprida
   [F Cornell-BUOW-ov; Wiki-BUOW]. A toca torna o "começa em um ovo" literal e
   tira a coruja do lugar estranho em que está hoje, voando sobre a lagoa.
7. **A sobreposição desenha o axolote e o pinguim com orelhas redondas de
   mamífero e focinheira** (`OverlayDoBaru.kt:335-348`, `:361-380`) [A]. Só a
   coruja ganha um desenho próprio ali. O estágio de crescimento novo tem de
   chegar à sobreposição também, senão o item 7 do brief piora.
8. **As animações ociosas são as mesmas seis para as nove espécies**
   (`pet.dart:554-561`) [A]. Proponho de 4 a 5 gestos-assinatura por espécie,
   todos tirados de comportamento real: o giro de cabeça e o balanço de
   paralaxe da coruja, o gole de ar e a sucção do axolote, a exibição extática,
   o alisar de penas e o microcochilo do pinguim.

---

## 0.1 Achados que valem para as três espécies

| # | Achado | Evidência |
|---|---|---|
| T1 | Sobrancelha triste não espelhada: no olho esquerdo a ponta de dentro desce (zangado), no direito sobe (triste) | `pet.dart:3618-3624` desenha `(-0.9r,-1.5r)→(0.5r,-1.1r)` igual nos dois olhos. Imagens: `pet-owl-saudade.png`, `pet-axolotl-saudade.png`, `pet-penguin-saudade.png` [A] |
| T2 | A pálpebra caída tem o mesmo defeito | `pet.dart:3605-3616`: borda de `-0.35r` à esquerda e `-0.75r` à direita nos dois olhos [A] |
| T3 | Lágrima em posição fixa do quadro, desligada da anatomia | `pet.dart:3996-4009` [A]. Na coruja cai em x≈360/1200, na borda do corpo; no axolote, sobre a guelra [A, imagens] |
| T4 | "Radiante" e "contente" quase iguais nas duas espécies de bico (coruja e pinguim): só mudam a bochecha e os brilhos | `pet-owl-radiante/contente.png`, `pet-penguin-radiante/contente.png` [A]. O bico não muda com o humor (`pet.dart:2050-2060`, `:2261-2280`) |
| T5 | No radiante, a bochecha do pinguim é rosa a 24% de opacidade sobre azul-acinzentado e vira uma mancha cinza-barrenta | `pet.dart:3743-3749` + `pet-penguin-radiante.png` [A] |
| T6 | Habitat único de lagoa. No humor radiante, a atividade é `swim` (`state.dart:952-953`): o axolote e o pinguim ficam **em pé**, com água até o peito, e a coruja paira sobre a água de asas abertas | `home-axolotl.png`, `home-penguin.png`, `home-owl.png` [A] |
| T7 | À noite a coruja faz exatamente o que faz de dia | `home-owl-noite.png` × `home-owl.png` [A]. A coruja-buraqueira caça sobretudo no crepúsculo [F Wiki-BUOW], e essa chance de identidade fica perdida |
| T8 | Ociosos genéricos e iguais para todas | `pet.dart:544-573` [A] |
| T9 | As paletas são escadas de tom do mesmo pelo: 6 rosas no axolote, 6 azul-acinzentados no pinguim | `design/tokens.dart:101-128` [A]. O axolote real tem morfos de cor bem distintos [F Wiki-Axolotl; Axolotl.org] |
| T10 | Sobreposição genérica (orelhas redondas no axolote e no pinguim) | `OverlayDoBaru.kt:335-348` [A] |
| T11 | O seletor de espécie é só texto, sem miniatura do bicho, e o cartão do companheiro tem 120 px de altura, onde as escamas de pena da coruja e os dedos do pinguim somem | `pet_profile.dart:144-176`, `:204-213` [A] |

**O que já funciona e deve ser mantido** [A/I]: traço chapado com curvas de
Bézier e paleta quente, construção coerente entre as espécies (o mesmo olho,
o mesmo brilho, a mesma família de formas), sono legível (arcos e "Z") e o
sorriso largo do axolote, que é exatamente o traço pelo qual o axolote real é
querido.

---

## 0.2 O modelo de crescimento comum às três espécies

**Regra proposta** [I]:

- **Contador por espécie**: `sessoesCom[especie]`, que soma uma sessão
  concluída com aquela espécie ativa. Fica em `local_store` e no snapshot.
- **Estágio** = função do contador, com os limiares em `Balanco`
  (`progressao.dart`), que é onde moram todos os números do jogo
  (`progressao.dart:1-6`):

| Estágio | Entra quando | Tempo típico* | Altura na cena (adulto = 100%) |
|---|---|---|---|
| 1 Ovo | espécie recém-chegada | 0 | 30% |
| 2 Recém-nascido | **1ª sessão concluída**: a própria sessão choca o ovo | 1º dia | 42% |
| 3 Filhote | 5 sessões | ~2–3 dias | 60% |
| 4 Jovem | 15 sessões | ~1 semana | 80% |
| 5 Adulto | 40 sessões | ~3 semanas | 100% |

\* Estimativa minha a partir da conta que o próprio código usa, "~70 XP/dia
(duas sessões...)" (`progressao.dart:274-276`). Não é medição de uso real.

- **Nunca desce.** O estágio guardado é `max(guardado, derivado)`. Trocar de
  espécie congela o estágio daquela espécie e não zera nada. Ficar dias sem
  abrir o app não faz o bicho encolher nem voltar a ser ovo (contrato: nada se
  perde).
- **Nunca por dinheiro.** Não existe item, pacote ou assinatura que acelere o
  estágio. O crescimento vem só de sessão de foco.
- **Contas antigas (piso de posse).** Toda espécie já liberada antes da
  atualização entra no estágio 5. Quem já tinha a Nina adulta não pode abrir o
  app e encontrar um ovo, porque isso seria tirar dela algo que já existia. Nos
  ajustes entra um "Ver como a Nina nasceu", que reproduz as 4 transições como
  replay, só cosmético. Espécies liberadas **depois** da atualização chegam
  como ovo.
- **Onde o estágio aparece**: home, cartão do companheiro, celebração, trilha
  (nó "chegou" vira "chegou um ovo"), relatório e **sobreposição**.
- **O ovo durante a 1ª sessão**: a cada 20% do tempo da sessão aparece uma
  rachadura nova. A eclosão acontece na tela de resultado. Se a pessoa
  desistir, o ovo **não esfria nem sofre**: ele só continua inteiro e
  balançando, à espera da próxima sessão (sem punição).
- **Proporção**: quanto mais novo, maior a cabeça em relação ao corpo e
  maiores os olhos em relação à cabeça. É o esquema de bebê, cujo efeito em
  fofura percebida e em vontade de cuidar foi medido em rostos humanos
  [F Glocker 2009]. Extrapolar para bichos desenhados é inferência minha [I].

---

## 1. Coruja: Nina

### 1.1 Biologia real

**Escolha de espécie-base: coruja-buraqueira (*Athene cunicularia*)** [I],
pelos fatos abaixo:

- Ocorre no Brasil central e oriental (subespécie *A. c. grallaria*), do sul do
  país e do Pantanal até a Patagônia, e vem se expandindo na Amazônia central
  com o desmatamento [F Wiki-BUOW].
- Vive no chão, em toca cavada ou tomada de outro animal, e fica de pé no
  montinho de terra da entrada, às vezes só com a cabeça para fora
  [F Cornell-BUOW-ov]. Isso combina com uma cena no chão e acaba com a coruja
  "voando sobre a lagoa" (T6).
- É ativa de dia, sobretudo no começo da manhã e no fim da tarde
  [F Cornell-BUOW-ov], e caça mais no crepúsculo [F Wiki-BUOW]. Ou seja,
  aparece acordada na home de dia **e** tem um motivo biológico para mudar ao
  entardecer.
- Não tem tufos, tem disco facial achatado, sobrancelha e queixo brancos
  marcados, pintas brancas no dorso marrom e perna longa
  [F Wiki-BUOW; Cornell-BUOW-ov]. Olho amarelo vivo [F Cornell-BUOW-ov].

Alternativas descartadas como base (podem virar referência de itens):

- **Suindara (*Tyto furcata*/*alba*)**: rosto em coração, branca, ninho em
  torres e sótãos [F PMSP-suindara]. O grito é um rasgado alto
  [F Cornell-BAOW-sons]. No Norte e no Nordeste ela é a "rasga-mortalha",
  ave de mau agouro no folclore [F PortalAmazônia†]. Para um bicho fofo que
  chama a pessoa de volta, esse peso cultural é um risco [I].
- **Corujinha-do-mato (*Megascops choliba*)**: tem tufos pequenos, olho
  amarelo e vive em áreas residenciais [F Wiki-Megascops]. Seria a opção para
  **manter** os tufos do desenho atual. Fica como plano B (§8).

**Ciclo de vida e estágios (buraqueira, com barn owl de apoio onde faltou dado)**

| Estágio real | Idade | Aparência | Fonte |
|---|---|---|---|
| Ovo | postura de 2–12 (Cornell) ou 4–12, em geral 9 (Wiki); incubação de 28–30 dias (Cornell) ou 3–4 semanas (Wiki) | branco e liso, 3–3,4 × 2,5–2,8 cm | [F Cornell-BUOW-LH; Wiki-BUOW] |
| Eclosão | — | o filhote rompe a membrana e a casca com o **dente do ovo**, descansa e depois "zipa" a casca em volta (padrão das aves; tempos variam por espécie) | [F JourneyNorth (águia)] |
| Recém-nascido | 0–~10 dias | penugem branco-acinzentada, indefeso, **olhos fechados** | [F Cornell-BUOW-LH] |
| Abre os olhos | ~10 dias (suindara) | — | [F SouthDowns†] |
| 2ª penugem (mesoptile) | 1–3 semanas, conforme a espécie | penugem mais grossa e cinzenta substitui a primeira | [F OwlPages; SouthDowns†] |
| Jovem | ~4 semanas: primeiros voos curtos | menos pintas brancas no dorso, peito amarelado-claro (buff) e liso, faixa buff na asa | [F Wiki-BUOW] |
| Sai do ninho | 44–53 dias | — | [F Cornell-BUOW-LH] |
| Dependência | pais alimentam por 1–3 meses | — | [F Wiki-BUOW] |

"Brancher" é o estágio das corujas de árvore em que o filhote sai do ninho
antes de voar, pulando e escalando galhos enquanto os pais seguem
alimentando [F SussexWT†; Cornell-cams†]. Na buraqueira o equivalente é o
jovem que passa o dia no montinho da toca e arrisca voos curtos por volta de 4
semanas [F Wiki-BUOW]. O que eu chamo de "jovem de montinho" adiante é uma
adaptação minha [I].

**Comportamentos marcantes**

- **Balança a cabeça** para cima e para baixo quando está perturbada e quando
  mira presa [F Cornell-BUOW-LH]. Ao balançar, abre o babador branco
  [F Wiki-BUOW].
- **Balanço lateral (paralaxe)**: o olho quase não se move na órbita, então a
  coruja move a cabeça inteira, e o balanço ajuda a medir distância. O
  mecanismo exato ainda é debatido [F ORI-paralaxe†].
- **Gira a cabeça até ~270°** para cada lado sem cortar o sangue do cérebro
  (Johns Hopkins, *Science* 2013) [F ScienceDaily].
- **Forra a entrada da toca com esterco**, que atrai insetos que ela come
  [F Cornell-BUOW-ov]. Guarda comida na toca [F Cornell-BUOW-ov].
- **Os jovens brincam de caçar** no esterco em volta da toca
  [F Cornell-BUOW-LH].
- **Corre atrás de presa** com as pernas longas [F Wiki-BUOW].

**Vocalizações reais**

- O macho dá um **arrulho de duas notas** parecido com o de codorna, o som mais
  comum da espécie. A espécie "não é especialmente vocal" [F Cornell-BUOW-sons].
- Os filhotes fazem um "**eep**" e sons ásperos. O mais intenso imita o **chocalho
  da cascavel** e espanta predadores [F Cornell-BUOW-sons; Wiki-BUOW].
- Suindara: grito rasgado de ~2 s, ronronado suave entre o casal, chiado de
  3–4 s contra intrusos, estalo de bico quando agitada [F Cornell-BAOW-sons]. O
  estalo de bico e o "bufar" também aparecem na suindara paulistana
  [F PMSP-suindara].

**Linguagem corporal ligada a estado**

| Estado | Sinal | Fonte |
|---|---|---|
| Relaxada | tufos baixos mas não colados (nas espécies com tufo), penas da cabeça neutras, **pálpebra superior um pouco baixa**, plumagem solta e fofa | [F IOC†; WorldOfOwls†] |
| Alerta ou estressada | magra, penas apertadas, olhos bem abertos, balançando a cabeça, pronta para voar | [F GoldenGate†; WorldOfOwls†] |
| Ameaça (suindara) | asas abertas, cabeça baixa balançando, chiado e estalo de bico | [F Vassar†] |
| Filhote dormindo | queixo apoiado no chão é mais comum que dormir de bruços (que acontece, mas é raro) | [F Snopes] |
| Confortável | se limpar ignorando o observador é sinal de conforto | [F IOC†] |

**Habitat e alimentação**: áreas abertas de vegetação baixa e rala
[F Cornell-BUOW-LH]. Come principalmente insetos (gafanhoto, grilo, besouro)
em número de itens e pequenos vertebrados em massa [F Cornell-BUOW-LH].

### 1.2 O desenho atual

Abri: `pet-owl-{radiante,contente,sono,saudade}.png`,
`home-owl.png`, `home-owl-noite.png`, e li `pet.dart:1858-2066`.

| Critério | Avaliação |
|---|---|
| Proporção | Cabeça (86×70) quase da largura do corpo (94×100). Lê como coruja de livro infantil, e isso é bom [A]. Os pés ficam quase escondidos sob a barriga, e uma buraqueira sem perna perde a marca da espécie [A/F] |
| Legibilidade | Os tufos grandes e o disco duplo fazem ler "coruja" na hora [A]. Mas os tufos dizem jacurutu ou corujão-orelhudo, não buraqueira nem suindara [F Wiki-BUOW] |
| Olhos | Esclera branca + íris marrom + pupila (`pet.dart:3577-3592`). Coruja real não mostra branco no olho. A íris da buraqueira é amarela [F Cornell-BUOW-ov]. O olho branco é o que deixa a Nina com cara de "assustada" mesmo no contente [A/I] |
| Fofura | Alta no sono (arcos + folha + Z). Média no contente: sem boca, a cara depende só do olho, que não muda [A] |
| Clareza de humor | Radiante ≈ contente (T4). A saudade lê como **desconfiada ou brava** (T1, T2) e a gota fica fora do rosto (T3) [A] |
| Consistência com as outras | Boa no traço. Mas o bico em triângulo laranja é **idêntico** ao do pinguim (`pet.dart:2050-2060` × `:2261-2271`), e as duas espécies de bico ficam com a mesma "cara de triângulo sob dois olhos" [A] |
| Na cena | Radiante = voo sobre a lagoa (`pet.dart:118-123`). Na home, asas abertas e garras recolhidas sobre a água parecem um mergulho de pesca ou um pouso na água [A/I]. À noite, nada muda (T7) |
| Escamas do peito | Três fileiras de arcos (`pet.dart:1909-1924`) que somem a 120 px (`pet_profile.dart:204-213`) [A] |

### 1.3 Cinco estágios: Nina, coruja-buraqueira

Paleta-base sugerida para o adulto [I]: dorso `#9A7552`, pintas `#F3E9D8`,
peito `#EAD9BC` com barras `#A8835E`, disco `#C9A982` com contorno `#7A5B40`,
sobrancelha e babador `#FBF6EC`, íris `#F2C230`, pupila `#2B2118`, bico
`#CDB878` (o bico é "amarelo-escuro ou cinza" conforme a subespécie
[F Wiki-BUOW]), pernas `#D2C6AE`. As 6 pelagens de `pelagemCoruja` continuam
como tons de areia e canela.

| # | Nome no app | Silhueta e proporção | Cores | Detalhes que surgem | Base real |
|---|---|---|---|---|---|
| 1 | **Ovo na toca** | oval vertical 0,78:1, 30% da altura do adulto, apoiado num ninho de capim seco. Atrás dele, um arco de terra (a boca da toca) em corte | casca `#F6F1E7` com brilho `#FFFFFF` a 60%; capim `#C9A86A`; terra `#8B6A4E` | balança; um coração tênue pulsa por dentro quando a pessoa toca | ovo branco e liso [F Cornell-BUOW-LH]; toca [F Cornell-BUOW-ov] |
| 2 | **Recém-nascida** | pera sentada; **cabeça = 60% da altura total**; sem pernas visíveis; bico grande e claro; asinhas em toco | penugem `#E9E4DC` com sombra `#CFC7BB`; bico `#E6DCC4` | **olhos fechados** (dois arcos) nas primeiras horas. Na 2ª sessão acontece o micro-evento "Nina abriu os olhos" | penugem branco-acinzentada, olhos fechados [F Cornell-BUOW-LH]; olhos abrem ~10 d [F SouthDowns†] |
| 3 | **Filhote de penugem** | bola quase perfeita, 1:1, pernas finas e compridas saindo por baixo (a marca da buraqueira já aparece aqui); cabeça = 50% | penugem `#C8BBA8` (cinza-bege mais grosso); olhos amarelos abertos | sobrancelha branca em esboço; primeiras penas marrons nas costas; tufinho de penugem arrepiado no topo da cabeça | 2ª penugem cinzenta [F OwlPages] |
| 4 | **Jovem de montinho** | corpo alongando (altura 1,25× largura), pernas longas inteiras, cabeça = 42% | dorso `#9A7552` com **poucas** pintas; peito **liso** `#E8D3A8` (buff) | faixa buff na asa; restos de penugem nas pontas da cabeça e das coxas; dá pulinhos-voo do montinho | juvenil com menos pintas, peito buff, faixa na asa; voos curtos com ~4 semanas [F Wiki-BUOW] |
| 5 | **Adulta** | ereta, pernas longas, cabeça = 38%; disco facial achatado, **sem tufos** | paleta-base acima | pintas brancas no dorso, barras no peito, sobrancelha e babador brancos marcados, íris amarela | [F Wiki-BUOW; Cornell-BUOW-ov] |

**Cenas de transição** (3–5 s, puláveis; com "reduzir movimento", uma troca
cruzada + texto) [I]:

- **1→2, a eclosão** (o exemplo do dono). O ovo balança 3 vezes, cada vez mais
  forte. Aparece uma rachadura em zigue-zague no terço de cima e **a pontinha
  do bico com o dente do ovo** (um ponto branco) fura a casca. Vem uma pausa de
  1 s, porque o filhote real descansa depois de furar [F JourneyNorth]. A
  rachadura então dá a volta no ovo, a tampa salta e **cai de chapéu na cabeça
  da corujinha**. A penugem sai "molhada" (contorno mais liso e escuro),
  sacode em 2 tempos e afofa. Termina com um "eep".
- **2→3**: a recém-nascida boceja, se encolhe numa bola e um "puf" de penugem
  sobe. Ela reaparece maior e redonda, com as pernas aparecendo uma de cada
  vez.
- **3→4**: ela sobe no montinho, balança a cabeça (o *head-bob* real), solta
  uma chuva de penugem e aparece com o peito liso. Arrisca um pulo-voo curto.
- **4→5**: entardecer (céu da cena em laranja). Ela gira a cabeça para trás e
  volta. Quando o rosto retorna, o disco está completo e a sobrancelha branca
  "acende". Fecha com o arrulho de duas notas [F Cornell-BUOW-sons].

### 1.4 Personalidade e humores

**Traço** [I, ancorado em fato]: *a sentinela calma*. Ela fica de guarda na
porta da toca [F Cornell-BUOW-ov], observa antes de agir e fica mais acesa no
fim da tarde [F Wiki-BUOW]. Isso conversa com a frase atual da espécie, "Mais
lúcida depois que escurece. Você precisa de silêncio, não de pressa."
(`l10n.dart:843-846`) [A].

| Humor | Como aparece na Nina |
|---|---|
| Radiante | olhos amarelos bem abertos, sobrancelhas brancas **erguidas**, **balança a cabeça** em ritmo de dança e abre o babador branco [F Wiki-BUOW], pulinhos nas pernas longas, penas afofadas (silhueta 5% maior). **Não voa sobre a lagoa**: o "nado" dela vira **caçar gafanhoto** (corre e salta do montinho) |
| Contente | plumagem solta, **pálpebra de cima um pouco baixa** [F IOC†], cabeça levemente inclinada, se limpa de vez em quando (sinal de conforto [F IOC†]) |
| Neutro | de pé no montinho, olhar à frente, pisca devagar, um balanço de paralaxe ocasional |
| Sonolento | olhos em fenda, cabeça afunda nos ombros, penas infladas viram uma bola. **Filhote**: apoia o queixo no chão [F Snopes] |
| Sentindo falta | de pé na entrada da toca, **cabeça girada para o lado da "porta"** (a borda da tela de onde a pessoa "chega"), sobrancelhas brancas com as pontas de dentro **para cima** (tristeza, corrigindo T1), ombros caídos. **Sem lágrima.** Ao abrir o app, ela gira a cabeça de volta e balança, contente de ver a pessoa |

**Animações-assinatura** (novos `GestoOcioso`, só da coruja):

1. **Giro de cabeça** (*giraCabeca*): a cabeça gira sobre o próprio eixo até
   ~180°, mostrando a nuca pintada, e volta. Real: até ~270° [F ScienceDaily].
   Uso 180° para ser fofo e não assustar [I]. **Como**: hoje `_cabecaGiro`
   (`pet.dart:1474-1480`) é só inclinação (`canvas.rotate`). O giro de verdade
   é eixo vertical: `scale(cos θ, 1)` no rosto e, passando de 90°, troca pelo
   desenho da nuca.
2. **Balanço de paralaxe** (*paralaxe*): quando a pessoa toca perto, a cabeça
   desliza de um lado para o outro e para cima e para baixo, "medindo a
   distância do dedo" [F ORI-paralaxe†].
3. **Balanço de cabeça** (*headBob*): sobe e desce rápido, com o babador
   aberto [F Cornell-BUOW-LH; Wiki-BUOW]. É a reação ao toque no radiante.
4. **Arrepia e assenta**: infla as penas, sacode e volta a ficar magra
   (relaxada vs. alerta [F WorldOfOwls†]).
5. **Caça ao gafanhoto**: um gafanhoto pula na cena, ela corre com as pernas
   longas e pega [F Cornell-BUOW-LH; Wiki-BUOW]. É o substituto do "voo"
   atual.

### 1.5 Voz e sons (prompts para ElevenLabs Sound Effects)

Tudo curto e baixo, sempre abaixo do `conquista.wav`. Prompts em inglês, que
é como o gerador de efeitos responde melhor [I].

| Arquivo | Quando toca | Prompt | Duração |
|---|---|---|---|
| `coruja_arrulho.wav` | radiante, transição 4→5, fim de sessão | "Soft gentle two-note cooing of a small burrowing owl, like a quail, warm and close, dry outdoor ambience, no echo" | 0,8 s |
| `coruja_eep.wav` | recém-nascida e filhote, toque | "Tiny owlet chick peep, single high soft 'eep', cute, very short" | 0,3 s |
| `coruja_chocalho_fofo.wav` | toque repetido muito rápido (cócegas) | "Very soft playful hissing rattle of an owlet, gentle and comic, not scary, quiet" | 0,6 s. Base real: chiado-chocalho do filhote [F Cornell-BUOW-sons]. **Nunca** em volume alto |
| `coruja_bico.wav` | caça ao gafanhoto | "Two tiny beak clicks, small bird, crisp" | 0,25 s |
| `coruja_penas.wav` | arrepia e assenta | "Soft feather ruffle and fluff shake, small bird" | 0,5 s |
| `ovo_racha_1..3.wav` | rachaduras durante a 1ª sessão | "Tiny eggshell crack, delicate, close-up" (3 variações) | 0,2 s |
| `ovo_eclode.wav` | eclosão | "Eggshell cap popping off with a soft pop followed by a tiny chick peep" | 0,8 s |

**Não usar** o grito da suindara: ~2 s de som rasgado [F Cornell-BAOW-sons], com
peso de mau agouro no folclore [F PortalAmazônia†].

### 1.6 Itens temáticos da coruja (comprados com folhas)

Os preços seguem a faixa atual da loja (40–400, `models.dart:258-509`) [A].
Nenhum item acelera o crescimento.

| Item (pt-BR) | Tipo | Onde aparece | Preço sugerido |
|---|---|---|---|
| Montinho da toca | objeto (Mata) | primeiro plano, à esquerda: monte de terra com a entrada da toca. Vira o "poleiro" da Nina | 120 |
| Óculos redondos de leitura | roupa · rosto | sobre o disco facial (variação do `oculos` existente) | 90 |
| Capelo de formatura | roupa · cabeça | entre as sobrancelhas, inclinado | 150 |
| Pilha de livros | objeto (Mata) | ao lado do montinho; a Nina sobe nela quando está radiante | 140 |
| Lua crescente de pano | objeto (Noite) | pendurada no céu da cena, brilha à noite | 180 |
| Gafanhoto de pelúcia | objeto (Mata) | no chão; é o alvo da animação de caça | 70 |
| Cachecol de tricô cor de areia | roupa · pescoço | sob o babador branco | 110 |
| Cerca de estaca | objeto (Mata) | fundo da cena (área aberta e campestre) | 160 |

---

## 2. Axolote: Lume

### 2.1 Biologia real

- **Neotenia**: o axolote passa a vida inteira na água como larva sexualmente
  madura e não sofre metamorfose [F TorontoZoo†; ExplorationPlace]. Mantém na
  vida adulta traços de juvenil, como as **brânquias externas** e a
  **barbatana da cauda** [F SDZG-carac].
- **Onde vive**: só no lago de Xochimilco e nos canais vizinhos, no México
  [F BakuZoo†]. Está **Criticamente em Perigo** pela IUCN e no Apêndice II da
  CITES [F Wiki-Axolotl]. A densidade caiu de ~6.000/km² em 1998 para ~100/km²
  em 2008 (levantamento da equipe de Zambrano, como relatado pela imprensa)
  [F SciAm†].
- **Tamanho**: até 30 cm. Fêmeas pesam 170–180 g, machos 125–130 g
  [F SDZG-carac].

**Ciclo de vida e estágios**

| Estágio real | Idade | Aparência | Fonte |
|---|---|---|---|
| Ovo | eclode com ~2 semanas a 20 °C (pode levar 3–4 semanas) | embrião de 2–3 mm dentro de gelatina transparente, em cachos presos a planta ou pedra; a fêmea põe 200–1.500 ovos | [F SDZG-repro] |
| Larva recém-eclodida | estágio 44, até 5–6 dias após a eclosão | 11–13 mm; as **patas da frente são só brotos**; as guelras se alongam; saco vitelino interno alimenta por ~1 semana | [F Nye2003; SDZG-repro] |
| Larva com patas da frente | estágios 45–53, de 6 a 25 dias após a eclosão | 12–28 mm; a pata da frente cresce e ganha dedos; as **patas de trás** só despontam depois | [F Nye2003]; a divulgação dá patas da frente com ~30 dias e de trás com ~45 dias [F ExplorationPlace] |
| Juvenil | depois de 25 dias após a eclosão | 27–50 mm; pata de trás completa no estágio 57 | [F Nye2003] |
| Adulto neotênico | maturidade sexual com ~1,5 ano | **3 pares de ramos branquiais** com filamentos; barbatana de trás da cabeça até a cloaca; olhos **sem pálpebra**; cabeça larga | [F SDZG-repro; Wiki-Axolotl] |

**Comportamentos marcantes**

- Passa muito tempo **parado no fundo**. As larvas nadam mais que os adultos,
  mas também ficam sobretudo no fundo. O adulto mais **anda** do que nada
  [F SDZG-comp].
- **Sobe de vez em quando para engolir ou soltar ar** e ajustar a flutuação
  [F SDZG-comp; Axolotl.org].
- **Come por sucção**: abre a boca, baixa o aparelho hioide, a água entra
  trazendo a presa e sai pelas fendas das brânquias
  [F Wiki-Axolotl; Sucção 2025]. É caçador de emboscada que acha a presa pela
  visão [F SDZG-dieta].
- **Nada como enguia**, ondulando o corpo, com a cauda adaptada a manobrar
  entre plantas, não a correr [F SDZG-comp].
- **Corte**: macho e fêmea giram um em volta do outro, uma "valsa"
  [F SDZG-repro].
- **Regenera** patas, cauda, partes do olho e do coração, sem cicatriz
  [F Wiki-Axolotl; SDZG-carac].

**Vocalização**: não achei fonte que descreva vocalização. A Wikipedia não
menciona som algum [F Wiki-Axolotl], e a comunicação documentada é química,
por odor [F SDZG-comp]. Conclusão [I]: a "voz" do Lume é **água**: bolha, gole
de ar, ondulação.

**Linguagem corporal**: o único sinal popular, "guelra dobrada para frente =
estresse", vem de fórum de criador e é contestado no próprio fórum
[F Caudata†]. **Não é fato científico**, e eu não uso como emoção [I].

**Cores reais (morfos)**: selvagem (marrom ou tan com pintas douradas e fundo
oliva), leucístico (rosa claro, olho preto), xântico (cinza, olho preto),
albino (rosa claro ou branco, olho vermelho), melanístico (preto ou
azul-escuro, sem pintas) [F Wiki-Axolotl]. Em cativeiro também existem branco
e dourado [F SDZG-carac; Axolotl.org].

**Dieta**: larvas comem zooplâncton e vermes. Adultos comem peixe pequeno,
vermes, insetos, crustáceos e lagostim [F SDZG-dieta].

### 2.2 O desenho atual

Abri: `pet-axolotl-*.png`, `home-axolotl.png`, `home-axolotl-noite.png`, e li
`pet.dart:2068-2158`.

| Critério | Avaliação |
|---|---|
| Proporção | Ursinho de pé: cabeça 86×73 sobre um corpo 82×71 e dois "pés" ovais (`pet.dart:2082-2085`). **Sem cauda.** Sem a cauda, o axolote vira "bicho rosa com folhas na cabeça" [A] |
| Guelras | Três pétalas lisas de cada lado, na cor `lerp(pelo, acento, 0.34)` (`pet.dart:2109`): rosa sobre rosa, contraste baixo. Sem filamentos, lê como folha, orelha ou asa [A]. As reais são plumosas [F SDZG-carac; Wiki-Axolotl] |
| Fofura | Alta no rosto: o sorriso largo e as bochechas funcionam [A]. É o melhor rosto dos três |
| Clareza de humor | Radiante × contente é claro (sorriso maior). O sono é claro. A saudade lê como **brava** (T1/T2) e a gota cai na guelra (T3) [A] |
| Biologia × estilização | O olho **fecha** no sono, mas o axolote não tem pálpebra [F Wiki-Axolotl]. É uma estilização aceitável se a pose também contar o sono (§2.4) [I] |
| Na cena | No radiante, fica de pé com água até o peito, olhando para fora d'água como gente na banheira (`home-axolotl.png`). O axolote real fica no fundo [F SDZG-comp] [A/I] |
| Paleta | 6 rosas (`tokens.dart:111-118`) [A]. Os morfos reais (selvagem, dourado, melanoide) são as "pelagens" naturais e mais bonitas da espécie [F Wiki-Axolotl] |
| Sobreposição | Desenhado com orelhas redondas e focinheira (`OverlayDoBaru.kt:345-348`, `:361-380`) [A] |

### 2.3 Cinco estágios: Lume

**Mudança de vista** [I]: do estágio 2 em diante, o Lume é desenhado em **três
quartos, deitado no fundo**, com corpo horizontal, cabeça virada para quem
olha e cauda curvada visível. A vista frontal "de pé" fica só para o toque,
quando ele sobe e "espia" a pessoa pelo vidro. Na cena, a lagoa ganha uma
**janela em corte** (vista subaquática lateral) sempre que o axolote estiver
ativo.

Paleta leucística de referência [I]: corpo `#F4C9CF`, barriga `#F9DDE0`,
guelras `#E8737F` com filamentos `#F09AA3` (guelra mais viva que o corpo, para
contrastar), olho `#2B2118`. As outras pelagens são os morfos: selvagem
`#6E6A45` com pintas `#C9A84A`, dourado `#E8C46A` com guelra `#F0A07A`,
melanoide `#2F3440` com guelra `#5A4E6E`, branco `#F7F1EA` com guelra
`#F2A3AE`.

| # | Nome no app | Silhueta e proporção | Cores | Detalhes que surgem | Base real |
|---|---|---|---|---|---|
| 1 | **Ovo na planta** | esfera de gelatina, 26% da altura do adulto, presa a uma folha de elódea; dentro, um embrião em vírgula enrolado | gelatina `#DDEFE6` a 55% com reflexo branco; embrião `#B9A08F` | a vírgula se mexe de leve; ao toque, a gelatina treme como pudim | gelatina transparente presa a planta [F SDZG-repro] |
| 2 | **Larvinha** | "vírgula" horizontal longa (comprimento = 3× altura), olhos grandes, **sem patas** (só dois brotos), barbatana contínua no dorso | corpo translúcido `#EAD9D2` com pontinhos escuros; barriguinha amarela de vitelo `#F3E3A8` | guelras = 3 cotocos de cada lado | 11–13 mm, brotos das patas da frente [F Nye2003]; vitelo ~1 semana [F SDZG-repro] |
| 3 | **Larva de patinhas** | corpo 2,5:1; **duas patinhas da frente** com 4 dedos; guelras alongadas e começando a ramificar | cor do morfo surgindo (50% de saturação) | o "sorriso" aparece; anda com as mãozinhas e arrasta o resto | patas da frente antes das de trás [F Nye2003; ExplorationPlace] |
| 4 | **Juvenil** | **quatro patas**, cabeça larga, cauda com barbatana; guelras com filamentos curtos | morfo a 85% | pintas douradas (no selvagem) e brilho no olho | patas de trás completas no estágio 57 [F Nye2003] |
| 5 | **Adulto** | cabeça bem larga; **3 ramos de guelra plumosa de cada lado** (o maior em cima); barbatana de trás da cabeça até a cloaca; dedos longos e finos | morfo pleno | sorriso largo; guelras ondulam o tempo todo | [F Wiki-Axolotl; SDZG-carac] |

**Cenas de transição** [I]:

- **1→2**: a vírgula gira dentro da gelatina 3 vezes. A gelatina estica,
  "plop", e a larvinha sai deslizando até o fundo e fica deitada de lado,
  piscando o olhão.
- **2→3**: ela faz força, aparece um brotinho de cada lado que vira mãozinha, e
  ela dá o primeiro "passo" de mão.
- **3→4**: nada em ondulação até a borda da janela, volta, e já chega com as
  pernas de trás. As guelras se abrem como um leque.
- **4→5**: sobe à superfície, **gole de ar com bolha** [F SDZG-comp], desce
  devagar girando. As guelras ganham os filamentos de baixo para cima, como
  uma pena se abrindo. Termina com o sorriso.

### 2.4 Personalidade e humores

**Traço** [I, ancorado em fato]: *o calmo que recomeça*. Fica quieto no fundo
[F SDZG-comp] e regenera o que perde [F Wiki-Axolotl]. Isso já está na frase
atual: "Calmo em água parada, e se recupera do que parecia perdido. Você
recomeça melhor do que continua." (`l10n.dart:847-850`) [A]. Combina com
"sem punição": a volta depois de dias fora é **festa de recomeço**, nunca
cobrança.

| Humor | Como aparece no Lume |
|---|---|
| Radiante | sorriso aberto, **guelras em leque ondulando rápido**, nada em S pela janela, solta bolhinhas e dá uma cambalhota lenta |
| Contente | deitado no fundo, guelras abrindo e fechando devagar, sorriso pequeno, a cauda balança de leve |
| Neutro | parado no fundo, guelras quietas, cauda reta, pupila acompanha o dedo |
| Sonolento | deitado de barriga sobre uma folha, **guelras caídas para trás** e paradas, olho "apagado" (pupila menor, sem brilho). Como não tem pálpebra [F Wiki-Axolotl], o sono é contado pela **pose + bolhinha** saindo da boca. O arco de olho fechado fica como reforço opcional |
| Sentindo falta | encostado no vidro da janela olhando para fora, as pontas das guelras um pouco murchas, sobe devagar até a superfície "para ver se você chegou" e desce. Ao abrir o app, dá a volta-cambalhota de recomeço |

**Animações-assinatura**:

1. **Aceno de guelras**: os três ramos de cada lado ondulam em cascata, de
   cima para baixo. É o "oi" ao toque.
2. **Gole de ar**: sobe até a superfície, "blup", uma bolha, e desce flutuando
   [F SDZG-comp; Axolotl.org].
3. **Sucção relâmpago**: um pontinho de comida passa e a boca abre em 1
   quadro, o hioide "infla" a garganta e o pontinho some
   [F Wiki-Axolotl; Sucção 2025]. Substitui o "petisco" atual.
4. **Passeio no fundo**: anda com as quatro patas, a cauda serpenteando
   [F SDZG-comp].
5. **Valsa sozinho** (radiante raro): gira em círculo em volta de si mesmo,
   uma referência fofa à valsa de corte [F SDZG-repro] sem o contexto
   reprodutivo [I].

### 2.5 Sons (ElevenLabs)

| Arquivo | Quando | Prompt | Duração |
|---|---|---|---|
| `axolote_blup.wav` | gole de ar | "Single soft underwater air gulp at the water surface, small bubble pop, cute, close" | 0,4 s |
| `axolote_bolhas.wav` | radiante, aceno | "Gentle cluster of tiny rising bubbles underwater, light and sparkly" | 0,7 s |
| `axolote_succao.wav` | sucção | "Very short soft underwater suction 'fwip', small creature eating" | 0,2 s |
| `axolote_guelras.wav` | aceno de guelras | "Faint soft water swish, like a feather moving underwater, airy shimmer" | 0,5 s |
| `ovo_gelatina.wav` | toque no ovo, eclosão | "Small jelly wobble squish followed by a soft underwater plop" | 0,6 s |

Sem "fala" e sem pio: o axolote real não vocaliza (ver 2.1) [I].

### 2.6 Itens temáticos do axolote

| Item | Tipo | Onde aparece | Preço |
|---|---|---|---|
| Janela de vidro do lago | cenário | ativa a vista em corte com borda arredondada de "aquário de lago" | 200 |
| Toquinha de cerâmica | objeto (Água) | no fundo, à direita; o Lume entra e sai | 130 |
| Pedrinhas lisas do canal | objeto (Água) | chão da janela | 80 |
| Ramo de elódea | objeto (Água) | lado esquerdo da janela; é onde o ovo fica preso | 90 |
| Canteiro flutuante (inspirado nas chinampas de Xochimilco [I]) | objeto (Água) | superfície da lagoa, com flores | 260 |
| Laço de fita entre as guelras | roupa · cabeça | no topo da cabeça, entre os ramos de cima | 100 |
| Óculos de mergulho | roupa · rosto | sobre os olhos | 120 |
| Lanterna subaquática | objeto (Noite) | brilho verde-água no fundo à noite | 190 |

---

## 3. Pinguim: Nino

### 3.1 Biologia real

**Escolha de espécie-base: pinguim-de-magalhães (*Spheniscus magellanicus*)**
[I], porque:

- Depois da reprodução migra para o norte e se alimenta ao largo do Brasil e
  do Peru [F Wiki-Magellanic]. Chega ao litoral brasileiro entre maio e
  setembro, na maioria **juvenis** [F BemParaná†], seguindo cardumes de
  anchoíta [F UNESP†].
- O adulto tem duas faixas pretas no peito (a de baixo em ferradura invertida),
  cabeça preta com borda branca larga e pele rosa perto do olho no período
  reprodutivo [F Wiki-Magellanic]. O **juvenil é mais cinza e não tem as
  faixas** [F CES]. Tem pés manchados que escurecem até ficar pretos por volta
  dos 10 anos [F Wiki-Magellanic].
- Faz ninho em toca cavada, sob arbusto ou numa depressão rasa
  [F CES; Wiki-Magellanic].
- Mede 61–76 cm e pesa 2,7–6,5 kg [F Wiki-Magellanic]. Vive até 25 anos na
  natureza [F Wiki-Magellanic]. Status IUCN: Pouco Preocupante, com população
  em queda [F Wiki-Magellanic].

**Ciclo de vida e estágios**

| Estágio real | Idade | Aparência | Fonte |
|---|---|---|---|
| Ovo | postura de 2 ovos em outubro; incubação de 39–42 dias, em turnos de 10–15 dias | casca dura, do tamanho de um ovo de ganso | [F CES; Wiki-Magellanic]; 39,8 ± 1,7 dias em Punta Tombo [F Yorio†] |
| Eclosão | o filhote leva ~2–3 dias para sair da casca (dado do pinguim-de-humboldt, mesmo gênero) | — | [F Primorsky†] |
| Filhote em guarda | ~20–25 dias | coberto de penugem; os pais alimentam a cada 2–3 dias | [F CES; Scolaro 1987†; Wiki-Magellanic] |
| Filhote crescido | ~60–85 dias (fase de "creche" em Scolaro; a Britannica diz que a espécie quase não forma creche, e esse ponto está em aberto) | 2ª penugem; marrom com rosto e barriga brancos segundo a Britannica, cinza-esbranquiçado segundo zoológico | [F Scolaro 1987†; Britannica Kids†] |
| Juvenil | sai da colônia entre o fim de fevereiro e março | a plumagem juvenil empurra a penugem para fora antes de deixar a colônia; dorso cinza-azulado, peito cinza-azulado claro, sem faixas | [F CES; Wiki-Magellanic] |
| Adulto | — | faixas, borda branca na cabeça, pele rosa | [F Wiki-Magellanic] |

**Muda anual**: penas novas crescem por baixo e empurram as velhas, e o bicho
fica "bem desgrenhado" por semanas [F CalAcademy]. Durante a muda o pinguim
jejua e chega a perder até 58% do peso (pinguim-azul) [F BiologyOpen 2025†].
**Não desenhar** a muda como estágio de sofrimento [I].

**Comportamentos e vocalizações**

- **Exibição extática**: pés afastados, bico para o céu, nadadeiras erguidas,
  peito estufado e chamado alto, o **zurro** [F CalAcademy]. Os pinguins do
  gênero ganharam o apelido de "jumento" porque o chamado lembra o zurro
  [F Banded]. As categorias de chamado são contato, agonístico, exibição
  extática e exibição mútua (cantada pelo casal no ninho) [F Banded]. A fêmea
  reconhece o parceiro só pelo chamado [F Wiki-Magellanic].
- **Reverência e balanço de cabeça** entre parceiros reforçam o vínculo
  [F CalAcademy].
- **Andar esguio**: estica o corpo e o pescoço e ergue a cabeça para dizer
  "não sou ameaça" ao passar no território alheio [F CalAcademy].
- **Alisar as penas**: belisca a glândula de óleo perto da cauda e espalha o
  óleo com o bico [F CalAcademy].
- **Tobogã de barriga**: o pinguim-imperador desliza de barriga para poupar
  energia [F WHOI]. **Não achei fonte de tobogã no pinguim-de-magalhães.**
  No Nino, o tobogã é estilização [I].
- **Microcochilos**: o pinguim-de-barbicha, que choca no ninho, dorme mais de
  10.000 vezes por dia em cochilos de ~4 s, somando mais de 11 horas
  (*Science* 2023) [F NPR; KOPRI]. É outra espécie, mas é a base mais fofa e
  defensável para o "sonolento" [I].
- **Nada "voando"** com as nadadeiras; os pés palmados fazem de leme [F CES].
  Isso já está implementado (`pet.dart:2167-2171`, `:2212-2216`) [A].
- **Dieta**: peixe pelágico pequeno, lula, krill. Mergulha 20–50 m
  [F Wiki-Magellanic]. Em terra, não come [F CES].

### 3.2 O desenho atual

Abri: `pet-penguin-*.png`, `home-penguin.png`,
`home-penguin-entardecer.png`, e li `pet.dart:2161-2287`.

| Critério | Avaliação |
|---|---|
| Silhueta | Bola de cabeça (72×60) sobre bola de corpo (90×91), com o pescoço marcado (`pet.dart:2185-2253`). Pinguim real não tem pescoço visível: cabeça e corpo são **uma** forma de pino [I]. Do jeito que está, lê como chapim ou pombinho [A] |
| Cor | Azul-acinzentado com barriga cinza-clara (`tokens.dart:121-128`) [A]. Não é nem o preto do adulto nem uma referência clara. Lê como "passarinho azul" [I] |
| Bico e pés | Triângulo laranja **igual ao da coruja** e pés laranja. O pinguim-de-magalhães tem bico escuro e pé manchado ou preto [F Wiki-Magellanic] |
| Olhos | O olho (y=-3) cai exatamente na borda da máscara clara (topo em y≈-8): metade sobre o escuro, metade sobre o claro, e o contorno fica sujo [A, `pet.dart:2247-2259`] |
| Fofura | Média. Sem boca, o contente fica sem expressão nenhuma (`pet-penguin-contente.png`) [A] |
| Clareza de humor | Radiante ≈ contente (T4); bochecha barrenta (T5); saudade brava (T1/T2) [A] |
| Na cena | Em pé com água até o peito, pés aparecendo na frente da água [A, `home-penguin.png`] |
| Sobreposição | Orelhas redondas e focinheira (`OverlayDoBaru.kt`) [A] |

### 3.3 Cinco estágios: Nino, pinguim-de-magalhães

Paleta do adulto [I]: dorso e faixas `#26313A` (preto-azulado, mais quente que
o preto puro), barriga `#F7F4EE`, borda da cabeça `#F7F4EE`, pele rosa `#E8A3A0`,
bico `#3A3F45` com faixa clara `#8C9399`, pés `#5E5254`. As 6 pelagens viram
tons do "preto" (ardósia, grafite, azul-noite...).

| # | Nome no app | Silhueta e proporção | Cores | Detalhes que surgem | Base real |
|---|---|---|---|---|---|
| 1 | **Ovo no ninho** | oval grande e gordo (0,8:1), 30% da altura, numa cavidade de areia **sob um arbusto** | casca `#EEF0E8`; areia `#E3CFA4`; arbusto `#7E9A6A` | balança; uma rachadura por sessão-quinto (§0.2) | 2 ovos sob arbusto ou em toca [F CES] |
| 2 | **Bolinha recém-nascida** | gota sentada, cabeça = 55% da altura, bico curtinho, nadadeiras em toco | penugem `#B9B4AD`; rosto e barriga `#DDD8D0` | pia de bico aberto pedindo comida | penugem, cuidado em guarda [F CES; Scolaro†] |
| 3 | **Filhote de penugem** | **bola** quase perfeita, mais larga que alta (1,1:1), 60% da altura; pés grandes desproporcionais | 2ª penugem `#9C948A` (cinza-pardo) com rosto e barriga `#E3DED6` | fica de pé sobre os pés grandes, cai sentado, levanta | 2ª penugem; marrom de rosto e barriga claros [F Britannica†] |
| 4 | **Juvenil** | pino alongado, 80%; no início do estágio sobram **tufos de penugem** grudados na cabeça e nas costas | dorso `#6F8494` (cinza-azulado), peito `#D9DFE3`; **sem faixas**; pés claros com manchas `#C99A98` | aprende a nadar; os tufos de penugem vão caindo nas sessões seguintes | juvenil mais cinza e sem faixas, pés manchados [F CES; Wiki-Magellanic]; a plumagem empurra a penugem [F CES] |
| 5 | **Adulto** | pino ereto, 100%, sem pescoço; nadadeiras um pouco para fora do contorno | paleta do adulto | **duas faixas pretas** (a de baixo em ferradura), borda branca da cabeça, pele rosa perto do olho | [F Wiki-Magellanic] |

**Cenas de transição** [I]:

- **1→2**: o ovo balança. Como o filhote real leva dias para sair
  [F Primorsky†], a cena faz piada disso: um furinho, uma pausa, o bico
  aparece e volta ("ainda não"), e então a casca abre ao meio e a bolinha
  fica sentada dentro da metade de baixo, como num barquinho.
- **2→3**: pia, estica, e a penugem "estufa" em dois tempos até virar bola.
  Ela rola meio giro.
- **3→4**: sacode o corpo inteiro. A penugem sai em flocos e revela a plumagem
  cinza-azulada, com um tufo de penugem teimoso no topo da cabeça que só cai
  na sessão seguinte. Pisa na água pela primeira vez.
- **4→5**: mergulha na lagoa (janela em corte), faz o "voo" subaquático e sai
  da água com as **duas faixas desenhando-se** do centro para fora. Termina
  com a primeira **exibição extática** e o zurro.

### 3.4 Personalidade e humores

**Traço** [I, ancorado em fato e na frase atual]: *desajeitado em terra,
exato na água* (`l10n.dart:851-854`) [A]. Social e falante, faz questão de
ser reconhecido pela voz [F Wiki-Magellanic; Banded].

| Humor | Como aparece no Nino |
|---|---|
| Radiante | **exibição extática**: bico para o céu, nadadeiras abertas, peito estufado, zurro [F CalAcademy]. Na água, "voa" com as nadadeiras (já existe). Na areia, **tobogã de barriga** (estilização) |
| Contente | alisa as penas com o bico [F CalAcademy], balança as nadadeiras soltas, passinho de um pé para o outro |
| Neutro | de pé, corpo reto, vira a cabeça de um lado para o outro devagar |
| Sonolento | **microcochilos**: a cabeça cai, os olhos fecham por 2–4 s, ele acorda num pulinho e cochila de novo [F NPR] |
| Sentindo falta | na beira, olhando o horizonte, nadadeiras caídas, **chamado de contato** baixinho de tempos em tempos [F Banded]. Ao abrir o app: reverência e balanço de cabeça, o gesto de vínculo [F CalAcademy] |

**Animações-assinatura**:

1. **Exibição extática + zurro** (radiante, fim de sessão) [F CalAcademy].
2. **Alisar as penas**: o bico vai à base da cauda e passa pelo peito
   [F CalAcademy].
3. **Microcochilo** (sonolento) [F NPR].
4. **Andar esguio**: ao atravessar a cena, estica o pescoço e anda na ponta
   dos pés [F CalAcademy].
5. **Tobogã de barriga** (estilização inspirada no imperador [F WHOI]).
6. **Sacudida pós-mergulho**: chacoalha o corpo e espalha gotinhas [I].

### 3.5 Sons (ElevenLabs)

| Arquivo | Quando | Prompt | Duração |
|---|---|---|---|
| `pinguim_zurro.wav` | exibição extática | "Short cute penguin bray, donkey-like honk scaled down and softened, two syllables, friendly, not loud" | 0,9 s. Base: zurro [F CalAcademy; Banded]. **Encurtado e suavizado**: o real é o chamado mais alto da espécie [F Banded] |
| `pinguim_contato.wav` | sentindo falta, toque | "Single soft short penguin contact call, gentle low honk" | 0,4 s |
| `pinguim_filhote.wav` | estágios 2–3 | "Tiny penguin chick whistle-peep, begging, cute, very short" | 0,3 s |
| `pinguim_tobogã.wav` | tobogã | "Soft belly slide on wet sand, short swoosh" | 0,6 s |
| `pinguim_tapinha.wav` | reverência, sacudida | "Two soft flipper pats on a feathered belly" | 0,3 s |
| `pinguim_splash.wav` | mergulho | "Small playful splash of a little bird diving into a pond" | 0,5 s |

### 3.6 Itens temáticos do pinguim

| Item | Tipo | Onde aparece | Preço |
|---|---|---|---|
| Arbusto-ninho | objeto (Mata) | à direita, com a cavidade de areia embaixo; é a casa do ovo | 150 |
| Gravata-borboleta | roupa · pescoço | entre as duas faixas (brinca com o "fraque") | 90 |
| Gorro de lã com pompom | roupa · cabeça (variação do `gorro`) | topo da cabeça | 110 |
| Boia de rosquinha | objeto (Água) | na lagoa; o Nino boia nela no radiante | 170 |
| Cardume de anchoíta | objeto (Água), variação do `cardume` existente | atravessa a janela subaquática | 160 |
| Guarda-sol de praia | objeto (Mata) | areia, no habitat Praia | 210 |
| Óculos de natação | roupa · rosto | sobre os olhos | 100 |
| Prancha de bodyboard | objeto (Água) | encostada no arbusto; o tobogã acontece em cima dela | 230 |

---

## 4. Jornada dedicada

**Princípio** [I]: os 22 marcos, os ids, os critérios e as folhas **não
mudam**. Os ids são chave de resgate (`progressao.dart:278-282`) e reordenar
mexe na escada de folhas. Muda só a **pele** de cada nó (nome, ilustração e
mini-cena) conforme a espécie ativa, e os nós que entregam espécie continuam
iguais para todos. Espécie continua liberando só por marco (§4 do contrato).

**A espécie liberada chega como ovo.** No passo 13 (`vinte_focos`), a cena de
desbloqueio mostra uma folha de elódea com um ovo de gelatina. No passo 16
(`quinze_dias_abaixo`), um ovo na areia sob um arbusto. No passo 17
(`nivel_10`), um ovo branco na boca da toca.

| # | id | Nina (coruja) | Lume (axolote) | Nino (pinguim) |
|---|---|---|---|---|
| 1 | primeiro_foco | Bicada no ovo | A gelatina treme | O ovo pipoca |
| 2 | primeiro_dia_abaixo | Noite quieta na toca | Água parada | Maré mansa |
| 3 | nivel_3 (Igarapé) | Toca na beira do igarapé | O canal do igarapé | Visita ao igarapé |
| 4 | tres_focos | Três gafanhotos | Três bolhas de ar | Três peixinhos |
| 5 | tres_dias | Três manhãs no montinho | Três dias no fundo | Três marés |
| 6 | tres_dias_abaixo | Sentinela da toca | Guelras em leque | Penas alinhadas |
| 7 | cinco_focos | Chega o Rio (lontra) | idem | idem |
| 8 | cinco_dias_abaixo | Chega o Toco (tartaruga) | idem | idem |
| 9 | nivel_5 | Arrulho de duas notas | Primeiro passeio no fundo | Primeiro zurro |
| 10 | dez_focos | Dez caçadas | Dez goles de ar | Dez anchoítas |
| 11 | semana_inteira (Manguezal) | Uma semana de sentinela | Raízes do mangue | Ninho no mangue |
| 12 | nivel_6 | Cabeça que gira | Sorriso de axolote | Tobogã de barriga |
| 13 | vinte_focos (Serra) | Chega um ovo de axolote | **Lume chega** | Chega um ovo de axolote |
| 14 | duas_semanas | Duas semanas no montinho | Duas semanas de canal | Duas semanas de praia |
| 15 | nivel_8 | Primeiro voo curto | Guelras de pluma | Voo debaixo d'água |
| 16 | quinze_dias_abaixo | Chega um ovo de pinguim | idem | **Nino chega** |
| 17 | nivel_10 | **Nina chega** (para quem não começou com ela) | Chega um ovo de coruja | idem |
| 18 | trinta_dias (Praia) | Lua cheia na praia | Um mês de água clara | A praia é casa |
| 19 | trinta_dias_abaixo | Caça perfeita ao entardecer | Lago espelhado | Cardume de inverno |
| 20 | cinquenta_focos | Chega a Bolota (buldogue) | idem | idem |
| 21 | nivel_15 | Coruja sábia | Mestre do fundo | Voz da colônia |
| 22 | cem_focos (Ilha) | Cem entardeceres | Cem bolhas | Cem mergulhos |

Os nomes valem para pt. Cada um precisa nascer nos 4 idiomas (contrato §4).

**O cantinho da espécie em cada habitat** (prop fixo, de graça, que aparece
quando a espécie está ativa) [I]:

| Habitat | Nina | Lume | Nino |
|---|---|---|---|
| Lagoa | montinho com toca no barranco | janela subaquática com elódea | pedra lisa na margem |
| Igarapé | toca no barranco de terra vermelha | raízes submersas | tronco caído para mergulhar |
| Manguezal | toca na parte seca | raízes de mangue sob a água | ninho entre raízes |
| Serra | campo aberto com cupinzeiro | poço de água fria | pedra alta |
| Praia | duna com toca | piscina de maré | arbusto-ninho e areia molhada |
| Ilha | campo com cerca | lagoa interna | colônia: silhuetas de outros pinguins ao longe |

---

## 5. Recomendações detalhadas

### R1. Sistema de crescimento em 5 estágios por espécie
- **O quê**: §0.2 (contador por espécie, limiares 1/5/15/40, piso, estágio 5
  para espécies já liberadas, replay "Ver como nasceu").
- **Por quê**: pedido explícito do dono (brief, item 6), e hoje não existe
  estágio nenhum [A]. A diferença entre os estágios usa o que é real em cada
  espécie (§1.3, §2.3, §3.3) [F].
- **Como**: `Balanco.limiaresDeEstagio = [1, 5, 15, 40]`;
  `estagioDe(especie)`; `Map<Species,int> sessoesComEspecie` no `local_store`
  e no snapshot, incrementado onde a sessão concluída já credita XP; parâmetro
  `estagio` em `PetView` e `_PetPainter`; `shouldRepaint` passa a comparar
  `estagio`. Cada `_coruja/_axolote/_pinguim` ganha um ramo por estágio. O
  formato do snapshot muda, então precisa de ADR.
- **Esforço**: G (dados e lógica M; desenho dos 15 estágios G).
- **Impacto esperado**: alto no "acompanhar o crescimento", que é a queixa
  número 6 do dono.
- **Critério de aceite**: (a) conta nova com a Nina mostra o ovo antes da 1ª
  sessão e a recém-nascida depois dela; (b) com 5, 15 e 40 sessões o estágio
  muda; (c) teste: trocar de espécie e voltar mantém o estágio; (d) conta
  migrada com espécie liberada abre no estágio 5; (e) teste: o estágio nunca
  diminui.

### R2. A sessão choca o ovo
- **O quê**: rachaduras proporcionais ao tempo da 1ª sessão e eclosão na tela
  de resultado.
- **Por quê**: amarra o primeiro valor do produto (o foco) ao primeiro momento
  emocional (o nascimento) [I]. O relatório de agosto já apontava que a
  revelação do pet não celebra (`RELATORIO_UX_DUOLINGO.md:104`) [A].
- **Como**: na `session_screen`, `PetView(estagio: 1, progressoDoOvo: t)`,
  com rachaduras como `Path` pré-desenhado revelado por
  `PathMetric.extractPath` até t. A eclosão é um `AnimationController`
  sequencial: balanço, furo, pausa, volta da rachadura, tampa (com
  `Curves.elasticOut`), penugem afofando.
- **Esforço**: M.
- **Impacto**: alto na primeira sessão (inferência; medir conclusão da 1ª
  sessão antes e depois).
- **Aceite**: rachaduras visíveis a 20/40/60/80% do tempo; desistir não muda
  nada no ovo e não mostra texto de culpa; a eclosão roda com "reduzir
  movimento" desligado e vira troca cruzada com ele ligado.

### R3. Corrigir o espelhamento da tristeza (T1/T2) e a lágrima (T3)
- **O quê**: espelhar sobrancelha e pálpebra pelo lado do olho; lágrima
  ancorada no canto do olho de cada espécie ou removida.
- **Por quê**: a saudade lê como "brava" nas três espécies [A]. Viola o
  espírito de "nunca culpa" do contrato [I].
- **Como**: `_olho(..., lado: -1|1)` e multiplicar os x da sobrancelha e da
  pálpebra por `lado`, com a ponta de dentro sempre mais alta. `_pingo` passa
  a receber o `Offset` do olho no espaço da espécie. Proposta: nas três
  espécies desta pesquisa, **sem lágrima** (§1.4, §2.4, §3.4).
- **Esforço**: P.
- **Impacto**: alto na clareza do humor mais delicado.
- **Aceite**: nos 9 `*-saudade.png` regerados, a ponta de dentro das duas
  sobrancelhas fica acima da de fora; nenhuma gota fora do rosto.

### R4. Nina vira coruja-buraqueira
- **O quê**: sem tufos, olho amarelo sem esclera branca, sobrancelha e
  babador brancos, pernas longas, pintas; na cena, o montinho com toca.
- **Por quê**: espécie brasileira, de chão, diurna-crepuscular, sem tufos
  [F Wiki-BUOW; Cornell-BUOW-ov].
- **Como**: `_coruja` sem o bloco dos tufos (`pet.dart:2011-2027`); o `_olho`
  com `coruja: true` passa a desenhar a íris amarela ocupando o olho todo;
  pernas com 2 segmentos; o voo do radiante vira caça (`acaoDoBicho`,
  `pet.dart:122-123`, troca `voo` por `brincadeira` ou por uma ação nova
  `caca`).
- **Esforço**: M.
- **Impacto**: identidade e coerência com o habitat [I].
- **Aceite**: teste de reconhecimento rápido com 5 pessoas — mostrar a Nina
  nova a 120 px por 2 s, e ≥4 dizem "coruja". Na home radiante, ela não paira
  sobre a água.

### R5. Lume ganha cauda, guelras plumosas, vista de 3/4 e janela
  subaquática
- **O quê**: §2.3.
- **Por quê**: sem cauda e sem filamentos, o bicho perde a espécie
  [F Wiki-Axolotl; SDZG-carac] [A]. De pé na água, contradiz o
  comportamento de fundo [F SDZG-comp].
- **Como**: novo `_axolote` em vista lateral com `Path` contínuo
  (cabeça-corpo-cauda) e barbatana como segunda camada clara; guelras como 3
  `Path` de haste + filamentos em `drawLine` curtos ao longo da haste,
  balançando com `pose.cauda`; janela = `ClipRRect` na faixa d'água do
  `habitat.dart` com gradiente subaquático.
- **Esforço**: G.
- **Impacto**: alto em fofura e legibilidade [I].
- **Aceite**: cauda visível em todos os humores; guelras com ≥6 filamentos
  por ramo no estágio 5; na home, o corpo inteiro fica sob a linha d'água.

### R6. Nino vira pinguim-de-magalhães, numa forma de pino só
- **O quê**: §3.3; bico escuro, pés manchados, faixas só no adulto.
- **Por quê**: silhueta genérica e bico igual ao da coruja [A]; espécie que
  visita o Brasil [F Wiki-Magellanic; BemParaná†]; as faixas viram marco
  visível de crescimento [F CES].
- **Como**: `_pinguim` com um `Path` contínuo de cabeça e corpo; máscara clara
  reposicionada para o olho cair inteiro dentro do branco; faixas como dois
  `Path` em arco recortados no corpo, ligados só no estágio 5.
- **Esforço**: M.
- **Impacto**: identidade [I].
- **Aceite**: nenhum laranja no pinguim adulto; o olho não cruza a borda da
  máscara; estágio 4 sem faixas, estágio 5 com duas.

### R7. Gestos-assinatura por espécie
- **O quê**: §1.4, §2.4, §3.4 (≥4 por espécie).
- **Por quê**: os gestos de hoje são iguais para todas (T8) [A]. Os novos vêm
  de comportamento documentado [F].
- **Como**: o `enum GestoOcioso` ganha os valores novos; `_agendaGesto`
  (`pet.dart:544-573`) passa a sortear de `repertorioDe(species)`. Os gestos
  genéricos ficam como fundo, com peso menor.
- **Esforço**: M.
- **Impacto**: "animações extremamente limitadas" (brief, item 4).
- **Aceite**: em 2 minutos de ócio gravados, cada espécie mostra ≥2 gestos que
  nenhuma outra faz; o giro da coruja passa de 90° e mostra a nuca.

### R8. Humor por espécie, não só por olho e boca
- **O quê**: as tabelas de humor das §1.4, §2.4 e §3.4; radiante ≠ contente
  pelo corpo (postura, penas, guelras), não só pela bochecha.
- **Por quê**: T4 e T5 [A].
- **Como**: `_PetPainter` passa a ler `mood` dentro de cada espécie para
  postura (afofar penas = escala 1,05 na silhueta; guelras = amplitude e
  ângulo; nadadeiras do pinguim abertas no radiante); trocar a bochecha do
  pinguim pela pele rosa do olho, que é anatômica e não fica barrenta.
- **Esforço**: M.
- **Impacto**: clareza das emoções (pedido explícito do dono).
- **Aceite**: teste em que pessoas classificam os 5 humores de cada espécie
  pela silhueta, a 50% de opacidade e sem cor; acerto ≥80% entre radiante e
  contente.

### R9. A sobreposição desenha a mesma espécie no mesmo estágio
- **O quê**: o pet da sobreposição deixa de ser um mamífero genérico.
- **Por quê**: o axolote e o pinguim aparecem ali com orelhas
  (`OverlayDoBaru.kt:335-348`) [A]; item 7 do brief.
- **Como**: a curto prazo, passar `estagio` e uma imagem pré-renderizada do
  pet (gerada em Dart com `PictureRecorder` → `toImage` → PNG, enviada pelo
  canal que já leva `EXTRA_ESPECIE`). A solução completa é tema de outro laudo.
- **Esforço**: M.
- **Impacto**: alto (é o que a pessoa vê quando escapa do foco).
- **Aceite**: captura da sobreposição com Lume no estágio 3 mostra a larva de
  patinhas, não um bicho de orelhas.

### R10. Pelagens que são morfos e plumagens reais
- **O quê**: axolote com leucístico, selvagem (pintas douradas), dourado,
  melanoide, branco e cobre-claro; pinguim com tons do "preto"; coruja
  continua em areias.
- **Por quê**: T9 [A]; morfos reais [F Wiki-Axolotl; SDZG-carac].
- **Como**: usar `coatIndex` no axolote como já se faz no buldogue
  (`pet.dart:170-185`, `_MarcaDoBuldogue`; `coatIndex` em `pet.dart:1099-1109`) para ligar as pintas do selvagem e
  trocar a cor da guelra por morfo; o `CoatPicker` (`pet_profile.dart:63-127`)
  mostra amostra com padrão, não só um círculo liso.
- **Esforço**: P–M.
- **Impacto**: médio (personalização e conversa com quem conhece axolote).
- **Aceite**: as 6 amostras do axolote são distinguíveis em tons de cinza.

### R11. Jornada com pele por espécie e ovo na chegada
- **O quê**: §4.
- **Por quê**: "jornada limitada" (brief, item 5) [A], sem tocar em ids nem
  em folhas.
- **Como**: `rotuloDoMarco(id, especie)` no l10n, com a ilustração do nó
  como `CustomPainter` pequeno por espécie; `RecompensaDeMarco.especie`
  passa a abrir a cena "chegou um ovo".
- **Esforço**: M (66 rótulos × 4 idiomas é o grosso).
- **Impacto**: médio.
- **Aceite**: `test/l10n_*` cobre os 66 rótulos nos 4 idiomas; mudar de
  espécie muda os nomes dos nós sem mudar progresso nem folhas.

### R12. Sons da espécie
- **O quê**: §1.5, §2.5, §3.5.
- **Por quê**: só existem 7 sons genéricos (`assets/sons/`) e nenhum de
  espécie [A]; queixa 3 do brief.
- **Como**: gerar no ElevenLabs com os prompts, normalizar, tocar pelo
  `som_service` com `PlayerMode.lowLatency` (já usado em
  `som_service.dart:170`).
- **Esforço**: P (geração) + P (integração).
- **Impacto**: médio.
- **Aceite**: cada espécie tem ≥4 sons próprios; nenhum dura mais de 1 s;
  nenhum toca com o modo silencioso do app ligado.

### R13. Itens temáticos
- **O quê**: §1.6, §2.6, §3.6 (8 por espécie).
- **Por quê**: dar destino às folhas ("falta sumidouro", relatório de agosto,
  §6) [A]. Itens de espécie também dão motivo para trocar de espécie [I].
- **Como**: novos `ShopItemDef` com `especieSugerida` (só para ordenar a
  vitrine, nunca para travar a compra); a roupa se ajusta via `_veste(w, h)`
  com as dimensões da cabeça **de cada estágio**; no ovo, roupa nenhuma.
- **Esforço**: M.
- **Impacto**: médio.
- **Aceite**: toda roupa nova renderiza nos estágios 2–5 sem cortar; nenhum
  item altera estágio, XP ou desbloqueio.

### R14. A Nina muda ao entardecer
- **O quê**: no entardecer e à noite, a Nina fica mais acesa (olho mais
  aberto, mais balanço de cabeça) e caça; de dia, cochila mais no montinho.
- **Por quê**: caça no crepúsculo [F Wiki-BUOW]; hoje não muda nada (T7) [A].
- **Como**: `habitat` já sabe a hora; passar `periodo` ao `PetView` e ajustar
  pesos do repertório e a abertura do olho.
- **Esforço**: P.
- **Impacto**: médio (dá motivo para abrir o app em outro horário [I]).
- **Aceite**: `home-owl-entardecer.png` e `home-owl.png` mostram poses
  diferentes no mesmo humor.

---

## 6. As 10 recomendações mais importantes, em ordem

1. **R3**: corrigir o espelhamento da tristeza e a lágrima. É P e conserta as
   nove espécies de uma vez.
2. **R1**: sistema de 5 estágios com piso e "nunca por dinheiro".
3. **R2**: a 1ª sessão choca o ovo, o "a coruja começa em um ovo" do dono.
4. **R5**: Lume com cauda, guelras plumosas e janela subaquática.
5. **R6**: Nino pinguim-de-magalhães, em pino só, com faixas no adulto.
6. **R4**: Nina coruja-buraqueira, sem voo sobre a lagoa.
7. **R9**: sobreposição com a mesma espécie e o mesmo estágio.
8. **R7**: gestos-assinatura por espécie.
9. **R8**: humores pelo corpo, não só pela bochecha.
10. **R12**: sons da espécie (barato e de efeito imediato).

R10, R11, R13 e R14 vêm depois. R11 depende de R1.

---

## 7. O que **não** fazer

- **Não** vender crescimento: nada de "poção", "chocadeira premium" ou
  assinatura que acelere estágio, e nada de vender ovo de espécie. O
  contrato proíbe espécie por dinheiro, e acelerar o crescimento seria a
  mesma coisa por outro caminho.
- **Não** fazer o ovo esfriar, rachar mal ou "morrer" quando a pessoa sai da
  sessão ou some por dias. O bicho nunca sofre (contrato).
- **Não** regredir estágio, nem por inatividade, nem por trocar de espécie.
- **Não** transformar em ovo um bicho que a pessoa já tinha adulto (piso de
  posse, §0.2).
- **Não** usar o grito real da suindara, o chocalho de cascavel em volume
  alto, nem o zurro real em volume cheio (§1.5, §3.5).
- **Não** desenhar a muda do pinguim nem a "guelra dobrada" do axolote como
  doença ou sofrimento. A primeira é jejum real de semanas [F BiologyOpen†]; a
  segunda é crença de fórum sem base [F Caudata†].
- **Não** mostrar regeneração de membro (axolote perdendo pata). A metáfora
  do recomeço fica no texto e na festa da volta, nunca em ferida.
- **Não** reordenar a trilha nem trocar ids para "encaixar" a espécie no
  habitat que combina (`progressao.dart:278-282`).
- **Não** colocar pinguim encalhado ou debilitado na narrativa da praia, mesmo
  sendo o fato mais noticiado sobre o pinguim no Brasil [F BemParaná†].
- **Não** desenhar o axolote em pé com água até o peito, nem a coruja pousando
  ou planando sobre a água.

---

## 8. Riscos e dúvidas em aberto

1. **Coruja sem tufos pode ser lida como "passarinho"** [I]. É o risco de R4.
   Mitigar com o disco facial achatado, a sobrancelha branca em "V" e o olho
   amarelo grande, e validar com o teste de R4. Se reprovar, o plano B é a
   corujinha-do-mato (*Megascops choliba*), que tem tufos pequenos, olho
   amarelo e vive em área residencial no Brasil [F Wiki-Megascops].
2. **O onboarding perde a "foto" do bicho** se a revelação mostrar só um ovo.
   Proposta: mostrar a Nina adulta por 1,5 s como "quem vai nascer" e cortar
   para o ovo. Validar com usuário.
3. **Ritmo dos limiares** (1/5/15/40) é estimativa minha sobre a conta do
   código (~2 sessões por dia, `progressao.dart:274-276`), não medição.
   Instrumentar o tempo real até cada estágio antes de fixar.
4. **Base de usuários sem sessão de foco** (quem usa só o tempo de tela)
   ficaria com o ovo para sempre. Decidir se o "dia abaixo da meta" também
   conta para chocar. Isso exige uma decisão de produto.
5. **Contrato**: R1 não muda regra nenhuma, mas acrescenta estado persistido
   (contador por espécie) e um piso novo. Registrar num ADR em
   `DECISIONS.md`.
6. **Custo de desenho**: 15 estágios + 3 cenas de transição × 4 + sobreposição.
   O `CustomPainter` dá conta (o estilo é chapado), mas `pet.dart` já tem ~4.000
   linhas [A]. Dividir em `pet_coruja.dart`, `pet_axolote.dart` e
   `pet_pinguim.dart` (ou `part of`) antes de começar.
7. **Lacunas de fonte**: o tempo exato da 2ª penugem do pinguim-de-magalhães, a
   existência de creche nele (Scolaro † vs. Britannica †), o tobogã nessa
   espécie e o sono da coruja-buraqueira. Tudo marcado como estilização.
   WikiAves inacessível (403).
8. **Ovo de pinguim**: a espécie põe 2 ovos [F CES], e o app mostra um. É uma
   escolha deliberada (um bicho por pessoa). Não usar "o irmão" em lugar
   nenhum.
9. **Itens de espécie numa conta com várias espécies**: decidir se a roupa
   comprada vale para todas (hoje sim, `_veste`) ou só para a espécie. A
   recomendação é valer para todas, sem trava.

---

## 9. Fontes

† = lido só pelo resumo da busca; conferir a página antes de citar em texto
público.

**Coruja**
- [Cornell-BUOW-LH] Cornell Lab, All About Birds, Burrowing Owl — Life History: https://www.allaboutbirds.org/guide/Burrowing_Owl/lifehistory
- [Cornell-BUOW-sons] Burrowing Owl — Sounds: https://www.allaboutbirds.org/guide/Burrowing_Owl/sounds
- [Cornell-BUOW-ov] Burrowing Owl — Overview: https://www.allaboutbirds.org/guide/Burrowing_Owl/overview
- [Cornell-BAOW-LH] Barn Owl — Life History: https://www.allaboutbirds.org/guide/Barn_Owl/lifehistory
- [Cornell-BAOW-sons] Barn Owl — Sounds: https://www.allaboutbirds.org/guide/Barn_Owl/sounds
- [Wiki-BUOW] Wikipedia, Burrowing owl: https://en.wikipedia.org/wiki/Burrowing_owl
- [Wiki-Megascops] Wikipedia, Tropical screech owl (cita Birds of the World, Ong 2020): https://en.wikipedia.org/wiki/Tropical_screech_owl
- [PMSP-suindara] Prefeitura de São Paulo, Espécies da cidade — Suindara: https://prefeitura.sp.gov.br/web/meio_ambiente/w/servicos/fauna/especies_da_cidade/11324
- [PortalAmazônia†] Lenda da suindara: https://portalamazonia.com/meio-ambiente/coruja-rasga-mortalha-canto/
- [OwlPages] The Owl Pages, mesoptile: https://www.owlpages.com/owls/articles.php?i=35
- [SouthDowns†] South Downs National Park, Barn owl blog: https://www.southdowns.gov.uk/barn-owl-blog-the-growing-family/ ; Barn Owl Trust: https://barnowltrust.org.uk/barn-owl-facts/owlets-young-barn-owls
- [SussexWT†] Sussex Wildlife Trust, Tawny owlets branching out: https://sussexwildlifetrust.org.uk/news/tawny-owlets-branching-out
- [Cornell-cams†] Barred owlets prepare to leave the nest box: https://allaboutbirds.org/cams/barred-owlets-prepare-to-leave-the-nest-box
- [ScienceDaily] Johns Hopkins, owl head rotation (2013): https://www.sciencedaily.com/releases/2013/01/130131144102.htm
- [ORI-paralaxe†] Owl Research Institute, motion parallax: https://www.owlresearchinstitute.org/single-post/motion-parallax-in-owls
- [IOC†] International Owl Center, respectful observation: https://www.internationalowlcenter.org/respectful_observation.html
- [WorldOfOwls†] https://worldofowls.com/behaviour/
- [GoldenGate†] Golden Gate Bird Alliance, owling guide: https://goldengatebirdalliance.org/?p=68158
- [Vassar†] The Biology of the Barn Owl: https://pages.vassar.edu/sensoryecology/the-biology-of-the-barn-owl-tyto-alba/
- [Snopes] Baby owls sleep on stomachs? https://www.snopes.com/fact-check/baby-owls-sleep-stomachs/
- [JourneyNorth] Hatching facts (águia-careca; processo de pipping): https://journeynorth.org/tm/eagle/annual/facts_hatching.html

**Axolote**
- [SDZG-repro] San Diego Zoo Wildlife Alliance Library, Axolotl fact sheet — Reproduction: https://ielc.libguides.com/sdzg/factsheets/axolotl/reproduction
- [SDZG-comp] — Behavior: https://ielc.libguides.com/sdzg/factsheets/axolotl/behavior
- [SDZG-carac] — Characteristics: https://ielc.libguides.com/sdzg/factsheets/axolotl/characteristics
- [SDZG-dieta] — Diet: https://ielc.libguides.com/sdzg/factsheets/axolotl/diet
- [Nye2003] Nye, Cameron, Chernoff & Stocum (2003), Extending the Table of Stages of Normal Development of the Axolotl: Limb Development, *Developmental Dynamics* 226:555–560: https://ambystoma.uky.edu/genetic-stock-center/documents/Nye%20et%20al%202002.pdf
- [ExplorationPlace] Sponsor Axolotl: https://theexplorationplace.com/?p=11998
- [Wiki-Axolotl] Wikipedia, Axolotl: https://en.wikipedia.org/wiki/Axolotl
- [Axolotl.org] Axolotl biology: https://www.axolotl.org/biology.htm
- [Sucção 2025] The impact of size and ontogeny on suction feeding kinematics in the axolotl, *Biology Open*: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12309904/
- [TorontoZoo†] https://www.torontozoo.com/animals/Axolotl
- [BakuZoo†] https://bakuzoo.az/en/animals/fish/363
- [SciAm†] Scientific American, population drops 90% in four years: https://www.scientificamerican.com/blog/extinction-countdown/the-population-of-a-unique-mexican-amphibian-drops-90-percent-in-four-years
- [Caudata†] fórum de criadores (anedótico): https://www.caudata.org/threads/curled-gills-and-tail-questions.64687/

**Pinguim**
- [CES] Center for Ecosystem Sentinels (Univ. of Washington), Magellanic Penguin Biology: https://ecosystemsentinels.org/?p=3616
- [Wiki-Magellanic] Wikipedia, Magellanic penguin: https://en.wikipedia.org/wiki/Magellanic_penguin
- [Yorio†] Yorio et al., Breeding biology of Magellanic Penguins, *Marine Ornithology* 29: https://sora.unm.edu/sites/default/files/MO_29_2_75-79.pdf
- [Scolaro 1987†] Scolaro, *Journal of Field Ornithology* 58(4):432–441: https://sora.unm.edu/sites/default/files/journals/jfo/v058n04/p0432-p0441.pdf
- [Britannica Kids†] Magellanic penguin: https://kids.britannica.com/students/article/Magellanic-penguin/545029
- [Banded] Wikipedia, Banded penguin: https://en.wikipedia.org/wiki/Banded_penguin
- [CalAcademy] California Academy of Sciences, Common penguin behaviors: https://blog.calacademy.org/explore-science/common-penguin-behaviors
- [WHOI] Woods Hole Oceanographic Institution, Why do emperor penguins toboggan? https://www.whoi.edu/know-your-ocean/did-you-know/why-do-emperor-penguins-toboggan
- [NPR] These penguins take 10,000 little naps a day (sobre Libourel et al., *Science* 382:1026–1031, 2023): https://www.mprnews.org/story/2023/12/01/npr-these-penguins-take-10-000-little-naps-a-day-seconds-at-a-time ; [KOPRI] registro do artigo: https://repository.kopri.re.kr/handle/201206/16409?mode=full
- [BiologyOpen 2025†] muda e jejum em pinguim-azul: https://pmc.ncbi.nlm.nih.gov/articles/PMC12444856
- [Primorsky†] Primorsky Aquarium (pinguim-de-humboldt, incubação e eclosão): https://primocean.ru/en/aquarium/kopiya-novosti/kopiya-2023/new-penguin-chicks-to-hatch-soon.html
- [BemParaná†] Pinguins reabilitados no Paraná (PMP-BS, 2026): https://www.bemparana.com.br/noticias/parana/nove-pinguins-reabilitados-no-litoral-do-parana-retornam-ao-mar-mas-os-sobreviventes-sao-poucos
- [UNESP†] Dissertação sobre pinguim-de-magalhães e anchoíta: https://repositorio.unesp.br/handle/11449/216262

**Design**
- [Glocker 2009] Glocker et al., Baby Schema in Infant Faces Induces Cuteness Perception and Motivation for Caretaking in Adults, *Ethology* 115(3):257–263: https://pmc.ncbi.nlm.nih.gov/articles/PMC3260535/

# Laudo 08: Mel (gata), Faísca (raposa) e Bolota (buldogue francês)

Pesquisa dedicada a cada um dos três bichos, com a jornada e os visuais de
cada um. Outubro de 2026.

**Método.** Li o `BRIEF.md`, `docs/PRODUCT.md` e a seção de trilha do
`RELATORIO_UX_DUOLINGO.md`, e também o código: as partes de gata, raposa e
buldogue em `baru_app/lib/widgets/pet.dart`, os helpers compartilhados de olho,
boca e pose, `pet_profile.dart`, `progressao.dart`, o catálogo da loja em
`models.dart`, as paletas em `design/tokens.dart` e o posicionamento em
`habitat.dart`. Olhei 12 artes de humor (`play-store/arte/pet-{cat,fox,frenchie}-*.png`),
as homes `home-{cat,fox,frenchie}.png` e `home-cat-noite.png`, e as evidências
do buldogue de 28/08 (`buldogue-humores`, `-pelagens`, `-atividades`). As
fontes externas foram buscadas na web e estão citadas com link no texto e na
lista do fim.

**Legenda usada em todo o laudo:**
- **[F]** fato com fonte (link ao lado);
- **[A]** observação do app (arquivo:linha ou imagem);
- **[I]** inferência ou opinião minha.

Quando a única fonte encontrada é fraca (blog de tutor, loja), isso vem dito ao
lado. Quando não achei fonte, também digo.

---

## 0. Resumo executivo

1. **[A] As três espécies chegam tarde**: a gata no passo 18, o buldogue no 20
   e a raposa no 22, o último (`progressao.dart:419-471`). Pela estimativa do
   próprio código, isso dá cerca de 30, 33 e 67 dias de uso engajado
   (`progressao.dart:298-301`). Por isso o crescimento delas **não pode
   depender da trilha principal**, porque quando chegam a trilha já está quase
   no fim. Proponho um contador próprio de cada bicho, "sessões juntos", com 5
   estágios que nunca regridem.
2. **[A] Há um defeito comum nos olhos, que afeta as 9 espécies.** A
   pálpebra caída e a sobrancelha de tristeza em `_olho`
   (`pet.dart:3605-3625`) não são espelhadas entre os dois olhos. O olho
   esquerdo sai "triste" e o direito sai "bravo". Por isso a gata e a raposa
   em "saudade", e o buldogue em "neutro" e "sentindo falta", parecem
   **desconfiados ou zangados** em vez de saudosos. A correção é pequena e é a
   de maior retorno deste laudo.
3. **[A] Na gata e na raposa o humor está só no rosto.** As orelhas apenas
   tremem (`pet.dart:2340`, `2478`) e a cauda não muda com o humor. **[F]**
   Num estudo de sinais visuais em gatos, a posição das orelhas foi o fator
   que mais influenciou o desfecho das interações
   ([Deputte et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8469685/)).
   O buldogue já usa a orelha como canal de humor (`_orelhaTomba`,
   `pet.dart:2643-2653`). Os outros dois ficaram para trás.
4. **[A] A raposa não lê como raposa-vermelha.** Faltam o queixo, a garganta e
   a ponta da cauda **brancos**, as "meias" pretas e o focinho em V. Na tela
   ela lê como panda-vermelho ou esquilo (`pet-fox-*.png`).
5. **[A] Os três ficam de pé dentro do lago** na home (`home-cat.png`,
   `home-fox.png`, `home-frenchie.png`), embora o próprio código diga que gata,
   raposa e buldogue não entram na água (`pet.dart:89-95`, `124-132`).
6. **[F] Buldogue: ronco é sintoma.** O padrão da raça do Royal Kennel Club
   considera "inaceitável" o cão com "ruído respiratório excessivo" e pede
   narinas "visivelmente abertas" e focinho visível de perfil
   ([RKC](https://www.royalkennelclub.com/breed-standards/utility/french-bulldog)).
   O ronco do Bolota deve ser um ressonar leve e fofo, e não um chiado de BOAS
   (síndrome respiratória dos braquicefálicos) apresentado como graça.
7. **Para cada espécie entrego**: 5 estágios desenháveis em vetor, sendo o
   primeiro **de olhos fechados no ninho**, que é o equivalente do "ovo da
   coruja" que o dono pediu; a cena de cada transição; o mapa dos 5 humores;
   de 4 a 5 animações de assinatura com base em comportamento real; um
   "Diário" de marcos próprio; prompts de som para o ElevenLabs; e 7 itens
   temáticos.

---

## 1. Achados transversais (valem para as três espécies)

### 1.1 Onde elas entram na trilha e o que isso obriga

| Espécie | Passo | Marco | Critério | Estimativa do código |
|---|---|---|---|---|
| Gata (Mel) | 18 | `trinta_dias` | 30 dias seguidos de presença | ~30 dias |
| Buldogue (Bolota) | 20 | `cinquenta_focos` | 50 sessões | ~33 dias |
| Raposa (Faísca) | 22 | `cem_focos` | 100 sessões | ~67 dias |

Fonte: [A] `progressao.dart:419-471` e a estimativa em `progressao.dart:298-301`.

- **[I] Consequência 1.** Quem desbloqueia a raposa terminou a trilha. Se o
  crescimento dela dependesse de marcos da trilha, ela nasceria adulta e
  pronta, sem jornada nenhuma. O crescimento tem de contar **o tempo com aquele
  bicho**.
- **[I] Consequência 2.** O contador certo é o de **sessões concluídas com a
  espécie ativa**. Há três motivos. Sessão é o comportamento central do
  produto. Ela anda sem a permissão de uso, e o código já explica por que um
  contador que trava sem permissão vira muro (`progressao.dart:171-186`). E
  ela não se acumula sozinha, o que acontece com os dias de presença.
- **[I] Consequência 3.** Cada bicho tem o seu contador. Trocar de espécie nos
  ajustes **pausa** o crescimento de uma e retoma o da outra, e nada se perde
  (§1 do contrato).

### 1.2 Proposta comum: estágios de crescimento por bicho

| Estágio | Nome genérico | Sessões com o bicho | Tempo típico* | O que muda na tela |
|---|---|---|---|---|
| E1 | Recém-nascido | 0 (adoção) | minutos | No ninho ou na toca, olhos fechados, não fica em pé |
| E2 | Filhote | 1 | mesmo dia | Olhos abertos, cabeça enorme, cambaleia |
| E3 | Jovem | 5 | ~3 dias | Membros e orelhas desproporcionais, fase de brincar |
| E4 | Adulto | 15 | ~1 semana | O desenho de referência (atual, corrigido) |
| E5 | Pleno ("sábio" ou "veterano") | 45 | ~3 semanas | Sinais calmos de maturidade, nunca fragilidade |

\* **[I]** A coluna parte da estimativa do código de "duas sessões" por dia
engajado (`progressao.dart:298-299`). Os limiares são proposta minha e devem
ser calibrados com dados.

Regras da proposta:

- **[I] Nunca regride, e a pessoa escolhe o que mostrar.** Um "álbum" no perfil
  guarda todos os estágios já alcançados. Quem quer manter a Mel filhote para
  sempre pode, e isso conversa com o "nunca perde nada".
- **[I] O E1 dura até a primeira sessão com o bicho.** Ele existe para dar a
  sensação de "chegou um bebê" (o "ovo" do pedido do dono) sem obrigar o
  desenho de humor de olhos fechados a sustentar dias de uso.
- **[I] O E5 não é velhice com fragilidade.** O app não pode sugerir morte. O
  dono do produto pediu "idoso", mas o contrato diz "o bicho nunca morre", e
  **[F]** o buldogue francês tem a menor expectativa de vida ao nascer entre as
  raças de um estudo britânico, 4,53 anos
  ([Teng et al. 2022](https://rvc-repository.worktribe.com/output/1550511/life-tables-of-annual-life-expectancy-and-mortality-for-companion-dogs-in-the-united-kingdom)).
  Desenhar um Bolota velho, para quem conhece a raça, pode trazer essa sombra.
  Proponho **"pleno"**: focinho levemente grisalho no cão (**[F]** grisalhar é
  mais comum em cães que em gatos e aparece mais na face,
  [Oradell Animal Hospital](https://www.oradell.com/services/blog/aging-changes-dogs-and-cats)),
  postura serena e acessórios de "veterano". Ficam de fora bengala, olho
  opaco, magreza e tremor. **Isto não muda regra nenhuma do contrato.**
- **Como, em Flutter [I].** O desenho já é paramétrico (`_PetPainter` com
  `_bolha` e offsets). Cada estágio vira um registro
  `ProporcoesDoEstagio({escala, cabeca, olhoR, corDaIris, orelhaAltura,
  orelhaDobra, cauda, perna, pelagemFofa, ...})` por espécie. A transição
  anima com `lerpDouble`/`Color.lerp` entre dois registros, num
  `AnimationController` de 1,2 s, dentro da cena de transição (§2.3). O
  estado novo fica em `AppState`: `Map<Species,int> sessoesJuntos` e
  `Map<Species,int> estagioExibido`, sincronizado como o resto. Para manter o
  `_PetPainter` legível, os estágios E1 e E2 (pose deitada no ninho) devem
  sair em funções próprias, como `_gataNoNinho`, e não como mais
  condicionais dentro de `_gata`.

### 1.3 Defeito: pálpebra e sobrancelha não espelhadas (todas as espécies)

- **[A]** Em `pet.dart:3605-3616`, a pálpebra de "neutro" ou "triste" é um
  polígono de `(-1,05r, -0,35r)` até `(+1,05r, -0,75r)`, igual nos dois olhos.
  Em `pet.dart:3618-3624`, a sobrancelha triste vai de `(-0,9r, -1,5r)` até
  `(+0,5r, -1,1r)`, também igual nos dois. Nenhum dos dois recebe o lado.
- **[A] Na imagem.** Em `pet-cat-saudade.png`, a sobrancelha esquerda desce
  **em direção ao centro** (de x≈450,y≈277 até x≈517,y≈298), que é a
  expressão de raiva. A direita desce **para fora** (x≈683→748), que é a de
  tristeza. O mesmo padrão aparece em `pet-fox-saudade.png`. Em
  `buldogue-humores.png`, o olho direito do "neutro" e o do "sentindo falta"
  têm a pálpebra inclinada para dentro e leem como desconfiança.
- **[I] Efeito.** O humor "sentindo falta" é o mais delicado do produto (sem
  culpa) e hoje lê como "bravo com você". É o contrário do tom do contrato.

### 1.4 Os três ficam dentro do lago

- **[A]** Em `home-cat.png`, `home-fox.png` e `home-frenchie.png`, as patas
  ficam na faixa de água, sem anel nem lâmina, e o bicho parece flutuar de pé.
  O `habitat.dart:543-561` posiciona todos na mesma altura e desenha uma
  sombra cinza sobre a água. O comentário em `pet.dart:89-95` decide que gata e
  raposa "não entram na água por vontade própria", e o de `pet.dart:126-131`
  diz o mesmo do buldogue. O desenho de cena contradiz a decisão.
- **[I]** Para quem não nada, o certo é um **chão**: a margem de areia, uma
  pedra chata ou o item do bicho (almofada, toca, caminha, §2.6, §3.6, §4.6).

### 1.5 Nível de acabamento desigual

- **[A]** O buldogue tem cerca de 900 linhas próprias (`pet.dart:2560-3475`),
  com orelha por humor, sobrancelha por humor, rugas, papada, máscara e seis
  marcações. A gata (`pet.dart:2290-2419`) e a raposa (`pet.dart:2425-2550`)
  têm cerca de 130 linhas cada, com corpo `_bolha` genérico e humor só pelos
  helpers comuns.
- **[A] Na imagem.** O Bolota ocupa a largura x≈270-920 de 1200 e preenche o
  quadro como um bloco. A gata e a raposa são silhuetas de "boneco de pelúcia"
  com cauda à parte. Lado a lado, parecem de dois jogos diferentes.
- **[I]** A meta não é empobrecer o buldogue. É levar gata e raposa ao mesmo
  vocabulário: orelha, cauda e pose por humor, e marcas da espécie.

### 1.6 Sobreposição (item 7 do briefing)

- **[A]** `OverlayDoBaru.kt:299` desenha um bicho próprio em Kotlin, sem passar
  pelo `_PetPainter`. Os estágios propostos aqui **multiplicam** a divergência:
  a pessoa veria a Mel filhote no app e um bicho genérico sobre os outros apps.
- **[I]** Isto pertence a outro laudo, mas é uma dependência: os estágios só
  fazem sentido se a sobreposição usar o mesmo desenho. Um caminho é
  rasterizar o `PetView` atual (por `RepaintBoundary.toImage`) ao entrar em
  foco e entregar o PNG ao serviço nativo pelo `MethodChannel` que já existe.

---

## 2. Mel — gata

### 2.1 Biologia e comportamento reais

**Ciclo de vida**

| Fase | Idade | Aparência e comportamento | Fonte |
|---|---|---|---|
| Recém-nascido | 0-7 dias | Olhos fechados ao nascer, começam a abrir por volta do dia 6. Orelhas **dobradas**, desdobram entre o dia 3 e o 7. Não fica em pé. 85-140 g (3-5 oz) | **[F]** [Alley Cat Allies](https://alleycat.org/KittenProgression) |
| | 7-10 dias | Pálpebras abrem em fenda, às vezes **um olho antes do outro** | **[F]** [Agria](https://agriapet.co.uk/guides-and-advice/when-do-kittens-open-their-eyes) (seguradora; fonte de divulgação) |
| Filhote inicial | 2 semanas | Olhos totalmente abertos e **todos azuis**. Primeiros passos bambos. Já amassa pãozinho, sem conseguir recolher as unhas | **[F]** Alley Cat Allies |
| | 3-4 semanas | Dentes nascem, começa a brincar, orelhas totalmente estendidas por volta do dia 22 | **[F]** Alley Cat Allies |
| | 6 semanas | Usa a cauda para equilíbrio. **Espreita, se esconde, dá o bote**, cava | **[F]** Alley Cat Allies |
| | 7-8 semanas | Brincadeira com objetos aumenta muito | **[F]** [AAHA, desenvolvimento comportamental felino](https://www.aaha.org/resources/2015-aaha-canine-and-feline-behavior-management-guidelines/behavioral-developments-in-cats/) |
| | ~dia 57 | Olho adulto (amarelo, no exemplo da fonte) | **[F]** Alley Cat Allies |
| | 12-14 semanas | Brincadeira social começa a cair | **[F]** AAHA |
| Filhote ("kitten") | até 1 ano | Faixa etária oficial | **[F]** [AAHA/AAFP 2021](https://www.aaha.org/resources/2021-aaha-aafp-feline-life-stage-guidelines/feline-life-stage-definitions/) |
| Adulto jovem | 1-6 anos | | **[F]** AAHA/AAFP 2021 |
| Adulto maduro | 7-10 anos | | **[F]** AAHA/AAFP 2021 |
| Sênior | >10 anos | Pode ganhar pelos grisalhos e pelagem mais opaca ou fina | **[F]** AAHA/AAFP 2021; [Hill's](https://hillspet.com/cat-care/behavior-appearance/cat-aging-signs) |

**Comportamentos marcantes**

- **Piscada lenta.** **[F]** Os gatos semicerraram e piscaram mais quando os
  donos lhes davam a piscada lenta. Com um pesquisador desconhecido, os gatos
  se aproximaram mais depois da piscada lenta do que diante de rosto neutro.
  Os autores descrevem a piscada lenta como "uma série de meias-piscadas
  seguida de olho semicerrado prolongado ou fechamento" e a tratam como
  comunicação emocional positiva
  ([Humphrey et al. 2020, Scientific Reports](https://pmc.ncbi.nlm.nih.gov/articles/PMC7536207/)).
  É o "olhos semicerrados = confiança" do pedido, agora com fonte.
- **Cauda erguida.** **[F]** Ao se aproximar de uma pessoa, a gata em geral vem
  de cauda erguida, e quase sempre termina se esfregando na perna. Entre gatos,
  o papel afiliativo da cauda erguida ficou só "parcialmente" confirmado
  ([Deputte et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8469685/)).
  O estudo clássico é Cafazzo & Natoli, *Behavioural Processes* 80(1), 2009,
  citado pela mesma revisão. Não abri o texto completo dele.
- **Orelhas.** **[F]** Orelhas eretas nos dois gatos levaram a desfechos
  positivos (esfregar, ficar perto). Orelhas achatadas para os lados ou para
  trás levaram a fuga, evitação ou postura defensiva congelada (Deputte et al.
  2021).
- **Amassar pãozinho.** **[F]** É herança de filhote: o filhote pisa a mãe para
  estimular o leite. O gato adulto amassa quando se sente seguro ou sobre algo
  macio ([Live Science citando a enfermeira veterinária da International Cat Care](https://www.livescience.com/animals/cats/why-do-cats-knead);
  [The Conversation, Susan Hazel](https://theconversation.com/why-do-cats-knead-192743)).
  Alguns gatos adultos nunca amassam, e isso é normal.
- **Ronronar.** **[F]** Laringes de gato isoladas, sem nenhuma entrada neural,
  vibraram a **25-30 Hz**. Os autores atribuem isso a massas de tecido
  conjuntivo nas pregas vocais e não descartam totalmente o modelo muscular
  ([Herbst et al. 2023, Current Biology, cópia aberta](https://phaidra.vetmeduni.ac.at/o:3419)).
  **[I]** Para som e háptico, isso significa um "motorzinho" grave e contínuo,
  e não cliques espaçados.
- **Miado.** **[F]** O miado é a vocalização mais comum do gato para o humano e
  é pouco observado entre gatos. Ronronar e trinado são sons de boca fechada
  ([Nicastro & Owren 2003](https://Gwern.net/doc/cat/psychology/2003-nicastro.pdf),
  que cita Bradshaw & Cameron-Beaumont).
- **Caixa e esconderijo.** **[F]** Gatos recém-chegados a um abrigo que tinham
  uma caixa para se esconder tiveram escore de estresse menor nos dias 3 e 4
  ([Vinke et al. 2014](https://research-portal.uu.nl/en/publications/will-a-hiding-box-provide-stress-reduction-for-shelter-cats/)).
- **Corridas doidas ("zoomies") em gatos.** **Não achei fonte veterinária
  primária.** A fonte de "FRAPs" que encontrei é sobre cães (AKC, §4.1). Trato
  a ideia como inferência para a gata.

### 2.2 Avaliação do desenho atual

| Aspecto | Observação | Tipo |
|---|---|---|
| Proporção | A cabeça (82×69) tem praticamente a largura do corpo (80×70) (`pet.dart:2316-2318`, `2369-2371`). Dá uma silhueta "bichinho de pelúcia" boa para fofura, mas sem nada felino abaixo do pescoço: as patas são dois ovais quase escondidos sob a barriga (`pet-cat-contente.png`, y≈830-860) | [A] |
| Cauda | É uma cunha cheia de `sombraForte`, marrom-escuro, mais larga na base (`pet.dart:2298-2310`). Lê como cauda de castor ou esquilo, e não como a cauda fina e flexível de gata. Tem cor diferente do pelo e por isso parece objeto à parte | [A] |
| Orelhas | Triangulares, com a ponta **arredondada** (`pet-cat-*.png`), o que aproxima de lince ou urso. Não mudam com o humor, só tremem (`pet.dart:2340`) | [A] |
| Marcas | Três listras na testa (`pet.dart:2374-2384`) seguram o "gata". Falta o "M" de tabby, que é o que mais se reconhece numa gata malhada | [A] / [I] |
| Radiante × contente | Diferem só por brilhos, bochecha e o tamanho do sorriso (`pet-cat-radiante.png` × `pet-cat-contente.png`). O corpo é idêntico | [A] |
| Sono | Dorme **sentada**, só com olhos fechados, zZ e folha (`pet-cat-sono.png`). O cochilo apenas gira o corpo em -0,16 (`pet.dart:1296`). Gata dormindo enrola ("rosquinha") | [A] / [I] |
| Saudade | Lê como **brava** por causa do defeito do §1.3 | [A] |
| Legibilidade na home | Boa de longe: listras e bigodes aparecem (`home-cat.png`). Na noite (`home-cat-noite.png`) o bicho perde contraste, mas continua legível | [A] |
| Consistência | É a mais simples das três (§1.5) | [A] |
| Fofura | Alta no rosto (olhos grandes, nariz de coração, `pet.dart:2393-2402`). Baixa no corpo | [I] |

### 2.3 Cinco estágios da Mel

Coordenadas no sistema do painter (corpo centrado em `(0, 20)`; o adulto atual
tem cabeça 82×69 e olho r = 7,5). As cores derivam de `pelagemGata`.

**E1 — Mel recém-nascida, "no cestinho"**
- **Cena.** Cesto de vime oval (90×34, `AppColors.wood` com trama em
  `woodDark`) e manta xadrez creme e laranja dobrada. O cesto fica **na margem
  de areia**, e não na água.
- **Corpo.** Feijão deitado de barriga, 46×24, encostado na manta. A cabeça é
  uma bolha de 38×30, quase do tamanho do corpo, apoiada de lado.
- **Olhos fechados.** Duas linhas curvas de 6 px, com a curva para baixo
  (dormindo de verdade), e não o arco feliz.
- **Orelhas dobradas.** Triângulos de 8 px de altura, tombados para os lados e
  rentes ao crânio, porque ao nascer as orelhas são dobradas (Alley Cat Allies).
- **Pelo.** Contorno com 5 ou 6 "bicos" suaves (penugem). Focinho e almofadas
  rosados. Bigodes de só 2 fios curtos. Cauda é um toquinho de 12 px.
- **Escala total.** 0,45 do adulto.
- **Movimento.** Respiração rápida e curta e, às vezes, um "pedalar" das patas
  dianteiras na manta (o amassar já existe aos 14 dias, Alley Cat Allies).

**E2 — Mel filhote, "olho azul"**
- **Pose.** Sentada e meio torta, com o peso caindo para um lado.
- **Proporções.** Cabeça 66×58 sobre corpo 44×40, ou seja, a cabeça 50% maior
  que o corpo. Olhos r = 10, íris **azul-acinzentada** (`#8FA7C4`) com dois
  brilhos, porque os filhotes têm olhos azuis às duas semanas (Alley Cat
  Allies).
- **Orelhas.** Pequenas, de 16 px, arredondadas e bem afastadas.
- **Patas.** Grossas e curtas, com almofadas rosadas visíveis.
- **Cauda.** Curta (22 px), reta e para cima, como uma antena.
- **Marcas.** "M" fraco na testa.
- **Escala.** 0,6.

**E3 — Mel jovem, "fase do bote"**
- **Olhos.** Já na cor adulta: âmbar `#D9A441` ou verde `#9DB36A`, escolhido
  na pelagem. A cor adulta aparece por volta do dia 57 (Alley Cat Allies).
- **Orelhas.** **Grandes demais** para a cabeça: 30 px numa cabeça de 70.
  **[I]** É a desproporção que todo mundo reconhece num gato de 3 meses.
- **Corpo.** Esguio (58×60), pernas visivelmente mais longas, cauda longa e
  fina (70 px) com 3 anéis escuros.
- **Postura.** Traseiro um pouco mais alto que a frente, pronto para brincar.
- **Escala.** 0,8.

**E4 — Mel adulta (o desenho de referência, corrigido)**
- **Cabeça e orelhas.** A cabeça atual, com orelhas de ponta **fina** e um
  tufinho claro dentro, e o "M" tabby completo.
- **Cauda.** Troca a cunha por um tubo de 9 px na cor do pelo, com anéis em
  `sombra`. Nos humores bons, sobe e termina em gancho ("ponto de
  interrogação").
- **Patas.** As dianteiras aparecem na frente da barriga, de 14×12 cada.
- **Escala.** 1,0.

**E5 — Mel plena, "dona do sol"**
- **Silhueta.** A adulta, 6% mais larga e 3% mais baixa.
- **Pelagem.** Alguns fios claros no focinho e acima dos olhos (3 traços de
  1 px em `claro`). O fundamento é que gatos idosos podem ganhar pelos
  grisalhos ([Hill's](https://hillspet.com/cat-care/behavior-appearance/cat-aging-signs)).
- **Olhos.** No repouso ficam semicerrados por mais tempo: `fechamento` de
  base 0,25.
- **Acessório.** Ganha uma almofada própria, de cor escolhida.
- **Escala.** 1,0.

**Cenas de transição** (4 a 6 s, puláveis; com "reduzir movimento" vira um
cartão estático de antes e depois):

| De → para | Cena | Base real |
|---|---|---|
| E1 → E2 | **"A primeira olhada."** A manta se mexe, abre **um** olho azul e depois o outro, a Mel boceja e senta, torta | Pálpebras abrem em fenda, às vezes um olho antes do outro (Agria) |
| E2 → E3 | **"O primeiro bote."** Uma folha cai, ela abaixa, rebola o traseiro e salta. Erra e cai de costas. Na hora em que pousa, as proporções interpolam para E3 | Espreitar, se esconder e dar o bote às 6 semanas (Alley Cat Allies) |
| E3 → E4 | **"O ponto de interrogação."** Ela caminha até a câmera de cauda erguida em gancho, para e faz a **piscada lenta** para a pessoa | Aproximação de cauda erguida (Deputte 2021) e piscada lenta (Humphrey 2020) |
| E4 → E5 | **"Lugar ao sol."** Um feixe de luz cruza a cena, ela amassa a almofada nova três vezes e se deita | Amassar quando se sente segura (iCatCare via Live Science) |

### 2.4 Personalidade, humores e animações

**Traço de personalidade.** **[A]** O texto atual da espécie diz: "Escolhe a
hora e o lugar, e não negocia" (`l10n.dart:855-858`). **[I]** Proponho somar
"carinho dado nos termos dela". A confiança da Mel aparece pela piscada lenta
e pela cauda, e não pelo pedido de colo.

**Humores do app na gata** (`Mood` em `pet.dart:1158`; a precedência vem de
`PRODUCT.md §3`):

| Humor | Orelhas | Cauda | Olhos | Corpo e boca | Som |
|---|---|---|---|---|---|
| Radiante | Eretas, viradas para a frente | **Erguida, com gancho na ponta**, tremendo de leve | Abertos e brilhantes, com uma piscada lenta a cada 8-12 s | Sentada alta. Boca "w" de gato | Trinado curto ("brrrp") |
| Contente | Eretas e relaxadas | Erguida, sem tremor | Semicerrados (`fechamento` 0,3) | Sentada, com as patas juntas. Bigodes para a frente | Ronronar baixo, só no afago |
| Neutro | Uma delas gira de lado de vez em quando ("radar") | Horizontal, com a ponta balançando devagar | Abertos, sem brilho extra | Postura de esfinge ("pão de forma") | Nenhum |
| Sonolento | Relaxadas, um pouco para os lados | Enrolada em volta das patas | Fechando aos poucos | Rosquinha (§R7) | Respiração lenta |
| Sentindo falta | **Para os lados e um pouco baixas**, nunca achatadas para trás, que é sinal de medo ou agressão (Deputte 2021) | Baixa, enrolada no corpo | Abertos e voltados para a porta ou borda da cena; sobrancelhas **espelhadas** (§1.3) | Sentada de costas meio virada, olhando para fora | Um miado único e suave quando a pessoa volta. Ao voltar, a reação é de alegria, e não de cobrança |

**Animações de assinatura** (ociosas; entram no `GestoOcioso` por espécie,
`pet.dart:554-561`):

1. **Piscada lenta de volta.** Se a pessoa segura o dedo parado sobre o rosto
   da Mel por 1,5 s, ela faz 2 meias-piscadas e um fechamento de 0,8 s. **[F]**
   Humphrey 2020. **[I]** É o "carinho" mais barato e mais verdadeiro que o
   app pode ter.
2. **Amassar pãozinho.** Durante o afago, a partir de `gosto > 0,5`, as patas
   dianteiras alternam para cima e para baixo (3 px, a 2 Hz) sobre a almofada
   ou o chão. **[F]** iCatCare via Live Science.
3. **Caça brincando.** Ela abaixa, rebola o traseiro (oscilação lateral de
   ±3 px, 3 vezes), salta sobre uma folha, uma borboleta ou o novelo comprado.
   **[F]** Alley Cat Allies, 6 semanas.
4. **Higiene.** Lambe a pata e passa atrás da orelha, 2 vezes. **[I]** Comum e
   imediatamente reconhecível. Não busquei fonte específica.
5. **Corrida noturna** (só no horário de noite do habitat e só com humor
   radiante). Ela atravessa a cena de um lado ao outro e volta, de cauda
   eriçada. **[I]** Sem fonte primária para gatos (ver §2.1).

### 2.5 Jornada da Mel

**Diário da Mel.** Uma trilha curta própria, contada em sessões com a Mel. A
recompensa é visual e de cena, e às vezes folhas, mas **nunca dinheiro real**:

| Marco | Critério | Entrega |
|---|---|---|
| Chegada | Desbloquear no passo 18 | E1: o cesto aparece na margem do habitat atual |
| Primeira olhada | 1 sessão | E2 e a cena de transição |
| Primeiro bote | 5 sessões | E3, a folha vira brinquedo fixo e libera o gesto "caça brincando" |
| Confiança | 10 sessões | O gesto "piscada lenta de volta" (§2.4-1) passa a responder |
| Cauda erguida | 15 sessões | E4 e a saudação de cauda erguida ao abrir o app |
| Janela | 25 sessões | Cenário próprio "Parapeito ao sol", um quadro de janela sobre a cena |
| Ninho de caixa | 35 sessões | A caixa de papelão aparece de graça na cena (§2.6 tem a versão "decorada" na loja) |
| Lugar ao sol | 45 sessões | E5 e a almofada própria |

- **[I] Ligação com a trilha principal.** No passo 17, um passo antes da Mel,
  aparecem pegadinhas na areia do habitat, como prévia do que vem. Isso
  aprofunda a R24 do relatório anterior (prévia do próximo capítulo).

**Sons e voz** (prompts para o ElevenLabs, em *Sound Effects*, em inglês, que
é a língua em que o modelo foi treinado com mais exemplos). **[I]** Saem como
som e não como fala, então não exigem os 4 idiomas.

| Uso no app | Prompt (EN) | Duração |
|---|---|---|
| Afago (substitui `carinho.wav` para a Mel) | "Close-mic domestic cat purr, warm low rumble around 25 Hz, steady and soft, no room noise, gentle fade in and out" | 3 s, em loop |
| Saudação, radiante | "Single short cat trill, friendly 'brrrp' chirp with rising pitch, soft, close, no background" | 0,4 s |
| Volta depois de saudade | "One gentle soft cat meow, short and sweet, not demanding, quiet, indoor, no reverb" | 0,6 s |
| E1 (recém-nascida) | "Very tiny newborn kitten squeak, faint and soft, single, close microphone" | 0,3 s |
| E2 (filhote) | "Small kitten mew, high pitched, cute, short, single" | 0,4 s |
| Bote ou brincadeira | "Quick soft paw pounce on dry leaves, light rustle, playful" | 0,5 s |
| Transição de estágio | "Soft cat purr swelling into a bright gentle chime, warm and magical, short" | 2 s |

- **[I] Mixagem.** Normalizar para o mesmo nível dos `assets/sons/*.wav`
  atuais. Nada de chiado nem de "hiss", porque o hiss é som de ameaça e não
  combina com o tom do app.

### 2.6 Itens temáticos da Mel (folhas, nunca dinheiro)

| Item (pt-BR) | Categoria | Onde aparece | Preço sugerido | Gatilho de animação |
|---|---|---|---|---|
| Caixa de papelão | Objeto | Margem direita, x≈262-330, y≈150-176 | 90 | Ela entra e só as orelhas aparecem (base: Vinke 2014) |
| Novelo de lã | Objeto | Areia à frente, à esquerda do bicho | 70 | Alvo da "caça brincando" |
| Arranhador de tronco | Objeto | Margem esquerda, ao lado da árvore | 150 | Espreguiça e arranha (gesto `espreguica` existente) |
| Almofada ao sol | Objeto (chão do bicho) | Sob a Mel, resolve o §1.4 | 120 | Amassar pãozinho |
| Varinha de pena | Objeto | Presa no varal ou galho, balança | 110 | Ela olha e balança a cabeça junto |
| Laço de fita | Roupa (cabeça) | Entre as orelhas | 60 | — |
| Coleira de sininho | Roupa (pescoço) | Pescoço | 70 | Tilinta baixinho quando ela pula. **[I]** O som deve ser opcional, porque irrita em loop |

**[I]** A caixa, o novelo e a almofada viram também o **chão** da gata (§1.4).

---

## 3. Faísca — raposa

### 3.1 Biologia e comportamento reais

**Espécie de referência.** Raposa-vermelha (*Vulpes vulpes*), porque é a raposa
"de livro" que todo mundo reconhece. **[F]** No Brasil não há raposa-vermelha
nativa. Os "graxains" são canídeos sul-americanos: o graxaim-do-campo
(*Lycalopex gymnocercus*), de áreas abertas e classificado como "menos
preocupante" pelo ICMBio
([ICMBio, avaliação](https://revistaeletronica.icmbio.gov.br/BioBR/article/download/383/290/1554)),
e o graxaim-do-mato ou cachorro-do-mato (*Cerdocyon thous*). Os dois vivem
juntos no Rio Grande do Sul, e o do mato é predominantemente noturno
([Univates](https://univates.br/revistas/index.php/destaques/article/view/3326)).
O graxaim-do-campo tem pelagem avermelhada na cabeça e no pescoço e uma marca
preta no focinho ([Wikipedia, Pampas fox](https://en.wikipedia.org/wiki/Pampas_fox)).
**[I]** Recomendo manter a Faísca como raposa-vermelha, por legibilidade
global nos 4 idiomas, e oferecer o graxaim como **pelagem** (cinza-mesclado com
cabeça ruiva), um aceno brasileiro que não confunde (§3.6).

**Ciclo de vida** (salvo indicação, a fonte é
[Wildlife Online, crescimento dos filhotes](https://www.wildlifeonline.me.uk/animals/article/red-fox-breeding-growth-development-of-cubs)):

| Fase | Idade | Aparência e comportamento |
|---|---|---|
| Recém-nascido | 0-7 dias | **Pelo cinza, fino e lanoso, e nariz rosado**, que fica preto na primeira semana. 50-150 g. **Cego e surdo**, não regula a própria temperatura |
| | 10-14 dias | Olhos e orelhas abrem |
| | ~2 semanas | O cinza escurece para **marrom-chocolate** |
| | ~3 semanas | Aparece uma **faixa preta no olho** e ele começa a andar cambaleando |
| | ~4 semanas | Surgem o **focinho branco e as manchas ruivas**; as orelhas ficam eretas e o focinho começa a alongar |
| | 4-6 semanas | O olho passa de azul-ardósia a "castanho-fumaça" e chega ao **âmbar por volta de 3 meses** |
| | ~5 semanas | Sai da toca e brinca do lado de fora |
| | ~6 semanas | Pelagem parecida com a do adulto, mas ainda lanosa |
| | ~8 semanas | Pelos de guarda longos dão brilho, e ele descansa fora da toca |
| | 8-15 semanas | A brincadeira diminui e o filhote fica **desconfiado com o novo** (neofobia) |
| | ~4 meses | Tamanho adulto, mas peso de cerca de 3 kg |
| Adulto | 1 ano | Considerado adulto. A pelagem de inverno começa a crescer em agosto (no hemisfério norte) |
| Expectativa de vida | | Cerca de 6 anos na natureza e até 15 em cativeiro ([Forest Park Zoo](https://forestparkzoo.org/animals/red-fox)). **Não achei a ficha de um zoo grande**, como o Smithsonian |

**Comportamentos e corpo**

- **Cauda-cobertor.** **[F]** No vento frio do inverno, usa a cauda longa para
  cobrir a pele nua do nariz e das almofadas das patas. A cauda chega a cerca
  de metade do comprimento do corpo. A ponta da cauda é branca, e o branco
  também está na parte de baixo, no queixo e na garganta
  ([National Park Service, Isle Royale](https://www.nps.gov/isro/learn/nature/red-fox.htm)).
- **Ponta branca como sinal.** **[F]** Henry propôs que a ponta branca,
  combinada com a cauda chicoteando, evoluiu como exibição para chamar atenção.
  O padrão de cor das orelhas funcionaria como um semáforo
  ([Wildlife Online, comunicação](https://wildlifeonline.me.uk/animals/article/red-fox-behaviour-communication)).
- **Postura defensiva.** **[F]** Orelhas achatadas, dorso levemente arqueado e
  cauda enrolada. Na submissão, a raposa pode deitar de bruços de boca aberta
  (Wildlife Online, comunicação).
- **Bote de rato ("mousing").** **[F]** Ouve presas sob a neve
  ([Smithsonian, vídeo](https://www.si.edu/object/red-fox-hilariously-pounces-headfirst-snow%3Ayt_RCqQYpM1hCA)).
  Num estudo com 84 raposas e 592 saltos, os botes na direção nordeste
  acertaram 73%, contra 18% nas direções laterais
  ([Červený et al. 2011, Biology Letters, via phys.org](https://phys.org/news/2011-01-predation-foxes-aided-earth-magnetic.html)).
  A hipótese magnética é dos autores e não está confirmada.
- **Esconder comida.** **[F]** A raposa enterra sobras espalhadas em vários
  esconderijos, e a regra é a dispersão e não a despensa única
  ([Wildlife Online](https://www.wildlifeonline.me.uk/questions/answer/are-there-exceptions-to-the-foxes-scatter-cache-rule)).
- **Horário.** **[F]** Caça preferencialmente ao entardecer e ao amanhecer
  (Forest Park Zoo). **[I]** Combina com o habitat que muda com a hora do dia,
  e a Faísca pode ficar mais animada nesses horários.

**Vocalizações**

- **Repertório.** **[F]** 20 tipos de chamado, dos quais 8 só de filhotes, a
  partir da análise de 585 gravações
  ([Newton-Fisher et al. 1993, Bioacoustics](https://bioacoustics.info/article/structure-and-function-red-fox-vulpes-vulpes-vocalisations)).
- **Os chamados descritos.** **[F]** Pela Wildlife Online (comunicação):
  - latido "wow-wow-wow", provavelmente territorial;
  - **gekkering**, um gaguejar de boca aberta usado em embates;
  - grito da fêmea;
  - **gemido-rosnado de saudação**;
  - a mãe chama os filhotes com um rosnado baixo descrito como "mew/churr/purr";
  - os filhotes choramingam e "gorjeiam" quando estão sozinhos;
  - o chiado do filhote, a partir de 1 mês, evolui para o gekkering.
- **[I] O que usar no app.** O **gekker de brincadeira**, curto e abafado, e
  os sons de filhote. Evitar o grito e o latido territorial, porque assustam e
  soam lúgubres. A própria fonte compara o grito a "o lamento de todos os
  enlutados".

### 3.2 Avaliação do desenho atual

| Aspecto | Observação | Tipo |
|---|---|---|
| Leitura de espécie | Lê como **panda-vermelho ou esquilo** (`pet-fox-contente.png`): cabeça redonda, focinho em oval largo que não projeta, barriga e focinho **salmão** (`claro`) em vez de branco | [A] |
| Brancos ausentes | Queixo, garganta, peito e ponta da cauda são brancos na espécie (NPS). No desenho, a ponta da cauda é `claro` (laranja-pálido, `pet.dart:2445-2447`) e o corpo da cauda é `sombraForte` marrom-escuro, sem nenhum ruivo. Na espécie, a cauda é ruiva com ponta branca | [A] / [F] |
| Pernas | Patas na cor `sombraForte` (`pet.dart:2449-2452`). **[I]** As "meias" pretas da raposa-vermelha são marca clássica. Não achei fonte técnica direta, só o consenso de guias, então registro como inferência de reconhecimento | [A] / [I] |
| Orelhas | Grandes e com ponta escura (`pet.dart:2477-2508`), o que é correto. Mas a ponta escura lê como uma "boina" solta, e há um **corte reto horizontal** na base de cada orelha, fora do contorno da cabeça (`pet-fox-contente.png`, x≈370,y≈322 e x≈835,y≈327) | [A] |
| Humor | Igual ao da gata: só o rosto muda. Orelha e cauda não mudam (`pet.dart:2478`) | [A] |
| Sono | Sentada, sem a cauda-cobertor, que é o gesto mais icônico de raposa dormindo (`pet-fox-sono.png`) | [A] / [F] NPS |
| Saudade | Lê como brava (§1.3) | [A] |
| Fofura | O focinho curto deixa fofa, mas genérica. **[I]** Um focinho em V moderado, com bochechas brancas, segue fofo e fica inconfundível | [I] |
| Contraste na home | Ruivo sobre verde lê bem (`home-fox.png`) | [A] |

### 3.3 Cinco estágios da Faísca

A diferença entre os estágios **já é extremamente visível na própria biologia**:
o filhote nasce **cinza-chocolate**, e não laranja.

**E1 — Faísca recém-nascida, "na toca"**
- **Cena.** A boca de uma toca no barranco da margem: um arco escuro de 60×36
  com raízes (`woodDark`) por cima e um montinho de terra na frente.
- **Corpo.** Uma bolinha enrolada de 40×26, **cinza-carvão** (`#5A5450`), com
  penugem de contorno serrilhado. Focinho curto e **nariz rosado**, porque ao
  nascer o nariz é rosa e o pelo é cinza (Wildlife Online).
- **Olhos e orelhas.** Olhos fechados (linhas curvas para baixo). Orelhas são
  dois toquinhos dobrados de 6 px.
- **Cauda.** Fina, de 16 px, enrolada no corpo.
- **Escala.** 0,4.
- **Detalhe vivo.** De vez em quando, uma segunda cabecinha aparece e some no
  fundo da toca. **[I]** Raposas nascem em ninhada, e isto dá vida à cena sem
  criar um segundo bicho jogável.

**E2 — Faísca filhote, "chocolate de olho azul"**
- **Pelagem e olhos.** Marrom-chocolate (`#5E4334`), olhos abertos
  **azul-ardósia** (`#7D93A8`) e r = 9,5.
- **Máscara.** Uma **faixa escura do olho até o focinho**, como uma lágrima,
  que aparece às 3 semanas (Wildlife Online).
- **Proporções.** Cabeça redonda e grande (64×56) sobre corpo de 42×40.
  Orelhas **ainda semidobradas**, arredondadas, de 14 px.
- **Pose.** Cambaleia (o `pesoNoPe` mais exagerado).
- **Escala.** 0,55.

**E3 — Faísca jovem, "primeiro ruivo"**
- **Pelagem.** Ruivo aparecendo em manchas sobre o chocolate (dorso e cabeça),
  **focinho branco** e **orelhas eretas, grandes demais**. É o que acontece às
  4 semanas (Wildlife Online).
- **Focinho.** Começa a alongar: 30 px de projeção, contra 22 no E2.
- **Olhos.** "Castanho-fumaça" (`#8A7560`), o tom das 4 a 6 semanas.
- **Pelo.** Ainda lanoso, com contorno fofo.
- **Cauda.** Ganha volume e uma **ponta branca pequena**.
- **Escala.** 0,75.

**E4 — Faísca adulta (redesenho)**
- **Cabeça.** Em "V" suave: largura de 80 nas bochechas e focinho projetado e
  afinando até o nariz preto.
- **Brancos.** Bochechas, queixo, garganta e peito **brancos**
  (`Cores.superficie`), que é o par cromático que define a espécie (NPS).
- **Olhos.** **Âmbar** (`#D79A3C`), com pupila levemente oval.
- **Pernas e orelhas.** Pernas com "meias" escuras do joelho para baixo e dorso
  da orelha escuro, desenhado como gradiente na borda e não como boina solta.
- **Cauda.** Na cor do pelo, com a ponta **branca** grande (disco de 17 px,
  como hoje, mas em branco) e comprimento de ~60% da altura do corpo. A espécie
  tem cerca de metade do comprimento do corpo (NPS); **[I]** exagero um pouco
  porque a cauda é o nome dela.
- **Escala.** 1,0.

**E5 — Faísca plena, "pelagem de inverno"**
- **Pelagem.** Mais cheia: contorno do corpo e da cauda +8%, com "colarinho"
  branco mais volumoso. A pelagem de inverno começa a crescer em agosto
  (Wildlife Online).
- **Cauda.** Maior do elenco, e passa a servir de cobertor em todas as sonecas.
- **Focinho.** Fios prateados discretos. **[I]** O NPS cita pelagem com pontas
  prateadas como variação de cor, e não como idade. Uso como "brilho de
  maturidade", sem afirmar que é envelhecimento.
- **Escala.** 1,05.

**Cenas de transição**

| De → para | Cena | Base real |
|---|---|---|
| E1 → E2 | **"Olhos azuis no escuro."** Dois pontos azuis acendem dentro da toca e ela põe a cabeça para fora, piscando | Olhos abrem aos 10-14 dias e são azul-ardósia (Wildlife Online) |
| E2 → E3 | **"A primeira saída."** Ela sai da toca cambaleando, as orelhas se erguem uma de cada vez ("boing", "boing") e o ruivo "acende" em manchas | Sai da toca por volta de 5 semanas; orelhas eretas às 4 (Wildlife Online) |
| E3 → E4 | **"A ponta branca."** Ela persegue a própria cauda, para, e a ponta clareia até o branco. Termina com o primeiro bote de rato, de focinho na grama | Ponta branca como sinal (Wildlife Online); bote (Smithsonian, Červený 2011) |
| E4 → E5 | **"Primeira geada."** Folhas ou flocos caem, a pelagem engrossa, e ela se enrola com a cauda sobre o nariz | Pelagem de inverno (Wildlife Online); cauda-cobertor (NPS) |

### 3.4 Personalidade, humores e animações

**Traço.** **[A]** O texto atual: "Curiosa e rápida de mudar de ideia. Você
aprende no atalho" (`l10n.dart:859-862`). **[I]** Somo "**desconfiada no
começo, fiel depois**", com apoio na neofobia das 8 a 15 semanas (Wildlife
Online). No E3, a Faísca dá um passinho para trás na primeira vez que a pessoa
toca nela. A partir do E4, ela vem até o dedo. É uma narrativa de confiança
conquistada que combina com "voltar todo dia".

**Humores na raposa**

| Humor | Orelhas | Cauda | Olhos | Corpo e boca | Som |
|---|---|---|---|---|---|
| Radiante | Eretas e para a frente, girando como radar | Alta e **chicoteando** de leve, com a ponta branca bem visível | Abertos, âmbar com brilho | Saltitante (gesto `saltinho`), boca aberta com "sorriso" de canídeo | Gekker curto de brincadeira |
| Contente | Eretas e relaxadas | Horizontal, com balanço lento | Semicerrados | Sentada, com a cauda enrolada ao lado das patas | Gemido-rosnado de saudação, baixinho, só ao abrir o app |
| Neutro | Uma gira para o lado | Baixa e reta | Abertos | Deitada como esfinge, olhando a cena | Nenhum |
| Sonolento | Deitadas para trás e relaxadas | **Sobre o nariz** (cobertor) | Fechados | Enrolada em círculo | Respiração |
| Sentindo falta | Para os lados e baixas, sem achatar para trás, que é postura defensiva (Wildlife Online) | Baixa, enrolada no corpo | Voltados para a borda da cena | Sentada na boca da toca, olhando a trilha | Choramingo de filhote **muito** suave e único. **[I]** Nunca em loop, para não culpar |

**Animações de assinatura**

1. **Bote de rato.** Ela congela, as orelhas giram, o corpo agacha, faz um
   salto em arco alto e cai **de focinho** na grama (cerca de 1,4 s).
   - **[F]** Smithsonian e Červený 2011.
   - **Easter egg:** o bote vai sempre para o canto **superior direito** da cena
     (o "nordeste" do mapa). **[I]** Um detalhe que fã de natureza reconhece.
2. **Cauda-cobertor.** Ao entrar em cochilo, ela gira duas vezes, deita e
   puxa a cauda sobre o nariz. **[F]** NPS.
3. **Orelhas de radar.** A cada toque na **cena** (fora do bicho), as duas
   orelhas giram até o ponto tocado e a cabeça vem atrás 150 ms depois. **[F]**
   Audição usada para caçar (Smithsonian).
4. **Esconder petisco.** Depois do `petisco`, ela cava um buraquinho, enterra
   metade e cobre com o focinho. **[F]** Wildlife Online (esconder comida).
5. **Gekker de brincadeira.** No radiante, faz pulinhos laterais com a boca
   aberta e o som gaguejado. **[F]** O chiado do filhote evolui para o
   gekkering (Wildlife Online).

### 3.5 Jornada da Faísca

**Diário da Faísca** (em sessões com a raposa):

| Marco | Critério | Entrega |
|---|---|---|
| A toca | Desbloquear no passo 22 | E1. A toca aparece no barranco do habitat atual |
| Olhos azuis | 1 sessão | E2 |
| Primeira saída | 5 sessões | E3. Ela passa a explorar a margem (anda até as bordas no ocioso) |
| Confiança | 10 sessões | Para de recuar ao toque (§3.4) |
| A ponta branca | 15 sessões | E4 e o "bote de rato" |
| Capim alto | 25 sessões | Cenário próprio "Campo de capim" ao entardecer |
| Esconderijos | 35 sessões | Ela passa a "esconder" folhas, que reaparecem no dia seguinte como +1 folha de bônus. **[I]** Isso exige um ajuste de balanço: limitar a 1 por dia e registrar em `progressao.dart` |
| Primeira geada | 45 sessões | E5 |

- **[I] O problema do fim de trilha.** A raposa é o último marco, e o
  relatório anterior aponta que "ao completar: nada"
  (`RELATORIO_UX_DUOLINGO.md`, §5). O Diário da Faísca é, de fato, **o
  primeiro conteúdo pós-trilha** do app, e por isso merece prioridade.
- **[I] Prenúncio.** No passo 21, aparecem orelhas ruivas por cima do capim na
  borda do habitat por 2 s, uma vez por dia.

**Sons e voz** (ElevenLabs, Sound Effects)

| Uso | Prompt (EN) | Duração |
|---|---|---|
| Radiante | "Short playful fox gekkering, soft rapid chattering stutter, muffled, cute, close mic, no background" | 0,6 s |
| Saudação ao abrir | "Gentle fox greeting whine with a soft low churr, affectionate, quiet" | 0,8 s |
| E1 | "Tiny fox cub whimper, very soft, faint squeak inside a burrow, muffled" | 0,4 s |
| E2 | "Fox kit small yip, high pitched, single, cute" | 0,3 s |
| Bote de rato | "Quick swish of a light animal leaping, then soft thump into tall grass with rustle" | 0,8 s |
| Esconder petisco | "Small paws digging in soft soil, three quick scratches, then a gentle pat" | 0,9 s |
| Transição | "Rustling autumn leaves swirling, then a soft bright twinkle chime" | 2 s |

**[I]** Não usar o grito da fêmea nem o latido "wow-wow". Ficam fora do tom.

### 3.6 Itens temáticos da Faísca

| Item (pt-BR) | Categoria | Onde | Preço | Gatilho |
|---|---|---|---|---|
| Toca de raízes | Objeto (chão do bicho) | Margem esquerda, barranco, x≈20-90, y≈150-178 | 150 | Ela dorme na boca da toca (resolve o §1.4) |
| Capim alto | Objeto | Margem direita, em tufos | 90 | Alvo do bote de rato |
| Arbusto de amoras | Objeto | Margem, atrás do bicho, à direita | 130 | `petisco` vira "come amora". **[F]** A dieta inclui frutas (Forest Park Zoo) |
| Ninho de folhas secas | Objeto | Sob o bicho | 110 | Ela se enrola nele no sono |
| Cachecol de tricô | Roupa (pescoço) | Pescoço | 70 | — |
| Pelagem "graxaim" | Pelagem (nova entrada da paleta) | Corpo: cinza-mesclado com cabeça e orelhas ruivas e marca escura no focinho | Grátis, no marco 25 do Diário | Aceno brasileiro. **[F]** Graxaim-do-campo: cabeça e pescoço avermelhados e marca preta no focinho (Wikipedia) |
| Lanterna de vaga-lume | Objeto (coleção noite) | Pendurada no galho | 190 | À noite ela segue a luz com os olhos |

---

## 4. Bolota — buldogue francês

### 4.1 Biologia e comportamento reais

**Padrão e temperamento**

- **Temperamento.** **[F]** "Cheio de coragem, mas com qualidades de palhaço",
  "vivaz, profundamente afetuoso, inteligente". Orelhas "de morcego", largas na
  base, arredondadas no topo e eretas
  ([Royal Kennel Club](https://www.royalkennelclub.com/breed-standards/utility/french-bulldog)).
- **Focinho e respiração.** **[F]** O mesmo padrão pede focinho "bem definido,
  que se possa ver claramente de perfil", nariz "com narinas visivelmente
  abertas" e diz: "**cães que mostrem dificuldade respiratória ou façam ruído
  respiratório excessivo são inaceitáveis**".
- **Cores.** **[F]** Pelo RKC, as únicas cores corretas são **tigrado, fulvo e
  pied**. Pelo padrão da FCI, publicado pela Dogs NZ, preto e as diluições do
  preto são desqualificantes
  ([Dogs NZ](https://dogsnz.org.nz/breeds/info/french-bulldog/732)).
- **[A] Divergência com o código.** `design/tokens.dart:150-170` diz que a
  paleta do buldogue traz "as cores que o padrão da raça de fato admite" e
  inclui **blue e preto**. Pelos dois padrões consultados, isso não procede.
  **[I]** Para um bicho virtual não há problema em ter blue e preto como
  escolha. O que está errado é o comentário que afirma o padrão.

**Respiração e ronco**

- **[F]** Cães braquicefálicos tiveram muito mais eventos de respiração
  alterada no sono do que cães de focinho longo
  ([Univ. Helsinki, JVIM 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10365046)).
  Ronco, dormir sentado ou de queixo erguido e apneias percebidas aparecem
  como sinais.
- **[I] Consequência de design.** O ronco do Bolota é **um ressonar leve**,
  nunca chiado, engasgo ou dormir sentado com a cabeça para cima.

**Vida, filhotes e água**

- **Expectativa de vida.** **[F]** 4,53 anos ao nascer numa amostra de óbitos
  no Reino Unido (Teng et al. 2022), a menor das raças estudadas. Por isso o E5
  é "pleno" e não "velho" (§1.2).
- **Filhotes (fontes de divulgação, fracas).** Nascem com olhos e ouvidos
  fechados, que abrem por volta das 2 semanas
  ([Rover](https://www.rover.com/uk/blog/puppy-stages/)). As orelhas do
  buldogue francês costumam ficar em pé entre 5 e 15 semanas, às vezes uma
  antes da outra
  ([French Bulldog Owner, guia de tutor](https://frenchbulldogowner.com/when-do-french-bulldogs-ears-stand-up/)).
  **Não achei fonte veterinária** para a idade das orelhas.
- **Nado.** **[F] (fonte fraca, de produto)** Braquicefálicos precisam
  inclinar a cabeça para respirar nadando e têm dificuldade na água
  ([Tractive](https://tractive.com/blog/en/safety/can-my-dog-swim-a-guide-to-swimming-with-dogs)).
  O código já tira o buldogue da água (`pet.dart:126-131`). A cena não tira
  (§1.4).

**Comportamentos**

- **Zoomies.** **[F]** "Frenetic Random Activity Periods": correr em voltas,
  parar e virar de repente, muitas vezes com **reverência de brincadeira**
  (play bow) no meio. Mais comum em cães jovens, e o gatilho pode ser
  excitação, alívio depois do banho ou a noite
  ([AKC](https://www.akc.org/expert-advice/lifestyle/what-are-zoomies/)).
- **Reverência (play bow).** **[F]** Bekoff associa o gesto a manter a
  brincadeira ([Bekoff 1995](https://web-archive.southampton.ac.uk/cogprints.org/158/1/199709003.html)).
  Estudos posteriores não confirmaram a função "metacomunicativa"
  ([resumo de McConnell](https://www.patriciamcconnell.com/theotherendoftheleash/?p=10902)).
  **[I]** Para o app basta o uso popular: "quero brincar".
- **Olhar pidão.** **[F]** O músculo que ergue a parte interna da
  sobrancelha está presente nos cães e não nos lobos. Os cães o usam mais
  diante de humanos
  ([Kaminski et al. 2019, PNAS](https://irep.ntu.ac.uk/id/eprint/41286)).
  **[A]** O `_sobrancelhaDoBuldogue` já usa isso em "sentindo falta"
  (`pet.dart:3257-3277`). É um acerto.
- **Inclinar a cabeça.** **[F]** Cães "aprendizes de palavras" inclinaram a
  cabeça em ~43% das vezes que ouviram o nome de um brinquedo, contra ~2% dos
  cães típicos, e cada cão tende a inclinar sempre para o mesmo lado
  ([ELTE, resumo de Sommese et al.](https://ttkold.elte.hu/en/content/talk-to-tilt-head-tilting-in-dogs.t.5018)).
- **Abanar a cauda.** **[F]** Cães abanaram mais para a direita ao ver o dono
  e mais para a esquerda diante de um cão dominante desconhecido
  ([Quaranta et al. 2007, via Nature](https://www.nature.com/news/2007/070319/full/news070319-6.html)).
  **[I]** O Bolota só tem um toco, que hoje não é desenhado
  (`pet.dart:2595-2598`). O equivalente visível é a **bunda inteira
  rebolando**, para a direita quando a pessoa volta. É um detalhe de fã.

### 4.2 Avaliação do desenho atual

| Aspecto | Observação | Tipo |
|---|---|---|
| Reconhecimento | Excelente: orelha de morcego, máscara, papada e pera invertida estão todos lá (`pet-frenchie-contente.png`, `buldogue-pelagens.png`). É o desenho mais maduro do elenco | [A] |
| Humor pela orelha | Bom: a orelha tomba de 0 a 0,82 conforme o humor (`pet.dart:2643-2653`) e lê de longe (`buldogue-humores.png`) | [A] |
| Saudade e neutro | O olho direito sai "desconfiado" (§1.3). No `pet-frenchie-saudade.png`, os olhos viram fendas quase fechadas, e o conjunto (fenda, sobrancelha e boca para baixo) lê como **mal-humorado ou de ressaca**, e não como saudade. **[I]** Saudade pede olho **aberto** e úmido, voltado para cima e para fora, que é o "olhar pidão" | [A] / [I] |
| Focinho e narinas | Plano total. As narinas são duas vírgulas escuras (`pet-frenchie-radiante.png`). **[F]** O RKC pede focinho visível de perfil e narinas visivelmente abertas. **[I]** Abrir as narinas (oval com interior escuro e borda clara) e dar 2-3 px de projeção ao focinho deixa mais saudável sem perder a raça | [A] / [F] |
| Máscara | No fulvo ela pesa, e o miolo da cara vira uma mancha marrom grande (`pet-frenchie-contente.png`). O próprio código já recuou de 0,55 para 0,45 (`pet.dart:2626-2632`). **[I]** Testar 0,38 com a borda esfumada | [A] / [I] |
| Artefatos | Há um entalhe no topo do crânio (`pet-frenchie-contente.png`, x≈598,y≈258) e um corte reto na base das orelhas (x≈318,y≈378 e x≈876,y≈383) | [A] |
| Língua no radiante | Funciona e é fofa (`pet-frenchie-radiante.png`) | [A] |
| Escala | Ocupa mais área que os outros: x≈270-920, contra x≈360-850 do corpo da gata. Na home domina a cena (`home-frenchie.png`) | [A] |
| Sono | Cochilo inclinado, com a orelha caindo, lê bem (`buldogue-atividades.png`). Mas dorme sentado, o que, para braquicefálico, lembra justamente o sinal de respiração ruim citado no estudo de Helsinki. **[I]** Trocar por esfinge com o queixo nas patas, ou de lado | [A] / [F] / [I] |

### 4.3 Cinco estágios do Bolota

**E1 — Bolota recém-nascido, "na caminha"**
- **Cena.** Caminha redonda baixa (96×30, borda acolchoada em `AppColors.boat`
  ou na cor escolhida) com uma bolsinha de água morna xadrez.
- **Corpo.** "Salsichinha" gorda deitada de barriga, 50×24, quase sem pescoço.
  A cabeça é uma bolha de 36×28.
- **Olhos e orelhas.** Olhos fechados e **orelhas moles, dobradas para a
  frente**, como abas de 10 px, sem nada de morcego ainda. Os filhotes nascem
  com olhos e ouvidos fechados (Rover).
- **Focinho.** Rosado com manchinhas escuras. **[I]** Muitos filhotes têm o
  nariz despigmentado ao nascer. Não achei fonte para a raça, então é
  opcional.
- **Marcação.** A da pelagem escolhida (máscara, pied, tigrado) já aparece, só
  que mais clara.
- **Escala.** 0,45.

**E2 — Bolota filhote, "uma orelha em pé"**
- **Pose.** Sentado e desabado, com a barriga redonda à mostra.
- **Proporções.** Cabeça 74×60 sobre corpo de 52×46. Patas grandes e as
  dianteiras afastadas.
- **Orelhas.** **Uma em pé e a outra dobrada.** As orelhas sobem entre 5 e 15
  semanas, às vezes uma antes da outra (guia de tutor, fonte fraca). **[I]** É
  o traço mais fofo e reconhecível desta fase.
- **Rugas.** Mais fundas na testa (+30% na `forca` de `_dobraDaPele`). Olhos
  grandes, r = 10.
- **Escala.** 0,6.

**E3 — Bolota jovem, "orelhas de radar"**
- **Orelhas.** As duas de morcego eretas, **grandes demais** para a cabeça:
  altura de 52, contra 46 no adulto.
- **Corpo e pernas.** O corpo alonga (sem a pera completa ainda) e as pernas
  ficam mais finas que no adulto.
- **Acessório.** Mordedor ou bolinha sempre perto.
- **Escala.** 0,8.

**E4 — Bolota adulto (o atual, corrigido)**
- **Correções.** O desenho atual, com o §1.3 corrigido, narinas abertas,
  focinho com 2-3 px de projeção, máscara mais leve, artefatos removidos e a
  saudade de olho aberto.
- **Escala.** 1,0.

**E5 — Bolota pleno, "o veterano do sofá"**
- **Pelagem.** **Focinho e sobrancelhas grisalhos**: pelos claros salpicados
  na focinheira e um arco claro sobre cada olho. Em cães, o grisalho aparece
  mais na face (Oradell).
- **Postura.** Mais baixo e largo (+4%). O ocioso padrão vira deitado de
  esfinge.
- **Acessório.** Ganha o "Cobertor do veterano".
- **Proibido.** Olho opaco, magreza e respiração difícil.
- **Escala.** 1,0.

**Cenas de transição**

| De → para | Cena | Base real |
|---|---|---|
| E1 → E2 | **"Primeiros passos."** Ele abre os olhos, tenta sair da caminha, rola para fora e senta. Uma orelha sobe, "plim" | Olhos abrem por volta de 2 semanas (Rover) |
| E2 → E3 | **"A outra orelha."** Ele se coça, sacode a cabeça (o gesto `sacode` existente) e a segunda orelha sobe | Orelhas sobem entre 5 e 15 semanas (guia de tutor) |
| E3 → E4 | **"Primeiro zoomie."** Reverência, duas voltas pela cena com derrapada e "plof" sentado de frente para a pessoa, com a língua de fora | Zoomies com play bow (AKC) |
| E4 → E5 | **"O sofá é dele."** Ele sobe na caminha nova, dá três voltas, solta um suspiro e deita de esfinge | [I] |

### 4.4 Personalidade, humores e animações

**Traço.** **[A]** O texto atual: "Ronco, sofá e presença. Você trabalha melhor
ao lado de alguém" (`l10n.dart:863-866`), e a escolha dele como prêmio de "50
sessões acompanhadas" (`progressao.dart:436-449`). **[F]** "Palhaço corajoso",
"profundamente afetuoso" (RKC). **[I]** A personalidade do Bolota é a
**presença**: ele não faz nada de especial, só fica perto, e a assinatura dele
deve ser *estar* na sessão. Ele é o único que, durante o foco, deita encostado
na borda da tela "esperando".

**Humores no buldogue** (já existe boa parte: orelha, sobrancelha, língua)

| Humor | Orelhas | Toco e quadril | Olhos e sobrancelha | Corpo e boca | Som |
|---|---|---|---|---|---|
| Radiante | Eretas (0) | **Quadril rebolando** para a direita | Abertos, sobrancelha alta | Língua de fora (já existe), patinhas sapateando | Um "bufinho" feliz e um "auu" curto de conversa |
| Contente | 0,05 | Rebola leve | Abertos | Dentinhos (já existe) | Fungada curta |
| Neutro | 0,18 | Parado | Abertos, com a pálpebra **espelhada** (§1.3) | Sentado | Nenhum |
| Sonolento | 0,58 | Parado | Fechando | Esfinge, com o queixo nas patas | **Ressonar leve** |
| Sentindo falta | 0,82 ("orelha de avião") | Parado | **Abertos**, sobrancelha interna erguida (Kaminski 2019), sem fenda | Cabeça inclinada (já existe, `pet.dart:2680-2683`), olhando para a borda | Um gemidinho curto e único |

**Animações de assinatura**

1. **Zoomie.** Só no radiante e no máximo 1 vez por abertura de app. Começa
   com uma reverência (peito baixo e quadril alto, 0,4 s), seguem duas voltas
   em oito pela cena com rastro de poeira, uma derrapada, e termina sentado.
   **[F]** AKC.
2. **Inclinar a cabeça.** Ao tocar no bicho com o app falando (uma
   notificação lida, um marco), ou quando a pessoa digita o nome dele, a
   cabeça inclina 12° **sempre para o mesmo lado**, sorteado uma vez por conta.
   **[F]** Sommese et al., via ELTE.
3. **Olhar pidão.** Quando a pessoa abre a loja ou o petisco, a sobrancelha
   interna sobe e a pupila aumenta. **[F]** Kaminski 2019.
4. **Rebolado de toco.** Ao reabrir o app depois de mais de 1 hora, o quadril
   rebola 4 vezes para a direita. **[F]** Quaranta 2007.
5. **Ressonar e suspiro.** No cochilo, o peito sobe e desce, com um ressonar
   baixo a cada 4-5 ciclos e um suspiro longo ao acordar. **[I]** O suspiro é
   comportamento comum e não busquei fonte.

### 4.5 Jornada do Bolota

**Diário do Bolota** (em sessões com o buldogue):

| Marco | Critério | Entrega |
|---|---|---|
| A caminha | Desbloquear no passo 20 | E1 |
| Primeiros passos | 1 sessão | E2 |
| A outra orelha | 5 sessões | E3 e o mordedor |
| Fiel escudeiro | 10 sessões | Durante o foco, ele deita na borda da tela de sessão "fazendo companhia" |
| Primeiro zoomie | 15 sessões | E4 e o gesto zoomie |
| Passeio | 25 sessões | Cenário próprio "Pracinha" (gramado, banco e poste) ao amanhecer |
| Quintal | 35 sessões | Uma bolinha fixa na cena e a reverência ao tocar nela |
| O sofá é dele | 45 sessões | E5 e o "Cobertor do veterano" |

- **[I] O marco 10.** Ele é a tradução direta da justificativa de produto do
  buldogue (prêmio de "sessões acompanhadas", `progressao.dart:447-449`).
  Aparecer **dentro da sessão de foco** é o que nenhuma outra espécie faz.
- **[I] Prenúncio.** No passo 19, uma bolinha de tênis rola sozinha pela cena,
  uma vez por dia.

**Sons e voz** (ElevenLabs, Sound Effects)

| Uso | Prompt (EN) | Duração |
|---|---|---|
| Sono | "Small dog gentle soft snore, light and cute, slow rhythmic breathing, no wheezing, no rasp, close mic" | 3 s, em loop |
| Radiante | "French bulldog happy short 'woo' talking sound, playful grumble, cute, single" | 0,7 s |
| Afago | "Small dog contented sigh and soft snuffle, relaxed, intimate" | 1 s |
| Saudade, ao voltar | "One short soft puppy whimper turning into a happy snort, quiet" | 0,8 s |
| E1 | "Tiny newborn puppy squeak, faint, soft, single" | 0,3 s |
| E2 | "Puppy small yip and snort, cute, short" | 0,4 s |
| Zoomie | "Small dog paws scrabbling and skidding on grass, fast patter then a soft thud" | 1,5 s |
| Transição | "Playful little snort followed by a bright soft chime" | 2 s |

**[I]** Revisar todo áudio de ronco contra o critério do RKC: nada que soe como
dificuldade de respirar.

### 4.6 Itens temáticos do Bolota

| Item (pt-BR) | Categoria | Onde | Preço | Gatilho |
|---|---|---|---|---|
| Caminha redonda | Objeto (chão do bicho) | Sob o Bolota, na margem (resolve o §1.4) | 150 | Três voltas antes de deitar |
| Bolinha de tênis | Objeto | Areia, à direita | 60 | Zoomie ao tocar |
| Tigela com nome | Objeto | Margem esquerda | 90 | `petisco` come da tigela, com o nome do pet gravado (até 18 caracteres) |
| Mordedor de corda | Objeto | Ao lado da caminha | 80 | Cabo de guerra com o dedo (arrastar) |
| Bandana | Roupa (pescoço) | Pescoço, triângulo sobre o peito | 60 | — |
| Capa de chuva amarela | Roupa (**corpo**, slot novo) | Tronco | 160 | Combina com o cenário "chuva" |
| Tapete gelado | Objeto | Sob o bicho, nos horários de dia | 120 | Deita de barriga no calor. **[I]** Cuidado com o calor de braquicefálico; o RKC fala de respiração, não achei fonte específica de calor |

**[A]/[I]** A capa de chuva exige um `Vestimenta.corpo` novo, e hoje só há
`cabeca`, `pescoco` e `rosto` (`models.dart:182`). Esforço M, porque cada uma
das 9 espécies precisa de uma silhueta de tronco.

---

## 5. Recomendações

Formato: **o quê**, **por quê**, **como**, **esforço** (P/M/G),
**impacto** e **critério de aceite**.

### R1. Espelhar a pálpebra e a sobrancelha de `_olho`

- **O quê.** Passar o lado (`lado: -1 | 1`) para `_olho` e espelhar os x da
  pálpebra (`pet.dart:3605-3616`) e da sobrancelha (`3618-3624`).
- **Por quê.** Hoje um olho sai "triste" e o outro "bravo" em neutro e saudade,
  nas 9 espécies (§1.3).
- **Como.** Multiplicar os `dx` por `lado` e ajustar as 18 chamadas de `_olho`.
- **Esforço.** P.
- **Impacto.** Alto: o humor mais sensível passa a ler como saudade, e não
  como raiva.
- **Aceite.** Um teste de *golden* por espécie em saudade e neutro em que a
  metade esquerda da cara é o espelho da direita (diferença de pixels < 1%
  depois do flip horizontal, descontando a cauda).

### R2. Estágios de crescimento por bicho

- **O quê.** 5 estágios por espécie, contados em "sessões juntos" (§1.2).
- **Por quê.** É o pedido 6 do dono. As três espécies chegam depois do passo
  18, então a trilha não pode servir de régua.
- **Como.** `Map<Species,int> sessoesJuntos` em `AppState`, incrementado em
  `_concluiSessao` (`state.dart:1897`) para a espécie ativa. Os limiares (1, 5, 15, 45) ficam em
  `progressao.dart` (classe `Balanco`). `ProporcoesDoEstagio` vai para o
  painter. Álbum no `CompanionCard` (`pet_profile.dart:195`) para escolher o
  estágio exibido.
- **Esforço.** G.
- **Impacto.** Alto: cria "por que eu volto" depois da trilha.
- **Aceite.** (a) Com 0, 1, 5, 15 e 45 sessões, o `PetView` de cada espécie
  produz 5 *goldens* distintos. (b) Trocar de espécie e voltar preserva o
  estágio. (c) Nenhum caminho de código reduz `sessoesJuntos`. (d) O estágio
  exibido pode ser qualquer um já alcançado.

### R3. Cerimônia de adoção no passo 18, 20 ou 22

- **O quê.** Ao conquistar o marco que entrega a espécie, mostrar a cena "o
  cesto, a toca ou a caminha chegou" com o E1, em vez de só liberar a espécie
  no seletor.
- **Por quê.** É o "ovo" do pedido e dá corpo a uma recompensa que hoje é um
  chip destravado (`pet_profile.dart:165-174`).
- **Como.** Reaproveitar `celebracao.dart`, adicionando um passo "conhecer" com
  os botões "Adotar agora" e "Depois". O "Depois" não perde nada.
- **Esforço.** M.
- **Impacto.** Alto.
- **Aceite.** O marco com `especie != null` abre a cena. "Depois" mantém a
  espécie liberada nos ajustes.

### R4. Orelhas e cauda por humor na gata e na raposa

- **O quê.** Criar `_orelhaPorHumor` e `_caudaPorHumor`, nos moldes de
  `_orelhaTomba` (`pet.dart:2643-2653`), com as tabelas dos §2.4 e §3.4.
- **Por quê.** A orelha é o sinal felino mais preditivo (Deputte 2021) e a
  cauda erguida é o cumprimento ao humano. Hoje radiante e contente só diferem
  por brilho.
- **Como.** Para a gata: ângulo da orelha de 0 a 0,5 rad para os lados (nunca
  para trás) e cauda com 4 poses interpoladas. Para a raposa: o mesmo, mais a
  cauda sobre o nariz no sono.
- **Esforço.** M.
- **Impacto.** Alto em clareza de humor.
- **Aceite.** Num teste com 5 pessoas que veem as 5 artes de humor sem
  legenda, pelo menos 4 acertam radiante, sonolento e sentindo falta em cada
  espécie.

### R5. Redesenho da raposa adulta

- **O quê.** Os brancos (bochecha, queixo, peito, ponta da cauda), a cauda na
  cor do pelo, as meias escuras, o focinho em V, o olho âmbar e o fim do corte
  na base da orelha (§3.2, §3.3 E4).
- **Por quê.** Hoje ela lê como panda-vermelho ou esquilo.
- **Como.** Em `_raposa`, trocar `claro` por `Cores.superficie` nas áreas
  brancas e fechar a base da orelha dentro do contorno da cabeça.
- **Esforço.** M.
- **Impacto.** Alto: é o bicho-prêmio final da trilha.
- **Aceite.** Num teste de 5 segundos com 5 pessoas, 4 dizem "raposa" sem
  pista.

### R6. Gata: cauda, orelha e marca tabby

- **O quê.** Cauda tubular na cor do pelo com anéis, orelha de ponta fina e o
  "M" na testa (§2.3 E4).
- **Por quê.** A cunha marrom lê como castor e a orelha redonda lê como urso.
- **Como.** Reescrever o `Path` da cauda (`pet.dart:2298-2310`) como traço
  grosso (`strokeWidth` 9, ponta redonda) na cor `pelo`.
- **Esforço.** P.
- **Impacto.** Médio.
- **Aceite.** O *golden* atualizado; a cauda não usa `sombraForte` como
  preenchimento.

### R7. Pose de sono por espécie

- **O quê.** Gata em rosquinha, raposa com a cauda sobre o nariz, buldogue em
  esfinge com o queixo nas patas.
- **Por quê.** Hoje os três dormem sentados. Para o buldogue, dormir sentado
  evoca o sinal de respiração ruim (Helsinki 2023).
- **Como.** Desenhar a pose em função própria quando `acao ==
  AcaoDoBicho.cochilo`.
- **Esforço.** M.
- **Impacto.** Médio-alto: "sonolento" vira inconfundível.
- **Aceite.** Os *goldens* de cochilo mostram o corpo deitado: a altura do
  bounding box cai pelo menos 30% em relação ao ocioso.

### R8. Chão para quem não nada

- **O quê.** Gata, raposa e buldogue ficam sobre a margem ou sobre o item
  próprio (almofada, toca, caminha), e não sobre a água.
- **Por quê.** É a contradição do §1.4.
- **Como.** `_alturaDoPet` (`habitat.dart`) passa a depender da espécie, com
  um apoio padrão (pedra chata) quando não há item.
- **Esforço.** M.
- **Impacto.** Médio.
- **Aceite.** Na captura `home-{cat,fox,frenchie}.png`, as patas ficam acima
  da linha d'água (`PetView.linhaDaguaEm`).

### R9. Repertório ocioso por espécie

- **O quê.** O `GestoOcioso` passa a ser escolhido de um repertório por
  espécie: as 4 ou 5 assinaturas dos §2.4, §3.4 e §4.4.
- **Por quê.** O pedido 4 do briefing: animações extremamente limitadas. Os
  gestos atuais são os mesmos para as 9 espécies (`pet.dart:554-561`).
- **Como.** `Map<Species, List<GestoOcioso>>`, com os gestos novos no enum.
- **Esforço.** M por espécie.
- **Impacto.** Alto em "parece vivo".
- **Aceite.** Em 3 minutos de ocioso registrados, cada espécie mostra pelo
  menos 3 gestos exclusivos.

### R10. Sons por espécie

- **O quê.** Gerar os sons das tabelas §2.5, §3.5 e §4.5 e mapear no
  `som_service`.
- **Por quê.** O pedido 3 do briefing. Hoje há 7 sons genéricos
  (`assets/sons/`).
- **Como.** ElevenLabs Sound Effects, 2 variações por evento, normalizadas.
- **Esforço.** M.
- **Impacto.** Médio-alto.
- **Aceite.** Cada espécie tem ≥ 5 eventos com som próprio. Nenhum supera o
  pico dos sons atuais. Nenhum som de ronco tem chiado (revisão manual).

### R11. Diário do bicho

- **O quê.** A mini-trilha por espécie dos §2.5, §3.5 e §4.5, que contém os
  estágios da R2.
- **Por quê.** É o primeiro conteúdo pós-trilha (relatório anterior, §5) e o
  pedido de "jornada dedicada com visuais dedicados".
- **Como.** Reaproveitar `Marco` e `ProgressoDaTrilha` com um novo
  `TipoDeMarco.sessoesJuntos`. A tela usa o mesmo componente da trilha.
- **Esforço.** G.
- **Impacto.** Alto.
- **Aceite.** Os 8 marcos de cada Diário são exibidos com prévia. Nenhum
  depende de compra. O resgate é idempotente, como na trilha.

### R12. Itens temáticos com filtro por espécie

- **O quê.** 7 itens por espécie (§2.6, §3.6, §4.6), com um campo `especie`
  opcional em `ShopItemDef`.
- **Por quê.** A loja é igual para todos, e o bicho não interage com nada.
- **Como.** Nomes em `l10n_loja.dart` nos 4 idiomas, com `TODO-i18n` onde
  houver incerteza, e entrada **no fim** do catálogo (`models.dart:238-250`).
  O gatilho de animação fica no painter.
- **Esforço.** M.
- **Impacto.** Médio.
- **Aceite.** Os itens de outra espécie aparecem com o rótulo "da Mel" (ou da
  espécie dona), e não somem. Comprar um item da espécie ativa dispara o
  gatilho descrito.

### R13. Buldogue mais saudável e honesto

- **O quê.** Narinas abertas, focinho com 2-3 px de projeção, ronco leve,
  saudade de olho aberto e a correção do comentário de `tokens.dart:150-170`.
- **Por quê.** O padrão do RKC (§4.1) e a leitura atual de "mal-humorado".
- **Como.** Em `_focinhoDoBuldogue` e `_olho` (com a R1).
- **Esforço.** P.
- **Impacto.** Médio, e reduz risco de imagem.
- **Aceite.** Os *goldens* mostram as narinas com interior escuro e borda
  clara. O comentário não afirma mais que o padrão admite blue e preto.

### R14. Prenúncio antes do desbloqueio

- **O quê.** Pegadas no passo 17, bolinha rolando no 19 e orelhas no capim no
  21.
- **Por quê.** Antecipação (o R24 do relatório anterior). Hoje a espécie
  travada é só um cadeado (`pet_profile.dart:271-302`).
- **Como.** Um evento visual por dia no habitat, a partir do passo anterior.
- **Esforço.** P.
- **Impacto.** Médio.
- **Aceite.** Com o passo N-1 atual, o evento aparece no máximo 1 vez por dia
  e nunca durante a sessão.

---

## 6. As 10 recomendações mais importantes, em ordem de prioridade

1. **R1:** espelhar pálpebra e sobrancelha (P, corrige as 9 espécies).
2. **R2:** estágios de crescimento por bicho, contados em sessões juntos (G).
3. **R5:** redesenho da raposa adulta (M).
4. **R4:** orelha e cauda por humor na gata e na raposa (M).
5. **R3:** cerimônia de adoção com E1 no ninho (M).
6. **R11:** Diário do bicho, o conteúdo pós-trilha (G).
7. **R7:** pose de sono por espécie (M).
8. **R8:** chão para quem não nada (M).
9. **R9 e R10:** repertório ocioso e sons por espécie (M + M).
10. **R13:** buldogue com narinas abertas, ronco leve e saudade de olho aberto
    (P).

R6, R12 e R14 vêm logo depois e são baratos.

## 7. O que não fazer

- **Não** fazer do E5 uma velhice com fragilidade (bengala, olho opaco,
  magreza, tremor). Isso fere o "nunca morre" no espírito, sobretudo no
  buldogue (Teng 2022).
- **Não** fazer o crescimento regredir, nem "pausar por inatividade" de forma
  visível. A pausa só existe ao trocar de espécie, e nunca é mostrada como
  perda.
- **Não** vender estágio, aceleração de crescimento nem espécie por dinheiro.
  Itens só por folhas.
- **Não** usar chiado ou engasgo como "ronco fofo" nem colocar o buldogue
  nadando (RKC; Helsinki 2023).
- **Não** usar o grito da raposa nem o hiss da gata. São sons de ameaça e
  ficam fora do tom.
- **Não** fazer o filhote em saudade chorar em loop. Um som único e suave
  quando a pessoa volta, sempre como alegria, e não como cobrança.
- **Não** achatar as orelhas da gata ou da raposa **para trás** em saudade.
  Para trás é medo ou agressão (Deputte 2021; Wildlife Online). Use "para os
  lados".
- **Não** trocar a raposa-vermelha pelo graxaim como espécie. O graxaim entra
  como pelagem.
- **Não** criar estágio só na tela principal: a sobreposição (§1.6) e o ícone
  de app precisam acompanhar, senão a divergência piora.
- **Não** inserir itens novos no meio do catálogo, porque isso renomeia
  compras (`models.dart:238-245`).

## 8. Riscos e dúvidas em aberto

- **Calibração dos limiares (1, 5, 15, 45).** São inferência a partir da
  estimativa de 2 sessões por dia do código. Precisam de dados reais de
  sessões por dia depois do passo 18.
- **Contas antigas.** Quem já usa a gata, a raposa ou o buldogue hoje começa
  do zero? **[I]** A sugestão é um piso de migração: quem já tem a espécie
  ativa entra no E4 com o álbum E1-E3 liberado. Assim nada se perde, e o
  `entregues` de `progressao.dart:493-506` é o precedente.
- **Custo de arte.** São 3 espécies × 5 estágios × 5 humores × 7 ações. Os E1
  e E2 deitados reduzem a matriz (no ninho só há sono, ocioso e afago), mas o
  teste de *golden* vai crescer muito.
- **Sobreposição nativa.** Sem a unificação do §1.6, os estágios aumentam a
  divergência. É uma dependência de outro laudo.
- **Fontes fracas.** A idade das orelhas do buldogue (guia de tutor), o nado
  de braquicefálico (Tractive), a abertura dos olhos de cão (Rover) e as
  "meias" pretas da raposa não têm fonte veterinária ou acadêmica. Não achei
  fonte primária para zoomies em gatos nem uma ficha de zoológico grande para a
  raposa-vermelha.
- **Padrão de cores do buldogue.** Manter blue e preto é decisão de produto
  (são populares), mas o texto do código não deve afirmar que o padrão as
  admite.
- **Termos e cultura.** "Graxaim" é regional (Sul). Nos outros idiomas, a
  pelagem pode se chamar "pampas" ("Pampas fox"). A tradução para zh precisa
  de revisão (`TODO-i18n`).
- **Regras do contrato.** Nenhuma recomendação muda regra. A R12 com
  `Vestimenta.corpo` muda o catálogo e as 9 silhuetas, mas não o contrato.

---

## Fontes

**Gata**
- AAHA/AAFP 2021, Feline Life Stage Guidelines: <https://www.aaha.org/resources/2021-aaha-aafp-feline-life-stage-guidelines/feline-life-stage-definitions/>
- Alley Cat Allies, Kitten Progression: <https://alleycat.org/KittenProgression>
- Agria, quando os filhotes abrem os olhos: <https://agriapet.co.uk/guides-and-advice/when-do-kittens-open-their-eyes>
- AAHA, desenvolvimento comportamental felino: <https://www.aaha.org/resources/2015-aaha-canine-and-feline-behavior-management-guidelines/behavioral-developments-in-cats/>
- Humphrey et al. 2020, piscada lenta (Scientific Reports): <https://pmc.ncbi.nlm.nih.gov/articles/PMC7536207/>
- Deputte et al. 2021, sinais visuais em gatos (Animals): <https://pmc.ncbi.nlm.nih.gov/articles/PMC8469685/>
- Herbst et al. 2023, ronronar (Current Biology, cópia aberta): <https://phaidra.vetmeduni.ac.at/o:3419>
- Nicastro & Owren 2003, miado: <https://Gwern.net/doc/cat/psychology/2003-nicastro.pdf>
- Live Science, amassar pãozinho (citando a iCatCare): <https://www.livescience.com/animals/cats/why-do-cats-knead>
- The Conversation, Susan Hazel: <https://theconversation.com/why-do-cats-knead-192743>
- Vinke et al. 2014, caixa de esconderijo: <https://research-portal.uu.nl/en/publications/will-a-hiding-box-provide-stress-reduction-for-shelter-cats/>
- Hill's, sinais de envelhecimento felino: <https://hillspet.com/cat-care/behavior-appearance/cat-aging-signs>

**Raposa**
- Wildlife Online, crescimento dos filhotes: <https://www.wildlifeonline.me.uk/animals/article/red-fox-breeding-growth-development-of-cubs>
- Wildlife Online, comunicação: <https://wildlifeonline.me.uk/animals/article/red-fox-behaviour-communication>
- Wildlife Online, esconder comida: <https://www.wildlifeonline.me.uk/questions/answer/are-there-exceptions-to-the-foxes-scatter-cache-rule>
- Newton-Fisher et al. 1993, vocalizações (Bioacoustics): <https://bioacoustics.info/article/structure-and-function-red-fox-vulpes-vulpes-vocalisations>
- National Park Service, Isle Royale, red fox: <https://www.nps.gov/isro/learn/nature/red-fox.htm>
- Červený et al. 2011, bote (via phys.org): <https://phys.org/news/2011-01-predation-foxes-aided-earth-magnetic.html>
- Smithsonian, vídeo do bote na neve: <https://www.si.edu/object/red-fox-hilariously-pounces-headfirst-snow%3Ayt_RCqQYpM1hCA>
- Forest Park Zoo, red fox: <https://forestparkzoo.org/animals/red-fox>
- ICMBio, avaliação do graxaim-do-campo: <https://revistaeletronica.icmbio.gov.br/BioBR/article/download/383/290/1554>
- Univates, *C. thous* e *L. gymnocercus* no RS: <https://univates.br/revistas/index.php/destaques/article/view/3326>
- Wikipedia, Pampas fox: <https://en.wikipedia.org/wiki/Pampas_fox>

**Buldogue francês**
- Royal Kennel Club, padrão da raça: <https://www.royalkennelclub.com/breed-standards/utility/french-bulldog>
- Dogs NZ (padrão FCI): <https://dogsnz.org.nz/breeds/info/french-bulldog/732>
- AKC, French Bulldog: <https://www.akc.org/dog-breeds/french-bulldog/>
- Teng et al. 2022, tábuas de vida (Scientific Reports): <https://rvc-repository.worktribe.com/output/1550511/life-tables-of-annual-life-expectancy-and-mortality-for-companion-dogs-in-the-united-kingdom>
- Univ. Helsinki 2023, respiração no sono de braquicefálicos (JVIM): <https://pmc.ncbi.nlm.nih.gov/articles/PMC10365046>
- AKC, zoomies: <https://www.akc.org/expert-advice/lifestyle/what-are-zoomies/>
- Bekoff 1995, play bow: <https://web-archive.southampton.ac.uk/cogprints.org/158/1/199709003.html>
- McConnell, revisão do play bow: <https://www.patriciamcconnell.com/theotherendoftheleash/?p=10902>
- Kaminski et al. 2019, sobrancelha (PNAS): <https://irep.ntu.ac.uk/id/eprint/41286>
- ELTE, inclinar a cabeça (Sommese et al.): <https://ttkold.elte.hu/en/content/talk-to-tilt-head-tilting-in-dogs.t.5018>
- Nature News, Quaranta et al. 2007: <https://www.nature.com/news/2007/070319/full/news070319-6.html>
- Oradell Animal Hospital, envelhecimento: <https://www.oradell.com/services/blog/aging-changes-dogs-and-cats>
- Fontes fracas, assinaladas no texto:
  - Rover, fases do filhote: <https://www.rover.com/uk/blog/puppy-stages/>
  - French Bulldog Owner, orelhas: <https://frenchbulldogowner.com/when-do-french-bulldogs-ears-stand-up/>
  - Tractive, nado: <https://tractive.com/blog/en/safety/can-my-dog-swim-a-guide-to-swimming-with-dogs>

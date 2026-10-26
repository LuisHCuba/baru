# Laudo 03 — Visual, estética e elementos gráficos

Baru, outubro de 2026. Escopo: auditoria visual do app como ele está hoje,
pesquisa de referência, sistema de emoções dos bichos e uma direção de arte
unificada, com plano de execução em Flutter.

**Legenda usada em todo o laudo**

- **[Fonte]** — fato com fonte externa, link na própria linha ou na seção 9.
- **[App]** — observação do app, com arquivo:linha ou imagem.
- **[Opinião]** — inferência ou julgamento de direção de arte. É minha leitura,
  não é fato.

**O que foi olhado (com a ferramenta Read, imagem por imagem):** as 10 capturas
`play-store/telas/pt/01..10`, as 36 homes por espécie e horário (em folhas de
contato), os 36 retratos `play-store/arte/pet-*.png` (9 espécies × 4 humores),
`docs/evidence/2026-08-28/{elenco-nove, buldogue-humores,
descanso-quatro-estados, fala-contente-acima, missoes-para-colher}.png`,
`docs/evidence/2026-08-27/{reacao-1..7, pet-graze/nap/idle/swim,
celebracao-nivel, habitat-*, habitat-trilha-*, raiz-crescendo, cartao-da-raiz,
trilha-andamento, onboarding-revelacao, tempo-vazio, tela-sobreposicao}.png`.
Código lido: `lib/design/tokens.dart`, `lib/theme.dart`,
`lib/widgets/componentes.dart`, `lib/widgets/common.dart`,
`lib/widgets/app_icons.dart`, trechos de `lib/widgets/pet.dart`,
`lib/screens/result_screen.dart`, `lib/widgets/celebracao.dart`, contagens em
`lib/**`. Contrastes calculados com a fórmula de luminância relativa do WCAG
2.x (script próprio; valores na seção 1.5).

**Limite da pesquisa:** a cota de buscas na web acabou no fim da coleta. O que
não achei está dito como "não achei" no ponto em que aparece.

---

## Sumário executivo

1. **O problema central não é falta de capricho num elemento; é ausência de um
   sistema.** Hoje convivem quatro linguagens: (a) bichos em formas chapadas
   sem contorno, (b) cenário em retângulos arredondados quase abstratos,
   (c) 73 ícones Material genéricos diferentes, espalhados por 24 arquivos, e (d) cartões
   de app de produtividade em quatro tintas diferentes. Cada uma é razoável
   sozinha. Juntas, parecem de quatro produtos diferentes. É isso que o dono
   chama de "desconexo".
2. **O elemento mais importante, o rosto do bicho, comunica errado.** O olho
   com esclera branca em anel dá cara de susto ou de "olho de boneco" em todos
   os humores. Radiante e contente são quase idênticos. "Sentindo falta" lê
   como **irritado e desconfiado**, porque a pálpebra e a sobrancelha de
   tristeza não são espelhadas entre os dois olhos (`pet.dart:3605-3624`).
   Para um produto cuja regra nº 1 é "nunca culpa", um bicho de cara feia
   para quem desistiu (`result_screen.dart:27`) é o pior erro visual do app.
3. **A moeda tem quatro desenhos e três cores.** A folha é uma gota verde na
   home, uma gota cor de ferrugem nas missões, um `Icons.eco` (folha com
   nervura) na loja e na tela de folhas, e uma gota laranja no fim de sessão.
   A raiz (streak) é laranja no app e verde no cartão de compartilhar.
4. **A paleta reprova acessibilidade em pontos-chave.** Texto creme no botão
   verde dá 3,6:1; texto claro nos chips laranja ("Resgatar", "A principal de
   hoje") dá 2,3–2,6:1; rótulos de seção em tinta 42% dão ~2,4:1. O mínimo do
   WCAG para texto comum é 4,5:1.
5. **O cenário não acompanha a ambição do bicho.** Os seis habitats da trilha
   diferem quase só pela cor da água; os itens da loja são pílulas e
   retângulos; o bicho fica do tamanho de uma árvore e "flutua" sem sombra de
   contato.
6. **A direção proposta:** "bichos de feltro sob luz de fim de tarde" — formas
   redondas, sem contorno preto, duas tonalidades por material com luz sempre
   vinda de cima-esquerda, sombra de contato em pílula, olho escuro sólido com
   brilho, iconografia própria em traço arredondado com preenchimento
   (duotom), botões 3D com "lábio", e uma paleta semântica fixa (verde =
   folha/ação, terracota = raiz, mel = conquista/XP, céu = congelamento). O
   bicho migra para Rive (um arquivo `.riv` por espécie com máquina de
   estados), o que também resolve o pet genérico da sobreposição nativa,
   porque o Rive tem runtime Android nativo.

---

## 1. Auditoria do estado atual

### 1.1 Os bichos

| # | Problema | Evidência | Por que parece amador |
|---|---|---|---|
| B1 | **Todos os nove são o mesmo boneco com outra cor.** Corpo em pera, barriga oval mais clara, pés em feijão, cabeça em círculo ou retângulo arredondado. Capivara e lontra só se distinguem pela cauda e pelo bigode. | `docs/evidence/2026-08-28/elenco-nove.png`; `play-store/arte/pet-capybara-*.png` × `pet-otter-*.png` | **[Opinião]** A silhueta é o primeiro canal de reconhecimento de personagem. O Duolingo exige personagens "clearly silhouetted" **[Fonte: Barker 2020]**. Aqui, preenchidas de preto, capivara, lontra, gata e raposa viram a mesma pera com orelhas. |
| B2 | **Nível de detalhe desigual entre espécies.** Coruja tem escamas de pena e disco facial, buldogue tem rugas, gata tem listras e bigode, gata e raposa têm orelhas internas em dois tons; capivara e axolote são formas quase lisas. | `elenco-nove.png` | Detalhe desigual faz parecer que cada bicho foi desenhado por uma pessoa diferente, em épocas diferentes. |
| B3 | **A cabeça da capivara é um "bloco".** Retângulo arredondado com o topo reto e levemente inclinado; lê como caixa, não como crânio. | `pet-capybara-contente.png`; recorte em zoom (topo sobe ~2 px da esquerda para a direita) | **[Opinião]** A capivara é o personagem-título e a espécie de ícone; ela é a que mais precisa de construção cuidada. |
| B4 | **O olho é um "olho de boneco".** Disco creme + pupila escura deslocada para cima-esquerda + dois brilhos, em todos os humores e todas as espécies. Com o anel claro, o olhar parece de susto ou de lado. | `pet.dart:3577-3603`; qualquer `pet-*-contente.png` | O anel de esclera grande é o que mais aproxima o bicho de clip-art. Ele também briga com as pálpebras: não há onde "apertar" o olho de alegria. |
| B5 | **Radiante e contente quase não diferem.** Mesmos olhos; o radiante só ganha bochecha rosada, um sorriso 25% maior e quatro brilhos laranja ao redor. | `/play-store/arte/pet-capybara-radiante.png` vs `-contente.png` (comparados lado a lado em zoom) | Uma pessoa que olha a home não percebe que "subiu" de humor; a recompensa emocional some. |
| B6 | **"Sentindo falta" lê como raiva ou desconfiança.** A pálpebra caída e a sobrancelha de tristeza são desenhadas com o **mesmo** vetor nos dois olhos (`moveTo(-x)…lineTo(+x)` sem espelhar por lado). Resultado: no olho esquerdo a sobrancelha desce para o centro (sinal de raiva), no direito sobe (tristeza); as duas pálpebras inclinam para o mesmo lado (olhar enviesado). | `pet.dart:3605-3624`; recorte `pet-fox/capybara/cat-saudade.png` | Ver 3.1: a sobrancelha que desce para o centro sem erguer a ponta interna é o sinal de raiva da FACS. Num app "sem culpa", o bicho parece bravo com a pessoa. |
| B7 | **O buldogue em "neutro" e "sentindo falta" parece emburrado.** Olho fechado em fenda com sobrancelha baixa. | `docs/evidence/2026-08-28/buldogue-humores.png` | Mesmo problema do B6, agravado pela máscara escura do focinho. |
| B8 | **A lágrima é quase invisível.** Gota cinza-azulada clara sobre pelo médio. | `pet-capybara-saudade.png`, `pet-otter-saudade.png` | O sinal mais claro de tristeza (e o menos acusatório) está apagado; o que sobra é a sobrancelha "brava". |
| B9 | **O humor triste escurece o pelo em 14%.** | `pet.dart:1157-1164` | **[Opinião]** Escurecer o bicho quando a pessoa some é um sinal de "ele adoeceu por sua causa". Fere o espírito da regra 1 do PRODUCT.md, mesmo sem perda real. |
| B10 | **Folha solta na barriga em "sono".** Uma folhinha verde aparece sobre o corpo em todos os retratos de sono. | `pet-*-sono.png` | Sem contexto (não há chão, nem árvore), parece sujeira ou erro de camada. |
| B11 | **O bicho não toca o chão nem a água.** Na home, gata, raposa e buldogue ficam de pé **sobre** a lâmina d'água; capivara e axolote afundam atrás de uma faixa translúcida que deixa o corpo cor de oliva-lama. Não há sombra de contato. | `play-store/telas/pt/home-cat.png`, `home-fox.png`, `home-axolotl.png`, `01-home.png` | Sem contato, o personagem vira adesivo colado na cena. O próprio código já admite isso num comentário (`pet.dart`, `afunda`). |
| B12 | **O bicho invade o texto nos Ajustes.** O cartão de perfil usa a atividade atual (`app.activity`); quando é nado, a capivara é desenhada com linha d'água num cartão sem água, e o corpo passa por cima de "Você é uma capivara." | `play-store/telas/pt/09-ajustes.png`; `lib/widgets/pet_profile.dart:215-218` | Sobreposição de arte sobre texto é o tipo de erro que o usuário percebe na hora como "malfeito". |
| B13 | **Escala do bicho na cena.** O bicho ocupa ~40–45% da largura da cena e tem a altura das árvores e do deque. | `docs/evidence/2026-08-27/habitat-cheio.png` | Sem escala coerente, o habitat parece colagem de adesivos e não um lugar. |
| B14 | **O pet da sobreposição é outro desenho.** A pré-visualização dentro do app mostra o bicho Flutter, mas a sobreposição real é desenhada à parte em Kotlin com ovais e círculos. | `tela-sobreposicao.png` vs `android/.../OverlayDoBaru.kt:315-380` | Ponto 7 do brief; aqui ele entra como problema de **consistência de sistema** (ver R-V9). |

### 1.2 Emoções: como cada humor lê hoje

| Humor | O que o código desenha | Como lê (minha leitura das imagens) | Veredito |
|---|---|---|---|
| Radiante | olhos iguais ao contente com pupila 12% maior, sorriso largo, bochecha, 4 brilhos laranja | "contente com adesivos de brilho" | fraco: diferença de 1 canal |
| Contente | olho anel, sorriso pequeno | "assustado e sorrindo" (por causa do anel) | ambíguo |
| Neutro | pálpebra superior chapada inclinada, boca reta | "desconfiado", "de lado" | errado: não é neutro, é desconfiado |
| Sonolento | olhos em arco, "zZ", folha | lê bem; é o melhor dos cinco | ok |
| Sentindo falta | pálpebra inclinada, sobrancelha não espelhada, boca para baixo, lágrima apagada, pelo 14% mais escuro | "bravo/emburrado" | **errado e contra o tom do produto** |

**[App]** Não há postura por humor nos retratos (o corpo é o mesmo nos
quatro), não há orelhas ou cauda expressivas (exceção: buldogue, cujas orelhas
caem em sono e saudade, `pet.dart:2640-2648`), e as partículas de emoção são
só duas (brilho laranja e "zZ"); coração aparece apenas no afago
(`reacao-3-carinho.png`, `reacao-7-afago.png`).

### 1.3 Habitat e cena

- **[App]** Cenário inteiro em formas chapadas e translúcidas: morros em
  semicírculo, sol com halo, deque e pedras em retângulos arredondados, plantas
  aquáticas em pílulas (`01-home.png`). Não há primeiro plano, não há textura,
  não há variação de borda. O bicho é a única coisa com volume.
- **[App]** Os seis habitats da trilha (lagoa, igarapé, manguezal, praia,
  serra, ilha) diferem quase só pela cor da água e pela forma dos morros; o
  manguezal não tem raízes de mangue, a praia não tem areia, a ilha não tem
  ilha (`docs/evidence/2026-08-27/habitat-trilha-*.png`).
- **[App]** `habitat-cheio.png`: com os 8 itens, a cena vira colagem — lanterna,
  árvore com uma fruta, nuvens em pílula, varal de luzes, peixes em pílula —
  cada item numa escala, nenhum com sombra.
- **[App]** 85 cores escritas à mão em `lib/widgets/habitat.dart` (contagem de
  `Color(0x` por arquivo), contra a regra do próprio `tokens.dart:1-8`
  ("Nenhum valor de cor… deve ser escrito fora daqui").
- **[App]** As miniaturas de itens na loja são a mesma cena reduzida com um
  objeto quase abstrato: vitórias-régias = duas pílulas verdes; juncos = três
  bastões; cogumelos = dois retângulos vermelhos (`06-loja.png`). Nada nelas
  dá vontade de comprar.
- **[App] ponto positivo:** a variação por hora do dia existe e funciona
  (`habitat-amanhecer/dia/entardecer/noite.png`); o céu de noite com lua e
  lanterna é a imagem mais bonita do app.

### 1.4 Iconografia

- **[App]** **73 ícones Material distintos em 24 arquivos** (contagem de
  `Icons.<nome>` únicos em `lib/`). Os mais visíveis: tab bar
  (`home`, `route`, `flag`, `settings` — `app_icons.dart:68-73`), cadeado,
  `eco`, `redeem` (presente), `bedtime` (lua), `self_improvement` (pessoa
  meditando), `park` (árvore), `ac_unit` (floco de neve), `emoji_events`
  (troféu), `trending_down`, `wc` (banheiro, para "Sexo"!), `pets` (pata),
  `palette`, `insights`, `local_florist` (na celebração de nível).
- **[App] A moeda tem quatro desenhos:**
  1. `LeafMark` — gota com dois cantos vivos (`common.dart:339-360`), verde,
     no selo de saldo da home;
  2. `LeafMark` em `Cores.acentoTexto` (ferrugem) nas recompensas de missão
     (`missoes_screen.dart:627-631`, visível em `04-missoes.png`);
  3. `Icons.eco_rounded` (folha com nervura e cabo) na loja e na tela de
     folhas (`shop_screen.dart:281`, `folhas_screen.dart:167`; `06-loja.png`,
     `10-folhas.png`);
  4. `LeafMark` laranja no fim de sessão (`result_screen.dart:43`).
- **[App] A raiz tem três desenhos e duas cores:** o ícone do selo da home
  (um traço laranja que lê como "tênis" ou "lesma"), o rabisco da tela "Sua
  raiz" — três traços cor de ferrugem num quadrado pêssego que não preenche o
  cartão (`08-sequencia.png`) — e a raiz **verde** do cartão de compartilhar
  (`cartao-da-raiz.png`).
- **[App]** O dia da semana marcado é um anel verde na home (`01-home.png`) e
  um anel laranja na tela da raiz (`08-sequencia.png`) — o mesmo dado em duas
  cores.
- **[Opinião]** Ícone Material é desenhado para interface utilitária (Gmail,
  Configurações). Ao lado de um personagem ilustrado, ele puxa o app para
  "formulário". O pior caso é o `wc_rounded` (pictograma de banheiro) para o
  sexo do bicho, em `settings_screen.dart:54`.

### 1.5 Paleta e contraste

Valores calculados com a fórmula do WCAG 2.x. Critérios: texto comum ≥ 4,5:1;
texto grande (≥ 18 pt, ou ≥ 14 pt em negrito) ≥ 3:1; componentes e gráficos
≥ 3:1 **[Fonte: W3C, SC 1.4.3 e 1.4.11]**.

| Par (onde aparece) | Contraste | Passa? |
|---|---|---|
| Tinta `#3E2F23` sobre superfície `#FAF1E3` (títulos) | 11,5:1 | sim |
| Creme sobre verde primário `#5C8A4E` (texto dos botões, 17 px w700) | **3,6:1** | não (17 px negrito não é "texto grande") |
| Creme/branco sobre acento `#EF8354` ("Resgatar", "A principal de hoje") | **2,3–2,6:1** | não |
| Acento `#EF8354` como texto sobre superfície ("+15" no relatório) | **2,3:1** | não |
| `acentoTexto #B8502A` sobre pêssego (cartão "Próximo passo", raiz) | 3,9:1 | não |
| Verde primário como texto sobre superfície ("Raiz de 4 dias", "Folhas >") | 3,6:1 | não |
| Rótulo de seção (tinta 42%, 11,5 px, maiúsculas — `SectionLabel`) | **~2,4:1** | não |
| `TextAction` (tinta 55%) — "Desistir", "Compartilhar minha raiz" | 3,2:1 | não |
| Texto do chip "Áudio" `#B39BC8` sobre o próprio tingido | **2,2:1** | não |
| Chips "Dispersivo"/"Neutro" | 2,6:1 | não |
| Trilho das barras (tinta 9%) contra o cartão | 1,2:1 | o preenchimento é o que importa; ver abaixo |
| Preenchimento laranja da barra contra o cartão | 2,5:1 | não (1.4.11) |

**[App]** A paleta tem 2 verdes de marca + 3 laranjas + 1 lilás e 1 azul só
para categorias (`tokens.dart:178-181`) — lilás e azul não existem em nenhuma
outra parte do app nem do cenário, por isso as barras de "Seu tempo de tela"
parecem tiradas de outro produto (`05-tempo.png`).

**[App]** **Semântica de cor misturada:** laranja quer dizer, ao mesmo
tempo, "raiz/streak", "próximo passo da trilha", "missão principal", "pronta
para resgatar", "dispersivo" e "você passou da meta" (barra laranja em
`fala-contente-acima.png`). O verde quer dizer "ação", "folha", "produtivo",
"nível" e "em uso". Quando uma cor quer dizer tudo, não quer dizer nada.

**[Fonte]** Deficiência de visão de cores vermelho-verde afeta até ~8% dos
homens de ascendência norte-europeia e menos de 1% das mulheres
([Healthcare/MDPI 2025, PMC12385717](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12385717/)).
**[Opinião]** O par verde (produtivo) × laranja (dispersivo) é exatamente o
par que essa população confunde; hoje o rótulo de texto salva, mas o
contraste do rótulo também reprova.

### 1.6 Tipografia

- **[App]** Nunito empacotada (4 pesos). Boa escolha, coerente com o contrato
  (PRODUCT.md §11).
- **[App]** **Duas escalas tipográficas paralelas:** `Tipo` em `tokens.dart:292-311`
  e o `TextTheme` em `theme.dart:159-174` com tamanhos que não existem em
  `Tipo` (26, 17, 15, 13,5). Telas antigas usam `nunito(size: …)` direto com
  números soltos (`result_screen.dart:46, 61, 69, 98, 100`; `common.dart`
  inteiro). É a causa de títulos de cartão em 16, 17 e 18 px em telas
  vizinhas.
- **[App]** Rótulos em caixa alta de 11–11,5 px com espaçamento 0,7–0,8 em
  tinta 42–45% ("ESTA SEMANA", "PARA FAZER HOJE", "DE ONDE VIERAM") — pequenos
  e claros demais (ver 1.5).
- **[App]** `NO HABITAT` em caixa alta e peso 800 convive com "Beira d'água"
  em caixa normal na mesma tela (`06-loja.png`): dois níveis de título com
  regras diferentes.
- **[App/Inferência]** Não há `fontFamilyFallback` declarado (`grep` vazio em
  `lib/`). A Nunito não tem glifos CJK; em `zh` o texto cai na fonte do
  sistema, com outra altura de x e talvez sem o peso 800. Não verifiquei em
  aparelho.
- **[App]** O texto é limitado a 1,25× (`app_frame.dart:50`); o relatório de
  agosto já apontou (C-09). Fica registrado porque qualquer redesenho de
  cartões precisa ser testado a 1,3× e 2×.

### 1.7 Componentes

- **Cartões — quatro estilos para a mesma função.** Creme elevado com sombra
  difusa (`CartaoBaru`), verde-oliva tingido sem sombra ("Nível 4", "137
  folhas"), pêssego tingido sem sombra ("Próximo passo", "Raiz atual") e bege
  acinzentado ("O dia de Baru", stats do resultado em `inkA(0.05)`). Nenhum tem
  ilustração própria; a hierarquia vem só da cor do fundo
  (`03-trilha.png`, `07-relatorio.png`, `08-sequencia.png`).
- **[App]** A sombra do selo de folhas da home é uma "borda inferior" sólida
  (3D), a do selo da raiz ao lado não tem nenhuma (`01-home.png`): dois
  elementos lado a lado, duas profundidades.
- **Botões — cinco desenhos sem estado pressionado.** `PrimaryButton` é chapado,
  com raio 20 escrito à mão, e só muda de cor no *hover* (mouse), nunca no
  toque (`common.dart:42-100`). `GhostButton` cinza, `TextAction` sem fundo,
  `_BotaoCompacto` com sombra colorida, chip "Resgatar" laranja em pílula. O
  botão de compra da loja mostra só "🍃 90", sem verbo (`06-loja.png`).
- **Barras de progresso.** Três cores (verde, laranja, cinza) para o mesmo
  componente sem regra visível: laranja = "pronta" nas missões, laranja =
  "próximo passo" na trilha, laranja = "acima da meta" na home.
- **Estados vazios.** `EstadoVazio` = ícone Material dentro de um círculo
  tingido + título + texto (`componentes.dart:227-284`; `tempo-vazio.png` com
  ampulheta). É o padrão genérico de qualquer app; o bicho, que é o maior
  ativo do produto, não aparece.

### 1.8 Telas

| Tela | O que está desconexo ou amador | Imagem |
|---|---|---|
| Home | "Raiz de 4 dias" aparece **três vezes** (selo, título, cartão da semana). Banner "relatório pronto" com ícone `insights` (gráfico com brilhos) e fundo oliva. Cena e corpo da tela em linguagens diferentes. Semana com só a segunda marcada, apesar de 4 dias seguidos (dado de captura ou bug a conferir). | `01-home.png` |
| Sessão | A água é uma faixa verde que atravessa a tela inteira e some num degradê bege, sem margem nem chão: parece um pedaço de outra tela. 60% da tela é vazio bege. Barra de progresso de 4 px quase invisível. | `02-sessao.png` |
| Fim de sessão | Folha laranja, *padding* escrito à mão `(26, 20, 26, 34)` (`result_screen.dart:18`), dois cartões cinza de estatística sem ícone, e em caso de desistência o bicho com a cara "brava" do B6 (`result_screen.dart:27`). Sem captura no Play Store; descrição pelo código. | — |
| Raiz | A "ilustração" da raiz é um rabisco de três traços num quadrado que não preenche o cartão. Quatro ícones Material (troféu, floco, meditação, gráfico descendo). | `08-sequencia.png`, `raiz-crescendo.png` |
| Missões | Folha cor de ferrugem; chip lua `bedtime`; botão "Resgatar" com ícone de presente `redeem` e contraste 2,6:1; cartão principal com botão verde chapado. Bom: hierarquia "principal / para colher / para fazer". | `04-missoes.png` |
| Trilha | Nós são círculos verdes com `check` Material; nenhuma ilustração de marco; miniaturas de habitat quase iguais entre si; cadeado Material sobre a miniatura bloqueada. | `03-trilha.png`, `trilha-andamento.png` |
| Loja | Folha `eco`; miniaturas abstratas; selo "Seu" com ícone de caixa (`inventory`); "Tirar" com `check_circle`; cartão cortado na lateral sem indicação de rolagem. | `06-loja.png` |
| Ajustes | Bicho invadindo o texto (B12); ícone de banheiro para "Sexo"; campo do nome "Baru" num cinza que parece desabilitado. | `09-ajustes.png` |
| Celebração de nível | Fundo marrom chapado, círculo verde com `local_florist` (flor Material), "Nível 4" em cinza claro de baixo contraste, bolinhas verdes. **O bicho não aparece** no momento mais feliz do app. (A captura pode ser um quadro do meio da animação, mas a composição final é essa.) | `celebracao-nivel.png`; `app.dart:322`; `celebracao.dart:24` |
| Onboarding — revelação | O bicho revelado tem ~120 px numa tela de 824 px; a lista "Prefere outro?" é só texto, sem retratos; espécies bloqueadas viram chips com cadeado, sem silhueta. | `onboarding-revelacao.png` |

---

## 2. Referências (fatos com fonte)

### 2.1 Duolingo — sistema de ilustração

- **[Fonte]** O guia de identidade do Duolingo descreve ilustrações feitas de
  **três formas básicas** (retângulo arredondado, círculo e triângulo
  arredondado); pontas vivas "quebram o estilo"; **poucas formas**;
  **perspectiva chapada**; **sombras em pílula, não oval**, porque oval sugere
  perspectiva; cabeça e corpo de personagem com 1–2 formas cada; repetição de
  formas para coesão; olhos geométricos. (Página `design.duolingo.com/illustration`
  e `/illustration/characters`, conforme o índice de busca; hoje o domínio
  redireciona para [blog.duolingo.com/hub/design](https://blog.duolingo.com/hub/design/)
  e não consegui abrir a versão arquivada. Trate o detalhe como "segundo o
  índice", não como citação literal.)
- **[Fonte]** Megan Barker, "Shape language: Duolingo's art style", 2 jul.
  2020 ([blog](https://blog.duolingo.com/shape-language-duolingos-art-style/)):
  o estilo arredondado nasceu no Duolingo KIDS (2018) buscando ilustrações
  "brighter, rounder, friendlier"; regra de usar "the fewest details needed to
  get the point across"; personagens exagerados "almost to the point of
  caricature"; ritmo por "a strategic variety of shapes and sizes"; o estilo
  definido é o que permite produzir muito sem perder qualidade.
- **[Fonte]** Khalaf & Zabell, "How to draw Duo in 10 easy steps", 10 jun.
  2022 ([blog](https://blog.duolingo.com/how-to-draw-duo-the-owl)): corpo em
  círculo, olhos grandes com pupila e **um brilho no alto à esquerda** de cada
  pupila, a máscara ao redor dos olhos como marca, pés em pílula.
- **[Fonte]** Cores oficiais: Feather Green `#58CC02` como cor-núcleo, Mask
  Green `#89E219` secundária, Eel `#4B4B4B` para tipografia, Snow `#FFFFFF`
  como fundo, mais secundárias nomeadas por bicho (Macaw, Cardinal, Bee, Fox,
  Beetle, Humpback) ([design.duolingo.com/identity/color](https://design.duolingo.com/identity/color),
  conforme o índice de busca). **[Opinião]** A lição para o Baru não é copiar
  as cores, é **dar nome e papel fixo** a cada cor.
- **[Fonte]** Animação de personagem em Rive: os dez "World Characters" usam
  uma máquina de estados Rive com estados de pose, estados só de boca e
  ociosos (piscar, sobrancelha, aceno), 20+ formas de boca por personagem,
  exportados como **um único arquivo** de runtime; Rive foi escolhido por
  arquivos pequenos para Android/iOS/web e pela máquina de estados (Vahidsafa
  & Lenzo, 10 nov. 2022, [blog](https://blog.duolingo.com/world-character-visemes)).
  No Video Call, a Lily tem 8 animações de cabeça e 8 de corpo combinadas em
  64+ variações de pose neutra, com transições calculadas em tempo de execução
  ([Rive](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)).
- **[Fonte]** Streak: o time descobriu em pesquisa que a metáfora da chama
  não era entendida em todas as culturas; trocou por "power-ups" com o Duo
  **se transformando** nos marcos (fênix); "Timing is everything in
  animation" (Hartfelder, 21 jan. 2022,
  [blog](https://blog.duolingo.com/streak-milestone-design-animation)).
  **[Opinião]** Vale para a "raiz": hoje ela é um rabisco; a metáfora precisa
  de um objeto visível que cresce (broto → muda → árvore) e de um marco em que
  **o bicho muda** (chapéu de folha, coroa de flores).
- **Botões 3D do Duolingo:** não achei documentação oficial. Só
  reconstruções de terceiros descrevem a "sombra inferior sólida de 3–4 px na
  cor mais escura, que some ao pressionar". A spec da seção 4.8 é minha, a
  partir da observação do app.

### 2.2 Apps e jogos "cozy"

- **[Fonte] Finch:** pets "never die because it can be too anxiety-inducing";
  o pássaro chega a "toddler" após 7 dias de aventura e a adulto após 67, e o
  app diz quanto falta para o próximo estágio
  ([FAQ do Finch](https://befinch.notion.site/Finch-FAQ-474652d0123d4883ac7a0cd6c8f5aa70),
  conforme o índice de busca; a página não abriu no fetch). Ao chocar, o
  pássaro é cinza e é colorido depois com tinturas
  ([TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Finch), fonte
  de fã). Não achei entrevista sobre a direção de arte do Finch.
- **[Fonte] Animal Crossing: New Horizons:** 48 "Reactions" (emotes),
  aprendidas com os vizinhos, uma por dia, algumas só com amizade alta
  ([Nookipedia](https://nookipedia.com/wiki/Emotion)). **[Opinião]** Expressão
  como coisa **colecionável e ensinada pelo bicho** casa com o Baru: o bicho
  aprende um gesto novo a cada marco.
- **[Fonte] Iconografia de emoção (manpu):** convenções gráficas do mangá —
  gota de suor = constrangimento ou estresse, veia = raiva, espiral =
  confusão, ">  <" = nervosismo ou empolgação
  ([Wikipedia, Manga iconography](https://en.wikipedia.org/wiki/Manga_iconography);
  guia da BnF, "Ideograms in Comics"). Animal Crossing e Pokémon usam esse
  vocabulário em balões sobre a cabeça.
- **[Fonte] Neko Atsume:** a imprensa atribui parte do sucesso ao estilo
  simples, "reminiscent of notebook doodles", em que a falta de detalhe
  aumenta a fofura ([Fanlore](https://fanlore.org/wiki/Neko_Atsume)). É
  comentário secundário; não achei declaração da Hit-Point sobre a arte.
- **[Fonte] Pokémon Sleep:** cada Pokémon tem 3–4 "sleep styles"
  (posições de dormir) colecionáveis, com raridade de 1 a 5 estrelas
  ([Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Sleep_style)).
  **[Opinião]** O Baru já tem "descanso" e atividades; transformá-los em
  **poses colecionáveis** dá motivo para abrir o app e olhar o bicho.
- **[Fonte] Headspace:** o redesenho de 2024 criou "a range of faces
  expressing a range of emotions beyond a smile" (estresse, tristeza,
  contentamento), manteve o laranja como assinatura e priorizou contraste para
  acessibilidade (Gorny, It's Nice That, 25 abr. 2024,
  [link](https://www.itsnicethat.com/articles/italic-studio-headspace-graphic-design-project-250424)).
- **[Fonte] Sanrio:** a Hello Kitty não tem boca desenhada para que as
  pessoas "project their own feelings onto her face", segundo a designer Yuko
  Yamaguchi e porta-vozes da Sanrio
  ([Wikipedia](https://en.wikipedia.org/wiki/Hello_Kitty)). **[Opinião]**
  O Baru precisa do oposto em clareza (o humor é informação), mas a lição de
  contenção vale: **rosto mínimo**, poucos traços, a emoção carregada pelos
  olhos e pela postura.
- **[Fonte] "Cozy":** o relatório do Project Horseshoe 2017 define
  aconchego em jogos como a fantasia de **segurança, abundância e maciez**
  (resumo em [Game Developer](https://www.gamedeveloper.com/design/designing-for-coziness);
  não abri o original). Maciez inclui ritmo e interface, não só estética.

### 2.3 Ciência de fofura, forma, luz e expressão

- **[Fonte] Kindchenschema (Lorenz):** cabeça grande em relação ao corpo,
  testa alta, olhos grandes **abaixo da linha média do crânio**, bochechas
  redondas, nariz, boca e queixo pequenos
  ([Wikipedia, Baby schema](https://en.wikipedia.org/wiki/Baby_schema)).
  Glocker et al. (Ethology, 2009) mostraram que a fofura percebida acompanha
  a motivação de cuidar, e (PNAS, 2009) que rostos com mais "baby schema"
  ativam o núcleo accumbens, área de recompensa
  ([PNAS PDF](https://www.cceb.upenn.edu/csa/assets/user-content/documents/PNAS-2009-Glocker.pdf);
  [Ethology, repositório UPenn](https://repository.upenn.edu/cog_neuro_pubs/11)).
- **[Fonte] Fofura e foco — o achado mais relevante para o Baru:** Nittono
  et al. (PLoS ONE, 2012), "The Power of Kawaii": depois de ver fotos de
  filhotes, o desempenho numa tarefa motora fina melhorou 43,9% contra 11,9%
  com bichos adultos; o efeito se repetiu numa busca visual, e comida gostosa
  não teve efeito; a interpretação é que imagens fofas estreitam o foco de
  atenção ([PMC3458879](https://pmc.ncbi.nlm.nih.gov/articles/PMC3458879)).
  Amostra pequena (132 universitários). **[Opinião]** É um argumento a favor
  de mostrar o bicho, grande e fofo, **na tela de sessão de foco**, e não uma
  faixa d'água num fundo vazio.
- **[Fonte] "Olhos de cachorro pidão":** cães têm um músculo que ergue a
  parte interna da sobrancelha (ação AU101) que os lobos praticamente não
  têm; o movimento deixa os olhos maiores e mais infantis e lembra uma
  expressão humana de tristeza (Kaminski et al., PNAS 2019,
  [PMC6642381](https://pmc.ncbi.nlm.nih.gov/articles/PMC6642381)). Em
  abrigos, cães que fazem mais esse movimento foram adotados mais rápido
  (Waller et al., PLoS ONE 2013,
  [PMC3873274](https://pmc.ncbi.nlm.nih.gov/articles/PMC3873274/)).
- **[Fonte] FACS:** no Sistema de Codificação de Ação Facial (Ekman &
  Friesen), o protótipo de tristeza é AU1+4+15 (ergue a ponta interna da
  sobrancelha + aproxima as sobrancelhas + baixa os cantos da boca); **AU4
  sozinho** puxa as sobrancelhas para baixo e para o centro, o desenho típico
  de raiva/concentração
  ([Wikipedia, FACS](https://en.wikipedia.org/wiki/Facial_Action_Coding_System)).
  **[Opinião]** É exatamente a diferença entre o "sentindo falta" atual (AU4
  sem AU1 num olho) e o que ele deveria ser (AU1 dominante, "olhos pidões").
- **[Fonte] Forma × sentimento (bouba/kiki):** Ramachandran & Hubbard
  (2001) repetiram o experimento de Köhler e 95–98% das pessoas chamaram a
  forma redonda de "bouba" e a pontuda de "kiki"
  ([Wikipedia](https://en.wikipedia.org/wiki/Bouba/kiki_effect)). Base para
  "redondo = gentil" na linguagem de formas.
- **[Fonte] Luz de cima:** Ramachandran (Nature, 1988) mostrou que o sistema
  visual interpreta sombreado assumindo luz vinda de cima (círculo escuro
  embaixo = convexo); trabalhos posteriores mostram que a suposição é
  flexível ([PeerJ 2014](https://peerj.com/articles/363)). Base para "uma
  direção de luz, sempre de cima".
- **[Fonte] Princípios de animação:** os 12 princípios de Thomas & Johnston
  (*The Illusion of Life*, 1981), entre eles *squash and stretch*,
  antecipação, exagero e *appeal*
  ([Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)).

### 2.4 Ferramentas

- **[Fonte] Rive em Flutter:** pacote `rive` (linha 0.14.x estável, 0.15 em
  dev), carrega `.riv` de asset, seleciona artboard e máquina de estados por
  nome, faz *data binding* com view models; renderizador próprio ou o canvas
  do Flutter (Impeller/Skia) ([docs](https://rive.app/docs/runtimes/flutter)).
- **[Fonte] SVG em Flutter:** `flutter_svg` (publicador flutter.dev) usa o
  backend `vector_graphics`, que **pré-compila SVG num binário** em tempo de
  build; CSS não é totalmente suportado — exportar do Illustrator com
  "Presentation Attributes" ([flutter_svg](https://pub.dev/packages/flutter_svg),
  [vector_graphics](https://pub.dev/packages/vector_graphics)).
- **Não verificado nesta pesquisa (cota de busca esgotada):** existe runtime
  Rive nativo para Android (`rive-android`, que eu conheço de antes); a
  recomendação R-V9 depende dele e precisa de uma checagem de 30 min antes
  de decidir.

---

## 3. Emoções dos bichos — sistema de expressão

### 3.1 Princípios

1. **Hierarquia de leitura.** Postura/silhueta → olhos → sobrancelha →
   boca → orelhas/cauda → partícula. A 48 dp (tamanho da sobreposição e da
   notificação) só os três primeiros sobrevivem; logo, **cada humor tem de
   diferir em pelo menos três canais**, e um deles tem de ser postura.
   **[Opinião]**
2. **Nenhum humor usa sinal de raiva.** Sobrancelha que desce para o centro
   sem erguer a ponta interna (AU4 isolado) está proibida em qualquer humor
   negativo. Tristeza = ponta interna **erguida** (AU1/AU101), olhos maiores e
   mais úmidos, não menores. **[Fonte: FACS; Kaminski 2019]**
3. **"Sentindo falta" é carência, não acusação.** O bicho quer a pessoa; não
   reclama dela. Ele procura (olha para a "porta"), segura um objeto da
   pessoa, e **se ilumina na hora** em que ela volta. **[Opinião, alinhada à
   regra 1 do PRODUCT.md]**
4. **Cor nunca é o único canal**, e o pelo **não escurece** por humor
   (remover `pet.dart:1157-1167`). A luz da cena muda com a hora; o bicho não
   "adoece".
5. **Rosto mínimo.** Olho escuro sólido, um brilho grande e um pequeno; boca
   de um traço; nada de esclera fora de expressões extremas (surpresa).
   **[Fonte: Barker 2020 — "fewest details"; Sanrio — contenção]**
6. **Simetria espelhada por padrão**; assimetria só intencional (uma orelha
   caída de curiosidade, cabeça inclinada).

### 3.2 Os cinco humores — especificação

Coordenadas de referência: unidade `u` = raio do olho em repouso.

| Canal | Radiante | Contente | Neutro | Sonolento | Sentindo falta |
|---|---|---|---|---|---|
| **Olhos** | fechados em arco para cima "^^" (olho que sorri), ou abertos com **dois** brilhos grandes | abertos, redondos, 1 brilho grande + 1 pequeno | abertos, brilho menor, pálpebra superior **reta e horizontal** cobrindo 15% (relaxado, não desconfiado) | pálpebras a 70% fechadas, piscada lenta; dormindo = arco para baixo | abertos **10% maiores**, dois brilhos grandes (olho úmido), pupila levemente para cima |
| **Sobrancelha** (traço ou mancha de pelo; coruja = tufos) | erguida inteira (+0,4 u) | repouso | repouso | levemente erguida (esforço de ficar acordado) | **ponta interna erguida** (+0,6 u), externa no lugar: "/ \\" invertido → "pidão" |
| **Boca** | aberta em "D", língua visível | sorriso pequeno em "u" | traço curto e reto, **centrado** | "o" pequeno de bocejo intermitente | traço curto levemente para baixo, sem beicinho exagerado |
| **Orelhas** | em pé, viradas para frente, pequena vibração | em pé | relaxadas | caídas para os lados | caídas para trás e para baixo |
| **Postura** | pulinho (squash & stretch), peito estufado | sentado ereto, respiração visível | sentado, peso num lado | cabeça pendendo, corpo afundado 8% | sentado de lado, **olhando para a borda da tela** (para onde a pessoa "foi"), abraçado a um objeto (folha, almofada) |
| **Cauda** | abanando rápido | balanço lento | parada | enrolada no corpo | baixa, ponta mexe de vez em quando |
| **Partícula (manpu)** | 3 brilhos dourados + notas musicais | 1 coraçãozinho a cada ~10 s | nenhuma | "z" que sobe e estoura em bolha | nuvem de pensamento com o **rosto/ícone da pessoa** (um "?" ou um coração pequeno); lágrima **só** no instante da volta, como lágrima de alegria |
| **Cor/luz** | aro de luz quente atrás (rim light) | — | — | cena 10% mais fria | — (sem escurecer o pelo) |
| **Ocioso** | gira, quica | olha ao redor, se coça | boceja, olha o céu | cochila e acorda | vai até a borda, volta, senta |

**Critério objetivo:** num teste de 5 segundos com 10 pessoas que não
conhecem o app, mostrando os cinco retratos sem legenda e pedindo para
nomear, cada humor tem de ser nomeado corretamente (ou com sinônimo) por
≥ 8 de 10, e **nenhuma** pessoa pode usar "bravo", "irritado" ou
"desconfiado" para qualquer um deles. **[Opinião — método de teste rápido de
legibilidade]**

### 3.3 Emoções e estados extras (usadas em momentos, não como humor do dia)

| Estado | Quando | Desenho |
|---|---|---|
| **Feliz em ver a pessoa** | abrir o app depois de horas; volta após "sentindo falta" | antecipação (agacha) → pulo → olhos "^^" → coração estoura; orelhas para frente. É o "reencontro": o momento mais importante do dia. |
| **Orgulhoso** | fim de sessão, missão resgatada | peito estufado, queixo para cima, olhos semicerrados de satisfação, brilho dourado no topo da cabeça |
| **Focado / guardando** | **durante a sessão** | olhos meio fechados e serenos, respiração lenta sincronizada com um anel de progresso; ou "cuidando" de um broto que cresce com o tempo |
| **Curioso** | item novo comprado, trilha com passo novo | cabeça inclinada 12°, uma orelha levantada, "?" pequeno, pupila segue o objeto |
| **Comendo** | atividade "pasto/petisco" | bochechas infladas, olhos fechados de gosto, migalhas/folhinhas |
| **Brincando** | toques repetidos, atividade de brincadeira | olhos ">  <" ou "^^", corpo em arco, objeto (bola de folhas, graveto) |
| **Dormindo** | noite, sonolento | enrolado, respiração com *squash*, "z" em bolha; pose varia por espécie (estilo "sleep styles") |
| **Com frio / com calor** | só se houver clima ou estação (opcional) | frio: encolhido, tremor de 2 px, bochecha azulada; calor: língua para fora, gota de suor, leque de folha |
| **Surpresa boa** | baú/recompensa abrindo | único estado com esclera: olhos grandes com anel, boca "o", pulinho |
| **Gratidão / afago** | carinho | já existe (`reacao-7-afago.png`) e é bom; manter |
| **Raiz segura (congelamento usado)** | primeiro acesso depois de um dia perdido | bicho segurando um cristal azul de orvalho, alívio (expira, ombros caem, sorriso) — **nunca** cena de perda |

### 3.4 Adaptação por espécie (sobrancelha "emprestada")

| Espécie | Canal extra de emoção | Observação |
|---|---|---|
| Capivara | orelhas pequenas que giram; **narinas**; corpo grande que "derrete" | Capivara é calma por natureza: radiante dela é sereno-feliz, não saltitante. Ave no lombo como acessório de alegria (pássaro pousa quando radiante). |
| Lontra | bigodes (sobem/descem), patas no peito, rolar de costas | Radiante = boiando de costas segurando algo. |
| Tartaruga | cabeça **entra/sai do casco** | Sentindo falta = só os olhos aparecendo na abertura do casco, olhando para fora. |
| Coruja | **tufos de orelha** como sobrancelha; disco facial; giro de cabeça | Não nada; nunca deve aparecer submersa (hoje aparece "voando" sobre a água em `home-owl.png`). |
| Axolote | **guelras** sobem, abrem e mudam de saturação | As guelras são as orelhas dele. |
| Pinguim | asas (bater = alegria, abraçar o corpo = frio/carência) | |
| Gata | orelhas (para trás = carência, nunca "achatadas" de raiva), cauda em "?" de curiosidade | |
| Raposa | cauda volumosa (abraça a cauda quando sente falta) | |
| Buldogue | orelhas (já existe) + língua + "ronco" | Rever a fenda dos olhos em neutro/saudade (B7). |

### 3.5 Iconografia de emoção própria (manpu do Baru)

Conjunto fixo de 10 símbolos, mesmo traço dos ícones (seção 4.5), cor
`mel` ou `tinta`: brilho de 4 pontas (alegria), coração (afeto), nota musical
(contentamento), "z" em bolha (sono), "?" (curiosidade), "!" (surpresa),
gota de suor pequena (esforço, nunca vergonha), nuvem de pensamento (sente
falta / lembra da pessoa), folhinha girando (fome/comer), floco de orvalho
(congelamento). **Proibidos:** veia de raiva, nuvem de tempestade, caveira,
espiral de tontura.

---

## 4. Direção de arte unificada

### 4.1 Conceito

**"Bichos de feltro sob luz de fim de tarde."** **[Opinião]** Três ideias
amarram tudo:

1. **Feltro/papel recortado:** formas redondas e cheias, sem contorno preto,
   com volume dado por **duas tonalidades** (base e sombra) e um brilho; leve
   grão ou textura só no cenário, nunca na interface.
2. **Uma luz só:** sempre de cima-esquerda, a ~45°. Sombra interna à
   direita-embaixo de cada forma; brilho à esquerda-em-cima. Bicho, itens,
   cenário e ícones obedecem à mesma luz. **[Fonte: Ramachandran 1988 para
   "luz de cima"]**
3. **Interface de madeira e folha:** a interface é o "chão" da casa do bicho
   — cartões creme com lábio inferior, botões como seixos/teclas que afundam,
   ícones como pequenos objetos do habitat.

### 4.2 Regras de traço, luz e sombra

| Regra | Valor |
|---|---|
| Contorno de forma | **não**. Separação por valor (claro × escuro), não por linha. |
| Traço de feição (olho fechado, boca, sobrancelha, bigode) | cor `tinta-700`, espessura = **4% da largura da cabeça**, ponta arredondada; **a mesma proporção nas nove espécies** |
| Sombra própria | uma forma por volume, cor = base com L × 0,82 (HSL), sem degradê |
| Brilho | uma forma por volume, base com L × 1,10, 40–60% do tamanho da sombra |
| Sombra de contato | **pílula** (não oval) na cor `tinta` a 14%, largura = 80% da base do corpo **[Fonte: guia Duolingo, sombras em pílula]** |
| Degradê | só no céu e na água; nunca no bicho ou nos ícones |
| Linha d'água | o bicho que nada tem **recorte** (máscara) na linha d'água, com o corpo submerso desenhado num tom da água — não uma faixa translúcida por cima (corrige B11) |
| Número de formas | cabeça ≤ 2 formas-base, corpo ≤ 2, membros ≤ 1 cada **[Fonte: guia Duolingo]** |

### 4.3 Construção dos bichos

- **Proporção kawaii** **[Fonte: Lorenz/Glocker para os traços; números são
  minha proposta]:** adulto com cabeça = 50–55% da altura total; filhote/
  estágio inicial 60–65%. Olhos com centro **abaixo** da linha média da
  cabeça (a 55–60% da altura da cabeça, de cima para baixo); distância entre
  olhos ≈ 1,3 × diâmetro do olho; focinho pequeno e baixo; bochechas
  marcadas por forma, não só por blush.
- **Silhueta única por espécie.** Teste: preencher de preto a 64 px; cada
  espécie tem de ser reconhecida por ≥ 8 de 10 pessoas. Proposta de traço de
  silhueta: capivara = pão de forma deitado (largo e baixo, cabeça
  retangular **com focinho quadrado e testa curva**); lontra = gota alongada
  com cauda grossa; tartaruga = cúpula; coruja = ovo com dois tufos; axolote =
  feijão com coroa de guelras; pinguim = boliche; gata = pera com orelhas em
  triângulo arredondado e cauda em "?"; raposa = gota com cauda maior que a
  cabeça; buldogue = tijolo com orelhas de morcego.
- **Olho padrão:** disco **escuro sólido** (`tinta-900` ou castanho da
  espécie), vertical levemente oval, com um brilho grande no alto-esquerda
  (35% do raio) e um pequeno embaixo-direita (15%) **[Fonte: brilho no alto à
  esquerda — Khalaf & Zabell 2022]**. Coruja: íris âmbar + pupila. Esclera só
  na "surpresa boa".
- **Estágios de crescimento** (ovo → filhote → jovem → adulto, por espécie):
  é tema do laudo de cada pet. Aqui só a regra visual: o estágio muda
  **proporção e silhueta**, não só tamanho (filhote com cabeça 65%, corpo sem
  pescoço, membros curtos; adulto com marcas da espécie completas — listras,
  máscara, casco com placas).

### 4.4 Paleta revisada (tokens)

Mantém o espírito do contrato (creme, verde musgo, laranja quente, madeira —
PRODUCT.md §11) mas **escurece os tons que carregam texto** e dá **um papel
fixo a cada família**. Contraste calculado contra `superficieElevada #FFFBF2`.

| Token novo | Hex | Papel único | Contraste |
|---|---|---|---|
| `folha500` | `#5C8A4E` | (atual) preenchimentos grandes, ilustração | — |
| `folha600` | `#3F7A34` | **face do botão primário**, barra de progresso, ícone da folha | creme sobre ele 5,0:1 |
| `folha700` | `#2F5C27` | lábio do botão primário; texto verde | 6,2:1+ |
| `raiz500` | `#D86F32` | ilustração da raiz e do selo | — |
| `raiz600` | `#B4532A` | texto/ícone da raiz, botão de raiz | creme sobre ele 4,8:1 |
| `raiz700` | `#873E20` | lábio | — |
| `mel400` | `#F2B33D` | **conquista, XP, nível, "pronto para colher"** (face do botão de recompensa, com texto em `tinta`) | tinta sobre ele 6,9:1 |
| `mel600` | `#D5900E` | lábio do botão de recompensa | — |
| `mel700` | `#8F5E0A` | texto "+10 XP" | 5,4:1 |
| `ceu600` | `#3F6F9A` | congelamento, água, informação | 5,2:1 |
| `tinta900` | `#3E2F23` | texto principal (atual) | 11,5:1 |
| `tinta700` | `#6B5A4A` | texto secundário (substitui tinta 55–62%) | 6,4:1 |
| `tinta500` | `#857563` | só texto ≥ 18 px ou desabilitado | 4,3:1 |
| `trilho` | `#EADFCB` | fundo das barras | folha600 sobre ele 3,9:1 |
| Categorias de tela | `dispersivo #C4552F`, `neutro #4F6E9E`, `produtivo #3F7A34`, `passivo #7B5A99` | barras e chips (texto do chip na cor cheia, fundo a 12%) | 4,3–5,4:1 sobre o cartão |

**Regras de uso:** laranja/terracota **só** para raiz; mel **só** para
conquista/recompensa; verde para ação e folhas; "acima da meta" usa
`tinta700` (neutro) e nunca laranja-alarme. As cores de pelagem continuam por
espécie, mas cada uma ganha `sombra` e `luz` calculadas pela regra da 4.2,
num único lugar (não mais `Color.lerp` espalhado).

### 4.5 Iconografia própria

- **Grade 24 × 24 dp, área viva 20 dp**, traço 2,25 dp com pontas e cantos
  arredondados, **duotom**: traço em `tinta900` (ou cor semântica) + um
  preenchimento interno em 20–25% da mesma cor deslocado 1 dp para
  baixo-direita (eco da luz da 4.1). **[Opinião]** A grade de 24 dp segue o
  padrão de sistema do Material
  ([material.io, system icons](https://material.io/design/iconography/system-icons.html));
  o traço e o duotom são o que dá identidade.
- **Glifos de moeda e progresso (um desenho cada, usados em todo lugar):**
  folha (gota assimétrica com uma nervura curva, `folha600`), raiz (broto
  com duas folhas saindo de um montinho de terra, `raiz600` — substitui o
  "tênis"), XP (semente/estrela de 4 pontas arredondada, `mel600`),
  congelamento (gota de orvalho com faceta, `ceu600`), nível (folha dentro
  de um escudo de madeira).
- **Tab bar (4):** Habitat = casinha-toca com folha no telhado; Trilha =
  duas pegadas; Missões = cesto de colheita; Ajustes = engrenagem própria (ou
  "mochila"). Estado ativo = versão cheia + bicho-ícone pulando 2 dp.
- **Substituições prioritárias:** `wc` → símbolos ♀/♂/○ desenhados; `pets` →
  pegada da espécie; `palette` → novelo de pelagem; `redeem` → cesto com
  brilho; `bedtime` → lua com folha; `self_improvement` → bicho meditando;
  `park` → item do habitat; `emoji_events` → coroa de folhas; `insights` →
  livrinho do dia; `lock` → cadeado de madeira com folha; `check` dos nós da
  trilha → folha marcada.
- **Implementação:** SVG desenhado uma vez, compilado com `vector_graphics`
  (`flutter_svg` já usa esse backend) e exposto por um enum
  `BaruIcone.folha`, `BaruIcone.raiz`… num widget `IconeBaru(…, size,
  cor)`; ~40 ícones cobrem o app. Alternativa sem dependência nova:
  `CustomPainter` por ícone (mais caro de manter, mas viável — os ícones são
  formas simples). Regra de lint/teste: `grep "Icons\."` em `lib/screens` e
  `lib/widgets` tem de dar zero, exceto `arrow_back`/`chevron` se se decidir
  mantê-los.

### 4.6 Tipografia

- Manter **Nunito** (contrato). Uma escala só: `Tipo` vira a única fonte; o
  `TextTheme` de `theme.dart` passa a ser gerado de `Tipo`; `nunito(size:
  …)` com número solto fica proibido em código novo e migrado no antigo.
- Escala proposta (sp): display 32/w900 (números de herói 64/w900 tabular),
  título 22/w800, subtítulo 18/w800, corpo 16/w500 (hoje 14,5 é pequeno para
  um público amplo), corpo pequeno 14/w500, rótulo 13/w700. **Nada abaixo de
  12 sp.** Rótulos de seção em caixa normal, `tinta700`, 14/w800 — caixa alta
  espaçada fica só para microetiquetas (≤ 2 palavras).
- Números de recompensa (folhas, XP, dias de raiz) sempre em w900 tabular +
  glifo próprio à esquerda.
- `fontFamilyFallback: ['Noto Sans SC', …]` para `zh`, com o peso mais
  próximo empacotado ou do sistema, e capturas de `zh` nos testes de
  evidência.

### 4.7 Cartões

Três tipos, nada além:

1. **Cartão base** — `superficieElevada`, raio 22, **borda inferior sólida
   de 3 dp** em `#EADFCB` (o "lábio", mesma linguagem dos botões) em vez da
   sombra difusa; ao toque, afunda 2 dp.
2. **Cartão de destaque** — mesmo formato, fundo branco-creme, **faixa
   ilustrada** à esquerda ou no topo (bicho, raiz, item), e uma cor semântica
   **só** no ícone/título/barra (nunca o fundo inteiro tingido).
3. **Linha de lista** — sem fundo próprio, dentro de um cartão base, ícone
   próprio de 24 dp num "seixo" de 36 dp.

Some: oliva tingido, pêssego tingido, bege-cinza (`inkA(0.05)`).

### 4.8 Botões 3D

**[Opinião — spec própria; a do Duolingo não é documentada oficialmente]**

| Propriedade | Valor |
|---|---|
| Altura | 56 dp (primário), 48 dp (compacto) |
| Raio | 18 dp |
| Face | cor 600 da família (folha/mel/raiz) ou creme `#F3E7D3` (secundário) |
| Lábio | 4 dp abaixo da face, cor 700 (secundário: `#DCCDB3`) |
| Texto | 17 sp w800, `tintaClara` sobre folha/raiz, `tinta900` sobre mel e creme, com contraste ≥ 4,5:1 |
| Pressionado | face desce 4 dp (`Transform.translate`), lábio vai a 0, 70 ms ida / 120 ms volta com leve *overshoot*; `HapticFeedback.lightImpact` |
| Desabilitado | face `#EADFCB`, sem lábio, texto `tinta500` |
| Ícone | à esquerda, 22 dp, do conjunto próprio |
| Rótulo | **verbo + objeto** ("Comprar · 🍃 90", "Colher 10 folhas"), nunca só o número |

Variantes: **primário** (folha), **recompensa** (mel — "Colher", "Abrir"),
**raiz** (raiz600), **secundário** (creme), **texto** (sem face, só para
ações destrutivas ou de saída, `tinta700` com sublinhado no toque). Um único
widget `BotaoBaru(variante: …)` substitui `PrimaryButton`, `GhostButton`,
`_BotaoCompacto` e o chip "Resgatar".

### 4.9 Estados vazios

Regra: **todo estado vazio tem o bicho** (o da pessoa, na espécie e pelagem
dela) fazendo algo que explica o vazio, + uma frase + uma ação. Exemplos:

| Vazio | Cena |
|---|---|
| Tempo de tela sem medição | bicho com lupinha olhando um relógio de sol vazio |
| Sem permissão de uso | bicho segurando uma chave de madeira, oferecendo |
| Sem missões para colher | bicho deitado na rede, cesto vazio ao lado |
| Loja "meus itens" vazia | bicho olhando uma prateleira vazia, com uma folha na mão |
| Trilha no início | bicho na primeira pegada, com mochila |

Técnica: `PetView` já aceita espécie/humor/atividade; falta um parâmetro
`objeto:` (acessório na mão) e poses extras. Com Rive, é um estado/artboard
por cena.

### 4.10 Cena e habitats

- **Camadas fixas:** céu (degradê por hora — manter), fundo (morros com
  perspectiva atmosférica: mais claros e azulados quanto mais longe), meio
  (chão/água com **linha de margem** visível), plano do bicho (sombra de
  contato), primeiro plano (folhagem ou juncos cortados na borda, que
  emolduram e dão profundidade).
- **Escala fixa:** bicho adulto = 30–34% da largura da cena; itens
  desenhados numa grade de escala em relação ao bicho (lanterna = altura da
  cabeça, árvore = 2,5× o bicho). Cada item com sombra de contato e luz de
  cima-esquerda.
- **Cada habitat com uma assinatura de silhueta e paleta:** lagoa (vitórias-
  régias e juncos), igarapé (árvores com raízes, água chá-escura), manguezal
  (raízes-escora em arco, caranguejo), praia (areia, ondas, coqueiro), serra
  (pedras, araucária, névoa), ilha (horizonte de mar, ilhota). Teste: as
  seis miniaturas, sem rótulo, têm de ser distinguidas por ≥ 8 de 10
  pessoas.
- **Espécie × cenário:** coruja em galho/poleiro, nunca submersa; gata e
  buldogue na margem/almofada, não "em pé sobre a água".
- **Técnica:** o cenário é o melhor candidato para **SVG pré-compilado em
  camadas** (desenhado por ilustrador num editor vetorial, exportado por
  camada, animado em Flutter só com deslocamento/opacidade/cor da hora), em
  vez de 990 linhas de `CustomPainter` com 85 cores à mão.

### 4.11 Telas-chave redesenhadas

**Home (Habitat)**

1. Barra superior de 3 selos do mesmo componente (lábio, glifo próprio,
   número w900): folhas · raiz · nível. Cada selo é tocável e abre a sua
   tela. Some o selo da raiz em pílula larga.
2. Cena em altura maior (≈ 52% da tela), cantos 28, **o bicho com o humor
   legível**, balão de fala curto saindo dele (a frase de humor que hoje está
   como título).
3. Um **CTA único e fixo** abaixo da cena: botão 3D primário "Focar 25 min"
   com seletor de duração em seixos ao lado. (O relatório de agosto já pediu
   o CTA fora da rolagem.)
4. Abaixo: "Missão de hoje" (cartão de destaque com cesto e barra) e a semana
   da raiz como **sete brotos** (vazio, broto, broto com orvalho = congelado),
   não bolinhas cinza. Título "4 dias seguidos…" sai da home (fica no balão
   ou na tela da raiz), eliminando a repetição tripla.

**Sessão de foco**

1. Fundo inteiro é o habitat em versão "calma" (cores dessaturadas 20%,
   hora do dia real), não um bege vazio.
2. O bicho **grande** (≈ 60% da largura) em pose "focado/guardando", com um
   broto à frente que cresce em 5 estágios ao longo da sessão — é o
   indicador de progresso principal. **[Fonte: Nittono 2012 — imagem fofa e
   foco; a aplicação é opinião]**
3. Cronômetro em display 64/w900 tabular sob a cena; anel de progresso fino
   em `folha600` ao redor do broto ou da cena.
4. "Desistir" como botão texto em `tinta700`, pequeno, no rodapé, com
   confirmação em folha inferior em que o bicho aparece **calmo** ("Tudo bem,
   a gente tenta de novo"), nunca triste-bravo.

**Fim de sessão (resultado)**

Sequência coreografada de 2–3 cartões, um por vez, cada um com o bicho:
(1) bicho orgulhoso + folhas subindo uma a uma até o selo (glifo verde, não
laranja), (2) XP enchendo a barra de nível em mel, (3) raiz: o broto do dia
nascendo na fileira da semana. Botão "Continuar" 3D primário. Se desistiu:
um único cartão com bicho **contente-calmo** e "Você ficou 12 min. Isso
conta como presença?" só se a regra de produto permitir — senão, apenas
"Até a próxima" sem recompensa e **sem cara triste**.

**Raiz (streak)**

1. Ilustração de herói que ocupa a largura: corte de terra com a planta em
   cima e a raiz embaixo; cada marco (7, 14, 30, 100 dias) muda a planta
   (broto → muda → arbusto → árvore) e o bicho ganha um acessório (coroa de
   folhas). **[Fonte: Duolingo — personagem que se transforma no marco]**
2. Número grande w900 em `raiz600` + glifo.
3. Semana em brotos; congelamentos como gotas de orvalho num "pote"
   (equipados à vista, não invisíveis até o uso).
4. Estatísticas em linhas com ícones próprios.

**Missões**

1. Cabeçalho com o bicho segurando o cesto (vazio → cheio conforme colhe).
2. "Principal de hoje" em cartão de destaque com ilustração da tarefa à
   esquerda; botão 3D primário.
3. "Prontas para colher": botão **mel** "Colher 10 🍃 +10 XP" com texto
   escuro; ao tocar, as folhas voam para o selo do topo (já pedido no laudo
   de UX, aqui como forma).
4. Recompensas sempre com o glifo da folha **verde** e o de XP **mel**.

**Trilha**

1. Caminho vertical com nós em forma de **pedras/pegadas** de 64 dp com lábio
   3D; nó atual maior, com o bicho em cima e halo; nós futuros com
   ilustração do prêmio em silhueta (ovo de espécie nova, miniatura de
   habitat, item).
2. Marcos de habitat como "placas" ilustradas que atravessam o caminho
   (mudança de bioma visível na própria trilha, como o caminho do Duolingo
   muda de seção).
3. Espécie bloqueada aparece como **ovo** ou silhueta com "?" — nunca
   cadeado Material.
4. Nível e "próximo passo" num cartão de destaque fixo no topo, com a cor
   mel para XP.

**Loja**

1. Vitrine com o **habitat da pessoa** no topo, mostrando onde o item vai
   ficar (pré-visualização ao tocar).
2. Itens em cartões quadrados com ilustração do objeto **isolado, grande,
   com sombra de contato**, nome, e botão 3D "Comprar · 🍃 90"; item possuído
   com selo de folha marcada.
3. Filtros em seixos (segmentado) com ícones próprios.
4. Saldo no selo padrão do topo.

### 4.12 O que é viável em CustomPainter, onde usar Rive, onde usar SVG

| Elemento | Recomendação | Por quê |
|---|---|---|
| **Bicho (9 espécies × estágios × humores × atividades)** | **Rive**, um `.riv` por espécie com máquina de estados (inputs: `humor`, `atividade`, `estagio`, `toque`, `olhar`), ou um arquivo com uma artboard por espécie | O `pet.dart` tem 4.036 linhas de geometria e lógica de pose; cada ajuste de expressão exige programador. Rive permite blend entre estados, ossos/malha (squash & stretch, cauda com *follow-through*), e o ilustrador itera sem tocar em Dart. É o caminho que o Duolingo usa para personagens **[Fonte: Duolingo/Rive]**. |
| Expressões faciais | Rive (camadas de olho/sobrancelha/boca como estados combináveis, como os visemas do Duolingo) | combinação humor × reação × atividade explode em CustomPainter |
| **Sobreposição nativa (Kotlin)** | o **mesmo** `.riv` via runtime Android nativo (a verificar) **ou**, como passo intermediário, PNGs do bicho renderizados pelo Flutter (`PictureRecorder` → `toImage`) por espécie/pelagem/humor, salvos no armazenamento do app e lidos pelo `OverlayDoBaru.kt` | resolve o ponto 7 do brief sem um segundo desenho |
| Celebrações (nível, marco, raiz) | Rive (bicho + partículas) ou Flutter puro para partículas simples | hoje não há bicho na celebração |
| Cenário/habitats | **SVG em camadas** pré-compilado (`vector_graphics`), cor da hora aplicada em Flutter (`ColorFilter`/`ShaderMask`) | arte de ilustrador, leve, sem 85 cores à mão |
| Itens da loja e miniaturas | SVG | idem |
| Ícones | SVG compilado (ou CustomPainter simples) | ~40 ícones de traço |
| Botões 3D, cartões, barras, anéis | Flutter puro (`DecoratedBox`, `AnimatedContainer`, `CustomPainter` para anel) | trivial e performático |
| Partículas de emoção e confete | CustomPainter | já existe motor (`celebracao.dart`) |
| Lottie | **não** | sem interatividade de máquina de estados; Rive cobre o caso |

**Custo e risco do Rive:** curva de aprendizado da ferramenta, dependência
nativa (`rive_native`), diferenças de renderização com Impeller apontadas
pela própria documentação **[Fonte: docs Rive]**, e o trabalho de redesenhar
9 espécies. Mitigação: começar por **uma** espécie (capivara) com os 5
humores e 3 atividades, medir tamanho do `.riv`, FPS em aparelho de entrada e
o tempo de produção por espécie, e só então decidir o resto.

---

## 5. Recomendações detalhadas

Formato: **o quê · por quê · como · esforço (P/M/G) · impacto · critério de
aceite.**

**R-V1 — Corrigir a cara de "bravo" do sentindo falta e do neutro (hoje, no
CustomPainter).**
O quê: espelhar pálpebra e sobrancelha por lado; trocar a sobrancelha de
tristeza para ponta interna erguida; neutro com pálpebra horizontal; remover
o escurecimento do pelo por humor; lágrima só na volta. Por quê: B6, B7, B9;
FACS/Kaminski. Como: em `_olho` (`pet.dart:3551-3632`) receber `lado` (−1/+1)
e multiplicar o x dos vértices por `lado` (`lado = -1` no olho esquerdo, `+1`
no direito); sobrancelha de tristeza da ponta interna
`o + Offset(-0.6r·lado, -1.65r)` para a externa `o + Offset(0.9r·lado,
-1.2r)` (interna **mais alta**); pálpebra caída também espelhada e, no
neutro, horizontal; apagar o `switch` de `pelo` (`pet.dart:1157-1167`) exceto
`radiant` (que pode clarear). No resultado de desistência
(`result_screen.dart:27`) usar `Mood.content`. Esforço: **P**. Impacto: alto
(remove o único sinal visual de culpa do app). Aceite: retratos regenerados;
teste de 5 s (3.2) com ≥ 8/10 para "triste/saudade" e 0 menções a
"bravo"; golden test que falha se as duas sobrancelhas tiverem inclinação
de mesmo sinal.

**R-V2 — Uma moeda, um glifo, uma cor; uma raiz, um glifo, uma cor.**
O quê: `GlifoFolha` único (verde `folha600`), `GlifoRaiz` único (`raiz600`),
`GlifoXp` (`mel`). Por quê: 1.4 (4 folhas, 3 cores; raiz verde no
compartilhar). Como: widget novo em `lib/widgets/glifos.dart`; substituir
`LeafMark`, `Icons.eco*`, o ícone do selo da raiz; teste que procura
`Icons.eco` e `LeafMark(` com cor diferente da do token. Esforço: **P**.
Impacto: alto na percepção de "coeso". Aceite: `grep -rn "Icons.eco\|LeafMark("
lib` = 0 fora de `glifos.dart`; captura das telas 01, 04, 06, 10 e resultado
com o mesmo glifo verde.

**R-V3 — Paleta semântica e contraste AA.**
O quê: tokens da 4.4; regra "laranja = raiz, mel = conquista, verde = ação".
Por quê: 1.5 (10 pares reprovados). Como: adicionar tokens em `tokens.dart`,
apontar `AppColors` para eles, trocar `acento` em chips/botões por `mel400`
com texto escuro e `acentoTexto` por `raiz600`; teste unitário que calcula o
contraste dos pares de token declarados (texto × fundo) e falha abaixo de
4,5:1. Esforço: **M**. Impacto: alto (legibilidade + coesão). Aceite: o
teste passa; todos os pares da tabela 1.5 ≥ 4,5:1 (texto) ou ≥ 3:1
(barras/ícones).

**R-V4 — Botão 3D único (`BotaoBaru`) com estado pressionado.**
O quê: spec 4.8. Por quê: 1.7 (cinco botões, sem toque). Como: `GestureDetector`
com `onTapDown/Up`, `AnimatedContainer` para face + `Container` do lábio,
`Movimento.reduzido` respeitado; migrar `PrimaryButton`, `GhostButton`,
`_BotaoCompacto`, chip "Resgatar". Esforço: **M**. Impacto: alto ("feito
para tocar"). Aceite: zero usos dos widgets antigos; golden de 5 variantes ×
3 estados; háptico em todos.

**R-V5 — Iconografia própria e fim dos ícones Material visíveis.**
O quê: ~40 ícones da 4.5. Por quê: 1.4 (73 ícones Material). Como: SVG +
`vector_graphics` + `IconeBaru`; começar pelos 15 mais vistos (tab bar,
folha, raiz, XP, cadeado, cesto, check da trilha, lua, info, chevron,
voltar, ajustes de perfil). Esforço: **M** (desenho) + **P** (código).
Impacto: alto. Aceite: `grep -rho "Icons\.[a-z_]*" lib/screens lib/widgets`
≤ 2 ícones (setas), e nenhum nas telas 01–10.

**R-V6 — Redesenho dos rostos e silhuetas (bíblia de personagem).**
O quê: folha-modelo por espécie (turnaround frente/¾, 5 humores, 10
estados extras, 4 estágios), com as regras 4.2–4.3 e 3.2–3.4. Por quê: B1–B5.
Como: ilustrador (ou o designer) produz em vetor; primeiro na capivara.
Esforço: **G**. Impacto: muito alto (é o "produto"). Aceite: teste de
silhueta 64 px ≥ 8/10 por espécie; teste de humor 5 s ≥ 8/10; revisão de
consistência (mesma espessura de traço de feição, mesma direção de luz) em
folha de contato com as 9.

**R-V7 — Bicho em Rive, começando pela capivara.**
O quê: `.riv` com máquina de estados de humor/atividade/reação/estágio.
Por quê: 4.12. Como: pacote `rive`; `PetView` passa a ter duas
implementações atrás de uma flag até as 9 migrarem; inputs vindos de
`AppState`. Esforço: **G**. Impacto: muito alto em animação e emoção.
Aceite: capivara em Rive com 5 humores e 3 atividades, ≥ 55 fps num aparelho
de entrada, arquivo ≤ 300 KB (meta minha, a validar), e retratos do Play
Store regenerados a partir dele.

**R-V8 — Cena com camadas, escala e contato.**
O quê: 4.10. Por quê: 1.3, B11, B13. Como: SVG por camada, sombra em pílula
sob o bicho, máscara de linha d'água, escala do bicho fixa; mover as 85 cores
para tokens de cenário. Esforço: **G**. Impacto: alto. Aceite: as 6
miniaturas distinguidas por ≥ 8/10; nenhuma espécie terrestre "em pé" na
água; `Color(0x` em `habitat.dart` = 0.

**R-V9 — O pet da sobreposição é o mesmo pet.**
O quê: eliminar o desenho Kotlin separado. Por quê: B14 e ponto 7 do brief.
Como: (a) curto prazo: renderizar no Flutter os PNGs do bicho da pessoa
(espécie, pelagem, humor, 2–3 quadros de piscada) ao mudar perfil/humor,
gravar em `filesDir` e o `OverlayDoBaru.kt` só exibe `Bitmap`; (b) longo
prazo: o mesmo `.riv` no runtime Android nativo (verificar). Esforço: **M**
(a) / **G** (b). Impacto: alto (coerência visível fora do app). Aceite:
captura da sobreposição real idêntica ao bicho da home para as 9 espécies.

**R-V10 — Estados vazios e celebrações com o bicho.**
O quê: 4.9 e celebração de nível com o bicho orgulhoso. Por quê: 1.7, 1.8.
Como: `EstadoVazio` passa a receber `cena:` (pose+objeto) em vez de
`IconData`; `Celebracao` recebe o `PetView` no lugar do ícone
(`app.dart:322`, `celebracao.dart:24`). Esforço: **M**. Impacto: médio-alto.
Aceite: nenhum `EstadoVazio(icone:` restante; captura da celebração com o
bicho visível.

**R-V11 — Tipografia numa escala só, sem texto < 12 sp.**
O quê: 4.6. Por quê: 1.6. Como: gerar `TextTheme` de `Tipo`; migrar
`nunito(size:` (busca e troca por token); `SectionLabel` em caixa normal e
`tinta700`; `fontFamilyFallback` para `zh`. Esforço: **M**. Impacto: médio.
Aceite: `grep -c "nunito(size:" lib` = 0 em telas; capturas em `zh` sem
quebra de peso.

**R-V12 — Cartões em três tipos, com lábio.**
O quê: 4.7. Por quê: 1.7. Como: `CartaoBaru(tipo: base|destaque)` e
`LinhaDeValor` com ícone próprio. Esforço: **M**. Impacto: médio. Aceite:
nenhum cartão com fundo tingido inteiro; capturas 01, 03, 07, 08 revisadas.

**R-V13 — Tela de sessão com o bicho grande e o broto.**
O quê: 4.11 "Sessão". Por quê: `02-sessao.png` (faixa solta, vazio);
Nittono 2012. Esforço: **M**. Impacto: alto (é a tela onde a pessoa passa
mais tempo olhando). Aceite: captura sem faixa d'água solta; broto com 5
estágios visíveis em capturas a 0/25/50/75/100%.

**R-V14 — Ajustes: corrigir o bicho que invade o texto.**
O quê: o cartão de perfil usa sempre atividade `idle`/pose de retrato.
Por quê: B12. Como: `pet_profile.dart:218` passar `Activity.idle`.
Esforço: **P**. Impacto: médio (erro visível). Aceite: `09-ajustes.png`
regenerada sem sobreposição.

---

## 6. As 10 recomendações mais importantes (priorizadas)

| # | Recomendação | Esforço | Por que nesta ordem |
|---|---|---|---|
| 1 | **R-V1** — corrigir "sentindo falta"/neutro (espelhar, sobrancelha pidona, sem pelo escuro, sem cara triste no "desistir") | P | Remove o único sinal de culpa do app; uma tarde de trabalho |
| 2 | **R-V2** — uma folha, uma raiz, um XP: glifos únicos com cor fixa | P | É o "desconexo" mais visível e o mais barato |
| 3 | **R-V3** — paleta semântica + contraste AA testado | M | Coesão e legibilidade em todas as telas de uma vez |
| 4 | **R-V4** — botão 3D único com estado pressionado | M | Dá "toque de jogo" ao app inteiro |
| 5 | **R-V6** — bíblia de personagem (silhueta, olho sólido, 5 humores + extras) | G | Base de tudo o que vem depois; sem ela, Rive só anima o problema |
| 6 | **R-V5** — iconografia própria, fim do Material visível | M | Segundo maior fator de "amador" |
| 7 | **R-V7** — capivara em Rive (piloto) | G | Destrava animação e emoção de verdade; mede custo antes de escalar |
| 8 | **R-V9** — sobreposição com o mesmo bicho (PNG renderizado já; Rive depois) | M | Ponto 7 do brief; coerência fora do app |
| 9 | **R-V8** — cena em camadas, escala e contato, 6 habitats distintos | G | Habitat é a "casa" e o que a loja vende |
| 10 | **R-V13 + R-V10** — sessão com bicho grande; vazios e celebrações com o bicho | M | Coloca o personagem onde hoje há ícone ou vazio |

R-V11, R-V12 e R-V14 entram no mesmo trem de R-V3/R-V4 (R-V14 é P e pode ir
junto com R-V1).

---

## 7. O que **não** fazer

- **Não** adotar contorno preto grosso "para dar acabamento". Ele não
  resolve inconsistência de construção e briga com a luz de duas
  tonalidades; o problema é de forma, não de linha.
- **Não** copiar a paleta saturada do Duolingo (verde `#58CC02` em tudo).
  O Baru é "cozy" e de redução de estímulo; a lição é papel fixo por cor, não
  saturação.
- **Não** usar sinais de raiva, doença, sujeira ou abandono em nenhum humor
  (veia, nuvem de tempestade, pelo escurecido, moscas, cenário murcho).
  Fere a regra 1 do PRODUCT.md.
- **Não** trocar Material Icons por outro pacote genérico (Phosphor, Lucide
  etc.) achando que resolve: continua sendo ícone de outro produto.
- **Não** migrar as nove espécies para Rive antes do piloto medir FPS,
  tamanho de arquivo e horas de produção por espécie.
- **Não** usar Lottie para o bicho (sem máquina de estados interativa).
- **Não** pôr degradê, *glow* ou sombra difusa no personagem e nos ícones;
  degradê só no céu e na água.
- **Não** adicionar mais cores de categoria sem papel no resto do app.
- **Não** fazer o redesenho tela a tela sem os tokens e componentes primeiro
  — é como o app chegou a quatro linguagens.
- **Não** gerar arte dos bichos por IA para produção sem bíblia de
  personagem e revisão: o resultado tende a variar de traço a cada geração,
  que é exatamente o defeito atual. (Opinião.)

---

## 8. Riscos e dúvidas em aberto

1. **Quem desenha?** A proposta pede um ilustrador de personagem para a
   bíblia e os SVG do cenário. Sem essa pessoa, R-V6 e R-V8 viram R-V1
   estendida (ajustes no CustomPainter), com ganho bem menor.
2. **Rive no Android nativo** não foi verificado nesta pesquisa (cota de
   busca esgotada). R-V9(b) depende disso; R-V9(a) não.
3. **Impeller × Rive:** a documentação do Rive registra diferenças de
   renderização com Impeller; precisa de teste em aparelho.
4. **Tamanho do app:** 9 `.riv` + SVGs de 6 habitats + ~40 ícones. Estimar no
   piloto.
5. **Contrato de paleta:** PRODUCT.md §11 lista o verde `#5C8A4E` e o laranja
   `#EF8354`. A proposta mantém os dois para ilustração e acrescenta tons mais
   escuros para texto e botões; **isso muda o contrato de forma aditiva e
   pede um ADR** (DECISIONS.md), porque o §11 diz "nunca introduzir estilo
   que quebre esse tom".
6. **"Sentindo falta" é humor obrigatório** (PRODUCT.md §3). A proposta não
   o remove; muda a expressão de "triste/bravo" para "carente/procurando".
   Se o dono quiser algo ainda mais leve (ex.: "esperando"), isso é mudança
   de nome e de tom e também pede ADR.
7. **Testes de legibilidade** (5 s, silhueta) foram propostos com 10 pessoas;
   é um teste de guerrilha, não pesquisa com validade estatística.
8. **Fontes não encontradas:** documentação oficial dos botões 3D do
   Duolingo; entrevista da arte do Finch; declaração da Hit-Point sobre o
   estilo de Neko Atsume; a página oficial de ilustração do Duolingo (hoje
   redireciona) — os detalhes dela vêm do índice de busca.
9. **Captura da home** com a semana marcando só a segunda-feira e "4 dias
   seguidos" pode ser artefato do gerador de capturas; conferir antes de
   tratar como bug.
10. **Escopo com outros laudos:** estágios de crescimento por espécie,
    jornada e itens são detalhados nos laudos dedicados; aqui só as regras
    visuais que eles devem seguir.

---

## 9. Fontes

- Duolingo — Barker, M. "Shape language: Duolingo's art style", 2020. https://blog.duolingo.com/shape-language-duolingos-art-style/
- Duolingo — Khalaf, S.; Zabell, S. "How to draw Duo in 10 easy steps", 2022. https://blog.duolingo.com/how-to-draw-duo-the-owl
- Duolingo — Vahidsafa, J.; Lenzo, K. "Art meets technology…", 2022. https://blog.duolingo.com/world-character-visemes
- Duolingo — Hartfelder, K. "You're on fire! Or, how we brought the streak milestone to life", 2022. https://blog.duolingo.com/streak-milestone-design-animation
- Duolingo — guia de identidade (ilustração, personagens, cor), via índice de busca; domínio hoje redireciona: https://design.duolingo.com/illustration · https://design.duolingo.com/illustration/characters · https://design.duolingo.com/identity/color · https://blog.duolingo.com/hub/design/
- Rive — "Duolingo's AI-powered Video Call brings Lily to life". https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life
- Rive — Flutter runtime. https://rive.app/docs/runtimes/flutter
- flutter_svg. https://pub.dev/packages/flutter_svg · vector_graphics. https://pub.dev/packages/vector_graphics
- Finch FAQ (via índice). https://befinch.notion.site/Finch-FAQ-474652d0123d4883ac7a0cd6c8f5aa70 · TV Tropes, Finch. https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Finch
- Nookipedia, Reaction/Emotion. https://nookipedia.com/wiki/Emotion
- Wikipedia, Manga iconography. https://en.wikipedia.org/wiki/Manga_iconography
- Fanlore, Neko Atsume. https://fanlore.org/wiki/Neko_Atsume
- Bulbapedia, Sleep style. https://bulbapedia.bulbagarden.net/wiki/Sleep_style
- Gorny, L. "Headspace overhauls visual identity…", It's Nice That, 2024. https://www.itsnicethat.com/articles/italic-studio-headspace-graphic-design-project-250424
- Wikipedia, Hello Kitty. https://en.wikipedia.org/wiki/Hello_Kitty
- Game Developer, "Designing for coziness" (resumo do Project Horseshoe 2017). https://www.gamedeveloper.com/design/designing-for-coziness
- Wikipedia, Baby schema. https://en.wikipedia.org/wiki/Baby_schema
- Glocker, M. et al. PNAS 2009. https://www.cceb.upenn.edu/csa/assets/user-content/documents/PNAS-2009-Glocker.pdf · Ethology 2009. https://repository.upenn.edu/cog_neuro_pubs/11
- Nittono, H. et al. "The Power of Kawaii", PLoS ONE 2012. https://pmc.ncbi.nlm.nih.gov/articles/PMC3458879
- Kaminski, J. et al. "Evolution of facial muscle anatomy in dogs", PNAS 2019. https://pmc.ncbi.nlm.nih.gov/articles/PMC6642381
- Waller, B. M. et al. "Paedomorphic facial expressions give dogs a selective advantage", PLoS ONE 2013. https://pmc.ncbi.nlm.nih.gov/articles/PMC3873274/
- Wikipedia, Facial Action Coding System. https://en.wikipedia.org/wiki/Facial_Action_Coding_System
- Wikipedia, Bouba/kiki effect. https://en.wikipedia.org/wiki/Bouba/kiki_effect
- Ramachandran, V. S. "Perception of shape from shading", Nature 331:163–166, 1988 (citado via) PeerJ 2014. https://peerj.com/articles/363
- Wikipedia, Twelve basic principles of animation (Thomas & Johnston, 1981). https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation
- W3C, Understanding SC 1.4.3 Contrast (Minimum). https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html · WebAIM, Contrast. https://webaim.org/articles/contrast/
- Healthcare (MDPI) 2025, "A Global Perspective of Color Vision Deficiency". https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12385717/
- Material Design, System icons. https://material.io/design/iconography/system-icons.html

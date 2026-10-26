# Laudo 09 — Economia, loja e itens compráveis

Data: 2026-10-26. Escopo: a moeda (folhas), as entradas e saídas dela, a loja,
o catálogo de itens, a celebração da compra e a clareza da coleta de
recompensas. Base: `docs/pesquisa/BRIEF.md` e a seção 6 de
`docs/RELATORIO_UX_DUOLINGO.md` (agosto), que este laudo aprofunda e atualiza.

**Legenda usada em todo o laudo**

- **[F]** fato com fonte externa (link na própria linha ou na lista de fontes).
- **[O]** observação do app, com `arquivo:linha` (relativo a `baru_app/`) ou
  imagem de `play-store/`.
- **[I]** inferência ou opinião minha.

**Método.** Li `lib/data/progressao.dart`, `lib/data/missoes.dart`,
`lib/data/descanso_do_dia.dart`, `lib/data/descanso_retencao.dart`,
`lib/data/carteira.dart`, `lib/models.dart` (catálogo), `lib/state.dart`
(créditos e `buy`), `lib/screens/shop_screen.dart`,
`lib/widgets/loja_vitrine.dart`, `lib/widgets/habitat.dart` (chegada de
item), `lib/l10n_loja.dart`, `docs/PRODUCT.md` §5 e §9, e olhei
`play-store/telas/pt/06-loja.png`, `01-home.png` e `10-folhas.png`. As contas
de renda foram feitas com um simulador dia a dia que aplica as regras do
código (recompensa por sessão, missões, descanso, bônus de meta, XP, curva de
nível, trilha em corrente com critério alternativo, congelamento semanal que
conta como presença — `state.dart:2087-2092`). O simulador não está no
repositório; as premissas estão na seção 1.3 para quem quiser refazer.

---

## Sumário executivo

1. **A economia não fecha para ninguém, por motivos opostos.** O engajado
   compra a loja inteira (31 itens, 5.510 folhas) no **dia 25** e termina o
   primeiro ano com ~55 mil folhas sem destino. O casual leva **239 dias**
   para comprar tudo, e a renda dele é 7,6× menor que a do engajado (20,7 vs
   157 folhas/dia sem marcos). Um catálogo único com preços fixos não serve os
   dois sem duas ferramentas: **sumidouros infinitos e desejáveis** para o
   topo e **itens baratos e frequentes** para a base.
2. **Mais catálogo sozinho não resolve.** Mesmo com os 86 itens propostos
   aqui (+12.250 folhas permanentes), o engajado esgota tudo por volta do
   **dia 91**. O que segura o topo é sumidouro sem fim e de bom gosto: o
   **Bosque** (plantar árvores nativas, sem teto), petiscos consumíveis, a
   feira semanal que gira e os sazonais que voltam todo ano.
3. **A compra é muda.** `buy()` não toca som, não vibra e não celebra
   (`state.dart:1732-1741`); não existe `SomDoBaru` de compra
   (`services/som_service.dart:24-51`). A queda com mola do item existe
   (`widgets/habitat.dart:622-650`), mas roda no habitat da home, que não está
   na tela quando a pessoa compra.
4. **O bicho ignora os itens.** Item é retângulo arredondado parado
   (`ShapePart`, `models.dart:257-505`); nenhum item muda o que o bicho faz.
   Nos apps de referência, o item vale pelo que o bicho faz com ele (Neko
   Atsume: gatos raros só vêm por certos objetos). Proposta: cada item novo
   dispara uma ação do bicho, e cada espécie tem favoritos.
5. **"De onde veio" mente por omissão.** O extrato só conhece sessão, marco,
   missão e compra (`data/carteira.dart:41`). Descanso (30/dia), bônus abaixo
   da meta (15/dia), retomada e presente de volta nunca aparecem: são
   **27% da renda do engajado** e 21% da do casual. A captura
   `10-folhas.png` mostra "+80" de origem, "-300" de gasto e saldo 137.
6. **Nada de dinheiro na moeda.** Folha é tempo longe da tela; vendê-la
   apagaria o sentido. A monetização futura fica na assinatura (que no
   Duolingo é 76% da receita) e, se um dia houver compra avulsa, ela é de
   cosmético direto, nunca de folhas, espécie, congelamento ou caixa-surpresa
   (loot box está proibida no Brasil para jogos de provável acesso por menores
   desde março de 2026).

---

## 1. Auditoria com números

### 1.1 Torneiras: de onde entram folhas

| Fonte | Valor | Frequência | Onde no código |
|---|---:|---|---|
| Sessão 25 / 50 / 90 min | 10 / 25 / 50 | por sessão | `models.dart:577-582` [O] |
| Sessão livre | `floor(min × 0,5)` | por sessão | `models.dart:581` [O] |
| Bônus "dia abaixo da meta" | 15 | 1×/dia, precisa de permissão de uso | `state.dart:62`, `state.dart:2072-2073` [O] |
| Missão diária (3 de um pool de 13) | 10 a 25 (média 18,7) | até 3/dia | `data/missoes.dart:157-280` [O] |
| Missão semanal (2 de um pool de 6) | 60 a 110 (média 82,5) | até 2/semana | `data/missoes.dart:322-378` [O] |
| Descanso (40 min longe do telefone) | 30 | 1×/dia | `data/descanso_do_dia.dart:28,42` [O] |
| Retomada (dia da volta) | 22 | quando cabe | `data/missoes.dart:301-307` [O] |
| Presente de volta (2, 3 ou 7+ dias fora) | 12 / 25 / 40 | por retorno | `data/descanso_retencao.dart:215-240` [O] |
| Marcos da trilha (22) | 20 a 500, **3.495 no total** | uma vez cada | `data/progressao.dart:308-472` [O] |

### 1.2 Ralo: para onde saem

Uma saída só: `buy()` (`state.dart:1732-1741`). Sem recompra, sem
consumível, sem serviço. O catálogo (`models.dart:257-505`) [O]:

| Categoria | Itens | Soma | Faixa de preço |
|---|---:|---:|---|
| Objetos de cena (4 coleções) | 22 | 4.130 | 40 – 400 |
| Roupas (cabeça, pescoço, rosto) | 5 | 420 | 60 – 120 |
| Cenários (um por vez) | 4 | 960 | 200 – 280 |
| **Total** | **31** | **5.510** | |

O contrato ainda descreve a loja antiga: "8 itens de posição fixa … Comprar
é a única ação que muda a cena" (`docs/PRODUCT.md:93-94`) [O]. Está
desatualizado desde a L-01 do roadmap (31 itens, colocar/tirar).

### 1.3 Três perfis de uso

Premissas [I], aplicadas dia a dia com as regras do código:

| | Casual | Regular | Engajado |
|---|---|---|---|
| Dias com sessão | 4/semana (seg, ter, qui, sáb) | 6/semana (seg–sáb) | 7/semana |
| Sessões | 1 × 25 min | 3 dias de 50 + 3 de 25 | 25 + 50 todo dia |
| Missões diárias resgatadas | 1 | 2 | 3 |
| Descanso cumprido | nunca | 2×/semana | todo dia |
| Dias abaixo da meta | 2/semana | 4/semana | 6/semana |
| Missões semanais | 0 | 1 | 2 |
| Afagos com XP | 3/dia ativo | 3/dia ativo | 5/dia |

Resultado:

| | Casual | Regular | Engajado |
|---|---:|---:|---:|
| Renda média sem marcos (folhas/dia) | **20,7** | **76,0** | **157,4** |
| Folhas acumuladas no dia 30 (com marcos) | 1.216 | 4.222 | 6.637 |
| Folhas acumuladas no dia 90 | 2.447 | 9.826 | 17.542 |
| Folhas acumuladas no dia 365 | 8.137 | 31.226 | 60.963 |
| Dia em que dá para comprar **a loja inteira** (5.510) | **239** | **45** | **25** |
| Primeira compra possível (40) | dia 1 | dia 1 | dia 1 |
| Trilha completa (22 passos) | **nunca** — para no passo 10 | dia 116 | dia 50 |
| Sobra no fim do ano 1, já com tudo comprado | ~2.600 | ~25.700 | ~55.400 |

Composição da renda diária (sem marcos):

| Fonte | Casual | Regular | Engajado |
|---|---:|---:|---:|
| Missões diárias | 10,7 (52%) | 32,0 (42%) | 56,1 (36%) |
| Sessões | 5,7 (28%) | 15,0 (20%) | 35,0 (22%) |
| Descanso | 0 | 8,6 (11%) | 30,0 (19%) |
| Missões semanais | 0 | 11,8 (16%) | 23,6 (15%) |
| Bônus abaixo da meta | 4,3 (21%) | 8,6 (11%) | 12,9 (8%) |

Leituras [I]:

- **A missão é a maior torneira**, não a sessão de foco. Isso é bom (missão
  já é desenhada para o comportamento certo), mas quer dizer que qualquer
  mudança no pool de missões mexe mais na economia que mudar o preço da
  sessão.
- **O casual bate num muro na trilha.** Com 4 dias por semana e um
  congelamento, a melhor sequência dele é 4 dias. O passo 11
  (`semana_inteira`, 7 dias seguidos, `progressao.dart:372-377`) não tem
  critério alternativo, então a corrente para ali e a renda de marcos dele
  congela em 565 folhas. Isto é assunto do laudo de jornada, mas pesa aqui:
  o casual depende 100% da renda diária. (Inferência do simulador; vale
  conferir com dados reais.)
- **O marco paga demais para o engajado no começo**: 3.495 folhas em 50 dias,
  63% do preço da loja inteira (o relatório de agosto já apontava isso).

### 1.4 O que acontece depois da loja

Quando tudo foi comprado, o cartão de destaque diz "Tudo o que existe aqui
já é seu." (`l10n_loja.dart:60`, `shop_screen.dart:373-394`) e a home mostra
"Habitat completo". Daí em diante cada folha ganha é número sem destino
[O]. O engajado chega aí no dia 25, ainda dentro do primeiro mês. Um
saldo que só cresce ensina que folha não vale nada, e aí a recompensa de
missão, descanso e sessão perde o peso que sustenta o hábito [I].

### 1.5 A loja como ela está (06-loja.png, 01-home.png)

- [O] O título da tela é **"Habitat"** (`l10n.dart:975`, `'shopT':
  'Habitat'`), o mesmo nome da aba de baixo. Quem toca para "ir à loja" cai
  numa tela chamada Habitat.
- [O] O topo é bom: saldo grande, filtros "Tudo / Dá para levar / Meus itens",
  destaque "DÁ PARA LEVAR AGORA — Noite estrelada" com botão de preço. A
  regra do destaque (o mais caro que o saldo já alcança) está certa
  (`shop_screen.dart:355-366`).
- [O] As miniaturas pintam a cena real (L-02), mas os itens em si são
  primitivos: "Vitórias-régias" são duas pílulas verdes; "Juncos da margem"
  são três barras e um retângulo marrom; na home, o deque é uma barra com
  duas pernas e a pedra é um retângulo cinza arredondado (`01-home.png`).
  É a queixa nº 2 do dono ("elementos gráficos desconexos e amadores").
- [O] Nota de rodapé: "Os itens ocupam um lugar fixo no habitat. Reorganizar
  vem depois." (`l10n.dart:977-978`).
- [O] Contador "2/22" por seção dá cara de coleção, mas completar uma seção
  não dá nada.

### 1.6 Defeitos e lacunas encontrados

| # | O quê | Onde | Efeito |
|---|---|---|---|
| E1 | `Carteira.proximoItem` diz "o mais barato que ainda não foi comprado" mas devolve o **primeiro do catálogo** | `data/carteira.dart:133-139` | Em `10-folhas.png` aparece "Dá para comprar Bambuzal agora" (70) quando o Chapéu de palha (60) é mais barato. É o B8 de agosto, ainda aberto. A home usa outra regra (`state.dart:1041-1045`). |
| E2 | Extrato sem descanso, bônus de meta, retomada e presente de volta | `data/carteira.dart:41` (enum com 4 origens), `:85-87` (só `poolDiario`+`poolSemanal`) | 27% da renda do engajado não aparece em "De onde vieram". |
| E3 | Bônus de meta só vira `SnackBar` | `state.dart:2236` | Recompensa diária anunciada no componente mais fraco da tela. |
| E4 | Compra sem som, háptico ou celebração | `state.dart:1732-1741`; `som_service.dart:24-51` | O momento de gastar, que fecha o ciclo foco → folhas → habitat, passa em silêncio. |
| E5 | A chegada com mola do item roda fora de vista | `habitat.dart:406-445`, `:622-650` | O usuário compra na loja; a animação acontece (ou não) no habitat da home, por baixo. Na remontagem com mais de 1 item ela é pulada (`habitat.dart:435-437`). Conferir em aparelho. |
| E6 | Compras e marcos sem data | `data/carteira.dart:32, 104-117` | Não dá para montar linha do tempo nem recibo. |
| E7 | O paywall promete "a loja completa do habitat" | `l10n.dart:884-885` | Nada no código restringe a loja a assinantes, e a cobrança está desligada (`cobranca.dart:7`). Quando a cobrança ligar, a promessa vira decisão de produto, não só texto. |
| E8 | Contrato desatualizado | `docs/PRODUCT.md:93-94` | "8 itens", "comprar é a única ação que muda a cena". |

---

## 2. Pesquisa com fontes

### 2.1 Duolingo — gems e loja

- [F] Gems são a moeda do app e se gastam na Shop ([blog, Duolingo 101](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/)).
- [F] A conta gratuita guarda até **2 Streak Freezes**; a captura da loja no
  mesmo post mostra Timer Boost a 450 gems e pacotes de 1.200, 3.000 e
  6.500 gems à venda ([blog, streak nas férias](https://blog.duolingo.com/how-to-keep-your-streak-on-vacation/)).
- [F] Em 2023 a assinatura respondeu por US$ 404,7 mi de US$ 531,1 mi de
  receita (~76%); compras avulsas são "benefícios únicos" como Streak Freezes
  e Timer Boosts ([relatório anual 2023, SEC](https://www.sec.gov/Archives/edgar/data/1562088/000156208824000093/duolingodecember312023an.htm)).
- [F] O reparo pago de streak é citado no catálogo de padrões enganosos do
  deceptive.design, com a ressalva de que os exemplos são enviados pelo
  público e não verificados ([deceptive.design](https://www.deceptive.design/articles/when-a-user-uses-duolingo-on-a-series-of-consecutive-days-this-is-called-a-streak-if-users-miss-a-day-they-can-pay-to-repair-it)).
- **Lição para o Baru [I]:** o sumidouro-âncora do Duolingo é proteção de
  streak, e ele tem teto (2 guardados). Dá para copiar com folhas (proteção,
  não punição). A parte que não se copia é vender a moeda e vender o
  conserto da streak por dinheiro: a receita grande está na assinatura, e é
  ali que a crítica pública mira.

### 2.2 Finch — rainbow stones, roupas e móveis

- [F] O hábito cumprido rende *rainbow stones*, que compram roupas e móveis
  para o pássaro ([Internet Matters, resumo em resultado de busca](https://www.internetmatters.org/advice/apps-and-platforms/wellbeing/finch/);
  página não abriu para leitura direta, 403).
- [F] A central de ajuda do Finch diz que, exceto a agência de viagem, as
  lojas têm "uma seleção de itens raros a cada dia" e que dá para pagar
  stones para trocar a seleção ([help.finchcare.com](https://help.finchcare.com/hc/en-us/articles/37935977276813-Shops-in-Finch-Outfits-Travel-and-More);
  lida via resultado de busca, a página retornou 403).
- [F] Segundo a wiki de fãs, a loja gira a cada 24 h junto com o dia do
  pássaro, a primeira troca manual do dia é grátis e as seguintes custam
  10 e depois sobem de 25 em 25 até 160 ([Finch Wiki](https://finch.fandom.com/wiki/Mr._Prickles'_Shop);
  wiki não oficial, 402 na leitura direta, dados do resultado de busca).
- [F] Os criadores evitaram a morte do bicho de propósito, por ser
  "ansiogênico demais" (FAQ do Finch, via [resultado de busca](https://befinch.notion.site/Finch-FAQ-474652d0123d4883ac7a0cd6c8f5aa70)).
- **Lição [I]:** é o vizinho mais próximo do Baru (bicho + autocuidado + sem
  morte). O motor de retorno da loja é a **vitrine diária de raros**, não
  o catálogo inteiro aberto. A troca paga em escada é sumidouro, mas com cara
  de caça-níquel; no Baru eu não copiaria a troca paga.

### 2.3 Animal Crossing: New Horizons — catálogo e sazonalidade

- [F] Itens sazonais ficam numa aba própria do catálogo, travados pela data
  real, giram por dia, e cada evento dura cerca de um mês ([GameSpot](https://gamespot.com/articles/new-animal-crossing-seasonal-items-now-available/1100-6495009/);
  [Nintendo Life](https://www.nintendolife.com/news/2020/06/animal_crossing_new_horizons_adds_cute_summer_and_winter-solstice_seasonal_items)).
- [F] As estações se invertem por hemisfério; Austrália e América do Sul
  ficam no hemisfério sul por padrão, e a pessoa pode escolher ([Nookipedia](https://nookipedia.com/wiki/Hemisphere);
  [Prima Games](https://primagames.com/tips/animal-crossing-new-horizons-north-hemisphere-or-south)).
- [F] O sumidouro grande da série é a casa: um ensaio estima ~6 milhões de
  bells da menor casa até a última reforma ([Wealthsimple](https://www.wealthsimple.com/en-us/magazine/animal-crossing);
  é texto opinativo, não medição).
- **Lição [I]:** (1) o sumidouro aspiracional é **um projeto grande em
  etapas** que a pessoa vê crescer; (2) sazonal é calendário real e
  **volta todo ano**; (3) o Baru é majoritariamente brasileiro e o Brasil
  está no hemisfério sul. Hoje o app vende "Neve" e "Folhas de outono" sem
  calendário; se virarem sazonais, dezembro é verão aqui.

### 2.4 Neko Atsume — goodies e gatos que escolhem

- [F] Os gatos deixam peixes (prata e ouro) como presente, e os peixes compram
  os goodies; gatos raros aparecem por goodies específicos (ex.: Joe DiMeowgio
  e a bola de beisebol) ([iMore](https://imore.com/neko-atsume-game-guide-how-collect-all-cats); [Daily Dot](https://dailydot.com/neko-atsume-cat-collecting-guide)).
- [F] Na versão 2 há goodies limitados vendidos só em certos meses, que voltam
  no ano seguinte, e a estação segue o hemisfério do jogador (wiki e FAQ de
  comunidade, [Neko Atsume Wiki](https://nekoatsume.fandom.com/wiki/Neko_Atsume_2)).
- **Lição [I]:** o objeto vale pelo **comportamento que provoca no bicho**. É
  a peça que falta no Baru: aqui o item é cenário, lá é isca de cena. Os
  "favoritos por espécie" da seção 3.4 vêm daqui.

### 2.5 Pou — o que não copiar

- [F] Moedas vêm de minijogos e compram comida, roupas, chapéus, brinquedos e
  papel de parede; há compra de moedas com dinheiro ([SourceForge, descrição da loja](https://sourceforge.net/app/pou-tm/iphone/);
  [MobyGames](https://www.mobygames.com/game/pou)).
- **Lição [I]:** comida como **necessidade** (barra de fome) é punição
  disfarçada e está fora do contrato do Baru. Petisco no Baru só pode ser
  **mimo**: nenhum medidor cai sem ele.

### 2.6 Forest — o concorrente mais parecido

- [F] Moedas vêm das sessões de foco e compram espécies de árvore e outros
  itens; com elas também se patrocina o plantio de árvores reais pela Trees for
  the Future, que passou de 2 milhões ([Wikipedia](https://en.wikipedia.org/wiki/Forest_(application))).
- [F] Pelo site oficial, plantar árvore real com moedas é recurso do plano
  Plus, limitado a 5 por conta, e "a Forest cobre o custo com a receita do
  app" ([forestapp.cc](https://www.forestapp.cc/)).
- [F] No Forest, sair do app durante o foco faz a árvore murchar
  ([Wikipedia](https://en.wikipedia.org/wiki/Forest_(application))).
- **Lição [I]:** o bosque como sumidouro infinito e com significado já foi
  provado por um app de foco. O Baru pode ter o bosque **sem a árvore
  morta**: plantou, cresce, nunca murcha.

### 2.7 Princípios de economia e de ética

- **Torneiras e ralos.** [F] Moeda virtual é criada e destruída por código.
  Quando entra mais do que sai há inflação; ralo demais frustra. Ralo
  aspiracional (um objetivo grande para o qual se junta) tira moeda de
  circulação "sem parecer punição" ([Medium, Sahin](https://medium.com/@msahinn21/designing-game-economies-inflation-resource-management-and-balance-fa1e6c894670);
  [resumo de *Virtual Economies*, Lehdonvirta & Castronova](https://www.antoinebuteau.com/virtual-economies-book-summary/)).
  São textos de praticante. A ideia é consenso; não uso número deles.
- **Padrões sombrios em jogos.** [F] Zagal, Björk e Lewis (FDG 2013)
  classificam padrões sombrios em temporais, monetários e de capital social,
  incluindo o "jogar com hora marcada" ([Chalmers](https://research.chalmers.se/en/publication/177148);
  [deceptive.design](https://www.deceptive.design/articles/dark-patterns-in-the-design-of-games)).
  Uma crítica de 2020 aponta que a taxonomia não tem base empírica
  ([DiGRA 2020](https://eprints.whiterose.ac.uk/156460/1/DiGRA_2020_paper_189.pdf)).
- **Caixa-surpresa paga.** [F] Uma metanálise acha correlação pequena a
  moderada entre gasto em loot box e sintomas de jogo problemático, r = 0,26
  ([Univ. da Tasmânia, metanálise](https://figshare.utas.edu.au/articles/journal_contribution/Meta-analysis_of_the_relationship_between_problem_gambling_excessive_gaming_and_loot_box_spending/22996898/1/files/40746986.pdf));
  correlação não prova causa ([Zendle, PeerJ](https://peerj.com/articles/7700.pdf)).
  A Google Play exige mostrar as chances antes da compra de qualquer item
  aleatório ([Play Console, Pagamentos](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en)),
  e no Brasil o ECA Digital (Lei 15.211/2025, art. 20, em vigor desde
  17/03/2026) proíbe loot boxes em jogos direcionados a crianças e
  adolescentes ou de provável acesso por eles ([Play Console, requisitos por país](https://support.google.com/googleplay/android-developer/answer/6223646?hl=en);
  [Machado Meyer](https://www.machadomeyer.com.br/images/ebooks/Factsheet_ECA_Digital.pdf);
  [Poder360](https://www.poder360.com.br/poder-governo/eca-digital-entra-em-vigor-nesta-3a-feira-entenda-o-que-muda/)).
  Um bicho fofo é "de provável acesso" por menor [I].
- **Coleções e progresso.** [F] Gradiente de meta: quanto mais perto do
  prêmio, mais rápido as pessoas agem (café "compre 10"), e progresso dado de
  graça acelera a conclusão (Kivetz, Urminsky e Zheng, *JMR* 2006,
  [Columbia](https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal)).
  O efeito do progresso dotado (Nunes e Drèze, *JCR* 2006) é a mesma
  família ([Coglode, resumo](https://www.coglode.com/nuggets/endowed-progress-effect)).
- **Personalização gera apego.** [F] O "efeito IKEA": as pessoas valorizam
  mais o que ajudaram a montar, e o efeito some quando a obra é desfeita ou
  fica incompleta (Norton, Mochon e Ariely, *JCP* 2012,
  [Harvard DASH](https://dash.harvard.edu/handle/1/12136084)).
- **Suco.** [F] "Juice it or lose it" (Jonasson e Purho, GDC Europe 2012):
  interpolação, esticar e encolher, partículas e som fazem a ação simples
  parecer viva ([Game Developer](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-)).
- **Mola em Flutter.** [F] `SpringSimulation` + `SpringDescription`
  (inclusive `withDampingRatio` e `withDurationAndBounce`) rodam com
  `AnimationController.animateWith`
  ([api.flutter.dev](https://api.flutter.dev/flutter/physics/SpringSimulation-class.html);
  [SpringDescription](https://api.flutter.dev/flutter/physics/SpringDescription-class.html)).
- **O baru é uma árvore.** [F] *Dipteryx alata*, árvore do Cerrado de cerca de
  15 m, com castanha comestível e frutificação entre setembro e outubro
  ([Embrapa](https://www.alice.cnptia.embrapa.br/bitstream/doc/1074669/1/baru.pdf);
  [Correio Braziliense](https://www.correiobraziliense.com.br/cidades-df/2024/05/6854384-baru-o-superalimento-do-cerrado-e-nutritivo-e-ja-conquista-novos-mercados.html)).
  O app tem o nome de uma árvore e não vende a árvore [O/I].

### 2.8 O que não achei

- Preço atual oficial do Streak Freeze e do reparo no Duolingo: só achei
  guias de terceiros com números divergentes. Não uso.
- Quantas stones o Finch paga por tarefa: nenhuma fonte confiável.
- Dados de retenção que meçam o efeito de loja rotativa ou de coleção em app
  de bem-estar: não achei estudo público. As recomendações abaixo que
  dependem disso estão marcadas como inferência e pedem teste.

---

## 3. Proposta

### 3.1 Regras de desenho da economia (o "contrato" da loja)

1. **Folha não se compra com dinheiro. Nunca.** Ela é a prova de tempo longe
   da tela; vendê-la apagaria o sentido do app [I].
2. **Nada sai do habitat.** Item comprado é para sempre; sazonal sai da
   *vitrine*, nunca do inventário. Nada estraga, quebra ou murcha.
3. **Consumível é mimo, nunca necessidade.** Nenhum medidor cai por falta de
   petisco. Petisco não dá XP nem folha (senão vira fazenda de recurso).
4. **Nada some para sempre.** Item da feira volta em até 8 semanas; sazonal
   volta no ano seguinte; a etiqueta diz quando. Escassez real só nas
   relíquias de marco, que não se compram.
5. **Sem aleatório à venda.** Presente surpresa só de graça (marco, coleção,
   volta), e com conteúdo fixo por evento.
6. **O saldo é sempre um pouco menor que o desejo.** O catálogo cresce por
   atualização, e o Bosque não tem teto.
7. **Todo crédito tem origem visível** e vira linha datada no extrato.
8. **Todo item faz o bicho fazer alguma coisa.** Item que só fica parado só
   entra se for base de outro (tapete, cerca).

Mudança de contrato necessária: `PRODUCT.md` §5 precisa de ADR para
(a) atualizar o catálogo descrito, (b) admitir consumíveis e brinquedos que
mudam a cena por alguns segundos, e (c) registrar as regras 1–5 acima.
Nenhuma regra inviolável muda.

### 3.2 Curva de preços

Preço medido em **dias de renda** de cada perfil (renda sem marcos: casual
20,7; regular 76; engajado 157):

| Faixa | Preço | Casual | Regular | Engajado | Papel |
|---|---:|---:|---:|---:|---|
| Petisco (consumível) | 8 – 40 | 0,4 – 1,9 d | ≤ 0,5 d | ≤ 0,25 d | mimo diário, sumidouro pequeno e constante |
| Comum | 40 – 90 | 2 – 4 d | 0,5 – 1,2 d | 0,3 – 0,6 d | a compra da semana do casual |
| Incomum | 100 – 200 | 5 – 10 d | 1,3 – 2,6 d | 0,6 – 1,3 d | meta de curto prazo |
| Raro | 220 – 450 | 11 – 22 d | 3 – 6 d | 1,4 – 2,9 d | meta do mês do casual |
| Especial / obra | 500 – 1.500 | 24 – 72 d | 7 – 20 d | 3 – 10 d | projeto aspiracional |
| Muda do Bosque | 250 (fixo, sem teto) | 12 d | 3,3 d | 1,6 d | sumidouro infinito do topo |

Regras da curva [I]:

- **Toda prateleira começa com um item ≤ 90.** O casual sempre vê algo ao
  alcance da semana.
- **Preço fixo, igual para todos.** Preço que sobe com o nível da pessoa é
  justo na planilha e injusto na cabeça de quem usa.
- **Não cortar torneiras.** O desequilíbrio do topo se resolve com ralo; tirar
  renda de quem já se acostumou parece castigo, mesmo sem violar o contrato.
- **Distribuição alvo do catálogo permanente:** ~30% comum, ~45% incomum,
  ~20% raro, ~5% especial. Os 66 permanentes propostos abaixo ficam em
  32% / 39% / 24% / 5% (21 / 26 / 16 / 3 itens).

### 3.3 Catálogo proposto (86 itens novos, mais os 31 que já existem)

Os 31 atuais **ficam** com o mesmo preço. Não se reprecifica item que alguém
já comprou: a pessoa veria o "valor" da compra mudar.

Quatro observações sobre o que existe [I]:

- **"Neve", "Folhas de outono" e "Cerejeira"** passam a ser **itens de
  calendário visual**: comprados uma vez, ficam ativos, e o desenho segue a
  estação real do hemisfério (neve só no inverno local; cerejeira floresce na
  primavera local e fica verde no resto do ano). Assim a coleção "Estações"
  vira o relógio do ano sem tirar nada de ninguém.
- **Os 22 objetos ganham a mesma regra do item 8 da seção 3.1** aos poucos:
  o barquinho leva o bicho para passear, o deque vira lugar de sentar, a
  ponte vira travessia, a fogueira esquenta as mãos à noite.
- **Arte.** Os novos itens não devem nascer como `ShapePart`. A arte deve
  vir do mesmo pipeline que o laudo de visual escolher (vetor/`CustomPainter`
  com volume, ou Rive para os interativos). Itens novos em retângulo
  repetem a queixa nº 2.
- **Roupas novas** exigem silhueta por espécie em `pet.dart` (ROADMAP L-01),
  então custam 9 desenhos cada. O slot novo "costas" é G.

Legenda: "Onde aparece" é a zona da cena de 372×296 (`models.dart:239-256`).
"Consumível: sim" = some ao usar. "Favorito de" = espécie que reage com mais
festa (seção 3.4).

#### Beira d'água (11 itens, 2260 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 1 | Aguapés em flor | 60 | Comum | água da frente, esquerda | não | — | derivam com a corrente; ao nadar perto, o bicho cheira a flor e espirra | — |
| 2 | Pedrinha favorita | 50 | Comum | na mão/nadadeira, ao boiar | não | — | boia de costas segurando a pedra sobre a barriga | lontra |
| 3 | Tronco boiando | 120 | Incomum | água do meio, à direita | não | — | em "nadar", o bicho sobe e boia sentado no tronco | — |
| 4 | Sapinho da pedra | 140 | Incomum | sobre a Pedra da fonte | não | — | coaxa ao anoitecer; o bicho vira a cabeça e pisca | — |
| 5 | Libélulas | 180 | Incomum | sobre a água, de dia | não | — | voam em 8; o bicho acompanha com os olhos (rastreio da cabeça) | — |
| 6 | Vara de bambu | 200 | Incomum | margem direita | não | — | em "pastar", vira "pescar": linha balança, peixinho pula 1x | lontra, pinguim, gata |
| 7 | Jardim de algas | 150 | Incomum | fundo da água, à esquerda | não | — | algas ondulam; o axolote se esconde e espia | axolote |
| 8 | Escorregador de barro | 260 | Raro | barranco da margem esquerda | não | — | toque: o bicho escorrega e cai na água com respingo | lontra, pinguim |
| 9 | Laguinho de lama | 180 | Incomum | margem, perto do bicho | não | — | em "cochilar", banho de lama com olhos semicerrados | capivara |
| 10 | Vitória-régia gigante | 320 | Raro | água da frente, centro-esquerda | não | — | a flor abre ao entardecer e fecha de manhã (luz da cena) | — |
| 11 | Moinho d'água | 600 | Especial | fio d'água da colina direita | não | — | roda gira sempre; som de água opcional; o bicho olha a roda | — |

#### Mata (11 itens, 2360 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 12 | Flores do campo | 50 | Comum | margem, entre itens | não | — | balançam ao vento; o bicho cheira e espirra | — |
| 13 | Cerca de bambu | 70 | Comum | fundo da margem | não | — | estática; emoldura a cena | — |
| 14 | Toco com musgo | 80 | Comum | margem esquerda | não | — | em "parado", o bicho apoia o queixo no toco | — |
| 15 | Trilha de formigas | 90 | Comum | areia da margem | não | — | formigas andam em fila; o bicho segue com o focinho | — |
| 16 | Bromélia | 110 | Incomum | tronco da Árvore antiga | não | — | um beija-flor visita 1x por hora de app aberto | — |
| 17 | Montinho de folhas | 120 | Incomum | margem direita | não | — | toque: o bicho mergulha de cabeça no monte | raposa |
| 18 | Cantinho de sol | 120 | Incomum | pedra lisa na margem | não | — | de dia, o bicho se estica ao sol (pose de aquecer) | tartaruga |
| 19 | Balanço de corda | 240 | Raro | galho da Árvore antiga | não | — | toque: o bicho balança 3 vezes | — |
| 20 | Pé de jabuticaba | 300 | Raro | margem esquerda, fundo | não | — | frutinhas aparecem; 1x por dia o bicho colhe uma e ela vira petisco grátis | — |
| 21 | Ipê-amarelo | 380 | Raro | colina esquerda | não | — | fica verde fora da floração e amarelo na época (calendário real, por hemisfério) | — |
| 22 | Pé de baru | 800 | Especial | colina direita, grande | não | — | dá frutos na época; o bicho cata castanha do chão; árvore-símbolo do app | — |

#### Céu e noite (8 itens, 2140 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 23 | Pipa | 90 | Comum | céu, de dia | não | — | dança no vento; o bicho olha para cima e acompanha | — |
| 24 | Móbile de lua | 120 | Incomum | pendurado na Árvore antiga | não | — | gira devagar; brilha à noite | — |
| 25 | Lanternas de papel | 200 | Incomum | fio sobre a margem | não | — | acendem ao anoitecer, uma por vez | — |
| 26 | Estrela cadente | 260 | Raro | céu noturno | não | — | 1 por noite com o app aberto; o bicho fecha os olhos e "faz um pedido" | — |
| 27 | Arco-íris | 300 | Raro | céu | não | — | aparece depois de cada sessão concluída e depois do cenário Chuva; o bicho pula | — |
| 28 | Telescópio | 420 | Raro | margem direita | não | — | à noite o bicho olha pelo telescópio; constelação desenhada aparece | coruja |
| 29 | Cenário: Cerrado ao amanhecer | 300 | Raro | cena inteira (cenário) | não | — | luz dourada baixa e capim; precisa de entrada em LuzDaCena | — |
| 30 | Cenário: Aurora | 450 | Raro | cena inteira (cenário) | não | — | faixas de luz ondulando no céu; o bicho olha para cima | — |

#### Casa e cantinho (13 itens, 2590 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 31 | Caixa de papelão | 60 | Comum | margem esquerda | não | — | o bicho entra e só as orelhas ficam de fora | gata |
| 32 | Cama de folhas secas | 80 | Comum | areia da margem | não | — | em "cochilar", o bicho deita na cama em vez da areia | — |
| 33 | Tapete de palha | 90 | Comum | areia da margem | não | — | estático; base para os outros itens do cantinho | — |
| 34 | Bule e xícaras | 110 | Incomum | sobre o tapete | não | — | vapor sobe; de manhã o bicho "toma chá" | — |
| 35 | Almofada de crochê | 120 | Incomum | sobre o tapete | não | — | em "parado", o bicho senta na almofada | — |
| 36 | Abajur de cabaça | 140 | Incomum | ao lado da cama | não | — | acende à noite; luz quente na cena | — |
| 37 | Cobertor xadrez | 150 | Incomum | cama/rede | não | — | à noite o bicho se enrola no cobertor | — |
| 38 | Caminha redonda | 150 | Incomum | margem direita | não | — | o bicho gira 3x antes de deitar | buldogue |
| 39 | Quadro da raiz | 180 | Incomum | tronco da árvore/poste | não | — | mostra o número da maior raiz e o passo da trilha (dados do usuário) | — |
| 40 | Rádio de pilha | 200 | Incomum | sobre o tapete | não | — | toque: toca trilha ambiente curta; o bicho balança a cabeça | — |
| 41 | Estante de livros | 260 | Raro | margem esquerda | não | — | durante a sessão de foco, o bicho lê um livro | coruja |
| 42 | Rede de descanso | 350 | Raro | entre a Árvore antiga e um poste | não | — | em "cochilar", dorme na rede balançando | — |
| 43 | Toca de madeira | 700 | Especial | margem direita | não | — | o bicho entra e sai; a janela acende à noite | — |

#### Roupas e acessórios (13 itens, 1640 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 44 | Laço de fita (cabeça) | 50 | Comum | no bicho | não | — | ao vestir: gira e "se olha no espelho" | — |
| 45 | Flor na orelha (cabeça) | 60 | Comum | no bicho | não | — | a flor balança quando o bicho anda | — |
| 46 | Bandana (pescoço) | 60 | Comum | no bicho | não | — | pontas tremulam ao nadar | — |
| 47 | Gravata-borboleta (pescoço) | 80 | Comum | no bicho | não | — | ao vestir: o bicho "ajusta" a gravata | — |
| 48 | Boné (cabeça) | 90 | Comum | no bicho | não | — | pala vira para trás ao correr | — |
| 49 | Laranjinha na cabeça (cabeça) | 90 | Comum | no bicho | não | — | equilibra a laranja; ao banhar, ela boia ao lado | capivara |
| 50 | Óculos escuros (rosto) | 110 | Incomum | no bicho | não | — | ao vestir: o bicho faz pose | — |
| 51 | Colar de sementes (pescoço) | 130 | Incomum | no bicho | não | — | sementes tilintam (som suave) ao andar | — |
| 52 | Fone de ouvido (cabeça) | 150 | Incomum | no bicho | não | — | durante o foco, o bicho fecha os olhos e balança a cabeça | — |
| 53 | Monóculo (rosto) | 160 | Incomum | no bicho | não | — | pisca o olho do monóculo ao ser tocado | coruja |
| 54 | Máscara de mergulho (rosto) | 180 | Incomum | no bicho | não | — | em "nadar", mergulha e solta bolhas | lontra, pinguim, axolote |
| 55 | Mochilinha (costas, slot novo) | 220 | Raro | no bicho | não | — | ao vestir: o bicho dá uma voltinha mostrando a mochila | — |
| 56 | Capa de chuva amarela (costas, slot novo) | 260 | Raro | no bicho | não | — | com o cenário Chuva, pula em poça | — |

#### Petiscos (12 itens, 485 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 57 | Folhinha de capim | 8 | Comum | arrastar até a boca | sim | — | mastiga 3x; migalhas verdes | capivara, tartaruga |
| 58 | Minhoquinha | 12 | Comum | arrastar até a boca | sim | — | engole de uma vez e lambe os lábios | axolote, coruja |
| 59 | Biscoito de osso | 12 | Comum | arrastar até a boca | sim | — | crec-crec; abana o corpo | buldogue |
| 60 | Peixinho | 15 | Comum | arrastar até a boca | sim | — | pega no ar e engole | lontra, pinguim, gata |
| 61 | Fatia de melancia | 15 | Comum | arrastar até a boca | sim | — | come até a casca; sementinha voa | — |
| 62 | Jabuticabas | 15 | Comum | arrastar até a boca | sim | — | uma por vez, bochecha estufa | — |
| 63 | Água de coco | 15 | Comum | arrastar até a boca | sim | — | canudinho; olhos fecham de prazer | — |
| 64 | Pão de queijo | 15 | Comum | arrastar até a boca | sim | — | sopra antes (está quente) | — |
| 65 | Morangos | 18 | Comum | arrastar até a boca | sim | — | bigode vermelho depois | raposa |
| 66 | Castanha de baru | 20 | Comum | arrastar até a boca | sim | — | quebra a casca com os dentes | capivara, raposa |
| 67 | Bolo de aniversário | 40 | Incomum | no aniversário do bicho | sim | — | sopra a vela; confete; foto para compartilhar | — |
| 68 | Toalha de piquenique | 300 | Raro | margem (permanente) | não | — | destrava "comer junto": todo petisco vira cena na toalha | — |

#### Brinquedos (9 itens, 960 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 69 | Graveto | 40 | Comum | margem | não | — | toque: o graveto voa; o bicho busca e traz | buldogue, raposa |
| 70 | Pedrinhas de quicar | 60 | Comum | margem | não | — | toque: pedra quica 3x na água; o bicho comemora | lontra |
| 71 | Bola de folhas | 70 | Comum | areia da margem | não | — | toque/arrasto: a bola rola com física; o bicho empurra com o focinho | — |
| 72 | Novelo de lã | 80 | Comum | areia da margem | não | — | toque: rola desenrolando; o bicho persegue | gata |
| 73 | Cata-vento | 90 | Comum | fincado na margem | não | — | gira com o vento e mais rápido ao toque | — |
| 74 | Peão de madeira | 100 | Incomum | areia da margem | não | — | toque: gira 4 s; o bicho fica tonto olhando | — |
| 75 | Soprador de bolhas | 120 | Incomum | margem | não | — | toque: bolhas sobem; o bicho tenta estourar | — |
| 76 | Bloco de gelo | 140 | Incomum | margem direita | não | — | o bicho escorrega de barriga | pinguim |
| 77 | Pula-pula de folha | 260 | Raro | margem esquerda | não | — | toque: o bicho pula 3x, cada vez mais alto | — |

#### Sazonais (voltam todo ano) (9 itens, 1170 folhas no total)

| # | Item | Preço | Raridade | Onde aparece | Consumível | Sazonal | O que dispara no bicho | Favorito de |
|---|---|---:|---|---|---|---|---|---|
| 78 | Bandeirinhas juninas | 150 | Incomum | fio sobre a margem | não | jun (BR) | tremulam; o bicho dá pulinhos de quadrilha | — |
| 79 | Chapéu de palha remendado (cabeça) | 120 | Incomum | no bicho | não | jun (BR) | ao vestir: dá um "arrasta-pé" | — |
| 80 | Pamonha | 20 | Comum | arrastar até a boca | sim | jun (BR) | desembrulha a palha antes de comer | — |
| 81 | Coroa de flores (cabeça) | 140 | Incomum | no bicho | não | primavera (por hemisfério) | pétalas caem devagar | — |
| 82 | Abóbora entalhada | 160 | Incomum | margem | não | outono (por hemisfério) | acende à noite; o bicho espia dentro | — |
| 83 | Lanternas do meio-outono | 200 | Incomum | fio sobre a água | não | Festival do Meio-Outono (zh) | refletem na água; lua cheia maior | — |
| 84 | Sorvete de açaí | 20 | Comum | arrastar até a boca | sim | verão (por hemisfério) | congela o cérebro: olhos apertados | — |
| 85 | Gorro de festa vermelho (cabeça) | 140 | Incomum | no bicho | não | dez | pompom balança | — |
| 86 | Fogos de luz silenciosos | 220 | Raro | céu noturno | não | 31 dez–6 jan | luzes abrem sem estampido; o bicho olha maravilhado | — |

**Resumo do catálogo proposto:** 86 itens novos. São 66 permanentes
(12.250 folhas), 13 petiscos consumíveis (8 a 40 cada) e 7 sazonais não
consumíveis (1.130 folhas por ano). Com os 31 atuais, o catálogo permanente
vai a 97 itens e 17.760 folhas.

**Quanto tempo isso dura (simulador, mesmas premissas da seção 1.3):**

| | Casual | Regular | Engajado |
|---|---:|---:|---:|
| Catálogo atual (5.510) | dia 239 | dia 45 | dia 25 |
| Catálogo atual + proposto (17.760) | depois do ano 1 | dia 188 | **dia 91** |
| Sobra no fim do ano 1 só com o catálogo | não sobra | ~12.300 | ~42.000 |

Por isso a seção 3.7 existe: catálogo maior empurra o problema três meses
para frente, mas não resolve.

### 3.4 Favoritos por espécie

Cada espécie tem itens e petiscos favoritos. Com um favorito a reação é
maior: coração, a animação longa do item e uma fala própria. Na primeira
vez ele é **descoberto** e entra no "Caderno do [nome]" (ex.: "Descobriu:
Rio adora peixinho"). É o mecanismo do Neko Atsume (seção 2.4) trocado de
"isca" para "carinho". Os laudos 06/07/08 vão sugerir itens temáticos por
espécie. Aqui o favorito é só **uma lista de ids por espécie** no dado do
item, então dá para acrescentar o que eles propuserem sem mexer em preço nem
curva.

| Espécie | Itens favoritos | Petisco favorito |
|---|---|---|
| Capivara (Baru) | Laguinho de lama, Laranjinha na cabeça | Folhinha de capim, Castanha de baru |
| Lontra (Rio) | Pedrinha favorita, Vara de bambu, Escorregador, Pedrinhas de quicar, Máscara de mergulho | Peixinho |
| Tartaruga (Toco) | Cantinho de sol | Folhinha de capim |
| Coruja (Nina) | Telescópio, Estante de livros, Monóculo | Minhoquinha |
| Axolote (Lume) | Jardim de algas, Máscara de mergulho | Minhoquinha |
| Pinguim (Nino) | Bloco de gelo, Escorregador, Vara de bambu, Máscara de mergulho | Peixinho |
| Gata (Mel) | Caixa de papelão, Novelo de lã, Vara de bambu | Peixinho |
| Raposa (Faísca) | Montinho de folhas, Graveto | Morangos, Castanha de baru |
| Buldogue (Bolota) | Caminha redonda, Graveto | Biscoito de osso |

Regra: o favorito **não é exclusivo**. Qualquer espécie usa qualquer item; o
favorito só reage com mais festa. Item travado por espécie faria quem troca
de espécie sentir que perdeu algo, e isso fere o §1 [I].

### 3.5 Vitrine que gira: banca do dia, feira da semana, sazonais

O catálogo permanente fica **sempre inteiro e visível**: nada do que existe
se esconde para criar urgência. O que gira é uma camada por cima:

**Banca do dia** (3 cartões no topo da loja, troca à meia-noite local)

- Sorteio **determinístico por conta e data**, como as missões (ADR-010; a
  função de hash já existe em `data/missoes.dart:589`). Mesmo dia, mesma
  banca em qualquer aparelho, sem servidor.
- Cartão 1, **"Ao seu alcance"**: um permanente não comprado com preço até
  saldo + 1 dia de renda média da pessoa (média móvel de 7 dias). Responde
  "o que eu levo hoje?" sem filtro.
- Cartão 2, **"Para o [nome]"**: um petisco ou item favorito da espécie ativa.
  Se o favorito ainda não foi descoberto, aparece como "Ele parece curioso
  com isto…".
- Cartão 3, **"Da feira"**: um dos itens da feira da semana.
- **Sem desconto e sem contagem regressiva.** A banca dá um motivo leve para
  abrir a loja todo dia (pedido do brief) sem fabricar urgência.

**Feira da semana** (4 itens, troca na segunda 00:00, junto com as missões
semanais)

- Pool rotativo de variantes: cores alternativas de roupas (`ShopItemDef.cor`
  já existe, `models.dart:231`), edições de objetos (ex.: Barquinho
  vermelho, Lampião de vidro verde) e itens de coleção mais raros.
- Cada item **volta em no máximo 8 semanas**. Ao sair, o cartão diz "Volta
  em ~6 semanas". Nada é "última chance".
- Pool inicial sugerido: 24 variantes, que dão 6 semanas sem repetir.
  Variante custa uma recolorização, não um desenho novo, e a roupa recolorida
  já funciona em `pet.dart`.

**Sazonais por hemisfério** (voltam todo ano)

- Hemisfério padrão pelo idioma/região do aparelho (pt-BR, es-AR/CL/UY: sul;
  o resto: norte) e editável em Ajustes ("Estações do seu lugar"), como o
  Animal Crossing faz (seção 2.3). Chave nova nos 4 idiomas.
- Calendário inicial:

| Janela (sul) | Janela (norte) | Itens |
|---|---|---|
| set – nov (primavera) | mar – mai | Coroa de flores; Cerejeira floresce; Pé de baru frutifica em set–out (frutificação real do baru, seção 2.7) |
| dez – fev (verão) | jun – ago | Sorvete de açaí |
| mar – mai (outono) | set – nov | Abóbora entalhada; Folhas de outono caem |
| jun – ago (inverno) | dez – fev | Neve aparece (item já existente) |
| junho | — (só pt-BR) | Bandeirinhas juninas, Chapéu de palha remendado, Pamonha |
| data lunar do Meio-Outono | idem (zh) | Lanternas do meio-outono |
| dezembro | dezembro | Gorro de festa vermelho |
| 31/12 – 6/1 | idem | Fogos de luz silenciosos |

- A florada do Ipê-amarelo fica presa à época local, mas **não achei fonte
  dos meses**: confirmar com a Embrapa antes de codificar.
- Festa por idioma pede revisão cultural nos 4 idiomas (`TODO-i18n` onde
  houver dúvida, conforme `PRODUCT.md` §2).

### 3.6 Coleções com recompensa

O contador "2/22" de hoje é uma coleção sem prêmio. Proposta: conjuntos
curtos (4 a 6 itens) **dentro** das prateleiras, cada um com um prêmio que
não se compra. A barra mostra "3/5" e a **silhueta do prêmio**: o gradiente
de meta funciona melhor quando o prêmio é visível e perto (seção 2.7). Como
os conjuntos misturam itens que a pessoa já tem, quase todos começam com
progresso, que é o efeito do progresso dotado.

| Coleção | Itens | Prêmio ao completar (não se compra) |
|---|---|---|
| Margem viva | Juncos, Aguapés em flor, Sapinho da pedra, Libélulas, Vitória-régia gigante | **Garça visitante**: pousa na margem de manhã; o bicho a cumprimenta |
| Dia de pesca | Deque, Barquinho, Vara de bambu, Cardume, Pedrinhas de quicar | **Martim-pescador** mergulha de vez em quando; o bicho aplaude |
| Sombra da mata | Árvore antiga, Cogumelos, Samambaia, Toco com musgo, Bromélia | **Sagui** aparece no galho e troca olhares com o bicho |
| Noite acesa | Lampião, Vaga-lumes, Varal de luzes, Fogueira, Lanternas de papel | **Via Láctea** no céu noturno (efeito exclusivo) |
| Cantinho do cochilo | Cama de folhas, Tapete de palha, Almofada, Cobertor xadrez, Abajur | **Sonho**: no cochilo, um balão mostra a última conquista da pessoa |
| Hora do lanche | Provar 6 petiscos diferentes (provar, não comprar todos) | **Cesta de vime**, e o bicho passa a pedir o favorito com um gesto |
| Inverno quentinho | Gorro, Cachecol, Cobertor xadrez, Bule e xícaras | **Luvinhas** (roupa exclusiva) |
| Quatro estações | Cerejeira, Folhas de outono, Neve, Nuvens, Ipê-amarelo | **Selo do ano** e o habitat passa a anunciar a virada de estação |
| Cerrado | Pé de baru, Ipê-amarelo, Flores do campo, Trilha de formigas, Cenário Cerrado | **Tucano visitante** no Pé de baru |
| Coisas do [nome] (uma por espécie) | Descobrir todos os favoritos da espécie | **Gesto exclusivo** da espécie (ex.: capivara fecha os olhos com a laranjinha; raposa faz o salto de caça no monte de folhas) |

Os visitantes são a recompensa certa [I]: dão vida à cena (queixa nº 4,
"animações extremamente limitadas"), não se compram e nunca saem.

### 3.7 Sumidouros: o que segura o topo

| Sumidouro | Preço | Natureza | Teto | Por quê |
|---|---|---|---|---|
| Petiscos | 8 – 40 | consumível, mimo | nenhum | pequeno e diário; vira cena de carinho |
| Feira da semana | 60 – 300 | permanente, gira | 4 por semana | renova a vitrine sem esconder o catálogo |
| Sazonais | 20 – 220 | permanente/consumível, anual | por calendário | dá ritmo ao ano |
| Congelamento extra da raiz | 120 | proteção | 2 guardados | âncora do Duolingo (2.1); proteção, não punição. Preço e teto a harmonizar com o laudo da raiz |
| **Bosque** | 250 por muda | permanente, infinito | nenhum | o ralo aspiracional que nunca acaba |

**O Bosque** [I], com o precedente do Forest (2.6), sem a árvore que morre:

- Tela própria (acesso pela loja e pelo perfil): um terreno que cresce para
  os lados conforme se planta. Cada muda custa 250 e cresce sozinha em tempo
  real: muda → jovem (7 dias) → adulta (30) → centenária (90). Nunca murcha
  e nunca regride.
- 12 espécies nativas brasileiras para escolher (ipê-roxo, ipê-amarelo,
  jatobá, pau-brasil, araucária, buriti, baru, pequizeiro, jequitibá,
  quaresmeira, embaúba, cajueiro), cada uma com nome nos 4 idiomas e uma
  linha de "sabia que…".
- Marcos do bosque (10, 25, 50, 100 árvores) dão relíquias e um cartão de
  share ("Meu bosque: 48 árvores · plantado com 210 h longe da tela"). O
  motor do `CartaoDaRaiz` já existe.
- Por que 250: é 1,6 dia de renda do engajado (1 muda a cada ~2–3 dias com o
  que sobra) e 12 dias do casual, para quem é uma conquista rara. Pela
  inferência, o casual nem deve olhar o bosque no primeiro ano; a banca do
  dia não o mostra para quem tem saldo < 250.

**Projeção do ano 1 com tudo isto** (inferência; premissas: engajado compra 1
a 2 petiscos/dia, 2 itens da feira por semana e 1 congelamento por mês;
regular, 1 petisco a cada 2 dias e 1 item da feira por semana):

| | Regular | Engajado |
|---|---:|---:|
| Renda do ano 1 | 31.200 | 61.000 |
| Catálogo permanente + sazonais | 18.900 | 18.900 |
| Feira | ~7.700 | ~15.700 |
| Petiscos | ~3.600 | ~9.100 |
| Congelamentos | ~700 | ~1.500 |
| Sobra para o Bosque | ~300 (≈1 muda) | ~15.800 (≈63 mudas) |

Leitura [I]: o regular termina o ano com o saldo quase todo transformado em
coisas que vê; o engajado termina com um bosque de ~60 árvores, que é um
artefato de orgulho e não um número parado. Os pesos reais têm de sair da
telemetria (seção 8).

### 3.8 Como a compra deve ser celebrada

Sequência proposta (tempos em ms a partir do toque):

| t | O que acontece | Como (Flutter) |
|---|---|---|
| 0 | Pílula afunda (escala 0,96, 80 ms) + háptico leve | `AnimatedScale`; `HapticFeedback.lightImpact()` |
| 0 | Item ≤ 200: compra na hora, com **"Desfazer" por 5 s** (estorno integral). Item > 200: **segurar 500 ms** com anel enchendo. | Sem diálogo de confirmação: desfazer protege sem interromper; segurar evita toque acidental caro |
| 0 – 450 | 5 a 8 folhas saem do saldo e voam até o cartão; contador desce | `OverlayEntry` + Bézier; `ContadorAnimado` já existe (`shop_screen.dart:283`) |
| 450 | Abre a **prévia ao vivo**: folha inferior com o `HabitatScene` de verdade (~55% da altura), não a miniatura | `showModalBottomSheet` com `HabitatScene(animado: true)` |
| 600 – 1.300 | Item cai de cima com mola e pousa com efeito da zona: água = anel de onda + respingo; terra = poeirinha; céu = brilho | `SpringSimulation(SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: 0.55), …)` via `animateWith` (2.7); hoje é `easeOutBack` (`habitat.dart:624-627`) |
| ~1.000 | Som de pouso por zona (plop / farfalhar / sininho) + háptico médio | `SomDoBaru.compra` novo + 3 variantes; `HapticFeedback.mediumImpact()` |
| 1.300 – 2.600 | O bicho vira a cabeça para o x do item, dá um pulo de alegria e **usa o item uma vez**; balão com fala do item ("Uma rede! Posso testar?") | Alvo de olhar no `PetPainter`; fala por item em `l10n_loja.dart` nos 4 idiomas |
| 2.600 | Se avançou coleção: barra "Margem viva 4/5" aparece e enche; se completou, encadeia a celebração da coleção (visitante chega) | Reusar a fila de `Celebracao` |
| fim | "Ver no habitat" / "Continuar na loja" | Fecha sem modal empilhado |

- **Movimento reduzido** (`Movimento.reduzido`): sem queda e sem voo; fade de
  200 ms, som e háptico continuam.
- **Roupa**: antes da compra há um **provador grátis** (o bicho veste na
  prévia e gira de 3/4 para a frente). Depois da compra vem a "pose de
  espelho".
- **Petisco**: arrastar até a boca (`Draggable` + `DragTarget` na cabeça do
  bicho), três mordidas, migalhas, "hmm". Com favorito: coração e o cartão
  de descoberta.
- **Brinquedo**: a prévia já entra no gesto ("Toque na bola").

### 3.9 Personalização: modo decorar

Hoje: "Os itens ocupam um lugar fixo no habitat. Reorganizar vem depois."
(`l10n.dart:977-978`). O efeito IKEA (2.7) diz que o apego vem de **ter
montado**, e o modo decorar é a parte de montar.

- Cada item ganha uma **zona** (água, margem, céu, galho) e 3 ou 4
  **âncoras** dentro dela. Toque longo no habitat abre o modo decorar;
  arrastar encaixa na âncora livre mais próxima; a ordem de desenho segue o
  y.
- Persistência: mapa `id → âncora` no snapshot (sincroniza como `equipados`).
- Preserva o que o código já garante: o bicho sempre por cima no miolo
  (`models.dart:250-256`) e nenhum item escondido atrás dele (âncoras fora do
  miolo).
- Esforço G. É a recomendação de maior efeito sobre apego e a que menos mexe
  na economia.

### 3.10 Como monetizar no futuro sem quebrar as regras

| Fase | O que se vende | O que nunca se vende |
|---|---|---|
| 0 (hoje) | nada; cobrança desligada (`cobranca.dart:7`) | — |
| 1: assinatura (§9) | **Ateliê**: uma vitrine de variantes exclusivas que o assinante **compra com folhas** (o dinheiro abre a vitrine, a folha paga o item); **presente do mês** com conteúdo anunciado antes; relatório e backup; opcional: patrocínio de árvore real no Bosque, com o custo pago pela receita, como no Forest (2.6) | folhas; espécies (§4, §8B); congelamento/reparo de raiz; caixa-surpresa |
| 2: só com dados | Pacote cosmético direto (dinheiro → item fixo e visível, sem moeda intermediária), nunca sazonal exclusivo | idem; e nada com prazo ("só hoje") |

Condições:

1. **Reescrever a promessa do paywall** (E7): "a loja completa do habitat"
   sugere que o gratuito tem loja cortada. Proposta: "o Ateliê de itens
   exclusivos e um presente por mês". O catálogo permanente segue inteiro no
   gratuito.
2. **Economia autoritativa no servidor antes de qualquer dinheiro** (C-12 do
   `docs/BACKLOG.md:41`, "crítico no dia do IAP").
3. **Nada aleatório pago**, nem com folhas compradas indiretamente (seção
   2.7: Play exige mostrar as chances; o ECA Digital proíbe para menores).
4. Consentimento parental para compra por menor: segundo análise jurídica
   encontrada em busca, o Marco Legal dos Jogos (Lei 14.852/2024) já pedia
   isso, e o ECA Digital reforça ([ConJur](https://www.conjur.com.br/2025-out-22/impactos-do-eca-digital-no-segmento-de-jogos-eletronicos/);
   não li o texto da lei). Confirmar com jurídico.

Nenhuma destas fases exige mudar regra inviolável. A fase 1 exige mudar o
texto do paywall e o §9 do contrato (o que o plano entrega).

---

## 4. Clareza na coleta de recompensas

### 4.1 Folhas voando do evento até o saldo

Hoje o saldo muda e a pessoa precisa acreditar (o próprio comentário de
`data/carteira.dart:5-6` diz isso). O voo:

- **Origem**: o ponto do evento (botão "colher" da missão, toca, cartão de
  resultado, cartão de descanso, presente de volta).
- **Destino**: o chip de saldo (`GlobalKey`; posição por
  `RenderBox.localToGlobal`). Se a tela não tem chip visível (resultado,
  trilha), um **"bolso" temporário** entra pelo canto superior, recebe as
  folhas e sai.
- **Partículas**: N = mínimo de (12, teto(valor ÷ 5)); saída escalonada de
  40 ms; curva Bézier quadrática com o ponto de controle sorteado acima da
  reta; `Curves.easeInOutCubic`; folha girando ±40°.
- **Chegada**: cada folha soma a parte dela no contador (a última corrige
  para o valor exato), o chip pulsa (escala 1,08) e toca um "tic" com tom
  subindo; háptico leve na primeira e na última.
- **Rótulo**: um "+25 · sessão de 50 min" sobe da origem enquanto as folhas
  voam. A origem sempre escrita.
- **Fila**: créditos simultâneos (sessão + missão + bônus) não voam juntos;
  entram em fila, um por vez, na ordem da cadeia de celebração.
- Movimento reduzido: sem voo; o rótulo aparece no chip e o contador sobe.

### 4.2 Recibo

- **Recibo da sessão**, na tela de resultado: as linhas do que a sessão
  rendeu ("+25 sessão de 50 min · +10 missão Um foco · +30 XP"), total em
  destaque e, embaixo, "Faltam 40 para a Rede de descanso" (alvo pela regra
  corrigida em E1).
- **Recibo do dia**, na chegada do dia seguinte (onde hoje aparece o
  `SnackBar` do bônus, E3): "Ontem: +15 dia abaixo da meta, +30 descanso".
  A cena de chegada já existe (`chegadaACelebrar`, `state.dart:2199`).

### 4.3 "De onde veio": extrato completo

- Um **livro-razão** persistido: lista de lançamentos `{valor, origem,
  quando, detalhe}` gravada **no momento do crédito ou débito**, com teto
  (ex.: 1.000 linhas ou 365 dias) e sincronizada junto do snapshot.
- `OrigemDeFolhas` ganha `descanso`, `bonusMeta`, `retomada`, `volta`,
  `colecao`, `presente`, `estorno`, `bosque`, `petisco`.
- `Carteira` lê o livro-razão; o cálculo atual fica só para contas antigas,
  com a nota honesta que já existe (`l10n.dart:681`).
- Tela de folhas: "Esta semana: +1.102 · −640" com barra por origem e lista
  datada. A conta tem de fechar à vista.

### 4.4 Baús e presentes de marco

- **Presente embrulhado na toca** para marcos, coleções e volta: o gesto de
  cavar e o som `premio` já existem (`widgets/toca.dart:95-104`).
- **Conteúdo fixo e anunciado**: a trilha mostra "Passo 9: 90 folhas + Regador
  de lata". Surpresa só no *jeito* de abrir, nunca no *quê* (regra 5).
- **Relíquias da trilha**: cada marco passa a entregar, além das folhas, um
  objeto que **não se compra** (ex.: passo 1 "Primeiro broto", passo 11
  "Placa Uma semana", passo 22 "Pedra dos 100 focos"). Os marcos ganham
  valor sem imprimir mais folhas, e a pessoa tem no habitat a prova de por
  onde passou. É acréscimo, então não mexe nos ids nem na escada de folhas
  (`progressao.dart:303-307`).

---

## 5. Recomendações detalhadas

Esforço: P (até 2 dias), M (até 2 semanas), G (mais que isso).

**R1. Celebrar a compra com prévia ao vivo, mola e reação do bicho.**
- O quê: a sequência da seção 3.8.
- Por quê: a compra é muda (E4) e a mola acontece fora de vista (E5). Suco
  é o que faz a ação parecer viva (2.7).
- Como: `SomDoBaru.compra`; `HapticFeedback`; folha inferior com
  `HabitatScene`; `SpringSimulation`; alvo de olhar no pet; desfazer em 5 s.
- Esforço: M. Impacto: alto; fecha o ciclo foco → folha → habitat.
- Aceite: num teste de widget, `buy()` dispara som e háptico, a prévia abre
  com o item em queda e o pet recebe o alvo de olhar; o "Desfazer" devolve
  exatamente o preço e é idempotente; com movimento reduzido não há queda.

**R2. Extrato completo com livro-razão datado.**
- O quê: seção 4.3.
- Por quê: 27% da renda do engajado é invisível (E2); compras e marcos sem
  data (E6); a captura 10-folhas não fecha.
- Como: lista persistida em `AppSnapshot`, gravada em cada `leaves +=` e
  `leaves -=` de `state.dart` (funil único `_credita(valor, origem,
  detalhe)`).
- Esforço: M. Impacto: alto em confiança.
- Aceite: teste que roda um dia sintético com sessão, 3 missões, descanso,
  bônus e uma compra e confere: soma do livro-razão do dia = variação do
  saldo; toda linha tem origem e data.

**R3. Folhas voando até o saldo e recibos.**
- O quê: seções 4.1 e 4.2.
- Por quê: recompensa que não se vê chegar não se sente (o próprio código
  diz isso do afago, `habitat.dart:944-946`).
- Como: `OverlayEntry` + `GlobalKey` no chip; fila de créditos; bolso
  temporário.
- Esforço: M. Impacto: alto.
- Aceite: em teste de integração, resgatar missão gera N partículas (N pela
  fórmula), o contador termina no valor exato e o rótulo cita a origem; o
  bônus de meta não usa mais `SnackBar`.

**R4. Corrigir o alvo da carteira (E1).**
- O quê: `proximoItem` ordenar por preço, uma fonte só com `nextItem`.
- Por quê: home e tela de folhas apontam alvos diferentes;
  `10-folhas.png` mostra Bambuzal (70) com Chapéu (60) livre.
- Como: `Carteira.proximoItem` delega para a mesma função de
  `state.dart:1041-1045`.
- Esforço: P. Impacto: médio.
- Aceite: teste com `owned = {lily}` devolve `chapeu_palha` nas duas telas.

**R5. Todo item faz o bicho fazer algo; favoritos por espécie.**
- O quê: campo `interacao` e `favoritoDe` em `ShopItemDef`; o pet ganha as
  ações (sentar, deitar, pescar, olhar, mergulhar); caderno de favoritos.
- Por quê: Neko Atsume (2.4); queixa nº 4 do dono (animações limitadas).
- Como: começar pelos 8 objetos originais (barco, deque, ponte, fogueira...)
  e pelos novos de "Casa e cantinho", que só pedem poses de cochilo e de
  sentar.
- Esforço: G (depende do pet novo do laudo de visual). Impacto: alto.
- Aceite: cada item com `interacao` tem um teste de evidência (quadro a
  quadro, como `test/evidencia_*`) mostrando o bicho usando o item; tocar no
  brinquedo dispara a ação em ≤ 100 ms.

**R6. Ampliar o catálogo em ondas com a curva de preços.**
- O quê: seção 3.3, em 3 ondas: (1) Casa e cantinho + Brinquedos (só pedem
  poses); (2) Beira d'água + Mata + Céu; (3) Roupas (9 silhuetas cada) e o
  slot "costas".
- Por quê: o engajado esgota a loja no dia 25.
- Como: novos itens entram no fim de `shopItems` com nome por id em
  `l10n_loja.dart` (a regra de ordem de `models.dart:238-245` continua);
  arte fora de `ShapePart`.
- Esforço: G. Impacto: alto.
- Aceite: teste de economia (R12) prova que o permanente dura ≥ 90 dias para
  o engajado simulado; cada prateleira tem item ≤ 90; paridade de chaves nos
  4 idiomas.

**R7. Banca do dia e feira da semana.**
- O quê: seção 3.5.
- Por quê: o Finch gira raros por dia (2.2); o brief pede motivo para abrir
  o app todo dia.
- Como: seleção determinística por conta e data com o hash de
  `data/missoes.dart:589`; feira por semana ISO.
- Esforço: M. Impacto: médio-alto (inferência; medir).
- Aceite: mesma conta e data dão a mesma banca em dois aparelhos (teste
  determinístico); nenhum item da feira fica fora mais de 8 semanas (teste de
  propriedade em 52 semanas); a loja não mostra contagem regressiva nem
  desconto.

**R8. Coleções com prêmio visitante.**
- O quê: seção 3.6.
- Por quê: gradiente de meta e progresso dotado (2.7); o "2/22" de hoje não
  paga nada.
- Como: `Colecao` ganha conjuntos com lista de ids e prêmio; o visitante é um
  ator animado no `HabitatScene`.
- Esforço: M (dados e UI) + G (visitantes animados). Impacto: médio-alto.
- Aceite: completar o conjunto encadeia a celebração uma vez só (resgate
  idempotente como missões); o visitante aparece no habitat e nunca some.

**R9. Sazonais por hemisfério, e os itens de estação que já existem viram
calendário vivo.**
- O quê: seção 3.5 (calendário) e 3.3 (Neve, Folhas de outono, Cerejeira).
- Por quê: Animal Crossing e Neko Atsume (2.3, 2.4); o Brasil está no
  hemisfério sul.
- Como: `Hemisferio` em Ajustes, padrão pela localidade; funções puras
  `estacaoEm(data, hemisferio)`.
- Esforço: M. Impacto: médio.
- Aceite: teste de tabela: 15/07 é inverno no sul e verão no norte; um
  sazonal comprado continua no inventário fora da janela.

**R10. Petiscos como mimo.**
- O quê: 13 consumíveis, arrastar até a boca, sem XP e sem folha.
- Por quê: sumidouro pequeno, diário e afetivo; o Pou mostra o risco de
  transformar comida em obrigação (2.5).
- Como: inventário com contagem (`Map<String,int>`); `Draggable`.
- Esforço: M. Impacto: médio.
- Aceite: nenhum estado do bicho depende de petisco (teste: 30 dias sem
  petisco não mudam humor, XP nem vínculo); comer registra uma linha
  `petisco` no livro-razão.

**R11. Bosque: sumidouro infinito.**
- O quê: seção 3.7.
- Por quê: o engajado tem ~42 mil folhas sobrando no ano 1 mesmo com o
  catálogo novo; o Forest provou o formato (2.6).
- Como: tela nova; árvores com data de plantio e estágio derivado da data
  (sem timer em segundo plano).
- Esforço: G. Impacto: alto no topo (inferência; medir).
- Aceite: nenhuma árvore regride ou some em teste de 400 dias simulados;
  estágio é função pura de (plantio, hoje); cartão de share gera imagem.

**R12. Simulador de economia como teste.**
- O quê: levar o simulador deste laudo para `test/economia_simulada_test.dart`
  lendo `Balanco`, `trilha`, os pools e o catálogo.
- Por quê: a economia mudou de 8 para 31 itens sem ninguém refazer a conta;
  o contrato ainda diz 8 (E8).
- Como: 3 perfis fixos e asserções de faixa.
- Esforço: P. Impacto: alto em prevenção.
- Aceite: o teste falha se (a) o engajado comprar o permanente antes do dia
  90, (b) o casual não conseguir uma compra até o dia 2, ou (c) alguma
  prateleira não tiver item ≤ 90.

**R13. Modo decorar.**
- O quê: seção 3.9.
- Por quê: efeito IKEA (2.7); a nota "Reorganizar vem depois".
- Esforço: G. Impacto: alto em apego.
- Aceite: arrastar move o item para a âncora livre mais próxima da zona
  dele; a posição sobrevive a reinício e a sincronização; nenhum item
  invade o miolo do bicho.

**R14. Relíquias de marco e presente embrulhado.**
- O quê: seção 4.4.
- Por quê: o marco hoje é só folha (`progressao.dart:118-137`); presente com
  conteúdo anunciado mantém a surpresa sem aleatório.
- Esforço: M. Impacto: médio.
- Aceite: a trilha mostra o conteúdo de cada presente antes; a relíquia
  entra no inventário com origem `presente` no livro-razão; ela não aparece
  na loja.

**R15. Nome e contrato.**
- O quê: a tela chamar "Loja" (ou "Loja do habitat") nos 4 idiomas;
  ADR que atualiza `PRODUCT.md` §5 (catálogo, consumíveis, regras 1–5 da
  seção 3.1) e §9 (o que a assinatura entrega).
- Por quê: E7, E8 e o título "Habitat" repetido.
- Esforço: P. Impacto: médio.
- Aceite: `test/l10n_test.dart` passa; o ADR existe e `PRODUCT.md` não cita
  mais "8 itens".

**R16. Congelamento extra por folhas.**
- O quê: 120 folhas, teto de 2 guardados (harmonizar com o laudo da raiz).
- Por quê: é o sumidouro-âncora do Duolingo (2.1) e é proteção.
- Esforço: P. Impacto: médio.
- Aceite: não dá para guardar 3; nunca é vendido por dinheiro; o congelamento
  gasto aparece no extrato e na tela da raiz.

---

## 6. As 10 recomendações mais importantes, priorizadas

| # | Recomendação | Esforço | Por que nesta ordem |
|---|---|---|---|
| 1 | **R1** Celebrar a compra (prévia ao vivo, mola, som, háptico, bicho reage, desfazer) | M | É o momento que fecha o ciclo do app, e hoje está mudo |
| 2 | **R3** Folhas voando até o saldo e recibos | M | Clareza da coleta é pedido explícito do brief |
| 3 | **R2** Livro-razão datado, extrato completo | M | 27% da renda invisível; base de R3, R10, R11 e da cobrança futura |
| 4 | **R4** Corrigir `proximoItem` | P | Bug aberto desde agosto, visível na captura |
| 5 | **R12** Simulador de economia como teste | P | Trava a curva antes de crescer o catálogo |
| 6 | **R5** Todo item faz o bicho agir; favoritos por espécie | G | Item que o bicho usa vale mais que item parado (Neko Atsume) |
| 7 | **R6** Catálogo novo em 3 ondas, com arte nova | G | O engajado esgota a loja no dia 25 |
| 8 | **R7** Banca do dia + feira da semana sem urgência falsa | M | Motivo diário de abrir sem padrão sombrio |
| 9 | **R8** Coleções com visitante | M/G | Metas de médio prazo e vida na cena |
| 10 | **R11** Bosque | G | O único ralo que segura o topo depois do dia 90 |

Logo depois: R13 (modo decorar), R9 (sazonais por hemisfério), R10
(petiscos), R14 (relíquias), R15 (nome e contrato), R16 (congelamento).

---

## 7. O que **não** fazer

- **Vender folhas por dinheiro**, nem "pacote de folhas" em promoção.
- **Caixa-surpresa paga** (com dinheiro ou com folhas compradas). Proibida
  para menor no Brasil desde 17/03/2026 e exige divulgação de chances na
  Play.
- **Item que estraga, quebra, murcha ou precisa de manutenção.** Fere o §1.
- **Fome, sede ou sujeira como medidor.** Petisco é mimo.
- **"Última chance", contagem regressiva, desconto relâmpago.** Escassez
  falsa é padrão sombrio temporal (2.7), e a feira volta.
- **Trocar a vitrine por folhas em escada** (como a troca paga do Finch).
  Cara de caça-níquel.
- **Espécie, raiz salva ou congelamento por dinheiro.** O primeiro é regra
  inviolável; os outros são o alvo da crítica ao Duolingo (2.1).
- **Reprecificar item já vendido** ou cortar torneiras para "equilibrar".
- **Item exclusivo por espécie.** Trocar de espécie faria a pessoa perder
  acesso.
- **Mais itens em `ShapePart`.** Repete a queixa de visual amador.
- **Preço que sobe com o nível da pessoa.**

---

## 8. Riscos e dúvidas em aberto

- **Premissas dos perfis.** Os três perfis são hipóteses. Antes de fixar
  preços, medir a distribuição real de renda diária (sem conteúdo, só os
  contadores que o app já tem) e recalibrar o simulador.
- **O muro do casual na trilha** (passo 11, sequência de 7 sem alternativa)
  é inferência do simulador. Se confirmado, é o maior problema de economia do
  casual e pertence ao laudo de jornada.
- **Custo de arte.** 86 itens, 13 roupas × 9 espécies, visitantes animados e
  interações por item são o grosso do esforço. Sem pipeline de arte novo,
  a proposta vira 86 retângulos. A ordem das ondas (R6) minimiza isso, mas
  não elimina.
- **Petisco e o pet novo.** A animação de comer depende do redesenho do
  bicho (laudos de visual e de espécie). Se o pet continuar em
  `CustomPainter` puro, cada ação nova custa caro.
- **Bosque com árvore real** é decisão de negócio (custo, parceiro,
  verificação: o próprio Forest diz que não há GPS por árvore) e de
  comunicação (não prometer impacto que não se mede).
- **Hemisfério por idioma** erra para quem fala espanhol no México e mora no
  sul, ou vice-versa; por isso tem de ser editável.
- **Sincronização.** Livro-razão e inventário de consumíveis aumentam o
  snapshot; definir teto e compactação antes de ligar. Com dinheiro, só com
  C-12 resolvido.
- **Assinatura x catálogo gratuito.** Se o negócio quiser travar parte do
  catálogo para não assinantes, isso não fere regra inviolável, mas
  contradiz o tom "sem punição" para quem não paga. Recomendo o Ateliê
  separado.
- **Efeito das vitrines rotativas em app de bem-estar**: não achei estudo.
  Tratar R7 como experimento, com métrica de abertura diária e de compras
  por semana, e desligar se aumentar abertura sem aumentar sessão de foco.

---

## Fontes

Duolingo
- Blog, Duolingo 101: https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/
- Blog, streak nas férias (2 freezes, loja, pacotes de gems): https://blog.duolingo.com/how-to-keep-your-streak-on-vacation/
- Relatório anual 2023 (SEC; assinatura US$ 404,7 mi de US$ 531,1 mi; compras avulsas = Streak Freezes, Timer Boosts): https://www.sec.gov/Archives/edgar/data/1562088/000156208824000093/duolingodecember312023an.htm
- deceptive.design sobre reparo pago de streak: https://www.deceptive.design/articles/when-a-user-uses-duolingo-on-a-series-of-consecutive-days-this-is-called-a-streak-if-users-miss-a-day-they-can-pay-to-repair-it

Finch
- Central de ajuda (lojas, raros diários; lida via busca, 403 na leitura): https://help.finchcare.com/hc/en-us/articles/37935977276813-Shops-in-Finch-Outfits-Travel-and-More
- Finch Wiki, loja do Mr. Prickles (não oficial; via busca): https://finch.fandom.com/wiki/Mr._Prickles'_Shop
- Internet Matters (via busca): https://www.internetmatters.org/advice/apps-and-platforms/wellbeing/finch/
- FAQ do Finch (sem morte; via busca): https://befinch.notion.site/Finch-FAQ-474652d0123d4883ac7a0cd6c8f5aa70

Animal Crossing
- GameSpot, sazonais: https://gamespot.com/articles/new-animal-crossing-seasonal-items-now-available/1100-6495009/
- Nintendo Life, sazonais: https://www.nintendolife.com/news/2020/06/animal_crossing_new_horizons_adds_cute_summer_and_winter-solstice_seasonal_items
- Nookipedia, hemisfério: https://nookipedia.com/wiki/Hemisphere
- Prima Games, hemisfério: https://primagames.com/tips/animal-crossing-new-horizons-north-hemisphere-or-south
- Wealthsimple, economia (opinião): https://www.wealthsimple.com/en-us/magazine/animal-crossing

Neko Atsume, Pou, Forest
- iMore, guia de gatos raros: https://imore.com/neko-atsume-game-guide-how-collect-all-cats
- Daily Dot, guia: https://dailydot.com/neko-atsume-cat-collecting-guide
- Neko Atsume Wiki, NA2: https://nekoatsume.fandom.com/wiki/Neko_Atsume_2
- Pou, descrição (SourceForge): https://sourceforge.net/app/pou-tm/iphone/
- Pou, MobyGames: https://www.mobygames.com/game/pou
- Forest, Wikipedia: https://en.wikipedia.org/wiki/Forest_(application)
- Forest, site oficial: https://www.forestapp.cc/

Princípios, ética e lei
- Sahin, economias de jogo (praticante): https://medium.com/@msahinn21/designing-game-economies-inflation-resource-management-and-balance-fa1e6c894670
- Resumo de *Virtual Economies* (Lehdonvirta & Castronova): https://www.antoinebuteau.com/virtual-economies-book-summary/
- Zagal, Björk, Lewis 2013: https://research.chalmers.se/en/publication/177148 ; resumo: https://www.deceptive.design/articles/dark-patterns-in-the-design-of-games
- Crítica DiGRA 2020: https://eprints.whiterose.ac.uk/156460/1/DiGRA_2020_paper_189.pdf
- Metanálise loot box × jogo problemático: https://figshare.utas.edu.au/articles/journal_contribution/Meta-analysis_of_the_relationship_between_problem_gambling_excessive_gaming_and_loot_box_spending/22996898/1/files/40746986.pdf
- Zendle, PeerJ: https://peerj.com/articles/7700.pdf
- Google Play, Pagamentos (chances de itens aleatórios): https://support.google.com/googleplay/android-developer/answer/9858738?hl=en
- Google Play, requisitos por país (Brasil, ECA Digital): https://support.google.com/googleplay/android-developer/answer/6223646?hl=en
- ECA Digital, factsheet Machado Meyer: https://www.machadomeyer.com.br/images/ebooks/Factsheet_ECA_Digital.pdf
- ECA Digital, Poder360: https://www.poder360.com.br/poder-governo/eca-digital-entra-em-vigor-nesta-3a-feira-entenda-o-que-muda/
- ConJur, ECA Digital e jogos (via busca): https://www.conjur.com.br/2025-out-22/impactos-do-eca-digital-no-segmento-de-jogos-eletronicos/
- Kivetz, Urminsky, Zheng 2006: https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal
- Progresso dotado (resumo de Nunes & Drèze 2006): https://www.coglode.com/nuggets/endowed-progress-effect
- Norton, Mochon, Ariely 2012: https://dash.harvard.edu/handle/1/12136084
- "Juice it or lose it" (Game Developer): https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-
- Flutter `SpringSimulation`: https://api.flutter.dev/flutter/physics/SpringSimulation-class.html
- Flutter `SpringDescription`: https://api.flutter.dev/flutter/physics/SpringDescription-class.html

Baru (a árvore)
- Embrapa: https://www.alice.cnptia.embrapa.br/bitstream/doc/1074669/1/baru.pdf
- Correio Braziliense: https://www.correiobraziliense.com.br/cidades-df/2024/05/6854384-baru-o-superalimento-do-cerrado-e-nutritivo-e-ja-conquista-novos-mercados.html

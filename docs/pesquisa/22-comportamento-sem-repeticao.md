# 22 — Comportamento sem repetição e repertório por espécie

Motivo: medição de 3 minutos na home (capivara e gata, humor contente):
93–94% do tempo o bicho estava no laço fixo da atividade (pastar/petiscar:
cabeça desce no mesmo ponto da volta, 14 mordidas por volta) e nenhum gesto
espontâneo aconteceu. A queixa ("faz o mesmo movimento a cada instante") era
literal.

Fontes marcadas [U] não foram verificadas em fonte primária.

## Parte A — Como produtos e pesquisa evitam repetição

- **Petz/Dogz/Catz** (Frank, Stern & Resner, AAAI Fall Symposium 1997):
  rede de animações de corpo com muitos pontos de ramificação; camadas
  aditivas por cima (olhar para qualquer lado independente do corpo,
  respiração, piscar, sacudir cabeça, postura, raça, idade) — "the
  subsequent number of permutations is enormous and therefore passes a
  critical threshold in human perception"; "constrained randomness" para
  ser "real, unpredictable, non-repetitive". Sem medidores na tela: o
  estado aparece no rosto, no andar, no som.
  https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm
- **The Sims / utilidade** (Zubek, *Needs-based AI*; Graham, *Game AI Pro*
  cap. 9; Dill, *Game AI Pro 2* cap. 3): sortear por peso entre as melhores
  (top 3–5 ou até 10% da melhor); escolher sempre a melhor "feels very
  robotic"; inércia/cooldown contra oscilação; decidir de novo só quando a
  fila esvazia.
  https://robert.zubek.net/publications/Needs-based-AI-draft.pdf ·
  http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter09_An_Introduction_to_Utility_Theory.pdf ·
  http://www.gameaipro.com/GameAIPro2/GameAIPro2_Chapter03_Dual-Utility_Reasoning.pdf
- **Creatures** (Grand, Cliff & Malhotra 1996): atenção por estímulo com
  inibição lateral; impulsos químicos e aprendizado; comportamento
  "surprisingly free from limit cycles".
  https://www.sussex.ac.uk/informatics/cogslib/reports/csrp/csrp434.pdf
- **Shimeji-ee** (código aberto): cada comportamento tem peso (`Frequency`),
  condição e `NextBehavior` (cadeia de Markov de episódios); durações
  `base + random·base`. https://github.com/chaoskagami/shimeji-ee
- **Duolingo / Rive (Lily)**: 8 animações de cabeça × 8 de corpo em
  artboards aninhados, combinadas em mais de 64 variações, para evitar
  "repetitive idle loops"; gestos aleatórios.
  https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life
- **The Last Guardian** (CEDEC 2017): pontos de interesse com prioridade
  que **cai** depois de interagir (habituação); ação depende do contexto.
  https://www.gameanim.com/?p=15474
- **Improv** (Perlin & Goldberg, SIGGRAPH 1996): canais com ruído coerente
  em oitavas; ações em camadas (globais atrás, fugazes na frente); escolha
  ponderada. https://mrl.cs.nyu.edu/~perlin/improv-paper
- **Episódios de comportamento animal** (Minasandra et al., PNAS 2025):
  durações de cauda longa (lognormal / lei de potência truncada), risco de
  terminar que **diminui** com o tempo do episódio.
  https://researchonline.jcu.edu.au/88056/1/88056.pdf
- **Percepção**: idles feitos à mão e curtos foram distinguidos de gravações
  reais em ~62% dos casos com clipes de 10 s (arXiv 2509.05023).
  https://arxiv.org/html/2509.05023v1 — não achamos estudo que meça em
  quantos ciclos alguém nota um laço.

Regras adotadas: episódios no lugar de laços; duração lognormal; sucessores
por episódio (Markov) com peso menor para o recente; camadas independentes
(corpo, cabeça, olhar, piscar, orelha, cauda) em relógios próprios; ruído
coerente no contínuo; repertório por espécie; raros escondidos com peso
baixo.

## Parte B — Etograma das nove espécies (o que dá para desenhar)

- **Capivara** (SDZ, ADW, Porto 2015/UEL): pasta de cabeça baixa, também
  sentada ou deitada; anda pouco entre tufos; vigilância constante (congelar
  e olhar); descanso deitada de barriga com a cabeça erguida; cochilos
  curtos; molho na água só com olhos e narinas de fora.
  https://animaldiversity.org/accounts/Hydrochoerus_hydrochaeris/
- **Lontra** (SeaWorld, ADW, Exeter 2020): limpeza contínua do pelo; rolar
  e se esfregar depois do banho; escorregar de barriga; malabarismo com
  pedrinha de costas; rolar e brincar na água; espiar (periscópio) [U].
  https://seaworld.org/animals/all-about/otters/behavior/
- **Tartaruga-de-orelha-vermelha** (ADW, Dreslik & Kuhns 2000): banho de
  sol; boiar com a cabeça de fora; recolher a cabeça e espiar; tremular as
  garras (corte). https://animaldiversity.org/accounts/Trachemys_scripta/
- **Coruja-buraqueira** (ADW, Cornell, NPS): sentinela no montinho;
  **balançar a cabeça para cima e para baixo** ao avistar algo; girar a
  cabeça ~270°; reverência; caçar a pé, correndo e saltando sobre insetos.
  https://www.allaboutbirds.org/guide/Burrowing_Owl/lifehistory
- **Axolote** (SDZ, ADW, SICB): descansa no fundo; anda no fundo; sobe para
  engolir ar e afunda devagar; bote de sucção; abanar das guelras [U].
  https://animaldiversity.org/accounts/Ambystoma_mexicanum/
- **Pinguim-de-magalhães** (Aquarium of the Pacific, ADW, SF Zoo): display
  extático (pescoço esticado, bico para o céu, zurro); alisar as penas;
  sacudir cabeça e cauda; bater as nadadeiras; microcochilos de ~4 s
  (pinguim-de-barbicha); saltos "golfinho" na água.
  https://www.aquariumofpacific.org/onlinelearningcenter/species/magellanic_penguin
- **Gato** (Cats Protection, Humphrey et al. 2020): espreita agachada,
  rebolar e bote; **piscada lenta** (gatos devolvem e se aproximam mais);
  amassar pãozinho com ronrom; pãozinho deitado; disparadas.
  https://pmc.ncbi.nlm.nih.gov/articles/PMC7536207/
- **Raposa** (Wildlife Online, ADW): congelar escutando, orelhas para a
  frente, e o **salto de caça** (~40°, até ~80°) caindo de patas
  dianteiras; reverência e "cara de brincadeira"; dormir enrolada.
  https://www.wildlifeonline.me.uk/animals/article/red-fox-diet-hunting-strategies-behaviour
- **Buldogue francês** (Byosiere 2016, Sommese 2021, PetMD): reverência;
  disparadas (zoomies) que acabam de repente; **inclinar a cabeça**, cada
  cão para o mesmo lado; sonha remando as patas (cão pequeno, a cada ~10
  min); ronco (manter fofo).
  https://pmc.ncbi.nlm.nih.gov/articles/PMC9107419

## Parte C — Dieta e locomoção (o que cada um come, por onde anda)

- **Capivara**: ~92% capim (Poaceae) num estudo brasileiro; plantas aquáticas;
  fruta de vez em quando (melão, abóbora). Nada muito bem; no estudo de
  Londrina (Rickli 2007) passava **29% do tempo na água**; nas horas quentes
  fica na água ou na lama. Ícone: capim. Petisco: melancia/melão.
  https://animaldiversity.org/accounts/Hydrochoerus_hydrochaeris/ ·
  https://repositorio.uel.br/bitstreams/21341008-4189-46f7-84f0-cc5d04361bb4/download
- **Lontra (de rio)**: peixe, lagostim, sapo. Come pequeno na água e leva o
  grande para a margem, segurando com as patas da frente. Comer de barriga
  para cima é da lontra-**marinha** — não usar.
  https://animaldiversity.org/accounts/Lontra_canadensis/
- **Tartaruga-de-orelha-vermelha**: filhote carnívoro, adulta come planta
  aquática; engole com a cabeça debaixo d'água; anda na margem, sobe para o
  sol e escorrega para a água ao se assustar. Petisco: minhoca.
  https://animaldiversity.org/accounts/Trachemys_scripta/ ·
  https://vcahospitals.com/know-your-pet/turtles---aquatic---feeding
- **Coruja-buraqueira**: ~90% dos itens são artrópodes (gafanhoto, grilo,
  besouro); caça voando baixo, **pairando**, andando, saltando e correndo;
  pousa no montinho da toca. https://www.allaboutbirds.org/guide/Burrowing_Owl/lifehistory
- **Axolote**: minhoca, larvas, pequenos crustáceos; **sucção**; inteiramente
  aquático (nunca sai da água). https://pmc.ncbi.nlm.nih.gov/articles/PMC12309904/
- **Pinguim-de-magalhães**: anchova, sardinha, lula; engole debaixo d'água;
  anda de passinhos curtos na terra. Petisco: lula.
  https://animaldiversity.org/accounts/Spheniscus_magellanicus/
- **Gato**: carnívoro (roedores, aves, peixe). **Raposa**: onívora (roedores,
  insetos, fruta); caça "mousing". **Buldogue francês**: ração; nada mal
  (focinho curto) — só brinca na beira.
  https://animaldiversity.org/accounts/Felis_catus/ ·
  https://animaldiversity.org/accounts/Vulpes_vulpes/

Aplicado: comida por espécie (na boca e no potinho), coruja voando
(decola, cruza baixo, paira mirando o chão, pousa), capivara, tartaruga,
lontra e pinguim indo e voltando da água por conta própria (e sacudindo o
corpo ao sair), axolote sempre na água, e comer na água para quem come
nela.

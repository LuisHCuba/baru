# 20 — Interação com o bicho: como fazer o pet parecer vivo

> Pesquisa feita em 27/10/2026 com busca na web. Toda afirmação traz o link da fonte. O que não consegui verificar está marcado como **[não verificado]**. Os tempos em ms marcados como **(proposta)** são recomendação de design minha, derivada das fontes citadas, e não números publicados por algum jogo.

## Resumo executivo

1. **O problema do Baru tem nome na literatura.** Os criadores de *Petz* (1997/98) escreveram: "A believable character should not appear to be repeating itself verbatim every time the user interacts with it" e "If a character reacts in a way that makes no sense, or doesn't react at all, then the illusion of life is broken" ([GDC Classic, Game Developer](https://gamedeveloper.com/design/gdc-classic-multiple-character-interaction-in-i-petz-i-games)). A solução deles foi **animação em camadas** (respiração, piscada e olhar por cima de uma pose base) e **aleatoriedade restrita** ([Stern, Frank, Resner, AAAI 1997](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm)).
2. **O verbo mais amado é o carinho com o dedo, e ele depende do lugar do corpo.** Petz reage "depending on what spot on its body is being petted" e também à velocidade e ao humor do pet. Nintendogs e Pokémon-Amie têm zonas favoritas, zonas que o bicho não gosta e um "rolar de barriga" como recompensa.
3. **Olhar é barato e dá muita vida.** Petz segue o cursor com a cabeça "no matter what its body is doing". Em nintendogs + cats os olhos viraram objetos que acompanham o que se move, e as pupilas se fecham na claridade ([GoNintendo/Iwata Asks](https://gonintendo.com/archives/143459-iwata-asks-nintendogs-cats-wii-sequel-almost-happened-originally-started-on)).
4. **Iniciativa e memória separam um pet de um GIF.** O pet de Petz busca o brinquedo e traz para você. Depois de dias de abandono, começa a choramingar. O Bird Buddy avisa quando um pássaro que você batizou volta.
5. **As reclamações mais comuns** são repetição ("just looping animations on a timer"), interação rasa ("wished they could do more to interact with these felines"), anúncios e cobrança, e punição pesada com perda de progresso.

---

## 1. O que os produtos de referência deixam o usuário fazer

| Produto | Verbos do usuário | Como o bicho reage | Fonte |
|---|---|---|---|
| **Nintendogs** (DS) | Acariciar com a caneta, chamar pelo nome (microfone), ensinar truques por gesto, frisbee e bola, passeio, banho e escova | Lambe a ponta da caneta se ela fica parada no focinho. Rola de barriga se gosta muito. Gira se você segura o rabo. Pula se você toca logo acima da cabeça quando ele está animado. Uivar, cavar e farejar só aparecem se você deixa o cão sozinho. Aprende só 3–4 truques por dia | [NWR review](https://www.nintendoworldreport.com/review/4394), [GamesFirst](https://gamesfirst.com/articles/2005/nintendogs-chihuahua-friends/), [FAQ](https://www.cheathappens.com/../text/nintendogsfaq.zip.txt), [Wikipedia](https://en.wikipedia.org/wiki/Nintendogs) |
| **Nintendogs** (gestos) | Sentar: acariciar a cabeça e deslizar para baixo. Pata: tocar a pata e levantar até a metade. Rolar: deslizar na horizontal com o cão deitado, depois para cima a partir da barriga. Implorar: deslizar da barriga ao pescoço | "?" vermelho quando não entendeu. Lâmpada quando entendeu, e você "dá" a lâmpada a ele. Late e brilha quando aprendeu | [FAQ Nintendogs](https://www.cheathappens.com/../text/nintendogsfaq.zip.txt) |
| **nintendogs + cats** (3DS) | Aproximar o rosto da câmera | O filhote vem e lambe seu rosto. Olhos modelados em 3D seguem objetos. Cão vira a cabeça inteira para olhar, gato acompanha só com os olhos | [GamesFirst](https://gamesfirst.com/articles/2005/nintendogs-chihuahua-friends/), [GoNintendo/Iwata Asks](https://gonintendo.com/archives/143459-iwata-asks-nintendogs-cats-wii-sequel-almost-happened-originally-started-on) |
| **Petz / Dogz / Catz** (PC) | Mão-cursor que acaricia e pega no colo, brinquedos, petiscos, borrifador d'água, duplo clique para "vem cá" | A reação muda com a zona, a velocidade e o humor. O pet busca brinquedos sozinho e traz para começar a brincadeira. Choraminga após dias sem atenção. Engorda ou fica agressivo conforme o cuidado. Pode fugir se for maltratado | [AAAI 1997](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm), [Wikipedia](https://en.wikipedia.org/wiki/Dogz_and_Catz) |
| **Pokémon-Amie / Refresh** | Acariciar, dar Poké Puffs arrastando, fazer caretas para a câmera, toca-aqui | Cada espécie tem pontos favoritos e pontos de que não gosta. No ponto ruim, solta um som mais grave de desconfiança. Toque rápido demais conta como bater e deixa o Pokémon bravo. Segurar a caneta parada fora do corpo por ~5 s vira um toca-aqui | [Bulbapedia via busca](https://bulbapedia.bulbagarden.net/wiki/Petting) (página deu 403 para fetch, dados vieram do índice), [Kotaku](https://kotaku.com/the-internet-reacts-to-pokemon-x-ys-silliest-feature-1447280949) |
| **Talking Tom Cat** | Acariciar, cutucar rosto, barriga e pés, puxar o rabo, falar | "Pet Tom and hear him purr". "Keep poking and discover hidden reactions". Repete sua voz | [App Store](https://apps.apple.com/us/app/talking-tom-cat/id377194688) |
| **Tamagotchi / Uni** | Alimentar, brincar, limpar, disciplinar, apagar a luz, passear (passos reais) | Chama atenção mesmo sem fome. A disciplina responde a esse chamado "falso". A forma adulta depende do cuidado. No Uni a personalidade (tímido, mimado etc.) muda as reações | [Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi), [Toy Insider](https://thetoyinsider.com/tamagotchi-uni-opens-up-the-tamaverse) |
| **Neko Atsume** | Pôr comida e brinquedos, esperar, fotografar | Os gatos decidem quando vir. Gatos raros só aparecem com certos itens. Deixam peixes e "mementos" como presente | [AV Club/NYT](https://avclub.com/read-this-the-new-york-times-explains-neko-atsume-s-ap-1798244391), [TalkAndroid](https://www.talkandroid.com/460491-how-to-play-neko-atsume-tips/), [Wikipedia](https://en.wikipedia.org/wiki/Neko_Atsume) |
| **Peridot** (Niantic) | Acariciar, alimentar, jogar bola, ensinar truques arrastando comida em padrões, procurar comida em superfícies reais | Os Dots têm "desejos" (um petisco, uma flor, ver um cão). Um LLM escolhe reações numa biblioteca grande de animações: "this really brought life into our characters" | [Dexerto](https://www.dexerto.com/gaming/peridot-niantic-review-2139367/), [Meta AI](https://ai.meta.com/blog/niantic-peridot-llama/) |
| **Duolingo** (Rive) | Nenhuma interação direta | Idle com aceno de cabeça, piscada e sobrancelha. Estados de corpo e de boca rodam em paralelo na state machine. Mais de 20 visemas por personagem | [Duolingo Blog](https://blog.duolingo.com/world-character-visemes) |
| **Finch** | Concluir metas de autocuidado, vestir, mandar o pássaro em aventuras | Usuários tratam o pássaro como pet de verdade ("my birb Dwight") e descrevem uma relação de reciprocidade. Gesto de carinho **[não verificado]**: só achei fontes de baixa qualidade | [Appbot](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/) |
| **Cats & Soup** | Mandar cozinhar, vestir, fotografar, dar peixe | Animações e sons elogiados, mas "some of the station animations are a bit repetitive" | [SplitMetrics](https://splitmetrics.com/apps/cats-soup/id1581431235), [TapTap](https://www.taptap.io/br/post/1721993) |
| **Desktop Goose / Shimeji** | Arrastar, soltar, arremessar com inércia | O ganso puxa o cursor e larga memes. Shimejis escalam janelas, caem e têm animação de "resistir" quando são arrastados | [Laptop Mag](https://www.laptopmag.com/news/i-let-the-goose-from-untitled-goose-game-rampage-all-over-my-desktop), [Chrome Web Store](https://chrome.google.com/webstore/detail/gohjpllcolmccldfdggmamodembldgpc), [shimeji-ee](https://github.com/gil/shimeji-ee) |
| **Bird Buddy** | Observar visitas reais | Notificação imediata só para visitantes raros (menos de 2 visitas na semana), o resto vai num resumo diário. Pássaros batizados geram aviso quando voltam | [Central de suporte (trecho indexado; página deu 403)](https://support.mybirdbuddy.com/hc/en-us/articles/13077682569233) |

Outros nomes da lista:

- **Pou**: a crítica do [Engadget](https://www.engadget.com/2014-01-08-a-huge-steaming-pile-of-pou.html) diz que o app não explica nada e só tem minijogos ultrassimples.
- **My Talking Tom 2**: anúncios constantes e "constant urgency to buy things" ([Common Sense](https://www.commonsensemedia.org/app-reviews/my-talking-tom-2)).
- **Webkinz e Neopets**: o laço é feito de barras de fome e felicidade. No Neopets o pet triste gera culpa ([UvA](https://mastersofmedia.hum.uva.nl/2010/10/pet-animal-2-0-neopets)).
- **Forest e Flora**: a árvore morre se você sai do app ([Headway](https://makeheadway.com/blog/forest-app-review/), [Business of Business](https://www.businessofbusiness.com/articles/flora-focus-productivity-app-review/)). Não existe interação com um ser vivo.
- **"Kinder Planet"**: não encontrei. O mais próximo é **Kinder World** (plantas e autocuidado, [SAYS](https://says.com/my/tech/kinder-world-lumi-interactive-game-review)).
- **"Pocket Love"** é um simulador de casal com cão ou gato ([Common Sense](https://www.commonsensemedia.org/app-reviews/pocket-love)).
- **"Hamster Town"**: o título é ambíguo. O jogo de itch.io tem hamsters que perambulam sem objetivo ([devlog](https://itch.io/devlog/116506/launch-of-hamster-town.amp)). A interação com o pet de nenhum dos dois foi verificada.
- **Animal Crossing**: villagers têm personalidades que definem fala e voz, e fazem festa no aniversário do jogador ([Nookipedia](https://nookipedia.com/wiki/Birthday), [Fandom](https://animalcrossing.fandom.com/wiki/Villager)). Não achei fonte primária sobre falas do tipo "não te vejo há dias".

---

## 2. As 15 mecânicas mais importantes para o Baru

Ordem por **impacto × viabilidade** num pet 2D procedural em Flutter (`CustomPainter` + `Ticker`). Base técnica sugerida: [`SpringSimulation`](https://api.flutter.dev/flutter/physics/SpringSimulation-class.html) para overshoot, [`HapticFeedback`](https://api.flutter.dev/flutter/services/HapticFeedback-class.html) para vibração e [`sensors_plus`](https://pub.dev/packages/sensors_plus) para inclinação. Referência de latência: com até 100 ms a reação "parece causada pelo usuário" ([NN/g](https://nngroup.com/articles/website-response-times/)).

### 1. Olhar vivo: segue o dedo e pisca de forma irregular
**Evidência:** Petz segue o cursor com a cabeça "no matter what its body doing" ([AAAI](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm)). Em nintendogs + cats os olhos seguem objetos e "in bright places, their pupils narrow". Cão vira a cabeça, gato move só os olhos ([Iwata Asks/GoNintendo](https://gonintendo.com/archives/143459-iwata-asks-nintendogs-cats-wii-sequel-almost-happened-originally-started-on)). Em Trico, fixar a cabeça antes do pescoço acabou com o ar "robótico" ([Ueda/Tanaka via Wikipedia e entrevistas](https://en.wikipedia.org/wiki/The_Last_Guardian)).
**Coreografia (proposta):**
- 0–80 ms após o toque: as pupilas saltam para o alvo (saccade).
- 80–250 ms: a cabeça segue com mola amortecida. Gata, raposa e coruja giram menos a cabeça e mais os olhos. Buldogue e lontra giram a cabeça inteira.
- Piscada a cada 2–6 s com intervalo sorteado; um tutorial de Rive no estilo Duolingo usa 2–5 s ([dev.to](https://dev.to/uianimation/building-duolingo-style-ai-mascot-animations-with-rive-2446)). Cada piscada dura ~150 ms (fecha 60, segura 30, abre 60). Em 15% das vezes, piscada dupla.
- Sem dedo na tela: a cada 3–8 s o olhar escolhe um ponto de interesse (um objeto do habitat, a borda da tela ou o próprio timer).

### 2. Carinho com zonas, direção e velocidade
**Evidência:** Petz reage conforme local, velocidade e humor. Pokémon-Amie tem pontos favoritos e pontos ruins, e rapidez demais conta como bater ([Bulbapedia via busca](https://bulbapedia.bulbagarden.net/wiki/Petting)). No Nintendogs, depois de carinho suficiente o cão rola de barriga e passa a pedir carinho ali ([MarioWiki](https://www.mariowiki.com/Nintendogs_(WarioWare_Gold))). Em gatos reais, a base da cauda gera as respostas mais negativas ([Ellis et al. 2015](https://agris.fao.org/search/es/records/65debad20f3e94b9e5d0b2ca)). Cães preferem carinho a elogio verbal e não mostraram saciedade em 8 sessões ([Feuerbacher & Wynne](https://pubmed.ncbi.nlm.nih.gov/25173617/), [Purdue](https://caninewelfare.centers.purdue.edu/?p=3924)).
**Coreografia (proposta):**
- Defina zonas por espécie: cabeça/bochecha, queixo, costas, barriga e cauda/base. Cada pet sorteia 1 zona favorita e 1 zona que não gosta no nascimento.
- 0–100 ms: orelhas giram para o dedo e o olhar sobe.
- 150–300 ms: o corpo se inclina 3–6° na direção do movimento ("pede mais").
- Depois de ~600 ms de carinho contínuo os olhos fecham pela metade, e depois de 1,5 s fecham por completo. A respiração desacelera ~20%.
- Velocidade ideal: 150–600 px/s, a favor do pelo (cabeça → cauda). Contra o pelo, os pelos/contorno se arrepiam e o pet faz uma careta curta de 300 ms. Rápido demais (>1500 px/s) gera um "ei!" e o pet se esquiva.
- Zona favorita por 2–3 s dispara o "derreter": rola de barriga (Nintendogs) ou faz biscoito com as patas. Haptic `selectionClick` a cada ~400 ms, que funciona como ronronado.
- Zona ruim: orelhas para trás e a cauda chicoteia uma vez em 200 ms. Na segunda vez, ele se afasta meio corpo.

### 3. Repertório de idle ponderado, sem loop
**Evidência:** Petz usa "constrained randomness" e camadas de "breathing, blinking, meowing, head shaking" ([Game Developer](https://gamedeveloper.com/design/gdc-classic-multiple-character-interaction-in-i-petz-i-games)). Um usuário de Pets Therapy elogia que os pets "actually nap and react instead of just looping the same animation", e outro critica "just looping animations on a timer" ([Product Hunt](https://www.producthunt.com/products/pets-therapy-desktop-pets)).
**Coreografia (proposta):**
- Camada base: a respiração segue frequência real de repouso, 15–30 por minuto para gatos ([WebVet](https://www.webvet.com/normal-cat-breathing-rate/)), ou seja, um ciclo de 2–4 s. Aplique ±10% de ruído por ciclo.
- Camada de micro-ações (12–20 por espécie): coçar, bocejar, lamber a pata, farejar, sacudir, esticar, olhar um inseto, trocar o peso das patas, cochilar.
- Seleção ponderada pelo humor e pela hora do dia, com *cooldown* por ação (a mesma ação não volta em menos de 60 s) e intervalo sorteado de 4–12 s entre micro-ações.
- Cada ação tem 2–3 variantes paramétricas: amplitude, velocidade (±15%) e lado.

### 4. Toque e cutucão com escalada (cócegas)
**Evidência:** Talking Tom: "Keep poking and discover hidden reactions" ([App Store](https://apps.apple.com/us/app/talking-tom-cat/id377194688)). No Pokémon-Amie, toques rápidos deixam o Pokémon bravo.
**Coreografia (proposta)**, contando toques numa janela de 1,5 s:
- 1º toque: squash de 8% em 80 ms, volta com mola em 220 ms e olha para o dedo.
- 2º: pulinho de susto.
- 3º e 4º: risadinha de cócegas com tremor de 6 Hz por 400 ms.
- 5º e 6º: bufa e vira de costas.
- 7º ou mais: "emburra" e ignora toques por 8 s.
- Raro (2%): reação secreta, como espirro, cair sentado ou um som engraçado.

### 5. Boop no nariz
**Evidência:** Nintendogs: "if you hold the stylus in front of their nose they will lick it" ([GamesFirst](https://gamesfirst.com/articles/2005/nintendogs-chihuahua-friends/)).
**Coreografia (proposta):**
- Toque no focinho: os olhos ficam vesgos por 120 ms e a cabeça recua 4 px.
- Em 30% das vezes vem um espirro: antecipação de 400 ms (inspira e a cabeça sobe), espirro em 100 ms (squash de 15%) e uma sacudida de 300 ms.
- Se o dedo fica parado sobre o nariz por mais de 700 ms, o pet fareja (narinas a 8 Hz) e depois dá uma lambida em 250 ms.

### 6. Saudação de retorno com memória de ausência
**Evidência:** No Nintendogs, depois de 2 dias de ausência o cão estava "in no mood to play". O cão pode até fugir ([Honolulu Advertiser](https://www.honoluluadvertiser.com/article/2005/Aug/26/en/FP508260312.html), [GamesRadar](https://www.gamesradar.com/nintendogs-review)). Usuários do Finch sentem que o pássaro "espera" por eles ([Appbot](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/)).
**Coreografia (proposta)**, sem punição:
- Menos de 1 h: olha e abana a cauda uma vez.
- 1–8 h: orelhas sobem, ele corre até a frente do habitat e dá dois pulinhos (anticipation de 150 ms).
- Mais de 1 dia: a primeira reação é uma pausa de 600 ms ("é você?"), depois corre e se esfrega.
- Mais de 3 dias: está dormindo ao abrir o app, acorda ao toque e mostra alegria redobrada. Nunca "triste" ou "doente".

### 7. O pet pede atenção (iniciativa)
**Evidência:** Petz: "if they really want something, they will just go and get it themselves" e trazem brinquedos ao usuário ([AAAI](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm)). Tamagotchi chama atenção sem necessidade real ([Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi)). Os Dots de Peridot têm "desejos" ([Dexerto](https://www.dexerto.com/gaming/peridot-niantic-review-2139367/)).
**Coreografia (proposta):** só fora do foco, no máximo 1 a cada 3–5 min de tela aberta.
- O pet olha para a câmera e segura o olhar por 1,2 s.
- Depois pega um item (bola, folha, peixe) e o leva até a "frente" da tela, que fica do lado do usuário.
- Ignorado: espera 6 s, cutuca o item uma vez e desiste com um suspiro, sem penalidade.
- Atendido em até 10 s: festa curta e um "+afeto" invisível.

### 8. Pegar no colo e arrastar
**Evidência:** Petz deixa pegar o pet no colo. Shimejis podem ser arrastados e "thrown with inertia", com animações de "resistir" ([Chrome Web Store](https://chrome.google.com/webstore/detail/gohjpllcolmccldfdggmamodembldgpc), [itch.io](https://pastaaa1.itch.io/cere-rru-shimeji)).
**Coreografia (proposta):**
- Long-press de 350 ms no corpo: o pet estica (stretch de 10% vertical). As patas pendem e balançam como pêndulo, com atraso proporcional à velocidade do dedo (follow-through).
- Personalidade decide a reação: o calmo relaxa, o arisco esperneia.
- Ao soltar, cai com gravidade e faz squash de 20% no contato (60 ms), com rebote por mola ou `HapticFeedback.lightImpact`. Depois sacode o corpo por 400 ms e olha para você.

### 9. Brinquedo arremessável específico de cada espécie
**Evidência:** Petz tem fetch e cabo de guerra. Miyamoto: o cão corre direto para o objeto, o gato encara e depois dá o bote ([GoNintendo/Iwata Asks](https://gonintendo.com/archives/143459-iwata-asks-nintendogs-cats-wii-sequel-almost-happened-originally-started-on), [Nintendo UK](https://www.nintendo.com/en-gb/Iwata-Asks-Nintendo-3DS/Vol-4-nintendogs-cats/1-Why-cats-Is-Smaller-in-the-Logo/1-Why-cats-Is-Smaller-in-the-Logo-204721.html)). Peridot tem bola ([Dexerto](https://www.dexerto.com/gaming/peridot-niantic-review-2139367/)).
**Coreografia (proposta):**
- Buldogue e lontra: assim que o dedo solta, partem atrás em 100 ms.
- Gata e raposa: rabo balança e a traseira rebola por 600–900 ms, depois vem o bote.
- Tartaruga: anda lento e às vezes desiste. É piada de personalidade.
- O pet só devolve o brinquedo em ~60% das vezes; no resto, deita com ele.

### 10. Alimentar arrastando a comida até a boca
**Evidência:** Pokémon-Amie (Poké Puffs) e Pou/Tom (feed) ([Common Sense](https://www.commonsensemedia.org/app-reviews/my-talking-tom-2)).
**Coreografia (proposta):**
- A comida entra num raio de 120 px: olhos fixam e o pet lambe os lábios (antecipação).
- A 60 px: a boca abre e o pescoço estica.
- No contato: 3 mastigadas de 180 ms cada, com farelos de partícula.
- Comida favorita: olhinhos fechados e um pulinho. Comida que não gosta: cheira e vira o rosto.

### 11. Dia e noite e sono real
**Evidência:** Tamagotchi e Nintendogs usam o relógio do aparelho ([Wikipedia](https://en.wikipedia.org/wiki/Nintendogs)).
**Proposta:**
- Pesos de idle mudam com a hora: manhã com espreguiçar, tarde com brincar, noite com bocejos e cochilos.
- Pet noturno (coruja, raposa) inverte os pesos.
- Dormindo, a respiração fica ~30% mais lenta. Um toque leve faz uma orelha mexer; o segundo toque o acorda devagar, com 800 ms de olho entreaberto.

### 12. Truques ensinados por gesto
**Evidência:** Nintendogs ensina com gestos de caneta e limita a 3–4 truques por dia ([NWR](https://www.nintendoworldreport.com/review/4394)). Peridot ensina com padrões de arrasto de comida.
**Proposta:**
- Gesto para baixo na cabeça = sentar. Círculo na barriga = rolar. Pinça na pata = dar a pata.
- Nas primeiras tentativas o pet erra de forma fofa e aparece um "?". Na terceira acerta e há um brilho.
- Limite diário de novos truques. Cria um motivo para voltar.

### 13. Piscada lenta de confiança
**Evidência:** Gatos respondem à piscada lenta do dono com estreitamento dos olhos e se aproximam mais de quem pisca devagar ([Humphrey et al. 2020, Sci. Rep.](https://researchportal.port.ac.uk/en/publications/the-role-of-cat-eye-narrowing-movements-in-cat-human-communicatio/)).
**Proposta:**
- Com afeto alto, o pet às vezes fecha os olhos devagar para o usuário (fecha em 400 ms, segura 600 ms, abre em 400 ms).
- Se o usuário tocar os olhos com 2 toques lentos, o pet devolve a piscada e ronrona. É um segredo descobrível.

### 14. Momentos raros, presentes e memória
**Evidência:** Iwata: "If we do things that are easily predictable, we won't be able to surprise people" ([Nintendo UK](https://www.nintendo.com/en-gb/Iwata-Asks-Nintendo-3DS/Vol-4-nintendogs-cats/1-Why-cats-Is-Smaller-in-the-Logo/1-Why-cats-Is-Smaller-in-the-Logo-204721.html)). Gatos de Neko Atsume deixam mementos ([Wikipedia](https://en.wikipedia.org/wiki/Neko_Atsume)). O Bird Buddy separa o raro do comum nas notificações.
**Proposta:**
- 1–3% das micro-ações são "raras": perseguir uma borboleta, cair do toco, cantar, ter um sonho que aparece em balão.
- O pet às vezes deixa um presente no habitat depois de uma sessão de foco longa.
- Registrar no álbum "primeira vez que…".

### 15. Inclinar e sacudir o celular
**Evidência fraca:** só achei exemplos de hobby e apps pequenos, como o iPetRock, que rola ao sacudir e depois cochila ([App Store, iPetRock](https://apps.apple.com/app/id302865248)). Nenhum produto grande documenta "tontura" **[não verificado como padrão]**.
**Proposta:** só fora do foco.
- Inclinação acima de 15°: o pet escorrega alguns px e se apoia com as patas.
- Sacudida forte: olhos em espiral por 1 s e depois um olhar de "sério?".

**Ficaram de fora do top 15**, por custo alto ou pouca evidência:
- Banho e secar: Nintendogs e Pou têm, mas é sujeira que vira obrigação.
- Voz: Talking Tom repete a voz e o reconhecimento do Nintendogs "é exigente" ([NWR](https://www.nintendoworldreport.com/review/4394)). Além disso, o microfone durante o foco é intrusivo.
- Esconde-esconde: não achei referência em nenhum produto pesquisado.
- Vestir: é cosmético e não dá vida.

---

## 3. Dez princípios de vida, com evidência

1. **Reagir sempre, rápido e com coerência.** "doesn't react at all → the illusion of life is broken" ([Petz](https://gamedeveloper.com/design/gdc-classic-multiple-character-interaction-in-i-petz-i-games)). A primeira resposta, nem que seja só o olhar, tem que vir em menos de 100 ms ([NN/g](https://nngroup.com/articles/website-response-times/)).
2. **Nunca repetir literalmente.** Use aleatoriedade restrita, cooldowns e variantes paramétricas ([Petz](https://gamedeveloper.com/design/gdc-classic-multiple-character-interaction-in-i-petz-i-games)). A repetição é a crítica nº 1 em [Cats & Soup](https://splitmetrics.com/apps/cats-soup/id1581431235), [Peridot](https://www.dexerto.com/gaming/peridot-niantic-review-2139367/) e até em [Nintendogs](https://www.nintendoworldreport.com/review/4394).
3. **Animar em camadas independentes.** Respiração, piscada, olhar, orelhas/cauda e ação principal rodam ao mesmo tempo, cada uma com o seu relógio ([Petz](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm)). Duolingo roda estados de corpo e de boca em paralelo ([Duolingo](https://blog.duolingo.com/world-character-visemes)). É o que quebra o "mesmo loop a cada segundo".
4. **Mostrar, não dizer.** "if they're not expressed, they're effectively not there". Em Petz o humor aparece em sobrancelhas, orelhas, andar e cauda, e não em barras ([Game Developer](https://gamedeveloper.com/design/gdc-classic-multiple-character-interaction-in-i-petz-i-games)).
5. **Personalidade e preferências individuais.** Petz tem gostos por pet ([AAAI](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm)). O Tamagotchi Uni tem personalidade que muda reações ([Toy Insider](https://thetoyinsider.com/tamagotchi-uni-opens-up-the-tamaverse)). Cada espécie de Pokémon tem os seus pontos favoritos.
6. **Especificidade de espécie.** Cão e gato "move completely different", e a primeira tentativa de gato com corpo de cão "was wagging its tail!" ([Nintendo UK](https://www.nintendo.com/en-gb/Iwata-Asks-Nintendo-3DS/Vol-4-nintendogs-cats/1-Why-cats-Is-Smaller-in-the-Logo/1-Why-cats-Is-Smaller-in-the-Logo-204721.html)). Os 9 bichos do Baru precisam de verbos de corpo próprios.
7. **Autonomia: a vida continua sem você.** Truques que só aparecem se você deixar o cão sozinho ([NWR](https://www.nintendoworldreport.com/review/4394)). Os gatos de Neko Atsume "decide to hang out for a bit until they get bored of you" ([AV Club](https://avclub.com/read-this-the-new-york-times-explains-neko-atsume-s-ap-1798244391)).
8. **Memória e consequência gentil.** Em Petz o cuidado muda a personalidade ([AAAI](https://alumni.media.mit.edu/~benres/verbiage/Socially%20Intelligent%20Virtual%20Petz.htm)). O Bird Buddy reconhece quem volta. O vínculo do Finch vem da reciprocidade ([Appbot](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/)).
9. **Física e peso.** Antecipação, squash e stretch, follow-through e arcos ([12 princípios](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)). Ueda diz que sem reação de músculo ao aterrissar "you can't feel its weightiness" e que é preciso eliminar o "popping" ([GIGAZINE](https://wbgsv0a.gigazine.net/gsc_news/en/20170115-the-last-guardian-ueda-humito-interview)). Overgrowth faz movimento fluido com poucos keyframes e molas procedurais ([GDC 2014](https://gamedeveloper.com/design/video-an-indie-approach-to-procedural-animation)).
10. **Multissensorial, coerente e com parcimônia.** A intensidade do haptic deve casar com a da animação, sem exagero: "the best haptic experience is one that people may not be conscious of, but miss when it's turned off". Precisa ser desligável ([Apple HIG](https://developer.apple.com/design/human-interface-guidelines/playing-haptics.md)). Petz usa latidos felizes, choramingos e ganidos como canal emocional.

---

## 4. Armadilhas apontadas por usuários e críticos

- **Loop e "GIF":**
  - "just looping animations on a timer" ([Product Hunt](https://www.producthunt.com/products/pets-therapy-desktop-pets)).
  - Estações repetitivas em Cats & Soup.
  - Em Peridot o cuidado "quickly becomes monotonous" e o crítico desistiu em ~1 semana ([Dexerto](https://www.dexerto.com/gaming/peridot-niantic-review-2139367/)).
- **Interação de um toque só:**
  - Em Cats & Soup o crítico queria "do a little more to interact with these felines" ([TapTap](https://www.taptap.io/br/post/1721993)).
  - Pou só tem minijogos ultrassimples ([Engadget](https://www.engadget.com/2014-01-08-a-huge-steaming-pile-of-pou.html)).
- **Anúncios e pressão de compra:**
  - Em My Talking Tom 2, "constant urgency to buy things" e anúncios aleatórios ([Common Sense](https://www.commonsensemedia.org/app-reviews/my-talking-tom-2)). O CARU recomendou mudanças em Talking Tom ([BBB](https://bbbprograms.org/media/newsroom/decisions/caru-reviews-outfit-7-s-talking-tom-cat-2-app-recommends-modifications)).
  - No Finch, preço e cobrança aparecem em 21–27% das reviews negativas.
  - Peridot cobra para chocar um Dot.
- **Perda e culpa:**
  - Reviews do Finch sobre streaks perdidos: "Finch broke my heart I cried for days" ([Appbot](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/)).
  - No Tamagotchi Uni é "surprisingly easy to kill" o pet ([Backloggd](https://backloggd.com/u/1chi50/reviews/)).
  - No Forest, árvores morrem quando o usuário sai do app por motivo legítimo ([Headway](https://makeheadway.com/blog/forest-app-review/)).
- **Tecnologia frágil:** reconhecimento de voz exigente no Nintendogs, AR obrigatório no Peridot que drena a bateria e câmera pouco confiável no Pokémon-Amie ([StrategyWiki](https://strategywiki.org/wiki/Pok%C3%A9mon_X_and_Y/Pok%C3%A9mon-Amie)).

## 5. Lacunas

- Não encontrei tempos publicados em ms para reações de nenhum desses jogos. Todos os ms aqui são **proposta**.
- Bulbapedia e Iwata Asks deram 403/503 no fetch. Os dados vieram de trechos indexados e de espelhos (GoNintendo, Nintendo UK).
- Os gestos exatos de carinho no Finch, a "tontura" por sacudir, o esconde-esconde e falas de saudade em Animal Crossing ficaram **[não verificados]**.
- "Kinder Planet" e "Hamster Town" não foram identificados com segurança.

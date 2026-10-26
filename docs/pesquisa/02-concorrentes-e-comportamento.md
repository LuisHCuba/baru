# Laudo 02 — Apps relacionados e comportamento do usuário

Data: 2026-10-26. Escopo: concorrentes e vizinhos no espaço "pet virtual +
hábito / foco / tempo de tela", e o que a pesquisa sobre comportamento diz
para o Baru. Este laudo **não** repete o relatório de agosto
(`docs/RELATORIO_UX_DUOLINGO.md`); ele cobre o que lá ficou de fora:
concorrentes diretos, crescimento visível do bicho, vínculo, culpa e
cuidado, personas e momentos do dia. Streak do Duolingo é tema de outro laudo.

## Como ler

Cada afirmação vem marcada:

- **[Fato]** — com fonte e link. Avaliações de usuários foram lidas
  diretamente na Google Play (endpoint público da página da loja) em
  2026-10-26; cito estrelas e data da avaliação. Citações ficam no original
  em inglês, com resumo em português.
- **[App]** — observação do Baru, com `arquivo:linha` ou imagem.
- **[Inferência]** — opinião minha a partir dos fatos. Pode estar errada.

Limites desta pesquisa, ditos de saída:

- **Reddit não pôde ser lido**: o domínio bloqueia o agente de busca. Usei
  avaliações da Play Store e da App Store, wikis de fãs, sites oficiais e
  artigos no lugar.
- O orçamento de buscas na web acabou no meio do trabalho. Ficaram **sem
  verificação** e por isso **fora** do laudo: o estudo de Lally et al. sobre
  tempo de formação de hábito, o artigo "Disposable love" de Bloch & Lemish
  sobre o Tamagotchi, o ensaio microrrandomizado de notificações de
  Bidargaddi et al. e dados de uso de celular por hora do dia no Brasil.
  Nenhum número deles aparece aqui.
- Não há dado de uso real do Baru. Personas e "dia típico" são hipóteses
  marcadas como tal.

---

## Sumário executivo

1. **O Baru não tem crescimento do bicho.** [App] `widgets/pet.dart` (4.036
   linhas) não tem nenhum parâmetro de idade ou estágio. A busca por
   `estagio` só acha o estágio do **habitat** (`data/progressao.dart:195-247`).
   O nível 4 e os 255 XP da trilha (`play-store/telas/pt/03-trilha.png`) são
   números num cartão: o bicho do nível 1 e o do nível 40 são o mesmo
   desenho, do mesmo tamanho. Todos os concorrentes que retêm bem tornam o
   progresso um **objeto que muda de forma**: o Finch faz o pássaro passar
   por cinco estágios (de ovo a adulto); no Forest a árvore cresce durante a
   sessão e vira floresta; no Pou o bicho cresce, e esse é um dos elogios
   mais curtidos da loja.
2. **O líder da categoria é o Finch, e ele faz quase tudo sem culpa.** [Fato]
   O Finch tem D1 de 54% e D7 de 37%, acima do Duolingo (51%/35%) na mesma
   comparação ([Deconstructor of Fun, dados Sensor Tower](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)).
   Ele faz isso com um pássaro que **nunca morre nem sofre**, que cresce por
   **dias cumulativos** (não seguidos), com ofensiva **opcional** e um widget
   vivo na tela inicial. É o modelo mais próximo das regras do Baru.
3. **Os apps de foco "com consequência" funcionam, mas cobram em culpa.**
   [Fato] O Forest declara que "a pequena sensação de perda é intencional"
   ([site oficial](https://www.forestapp.cc/)). Um usuário elogia o app por
   ser "the perfect combination of motivating and making you feel
   disappointed in yourself" ([App Store](https://apps.apple.com/us/app/forest-focus-for-productivity/id866450515)).
   A pesquisa mostra os dois lados (seção 5): um bicho triste aumenta a
   adesão no curto prazo, mas lapso destacado derruba o engajamento seguinte,
   e quem se perdoa procrastina menos depois.
4. **A queixa nº 1 de todos os concorrentes não é o design, é a
   monetização que muda de regra.** [Fato] Forest Plus, Finch, Opal, Plant
   Nanny, Daylio, Neko Atsume 2 e Focus Friend têm avaliações recentes de 1
   ou 2 estrelas de gente que **pagou** e perdeu acesso, ou viu coisa
   gratuita virar paga. O Finch apanha em 2026 por temas de mês que viraram
   propaganda de filme.
5. **Apps para usar menos o celular não podem prender a pessoa no app.**
   [Fato] Focus Plant e Finch recebem a mesma crítica: "I spent twice as much
   time in-app than IRL" ([Play, 2★](https://play.google.com/store/apps/details?id=com.shikudo.focus.google)).
   O Neko Atsume 2 é elogiado pelo oposto: "you cant advance until you put
   it down" ([Play, 5★](https://play.google.com/store/apps/details?id=jp.co.hit_point.nekoatsume2)).
   O Baru tem de ser recompensador em poucos segundos e recompensar o tempo
   **longe**.

As 10 recomendações priorizadas estão no fim (seção 9).

---

## 1. Os concorrentes, um por um

Formato fixo: proposta · loop · crescimento e como aparece · economia e loja
· notificações · o que elogiam · o que reclamam · monetização · copiar ·
evitar. Números da loja: Google Play, consulta de 2026-10-26.

### 1.1 Finch: Self-Care Pet — o modelo mais próximo

**Proposta.** [Fato] Cuidar de um pássaro ("birb") cuidando de si. Feito por
Stephanie Yuan e Nino Budi, ambos com histórico de ansiedade e depressão:
"We both struggled with anxiety and depression and found self-care
challenging to stick with" ([Paste](https://www.pastemagazine.com/article/finch-app-mental-health-virtual-pet-self-care)).
Mais de 10 milhões de downloads ([Android Developers Blog, #WeArePlay](https://android-developers.googleblog.com/2025/07/weareplay-app-game-founders-across-the-us.html)).
Play: 10M+, nota 4,9, 635 mil avaliações. App Store: 4,9 com 768 mil notas
([App Store](https://apps.apple.com/us/app/finch-self-care-pet/id1528595748)).

**Loop central.** [Fato] Metas de autocuidado dão **energia**; com a energia
cheia, o pássaro sai em **aventura** de cerca de 6 a 8 horas; metas feitas
durante a aventura **encurtam** a volta (cada ponto de energia tira 2
minutos); na volta, o pássaro conta uma **descoberta**, você responde, e a
resposta molda a personalidade dele (confiança, curiosidade, segurança,
resiliência, compaixão, lógica)
([wiki: Adventuring](https://finch.fandom.com/wiki/Adventuring),
[Energy](https://finch.fandom.com/wiki/Energy),
[Birb](https://finch.fandom.com/wiki/Birb)). A energia zera a cada dia, e
"se você deu um tempo, a energia necessária pode variar": a volta depois de
uma pausa é facilitada ([Energy](https://finch.fandom.com/wiki/Energy)).
O Deconstructor of Fun descreve isso como mecânica de **compromisso
marcado**, que cria "janelas orgânicas de retorno sem insistência
constante" ("anti-nag") ([DoF](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)).

**Crescimento e como aparece.** [Fato] Cinco estágios, por **aventuras
cumulativas** — dias em que a energia encheu, não dias seguidos
([wiki: Stages of Growth](https://finch.fandom.com/wiki/Stages_of_Growth)):

| Estágio | Entra após | Energia por aventura | Aventura dura | O que muda no corpo |
|---|---|---|---|---|
| Ovo | instalação | — | — | escolhe-se 1 de 6 ovos coloridos; a cor vira a do filhote |
| Bebê | eclode no onboarding | 15 | ~8 h | uma cor só, bico amarelo, pés cinza; só viaja na Finchie Forest |
| Criança pequena (toddler) | 7 aventuras | 20 | ~7 h | fica maior; topete e asas ficam cinza; **sorteia a cor do bico**; abre o estúdio de cores |
| Criança | 22 | 25 | ~6 h | maior; topete e asas customizáveis; **abre viagens** para outros lugares |
| Adolescente | 42 | 30 | ~6 h | maior; bochechas e pés customizáveis |
| Adulto | 67 | 35 | ~6 h | maior; barriga customizável; fim do crescimento |

Três coisas tornam isso visível: **o tamanho aumenta a cada estágio**; **cada
estágio abre uma parte nova do corpo** para pintar, e a troca vem com um
pequeno ritual (o app pede para sortear a cor da parte nova); e **cada
estágio abre funções** (viagens na fase criança). O adulto chega em 67 dias
de cuidado — curiosamente, o mesmo horizonte que o código do Baru estima para
percorrer a trilha (~67 dias, `data/progressao.dart:298-301`, citado no
relatório de agosto).

**Vínculo.** [Fato] Afagar a cabeça do pássaro solta corações e um
gorjeio; dez níveis de amizade com nomes ("Pals" → "Uber Soulmates"), cada um
com bônus permanente de pedras por aventura ([wiki: Friendship](https://finch.fandom.com/wiki/Friendship)).

**Economia e loja.** [Fato] Moeda única, **pedras-arco-íris**, ganhas em
quase tudo (metas, energia cheia, reflexões, "good vibes" para amigos). Elas
se gastam em quatro lojas: roupas (Mr. Prickles, vitrine que gira todo dia),
móveis, cores e viagens. Mr. Prickles dá 65–80 pedras grátis por dia a quem
abre a loja ([Rainbow Stones](https://finch.fandom.com/wiki/Rainbow_Stones),
[Mr. Prickles' Shop](https://finch.fandom.com/wiki/Mr._Prickles%27_Shop)).
Detalhe raro: **quem marca o humor mais baixo do dia ganha mais pedras por
toque** — o app paga mais no dia ruim ([Rainbow Stones](https://finch.fandom.com/wiki/Rainbow_Stones)).
A própria wiki avisa: "Some people find that they become too focused on
getting more stones and buying outfits, and stop paying attention to their
Goals."

**Eventos.** [Fato] Evento temático todo mês, com baú diário para quem enche
a energia e um micropet no dia 25 (no dia 20 para assinantes); 43 eventos até
abril de 2026 e 66 micropets até outubro de 2026
([Seasonal Events](https://finch.fandom.com/wiki/Seasonal_Events),
[Micropets](https://finch.fandom.com/wiki/Micropets)).

**Ofensiva.** [Fato] **Desligável** nas preferências; quem volta de uma
ausência escolhe o tamanho do compromisso: "Baby steps (2 days), Normal,
Intermediate, and On fire". Existe reparo de ofensiva com pedras
([wiki: Streaks](https://finch.fandom.com/wiki/Streaks)).

**Notificações e widget.** [Fato] Lembretes nos horários que a pessoa
escolhe ([Headway](https://makeheadway.com/blog/finch-app-review/)). O
widget é tratado como peça central de retenção: mostra o pássaro com a roupa,
a casa e a estação atuais, os estados "em andamento" e "concluído" e uma
barra única de progresso do dia. Para o DoF, widgets são "an under-used and
important retention unlock" ([DoF](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)).

**O que elogiam.** [Fato]
- Ausência de culpa: "You also don't get penalized/made to feel bad if you
  don't complete some goals for your day which I really like" ([App Store](https://apps.apple.com/us/app/finch-self-care-pet/id1528595748)).
- O bicho mantém o uso onde outros apps falharam: "All of them felt like a
  chore, but not Finch!" (mesma página).
- Resenha de 30 dias: "There's no punishment for the bird", e o dia perdido
  "feels like a pause" ([Headway](https://makeheadway.com/blog/finch-app-review/)).

**O que reclamam.** [Fato] (Play, 2★, mais relevantes)
- Falta de vínculo ativo: "If it's a pet to care for, I should be able to
  check and always interact with it. To get attached. But no, all it does
  is just do some things, ask for your opinion on something, then leaves for
  hours" (2026-02-21, 77 curtidas).
- Pedem mais Tamagotchi: "The ad claimed it was like a tamagotchi, but it
  isn't really... needing to feed your Birb would probably help more with
  motivation" (Play, avaliação em destaque).
- Propaganda disfarçada de tema: "we are on the second month of advertising
  some movie release... I pay for Plus, I don't want advertisements shoved
  down my throat" (2026-09-16); outra sobre o filme da Supergirl
  (2026-06-26) e a avaliação em destaque "The whole thing feels like an ad
  now".
- Inchaço: "now it just has way too much going on and it stresses me out
  just as much as everything else. all the extra side quests and limited
  time stuff" (2026-08-03).
- Cosmético mínimo pago: "you're telling me I can't even change my goal
  emojis without subscribing?" (2026-07-10).
- Perda de dados após atualização, travamentos e preço ($9,99/mês, $69,99/ano)
  ([Play](https://play.google.com/store/apps/details?id=com.finch.finch);
  preços confirmados em [Headway](https://makeheadway.com/blog/finch-app-review/)).

**Pesquisa.** [Fato] Uma autoetnografia de nove meses com o Finch durante
depressão sazonal achou quatro temas — melhora do autocuidado, **conexão
emocional**, interação social e **vício nos recursos gamificados** — e
descreve a passagem do apoio inicial para um uso movido a recompensa
([DOI 10.1145/3821402.3830132](https://doi.org/10.1145/3821402.3830132)).
É um caso único; serve de alerta, não de prova.

**Monetização.** [Fato] Grátis e sem anúncios; o Finch Plus dá recompensa
extra nos eventos, mais vagas raras na loja, customização e durações
longas. A wiki diz que não existem itens só para assinantes
([Finch Plus](https://finch.fandom.com/wiki/Finch_Plus)). Existe programa
"Guardian" que patrocina a assinatura de quem não pode pagar ($7,99 na App
Store).

**Copiar.** [Inferência] Crescimento por dias cumulativos com mudança de
corpo; ritual de troca de estágio; "ausência produtiva" (o bicho faz algo
enquanto você não está); widget vivo; ofensiva com compromisso escolhido;
pagar mais no dia ruim; patrocínio solidário.

**Evitar.** [Inferência] Inchaço de missões paralelas; eventos com prêmio
melhor para quem paga; parcerias com marca; cobrar por customização trivial.

### 1.2 Forest — o padrão do "foco com consequência"

**Proposta e loop.** [Fato] Você planta uma árvore ao iniciar a sessão; ela
cresce em tempo real; sair do app mata a árvore. Sessões concluídas viram uma
floresta (dia, semana, mês, ano). Moedas compram espécies, sons e o plantio
de árvores reais pela ONG Trees for the Future — o contador do site marca
2.102.946 árvores; até 5 por conta, só para Pro/Plus
([site oficial](https://www.forestapp.cc/), [Wikipedia](https://en.wikipedia.org/wiki/Forest_(application))).
Lançado em maio de 2014 pela Seekrtech; em dezembro de 2025 deixou de ser
pago e virou grátis com assinatura Forest Plus ([Wikipedia](https://en.wikipedia.org/wiki/Forest_(application))).
O site fala em 60M+ downloads. Play: 10M+, nota 4,3, 814 mil avaliações.

**Crescimento.** [Fato] O crescimento acontece **durante a sessão**: a
árvore passa de muda a árvore enquanto o tempo corre. As árvores mortas
ficam na floresta como registro — "an honest record of the journey, not a
verdict" ([site oficial](https://www.forestapp.cc/)). Uma avaliação pede
justamente para "more easily see different tree stages"
([Play](https://play.google.com/store/apps/details?id=cc.forestapp)).

**Consequência declarada.** [Fato] "That small sense of loss is
intentional." O mesmo site diz que o Forest é "a companion, not a coach",
sem vergonha nem sermão ([forestapp.cc](https://www.forestapp.cc/)). Na
modalidade "Plant Together", se uma pessoa desiste, morrem as árvores de
todos.

**Notificações e social.** [Fato] Sessões em grupo, desafios, eventos
sazonais, Time Guard (bloqueio agendado), lista de apps permitidos
([App Store](https://apps.apple.com/us/app/forest-focus-for-productivity/id866450515)).

**O que elogiam.** [Fato]
- Consequência concreta: "This app gives me a time limit that has a tangible
  consequence for breaking" (App Store, "Tangible for ADHD").
- Social que puxa: "I love looking at all the trees they grow when they
  focus too!" (Play, 5★, 2026-09-02).
- Pressão do grupo: "if I leave, everyone else's tree dies too" (Play, 5★,
  2020-05-01, 96 curtidas).
- Pausa: uma usuária conta que a pausa nova tirou o efeito ("there was no
  penalty") e que gostou de poder desligá-la (Play, 5★, 2026-04-26).

**O que reclamam.** [Fato] (Play)
- Funções pagas que foram retiradas: "Forest plus took away features that I
  HAD ALREADY PAID FOR" (2★, 2026-04-01); a perda de árvores já
  desbloqueadas na mudança de 2020: "all the tress I had unlocked were
  refund and I lost all of them" (1★, 2020-11-01, 495 curtidas).
- Pressão para assinar: "the constant premium upsells have pushed me to look
  for alternatives" (1★, 2026-05-27).
- Consumo como ansiedade: "the push toward overconsumption (even for digital
  rewards like trees) makes me anxious every time I open the app" (2★,
  2026-09-09).
- Eventos curtos demais: "have missed EVERY birthday item because their free
  collection period for the events are generally about 4 days" (2★,
  2024-05-31).
- Adulto sem pausa: "There are times I HAVE to leave. It's called
  responsibilities. This app is not adult friendly" (2★, 2026-04-03).

**Monetização.** [Fato] Forest Plus mensal de $5,99 e anual de $35,99 (preço
"early bird"), cristais e "elixir" avulsos ([App Store](https://apps.apple.com/us/app/forest-focus-for-productivity/id866450515)).

**Copiar.** [Inferência] Crescimento acontecendo **durante a sessão**,
diante dos olhos; a coleção acumulada (floresta) como prova do tempo
investido; foco junto com amigos; o propósito real (árvore de verdade) como
destino de moeda; registro honesto que "não é veredito".

**Evitar.** [Inferência] A morte como consequência — viola a regra 1. Também
retirar o que já foi pago, evento de 4 dias e tratar adulto como estudante
sem obrigações (pausa curta demais).

### 1.3 Flora — Green Focus

[Fato] Mesmo núcleo do Forest: escolher duração, plantar, a árvore morre se
você sair. Desafios com amigos dão uma árvore extra se ninguém sair;
lista de tarefas; jardim; plantio real opcional com Trees for the Future e
Eden Reforestation ([site oficial](https://flora.appfinca.com/)). Play:
100K+, nota 4,6.

- Elogio: "my progress is portrayed as the beautiful growing forest" (5★,
  2026-08-01); as plantas têm descrição com origem e uso, organizadas por
  região (5★, 2026-05-23).
- Reclamações: Android atrás do iOS em funções ("widgets don't work... we
  deserve the same quality", 1★, 2025-10-14); não dá para adicionar amigos
  entre sistemas ("I was HEARTBROKEN", 2★, 2026-01-12); arte gerada por IA nas
  paisagens afastou artistas (1★, 2025-11-04); o timer para em 3 horas sem
  avisar (2★, 2026-10-18)
  ([Play](https://play.google.com/store/apps/details?id=com.appfinca.flora.android)).

**Copiar.** [Inferência] Planta com ficha de conteúdo real (origem, uso) —
o Baru pode dar ficha às espécies e aos itens do habitat, todos brasileiros
(igarapé, manguezal, vitória-régia).
**Evitar.** [Inferência] Paridade fraca entre plataformas; arte gerada que o
público percebe como barata; teto silencioso de sessão.

### 1.4 Focus Plant — Pomodoro Forest

[Fato] O tempo de foco vira **gotas de chuva**, que regam cerca de 200
plantas e "limpam o lixo" de mundos devastados; há anúncios recompensados e
sessões em grupo ([Play](https://play.google.com/store/apps/details?id=com.shikudo.focus.google)).
Play: 1M+, nota 4,2, 57,8 mil avaliações. Plantas têm níveis (uma avaliação
fala em "level 3 plant").

- Elogio: "Positive reinforcement, not penalty based" (5★, 2023-11-24);
  "No paywall, not forced to watch ads, relaxing" (mesma avaliação); veio de
  outro app "after 'the other app' put up a paywall" (5★, 2024-05-11, 66
  curtidas).
- Reclamação central — **o jogo come o foco**: "I focused for 15 minutes on a
  task & was rewarded with so many points (& subsequent in-game points &
  little side-thingies to pay attention to), that I spent twice as much
  time in-app than IRL" (2★, 2022-07-03, 40 curtidas); "this app absolutely
  INUNDATES you with things to click on, micromanage, upgrade, and buy"
  (2★, 2026-09-09).
- Culpa logo na entrada: "immediately was pushed into a guilt trip for how
  much time I spend on my phone" (1★, 2026-08-10).
- Sessões perdidas por bug, sem crédito do tempo feito (1★, 2026-04-15).

**Copiar.** [Inferência] A metáfora de **restaurar** um lugar (o foco cura a
paisagem) combina com "habitat, não timer".
**Evitar.** [Inferência] Muitas micro-ações de recompensa depois de cada
sessão; anúncio recompensado; perder o tempo da sessão por falha técnica.

### 1.5 Focus Friend (Hank Green) — o fenômeno de 2025

[Fato] Um feijão que tricota enquanto você foca. Concluir a sessão rende meias
ou cachecóis, trocados por decoração do quarto; pegar o celular faz o feijão
derrubar as agulhas. Chegou ao nº 1 da App Store grátis
([NBC News](https://www.nbcnews.com/tech/tech-news/hank-green-focus-friend-app-rcna225967)).
A descrição da loja diz: "If you interrupt your Bean by turning off the timer,
they'll be really really sad" ([Play](https://play.google.com/store/apps/details?id=com.underthing.focus.friend)).
Play: 1M+, nota 4,9. Tem Live Activity, "Deep Focus Mode", cômodos novos e
skins do feijão.

- Elogios: "It doesn't try to shame you if you do stop the timer- the little
  bean's life doesn't depend on it" (5★, 2026-09-16, 60 curtidas); "the
  little nudge is just enough to keep me from doom scrolling endlessly" (5★,
  2025-09-06, 472 curtidas); uma pessoa com doença crônica usa o app para
  **descansar** sem culpa ("taking breaks... can feel undeserving", 5★,
  2026-09-13).
- Reclamações: a lista de apps permitidos é paga e sem ela o modo profundo
  bloqueia até o Spotify (2★, 2025-11-21, 45 curtidas); "there's too massive
  of a penalty if you 'cancel'. You have to lose ALL the socks... having
  integrity = loss of socks" (2★, 2025-08-19, 34 curtidas); o feijão
  continua tricotando com o TikTok aberto no modo normal (1★, 2026-09-27);
  rastreadores não declarados (1★, 2026-05-15, 16 curtidas).

**Copiar.** [Inferência] O bicho fazendo **uma atividade com resultado
visível** durante a sessão (o tricô cresce) — no Baru, o "Baru está
nadando" (`02-sessao.png`) poderia render algo palpável que aumenta na tela.
Também os cômodos que se abrem com o tempo e a copy que nega a vergonha.
**Evitar.** [Inferência] Punir a honestidade ("desistir" zera tudo, inclusive
o tempo já feito); cobrar pela lista de apps essenciais.

### 1.6 Habitica — o RPG de tarefas

[Fato] Hábitos, diárias e tarefas viram XP e ouro; hábito negativo tira vida
([Wikipedia](https://en.wikipedia.org/wiki/Habitica)). Play: 5M+, nota 4,6.

**Pesquisa.** [Fato] Diefenbach & Müssig (International Journal of
Human-Computer Studies, 2019) acharam efeitos contraproducentes **em todos
os participantes**; o mais comum foi "ser punido pelo Habitica em fases
especialmente produtivas", e houve quem recategorizasse tarefas como hábitos
sem prazo só para escapar da punição ([repositório LMU](https://epub.ub.uni-muenchen.de/77668),
DOI 10.1016/j.ijhcs.2018.09.004).

- Elogios: quem tem doenças crônicas usa para sustentar ~15 tarefas diárias
  ("helps that daily work feel less onerous", 5★, 2025-05-06, 402
  curtidas); "I've never skipped logging in a single day" (5★, 2026-08-13).
- Reclamações: perder pontos por fuso horário ("I cross into midnight... I
  lose points", 1★, 2022-09-20, 109 curtidas); recompensas sem sentido
  ("earn meaningless 'gold' & 'experience'", 1★, 2023-01-14); conteúdo que
  esvazia ("I'm already level 18 and will stop using the app soon", 2★,
  2024-12-24); não funciona offline
  ([Play](https://play.google.com/store/apps/details?id=com.habitrpg.android.habitica)).

**Copiar.** [Inferência] Ovos e pets colecionáveis como recompensa de
tarefa.
**Evitar.** [Inferência] Dano por falha (é exatamente o que a regra 1 do
Baru proíbe, e a pesquisa dá razão a ela); XP e ouro sem nada visível em que
se transformem — que é o estado atual do XP do Baru.

### 1.7 Pou — o pet clássico de massa

[Fato] Criatura alienígena para alimentar, limpar, fazer dormir e vestir;
minijogos dão moedas. A loja diz "watch it grow" ([Play](https://play.google.com/store/apps/details?id=me.pou.app)).
Play: **1B+ downloads**, nota 4,2, 11,2 milhões de avaliações. O criador,
Paul Salameh, disse que as pessoas "really got strongly attached to their
Pou" ([Wikipedia](https://en.wikipedia.org/wiki/Pou_(video_game))).

- Elogio mais curtido da amostra: "Love the gradual growth of the pou" (5★,
  2020-07-01, **6.547 curtidas**); outro lista "Watching him grow up" entre o
  que mais gosta (5★, 2024-07-13).
- Reclamações: barras que despencam ("When he sleeps, he doesn't gain ANY
  energy. It went from 100 down to 0", 1★, 2023-04-26); desbloqueios lentos
  demais ("The best accessories aren't unlocked before lvl 40", 2★,
  2024-12-22); anúncios novos depois de anos sem ("they finally got greedy",
  1★, 2026-07-15, 105 curtidas).

**Copiar.** [Inferência] Crescimento gradual e visível; cômodos e roupas como
expressão pessoal.
**Evitar.** [Inferência] Necessidades que decaem com o tempo (barra de fome,
energia) — é punição por ausência.

### 1.8 Tamagotchi (incluindo Uni e Paradise)

[Fato] Ciclo de vida em estágios (bebê, criança, adolescente, adulto, às
vezes sênior), cada um com duração fixa. A passagem é marcada por **uma
música e uma troca de aparência**, e a forma adulta depende do cuidado nas
fases anteriores. O bicho pode morrer de descuido, doença ou velhice; nas
duas primeiras versões morria em menos de meio dia sem cuidado. Escolas
proibiram, crianças fizeram enterros ([Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi)).
Vendas: 98,1 milhões de unidades até 2025. Tamagotchi Uni (2023) é o
primeiro com Wi-Fi e acesso ao "Tamaverse"; Tamagotchi Paradise (2025) tem
um disco de zoom e "volta a ser um bichinho" (mesma fonte).

**"Efeito Tamagotchi".** [Fato] Nome dado ao apego emocional a máquinas e
agentes de software; a página da Wikipedia é ensaística e marcada como tal,
então serve como definição, não como evidência
([Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi_effect)).

**Copiar.** [Inferência] O **momento sonoro e visual de troca de estágio**; a
forma adulta refletindo a história — no Baru, refletindo **o que a pessoa
fez**, nunca o que deixou de fazer (ex.: muito foco de manhã → plumagem de
alvorada).
**Evitar.** [Inferência] Morte, doença, cocô que adoece: tudo que fez o
Tamagotchi ser proibido.

### 1.9 Neko Atsume e Neko Atsume 2 — recompensar a ausência

[Fato] Você põe comida e brinquedos no quintal, fecha o app, e gatos vêm
enquanto você está fora; eles deixam peixes (moeda) e lembranças. Não tem
fim. Ganhou o prêmio de game design do CEDEC 2015 e chegou a 10 milhões de
downloads em dezembro de 2015. O criador queria um jogo que crianças
aproveitassem "sem muita habilidade ou tempo" ([Wikipedia](https://en.wikipedia.org/wiki/Neko_Atsume)).
Play: original 10M+ (4,8); sequência de outubro de 2024, 500K+ (4,8).

- Elogio que resume o design: "doesnt encourage nonstop use or grinding, in
  fact you cant advance until you put it down and stop using it" (NA2, 5★,
  2026-07-15); "you can pop in & see the kitties any time to brighten your
  day" (NA2, 5★, 2025-08-28, 104 curtidas).
- Reclamações sobre a sequência: **itens que quebram** e precisam de conserto
  ("Ruined items are no fun", 1★, 2025-04-10); assinatura mensal e peixe de
  ouro mais escasso (1★, 2024-12-19, 74 curtidas); exige internet (1★,
  2024-11-01) ([Play NA2](https://play.google.com/store/apps/details?id=jp.co.hit_point.nekoatsume2)).

**Copiar.** [Inferência] É o modelo certo para um app de **menos** tela:
algo acontece enquanto você está longe e há um motivo leve para espiar
**uma vez**. Também o álbum de colecionáveis (o "Catbook").
**Evitar.** [Inferência] Decaimento de item comprado (no Baru seria perda —
violaria a regra 1).

### 1.10 Pikmin Bloom — andar faz crescer

[Fato] Passos fazem mudas virarem Pikmin, que deixam trilha de flores no
mapa; há "lifelog" com foto e legenda diária; eventos colaborativos; moedas
compradas aceleram o progresso. Faturou US$ 44 milhões até abril de 2024
(AppMagic, via [Wikipedia](https://en.wikipedia.org/wiki/Pikmin_Bloom)).
Play: 5M+, nota 4,8.

- Elogios: "I walk longer and indifferent places just so I can get different
  decor themed Pikmin... I've named all my little guys" (5★, 2026-07-22);
  ver o caminho percorrido virar flores ("encouraging to see all the little
  flowers you plant as you walk", 5★, 2026-09-10).
- Reclamações: gacha que favorece veterano e quem paga (1★, 2026-08-10);
  inventário pago; travamentos e bateria (1★, 2026-06-07)
  ([Play](https://play.google.com/store/apps/details?id=com.nianticlabs.pikmin)).

**Copiar.** [Inferência] O comportamento real deixa um **rastro visível e
bonito** (flores no mapa); diário do dia com foto.
**Evitar.** [Inferência] Gacha; armazenamento pago.

### 1.11 Plant Nanny — beber água rega a planta

[Fato] Registrar água rega plantas de três níveis de dificuldade, numa estufa
com "criaturas" ([Play](https://play.google.com/store/apps/details?id=com.fourdesire.plantnanny2)).
Play: 5M+, nota 4,7. Não consegui confirmar, nesta pesquisa, se a planta
murcha quando a pessoa não bebe.

- Elogio: "Having little plants to take care of has made it much easier to
  stay motivated to take care of myself too" (5★, 2023-09-28).
- Reclamações: o app virou assinatura ("you can not use the app without
  paying a subscription fee", 1★, 2024-04-11, 62 curtidas); combinação de
  plantas para desbloquear criaturas ficou atrás da assinatura (2★,
  2025-01-13); notificações que não chegam (2★, 2025-07-11).

**Copiar.** [Inferência] Combinações que revelam criaturas raras
(colecionismo).
**Evitar.** [Inferência] Fechar atrás de assinatura o que era grátis.

### 1.12 Tide — foco, sono e som

[Fato] Timer Pomodoro com sons de natureza, sono, meditação; widgets, Live
Activities, Dynamic Island e "capas animadas" de tela de bloqueio; diz ter 30
milhões de usuários ([App Store](https://apps.apple.com/us/app/-/id1077776989)).
Play: 1M+, nota 4,4.

- Elogio: o despertar suave ("it gently wakes you up with birds or beautiful
  music", 5★, 2022-05-27, 59 curtidas).
- Reclamações: sessões que não registram depois de horas (1★, 2026-01-22, 45
  curtidas); onboarding longo após atualização: "WADING through seemingly
  endless pages of unskippable blah blah... exactly the opposite to what
  this app is trying to do" (2★, 2026-08-06, 40 curtidas); a anuidade passou
  de €12,99 para €61,99 (2★, 2019-11-19, 123 curtidas)
  ([Play](https://play.google.com/store/apps/details?id=io.moreless.tide)).

**Copiar.** [Inferência] A atmosfera sonora contínua durante o foco; o
despertar gradual como modelo de **som que acolhe**.
**Evitar.** [Inferência] Telas obrigatórias entre a pessoa e a ação.

### 1.13 Opal — controle de tempo de tela

[Fato] Sessões de foco, agendas, limites por app, Pomodoro, relatórios
semanais e ofensiva ([Play](https://play.google.com/store/apps/details?id=com.withopal.opal)).
"Focus Score" é a porcentagem do dia fora de apps distrativos; o gráfico por
hora é verde (foco) e vermelho (distração); apps podem ser marcados como
produtivos, distrativos ou neutros, e os neutros não contam; gemas
("MileStones") se desbloqueiam com progresso ([blog do Opal](https://opalapp.com/blog/introducing-the-new-opal-home-screen-track-your-screen-time-and-improve-your-focus)).
A própria loja cita a New Yorker: o Opal funcionou "through a combination of
mild friction, encouragement, and guilt" ([Play](https://play.google.com/store/apps/details?id=com.withopal.opal)).
Play: 500K+, nota 4,6.

- Elogio: "Every time I press an app mindlessly out of habit... and opal
  blocks it I think 'oh good! opal is working'" (5★, 2026-06-02).
- Reclamações: atualização que passou regras para o pago ("only allowing
  three rules for a free account, when I had at least 5-6 rules", 2★,
  2026-06-03); o app **recategoriza** sozinho apps de trabalho como
  distrativos (2★, 2026-08-30 e 2026-08-21); tempo medido errado (1★,
  2026-05-10); permissão de acessibilidade vista como risco (1★,
  2026-04-13); Android lançado sem paridade (1★, 2025-12-31).

**Comparação.** [App] O Baru já faz o que o Opal faz com categorias, e melhor
em dois pontos: quatro categorias com "passivo" (áudio) fora da meta, e a
escolha da pessoa persiste (`PRODUCT.md` §8; `05-tempo.png`).
**Copiar.** [Inferência] Um número único do dia fácil de ler; o gráfico por
hora.
**Evitar.** [Inferência] Recategorizar por cima da escolha da pessoa;
"culpa" como ingrediente declarado.

### 1.14 one sec — fricção antes de abrir

[Fato] Pausa com respiração antes de abrir um app escolhido. Estudo de
campo publicado na PNAS (Grüning, Riedel e Lorenz-Spreen, 2023), com 280
participantes durante seis semanas: as aberturas do app-alvo caíram 57%;
cerca de 36% das tentativas foram abandonadas na hora da intervenção, e as
tentativas caíram 37% em relação à primeira semana. Um experimento online
complementar (N = 500) achou que **a opção de desistir de abrir** teve o
efeito mais forte, e a mensagem de reflexão sozinha não funcionou
([registro da Univ. de Heidelberg](https://heibib.ub.uni-heidelberg.de/search/Record/1868867595),
[DOI](https://doi.org/10.1073/pnas.2213114120), [página do one sec](https://one-sec.app/max-planck-study)).
Ressalva: o fundador do app é coautor. Play: 1M+, nota 4,8.

- Elogio: "it doesnt completely shut off a short, it actually lets me watch
  that one" (5★, 2026-07-15) — gostam da **fricção sem proibição**.
- Reclamações: grátis só para um app (1★, 2024-12-29 e 2025-03-27); falha em
  Samsung e exige reconceder permissão todo dia (2★, 2025-01-26); a pausa
  dispara durante leitura legítima (2★, 2025-07-03)
  ([Play](https://play.google.com/store/apps/details?id=wtf.riedel.onesec)).

**Para o Baru.** [Inferência] A sobreposição do Baru é uma intervenção do
mesmo tipo. A evidência sugere que o que funciona é **oferecer a saída fácil
("voltar")** no momento do impulso, mais do que argumentar. O bicho
oferecendo "vamos voltar?" com um botão grande é o desenho certo; a fala
longa não é.

### 1.15 ScreenZen — gratuito por doação

[Fato] Bloqueio e pausa antes de abrir, limites e agendas; "the only
donation-supported screen time app"; diz ter mais de 500 mil usuários por mês
([site oficial](https://screenzen.co/)). Play: 1M+, nota 4,8.

- Elogio: a gratuidade com gorjeta opcional que dá recompensa **cosmética** e
  acesso vitalício garantido ("this one only has an OPTIONAL tip in exchange
  for a cosmetic reward", 5★, 2026-05-04, 85 curtidas); a respiração no lugar
  do bloqueio ("It's been retraining my nervous system through pauses", 5★,
  2026-08-24).
- Reclamações: para de funcionar sem aviso; pede permissões que já foram
  dadas; uma atualização deixou desligar o bloqueio "com dois toques" e a
  pessoa migrou para o Brick (1★, 2026-01-27)
  ([Play](https://play.google.com/store/apps/details?id=com.screenzen)).

**Para o Baru.** [Inferência] Falha silenciosa de permissão é a primeira
causa de 1★ em toda a categoria (ScreenZen, one sec, Opal, Flora). O Baru já
trata isso melhor que a média (`STATE.md`: "Faltar 'desenhar sobre outros
apps' deixou de ser silêncio"), mas precisa de um **verificador diário** de
saúde das permissões.

### 1.16 Daylio e Bearable — rastreadores

[Fato] Daylio: 10M+, nota 4,7. Uma avaliação de 1★ conta 2.632 dias seguidos
de registro e uma compra de 2018 que deixou de valer em 2026 sem aviso (1★,
2026-09-10); outra diz que a sequência travada virou estresse: "It was good
for the first 90 days, but now its just stressful" (1★, 2019-04-21); e
"cannot disable the endless steam of annoying achievement popups" (2★,
2026-08-30) ([Play](https://play.google.com/store/apps/details?id=net.daylio)).
Bearable: 500K+, nota 4,6; elogiado por correlações para levar ao médico e
criticado por notificações que param, o que "defeats the purpose" (2★,
2021-11-10) ([Play](https://play.google.com/store/apps/details?id=com.bearable)).

**Para o Baru.** [Inferência] Relevantes só em dois pontos. (1) **Pop-up de
conquista em excesso irrita** — a cadeia de celebração recomendada em agosto
precisa de botão de pular e de um teto. (2) Ofensiva longa vira fardo.

### 1.17 Duolingo — o que não é ofensiva

[Fato] **Widget**: mostra se a lição do dia foi feita e o tamanho da
ofensiva; a expressão do Duo muda com a hora e com o estado — fica mais em
pânico conforme a meia-noite se aproxima e relaxado depois da lição. Metade
de quem instalou o widget tem ofensiva de pelo menos 6 meses, e a retenção
foi melhor mesmo descontando que esse público já é mais comprometido. Os
usuários disseram que o widget funciona quase tão bem quanto as
notificações. A instalação só decolou quando o app passou a promover o
widget depois das lições, com um explicador animado ([blog do Duolingo](https://blog.duolingo.com/widget-feature/)).

[Fato] **Personagens vivos**: animações em Rive com máquina de estados;
piscar e acenar de cabeça rodam o tempo todo, há reação final a acerto e
erro e mais de 20 bocas por personagem para sincronizar a fala ([blog do
Duolingo](https://blog.duolingo.com/world-character-visemes/)).

**Para o Baru.** [Inferência] O widget do Baru já existe (2×2 e 4×2, humor
ao vivo — `ROADMAP.md:43-48`), mas o Duolingo mostra que **o que faz o widget
render é a promoção dele no pico emocional**. Copiar a variação por hora do
dia, mas com o tom invertido: o bicho **se aconchega** à noite, não entra em
pânico.

### 1.18 Outros do espaço (vistos de passagem)

[Fato] A própria descrição do Focus Plant lista dezenas de vizinhos (Plantie,
Study Bunny, Donut Dog, Fatty Cat, BFT Bear Focus Timer, Sleep Town,
Yeolpumta, Virtual Cottage e outros) — a categoria "bichinho + timer" está
saturada ([Play](https://play.google.com/store/apps/details?id=com.shikudo.focus.google)).
Não analisei esses um a um. O diferencial possível do Baru, sustentado pelo
que vi: **é o único da amostra que mede o tempo de tela real por categoria e
reage a ele com um bicho**, sem punir. Opal mede sem bicho; Forest e Focus
Friend têm bicho ou árvore mas não medem o resto do dia; Finch não mede tela.

---

## 2. Tabela comparativa

Play = Google Play em 2026-10-26 (downloads, nota). "Falha" = o que acontece
quando a pessoa não cumpre.

| App | Objeto | Crescimento visível | Falha | Moeda / loja | Monetização | Play | Lição para o Baru |
|---|---|---|---|---|---|---|---|
| **Finch** | pássaro | 5 estágios por dias cumulativos; tamanho + partes do corpo + funções | nada; o pássaro só demora a voltar | pedras; 4 lojas giratórias | assinatura cosmética e de conveniência | 10M+, 4,9 | crescer por dias cumulativos, nunca regredir |
| **Forest** | árvore | cresce durante a sessão; floresta acumulada | árvore morre (fica no registro) | moedas; espécies, sons, árvore real | Plus, cristais | 10M+, 4,3 | crescer **durante** o foco; coleção acumulada |
| **Flora** | árvore | jardim | árvore morre | sementes por região | grátis; plantio real opcional | 100K+, 4,6 | ficha de conteúdo real para itens |
| **Focus Plant** | ~200 plantas | níveis de planta; mundo restaurado | sessão perdida | gotas de chuva | anúncios + IAP | 1M+, 4,2 | metáfora de restaurar; **não** inchar |
| **Focus Friend** | feijão | tricô cresce; cômodos | feijão triste, perde meias | meias e cachecóis | Pro único, skins, assinatura | 1M+, 4,9 | atividade com resultado visível |
| **Habitica** | avatar RPG | nível, equipamento, pets | perde vida | ouro, gemas | assinatura, gemas | 5M+, 4,6 | punição é contraproducente |
| **Pou** | alien | cresce de tamanho | barras caem | moedas, minijogos | IAP, anúncios | 1B+, 4,2 | crescer é o elogio nº 1 |
| **Tamagotchi** | criatura | estágios com música + nova forma | morre | — | hardware | (não é app) | ritual de troca de estágio |
| **Neko Atsume 2** | gatos visitantes | álbum de gatos | itens quebram | peixes | assinatura | 500K+, 4,8 | recompensar a ausência |
| **Pikmin Bloom** | Pikmin + flores | mudas → Pikmin; mapa florido | nada | moedas | IAP, gacha | 5M+, 4,8 | rastro visível do comportamento |
| **Plant Nanny** | plantas | crescem com a água | (não verificado) | trevos | assinatura | 5M+, 4,7 | coleção por combinação |
| **Tide** | — | — | — | — | assinatura | 1M+, 4,4 | som que acolhe |
| **Opal** | gemas | gemas por marco | — | — | assinatura | 500K+, 4,6 | número do dia; "culpa" declarada |
| **one sec** | — | — | — | — | Pro | 1M+, 4,8 | dar a saída fácil no impulso |
| **ScreenZen** | — | — | — | — | doação | 1M+, 4,8 | gratuidade honesta |
| **Baru hoje** | 9 espécies | **nenhum no bicho**; só habitat e números | humor "saudade"; sem perda | folhas; 8 itens + roupas | trial + assinatura | (não publicado) | — |

---

## 3. O que o Finch faz com o pássaro, o Forest com a árvore, e como o Baru deve mostrar crescimento de forma extremamente visível

### 3.1 Finch

[Fato] Resumo da seção 1.1, com o que importa para o desenho:

1. **O começo é um ovo que a pessoa escolhe.** A cor do ovo vira a do
   filhote. O pássaro eclode no próprio onboarding — o primeiro momento do
   app já é um nascimento.
2. **O relógio é cumulativo.** Estágios contam aventuras, ou seja, dias em
   que a energia encheu. Faltar não desfaz nada; só não avança.
3. **Cada estágio é maior.** "As it reaches each stage it will increase in
   size."
4. **Cada estágio abre uma parte nova do corpo** (bico → topete e asas →
   bochechas e pés → barriga), e a troca é um ritual: o app pede para
   sortear a cor da parte nova.
5. **Cada estágio abre função** (viagens na fase criança) e muda o ritmo
   (pede mais energia, mas a aventura dura menos).
6. **O horizonte é longo e conhecido**: adulto em 67 dias de cuidado.

Fonte: [Stages of Growth](https://finch.fandom.com/wiki/Stages_of_Growth),
[Birb](https://finch.fandom.com/wiki/Birb).

### 3.2 Forest

[Fato]

1. **O crescimento acontece na frente da pessoa**, durante a sessão: a muda
   vira árvore enquanto o tempo corre.
2. **A sessão vira um objeto permanente** na floresta do dia, da semana, do
   mês e do ano. O progresso de longo prazo é uma **paisagem que se enche**.
3. **O fracasso também fica**, como árvore morta — "not a verdict", mas
   visível.
4. Fraqueza apontada pelos próprios usuários: é difícil ver os estágios e o
   nome das árvores no inventário ([Play](https://play.google.com/store/apps/details?id=cc.forestapp)).

Fonte: [forestapp.cc](https://www.forestapp.cc/).

### 3.3 O que o Baru tem hoje

[App]

- O bicho tem o mesmo tamanho e a mesma forma do primeiro dia ao centésimo:
  as 36 capturas `home-<especie>[-horario].png` mostram cada espécie numa
  única forma adulta. Não há parâmetro de idade em `widgets/pet.dart`.
- O progresso existe como **número**: "Nível 4 · 255 XP · 115 XP para o
  nível 5" e "Vínculo · 23 afagos" (`03-trilha.png`). Nenhum deles muda o
  desenho.
- O que muda de forma é o **habitat** (Lagoa → Igarapé → Manguezal…,
  `03-trilha.png`; `data/progressao.dart:215-220`) e a **raiz**, desenhada
  pequena num quadro de 160 px (`08-sequencia.png`).
- Durante a sessão nada cresce: o bicho nada parado sobre um fundo liso, com
  uma barra fina (`02-sessao.png`).
- **O bicho da sobreposição é outro bicho.** `OverlayDoBaru.kt:300-380`
  desenha ovais genéricas (corpo, barriga, cabeça, focinho), com exceção só
  para as orelhas da coruja (`:335`). Já o **widget** desenha o `PetView`
  real do Flutter e o grava como PNG (`services/widget_service.dart:196-202`
  e `:224`). O caminho técnico para o item 7 do briefing já existe no
  próprio app.

### 3.4 Proposta: o ciclo de vida do bicho do Baru

**Princípios** [Inferência, apoiada nas seções 1 e 5]:

- **Cumulativo e monotônico.** O estágio sobe por **dias de cuidado**
  acumulados (dia com ≥1 sessão concluída **ou** descanso cumprido) e
  **nunca desce**. Não depende da raiz: quebrar a raiz não atrasa o
  crescimento. Isso respeita a regra 1 e evita o efeito de "sequência
  quebrada" (seção 5.3).
- **Diferença absurda entre estágios.** Não é escala de 5%. Muda tamanho,
  proporção cabeça/corpo, traços da espécie, postura e repertório de
  animação. O teste é este: um print de cada estágio, lado a lado, sem
  legenda, e qualquer pessoa ordena certo.
- **Começo fiel à espécie.** Quem nasce de ovo começa ovo; mamífero começa
  como recém-nascido no ninho. "Conforme a espécie", como pede o briefing.
- **Cada estágio dá algo novo para fazer**, não só para ver.

**Estágios por espécie** [Inferência — proposta de direção de arte; o laudo
de cada pet aprofunda]:

| Espécie | Estágio 0 (início) | 1 Filhote | 2 Jovem | 3 Adolescente | 4 Adulto |
|---|---|---|---|---|---|
| Coruja (Nina) | **ovo** branco no oco da árvore, racha aos poucos | bola de penugem cinza, olhos enormes, sem tufos | penugem misturada com penas, tufos curtos | asas com padrão, tufos inteiros | plumagem completa, disco facial marcado, voo curto |
| Pinguim (Nino) | **ovo** sobre os pés de um adulto fora de quadro | penugem cinza-felpuda | "smoking" aparecendo em manchas | smoking quase completo | smoking completo, mergulho |
| Tartaruga (Toco) | **ovo** semienterrado na areia | filhote do tamanho de moeda, casco liso | casco com os primeiros escudos | escudos com padrão | casco desenhado completo, passo lento |
| Axolote (Lume) | **ovo gelatinoso** com o embrião visível | larva translúcida, brânquias mínimas | brânquias crescendo, pernas da frente | quatro patas, brânquias cheias | brânquias exuberantes, cor plena |
| Capivara (Baru) | **recém-nascido** dormindo enrolado num ninho de capim | filhote listrado de pelo fofo, cabeça grande | proporção de jovem | quase adulto | adulto, com o pássaro pousado nas costas |
| Lontra (Rio) | recém-nascido de olhos fechados na toca | filhote que boia de barriga para cima | nada desajeitado | nada com estilo | adulto que usa pedra como ferramenta |
| Gata (Mel) | recém-nascida de olhos fechados no cesto | filhote de olhos azuis e orelhas grandes | jovem desengonçado | quase adulta | adulta elegante |
| Raposa (Faísca) | recém-nascido escuro na toca | filhote de focinho curto | focinho alongando, cauda engrossando | ponta branca da cauda | adulta de cauda cheia |
| Buldogue (Bolota) | recém-nascido rosado no cobertor | filhote dobradinho de rugas | jovem de orelha meio caída | orelha de morcego em pé | adulto em bloco |

**Ritmo** [Inferência]. Ancorar no horizonte que o Finch valida (adulto em
67 dias de cuidado) e no que o Baru já tem (trilha de ~67 dias). Sugestão
inicial: estágio 0 → 1 na **primeira sessão concluída**; 1 → 2 com 7 dias de
cuidado; 2 → 3 com 21; 3 → 4 com 45. Os números entram em
`data/progressao.dart` como tudo que é balanceamento, e se ajustam com dado
real.

**Espécies conquistadas depois** [Inferência]. Uma espécie liberada no passo
13 chega como ovo ou recém-nascido — o desbloqueio vira um nascimento, que
celebra mais que um ícone liberado. Para ninguém sentir que "perdeu" tempo,
dias de cuidado contam **em dobro** para quem ainda não é adulto enquanto a
pessoa tem outro bicho já adulto. Trocar de espécie nos ajustes nunca
rebaixa nenhuma das duas.

**Contas existentes** [Inferência, e é **mudança que precisa de ADR**]. O
contrato já tem "piso de posse" para a trilha (`PRODUCT.md` §8B). O mesmo
vale aqui: o estágio inicial de uma conta antiga sai do histórico (dias com
sessão concluída), **arredondado para cima**. Nenhum usuário atual pode
abrir o app e ver o bicho adulto virar filhote — isso seria lido como perda,
e perda viola a regra 1. Em caso de dúvida, quem já tem conta começa adulto
e ganha a cerimônia e o álbum com os estágios "que ele viveu".

**Como mostrar o crescimento (seis lugares)** [Inferência]:

1. **Cerimônia de eclosão e de crescimento**, em tela cheia: o ovo balança,
   racha em três toques da pessoa (como a toca do resgate), luz, som próprio
   de cada espécie, háptico em crescendo. Para mamíferos: o filhote abre os
   olhos pela primeira vez. Na troca de estágio, silhueta branca → nova
   forma (o recurso clássico de "evolução"), seguida da escolha de uma
   coisa nova — cor de uma parte do corpo, como no Finch, ou nome de um
   truque novo.
2. **Barra do próximo crescimento na home**, colada à cena: "Nina cresce
   em 3 dias de cuidado", com a silhueta do próximo estágio. Hoje o nível
   fica escondido na aba Trilha.
3. **Álbum de crescimento** no perfil do bicho: os cinco estágios em
   linha, os vividos com a data ("chocou em 12/10"), os futuros como
   silhueta. É o equivalente ao "Catbook" do Neko Atsume.
4. **Cartão "antes e depois" compartilhável** a cada estágio, usando o motor
   do `CartaoDaRaiz` que já existe.
5. **Crescimento dentro da sessão** (lição do Forest e do Focus Friend):
   durante o foco, algo do bicho avança na tela — o ovo aquece e mexe; o
   filhote junta gravetos no ninho; o adulto constrói alguma coisa. No
   fim, o objeto vai para o habitat. Hoje `02-sessao.png` tem só uma barra
   fina.
6. **O mesmo bicho em todo lugar**: home, sessão, widget, ícone e
   **sobreposição**, no estágio, pelagem, roupa e humor atuais (seção 7, R2).

**Como fazer em Flutter/Android** [Inferência técnica]:

- `PetView` recebe `estagio` (0–4). Para cada espécie, o `CustomPainter`
  ganha (a) proporções por estágio (escala total, razão cabeça/corpo,
  comprimento de membros), interpoladas com `lerpDouble` para que a
  cerimônia anime a transição, e (b) flags de traço (tufos, brânquias,
  escudos, smoking). Nove espécies × cinco estágios dá 45 desenhos. No
  `CustomPainter` atual (~4.000 linhas) isso é **G**. Alternativa a avaliar
  no laudo visual: Rive com máquina de estados (o que o Duolingo usa),
  que dá estágio × humor × atividade num só arquivo por espécie.
- Dado: `diasDeCuidado` derivado de sessões e descansos (já persistidos),
  com `estagioMinimo` gravado (piso) e sincronizado.
- Testes: golden por espécie × estágio × humor; teste de que o estágio nunca
  desce; teste de que a migração respeita o piso.

**Critério de aceite.** Cinco capturas da mesma espécie, uma por estágio,
mostradas sem legenda a cinco pessoas: todas ordenam certo. A primeira
sessão concluída de uma conta nova dispara a eclosão. Nenhum caminho de
código diminui `estagio`.

---

## 4. Por que pessoas abandonam apps de hábito, e o que mantém o uso diário

### 4.1 Abandono — dados com fonte

- [Fato] **A queda é brutal e precoce.** Em 93 apps de saúde mental com pelo
  menos 10 mil instalações, a retenção mediana foi de **3,9% em 15 dias e
  3,3% em 30 dias** (Baumel et al., JMIR 2019, [link](https://www.jmir.org/2019/9/e14567)).
  Rastreadores (6,1%) e apps de suporte entre pares (8,9%) retiveram mais que
  exercícios de respiração (0,0%) aos 30 dias.
- [Fato] **Lembrete ajuda a repetir, mas atrapalha o hábito.** Num estudo de
  4 semanas, lembretes ajudaram a repetir o comportamento, mas impediram que
  ele ficasse automático; **gatilhos ligados a eventos** da rotina geraram
  mais automaticidade. O reforço positivo isolado não teve efeito medido. Na
  revisão de 115 apps, quase todos se apoiavam só em autorregistro e
  lembrete (Stawarz, Cox & Blandford, CHI 2015, [UCL](https://discovery.ucl.ac.uk/id/eprint/1468224/)).
- [Fato] **Ver a sequência quebrada derruba o uso seguinte.** Em sete
  estudos, destacar uma sequência intacta aumentou o engajamento seguinte em
  relação a destacar uma quebrada; o efeito piora quando a pessoa culpa a si
  mesma pela quebra e diminui quando é possível "consertar" a sequência
  (Silverman & Barasch, Journal of Consumer Research 2023,
  [repositório](https://udspace.udel.edu/items/42ce576b-8e1f-429a-8541-e29e48dbcfbb),
  [nota da Univ. do Colorado](https://www.colorado.edu/business/news/2023/04/20/research-streaks-marketing-tech-barasch)).
- [Fato] **Punição gamificada gera efeito contrário** (Habitica, seção 1.6).
- [Fato] **O que as avaliações mostram** (seção 1, contagem minha nas
  avaliações lidas): as causas de 1 e 2 estrelas se repetem em quase todos
  os apps — (1) monetização que muda de regra ou retira o que foi pago;
  (2) bugs que **perdem progresso ou sessão**; (3) permissões que falham em
  silêncio; (4) inchaço, com mais coisa para clicar do que tempo poupado;
  (5) falta de vínculo ou de "algo mais" depois de algumas semanas (Finch,
  Habitica "level 18 and will stop").

[Inferência] Para o Baru isso vira cinco regras: nunca perder sessão
(gravar a cada minuto e recuperar após crash), nunca retirar o que foi pago,
checar permissão todo dia e dizer na hora, manter a visita ao app curta, e
ter algo novo para **ver** a cada semana — o crescimento é justamente isso.

### 4.2 O que mantém o uso diário

- [Fato] **Presença ambiente.** No UbiFit Garden, um jardim no papel de parede
  do celular que florescia com a atividade física, o grupo **com** a tela
  manteve o nível de atividade inclusive nas semanas de feriado, e o grupo
  sem ela caiu de forma significativa (Consolvo et al., CHI 2008, experimento
  de 3 meses, N = 28; [PDF](https://makeabilitylab.cs.washington.edu/media/publications/Consolvo_ActivitySensingInTheWildAFieldTrialOfUbifitGarden_CHI2008.pdf)).
  O widget do Duolingo (seção 1.17) e o do Finch (seção 1.1) repetem o
  mesmo achado em produto.
- [Fato] **Compromisso marcado em vez de insistência.** A aventura do Finch
  cria a volta "sem insistência constante" ([DoF](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl));
  os gatos do Neko Atsume vêm enquanto você está fora.
- [Fato] **Um objeto que muda.** "Love the gradual growth of the pou"
  (6.547 curtidas); a floresta do Forest; o mapa florido do Pikmin.
- [Fato] **Social cooperativo.** "I made all my friends get this app"
  (Forest); desafios em grupo no Flora; "good vibes" no Finch dão energia a
  quem manda.
- [Fato] **Evento mensal**, desde que a janela seja longa (Finch: o mês
  inteiro) e não curta (Forest: cerca de 4 dias).

### 4.3 Apego ao personagem

- [Fato] **Bicho virtual muda comportamento real, pelo menos no curto
  prazo.** Adolescentes (N = 39, 9 dias) com um pet no celular que reagia à
  foto do café da manhã tomaram café com muito mais frequência; o melhor
  grupo recebia feedback **positivo e negativo**; os autores sugerem que
  "Teenagers may have eaten breakfast simply to avoid seeing their pet be
  sad" (Byrne et al., 2012, [Cornell](https://news.cornell.edu/node/271155)).
- [Fato] Fish'n'Steps ligou passos ao crescimento de um peixe virtual e
  incentivou exercício num estudo de 14 semanas com 19 pessoas (Lin et al.,
  UbiComp 2006, [DOI](https://doi.org/10.1007/11853565_16)).
- [Fato] **Fofura melhora o cuidado e o foco.** Depois de ver imagens de
  filhotes, participantes melhoraram 43,9% numa tarefa motora fina (contra
  11,9% com animais adultos) e 15,7% numa busca visual (contra 1,4%)
  (Nittono et al., PLoS ONE 2012, [link](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0046362)).
  [Inferência] É um argumento a favor de os primeiros estágios serem
  **filhotes de verdade**, e de o filhote aparecer na sessão de foco.
- [Fato] O apego é o que os usuários pedem: "To get attached" (Finch, 2★);
  "really got strongly attached to their Pou" (criador do Pou); "I've named
  all my little guys" (Pikmin).
- [Fato] E é também risco: a autoetnografia do Finch descreve "Addiction to
  Gamified Features" ([DOI](https://doi.org/10.1145/3821402.3830132)); a wiki
  do Finch alerta para quem passa a viver de pedras e roupas.

[Inferência] O Baru já tem a matéria-prima do apego (afago com háptico,
corações, nome editável, 9 espécies). O que falta é **história**: o bicho
não tem passado visível (nasceu quando? o que viveu?) nem futuro visível (o
que vai virar?). O ciclo de vida da seção 3 é a forma mais barata de dar as
duas coisas.

---

## 5. Culpa contra cuidado — por que o Baru proibiu punição e o que a literatura diz

### 5.1 O que o Baru decidiu

[App] `PRODUCT.md` §1: "O animal nunca morre, nunca perde nada, nunca culpa
o usuário... Abandonar uma sessão = sem recompensa, nada mais." Existe,
porém, um **sinal negativo leve**: o humor `missing_you` ("saudade") quando
há desistência em aberto no dia ou dois dias sem abrir (§3), que **sara**
com uma sessão concluída (ADR-020, `DECISIONS.md:682-683`).

### 5.2 O que a evidência diz, dos dois lados

**A favor de algum sinal negativo** [Fato]:

- O pet triste aumentou a adesão de adolescentes por 9 dias (Byrne et al.,
  [Cornell](https://news.cornell.edu/node/271155)).
- Usuários do Forest e do Focus Friend valorizam uma consequência
  "tangível"; o Forest admite que a perda é intencional; o Opal é descrito
  como funcionando por "mild friction, encouragement, and guilt".

**Contra a punição** [Fato]:

- Habitica: efeitos contraproducentes em todos os participantes, com gente
  driblando o sistema para não ser punida (Diefenbach & Müssig 2019).
- Sequência quebrada em destaque reduz o engajamento seguinte, mais ainda
  quando a pessoa se culpa (Silverman & Barasch 2023).
- **Autoperdão reduz procrastinação futura.** Estudantes que se perdoaram
  por procrastinar antes da primeira prova procrastinaram menos antes da
  segunda (Wohl, Pychyl & Bennett, Personality and Individual Differences
  2010; resumos em [Psychology Today](https://www.psychologytoday.com/us/blog/dont-delay/200903/self-forgiveness-reduces-procrastination)
  e [PsyBlog](https://www.spring.org.uk/2010/05/procrastinate-less-by-forgiving-yourself.php)).
  Não li o artigo original; as fontes divergem no N (119 ou 134).
- **Autocompaixão aumenta a motivação para melhorar.** Em quatro
  experimentos, quem adotou postura autocompassiva quis mais aprender com o
  erro e estudar para melhorar (Breines & Chen, Personality and Social
  Psychology Bulletin 2012; resumo em
  [Psychology Today](https://www.psychologytoday.com/us/blog/the-science-of-willpower/201206/does-self-compassion-or-criticism-motivate-self-improvement)).
  Também não li o original.
- Avaliações: "You also don't get penalized/made to feel bad" (Finch, 5★);
  "It doesn't try to shame you" (Focus Friend, 5★); "Positive reinforcement,
  not penalty based" (Focus Plant, 5★); "pushed into a guilt trip" (Focus
  Plant, 1★); "having integrity = loss of socks" (Focus Friend, 2★).
- O Tamagotchi com morte foi proibido em escolas e levou crianças ao luto
  ([Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi)).

### 5.3 Leitura para o Baru

[Inferência]

1. **A regra do Baru está do lado certo para um app de longo prazo e de
   saúde.** O que funciona com sinal negativo foi medido em dias (Byrne: 9
   dias); o que dá errado com punição aparece em semanas (Habitica, sequência
   quebrada). O público do Baru inclui quem já se sente mal com o próprio
   uso do celular — culpa em cima de culpa é o caminho da desinstalação.
2. **"Sem punição" não precisa significar "sem consequência".** A
   consequência boa é: (a) **imediata** (vale para a sessão, não para a
   vida do bicho), (b) **pequena**, (c) **reparável em um passo**, (d) **sem
   perda**. É o desenho do Focus Friend (o feijão solta as agulhas) sem a
   parte ruim (perder as meias já ganhas).
3. **A arte da "saudade" hoje lê como bronca.** [App] Em
   `play-store/arte/pet-owl-saudade.png`, a coruja tem sobrancelhas grossas
   inclinadas para dentro e uma gota de suor: lê-se irritação, não saudade.
   Saudade é olhar a porta, segurar um objeto da pessoa, orelhas baixas,
   sentar perto da entrada — e **alegrar-se ao ver a pessoa**. A reação de
   reencontro precisa ser maior que a de tristeza.
4. **O crescimento nunca pode depender da raiz.** O Finch separa: ofensiva é
   opcional, crescimento é cumulativo. No Baru, a raiz pode continuar com o
   seu congelamento, mas o bicho cresce com qualquer dia de cuidado.
5. **Pagar mais no dia difícil** (lição do Finch). Hoje, dia de muito tempo
   de tela dá humor `sleepy`. Que tal o dia difícil render uma missão curta
   e generosa de "recomeço" (5 minutos de foco = folhas cheias)? Isso
   transforma o pior dia no mais acolhedor, sem premiar o excesso.
6. **Nada de copy que acusa.** A sobreposição é o lugar de maior risco: ela
   aparece no momento em que a pessoa já se sente pega. Usar a lição do one
   sec: o que reduz o uso é **dar a saída fácil**, não o sermão.

---

## 6. Personas prováveis e o dia típico de cada uma

[Inferência — hipóteses] Não há dado de uso. As personas saem de três
fontes: as respostas que o próprio quiz do Baru oferece ("O que você quer do
Baru": menos tempo de tela, mais foco, uma rotina que eu mantenha, só
companhia; "O que mais rouba seu foco": redes sociais, vídeos, jogos,
mensagens e grupos — `lib/l10n.dart:772-805`), o perfil de quem escreve nas
lojas dos concorrentes (estudantes no Forest e no Focus Plant; trabalho
remoto no Focus Friend; TDAH, doença crônica e depressão no Finch e no
Habitica; vício em vídeo curto no one sec e no ScreenZen) e o contexto do
Brasil — 183 milhões de pessoas online, 86,2% da população; YouTube e
Instagram com mais de 140 milhões de usuários alcançáveis cada
([DataReportal 2025](https://datareportal.com/reports/digital-2025-brazil)).
Validar com o funil e com entrevistas antes de decidir com base nelas.

### P1 — Júlia, 19, cursinho / faculdade ("mais foco"; rouba: vídeos)

- 7h: acorda e abre o Instagram antes de levantar.
- 8h–12h: aula; celular na mesa.
- 14h–18h: estudo em casa; perde blocos de 20 minutos em vídeo curto.
- 19h: academia ou trabalho de meio período.
- 22h–1h: "só mais um vídeo" na cama.
- **Onde o Baru entra:** 13h45, sessão de 50 minutos já sugerida no
  horário aprendido; filhote no widget "pronto para estudar junto"; foco com
  amigas (o "Plant Together" do Forest, sem morte coletiva); à noite, o
  bicho dormindo no widget como deixa para largar o celular.

### P2 — Rafael, 31, trabalho remoto ("mais foco"; rouba: mensagens e grupos)

- 8h30: abre WhatsApp e e-mail antes do café.
- 9h–12h: reuniões partidas por notificações.
- 14h–17h: o bloco que precisa de foco profundo, e é o mais invadido.
- 21h: série com o celular na mão.
- **Onde o Baru entra:** precisa de lista de apps essenciais **grátis** (a
  queixa contra o Focus Friend); sessão de 90 minutos, que o Baru já premia
  mais; o "neutro" do Baru (mensagens contam na meta, mas não como
  dispersivo) combina com ele; resumo semanal no domingo à noite.

### P3 — Carla, 27, "rolagem infinita" ("menos tempo de tela"; rouba: redes)

- Pega o celular dezenas de vezes por dia sem intenção.
- Pior janela: depois do almoço e antes de dormir.
- **Onde o Baru entra:** é a persona da sobreposição e do descanso de 40
  minutos. A sobreposição precisa ser o **bicho dela**, curta, com "voltar"
  grande. O descanso precisa render algo visível (o bicho cresce, o habitat
  floresce). Missão de recomeço no dia ruim.

### P4 — Ana, 34, rotina e saúde mental ("uma rotina" / "só companhia")

- Dias bons e dias de cama; TDAH ou ansiedade; se culpa por "não render".
- **Onde o Baru entra:** é o público do Finch. Precisa de zero culpa, de
  sessões curtas de 5 a 10 minutos que contem, de descanso tratado como
  conquista (a avaliação do Focus Friend sobre descansar sem culpa) e de um
  bicho que a receba bem depois de três dias sumida. Raiz opcional ou com
  compromisso escolhido ("passinhos").

---

## 7. Momentos do dia em que o Baru deve aparecer

[Inferência, com base no Finch (manhã e noite), no Duolingo (variação por
hora no widget), no Stawarz (gatilhos de evento valem mais que lembretes) e
no que o Baru já tem (hora do hábito aprendida, relatório da noite, aviso de
raiz entre 19h e 22h — relatório de agosto, seção 7).]

| Momento | Canal | O que o bicho faz | Por quê |
|---|---|---|---|
| **Primeiro desbloqueio do dia** | widget | acorda, espreguiça; mostra a barra do próximo crescimento | presença ambiente (UbiFit, widget do Duolingo) sem custo de notificação |
| **Primeira abertura de app dispersivo do dia** | sobreposição (fora de sessão, se ativada) | "bom dia" curto, com "vamos fazer 25 juntos antes?" | gatilho de evento, não de relógio (Stawarz 2015) |
| **Hora do hábito** (aprendida) | notificação com deep link | "o ninho está pronto" | já existe; ganhar variação e o estágio do bicho na imagem |
| **Durante o foco** | sessão + notificação persistente | o bicho trabalha em algo que cresce | crescimento na frente da pessoa (Forest, Focus Friend) |
| **Saída durante o foco** | sobreposição | o **mesmo** bicho, "voltar" grande | one sec: a saída fácil é o que funciona |
| **Pós-almoço** | missão do descanso | o bicho cochila junto | janela típica de rolagem (P3) |
| **Fim de tarde** | notificação só se houver missão quase feita | "falta 1 para colher" | o lembrete com propósito do roadmap |
| **Noite** | widget + relatório | o bicho se aconchega para dormir; "achado do dia" | ritual de fechamento; nunca pânico |
| **Volta após ausência** | primeira tela | reencontro alegre, sem cobrança | Silverman & Barasch: não destacar a quebra |
| **Domingo à noite** | cena semanal | "sua semana com Nina", com o progresso de crescimento | fechamento de ciclo; compartilhável |

---

## 8. Mapa: o que copiar e o que evitar, consolidado

**Copiar** [Inferência]:

1. Estágios de vida visíveis por dias cumulativos (Finch, Pou, Tamagotchi).
2. Crescimento durante a sessão (Forest, Focus Friend).
3. Ritual de troca de estágio com som próprio (Tamagotchi) e escolha de algo
   novo (Finch).
4. Algo acontece enquanto a pessoa está longe (Finch, Neko Atsume).
5. Coleção com álbum (Neko Atsume, Pikmin, micropets do Finch).
6. Widget vivo e promovido no pico emocional (Duolingo, Finch).
7. Ofensiva com compromisso escolhido e desligável (Finch).
8. Pagar mais no dia ruim (Finch).
9. Foco cooperativo sem morte coletiva (Forest, Flora).
10. A saída fácil na intervenção (one sec).
11. Gratuidade honesta, com contribuição cosmética e solidária (ScreenZen,
    Guardian do Finch).

**Evitar** — ver seção 9.2.

---

## 9. Conclusões

### 9.1 As 10 recomendações mais importantes, priorizadas

Formato: o quê · por quê (evidência) · como · esforço · impacto esperado ·
critério de aceite.

**R1 — Ciclo de vida visível do bicho (ovo ou recém-nascido → filhote → jovem
→ adolescente → adulto), por dias de cuidado cumulativos, que nunca regride.**
- *Por quê:* o Baru não tem nenhum crescimento no bicho (seção 3.3); o
  concorrente com melhor retenção cresce em 5 estágios por dias cumulativos
  (Finch, D1 54% e D7 37%); "growth" é o elogio mais curtido do Pou;
  pedido explícito do dono do produto.
- *Como:* seção 3.4 — `estagio` em `PetView`, proporções interpoladas,
  flags de traço por espécie, `diasDeCuidado` com piso gravado; números em
  `data/progressao.dart`. Avaliar Rive contra `CustomPainter`.
- *Esforço:* G. *Impacto:* alto — dá passado e futuro ao bicho, objetivo de
  médio prazo e assunto para as celebrações.
- *Aceite:* 5 pessoas ordenam as 5 capturas sem legenda; teste automatizado
  de que `estagio` nunca diminui; contas antigas nunca abrem com o bicho
  menor do que estava.
- *Regra:* respeita todas; a migração de contas antigas pede ADR.

**R2 — O bicho da sobreposição é o bicho da pessoa.**
- *Por quê:* o briefing (item 7); hoje `OverlayDoBaru.kt:300-380` desenha
  ovais genéricas; o widget já rasteriza o `PetView` real
  (`widget_service.dart:196-224`); a sobreposição é o momento mais sensível
  do app (seção 5.3, item 6).
- *Como:* reaproveitar `HomeWidget.renderFlutterWidget` (ou `RenderRepaintBoundary.toImage`)
  para gerar PNGs do bicho atual — humor saudade, contente e radiante, mais
  o estágio, a pelagem e a roupa — sempre que um deles mudar; gravar em
  `filesDir`; `OverlayDoBaru` e `VigiaDaSessao` carregam o bitmap em vez de
  desenhar. Três quadros alternados dão animação barata (respira e pisca).
- *Esforço:* M. *Impacto:* alto em coerência e confiança ("é o meu Baru me
  chamando").
- *Aceite:* para as 9 espécies × 5 estágios, a captura da sobreposição bate
  com a da home (mesma pelagem, roupa e estágio); trocar de espécie atualiza
  a sobreposição na próxima aparição.

**R3 — A primeira sessão concluída faz o ovo chocar (ou o filhote abrir os
olhos).**
- *Por quê:* o Finch eclode no onboarding; o relatório de agosto já pede a
  primeira sessão guiada (R2 de lá) e a revelação celebrada (R3); juntar as
  duas dá ao primeiro foco um motivo emocional, não só numérico.
- *Como:* o onboarding entrega o ovo ou ninho; a sessão guiada de 5 minutos
  mostra o ovo aquecendo; a conclusão dispara a cerimônia com `Celebracao`,
  som e háptico; depois vem o nome.
- *Esforço:* M. *Impacto:* alto em D1 (hipótese a medir: % de instalações
  que concluem a 1ª sessão).
- *Aceite:* conta nova sem sessão mostra ovo ou ninho em home, widget e
  ícone; a 1ª sessão concluída mostra a eclosão uma vez só.

**R4 — Crescimento sempre à vista: barra do próximo estágio na home, álbum de
crescimento e cartão "antes e depois".**
- *Por quê:* progresso só em números é o estado atual (`03-trilha.png`); o
  Forest é criticado por esconder estágios; o Duolingo mostra que o
  compartilhável certo é alavanca.
- *Como:* componente sob a cena da home ("Nina cresce em 3 dias de
  cuidado" + silhueta); tela de perfil com os 5 estágios; cartão gerado pelo
  motor do `CartaoDaRaiz`.
- *Esforço:* P/M. *Impacto:* médio-alto.
- *Aceite:* da home, sem rolar, dá para ler quantos dias faltam para o
  próximo estágio; o álbum mostra data de cada estágio vivido.

**R5 — Crescimento dentro da sessão de foco.**
- *Por quê:* Forest e Focus Friend mostram progresso durante o foco; o Baru
  mostra uma barra fina (`02-sessao.png`).
- *Como:* por estágio, uma atividade que avança com o tempo (o ovo aquece; o
  filhote junta gravetos; o adulto constrói); o objeto feito vai para o
  habitat como lembrança datada da sessão. Desistir **não destrói** o que
  foi feito até ali — o objeto fica "pela metade" e pode ser terminado na
  próxima sessão (sem perda; regra 1).
- *Esforço:* M. *Impacto:* médio-alto na percepção de recompensa.
- *Aceite:* capturas aos 0%, 50% e 100% da sessão são visivelmente
  diferentes; uma sessão interrompida mantém o objeto parcial.

**R6 — "Ausência que rende": o bicho vive enquanto a pessoa está longe e
volta com um achado.**
- *Por quê:* Neko Atsume ("you cant advance until you put it down"); a
  aventura do Finch como compromisso marcado "anti-nag"; Focus Plant e Finch
  apanham por prender a pessoa no app.
- *Como:* concluir foco ou descanso gera um achado do habitat (pena,
  concha, semente) entregue na próxima abertura; álbum de achados por
  habitat; abrir para colher leva menos de 10 segundos.
- *Esforço:* M. *Impacto:* médio — motivo para abrir uma vez por dia sem
  aumentar o tempo de tela.
- *Aceite:* mediana do tempo da visita de coleta abaixo de 15 segundos (a
  instrumentar); nenhum achado expira.

**R7 — Redesenhar a "saudade": consequência pequena, imediata e reparável, e
reencontro maior que a tristeza.**
- *Por quê:* a arte atual lê como bronca (`pet-owl-saudade.png`); Silverman
  & Barasch (destacar a quebra derruba o uso); Wohl e Breines & Chen
  (perdão e autocompaixão motivam); Byrne (o sinal triste funciona no curto
  prazo — por isso manter um sinal, e não zerá-lo).
- *Como:* saudade = postura de espera (olhar a porta, objeto da pessoa no
  colo), sem sobrancelha franzida nem suor; reação de reencontro com
  animação própria e som; frase sem acusação; "uma sessão curta traz de
  volta" escrito no próprio estado.
- *Esforço:* P/M. *Impacto:* médio em retorno após ausência.
- *Aceite:* teste com 5 pessoas — nenhuma descreve a saudade como "bravo"
  ou "decepcionado"; o reencontro aparece na primeira abertura após 2 ou
  mais dias.

**R8 — Widget como canal principal, com estado por hora do dia e promoção no
pico emocional.**
- *Por quê:* UbiFit Garden (atividade mantida com a tela ambiente); widget do
  Duolingo (metade dos usuários com 6+ meses de ofensiva; instalações
  subiram com promoção pós-lição); Finch (widget como peça de retenção).
- *Como:* o widget já existe (`ROADMAP.md:43-48`). Falta: variação por hora
  (acordando, ativo, aconchegado, dormindo) **em tom de cuidado**; estágio
  de crescimento; barra do próximo estágio no 4×2; oferecer
  `requestPinAppWidget` logo depois da 1ª celebração e da eclosão.
- *Esforço:* M. *Impacto:* alto e barato em atenção (sem custo de
  notificação).
- *Aceite:* a imagem do widget muda em pelo menos 4 faixas do dia; o
  convite para fixar aparece uma vez após a eclosão e pode ser recusado para
  sempre.

**R9 — Política de monetização à prova das queixas da categoria.**
- *Por quê:* a causa nº 1 de 1★ e 2★ na amostra (Forest, Finch, Opal, Plant
  Nanny, Daylio, Neko Atsume 2, Focus Friend, Tide); a regra "espécie nunca
  por dinheiro" já aponta nessa direção.
- *Como:* (a) nunca retirar de quem pagou nem mover para o pago o que foi
  gratuito — vale como ADR; (b) premium só cosmético e de conveniência,
  **nunca estágio de crescimento, espécie ou lista de apps essenciais**;
  (c) eventos com janela de no mínimo um mês e itens que voltam; (d) nada de
  parceria de marca em tema; (e) considerar um "padrinho" (assinatura que
  patrocina a de outra pessoa, como o Guardian do Finch).
- *Esforço:* P (decisão), M (implementação). *Impacto:* protege a nota da
  loja e a confiança.
- *Aceite:* ADR publicado; teste que falha se algum item de crescimento ou
  espécie tiver preço em dinheiro.

**R10 — Vínculo com níveis que mudam o comportamento do bicho.**
- *Por quê:* o Finch tem 10 níveis de amizade com nome e bônus; o Baru já
  conta afagos ("Vínculo · 23 afagos", `03-trilha.png`; teto de 5 por dia em
  `progressao.dart:45`), mas o número não muda nada no bicho. Usuários
  pedem para "interact with it. To get attached" (Finch, 2★).
- *Como:* níveis de vínculo com nome nos 4 idiomas; cada nível libera um
  comportamento (seguir o dedo, vir até a borda quando o app abre, um truque
  próprio da espécie, chamar pelo nome da pessoa na fala); o afago continua
  sem moeda acima do teto.
- *Esforço:* M. *Impacto:* médio em apego.
- *Aceite:* cada nível tem uma animação nova verificável em captura; nenhum
  nível exige dinheiro.

### 9.2 O que **não** fazer

1. **Morte, murchar, doença ou decaimento** de bicho, planta ou item (Forest,
   Flora, Tamagotchi, Pou, itens quebrando no Neko Atsume 2). Viola a regra 1
   e a evidência não ajuda no longo prazo.
2. **Crescimento ligado à raiz.** Quebrar a raiz não pode atrasar o bicho.
3. **Regredir o estágio** de qualquer conta, inclusive na migração.
4. **Bicho em pânico ou bravo** como recurso de retenção (o Duo perto da
   meia-noite; a coruja atual de saudade).
5. **Punir a honestidade:** desistir não apaga o que já foi feito na sessão
   (a queixa das "meias" no Focus Friend).
6. **Inchar o app** com missões paralelas, popups de conquista sem fim e
   micro-ações pós-sessão (Focus Plant, Finch, Daylio). O Baru promete menos
   tela.
7. **Retirar o que foi pago** ou mover o grátis para o pago (Forest Plus,
   Opal, Plant Nanny, Daylio).
8. **Eventos de poucos dias e exclusivos de quem paga** (Forest, Finch).
9. **Tie-in com marca** nos temas (Finch 2026).
10. **Anúncio recompensado** (Focus Plant) e **culpa na entrada** ("guilt
    trip", Focus Plant 1★).
11. **Morte coletiva em foco em grupo** (Forest "Plant Together"): no Baru, o
    grupo ganha bônus se todos concluírem, e ninguém perde se alguém sair.
12. **Recategorizar apps por cima da escolha da pessoa** (Opal).
13. **Arte gerada por IA percebida como barata** (Flora 1★) — risco direto
    para o item "elementos gráficos amadores" do briefing.

### 9.3 Riscos e dúvidas em aberto

1. **Evidência contrária à regra 1.** Byrne et al. acharam que pet com
   feedback negativo funciona melhor que só positivo (9 dias, crianças). A
   regra do Baru é defensável pelo horizonte longo e pelo público, mas é uma
   aposta. Proposta: medir o efeito da "saudade" redesenhada no retorno D+3,
   em vez de removê-la.
2. **Custo de arte do ciclo de vida.** 9 espécies × 5 estágios × 5 humores
   × atividades é muito desenho no `CustomPainter` atual. Decidir entre
   `CustomPainter` e Rive antes de começar (laudo visual).
3. **Migração de contas antigas** pode ser lida como perda se mal feita.
   Precisa de ADR e de piso.
4. **Ritmo dos estágios** (7/21/45 dias) é chute ancorado no Finch; ajustar
   com dado. Rápido demais esvazia; lento demais frustra.
5. **Personas sem dado.** Instrumentar o quiz ("o que você quer do Baru") e
   cruzar com retenção antes de priorizar por persona.
6. **Lacunas de fonte** desta pesquisa: Reddit inacessível; orçamento de
   busca esgotado antes de verificar Lally et al. (tempo de formação de
   hábito), Bloch & Lemish (Tamagotchi), Bidargaddi et al. (notificações) e
   dados de uso por hora no Brasil; resultados de Wohl et al. e Breines &
   Chen vêm de resumos secundários. Vale uma rodada curta para fechar isso.
7. **Retenção do Finch** vem de estimativa da Sensor Tower citada por um
   blog de análise, não de dado da empresa.
8. **Viés das avaliações da loja:** quem escreve é quem está muito feliz ou
   muito irritado; as citações ilustram padrões, não medem frequência.

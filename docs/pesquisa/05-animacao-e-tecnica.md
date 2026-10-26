# Laudo 05 — Animação, movimento e soluções técnicas

Data: 26/10/2026 · Escopo: animação do bicho, do mundo e da interface;
tecnologia de animação para Flutter; crescimento visível do pet por estágios;
o pet real na sobreposição sobre outros apps; biblioteca de animações do Baru.

Convenções deste laudo:

- **[Fato]**: afirmação com fonte externa, com link.
- **[App]**: observação do código (`arquivo:linha`) ou de imagem do repositório.
- **[Opinião]**: inferência minha, de engenheiro e animador; não tem fonte e
  deve ser tratada como hipótese.

Caminhos de código são relativos a `baru_app/`.

---

## 0. Resumo em uma página

1. **O bicho já tem um rig procedural de verdade**, e ele é melhor do que o
   relato "animações extremamente limitadas" faz parecer: 9 controladores
   (respiração, flutuação, cauda, laço de atividade, piscar, orelha, toque,
   gesto ocioso, afago), 6 gestos ociosos sorteados, 7 ações por espécie,
   olhar que segue o dedo, afago com ronronar háptico
   (`lib/widgets/pet.dart:293-371`, `:545-573`, `:633-684`). O que falta é
   **amplitude, expressão e variedade por espécie**: a respiração muda o
   corpo em 1,8% (`pet.dart:1321-1324`) e nos quadros de evidência
   `respiracao-1` e `respiracao-4` não se vê diferença a olho nu; todos os
   gestos ociosos são os mesmos para as 9 espécies; o humor é decidido por
   booleanos (`feliz`, `triste`, `dormindo` — `pet.dart:1127-1130`), sem
   transição entre humores.
2. **O mundo e a interface animam pouco**: itens do habitat são retângulos
   arredondados que caem com `easeOutBack` (`lib/widgets/habitat.dart:622-654`,
   `models.dart:158-162`); a celebração é um círculo com ícone e 18 bolinhas
   (`lib/widgets/celebracao.dart:61-69`, `:266-279`); as molas definidas em
   `design/motion.dart:54-65` **não são usadas em lugar nenhum**; há 36
   durações escritas fora de `motion.dart`, contra a regra do próprio arquivo.
3. **Tecnologia:** manter o `CustomPainter` procedural como fonte única do
   bicho. É a única opção que nós (por código, sem animador) conseguimos
   produzir para 9 espécies × 5 estágios × 5 humores × 7 ações × pelagens ×
   roupas, e já alimenta app, widget da tela inicial, ícones e PNG de
   compartilhamento (ADR-015). Rive é o que o Duolingo usa e é tecnicamente
   o melhor runtime, mas só compensa com animador humano; Lottie e sprites
   explodem combinatoriamente; Flame é um motor de jogo e é desproporcional
   para o caso.
4. **Crescimento visível:** um estágio por espécie (`ovo/ninho → filhote →
   jovem → adulto → pleno`), derivado de um contador que só sobe
   (`xpPorEspecie`), com proporções do painter parametrizadas por estágio
   (cabeça e olhos maiores no filhote, o "esquema de bebê" de Lorenz) e uma
   **cena de evolução própria**. Persistência aditiva, no mesmo padrão já
   usado no app (`colunasOpcionais` + `fundeCom` com o maior valor).
5. **Overlay:** recomendação (a) — o Dart rasteriza o `PetView` do usuário
   (espécie, pelagem, roupa, humor, estágio) numa sequência curta de quadros
   PNG quando a sessão começa, o Kotlin toca os quadros e aplica respiração e
   piscar nativos. Já existe um precedente funcionando no app: o widget da
   tela inicial faz exatamente isso (`lib/services/widget_service.dart:1-12`,
   `:192-201`). Um segundo `FlutterEngine` no serviço (b) é mais bonito, mas
   frágil (processo morto, restrições de serviço em primeiro plano no
   Android 15); portar o painter para Kotlin (c) cria um segundo desenho que
   envelhece em silêncio.

---

## 1. Auditoria: o que existe, o que é limitado e por quê

### 1.1 Sistema de movimento (`lib/design/motion.dart`)

**[App] O que existe.** Tokens de duração (`microFeedback` 120 ms,
`componente` 260 ms, `tela` 380 ms, `celebracao` 900 ms, `contador` 700 ms,
`respiracao` 3400 ms — `motion.dart:11-31`), curvas (`easeOutBack`,
`easeInCubic`, `easeOutCubic`, `easeOutQuint`, `easeInOut` — `:34-51`),
molas (`toque`, `entrada`, `festa` — `:54-65`), deslocamentos (`:68-76`) e
o tratamento de "reduzir movimento" que **reduz amplitude e encurta, sem
zerar** (`:82-97`). É uma base boa e alinhada com a literatura: a faixa de
100–500 ms da NN/g, com saídas mais curtas que entradas
([NN/g, Animation Duration](https://www.nngroup.com/articles/animation-duration/)).

**[App] Limitações.**

- `Molas` não tem nenhum uso fora da própria definição (busca por `Molas.`
  em `lib/` só acha `motion.dart:55`). Toda a resposta física do app é
  `Curves.easeOutBack` com duração fixa — não há mola de verdade
  (`SpringSimulation`) em nenhum botão, item ou bicho.
- 36 literais `Duration(milliseconds: …)` fora de `motion.dart`, por exemplo
  `widgets/common.dart:71,132,245,320,425,483`, `toca.dart:59,63`,
  `componentes.dart:343`, `trilha_screen.dart:698`, além dos ~15 de `pet.dart`
  (estes justificados como "cadência de anatomia" em `pet.dart:184-189`).
  A regra do cabeçalho ("nenhuma duração fora daqui") não vale na prática.
- Não há token para **escalonamento** (stagger), **trajetória** (arco) nem
  **partículas**, que são o vocabulário das recompensas (seção 2.4).

### 1.2 O bicho (`lib/widgets/pet.dart`, 4036 linhas)

**[App] Como é desenhado.** Um `CustomPainter` (`_PetPainter`,
`pet.dart:1084`) com uma função por espécie (`_capivara` `:1498`, `_lontra`
`:1613`, `_tartaruga` `:1725`, `_coruja` `:1861`, `_axolote` `:2071`,
`_pinguim` `:2164`, `_gata` `:2290`, `_raposa` `:2425`, `_buldogue`
`:2655`). A forma-base é a "bolha" de quatro Béziers com fator por lado
(`:1195-1230`). Coordenadas são **números mágicos por espécie** (ex.: corpo
da coruja `Rect.fromCenter(center: Offset(0, 4), width: 94, height: 100)`,
`:1896-1900`). Roupa é desenhada no sistema de coordenadas da cabeça
(`_veste`, `:3313-3329`).

**[App] Como é animado.**

| Camada | Implementação | Arquivo |
|---|---|---|
| Respiração | `_respiro`, 3,4 s ida e volta; 6,4 s dormindo; 2,2 s no esforço | `pet.dart:293-296`, `:444-451` |
| Flutuação | `_flutua`, 4,7 s, período primo da respiração de propósito | `:300-303` |
| Cauda | `_cauda`, 2,6 s | `:306-309` |
| Laço da atividade | `_ciclo` sem `reverse` (braçada, asa, mastigada, salto, troca de pé) | `:317-320`, `:1002-1081` |
| Piscar | 170 ms, intervalo 1,8–6,4 s, 20% de piscada dupla | `:322-325`, `:509-523` |
| Orelha | tremor de 420 ms a cada 3,2–10,2 s | `:328-332`, `:525-535` |
| Toque | quique amortecido `sin(3πt)·e^(−4t)`, háptico, som, olhar para o dedo, corações do 3º toque em diante | `:575-627`, `:911-918`, `:1420-1441` |
| Gesto ocioso | 6 gestos (espreguiçar com bocejo, sacudir, olhar em volta, coçar, farejar, saltinho) a cada 5–12 s, só no ócio | `:44-52`, `:545-573`, `:920-965` |
| Afago | arrasto que vence a rolagem, satisfação 0→1 em 520 px, clique háptico a cada 26 px, olhos derretendo, pelo levantado, corações | `:633-684`, `:812-838`, `:1374-1414` |
| Squash & stretch | só na escala do corpo inteiro: respiração ±1,8%/1,4%, quique ±7%, espreguiçar +7% | `:1315-1324` |

Os quadros de evidência confirmam o que o código diz: o quique e os corações
(`docs/evidence/2026-08-27/reacao-3-carinho.png`), o bocejo com olhos fechados
na coruja (`reacao-4-espreguica.png`), as asas abertas no voo
(`atividade-voo-coruja-2.png`), a capivara afundada na lâmina d'água com o
tom da água só sobre o corpo (`atividade-nado-capivara-3.png`), o buldogue de
língua de fora e orelhas abertas na brincadeira
(`2026-08-28/buldogue-brincadeira-3.png`).

**[App] Limitações e por quê.**

1. **Amplitude baixa demais para ler em tela de celular.** A respiração
   escala o corpo em 1,8% na horizontal (`pet.dart:1322`). Num bicho de
   ~200 px na home isso é ~3–4 px. Nos seis quadros de
   `respiracao-1..6.png` a diferença é imperceptível a olho nu (comparei
   `respiracao-1` e `respiracao-4`: mesma silhueta). [Opinião] Para um
   personagem fofo, a respiração precisa ser vista sem esforço: 3–4% no
   tronco, com a cabeça atrasada em fase (sobreposição), e não o corpo
   inteiro escalando junto.
2. **Corpo rígido: tudo escala junto.** O squash & stretch é um `canvas.scale`
   no corpo inteiro (`:1321-1324`). Não há deformação por parte (barriga
   enche, cabeça fica), nem **follow-through** (orelhas e cauda que atrasam e
   assentam depois do movimento do corpo) — a orelha só "treme" em laço
   fixo (`:328-332`). É o que dá a impressão de "boneco de papel".
3. **Sem antecipação nos gestos.** O quique do toque começa subindo
   (`sin(3πt)` em `:914`); o saltinho idem (`:962-965`). Só a brincadeira
   tem agachamento antes do salto (`:1036-1037`). Antecipação é o princípio
   que mais vende peso num personagem (seção 2.2).
4. **Repertório igual para as 9 espécies.** Os 6 gestos ociosos são os mesmos
   para coruja, axolote e buldogue (`:554-561`). A coruja não gira a cabeça,
   o axolote não pulsa as guelras como gesto, o gato não lambe a pata, o
   pinguim não bate as nadadeiras de alegria. A espécie muda a forma, não o
   comportamento ocioso.
5. **Humor binário e sem transição.** `feliz`, `triste`, `dormindo` são
   booleanos (`:1127-1130`); a cor do pelo muda por `switch` (`:1157-1170`).
   Quando o humor muda, o desenho troca no quadro seguinte — não há
   "ele ficou contente" como animação. Os acessórios de humor são poucos e
   genéricos: 4 estrelinhas (`_brilhos`, `:3960-3982`), um pingo de lágrima
   (`_pingo`, `:3996-4009`), "zzz" e a folha do sono.
6. **Sem conceito de idade/estágio.** As proporções são constantes por
   espécie. Não existe nenhum parâmetro que permita "crescer" (seção 4).
7. **Custo de quadro.** O painter inteiro é refeito a cada quadro enquanto
   qualquer um dos 9 controladores anda (`:712-760`), e todos os `Path` são
   recriados a cada quadro. Nadando, há um `saveLayer` por quadro
   (`:1283`). [Fato] A documentação do Flutter avisa que `saveLayer` aloca
   um buffer fora da tela e força troca de alvo de renderização, "particularly
   disruptive" em GPU móvel
   ([Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)).
   [Opinião] Não é problema hoje (um bicho na tela), mas limita colocar
   vários bichos/elementos animados juntos (álbum de estágios, cena de
   evolução com antes/depois).
8. **Pausa por ciclo de vida, mas não por visibilidade.** O bicho para quando
   o app vai para o fundo (`:392-403`), mas continua pedindo quadro se a home
   for rolada até o bicho sair da tela. [Opinião] Pequeno custo de bateria.

### 1.3 Habitat (`lib/widgets/habitat.dart`)

**[App] O que existe.** Deriva lenta de camadas (14 s, `habitat.dart:343-346`),
luz por hora do dia e por cenário (`:471-476`), item novo "cai" com
`easeOutBack` em 900 ms, subindo 26 px com opacidade e escala 0,6→1
(`:622-654`; quadros `chegada-1..4.png`), "+3 XP" subindo após um afago
(`:349-353`, `:947-966`), pausa por ciclo de vida (`:372-380`).

**[App] Limitações.**

- **Itens são retângulos arredondados** (`ShapePart` = x, y, w, h, raio, cor
  — `models.dart:158-162`), desenhados como `Container` com sombra
  (`habitat.dart:635-649`). A "ponte" do quadro `chegada-2.png` e o banco em
  `play-store/telas/pt/home-owl.png` são barras cinza/marrons. Não há o que
  animar num retângulo além de posição e escala.
- **O `AnimatedBuilder` da cena reconstrói a pilha inteira, incluindo o
  `PetView`, a cada quadro da deriva** (`:513-598`). [Fato] O Flutter
  recomenda passar a subárvore que não depende da animação como `child`
  ([best practices](https://docs.flutter.dev/perf/best-practices)). Além
  disso, a peça usa `Opacity` animado (`:631`), que o mesmo guia manda evitar
  em animação.
- O bicho **não reage** ao item que chega (não olha, não pula).
- A queda do item não tem física: não acelera, não amassa ao tocar o chão,
  não levanta poeira.

### 1.4 Celebração e toca (`lib/widgets/celebracao.dart`, `toca.dart`)

**[App] O que existe.** Toca de 3 gestos com háptico crescente, terra
voando e prêmio subindo de dentro (`toca.dart:9-24`, `:79-108`,
`:116-158`); celebração com véu, círculo com ícone em `easeOutBack`,
18 partículas radiais, háptico forte e som, fechando sozinha 1,1 s depois
(`celebracao.dart:81-94`, `:150-234`, `:252-284`).

**[App] Limitações.**

- A celebração de nível **não mostra o bicho** — mostra um ícone de flor
  (`app.dart:316-327`; quadro `celebracao-nivel.png`). O personagem, que é o
  produto, está ausente do momento de maior recompensa.
- Partículas são círculos de uma cor só, em linha reta para fora
  (`celebracao.dart:268-279`): sem gravidade, sem rotação, sem forma de folha.
- Não há contador animado na celebração (nível N−1 → N), nem a barra de XP
  enchendo e transbordando.
- O relatório de agosto já registrou que o contador de folhas anima **na tela
  errada** (a home anima enquanto o usuário está no resultado —
  `docs/RELATORIO_UX_DUOLINGO.md:198-202`). Continua valendo.

### 1.5 Transições de tela (`lib/navegacao.dart`)

**[App]** Eixo compartilhado no espírito do Material: a página que sai some
nos primeiros 35% e a que entra aparece nos 65% finais
(`navegacao.dart:160-236`); irmãos deslizam 6% de lado, detalhe entra em
profundidade (escala), modal sobe, fluxo faz fade. Durações via token e
"reduzir movimento" respeitado (`:132-133`, `:190`, `:212`). Está correto.
**Limitação:** nenhum elemento atravessa a transição (não há `Hero`: a busca
por `Hero(` em `lib/` não acha nada), então o bicho da home não "vai junto"
para a tela do perfil ou da sessão; e o conteúdo de cada tela entra de uma
vez, sem escalonamento.

### 1.6 Sobreposição nativa (`OverlayDoBaru.kt`)

**[App]** O balão é uma `View` desenhada em `Canvas` Kotlin; o bicho é
"corpo oval + barriga + cabeça oval + orelhas redondas (tufos se for coruja)
+ focinho + olhos" (`OverlayDoBaru.kt:303-384`). Recebe só **espécie e cor**
(`:86-91`). Ignora roupa, humor, marcações do buldogue, forma de cada espécie.
Única animação: escala de entrada com `OvershootInterpolator` em 420 ms
(`:211-220`). O quadro `tela-sobreposicao.png` mostra o resultado: um
"urso-capivara" genérico. Detalhado na seção 5.

### 1.7 Por que está assim (diagnóstico)

[Opinião, com base no histórico do código.] Cada animação foi construída como
**correção de um defeito apontado** (os comentários de `pet.dart` são um
diário disso: "o bicho desmastigava", "a coruja parecia um elevador"). Isso
deu correção, não direção de arte. Faltam três coisas estruturais: (1) um
**rig por partes** (cabeça, tronco, membros, cauda, orelhas como nós com
pivô e mola própria), em vez de translações soltas dentro de cada função de
espécie; (2) **parâmetros de proporção** externos aos números mágicos, sem os
quais não há estágio de crescimento; (3) uma **biblioteca de movimentos
nomeados** com duração e curva definidas antes de codar, em vez de números
decididos caso a caso.

---

## 2. Pesquisa: como se anima personagem e recompensa

### 2.1 Duolingo: Duo e os personagens do mundo

- **[Fato]** O Duolingo adotou o **Rive** para os personagens do mundo por
  três motivos declarados: arquivos pequenos para Android, iOS e Web,
  encaixe na arquitetura do app e a passagem de bastão animador → engenharia.
  O recurso central é a **State Machine**, "a visual representation of the
  logic that connects the animations ('states') together"; ela decide quais
  estados tocam, como são chamados e como se misturam. A máquina inteira é
  exportada como **um único arquivo de runtime**
  ([Duolingo Blog, World character visemes, nov/2022](https://blog.duolingo.com/world-character-visemes)).
- **[Fato]** Lip-sync: o áudio de cada frase vem com o tempo de cada fonema;
  cada fonema vira um **visema** (formato de boca); há "20+ mouths" por
  personagem, que rodam **em paralelo** aos estados do corpo. Comportamentos
  ociosos citados: acenos de cabeça, piscar, sobrancelha (mesma fonte).
- **[Fato]** Na animação de marco de ofensiva, o Duo se transforma num
  "Fire Duo" (fênix), tratando o marco como um "power-up" de videogame; o
  time fez várias passadas brutas antes de refinar ritmo — "Timing is
  everything in animation" ([Duolingo Blog, streak milestone design](https://blog.duolingo.com/streak-milestone-design-animation)).
- **[Fato]** A nova animação da tela de ofensiva estendida (com versão
  especial em marcos) aumentou em **+1,7%** a chance de um aprendiz novo
  continuar usando o app 7 dias depois
  ([Duolingo Blog, How the streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit)).
- **[Fato]** O Rive também documenta a personagem Lily na chamada de vídeo
  do Duolingo usando state machine com transições misturadas em vez de
  clipes prontos para cada reação
  ([Rive blog — fonte do fornecedor](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)).

**[Opinião] O que importa para o Baru.** O que o Duolingo tem de valioso não
é o arquivo `.riv`, é a **arquitetura**: um personagem com camadas que tocam
ao mesmo tempo (corpo + rosto + boca), comandadas por entradas nomeadas
(humor, atividade, evento) e transições misturadas. O `PetView` já tem
metade disso (camadas paralelas de controladores, `_Pose` como "entradas").
Falta formalizar estados e transições (seção 3.4). Lip-sync não se aplica —
o Baru não fala em áudio —, mas o mesmo mecanismo serve para **boca falando
enquanto o balão escreve** na sobreposição.

### 2.2 Os 12 princípios da animação aplicados a personagem e UI

[Fato] Os 12 princípios vêm de Frank Thomas e Ollie Johnston, *The Illusion
of Life* (Disney, 1981); a aplicação a interfaces está resumida pela
Interaction Design Foundation
([IxDF — Disney's 12 principles in UI](https://ixdf.org/literature/article/ui-animation-how-to-apply-disney-s-12-principles-of-animation-to-ui-design))
e por [UX Collective](https://uxdesign.cc/disneys-12-principles-of-animation-exemplified-in-ux-design-5cc7e3dc3f75).
A tabela aplica cada um ao Baru; a coluna "Baru hoje" é observação do código,
a coluna "o que fazer" é opinião minha.

| Princípio | Baru hoje [App] | O que fazer [Opinião] |
|---|---|---|
| Squash & stretch | só escala global (`pet.dart:1321`) | por parte: barriga enche, cabeça amassa no pouso; volume constante (sx·sy ≈ 1) |
| Antecipação | só na brincadeira (`:1036`) | agachar 80–120 ms antes de todo salto/quique; olhos fecham antes do espirro/sacudida |
| Encenação (staging) | celebração sem o bicho | o bicho no centro de toda recompensa; véu escurece o resto |
| Pose a pose / direto | pose calculada por fórmula | manter procedural, mas com **poses-chave** nomeadas e interpolação entre elas |
| Follow-through e sobreposição | ausente | orelhas, cauda, guelras, tufos como molas atrasadas em relação à cabeça/corpo |
| Slow in / slow out | `easeInOut` nos contínuos (`:742-744`) | ok; nos gestos, usar curvas assimétricas (sobe rápido, assenta devagar) |
| Arcos | movimentos verticais retos | cabeça gira em arco; folha/moeda voam em Bézier quadrática |
| Ação secundária | corações, brilhos | piscar durante gesto, cauda abanando ao ser afagado, poeira no pouso |
| Timing | bom nas atividades (comentários `:184-214`) | manter; documentar como tabela (seção 6) |
| Exagero | baixo (respiração 1,8%) | dobrar amplitudes de respiração e quique; exagerar a evolução |
| Desenho sólido | silhuetas frontais boas (fox, frenchie) | proporções por estágio parametrizadas |
| Apelo | rosto simples e legível | esquema de bebê no filhote (seção 2.5) |

### 2.3 Micro-interações

- **[Fato]** NN/g: feedback simples ~100 ms ("feels immediate"); mudança
  substancial 200–300 ms; grandes movimentos até 400 ms; "At 500ms,
  animations start to feel like a real drag"; entrada um pouco mais longa
  que a saída ([NN/g](https://www.nngroup.com/articles/animation-duration/)).
- **[App]** O relatório de agosto já apontou botões mudos (sem escala, sem
  háptico) em `common.dart` enquanto `componentes.dart:141-170` tem a versão
  certa (`docs/RELATORIO_UX_DUOLINGO.md:188-192`).
- **[Opinião]** Micro-interação no Baru = **pressão** (escala 0,96 no toque,
  mola de volta), **confirmação** (ícone que vira check com traço desenhado),
  **contagem** (número rolando), **estado** (chip que muda com cor e leve
  quique). Todas com háptico leve; som só nas que encerram uma ação.

### 2.4 Animação de recompensa (contador, partículas, confete)

- **[Fato]** A "tela de ofensiva" animada do Duolingo teve efeito medido em
  retenção (+1,7% em D7 para novos) — ver 2.1.
- **[Fato]** Pacotes prontos existem: `confetti` (MIT, partícula com `Path`
  customizado e direção explosiva/direcional — [pub.dev/confetti](https://pub.dev/packages/confetti),
  última versão há 2 anos); Flame tem sistema de partículas
  ([pub.dev/flame](https://pub.dev/packages/flame)).
- **[Opinião] Anatomia de uma recompensa bem animada**, que proponho como
  padrão do Baru: (1) **origem visível** — a recompensa sai de algum lugar
  (a toca, o bicho, o cartão da missão); (2) **trajeto** — as folhas voam em
  arco até o saldo, escalonadas; (3) **chegada** — o saldo pulsa a cada folha
  que entra e o número sobe junto; (4) **reação do bicho** — ele olha para o
  saldo e faz um saltinho; (5) **som e háptico no impacto**, não no início.
  Confete genérico de cores primárias não combina com a estética do Baru
  (terra, folha, água): as partículas devem ser **folhas, sementes, gotas e
  vagalumes**, desenhadas no mesmo traço do bicho. Não precisa de pacote: o
  `_Explosao` existente (`celebracao.dart:252-284`) já é o esqueleto.

### 2.5 Squash & stretch e "fofura" em personagem

- **[Fato]** O "esquema de bebê" de Konrad Lorenz — cabeça grande, rosto
  redondo, olhos grandes — é percebido como fofo e aumenta a motivação de
  cuidar; Glocker et al. testaram isso experimentalmente variando essas
  proporções em rostos
  ([Glocker et al., Ethology 2009](https://repository.upenn.edu/cog_neuro_pubs/11);
  versão fMRI no PNAS:
  [PNAS 2009](https://www.cceb.upenn.edu/csa/assets/user-content/documents/PNAS-2009-Glocker.pdf)).
- **[Opinião] Consequência direta para os estágios:** o filhote deve ter
  cabeça ~60% da altura total, olhos 1,3–1,4× maiores, membros curtos e
  corpo mais redondo; o adulto, cabeça ~45%, olhos menores, membros e cauda
  mais longos, marcas da espécie completas. A diferença entre estágios fica
  **extremamente visível** sem trocar o desenho — só os parâmetros.
- **[Opinião]** Squash & stretch num bicho fofo deve conservar volume
  (sx·sy ≈ 1) e ser maior no pouso que no impulso; personagens "macios"
  (capivara, axolote, buldogue) amassam mais que os "rígidos" (tartaruga:
  o casco não deforma, só o pescoço e as patas).

### 2.6 Animações ociosas (idle)

- **[Fato]** O Duolingo cita piscar, acenos de cabeça e sobrancelha como
  comportamentos ociosos rodando em camadas paralelas
  ([Duolingo, visemes](https://blog.duolingo.com/world-character-visemes)).
- **[App]** O Baru já acerta o essencial do idle: períodos primos entre
  camadas (`pet.dart:298-303`), piscar irregular com piscada dupla
  (`:506-523`), gestos sorteados com janela variável (`:537-573`).
- **[Opinião]** O que falta: **idle em três níveis** — (1) micro, contínuo
  (respirar, piscar, orelha); (2) gesto, a cada 5–12 s (o que existe);
  (3) **"evento raro"**, a cada 45–120 s, longo e próprio da espécie (a
  coruja gira a cabeça quase de costas e volta, a lontra rola de barriga para
  cima, o pinguim escorrega de barriga, o axolote "sorri" e sobe uma bolha, a
  tartaruga recolhe a cabeça no casco e espia, a raposa salta de cabeça na
  "neve" (mergulho de caça), a gata amassa pãozinho, o buldogue roda atrás do
  próprio toco de rabo, a capivara deixa um passarinho pousar na cabeça).
  O evento raro é o que as pessoas filmam e mostram.

### 2.7 Material motion

- **[Fato]** O Compose Material 3 define dois `MotionScheme`: **expressive**,
  para elementos de destaque e interações "hero", e **standard**, para UI
  utilitária e recorrente; cada um tem specs *spatial* (posição/tamanho) e
  *effects* (cor/opacidade), em versões rápida, padrão e lenta — API ainda
  experimental
  ([Android reference — MotionScheme](https://developer.android.com/reference/kotlin/androidx/compose/material3/MotionScheme)).
  Valores numéricos de mola publicados por pacotes Flutter de terceiros
  divergem entre si (ex.: amortecimento 0,73 vs 0,8 para o mesmo token —
  [material_expressive](https://pub.dev/packages/material_expressive),
  [motor](https://pub.dev/packages/motor)); **não encontrei a tabela oficial
  do Google acessível**, então não cito números.
- **[Opinião]** Para o Baru: usar o espírito do esquema (molas para
  *spatial*, curva sem quique para *effects*), com "expressive" só em
  recompensas e no bicho, e "standard" em navegação — que é exatamente a
  divisão que `motion.dart` já sugere e não aplica.

---

## 3. Tecnologia: comparação e caminho realista

### 3.1 As opções

| | CustomPainter procedural (atual) | Rive | Lottie | flutter_animate | Sprites (PNG) | Flame |
|---|---|---|---|---|---|---|
| O que é | código Dart desenha cada quadro | runtime C++ via FFI + editor/CLI; state machine e data binding | player Dart de JSON do After Effects | efeitos encadeáveis em widgets | quadros pré-desenhados | motor de jogo 2D sobre Flutter |
| Interativo/estados | total (é código) | sim: state machine, entradas, view models | não (linha do tempo; só cor/propriedade em tempo de execução) | animação de widget, não personagem | troca de quadro | total |
| Combinação espécie×estágio×humor×roupa×pelagem | grátis (parâmetros) | possível com bones/data binding, mas cada espécie é um rig feito à mão | explode (um arquivo por combinação) | n/a | explode | igual ao procedural ou sprites |
| Quem produz | nós, por código | animador no editor; ou nós em RML via CLI (novo) | animador no After Effects | nós | ilustrador/animador | nós + arte |
| Peso no APK | zero | runtime nativo: Android puro ~2,4 MB download/7 MB instalado por ABI arm64 [Fato, Android, não Flutter] | pequeno (Dart) | pequeno | proporcional aos quadros | médio |
| Reuso no widget/ícone/overlay/compartilhar | sim, já feito (ADR-015, `widget_service.dart`) | só renderizando .riv em offscreen — segundo caminho | idem | n/a | sim (são PNGs) | não |
| Licença | — | runtime MIT; editor grátis exporta com splash, Cadet US$ 9/assento/mês remove | MIT | BSD-3 | — | MIT |

Fontes da tabela: Rive runtime Flutter (MIT, `rive` 0.14.11, depende de
`rive_native`, renderizador Rive ou Flutter)
([pub.dev/rive](https://pub.dev/packages/rive),
[Rive Flutter docs](https://rive.app/docs/runtimes/flutter/flutter));
tamanho do runtime Android (a página **não** tem números para Flutter)
([Rive runtime sizes](https://rive.app/docs/runtimes/runtime-sizes.md));
preço e splash do plano grátis ([Rive pricing](https://rive.app/pricing));
Lottie Dart puro, MIT, `ValueDelegate.color` para mudar cor em tempo de
execução, `renderCache` troca energia por memória
([pub.dev/lottie](https://pub.dev/packages/lottie));
flutter_animate BSD-3, efeitos encadeáveis, última versão há ~23 meses
([pub.dev/flutter_animate](https://pub.dev/packages/flutter_animate));
Flame MIT, motor de jogo minimalista
([pub.dev/flame](https://pub.dev/packages/flame)).

### 3.2 Rive merece um parágrafo à parte

- **[Fato]** Em 2025–2026 o Rive ganhou uma **CLI** e uma linguagem de
  marcação em XML (**RML**) que descreve um arquivo Rive inteiro em texto —
  artboard, formas, animações com keyframes e state machine — e compila para
  `.riv`, com verificação, inspeção e captura de tela por linha de comando
  ([Rive CLI](https://rive.app/docs/cli/overview),
  [RML](https://rive.app/docs/runtimes/advanced-topic/rml.md)). A própria
  documentação avisa que "a successful build doesn't prove the file behaves
  or looks correct" e que alguns erros falham em silêncio. Não encontrei
  documentação detalhada de bones/deformação de malha em RML (a página só
  lista "rigging" como tópico). Há também scripting em Luau dentro do
  arquivo ([Rive blog](https://rive.app/blog/why-scripting-runs-on-luau)).
- **[Opinião]** Isso muda o "Rive só com animador" para "Rive é possível por
  código", mas **não** resolve o problema central do Baru: teríamos de
  reescrever 4000 linhas de anatomia em XML de keyframes, com feedback visual
  mais lento que o do Dart (sem hot reload no mesmo app), e o bicho passaria a
  ter **duas fontes** — o `.riv` no app e o painter para widget, ícone,
  compartilhamento e overlay —, exatamente o que o ADR-015 proibiu ("um ícone
  feito à mão... envelheceria em silêncio"). O ganho visual (feathering,
  mesh, glows no renderizador Rive) é real, mas não é onde o Baru perde hoje.
- **Quando reconsiderar:** se um animador humano for contratado; ou para
  **peças isoladas que não dependem da espécie** (a toca abrindo, o ovo
  rachando genérico, o selo da raiz), onde um `.riv` de poucos KB, feito por
  RML/CLI ou no editor, convive bem com o painter.

### 3.3 Custo de produção sem animador (nós, por código)

[Opinião, estimativa de engenharia; sem fonte externa.]

| Caminho | Primeira espécie com 5 estágios, 5 humores, 7 ações | Cada espécie a mais | Manutenção |
|---|---|---|---|
| Procedural com rig por partes (recomendado) | G (refatorar o rig + parâmetros) | M | baixa: um lugar |
| Rive por RML | G+ (aprender formato, rig, state machine) | G | duas fontes de verdade |
| Lottie | inviável sem After Effects e animador | — | — |
| Sprites gerados do painter | M (gerar quadros em teste) | P | ilegível para editar; APK cresce |
| Flame | G (reescrever cena como jogo) | M | motor extra |

### 3.4 Recomendação técnica

**Manter o procedural e profissionalizá-lo**, em quatro passos:

1. **Rig por partes** (`lib/widgets/pet/rig.dart`): cada espécie declara
   nós (tronco, cabeça, orelha E/D, cauda, patas, apêndices) com pivô e
   **mola própria** (`SpringSimulation` com `Molas` de `motion.dart`), e a
   pose move o tronco; cabeça, orelhas e cauda seguem com atraso
   (follow-through grátis). As funções `_capivara`… passam a desenhar cada
   parte no espaço local do nó.
2. **Proporções como dado** (`EspecieProporcoes` × `EstagioDoBicho`): os
   números mágicos viram tabela; a seção 4 depende disso.
3. **Máquina de estados explícita** (`EstadoDoBicho`: ocioso, gesto, evento
   raro, atividade, reação, transição de humor, evolução), com prioridade e
   transições misturadas por `lerp` de `_Pose` — o equivalente em Dart da
   state machine do Rive.
4. **Desempenho**: cachear em `ui.Picture` as partes que não mudam no quadro
   (marcas do pelo, padrão de penas, casco), passar o `PetView` como `child`
   do `AnimatedBuilder` do habitat, e pausar o bicho quando sair da tela.

Não adotar `flutter_animate` como dependência: o app já tem tokens e
componentes próprios (`componentes.dart`); o que falta é usar molas e
escalonamento, que são poucas linhas. [Opinião]

---

## 4. Crescimento extremamente visível do pet

### 4.1 Estágios por espécie (proposta)

Biologia importa neste app: o código já recusa desenhar buldogue nadando e
gata na água porque seria "bonito e falso" (`pet.dart:97-133`). Pelo mesmo
critério, **só bota ovo quem bota ovo**:

| Espécie | Estágio 0 | 1 Filhote | 2 Jovem | 3 Adulto | 4 Pleno |
|---|---|---|---|---|---|
| Coruja (Nina) | ovo branco no ninho de galhos | corujinha de penugem cinza-clara, sem tufos | tufos curtos, disco facial aparecendo | tufos e penas do peito completos | penas com brilho, "sobrancelha" sábia, poleiro próprio |
| Tartaruga (Toco) | ovo enterrado na areia | filhote com casco liso | escudos do casco marcados | listra vermelha forte | casco com musgo/flor |
| Pinguim (Nino) | ovo sobre os pés de um adulto fora de quadro (ou ninho de pedrinhas) | filhote de penugem cinza fofa | muda: manchas de penugem | plumagem preta e branca lisa | gravata amarela/crista discreta |
| Axolote (Lume) | ovo em cacho gelatinoso | larva com guelras curtas | patas da frente | guelras longas e cheias | guelras que brilham levemente |
| Capivara, lontra, gata, raposa, buldogue | **ninho/cestinho**: recém-nascido enrolado, dormindo, olhos fechados | filhote | jovem | adulto | pleno (acessório natural: passarinho na cabeça da capivara, cauda cheia da raposa…) |

[Opinião] O pedido do dono do produto ("a coruja começa como ovo") é
atendido literalmente nas quatro espécies ovíparas; nos mamíferos, o estágio
0 é o recém-nascido no ninho, que entrega o mesmo efeito ("ele começou
pequenininho") sem mentir sobre a espécie.

### 4.2 De onde vem o estágio

**[App] O que existe.** XP é **um contador da conta**, não da espécie
(`state.dart:67`; `Balanco.nivelPara`, `progressao.dart:71-79`; nível máximo
40, `:82`); a troca de espécie não guarda nada por espécie
(`state.dart:1523-1545`). A estimativa de ritmo do próprio código é ~70 XP
por dia de uso engajado (`progressao.dart:299-301`).

**Proposta: `xpPorEspecie: Map<String, int>`**, contador que só sobe.

- Todo ganho de XP soma também em `xpPorEspecie[especieAtual]`.
- Estágio = função pura de `xpPorEspecie[especie]`, com limiares alinhados a
  níveis equivalentes (`xpAcumuladoPara(L) = 40(L−1) + 35(L−1)(L−2)/2`,
  derivado de `progressao.dart:56-68`):

| Estágio | Limiar | XP | Dias a ~70 XP/dia [cálculo] |
|---|---|---|---|
| 0 → 1 (eclodir/abrir os olhos) | primeira sessão de foco concluída com esta espécie | — | dia 1 |
| 1 → 2 | equivalente ao nível 5 | 370 | ~5 |
| 2 → 3 | nível 10 | 1620 | ~23 |
| 3 → 4 | nível 20 | 6745 | ~96 |

[Opinião] Eclodir na **primeira sessão** é o ponto: o primeiro foco da vida
do usuário termina com o ovo rachando, que é o "aha" do onboarding. Antes
disso o ovo balança e racha um pouquinho a cada minuto de foco dentro da
sessão (progresso visível).

**Migração sem regressão.** Na primeira leitura com o mapa vazio e `xp > 0`,
semear `{especieAtual: xp}`: quem já usa o app vê o bicho atual no estágio
correspondente ao que já fez (nunca volta a ovo — regra "nunca perde nada").
As outras espécies, quando escolhidas, começam no estágio 0. [Opinião]
**Isto é uma decisão de produto a confirmar**: começar uma espécie nova como
ovo não tira nada que a pessoa tinha (ela nunca teve aquela espécie
crescida), mas se o dono preferir, um piso de "filhote" para espécies
liberadas depois do nível 10 resolve sem mudar a arquitetura.

Alternativa descartada: estágio global derivado do nível. Mais simples, mas
trocar de espécie no dia 60 mostraria um adulto que a pessoa nunca viu
crescer — o oposto do pedido.

### 4.3 Persistência e sincronização (sem migration destrutiva)

Segue exatamente o padrão já estabelecido no app (migrations 10/15 —
`supabase/migrations/20260827220000_baru_progression_totais.sql`;
`supabase_gateway.dart:229-247`; `app_snapshot.dart:360-410`):

1. `AppSnapshot`: campos `xpPorEspecie` (`Map<String,int>`) e
   `estagioCelebrado` (`Map<String,int>`), com JSON tolerante a ausência.
2. `fundeCom`: **máximo por chave** nos dois mapas (contador que só sobe).
3. Migration aditiva e idempotente:
   `alter table public.baru_pets add column if not exists xp_por_especie
   jsonb not null default '{}'::jsonb, add column if not exists
   estagio_celebrado jsonb not null default '{}'::jsonb;`
4. `colunasOpcionais['baru_pets']` ganha as duas colunas, para o app novo
   funcionar contra um banco ainda sem a migration (`_upsertTolerante`,
   `supabase_gateway.dart:279-305`).
5. `row_codec.petRow` (`row_codec.dart:132-143`) grava os dois mapas.

Nenhuma linha existente é tocada; nenhum dado sai do aparelho além do que já
sai (o XP já sincroniza).

### 4.4 Como o painter muda por estágio

- `PetView` ganha `estagio` (e `progressoNoEstagio` 0–1 para o ovo rachar).
- `EstagioDoBicho` → `Proporcoes` por espécie: `cabeca` (escala do nó),
  `olho` (raio), `corpo` (escala e arredondamento da bolha), `membros`
  (comprimento), `apendice` (orelha, tufo, cauda, guelra, nadadeira),
  `marcas` (0–1: listra da tartaruga, máscara da raposa, penas do peito),
  `penugem` (0–1: contorno serrilhado de filhote).
- Estágio 0 é **outro painter** (`_ovo`, `_ninho`), com rachaduras como
  `Path` cuja extensão cresce com `progressoNoEstagio`
  (`PathMetric.extractPath`).
- Porque são parâmetros contínuos, a **transformação entre estágios é um
  `lerp`** de `Proporcoes` — morph de graça, impossível com sprites. Esta é a
  maior vantagem prática do procedural sobre Rive/Lottie para este pedido.

### 4.5 A cena de evolução

Rota própria (`TipoDeRota.fluxo`, `navegacao.dart:233-234`), disparada por
`estagio(especie) > estagioCelebrado[especie]`, com **prioridade sobre nível,
marco e chegada** na fila de `app.dart:316-354`, e **nunca durante a sessão
de foco**. Roteiro (total ~6 s, depois espera o toque):

| Tempo | O que acontece | Técnica |
|---|---|---|
| 0–400 ms | véu escurece, habitat some, bicho no centro em escala 1,4 | `FadeTransition` + `Hero` do bicho da home |
| 0,4–1,6 s | antecipação: bicho treme cada vez mais, olha para cima; som grave subindo | ruído senoidal com amplitude crescente; háptico leve a cada 300 ms |
| 1,6–3,6 s | silhueta clara pulsando entre a forma antiga e a nova, frequência acelerando (4 → 12 Hz) | `lerp(Proporcoes)` com t alternando 0/1; `ColorFilter` só nesse trecho |
| 3,6–3,75 s | clarão branco | quadro cheio, opacidade 1 → 0 em 150 ms |
| 3,75–4,6 s | revelação: nova forma pousa com squash (1,15/0,85) e assenta com `Molas.festa`; partículas de folhas/penas próprias da espécie | `SpringSimulation`; painter de partículas |
| 4,6–6 s | nome do estágio + "o que mudou" em uma linha + botão compartilhar; bicho faz o gesto ocioso novo do estágio | texto em 4 idiomas; `share_plus` já é dependência |

Ovo → filhote é uma variação: o ovo balança (antecipação), racha em três
batidas (uma por toque do usuário, reaproveitando o padrão da toca —
`toca.dart:43-50`), a casca se abre e o filhote pisca pela primeira vez.

"Reduzir movimento": sem tremor nem pulsar; crossfade de 600 ms entre as
formas e o texto. A evolução é **só subida** — não existe "des-evoluir",
nem cancelar (diferente do Pokémon, onde [Fato] o jogador pode apertar B
para impedir a evolução —
[Bulbapedia, Evolution prevention](https://bulbapedia.bulbagarden.net/wiki/Evolution_prevention));
aqui "pular" só encurta a animação.

### 4.6 Acompanhar o crescimento

- **Álbum** no perfil do bicho (`pet_profile.dart`): um retrato por estágio
  alcançado, rasterizado do painter, com data; estágios futuros como
  silhueta com "faltam N XP / N sessões".
- **Barra de crescimento** na home, abaixo do bicho, distinta da barra de
  nível (folha → muda → árvore, por exemplo).
- **Previsão honesta**: "Nina deve sair do ninho em ~3 dias no seu ritmo".

---

## 5. O pet real na sobreposição sobre outros apps

### 5.1 Situação e restrições

**[App]** `VigiaDaSessao` é um serviço em primeiro plano
(`foregroundServiceType="specialUse"`, `AndroidManifest.xml:187-194`) que
consulta o app da frente a cada 2 s e inicia `OverlayDoBaru`, um `Service`
comum, que adiciona uma `View` `TYPE_APPLICATION_OVERLAY` com
`FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL` por até 12 s
(`VigiaDaSessao.kt:229-260`, `OverlayDoBaru.kt:114-148`). O comentário do
vigia registra o requisito mais importante: **se o processo morrer, o
serviço sobe de novo sem o Dart** (`VigiaDaSessao.kt:31-34`). O próprio
overlay justifica o desenho nativo assim: "um overlay não pode depender do
motor do Flutter estar vivo" (`OverlayDoBaru.kt:170-176`).

**[Fato]** Restrições relevantes do Android:

- Um app é considerado em primeiro plano, para os limites de serviço do
  Android 8, se "It has a foreground service"
  ([Background Execution Limits](https://developer.android.com/about/versions/oreo/background))
  — é por isso que o `startService` do overlay a partir do vigia funciona.
- Desde o Android 12, iniciar **serviço em primeiro plano** a partir do fundo
  é proibido salvo exceções; ter outro FGS rodando **não** é exceção; ter
  `SYSTEM_ALERT_WINDOW` é, mas no **Android 15** só se o app "currently
  ha[s] a visible overlay window"
  ([FGS background start restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start);
  [Android 15 behavior changes](https://developer.android.com/about/versions/15/behavior-changes-15)).

### 5.2 As três soluções

**(a) Flutter rasteriza o `PetView` em quadros; o nativo toca.**

- **Precedente no próprio app:** o widget da tela inicial já rasteriza o
  `PetView` em PNG e o Kotlin mostra o bitmap
  (`widget_service.dart:1-12`, `:150-201`; `BaruWidget.kt:30-80`). A
  infraestrutura, os cuidados (não rasterizar no meio de animação — `:100-108`;
  tamanho em pixels finais — `:178-201`) e os testes já existem.
- Memória: [cálculo] quadro de 288×288 px (96 dp a 3×) em ARGB_8888 =
  ~332 KB; 8 quadros de respiração + 1 de olho fechado ≈ 3 MB, só enquanto
  o overlay está visível (≤ 12 s). Em disco, PNG comprimido, poucas centenas
  de KB.
- Bateria: [Opinião] desprezível — a rasterização acontece **uma vez** quando
  a sessão começa (o app está aberto) ou quando a aparência muda; o overlay
  invalida uma `View` pequena a ≤ 30 fps por no máximo 12 s.
- Início: decodificar 9 PNGs pequenos com `BitmapFactory` ao mostrar.
  [Opinião] Na ordem de dezenas de ms; **medir** no aparelho de referência
  (não achei número publicado).
- Compatibilidade Android 8–15: usa só APIs que o overlay já usa
  (`WindowManager`, `Canvas`, `BitmapFactory`, `ValueAnimator`). Nada novo de
  permissão nem de tipo de serviço. Funciona com o processo morto e o vigia
  ressuscitado, porque os quadros estão em disco.
- Limite: a animação nativa é simples (respiração, piscar, balanço, entrada
  com mola, "boca falando"). Não há afago nem reação ao toque no bicho.

**(b) Segundo `FlutterEngine` no serviço de overlay** (plugin
`flutter_overlay_window` ou engine própria via `FlutterEngineGroup`).

- **[Fato]** Engines de um `FlutterEngineGroup` custam ~180 kB incrementais
  **desde que outro engine do grupo esteja vivo**; se todos morrerem, o
  próximo tem o custo de um engine novo
  ([Flutter — multiple Flutters](https://docs.flutter.dev/add-to-app/multiple-flutters)).
  No caso do overlay, o engine principal costuma **não** estar vivo (o
  usuário está noutro app; o processo pode ter sido morto), então o custo e
  o tempo de início são os de um engine frio. Não achei número oficial para
  isso; precisa de medição.
- **[Fato]** `flutter_overlay_window` (MIT, 1.0.2) roda um `overlayMain()`
  próprio e declara seu próprio serviço `specialUse` com `SYSTEM_ALERT_WINDOW`
  e `FOREGROUND_SERVICE_SPECIAL_USE`
  ([pub.dev/flutter_overlay_window](https://pub.dev/packages/flutter_overlay_window));
  o histórico de versões registra correções de travamento ao fechar e de
  desacoplar a view do engine
  ([changelog](https://pub-web-s2.flutter-io.cn/packages/flutter_overlay_window/changelog)).
- Risco: [Opinião, a partir das regras citadas em 5.1] um **segundo FGS**
  iniciado do fundo esbarra na regra do Android 15 (exige overlay já visível
  — ovo e galinha). O estado do bicho teria de ser passado ao outro isolate
  por mensagem. Dois serviços `specialUse` aumentam a superfície de revisão
  da Play.
- Ganho: o bicho de verdade, animado, interativo (afago no overlay).

**(c) Portar o painter para Kotlin.** ~4000 linhas duplicadas que divergem a
cada ajuste — exatamente o que o ADR-015 recusou para o ícone. Descartada.

### 5.3 Recomendação: (a), com animação nativa leve

Implementação passo a passo:

1. **Desenho estático reutilizável** — `lib/widgets/pet.dart`: expor
   `PetRetrato` (ou `PetView.quadro`) que recebe uma `PoseFixa`
   (respiro −1…1, pisca 0–1, boca 0–1, olhar) e desenha o `_PetPainter` sem
   controladores. Hoje a pose é privada (`_Pose`, `:841`) e só nasce dos
   controladores.
2. **Aparência completa** — `lib/services/overlay_service.dart`: novo
   `AparenciaDoBicho {especie, pelagem, roupas, roupaDeCabeca, humor,
   estagio}` com `chave` estável (hash). Corrigir junto o widget da tela
   inicial, que também ignora roupa (`widget_service.dart:225-236`).
3. **Rasterizar** — `lib/services/quadros_do_bicho.dart`: com
   `ui.PictureRecorder` + `Picture.toImage(w, h)` +
   `toByteData(format: png)`, gerar 8 quadros de respiração (respiro em
   `sin(2πi/8)`), 1 com olhos fechados e 1 com boca aberta, em 288×288 px
   (ou `96 dp × devicePixelRatio`, teto 320). Sem dependência nova. Rodar
   **adiado e em repouso**, como `WidgetService` faz (`:100-122`), nunca no
   meio de uma animação.
4. **Quando** — antes de `vigiaComeca` (início da sessão, app aberto) e
   quando a aparência mudar; se a `chave` não mudou, não refaz.
5. **Entregar ao nativo** — `MethodChannel('baru/overlay')`, método novo
   `guardaQuadros {chave, quadros: List<Uint8List>}`; o `MainActivity`
   grava em `filesDir/overlay/<chave>/<n>.png` e um `chaveAtual` em
   `SharedPreferences`, apagando pastas antigas.
6. **Mostrar** — `OverlayDoBaru.kt`: `BalaoDoBaru.desenhaBicho` passa a
   carregar os quadros (`BitmapFactory.decodeFile`, com o mesmo cinto de
   `inSampleSize` do `BaruWidget.kt:49-73`); se não houver arquivo, cai no
   desenho genérico atual (fallback).
7. **Animar nativo** — um `ValueAnimator` em laço troca o quadro de
   respiração a ~8 fps (3,4 s por ciclo, mesmo `Tempo.respiracao`); outro
   agenda a piscada em intervalo aleatório 1,8–6,4 s (mesmo
   `pet.dart:511`); entrada: o bicho **sobe de baixo da borda** com
   `OvershootInterpolator` e o balão abre 120 ms depois; enquanto o texto do
   balão aparece (máquina de escrever, 30 ms/caractere), alterna boca
   aberta/fechada. Respeitar a escala de animação do sistema
   (`ValueAnimator.areAnimatorsEnabled()`, API 26 — confirmar na
   [referência](https://developer.android.com/reference/android/animation/ValueAnimator)).
8. **Humor no overlay** — durante a sessão o humor é previsível; gerar o
   conjunto do humor atual. [Opinião] Não mostrar o bicho triste sobre o
   TikTok: a regra "nunca culpa" pede o humor contente/curioso ali.
9. **Testes** — `test/overlay_test.dart`: a chave muda quando roupa, humor ou
   estágio mudam e não muda à toa; os quadros têm o tamanho certo; teste
   Kotlin (ou instrumentado) do fallback sem arquivo.

**Critério de aceite:** com buldogue tigrado de gorro, estágio filhote,
o overlay mostra **o mesmo desenho** da home (comparação visual lado a lado
na evidência), respira e pisca; com o processo do app morto durante a sessão,
o overlay continua mostrando o bicho certo; memória extra do overlay ≤ 5 MB
medida no Android Studio Profiler.

**Fase 2 opcional:** se a medição de (b) num aparelho intermediário mostrar
início < 500 ms e o FGS do plugin puder ser evitado (engine própria hospedada
pelo `VigiaDaSessao`, já em primeiro plano), reavaliar para ter afago no
overlay. Não antes.

---

## 6. Biblioteca de animações do Baru

Durações em ms. Curvas pelos nomes de `motion.dart` (`entrada` =
`easeOutBack`, `saida` = `easeInCubic`, `padrao` = `easeOutCubic`,
`enfatica` = `easeOutQuint`, `organica` = `easeInOut`) ou molas
(`toque` 500/26, `entrada` 320/22, `festa` 220/12). "RM" = com reduzir
movimento. Tudo é [Opinião] de especificação, calibrada pela faixa da NN/g
citada em 2.3.

### 6.1 Interface

| Animação | Gatilho | Duração | Curva | O que anima | RM |
|---|---|---|---|---|---|
| Entrada de tela (irmão) | troca de aba | 380 | padrao | já existe (`navegacao.dart:188-209`) + filhos escalonados 40 ms, fade + 8 px de subida, 260 cada | sem deslocamento, só fade 150 |
| Entrada de tela (detalhe) | abrir perfil, loja | 380 | padrao | já existe + `Hero` do bicho/ícone de origem | fade |
| Botão pressionado | dedo desce | 100 | padrao | escala 1 → 0,96, sombra baixa | escala 0,99 |
| Botão solto | dedo sobe | ~250 | mola toque | escala volta com leve passagem | igual |
| Chip selecionado | toque | 260 | mola toque | fundo preenche do centro, check desenhado (traço 0→1) | sem traço animado |
| Cartão de missão concluída | missão bate | 600 | enfatica | barra enche, check desenha, cartão faz quique 1,03 | só check |
| Botão "coletar" | missão pronta | laço 1600 | organica | brilho passando + respiração 1→1,03 | estático com contorno |
| Contador numérico | valor muda **na tela visível** | 700 | enfatica | já existe (`componentes.dart:48-66`); disparar só quando a tela está à vista | 280 |
| Barra de XP enchendo | ganho de XP | 700 + 300 | enfatica | enche; ao transbordar, brilho e reinicia do zero com o nível novo | salto direto |
| Toast/folha de baixo | aparece/some | 300 / 200 | entrada / saida | sobe 16 px + fade | fade |

### 6.2 Recompensa e mundo

| Animação | Gatilho | Duração | Curva | O que anima | RM |
|---|---|---|---|---|---|
| **Folhas voando até o saldo** | resgatar missão, fim de sessão, marco | 650–800 por folha, 6–10 folhas a cada 45 ms | arco Bézier; `easeInCubic` na chegada; rotação 1–2 voltas | folhas nascem na origem (`GlobalKey`), voam por `Overlay` até o `LeafBadge`; cada chegada: badge pulsa 1→1,12 (mola toque), +N no contador, tique sonoro, háptico leve | 1 folha, 300 ms |
| XP subindo | idem | 900 | padrao | "+N XP" sobe 40 px e some (existe no afago, `habitat.dart:947-966`); generalizar | fade |
| **Item caindo na cena** | compra/colocar | 450 queda + 120 impacto + 400 assentar | queda `easeIn` (gravidade); impacto squash 1,15/0,85; assentar mola festa | sombra cresce enquanto cai; poeira (4–6 partículas) no impacto; o bicho olha e faz saltinho | fade + 4 px |
| Item saindo | tirar | 250 | saida | sobe 10 px e some; bicho acompanha com o olhar | fade |
| **Raiz crescendo** | dia de ofensiva conta | 900 + 300 | padrao; broto em entrada | traço da raiz desenha (`PathMetric.extractPath` 0→1), broto novo surge com quique, terra treme 2 px | traço completo, broto fade |
| Congelamento usado | raiz protegida | 700 | padrao | geada cobre a raiz (gradiente) e brilha uma vez; sem tom de perda | fade |
| Toca (existente) | nível/marco | 3 gestos × 260 + 720 | — | manter; trocar ícone pelo bicho surgindo/cavando junto | igual |
| Celebração de nível | nível sobe | 900 + espera | entrada | **o bicho** no centro (não ícone), número N−1 → N rolando, partículas de folha com gravidade e rotação | sem partículas |
| Marco da trilha | marco | 900 | entrada | nó da trilha acende, linha entre nós desenha até o próximo, bicho anda até o nó | fade |
| **Evolução de estágio** | estágio sobe | ~6000 | ver 4.5 | ver 4.5 | crossfade 600 |
| Ovo rachando (progresso) | minuto de foco | 300 por racha | entrada | balanço ±6° e uma racha a mais | só racha |
| Chegada do dia | 1ª abertura | 900 | entrada | bicho acorda/vira para a câmera e acena; manter curto | fade |
| Habitat por hora | mudança de período | 2000 | organica | céu e luz em transição (hoje troca seca entre períodos) | 600 |

### 6.3 O bicho: humores

Transição entre humores: 600 ms, `lerp` de parâmetros de expressão
(abertura dos olhos, curva da boca, altura das sobrancelhas, inclinação da
cabeça, velocidade da respiração) — nunca troca seca.

| Humor | Respiração | Gestos (frequência) | Expressão | Acessório |
|---|---|---|---|---|
| Radiante | 2,8 s, amplitude 1,3× | saltinho e olhar em volta mais frequentes (4–8 s) | olhos arqueados, boca aberta | brilhos (existem); folhinhas dançando |
| Contente | 3,4 s | atual (5–12 s) | sorriso fechado | — |
| Neutro | 3,8 s | 8–15 s, mais "olhar" | boca reta | — |
| Sonolento | 5,0 s, funda | cabeceio (cabeça cai e levanta) a cada 6–10 s; bocejo | pálpebras a meio pau, piscar lento 400 ms | "zzz" (existe) |
| Sentindo falta | 3,8 s | olha para a borda da tela "esperando"; ao ver o usuário, levanta e se anima (transição para contente em 600 ms) | sobrancelhas para cima, olhar para longe | [Opinião] **remover a lágrima** (`_pingo`, `pet.dart:3996`): lágrima lê como culpa, e a regra é "nunca culpa"; esperar na porta comunica saudade sem acusar |

### 6.4 O bicho: ações e reações

| Animação | Duração | Notas |
|---|---|---|
| Toque | 900 (existe) | acrescentar antecipação de 90 ms (encolhe 3%) antes do quique; orelhas e cauda com follow-through |
| Carinho repetido | — | existe (corações); acrescentar cauda abanando por espécie |
| Afago | contínuo | existe; acrescentar inclinar o corpo para a mão (hoje só a cabeça, `pet.dart:1477-1478`) |
| Ser chamado pelo nome / notificação aberta | 800 | vira a cabeça para a câmera, orelhas sobem |
| Sessão começa | 700 | espreguiça e "vai trabalhar" (vai para a atividade da sessão) |
| Sessão termina | 900 | comemora: salto com squash no pouso, partículas |
| Desistência | 600 | **sem tristeza**: dá de ombros, volta ao ócio (regra "sem punição") |

### 6.5 Idle próprio de cada espécie (evento raro, a cada 45–120 s)

| Espécie | Gesto ocioso próprio (5–12 s) | Evento raro (45–120 s) |
|---|---|---|
| Capivara | mastigar o nada, orelha girando | passarinho pousa na cabeça e ela nem liga (3 s) |
| Lontra | esfregar o rosto com as patas | boiar de barriga para cima segurando uma pedrinha |
| Tartaruga | piscar lento, esticar o pescoço | recolher a cabeça no casco e espiar (2,5 s) |
| Coruja | girar a cabeça ~120° para um lado, voltar | girar quase de costas e voltar de repente; piscar um olho só |
| Axolote | guelras pulsando em onda | soltar uma bolha que sobe e estoura |
| Pinguim | bater as nadadeiras rapidinho | escorregar de barriga e voltar |
| Gata | lamber a pata | amassar pãozinho; perseguir a própria cauda com o olhar |
| Raposa | girar uma orelha de cada vez | salto de caça de cabeça na grama ("mouse") |
| Buldogue | bufada com o focinho, língua | rodar atrás do toco de rabo; deitar de barriga ("sapinho") |

---

## 7. Recomendações detalhadas

Formato: **o quê / por quê / como / esforço / impacto / critério de aceite.**

**R1 — Estágios de crescimento por espécie, com cena de evolução.**
Por quê: pedido explícito e item 6 do briefing; hoje não existe parâmetro de
idade (seção 1.2, item 6). Como: seções 4.2–4.5. Esforço: G. Impacto: alto —
cria o "acompanhar o crescimento" e um marco emocional no dia 1 (eclosão).
Aceite: conta nova com coruja vê ovo; ao concluir a 1ª sessão a cena de
eclosão roda e a coruja vira filhote; com 370 XP na espécie vira jovem; a
diferença entre estágios passa num teste de evidência (`evidencia_*`) com os
5 retratos lado a lado; sync entre dois aparelhos preserva o maior estágio.

**R2 — Overlay com o bicho real (quadros rasterizados).**
Por quê: item 7 do briefing; `OverlayDoBaru.kt:303-384` desenha genérico.
Como: seção 5.3. Esforço: M. Impacto: alto — é o momento em que o produto
cumpre a promessa central fora do app. Aceite: seção 5.3.

**R3 — Rig por partes com follow-through e antecipação.**
Por quê: corpo rígido, sem antecipação (1.2, itens 2–3). Como: 3.4 passo 1.
Esforço: G (refator), feito espécie a espécie. Impacto: alto na percepção de
"animação amadora". Aceite: no toque, orelhas/cauda continuam se mexendo
≥ 150 ms depois de o corpo parar (verificável em quadros de evidência);
antecipação presente em toque, saltinho e brincadeira.

**R4 — Dobrar amplitudes legíveis.**
Por quê: respiração invisível (`respiracao-1..6`). Como: respiração do
tronco 3,5% com cabeça atrasada ~15% da fase; quique 1,5×. Esforço: P.
Impacto: médio, imediato. Aceite: diferença de altura do tronco entre
quadro de pico e de vale ≥ 6 px num bicho de 200 px.

**R5 — Humores com transição e expressão contínua; remover a lágrima.**
Por quê: humor booleano (1.2 item 5); lágrima conflita com "nunca culpa".
Como: 6.3. Esforço: M. Impacto: médio-alto (item "emoções com mais
qualidade" do briefing). Aceite: mudar o humor gera 600 ms de interpolação
sem salto (teste de quadros); nenhum humor desenha lágrima.

**R6 — Idle em três níveis, com repertório por espécie.**
Por quê: os 6 gestos são iguais para 9 espécies. Como: 6.5, sorteio com
memória (não repetir os 2 últimos). Esforço: M (2–3 gestos por espécie).
Impacto: médio-alto (personalidade, compartilhável). Aceite: cada espécie
tem ≥ 2 gestos e 1 evento raro exclusivos, capturados em evidência.

**R7 — Folhas voando até o saldo e contador na tela certa.**
Por quê: coleta sem trajeto; contador anima fora da vista
(`RELATORIO_UX_DUOLINGO.md:198-202`). Como: 6.2, `Overlay` + `GlobalKey`,
escalonamento, pulso do badge por folha. Esforço: M. Impacto: alto
("clareza na coleta de recompensas" do briefing). Aceite: ao resgatar uma
missão, N folhas visíveis saem do cartão e o saldo só começa a subir quando
a primeira chega; com RM, uma folha em 300 ms.

**R8 — Celebração com o bicho no centro e partículas temáticas.**
Por quê: celebração de nível mostra um ícone de flor (`celebracao-nivel.png`).
Como: substituir o círculo com ícone por `PetView` em escala 1,6 fazendo a
reação de comemoração; partículas de folha com gravidade e rotação.
Esforço: P–M. Impacto: alto. Aceite: quadro de evidência da celebração
mostra o bicho da conta (espécie, pelagem, roupa).

**R9 — Habitat: itens desenhados e queda com física.**
Por quê: itens são retângulos (`models.dart:158-162`). Como: um painter por
item (ponte, banco, lanterna, pedras…) no mesmo traço do bicho; queda
6.2. Esforço: M–G (depende do laudo de visual). Impacto: alto na percepção
de "amador". Aceite: nenhum item da loja é desenhado como `Container`
retangular; o bicho olha para o item que chega.

**R10 — Fazer valer `motion.dart`: molas, stagger, sem literais.**
Por quê: `Molas` sem uso; 36 durações soltas (1.1). Como: tokens de
`stagger` (40 ms), `trajeto` (700 ms), `impacto` (120 ms); trocar literais;
um teste que falha se aparecer `Duration(milliseconds:` em `lib/widgets` ou
`lib/screens` fora de uma lista permitida (no estilo de
`test/uma_contagem_test.dart`, que já lê código-fonte). Esforço: P.
Impacto: médio (coerência). Aceite: o teste passa; `Molas.toque` usado nos
botões.

**R11 — Desempenho do bicho e da cena.**
Por quê: `AnimatedBuilder` do habitat reconstrói o bicho a cada quadro;
`Opacity` animado; `saveLayer` no nado (1.2 item 7, 1.3). Como: `child` no
`AnimatedBuilder`, cor semitransparente em vez de `Opacity`, `ui.Picture`
cacheado para marcas estáticas, pausar fora da tela. Esforço: P–M.
Impacto: bateria e margem para R1/R6. Aceite: DevTools sem quadro > 16 ms na
home num aparelho intermediário; número de rebuilds do `PetView` por segundo
na home = 0 (só repaint).

**R12 — `Hero` do bicho entre home, perfil, sessão e evolução.**
Por quê: nada atravessa a transição (1.5). Esforço: P. Impacto: médio
(continuidade, "é o mesmo bicho"). Aceite: ao abrir o perfil, o bicho voa
da cena para o cabeçalho.

---

## 8. Conclusão

### 8.1 As 10 recomendações mais importantes, em ordem

1. **R1** Estágios de crescimento por espécie (ovo/ninho → pleno) com
   `xpPorEspecie` aditivo e cena de evolução. (G)
2. **R2** Overlay com o bicho real: Dart rasteriza quadros, Kotlin toca com
   respiração e piscar nativos. (M)
3. **R8** Celebração com o bicho no centro e partículas de folha. (P–M)
4. **R7** Folhas voando até o saldo e contador animando na tela visível. (M)
5. **R4** Dobrar amplitudes legíveis (respiração, quique). (P)
6. **R3** Rig por partes com follow-through e antecipação. (G)
7. **R5** Humores com transição e expressão contínua; sem lágrima. (M)
8. **R6** Idle em três níveis com gestos e evento raro por espécie. (M)
9. **R9** Itens do habitat desenhados e queda com física. (M–G)
10. **R10 + R11** Tokens de movimento valendo de verdade e desempenho do
    bicho/cena. (P–M)

### 8.2 O que não fazer

- **Não migrar o bicho para Rive, Lottie ou sprites agora.** Cria uma segunda
  fonte de verdade, explode combinatoriamente e depende de animador que não
  temos (seção 3).
- **Não portar o painter para Kotlin** para o overlay (5.2-c).
- **Não colocar um segundo `FlutterEngine` com FGS próprio** no overlay sem
  medir e sem resolver a regra do Android 15 (5.2-b).
- **Não criar estágio que regride** ou "des-evolução" por inatividade, nem
  bicho que fica fraco/doente: viola "sem punição".
- **Não vender estágio, aceleração de crescimento ou espécie por dinheiro**:
  viola "espécies nunca por dinheiro" (e, por extensão, crescimento).
- **Não usar confete genérico multicolorido** nem efeitos de cassino: destoam
  da estética e transformam recompensa em ruído.
- **Não desenhar ovo para mamífero.** O produto já escolheu realismo
  (`pet.dart:97-133`).
- **Não animar fora da tela visível** (contador na rota de baixo) nem durante
  a sessão de foco (celebração invadindo o foco).

### 8.3 Riscos e dúvidas em aberto

- **Decisão de produto:** espécie liberada tarde começa como ovo ou com piso
  de filhote? (4.2). A arquitetura serve aos dois.
- **Limiares de estágio** foram calculados com a média de ~70 XP/dia do
  comentário do código (`progressao.dart:299-301`), não com dados reais de
  uso; validar com a distribuição real antes de fixar.
- **Custo de arte procedural:** 9 espécies × 5 estágios é muito desenho por
  código; o laudo de visual deve priorizar 2–3 espécies-vitrine primeiro
  (coruja, capivara, buldogue) e lançar as outras depois.
- **Tempo de início e memória do overlay** são estimativas de cálculo;
  precisam de medição em aparelho Android 8 de entrada e Android 15.
- **Rive RML/CLI** é recente; não verifiquei suporte a bones/mesh em RML. Se
  um dia for usado, começar por peças isoladas.
- **`flutter_overlay_window`** acabou de lançar 1.0.2; não encontrei relatos
  confiáveis de estabilidade no Android 14/15.
- **Valores oficiais de mola do Material 3 Expressive** não foram
  encontrados em fonte do Google acessível; os números de pacotes de
  terceiros divergem.
- **Não pude rodar o app nem o Flutter neste ambiente** (sem `flutter` no
  PATH): toda observação de movimento vem do código e dos quadros de
  evidência existentes, não de captura nova.

---

## Fontes

- Duolingo Blog — [World character visemes](https://blog.duolingo.com/world-character-visemes)
- Duolingo Blog — [Streak milestone design & animation](https://blog.duolingo.com/streak-milestone-design-animation)
- Duolingo Blog — [How the streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit)
- Rive blog — [Duolingo's AI video call brings Lily to life](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)
- Rive — [pub.dev/rive](https://pub.dev/packages/rive) · [Flutter runtime docs](https://rive.app/docs/runtimes/flutter/flutter) · [Runtime sizes](https://rive.app/docs/runtimes/runtime-sizes.md) · [Pricing](https://rive.app/pricing) · [CLI](https://rive.app/docs/cli/overview) · [RML](https://rive.app/docs/runtimes/advanced-topic/rml.md) · [Scripting em Luau](https://rive.app/blog/why-scripting-runs-on-luau)
- [pub.dev/lottie](https://pub.dev/packages/lottie) · [pub.dev/flutter_animate](https://pub.dev/packages/flutter_animate) · [pub.dev/flame](https://pub.dev/packages/flame) · [pub.dev/confetti](https://pub.dev/packages/confetti)
- [pub.dev/flutter_overlay_window](https://pub.dev/packages/flutter_overlay_window) · [changelog](https://pub-web-s2.flutter-io.cn/packages/flutter_overlay_window/changelog)
- Flutter — [Performance best practices](https://docs.flutter.dev/perf/best-practices) · [Multiple Flutter instances](https://docs.flutter.dev/add-to-app/multiple-flutters)
- Android — [Background execution limits (8.0)](https://developer.android.com/about/versions/oreo/background) · [Restrictions on starting FGS from background](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start) · [Android 15 behavior changes](https://developer.android.com/about/versions/15/behavior-changes-15) · [MotionScheme (Compose M3)](https://developer.android.com/reference/kotlin/androidx/compose/material3/MotionScheme) · [ValueAnimator](https://developer.android.com/reference/android/animation/ValueAnimator)
- NN/g — [Executing UX Animations: Duration and Motion Characteristics](https://www.nngroup.com/articles/animation-duration/)
- IxDF — [How to apply Disney's 12 principles of animation to UI](https://ixdf.org/literature/article/ui-animation-how-to-apply-disney-s-12-principles-of-animation-to-ui-design) · UX Collective — [Disney's 12 principles exemplified in UX](https://uxdesign.cc/disneys-12-principles-of-animation-exemplified-in-ux-design-5cc7e3dc3f75)
- Glocker et al. — [Baby schema in infant faces… (Ethology, 2009)](https://repository.upenn.edu/cog_neuro_pubs/11) · [PNAS 2009](https://www.cceb.upenn.edu/csa/assets/user-content/documents/PNAS-2009-Glocker.pdf)
- Bulbapedia — [Evolution prevention](https://bulbapedia.bulbagarden.net/wiki/Evolution_prevention)
- Terceiros, valores de mola divergentes: [material_expressive](https://pub.dev/packages/material_expressive) · [motor](https://pub.dev/packages/motor)

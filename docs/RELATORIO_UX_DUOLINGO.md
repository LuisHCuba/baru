# Baru × Duolingo — análise profunda de experiência do usuário

Data: 2026-08-29. Escopo: 100% experiência do usuário, com o Duolingo como
benchmark — a referência que o próprio [ROADMAP.md](ROADMAP.md) declara
("tão bom quanto o Duolingo, tão dinâmico quanto o Clash Royale").

Método: leitura integral do código das 16 telas, 8 serviços e dos catálogos de
dados (`lib/data/`), mais os documentos de produto e as evidências visuais de
`docs/evidence/`. Toda afirmação sobre o app cita `arquivo:linha`. As
referências ao Duolingo vêm do modelo de engajamento público deles (onboarding
com valor antes de cadastro, cadeia de celebração pós-lição, streak como
produto-bandeira, notificações com variação e bandit, ligas semanais, economia
com sumidouros).

---

## Sumário executivo

O Baru tem uma **fundação de experiência acima da média**: tom de voz
consistente e sem culpa nos 4 idiomas, contrato de "nunca punir" respeitado de
ponta a ponta, pet vivo com afago/háptico, missões determinísticas com
anatomia completa, trilha em corrente com 22 marcos, plano de notificações com
teto anti-spam e horário aprendido do hábito. Isso é raro num MVP e é
exatamente a matéria-prima que o Duolingo usa.

O problema não é falta de sistemas — quase todos existem. É que **os sistemas
não são *sentidos* nos momentos que decidem retenção**. Os cinco maiores gaps,
em ordem de impacto:

1. **O primeiro contato cobra tudo antes de dar qualquer coisa.** Login com
   e-mail/senha (possivelmente com confirmação por e-mail) antes do primeiro
   pixel de produto, ~15 toques até a home, quiz de 6 telas sem pular, até 4
   telas de permissão e um paywall sem botão de saída — e o usuário chega a um
   habitat vazio, sem nunca ter feito uma sessão. O Duolingo entrega a
   primeira lição completa, com celebração, **antes** de pedir conta.
2. **O momento de recompensa — o coração do loop — é mudo.** Concluir uma
   sessão toca um `.wav` e mostra números estáticos; nenhum botão do loop tem
   háptico ou som; o XP ganho nunca aparece; os contadores animados rodam na
   home **enquanto o usuário está na tela de resultado**; e a celebração de
   nível cobre o "+10 folhas" que acabou de ser entregue. No Duolingo o fim da
   lição é uma sequência coreografada de 3–5 telas (XP → combo → streak →
   liga), cada uma com som, contagem e personagem reagindo.
3. **A raiz (streak) não é tratada como produto-bandeira.** Só sessão
   concluída conta presença; a quebra é silenciosa; não há celebração de marco
   de raiz (7, 30, 100 dias); não há aviso de risco **dentro** do app; o
   congelamento é invisível até ser consumido. No Duolingo o streak é o motor
   nº 1 de retenção e recebe tela própria, marcos celebrados, equipagem de
   freezes e o "streak saved" como cena.
4. **A economia não tem sumidouro e o conteúdo acaba.** Um usuário engajado
   compra a loja inteira em ~28 dias e completa a trilha em ~67; depois disso
   folhas se acumulam sem destino, e nenhum sistema recomeça. O Duolingo
   nunca "acaba": ligas resetam toda semana, missões mensais trocam, a loja
   tem consumíveis.
5. **Zero mecânica social e notificações sem variação.** Nenhum amigo, liga ou
   desafio (declarado para depois no roadmap — mas é o multiplicador de
   retenção mais documentado do Duolingo), e todos os textos de notificação
   são fixos — a mesma frase todo dia perde efeito em semanas; o Duolingo
   rotaciona templates com um bandit e mede cada envio.

Além dos gaps estruturais, a varredura achou **defeitos pontuais de UX** que
valem correção imediata (seção 11): data hardcoded no relatório, botão
"+5 min" da sobreposição que não adia nada, chip "Livre" que é um 45 fixo,
resposta do quiz que nunca casa (`companhia` vs `so_companhia`), notificação
de saudade que só dispara com o app aberto, e a sobreposição de fora de sessão
desenhada por cima do próprio Baru.

---

## 0. O modelo do Duolingo, resumido como régua

Para o relatório ser acionável, o benchmark precisa ser explícito. O Duolingo
sustenta DAU/MAU ~30%+ com sete alavancas:

| # | Alavanca | Como o Duolingo faz |
|---|---|---|
| D1 | **Valor antes de compromisso** | A primeira lição inteira roda sem conta; o cadastro chega depois da primeira celebração ("delayed signup" foi um dos maiores ganhos de retenção que eles já publicaram). |
| D2 | **Cadeia de celebração** | Fim de lição = sequência de telas: XP com contagem, acerto/combo, progresso de missão, streak com chama animada, movimento na liga. Cada tela com som, háptico e o personagem reagindo. |
| D3 | **Streak como produto** | Chama onipresente, tela própria com calendário, marcos celebrados e compartilháveis (7/30/100/365), Streak Freeze comprável e equipável (2 de reserva), Streak Repair, aviso "seu streak expira em 1h" no fim do dia. |
| D4 | **Notificações vivas** | Dezenas de templates rotacionados por bandit multi-armed, persona do Duo ("passivo-agressivo" famoso), horário = hora habitual de prática, deep link para a ação, e a regra de parar quando não funciona ("we'll stop sending these"). |
| D5 | **Compromisso de agenda** | Missões diárias que expiram, missões mensais, eventos temáticos, Double XP em janelas — motivos para abrir *hoje*, não um dia. |
| D6 | **Social e status** | Ligas semanais (30 pessoas, sobe/desce), amigos, Friend Streak, Friends Quests cooperativas, perfil com conquistas. É o maior multiplicador de sessões/dia deles. |
| D7 | **Economia com sumidouro** | Gems entram sempre e saem sempre: freezes, roupas do Duo, boosts, recuperação de corações. O saldo nunca "enche". |

O Baru, pelo contrato de produto (sem punição, sem culpa), **não deve copiar
tudo** — corações/vidas e a agressividade de paywall do Duolingo contrariam a
marca. O relatório marca onde a régua se aplica e onde a identidade do Baru
pede outra resposta.

---

## 1. Onboarding e primeiro valor — o gap mais caro

### O que existe hoje (fatos)

- **Login antes de tudo.** Com Supabase ligado, `AuthGate` só constrói o app
  após sessão de e-mail válida (`lib/auth_gate.dart:266`); não há guest,
  anônimo nem "entrar depois" (`lib/screens/auth_screen.dart:11`). O signup
  tem 3 campos e pode exigir confirmação por e-mail — o usuário sai para o
  inbox **antes de ver qualquer pet** (`lib/l10n.dart:580`).
- **~15 toques até a home**: idioma → promessa → 6 telas de quiz → revelação →
  meta → até 4 telas de permissão → paywall (`lib/screens/onboarding_screen.dart:38-53`,
  `lib/state.dart:1185-1212`). Trilha e Missões ficam vazias até o fim
  (`lib/screens/trilha_screen.dart:30-36`).
- **A revelação do pet não celebra.** "Você é uma capivara" é uma `ListView`
  estática — zero `Celebracao`, som ou háptico no onboarding inteiro — e na
  mesma tela pede **quatro decisões** (nome, sexo, pelagem, trocar espécie),
  com 5 espécies cadeadas à vista (`onboarding_screen.dart:277-359`).
- **O paywall não tem saída visível.** Um único CTA ("Começar 7 dias grátis"),
  sem X nem "agora não"; o back devolve às permissões
  (`lib/screens/paywall_screen.dart:67-71`, `lib/navegacao.dart:60`). E ele
  não protege nada: a flag `trial` não gateia nenhuma funcionalidade, e
  "Restaurar" concede o trial sem verificação (`lib/state.dart:2234-2240`).
- **Fricções menores que somam**: o app sempre nasce em `pt` mesmo em aparelho
  em inglês (`lib/state.dart:458`); o CTA do passo 1 diz "Começar foco" mas
  leva ao quiz (mesma chave `start` do botão real de sessão); o passo 1
  mostra a capivara padrão que pode virar coruja duas telas depois; não há
  voltar entre passos — o back do sistema abre a folha de **sair do app**
  (`lib/state.dart:1109-1113`); a meta é pedida por autorrelato (4 chips)
  quando a permissão do passo seguinte mediria sozinha.
- **Ninguém ensina o loop.** Não existe primeira sessão guiada, tour ou
  destaque; o usuário cai numa home de 12 blocos com o botão "Começar foco"
  como **último item, abaixo da dobra** (`lib/screens/home_screen.dart:296-304`),
  num habitat zerado (`state.dart:1456-1479`).

### O que o Duolingo faz (D1)

Lição antes de conta; celebração antes de qualquer pedido; perguntas de perfil
diluídas ("por que você está aprendendo?") com barra andando e reforço
positivo a cada resposta; notificação e paywall só depois do primeiro sucesso.

### Recomendações

**R1 — Inverter a ordem: valor → compromisso → conta.** (P1, esforço G)
Sequência alvo: idioma (pré-selecionado pelo locale) → promessa → quiz →
**revelação celebrada** → **primeira sessão guiada** → resultado celebrado →
meta + permissão de uso (contextual) → *aí* conta e paywall. Tecnicamente:
Supabase suporta sign-in anônimo com upgrade posterior para e-mail — o
`AuthGate` passaria a exigir sessão (qualquer uma) e a `ContaScreen` ofereceria
"proteger meu progresso com e-mail". O snapshot local já existe como fallback
(`auth_gate.dart:63-73`), então o custo é o fluxo de upgrade, não a persistência.

**R2 — Primeira sessão guiada de 5 minutos.** (P1, M) Após a revelação:
"Vamos fazer seu primeiro foco juntos — 5 minutos". Sessão curta especial,
recompensa cheia (10 folhas + marco 1 da trilha `primeiro_foco`, que já paga
20 folhas — `lib/data/progressao.dart:312`), desaguando na cadeia de
celebração da R8. Isso ensina o loop inteiro (sessão → folhas → loja) por
demonstração, e o usuário chega à home com folhas para quase comprar o
primeiro item (lily, 40) — um objetivo imediato em vez de um habitat vazio.

**R3 — Celebrar a revelação e fatiar a customização.** (P1, P/M) Usar a
`Celebracao` existente (`lib/widgets/celebracao.dart`) na revelação: entrada
animada do pet, partículas, som `conquista`, háptico. Nome em tela própria
("Como você quer chamar ele?"), sexo/pelagem adiados para Ajustes ou para um
momento pós-primeira-sessão. Remover o `SpeciesPicker` com cadeados da
revelação — espécie trancada ali só enfraquece o "você é uma capivara".

**R4 — Paywall com saída e com produto.** (P0 para a saída; P2 para o gate)
Adicionar "Agora não" que leva à home — reter alguém à força numa tela que não
cobra nada só gera abandono no pior momento. Estrategicamente (quando o IAP
real chegar): decidir o modelo freemium — o Duolingo deixa 100% do core grátis
e vende conveniência/estética. Para o Baru, o candidato natural é: sessões e
raiz sempre grátis; premium = cenários/roupas exclusivos, estatísticas longas,
congelamento extra. Mostrar o paywall após a primeira celebração, não antes da
primeira sessão.

**R5 — Locale do aparelho como idioma inicial** (P0, P) — `state.dart:458`
nasce `'pt'`; usar `PlatformDispatcher.locale` como default do passo 0 (o
`auth_gate.dart:47` já faz isso para o login).

**R6 — Permissões no momento da necessidade.** (P2, M) Manter o assistente
(que é excelente — custo da recusa explícito, passo a passo do Android 13,
`lib/l10n_sobreposicao.dart:45-71`), mas movê-lo: uso do aparelho junto da
meta ("quer que eu meça em vez de chutar?"), sobreposição na primeira sessão
("posso te chamar de volta se você sair?"), notificações após o primeiro
resultado ("quer que eu avise quando a raiz correr risco?"). Cada pedido com
contexto converte mais que quatro seguidos no fim do onboarding.

---

## 2. O loop central: sessão → recompensa

### O que existe hoje (fatos)

- **Home**: 12 blocos num `ListView`; a cena tem 372px e o CTA "Começar foco"
  é o 12º item — **exige rolagem** num frame de 892px
  (`home_screen.dart:24-307`, `lib/widgets/app_frame.dart:13-14`). Folhas e
  raiz aparecem duplicadas (topo + cartão da semana).
- **Botões mudos**: `PrimaryButton`, `SelectChip`, `TextAction`, `GhostButton`
  e `SoftCard` não têm háptico, som nem escala de pressão — só efeito de
  *hover de mouse* (`lib/widgets/common.dart:13-40`). Existe um sistema
  paralelo **com** háptico e `AnimatedScale` (`lib/widgets/componentes.dart:141-170`)
  que o loop não usa.
- **Conclusão de sessão**: um som `fim` no domínio (`state.dart:1896`) e mais
  nada — sem háptico, sem partícula. A tela de resultado é estática: chip
  "+10 folhas" em `Text` cru, stats sem contador animado
  (`lib/screens/result_screen.dart:33-77`), **XP ganho nunca mostrado** (12 XP
  da sessão + 5 do dia de sequência ficam invisíveis).
- **A animação acontece na tela errada**: o `LeafBadge` e o `CartaoNivel` da
  home animam o incremento **enquanto o usuário está no resultado** (rota
  mantém a página de baixo montada — `navegacao.dart:129-149`); quando ele
  volta, a contagem já acabou.
- **A celebração atropela a recompensa**: subir de nível empilha um véu opaco
  com a toca de 3 gestos **por cima do resultado**, escondendo o "+folhas"
  (`lib/app.dart:295-302`, `lib/widgets/toca.dart:47`); e pode invadir até a
  sessão de foco (comentário em `app.dart:315`).
- **Anúncio duplicado**: a notificação "Sessão concluída / +{k} folhas" é
  agendada no início e dispara mesmo com o app em primeiro plano, junto com a
  tela de resultado (`state.dart:1842-1849`).
- **Fricções da sessão**: SnackBar de erro de permissão em cima da tela de
  foco recém-aberta (`state.dart:1806-1808`); folha de desistir aparece por
  corte seco, contra a regra declarada do próprio `navegacao.dart:15`
  (`session_screen.dart:178`); o chip "Livre" chama `pickDur(45)` sem picker e
  ainda paga menos que o de 50 min (22 folhas/18 XP vs 25/30 —
  `home_screen.dart:280`, `lib/models.dart:102,577-582`).
- **O pet é menos vivo quando o usuário vai bem**: os 6 gestos ociosos
  (espreguiçar, sacudir, farejar…) só rodam em `Activity.idle`, que só ocorre
  no humor triste `missingYou` (`lib/widgets/pet.dart:550`,
  `state.dart:936-948`). E o afago em sessão/resultado dispara háptico mas não
  credita nem soa nada (`aoCarinho` nulo fora da home).

### O que o Duolingo faz (D2)

Cada toque tem som e resposta visual; o fim da lição é uma **sequência**: tela
de XP com contagem crescente → precisão/combo → progresso das missões diárias
(barras enchendo na frente do usuário) → chama do streak → posição na liga.
O personagem comemora em cada uma. Nada é simultâneo; cada recompensa tem seu
segundo de palco.

### Recomendações

**R7 — Dar corpo tátil ao loop.** (P0, P) Migrar os botões do loop para o
padrão de `componentes.dart` (háptico `selectionClick` + `AnimatedScale`) e
adicionar som/háptico aos três eventos mudos: iniciar sessão (`lightImpact`),
concluir (`heavyImpact` junto do som `fim`), resgatar bônus de meta. Custo
mínimo — os sistemas já existem, é ligação.

**R8 — Transformar o resultado em cadeia de celebração.** (P1, M) Sequência
na própria `ResultScreen`, um foco por vez, ~1s cada, pulável por toque:
1. pet comemora (pose nova) + "+{k} folhas" com `ContadorAnimado` e chuva de
   folhinhas;
2. barra de XP enchendo com "+12 XP" (e "+5 primeira do dia" quando houver);
3. raiz: no dia que a presença conta, a `RaizViva` **cresce na tela** ("Raiz
   de 4 dias");
4. progresso de missões tocadas pela sessão ("Dois focos hoje: 1/2 → 2/2");
5. se houver nível/marco, a toca entra **aqui, como etapa final** — nunca
   como véu por cima do chip de folhas.
Todos os componentes (contador, barra, raiz, toca, partículas) já existem;
o trabalho é orquestração. Remover a notificação de fim quando o app está em
primeiro plano.

**R9 — CTA fixo na home.** (P1, P/M) "Começar foco" ancorado no rodapé (acima
da barra de abas) ou logo abaixo da cena do habitat; os cartões informativos
rolam por baixo. O botão mais importante do app não pode depender de rolagem.
Aproveitar para deduplicar folhas/raiz (aparecem 2× — `home_screen.dart:78,159`).

**R10 — "Livre" de verdade.** (P0, P) Chip abre um seletor (slider ou roda de
15–120 min) e a recompensa segue `floor(min×0,5)` com a curva mostrada antes
de iniciar ("45 min → 22 folhas · 18 XP"). Ou renomear para "45 min" até o
picker existir — o rótulo atual mente.

**R11 — Pet vivo para quem vai bem.** (P1, P) Liberar os gestos ociosos em
todas as atividades (com frequência menor durante nado/pastar), e creditar o
afago onde ele é possível — ou desligar `interativo` fora da home. O estado
mais expressivo do bicho não pode ser o triste: no Duolingo, o Duo comemora
com o usuário; a alegria é o estado mais animado, não o abandono.

**R12 — Higiene da sessão.** (P0, P) Mover o SnackBar de permissão de
sobreposição para antes de iniciar (na home, como linha sob o CTA); animar a
entrada/saída da folha de desistir (é um `if` num `Stack` hoje); mostrar na
tela de foco o que está em jogo ("+10 folhas · +12 XP ao concluir").

---

## 3. Raiz (streak) — de contador a produto-bandeira

### O que existe hoje (fatos)

- Presença = **só sessão de foco concluída** (`state.dart:1896-1901`,
  `2069-2085`). Descanso cumprido, missões e abrir o app não seguram a raiz.
- Congelamento: 1/semana, automático, reposto toda segunda (que também apaga
  as marcas da semana — `state.dart:2088-2092`); devolvido por winback após
  3+ dias fora. **Não é visível antes de usar, não é equipável, não é
  comprável.** Curiosidade: o freeze *incrementa* a raiz (+1 dia sem fazer
  nada) e pode bater `melhorSequencia` (`state.dart:2076-2085`).
- **Quebra silenciosa**: `streak = 0` na virada, sem tela, aviso ou
  reconhecimento; a raiz vira semente e a fala do humor simplesmente para de
  mencioná-la (`lib/l10n_humor.dart:146-149`).
- **Nenhum aviso de risco dentro do app** — só as notificações (bem
  desenhadas: hoje + amanhã, hora do hábito+1 com clamp 19–22h, variantes
  para véspera de marco e congelamento — `lib/data/descanso_retencao.dart:89-173`,
  `notification_service.dart:740-775`).
- A `RaizViva` cresce com galhos em marcos [3,7,14,30,60,100,180,365]
  (`lib/widgets/raiz.dart:53`), mas **nenhum marco de raiz dispara
  celebração** — `Celebracao` só existe para nível, marco de trilha e chegada
  (`app.dart:319-349`). E a curva satura: a raiz do dia 200 é indistinguível
  da do dia 500 (`raiz.dart:124-126`).
- O cartão compartilhável da raiz existe e é bonito (360×540, desenhado, não
  screenshot — `lib/widgets/cartao_da_raiz.dart`), mas só é oferecido
  passivamente na tela da sequência.

### O que o Duolingo faz (D3)

O streak é o sistema mais protegido e mais celebrado: chama na barra em toda
tela; marcos com tela cheia + cartão de share; freeze visível/equipável (ver
os 2 slots cheios dá segurança); Streak Repair pago; "streak society" após
365; aviso agressivo no fim do dia; e o "streak saved by freeze" é uma cena,
não um fato silencioso.

### Recomendações

**R13 — Celebrar os marcos da raiz.** (P1, P/M) Nos dias [3,7,14,30,60,100,
180,365] (os mesmos galhos de `RaizViva.marcos`), disparar a `Celebracao` com
a raiz crescendo em destaque e **oferta imediata do cartão de share** — é o
momento de maior orgulho e o melhor gancho viral do app (a própria doc do
cartão diz: "mostrar é o que traz gente nova", `sequencia_screen.dart:15-17`).

**R14 — Aviso de risco dentro do app.** (P1, P) Depois das ~19h sem presença,
a pílula da raiz na home muda de estado (laranja → âmbar pulsante, "Sua raiz
de 9 dias quebra à meia-noite. Um foco curto segura") e a fala do humor
assume o tema. Notificação sozinha não alcança quem está *no* app.

**R15 — Congelamento visível e "raiz salva" como cena.** (P1, M) Mostrar o
freeze como objeto ("1 congelamento guardado · volta toda segunda") na tela
da sequência e na pílula em risco; quando ele for consumido, a próxima
abertura mostra uma cena curta ("Seu congelamento segurou a raiz de 12 dias")
— hoje isso só existe como notificação. Considerar **comprar congelamento
extra com folhas** (teto de 2 guardados): dá o sumidouro que a economia não
tem (seção 6) e é a mecânica de streak mais aceita do Duolingo — e é proteção,
não punição, então respeita o contrato.

**R16 — Repensar o que conta presença.** (P2, decisão de produto) Hoje quem
abre o app, cumpre o descanso de 40 min e colhe 3 missões **perde a raiz**.
Coerente com "presença = foco", mas duro para um produto sem punição.
Alternativa alinhada: presença = sessão concluída **ou** descanso cumprido
(ambos são "tempo longe da tela", que é a promessa do app). Se mantiver a
regra atual, dizer explicitamente na tela da raiz o que conta.

**R17 — Reparo de raiz.** (P2, M) Perdeu a raiz ontem? Oferecer *uma* vez o
reparo por folhas caras ("Reenraizar: 150 folhas") nas primeiras 24h. É
sumidouro, é winback, e formulado como cuidado ("replantar") mantém o tom.

---

## 4. Missões e o compromisso diário

### O que existe hoje (fatos)

- 3 diárias (pool de 13) + 2 semanais (pool de 6), sorteio determinístico por
  conta+data (`lib/data/missoes.dart:535-613`), mais o **descanso** fixo (40
  min longe do telefone, 30 folhas) e a **retomada** no dia da volta. Anatomia
  exemplar: título de ação, linha de "como", barra, recompensa exata, prazo,
  toque leva à tela da ação (`missoes_screen.dart:440-611`), resgate pela toca
  com gesto de cavar.
- **Sem escalonamento nem personalização**: alvos constantes, sorteio uniforme,
  nenhuma adaptação a nível/histórico (`missoes.dart:151-156` aceita isso por
  ADR).
- **6 das 13 diárias exigem permissão de uso**: é estruturalmente possível
  sortear um dia com as 3 diárias travadas — e o descanso também exige
  (`missoes.dart:157-280,802`).
- Nada de missões mensais, eventos, ou missões cooperativas. Quando tudo está
  feito, o cartão aponta para a trilha (`l10n.dart:735`).

### O que o Duolingo faz (D5)

Missões diárias escalonadas ao usuário, Friends Quests cooperativas, desafio
mensal com badge colecionável (o motivo nº 1 de "abrir todo dia do mês"),
eventos temáticos e janelas de Double XP que criam compromisso de agenda.

### Recomendações

**R18 — Sorteio que garante dia jogável.** (P0, P) Filtrar o pool pela
permissão na hora do sorteio (mantendo a semente determinística): sem acesso
ao uso, sortear só entre as 7 executáveis. A missão-convite pode continuar
aparecendo, mas **além** das 3 jogáveis, não no lugar delas.

**R19 — Dificuldade progressiva.** (P2, M) Dois ou três degraus por definição
(ex.: `meia_hora` → 30/45/60 min conforme a média de minutos do usuário na
semana), com recompensa proporcional. O histórico necessário já existe
(`sessions`, 80 registros).

**R20 — Desafio mensal com selo.** (P1, M) "Setembro: 20 dias presentes" com
um selo colecionável (folha/flor do mês) exibido na trilha ou no perfil do
pet. É o análogo do badge mensal do Duolingo, barato de fazer com os
`CustomPainter` existentes, e dá objetivo de médio prazo entre a trilha (67
dias) e o dia a dia.

**R21 — Sequência de missões.** (P2, P) Meta-contador leve: "3 dias seguidos
colhendo tudo" → bônus de folhas. Cria um mini-streak dentro das missões sem
tocar na raiz.

---

## 5. Trilha, XP e o fim do conteúdo

### O que existe hoje (fatos)

- Trilha em corrente de 22 marcos, ~67 dias de uso engajado até o fim
  (estimativa no próprio código — `progressao.dart:300-301`), entregando 6
  habitats e 5 espécies; visual bom (nós, "VOCÊ ESTÁ AQUI", halo pulsante,
  ampulheta para critério batido fora da vez).
- Nível máximo 40 (~393 dias a ~70 XP/dia); depois, barra cheia e "Nível
  máximo" (`progressao.dart:86-99`).
- **Ao completar: nada.** "Trilha inteira percorrida", nós verdes, sem
  prestígio, temporada, trilha 2 ou conteúdo novo. Loja completa em ~28–38
  dias engajados (31 itens, 5.510 folhas; só os marcos pagam 63% disso).
- Marcos não são compartilháveis; a conquista de marco não mostra prévia do
  que vem depois.

### O que o Duolingo faz (D5/D6)

O conteúdo nunca acaba de verdade: a liga reseta semana a semana (escada
infinita), badges mensais renovam, e o path é longo o bastante para anos. O
usuário sempre tem um "próximo" em três horizontes: hoje (missões), esta
semana (liga), este mês (badge).

### Recomendações

**R22 — Horizonte pós-trilha antes do lançamento público.** (P2, G) O usuário
retido é exatamente o que alcança o fim. Opções em ordem de custo: (a)
desafios mensais (R20) como horizonte renovável; (b) "estações" da trilha —
blocos de 8–10 marcos adicionados por atualização; (c) prestígio do habitat
(níveis visuais extras do cenário já conquistado — o `estagioDoHabitat` e a
promessa de "companheiros visitantes" do backlog C-03 apontam para isso).

**R23 — Marco compartilhável.** (P2, P) A celebração de marco (toca + nome do
marco) ganha botão de share reutilizando o motor do `CartaoDaRaiz` ("Passo 11
· Uma semana inteira · construído com Baru").

**R24 — Prévia do próximo capítulo.** (P2, P) Ao conquistar marco com
habitat/espécie, a celebração mostra a miniatura do **próximo** desbloqueio
grande ("No passo 13: a Serra, e um axolote te espera") — o `MiniaturaDoHabitat`
já existe. Antecipação é metade do engajamento do Clash Royale que o roadmap
cita.

---

## 6. Economia de folhas — falta sumidouro

### O que existe hoje (fatos)

- Entradas por todo lado (sessões, bônus de meta, missões, descanso, marcos,
  winback) — ~145–197 folhas/dia para o engajado. Saída **única**: compra de
  item, sem recompra, sem consumível, sem qualquer outro débito
  (`state.dart:1721-1730`). Regra de teste: "o usuário nunca perde folhas"
  (`test/economy_test.dart:8-10`).
- Catálogo de 31 itens / 5.510 folhas esgota em ~28 dias engajados; depois o
  saldo cresce sem destino e a home diz "Habitat completo".
- Bug menor: `Carteira.proximoItem` devolve o primeiro do catálogo, não o mais
  barato; `AppState.nextItem` ordena por preço — home e tela de folhas podem
  apontar alvos diferentes (`lib/data/carteira.dart:134-139` vs
  `state.dart:1030-1034`).

### O que o Duolingo faz (D7)

Gems circulam: freezes (o sumidouro âncora), cosméticos do Duo, boosts,
retries. O saldo é sempre um pouco menor que o desejo.

### Recomendações

**R25 — Sumidouros alinhados à marca.** (P1, M) Em ordem de aderência:
1. **Congelamento extra** (R15) — proteção, recorrente, barato de implementar;
2. **Reparo de raiz** (R17) — caro e raro;
3. **Consumível de sessão**: "chá do foco" que dobra as folhas da próxima
   sessão (compromisso antecipado, mecânica de *pre-commitment* que combina
   com um app de foco);
4. **Itens sazonais rotativos** — a coleção "Estações" já existe
   (`models.dart` — cerejeira, neve, folhas de outono): vender por janela
   ("a cerejeira floresce só em setembro") cria demanda recorrente sem tirar
   nada de ninguém (item comprado é para sempre, some da vitrine, não do
   habitat).
5. Futuro social (SC-04 do roadmap): **presentear ervas** a amigos — sumidouro
   + laço social num só sistema.

**R26 — Corrigir o alvo da carteira** (P0, P): `proximoItem` ordenar por preço
como `nextItem`, uma fonte só.

---

## 7. Notificações e re-engajamento

### O que existe hoje (fatos)

O plano é sofisticado — teto de 2/dia com 3h de distância, horário aprendido
do hábito (histograma de 21 dias com peso por recência), aviso de raiz
agendado para hoje **e** amanhã (`descanso_retencao.dart:306-364`,
`notification_service.dart:740-775`) — mas a execução tem furos:

- **Textos 100% fixos**: um template por tipo, sem variação — a mesma frase
  todo dia às 21h habitua e morre (`l10n.dart:1027-1032`, `l10n_descanso.dart:31-39`).
- **"Senti sua falta" só dispara com o app aberto** — `_plugin.show` imediato
  chamado apenas em fluxos de app em execução: a notificação de ausência **só
  chega a quem já voltou** (`notification_service.dart:839-846,926-945`).
- **Nenhuma notificação tem payload/deep link** — o "Relatório da noite" abre
  o app na última tela, não no relatório (`notification_service.dart:214-216`);
  os deep links `baru://` existem e só o widget usa.
- **Sem quiet hours**: o lembrete do descanso herda a hora do hábito — hábito
  às 2h da manhã = notificação diária às 2h (`descanso_retencao.dart:347`).
- Sobreposição: o "+5 min" só esconde o balão (não adia nada —
  `OverlayDoBaru.kt:109`); "Fechar o app" manda para a home sem fechar nada;
  a promessa de "4×/dia com 25 min de intervalo" dos Ajustes só vale para um
  dos dois caminhos — durante sessão o vigia pode aparecer a cada 60s, até
  ~25 vezes numa sessão de 25 min (`VigiaDaSessao.kt:194,357-371` vs
  `overlay_service.dart:35-38`); e a sobreposição "fora de sessão" é disparada
  no `resumed`, ou seja, **desenhada por cima do próprio Baru**
  (`state.dart:1267-1279`, `app.dart:156-162`).

### O que o Duolingo faz (D4)

Dezenas de templates com bandit escolhendo o que funciona por usuário; persona
forte; horário = hora habitual; deep link direto para a lição; e desligamento
automático do que não performa.

### Recomendações

**R27 — Pools de variantes por tipo.** (P1, P/M) 4–6 frases por notificação,
rotacionadas de forma determinística (dia % n, como as sobreposições já fazem
— `state.dart:1267-1279`). A voz do pet já é forte; usá-la ("O Baru guardou
seu lugar na beira da lagoa"). Bandit pode esperar; variação não.

**R28 — Agendar a saudade de verdade.** (P0, P) Trocar o `show` imediato por
`zonedSchedule` na saída do app (agendada para D+2 na hora do hábito,
cancelada quando o usuário volta) — é a notificação de winback, ela precisa
alcançar quem *não* abre.

**R29 — Deep link em toda notificação.** (P0, P) `payload` → tela certa:
relatório da noite → `/report`; raiz em risco → home com o CTA de foco em
evidência; descanso → `/missoes`. A infra `baru://` já existe.

**R30 — Quiet hours e consertos da sobreposição.** (P1, P/M) Clamp de horário
(8h–22h) para tudo que não é raiz; "+5 min" silencia o vigia por 5 min de
verdade; unificar o teto de frequência dos dois caminhos (o cooldown de 60s
durante sessão é defensável como mecânica, mas então os Ajustes precisam
dizer isso); não disparar a sobreposição de fora de sessão quando o app em
primeiro plano é o próprio Baru.

**R31 — "Última chamada" opcional.** (P2, P) Duolingo avisa ~1h antes da
meia-noite. O Baru já tem o slot "amanhã"; adicionar variante às 23h para
raízes ≥7 dias (as que doem perder), como opt-in.

---

## 8. Social e viralidade — o multiplicador ausente

Estado: **zero mecânica social** (grep confirmou; Supabase só autentica e
sincroniza a própria conta). O roadmap declara social "para depois"
(SC-01..04) — decisão razoável para MVP, mas vale registrar que é a alavanca
com maior efeito documentado no Duolingo (ligas e Friend Streak são os
maiores drivers de sessões/dia que eles já publicaram).

O único vetor atual é o share de imagem (habitat na tela de resultado; cartão
da raiz na sequência) — unidirecional e sem loop de retorno. E o share do
habitat dispara a folha nativa sozinho 80ms após abrir, antes de o usuário
ver o que vai enviar (`share_sheet.dart:26-31`), com uma nota interna de fase
visível ("A fase 1 compartilha um screenshot" — `l10n.dart:1046-1047`).

### Recomendações

**R32 — Arrumar o share existente.** (P0, P) Pré-visualização antes de
disparar a folha nativa; remover a nota de desenvolvimento; oferecer o share
nos picos emocionais (marco de raiz — R13, marco de trilha — R23), não só no
resultado.

**R33 — Social fase 1: presença, não competição.** (P2, G) Quando chegar a
hora, o caminho coerente com a marca não é liga de 30 estranhos: é o **Friend
Streak** — "raízes entrelaçadas": você e um amigo mantêm presença juntos, e o
cartão mostra as duas raízes. Cooperativo, sem ranking, dobra a pressão
positiva de voltar. SC-04 (enviar ervas) encaixa como presente + sumidouro.

**R34 — Convite com recompensa.** (P2, M) "Plante uma raiz com um amigo" —
convite que dá folhas/item exclusivo aos dois quando o convidado completa a
primeira sessão. Loop viral básico que o cartão da raiz já alimenta.

---

## 9. Relatórios e sensação de progresso de longo prazo

Hoje tudo é **o dia corrente**: relatório do dia, tempo de tela por categoria
e por app (excelente granularidade — reclassificação por toque incluída), 7
pontinhos da semana. **Não existe tendência**: nada de semana × semana, média
móvel, melhor dia, ou gráfico — as 80 sessões guardadas nunca são lidas para
visualização (backlog C-07 já aponta). E `repDate` é uma string hardcoded
"Terça, 26 de agosto" nos 4 catálogos (`l10n.dart:962`,
`report_screen.dart:46`) — o relatório de hoje exibe uma data errada.

O Duolingo mostra progresso semanal, recordes e comparações a cada fim de
lição — a sensação de trajetória é parte da recompensa.

**R35 — (P0, P) Corrigir `repDate`** com `formatLongDate` (já usado em
`conta_screen.dart:98`).

**R36 — (P1, M) Semana real no relatório**: barras dos 7 dias (minutos
contados × meta) a partir do histórico de sessões + snapshots diários;
"melhor semana", "recorde de foco num dia". É o C-07 do backlog com cara de
produto.

**R37 — (P2, M) Resumo semanal como cena**: domingo à noite, um cartão "Sua
semana com o Baru" (sessões, dias abaixo da meta, raiz, item comprado) —
compartilhável. O análogo leve do recap que o Duolingo faz anual.

---

## 10. Acessibilidade e polimento transversal

- `textScaler` travado em 1.25× (backlog C-09) — limite real de acessibilidade.
- "Reduzir movimento" já respeitado no halo da trilha — estender à cadeia de
  celebração da R8.
- Feedback de toque inexistente nos componentes de `common.dart` (R7) também é
  questão de acessibilidade (confirmação não-visual).
- iOS: sem Screen Time (BL-06), o humor deriva só de sessões — o caminho está
  contratado como suportado, mas o paywall/onboarding deve esconder promessas
  de medição no iOS até o entitlement existir.

---

## 11. Defeitos pontuais encontrados na varredura (consertar já)

| # | Defeito | Onde | Efeito no usuário |
|---|---|---|---|
| B1 | `repDate` hardcoded "Terça, 26 de agosto" | `l10n.dart:962`, `report_screen.dart:46` | Relatório de hoje com data errada, nos 4 idiomas |
| B2 | Quiz: `fatorDaMeta` compara `'companhia'`, id real é `'so_companhia'` | `lib/data/quiz.dart:131,185` | Quem vem "só por companhia" não recebe a meta 0,88 — cai no default |
| B3 | "+5 min" da sobreposição só esconde o balão | `OverlayDoBaru.kt:109` | Botão mente; o vigia volta em 60s |
| B4 | "Senti sua falta" só dispara com app aberto | `notification_service.dart:839-846` | Notificação de winback nunca alcança quem sumiu |
| B5 | Sobreposição fora de sessão desenhada sobre o próprio Baru | `state.dart:1267-1279` + `app.dart:156-162` | Balão "volte do TikTok" aparece dentro do Baru |
| B6 | Chip "Livre" = 45 min fixo, e paga menos que o de 50 | `home_screen.dart:280`, `models.dart:102` | Rótulo enganoso + incentivo invertido |
| B7 | Frequência da sobreposição diverge da promessa dos Ajustes | `VigiaDaSessao.kt:194` vs `l10n.dart:663` | Até ~25 aparições numa sessão de 25 min |
| B8 | `proximoItem` ≠ `nextItem` (ordem de catálogo vs preço) | `carteira.dart:134-139` vs `state.dart:1030-1034` | Home e tela de folhas apontam alvos diferentes |
| B9 | Notificação "Sessão concluída" dispara com o app aberto | `state.dart:1842-1849` | Anúncio duplicado com a tela de resultado |
| B10 | Celebração pode cobrir a sessão de foco e o resultado | `app.dart:295-315` | Véu opaco sobre o cronômetro / sobre o "+folhas" |
| B11 | Toggle "Senti sua falta": religar no mesmo dia não reabilita | `notification_service.dart:926-944` | Preferência parece não funcionar |
| B12 | CTA do passo 1 usa a chave `start` ("Começar foco") mas abre o quiz | `onboarding_screen.dart:60` | Expectativa quebrada no 2º toque do app |
| B13 | `anunciaCelebracao()` sem chamadores | `state.dart:218-220` | Código morto no caminho de som |
| B14 | SnackBar de erro cobre a tela de foco recém-aberta | `state.dart:1806-1808` | Primeira sessão pode começar com mensagem de erro |

---

## 12. Priorização consolidada

**P0 — uma semana de correções, efeito imediato** (todas P/M):
B1–B14 da tabela acima + R4 (saída do paywall) + R5 (locale) + R7 (háptico nos
botões) + R18 (sorteio jogável) + R26/R35 + R28/R29 (saudade agendada + deep
links) + R32 (share com prévia).

**P1 — o salto de percepção (2–4 semanas):**
- R8 cadeia de celebração no resultado (o maior retorno por esforço do
  relatório inteiro);
- R2+R3 primeira sessão guiada + revelação celebrada;
- R9 CTA fixo na home;
- R13+R14+R15 raiz: marcos celebrados, risco visível no app, freeze visível;
- R11 pet vivo nos humores bons;
- R20 desafio mensal;
- R25 primeiros sumidouros (freeze extra, itens sazonais);
- R27+R30 variantes de notificação + quiet hours;
- R36 semana real no relatório.

**P2 — estratégico (pós-lançamento):**
- R1 conta depois do valor (a maior alavanca de conversão do funil, mas exige
  auth anônima + fluxo de upgrade);
- R6 permissões contextuais;
- R16/R17 política de presença + reparo de raiz;
- R19/R21/R22/R23/R24 dificuldade progressiva, horizonte pós-trilha, marcos
  compartilháveis;
- R31 última chamada;
- R33/R34 social fase 1 (raízes entrelaçadas, convite);
- R37 resumo semanal.

### Métricas para validar (instrumentar antes de mexer)

- Funil de onboarding por passo (hoje: onde os ~15 toques sangram);
- TTV: tempo até a 1ª sessão concluída (alvo pós-R2: < 10 min do install);
- D1/D7/D30; sessões de foco por DAU; % de dias com missão colhida;
- Distribuição de tamanho de raiz e taxa de quebra (antes/depois de R13–R15);
- Opt-in de cada permissão por posição do pedido (R6);
- CTR por variante de notificação (R27).

---

## 13. O que **não** copiar do Duolingo

Para fechar: a identidade do Baru é o ativo. Não importar — corações/vidas
(punição direta, viola a regra 1 do PRODUCT.md); ligas competitivas de
estranhos (ansiedade, oposto de "habitat"); paywall a cada lição; culpa como
humor de notificação (o "passivo-agressivo" do Duo funciona para eles, mas o
Baru promete "sem culpa" — a variação de copy da R27 deve vir da persona
calorosa do pet, não do meme). O objetivo é a *densidade de sentimento* do
Duolingo com o *tom* do Baru — os agentes de celebração, som e háptico já
estão no código; falta apontá-los para os momentos certos.

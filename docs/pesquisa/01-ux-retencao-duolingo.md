# Laudo 01 — Experiência do usuário, retenção diária e o modelo do Duolingo

Data: 2026-10-26. Escopo: ofensiva (raiz), cadeia de celebração, coleta de
recompensas, missões, notificações de lembrete, jornada de ponta a ponta e a
psicologia por trás, aplicados ao Baru. Complementa e atualiza
[`docs/RELATORIO_UX_DUOLINGO.md`](../RELATORIO_UX_DUOLINGO.md) (agosto). Não
repete as recomendações R1–R37 de lá: cita pelo número quando elas continuam
valendo e corrige o que a pesquisa nova desmente.

**Método.** (1) Leitura do código atual em `baru_app/lib` nos pontos do tema;
(2) leitura das capturas em `play-store/telas/pt/` (01-home, 02-sessao,
03-trilha, 04-missoes, 08-sequencia, 09-ajustes, 10-folhas); (3) pesquisa web
em fontes primárias do Duolingo (blog, paper do KDD, falas de resultado
trimestral), documentação Android/Flutter e literatura acadêmica sobre hábito,
sequências, metas e notificações.

**Legenda usada em todo o laudo.**

- **[F]** fato com fonte (link na própria linha ou na seção 14);
- **[F2]** fato de fonte secundária (análise de terceiros, imprensa) — usar
  com cautela;
- **[O]** observação do app, com `arquivo:linha` ou nome da captura;
- **[I]** inferência ou opinião minha.

Números de efeito (retenção, DAU etc.) aparecem só com fonte. Onde não achei
fonte, digo que não achei.

---

## 1. Sumário executivo

1. **Quase nada do loop de recompensa mudou desde agosto.** [O] A tela de
   resultado continua estática (`lib/screens/result_screen.dart`, 107 linhas,
   sem animação, sem XP, sem raiz); o botão "Começar foco" continua abaixo
   da dobra (captura `01-home.png`: não aparece na tela inicial); os marcos
   da raiz não disparam celebração (`lib/app.dart:316-349` só celebra nível,
   marco de trilha e chegada); os textos de notificação continuam fixos
   (`lib/l10n_descanso.dart:31-39`, `lib/l10n.dart:1027-1030`). As
   recomendações R8, R9, R13, R14, R27, R28 e R29 de agosto seguem abertas.
2. **O momento "minha raiz cresceu hoje" não existe na tela.** [O] Depois da
   primeira sessão do dia, a raiz soma +1 em silêncio
   (`lib/state.dart:1908-1912`) e o ponto de hoje na faixa da semana **continua
   como "hoje" (anel), não como "presente" (✓), até a meia-noite**
   (`state.dart:2086` só marca presente ao virar o dia;
   `screens/sequencia_screen.dart:237`, `screens/home_screen.dart:327`). A
   pessoa faz o que o app pede e não vê nada mudar. No Duolingo esse é o
   momento mais coreografado do dia [F2].
3. **A raiz cobra a ação mais cara do app.** [O] O menor foco possível é de
   25 min (`lib/models.dart:102`) e só foco conta presença
   (`state.dart:1908`); o descanso — que a própria tela de Missões chama de
   "A principal de hoje" (`04-missoes.png`) — não segura a raiz. O aviso de
   risco promete "Uma sessão curta segura" (`l10n_descanso.dart:34`), mas não
   existe sessão curta. [F] O Duolingo mediu o efeito de baixar a barra: deixar
   **uma lição** estender a ofensiva (em vez da meta diária inteira) deu
   +3,3% de retenção no D14 e, um ano depois, +40% de pessoas em ofensiva de
   7+ dias ([blog Duolingo](https://blog.duolingo.com/improving-the-streak/)).
4. **Quebrar a raiz hoje é o oposto de "sem punição".** [O] Sem
   congelamento, `streak = 0` na virada (`state.dart:2095`) e a raiz vira
   semente, sem cena e sem caminho de volta. [F] A pesquisa mostra que
   sequência quebrada derruba o engajamento seguinte, e que o efeito é menor
   quando a quebra **pode ser reparada** (Silverman & Barasch, *JCR* 2023). [F]
   O próprio Duolingo, em junho de 2026, deixou quem perdeu uma ofensiva
   longa recuperá-la **completando 3 lições**, sem pagar: mais de 15 milhões
   de pessoas recuperaram ([Android Authority](https://www.androidauthority.com/p-3673004/);
   [resumo da teleconferência do 2º tri/2026](https://longbridge.com/news/295028818.md)).
   Proponho o **"replantio por esforço"** (seção 4.4), que supera a R17 de
   agosto (reparo pago em folhas).
5. **As notificações têm defeitos que fazem o app mentir.** [O/I] O aviso de
   raiz em risco é recalculado só quando o app abre ou volta do segundo plano
   (`app.dart:162`, `state.dart:1268`), não ao concluir a sessão
   (`state.dart:1897-1937`): quem concluiu o foco e fechou o app ainda pode
   receber "Sua raiz quebra à meia-noite" às 21h. O lembrete "de amanhã" usa
   o texto de hoje e é **cancelado** para quem já esteve presente
   (`services/notification_service.dart:740-775`), então justamente a pessoa
   que esquece de abrir no dia seguinte fica sem aviso de raiz. E os cinco
   tipos de lembrete dividem um só canal (`notification_service.dart:249-256`),
   contra a orientação do Android de um canal por tipo [F].
6. **Baru não é o Duolingo: o objetivo é a pessoa largar o telefone.** [F] A
   pesquisa sobre notificações aponta custo real de atenção (Kushlev et al.,
   CHI 2016) e benefício em recebê-las em lotes previsíveis (Fitz et al.,
   2019). [I] Por isso o calendário proposto (seção 7) é **mais enxuto** que
   o do Duolingo: no dia em que a raiz já cresceu, o Baru não manda nada; e a
   sequência de fim de sessão termina em **"dia feito, pode largar o
   telefone"**, não em "mais uma lição".

---

## 2. O que mudou desde agosto (status das recomendações do tema)

| Rec. de agosto | Status hoje | Evidência |
|---|---|---|
| R8 cadeia de celebração no resultado | **Aberta** | [O] `result_screen.dart` — `PetView` + chip de folhas + 2 stats estáticos; nenhum controlador de animação |
| R9 CTA fixo na home | **Aberta** | [O] `01-home.png`: a dobra termina no cartão "1h 36min de 2h 30min"; o CTA não aparece |
| R13 marcos de raiz celebrados | **Aberta** | [O] `app.dart:316-349` |
| R14 risco da raiz visível no app | **Aberta** | [O] `home_screen.dart` não lê `avaliaRaizEmRisco` |
| R15 congelamento visível | **Parcial** | [O] `08-sequencia.png` mostra "Congelamentos 1 — volta a cada segunda"; não há cena de "raiz salva" |
| R16 o que conta presença | **Aberta** e agora mais grave (achado 3) | [O] `state.dart:1908` |
| R17 reparo de raiz | **Substituída** pela U5 (replantio por esforço) | ver 4.4 |
| R20 desafio mensal | **Aberta** | [O] `missoes.dart` só tem diárias e semanais |
| R27 variantes de notificação | **Aberta** | [O] `l10n_descanso.dart:31-39` |
| R28 saudade agendada | **Aberta** | [O] `notification_service.dart:926-945` ainda usa `_plugin.show` imediato |
| R29 deep link | **Aberta** | [O] nenhum `payload` em `notification_service.dart` |
| R31 última chamada | **Aberta** | — |

Correção ao relatório de agosto: lá se disse que no Duolingo o "streak saved
by freeze" é uma cena. [F2] A análise da Deconstructor of Fun descreve o
contrário: o congelamento é aplicado **em silêncio**, e a pessoa só vê um
floco de neve no dia faltado ao abrir o app
([teardown](https://duolingo.deconstructoroffun.com/mechanics/streaks)). Não
achei fonte primária. A recomendação de mostrar a cena no Baru continua de pé,
mas como escolha nossa, não como cópia.

---

## 3. Achados novos no app (observação)

| # | Achado | Onde | Efeito |
|---|---|---|---|
| A1 | Hoje nunca vira "presente" na faixa antes da meia-noite | `state.dart:2086`; `sequencia_screen.dart:237`; `home_screen.dart:327` | A ação do dia não tem eco visual |
| A2 | Mesma informação, códigos de cor opostos: na home, anel **laranja** = congelado e anel verde = hoje; na tela da raiz, anel **laranja** = hoje e floco cinza = congelado | `home_screen.dart:318-335` × `sequencia_screen.dart:235-238`; capturas 01 e 08 | Quem aprende a ler uma tela erra na outra |
| A3 | A segunda-feira apaga a semana: "Raiz de 4 dias" com um único ponto na faixa | `state.dart:2100-2103`; `01-home.png`, `08-sequencia.png` | A raiz parece mentir; os 3 dias anteriores somem |
| A4 | "Uma sessão curta segura", mas a sessão mínima é 25 min | `l10n_descanso.dart:34` × `models.dart:102` | Promessa que o produto não cumpre |
| A5 | O aviso de risco pode tocar depois de a pessoa já ter cumprido o dia | sincronização só em `app.dart:162`/`state.dart:1268`; `_concluiSessao` não ressincroniza (`state.dart:1897-1937`) | Notificação falsa de perda — a pior possível num app "sem culpa". **Verificar em aparelho** |
| A6 | O slot "amanhã" leva o texto de hoje e some para quem esteve presente | `notification_service.dart:740-775` + `state.dart:1405-1409` | Sem aviso para quem esquece de abrir no dia seguinte; número de dias errado se o congelamento entrar |
| A7 | Um canal (`baru_reminders`) para raiz, descanso, relatório, saudade e teste | `notification_service.dart:249-256, 801, 879, 915, 936` | Quem silencia um tipo no sistema silencia todos |
| A8 | A "principal de hoje" (descanso) não conta para a raiz | `04-missoes.png`; `state.dart:1908` | Hierarquia contraditória entre Missões e Raiz |
| A9 | A saudação diária usa o som de **conquista**, véu escuro e o texto "{a} passou o dia esperando por isso" | `celebracao.dart:85-99`; `app.dart:330-334`; `l10n.dart:718-719` | Banaliza o som de conquista e põe uma ponta de culpa na abertura |
| A10 | Colher missões: 3 gestos de cavar **por missão**, numa folha modal por vez; aba Missões sem indicador do que há para colher; progresso de missão não aparece no fim da sessão | `toca.dart:47`; `missoes_screen.dart:650-700`; `result_screen.dart` | Recompensa pronta fica parada; a coleta vira trabalho no 3º dia |
| A11 | Instrução "Toque em **Focar**", mas o botão diz "Começar foco"; e "fique com o **Baru**" mesmo quando o pet é outro | `l10n.dart:748` × `l10n.dart:765` | Ruído de clareza |
| A12 | A raiz desenhada aos 4 dias é um traço fino num quadrado de cor diferente do cartão | `08-sequencia.png` | O símbolo-bandeira lê como um graveto; não dá orgulho |
| A13 | Ajustes: o desenho do pet invade o texto "Você é uma capivara." | `09-ajustes.png` | Polimento |
| A14 | Um só `AudioPlayer` para todos os sons, e nenhum som próprio de raiz | `som_service.dart:70`; `assets/sons/` (7 arquivos) | Sem voz sonora para a ofensiva; dois sons seguidos se cortam |

---

## 4. A ofensiva do Duolingo em detalhe, e o que cabe na raiz

### 4.1 O que se sabe, por fonte

**Regra de extensão.**
- [F] Antes, só a meta diária completa estendia a ofensiva; passou a bastar
  **uma lição**. Resultados do teste A/B (relativos): +3,3% de retenção no
  D14; +1% de aprendizes ativos por dia; +10,5% de aprendizes diários em
  ofensiva em 20 dias; +19% entre novos. Efeito colateral: menos gente batendo
  a meta diária. Um ano depois, +40% de aprendizes em ofensiva de 7+ dias;
  "pouco mais da metade" dos aprendizes diários tinha ofensiva de 7+ dias,
  contra cerca de um terço antes. Quem chega a 7 dias tem 2,4× mais chance de
  voltar no dia seguinte ([improving the streak](https://blog.duolingo.com/improving-the-streak/)).
- [F2] A equipe relata 600+ experimentos de ofensiva, e que o compromisso
  ativo ("commit to my goal" em vez de "continue") melhorou retenção
  ([Lenny's Podcast, show notes](https://www.lennysnewsletter.com/p/behind-the-product-duolingo-streaks)).
  Detalhes dos experimentos não estão no texto público.

**Cena de extensão (o que acontece na tela).**
- [F2] Sequência pós-lição: XP ganho → pequena celebração → toque em
  "Continuar" → tela de incremento da ofensiva com chama em tela cheia e
  contador que sobe; dias de marco têm animação própria; a faixa da semana
  marca ✓ nos dias feitos e floco azul nos dias salvos por congelamento
  ([teardown](https://duolingo.deconstructoroffun.com/mechanics/streaks)).
- [F] Para os marcos, o Duo vira "Fire Duo" (fênix envolta em chamas), tratado
  "como um power-up de videogame"; a equipe fez várias passadas de animação
  bruta para acertar tempo e ritmo; há cartão de compartilhamento
  ([milestone design](https://blog.duolingo.com/streak-milestone-design-animation/)).
  A nova animação de marco aumentou em +1,7% a chance de um novato ainda usar
  o app 7 dias depois ([how the streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit/)).
- **Não achei** fonte que descreva a cena quadro a quadro com tempos, som ou
  háptico. O blog de marcos não menciona som nem vibração. Nenhuma fonte
  oficial confirma que a cena é feita em Rive; [F] o Duolingo usa Rive com
  máquina de estados para os personagens das lições ([world character
  visemes](https://blog.duolingo.com/world-character-visemes)). O storyboard
  da seção 5 é proposta minha, não engenharia reversa.

**Congelamento (Streak Freeze).**
- [F] Até **2 equipados**; reposição comprada com gemas (tela: "Refill streak
  freezes", 400 gemas). Permitir 2 em vez de 1 aumentou em +0,38% os
  aprendizes ativos diários e **não** fez as pessoas tirarem mais folgas
  ([how the streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit/)).
  O mesmo texto cita estudo da Penn/UCLA de que folga planejada motiva mais
  que regra rígida — é o trabalho de Sharif & Shu (seção 8).
- [F2] Congelamentos também caem de baús, missões e marcos; teto sobe para 5 na
  Streak Society; aplicação é silenciosa ([teardown](https://duolingo.deconstructoroffun.com/mechanics/streaks)).

**Reparo / recuperação.**
- [F2] Reparo pago com gemas existe ([Android Authority](https://www.androidauthority.com/p-3673004/));
  o catálogo Deceptive Design lista o reparo pago no "Hall of Shame"
  ([deceptive.design](https://www.deceptive.design/articles/when-a-user-uses-duolingo-on-a-series-of-consecutive-days-this-is-called-a-streak-if-users-miss-a-day-they-can-pay-to-repair-it)).
- [F2] Em junho de 2026, evento único: quem perdeu ofensiva de 30+ dias podia
  recuperá-la **fazendo 3 lições seguidas**, sem gemas
  ([Android Authority](https://www.androidauthority.com/p-3673004/)).
  Na teleconferência do 2º tri/2026 a empresa disse que mais de 15 milhões de
  pessoas recuperaram e que esse grupo "retém melhor que uma coorte típica de
  reengajamento", e atribuiu parte do crescimento de DAU (+23% a/a) ao evento
  ([resumo](https://longbridge.com/news/295028818.md)). Não consegui abrir a
  carta aos acionistas (403); os números vêm do resumo da teleconferência.

**Marcos, Streak Society, calendário, Perfect Streak.**
- [F] Marcos citados: 1 semana, 1 mês, 100 dias, 1 ano; a Streak Society é
  "uma associação exclusiva" para quem bate marcos
  ([streak celebration parties](https://blog.duolingo.com/streak-celebration-parties/)).
  Vantagens concretas: **não achei** fonte oficial; [F2] fontes de fãs
  divergem (congelamentos extras, ícone do app, status no placar).
- [F2] "Perfect Streak": dias sem usar congelamento; a faixa da semana vira
  uma barra laranja contínua e a chama ganha halo
  ([teardown](https://duolingo.deconstructoroffun.com/mechanics/streaks)).

**Comunicação de risco.**
- [F] A linguagem é de aversão à perda: "Protect your 3 day streak!" junto
  da oferta de congelamento ([how the streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit/)).
- [F] No widget, o Duo fica "cada vez mais desesperado conforme a
  meia-noite se aproxima"; metade de quem instalou o widget tem ofensiva de
  pelo menos 6 meses; a equipe afirma retenção melhor mesmo controlando pelo
  fato de esses usuários já serem mais engajados
  ([widget feature](https://blog.duolingo.com/widget-feature/)).

**Ofensiva com amigos.**
- [F] Quem tem pelo menos uma Friend Streak tem 22% mais chance de completar a
  lição do dia; teto de 5 amigos; o maior gargalo do funil é mandar o
  primeiro convite; o desenho dispensa interação entre os dois, "como estudar
  lado a lado numa biblioteca" ([product lessons](https://blog.duolingo.com/product-lessons-friend-streak/)).
  O texto não diz se o 22% vem de teste randomizado.

### 4.2 O que disso cabe na raiz sem violar "sem punição"

| Mecânica do Duolingo | Cabe no Baru? | Como, no Baru |
|---|---|---|
| Barra mínima para estender (1 lição) | **Sim, prioritário** | Raiz cresce com **foco de 10 min** ou **descanso cumprido** (U3). Exige ADR (regra de presença e opção de duração) |
| Cena de extensão diária | **Sim** | "Raiz cresceu hoje" (seção 5), a cada primeira presença do dia |
| Animação especial em marcos | **Sim** | Galho novo + transformação do pet + cartão de compartilhar (U2) |
| Congelamento equipável, até 2 | **Sim** | 1 grátis por semana (já existe) + até 1 guardado extra; ganho por missão semanal/mensal, nunca só por dinheiro (U6) |
| Reparo pago em gemas | **Não** | Pagar para desfazer uma perda é o padrão criticado no Deceptive Design; e "perda de moeda" para evitar perda fere o espírito da regra 1 |
| Recuperar por esforço (3 lições) | **Sim, e melhor** | "Replantio": 3 focos em até 3 dias trazem a raiz de volta (U5) |
| Widget com humor do personagem | **Sim, com o tom invertido** | O widget do Baru já existe; o pet fica **mais sonolento/aconchegado**, nunca "desesperado" (U9) |
| "Protect your streak" (aversão à perda) | **Parcial** | Dizer o fato e a ação, sem drama: "Sua raiz de 9 dias ainda pode crescer hoje. 10 min bastam." |
| Perfect Streak | **Não por agora** | Cria uma segunda régua de culpa ("usou congelamento = imperfeito") |
| Streak Society | **Sim, como coleção** | "Bosque": marcos 30/100/365 viram árvore permanente no habitat — nunca removida (U8) |
| Friend Streak | **Sim, futuro** | "Raízes entrelaçadas" (R33 de agosto) — cooperativo, sem placar |
| Duo "desesperado"/passivo-agressivo | **Não** | Viola a regra "nunca culpa" |

### 4.3 Comunicar risco sem culpar — regras de texto

[I] Derivadas do contrato (`docs/PRODUCT.md` §1) e da pesquisa da seção 8:

1. **Fato + ação mínima + tempo.** "Sua raiz de 9 dias pode crescer hoje.
   Um foco de 10 min basta." Nada de "você vai perder".
2. **O pet nunca sofre por causa da pessoa.** Ele convida, guarda, mostra,
   conta. Não espera "o dia todo", não fica triste, não "sente falta" como
   cobrança. (Isso pede revisar `celebChegadaSub` e `notifMissedBody` —
   achado A9.)
3. **Atribuição externa quando a raiz para.** [F] Silverman & Barasch acharam
   que o efeito negativo da quebra é maior quando a pessoa culpa a si mesma.
   Texto: "Dias corridos acontecem." e nunca "você esqueceu".
4. **Sempre mostrar o caminho de volta** junto da notícia (replantio).
5. **Palavras proibidas em pt** (equivalentes nos 4 idiomas): perdeu,
   abandonou, esqueceu, decepcionado, triste por você, última chance, morreu,
   murchou.

### 4.4 Proposta de regras da raiz (versão 2)

[I] Exige ADR e atualização de `docs/PRODUCT.md` §7.

| Situação | Hoje | Proposta |
|---|---|---|
| O que conta presença | Só foco concluído | Foco concluído de **≥10 min** **ou** descanso cumprido |
| Dia faltado com congelamento | Absorve, +1 na raiz | Igual, e a próxima abertura mostra a cena "o congelamento segurou" (5.3) |
| Dia faltado sem congelamento | `streak = 0` | Raiz **adormece** por 3 dias: desenho intacto, com uma lua pequena; contagem congelada |
| Volta dentro dos 3 dias | — | **Replantio**: 3 focos (qualquer duração ≥10 min) em até 3 dias acordam a raiz com a contagem anterior, e o dia de hoje soma |
| Passaram os 3 dias | — | A raiz antiga vira **raiz guardada** (fica no "Bosque", com número e data — nunca apagada); uma nova nasce ao lado |
| Recorde | `melhorSequencia` | Igual, e o Bosque mostra todas |

Por que é coerente: não há decaimento nem perda — o que se construiu fica à
vista para sempre; e a regra dá folga planejada (Sharif & Shu) e reparo
(Silverman & Barasch), as duas coisas que a pesquisa associa a voltar depois
da falha.

---

## 5. Storyboard — cena "raiz cresceu hoje"

**Quando dispara.** Na primeira presença do dia (foco ≥10 min concluído ou
descanso cumprido), como etapa 2 da sequência de fim de sessão (seção 6). Se
a presença veio por um caminho sem tela de resultado (ex.: descanso concluído
com o app fechado), dispara na próxima abertura, antes da saudação.

**Princípios técnicos.** Durações seguem os tokens de movimento do Material 3
expostos no Flutter (`Durations.short1` = 50 ms … `extralong4` = 1000 ms
[F](https://api.flutter.dev/flutter/material/Durations-class.html)).
Háptico segue a orientação do Android: "menos é mais", força proporcional à
importância, sincronizado com som e imagem, e evitar vibração única longa —
um clique bom dura 10–20 ms [F](https://developer.android.com/develop/ui/views/haptics/haptics-principles).
Toque em qualquer lugar a partir de 600 ms pula para o quadro final. O total
fica em ~2,4 s.

**Composição da tela.** Corte transversal de terra ocupando ~60% da altura;
linha de grama no terço superior com o pet sentado; a `RaizViva` desce da
grama; à direita da raiz, o contador; abaixo, a faixa dos últimos 7 dias.

| Quadro | Tempo (ms) | Imagem | Som | Háptico |
|---|---|---|---|---|
| Q0 entrada | 0–400 | O painel de terra sobe da borda inferior (curva *emphasized decelerate*); o pet já está sentado na grama; contador mostra **N** em tinta neutra; a ponta da raiz está no fim do desenho de N dias | — | — |
| Q1 a gota | 400–750 | Uma gota de luz (folha-luz, cor `acento`) se forma sob as patas do pet (150 ms) e escorre pela raiz até a ponta (350 ms, *ease-in*), deixando um rastro que esmaece | "gota" curta, grave, ~120 ms, no fim da queda (700 ms) | — |
| Q2 o toque na ponta | 750 | A gota toca a ponta; pequeno clarão circular (raio 0→24 px, 150 ms) | "toc" de madeira, ~80 ms | 1 clique (`PRIMITIVE_CLICK` 0,6; fallback `HapticFeedback.lightImpact`) |
| Q3 crescimento | 750–1350 | A raiz alonga de L(N) para L(N+1) e engrossa o tronco na proporção do desenho; a terra em volta da ponta se desloca em 4–6 grãos | Arpejo ascendente de 3 notas (ex.: dó-mi-sol pentatônico), uma a cada 150 ms (850, 1000, 1150) | 3 ticks crescentes sincronizados com as notas (`PRIMITIVE_TICK` 0,3 / 0,5 / 0,7) |
| Q4 contador | 1150–1450 | O número rola de N para N+1 como odômetro (250 ms, *easeOutBack*); cor passa de tinta para `acento`; pulso de escala 1,0→1,15→1,0 | "plim" brilhante, ~200 ms, em 1200 | 1 batida firme em 1200 (`PRIMITIVE_THUD` ou `HapticFeedbackConstants.CONFIRM`; fallback `mediumImpact`) |
| Q5 o pet reage | 1200–1650 | Gesto de alegria **da espécie** (Baru dá um pulinho e espirra água; Nina abre as asas; Toco estica o pescoço ao sol; etc.); 6–8 folhinhas saem do chão na linha da grama (não confete) | o som de alegria da espécie, baixo, se existir | — |
| Q6 texto e semana | 1450–2000 | Entra o título "Raiz de N+1 dias" e uma linha que varia (abaixo); na faixa dos 7 dias, o ponto de hoje passa de anel para ✓ (escala 0→1,2→1, 300 ms) | — | 1 tick leve em 1750 (`selectionClick`) |
| Q7 descanso | 2000–2400 | Tudo para; o pet respira; o botão "Continuar" aparece (fade 200 ms) | — | — |

**Linha variável do Q6** (uma por vez, nesta prioridade):

1. recorde: "A mais funda que você já teve."
2. a 1–3 dias de um marco: "Faltam 2 dias para o galho da primeira semana."
   (efeito de meta próxima — seção 8);
3. primeiro dia depois de replantio: "Replantada. A raiz de 12 dias voltou a
   crescer.";
4. padrão (rotação de 5): "Mais funda que ontem." / "Ficou mais firme." /
   "Mais um dia na terra." / "Ela segura o hábito por você." / "Cresceu
   enquanto você estava longe da tela."

**Variante de marco (3, 7, 14, 30, 60, 100, 180, 365).** Entre Q4 e Q6 entra
um bloco de +900 ms: a raiz para, a terra treme (3 px), **um galho novo
brota** (500 ms) e sobe uma árvore-semente na grama; o pet ganha o adereço do
marco (tiara de folhas aos 7, etc.). Som `conquista`. Háptico: subida
(`PRIMITIVE_QUICK_RISE`) + batida (`PRIMITIVE_THUD`) — o único háptico forte
da raiz. O Q7 mostra dois botões: "Compartilhar minha raiz" (gera o
`CartaoDaRaiz` existente) e "Continuar".

**Variante "reduzir movimento".** `MediaQuery.disableAnimations` (ou a
amplitude de `Movimento.amplitude` já usada em `celebracao.dart`):
crossfade de 200 ms para o quadro final, um som (`plim`), um háptico (`CONFIRM`).

**Variante sem som/sem vibração.** Respeita o interruptor "Som" dos Ajustes e
o modo silencioso; háptico respeita a configuração do sistema
(`View.performHapticFeedback`) e um novo interruptor "Vibração".

**Como fazer em Flutter.**
- Um `AnimationController` de 2400 ms com `Interval`s por quadro
  (`CurvedAnimation(parent: c, curve: Interval(0.31, 0.56, curve: ...))`).
- `RaizViva` passa a aceitar `double dias` (ou um `crescimento` 0–1) e
  desenha o último segmento com `PathMetric.extractPath(0, comprimento * t)`.
  A forma continua determinística (a semente é o inteiro).
- Odômetro: `TweenAnimationBuilder<double>` por dígito com `ClipRect` +
  `Transform.translate`.
- Sons e hápticos disparados por limiares do controlador (listener que
  compara `valorAnterior < limiar <= valorAtual`), não por `Future.delayed` —
  assim pular a cena não deixa som atrasado tocando.
- Háptico rico: `MethodChannel('baru/haptica')` → Kotlin
  `VibrationEffect.startComposition().addPrimitive(...)` (API 30+), checando
  `Vibrator.areAllPrimitivesSupported`; senão, `HapticFeedback.*`.
- Som: pré-carregar os arquivos e usar 2 vozes (o `SomService` atual tem um
  player só — `som_service.dart:70`), para o "plim" não cortar o fim do arpejo.

**Critério de aceite.** Teste de widget avança o relógio e verifica: o
contador mostra N em t=1100 ms e N+1 em t=1500 ms; o ponto de hoje vira
"presente" ao fim; o espião do `SomService` registra `gota, toc, nota×3,
plim` nessa ordem; com `disableAnimations` só `plim`. Golden do quadro final
para as 9 espécies. Em aparelho: gravação a 60 fps sem quadro perdido
(DevTools, *raster* < 16 ms).

### 5.3 Mini-cenas da raiz (mesma linguagem)

- **"O congelamento segurou."** Na abertura seguinte a um dia congelado: o
  segmento da raiz daquele dia aparece com cristais de gelo que derretem em
  orvalho (600 ms); texto "Seu congelamento segurou a raiz de 12 dias. Outro
  chega segunda." Um tick. Sem som de conquista — é alívio, não prêmio.
- **"A raiz adormeceu."** Abertura depois de um dia faltado sem congelamento:
  a raiz intacta, uma lua pequena sobre a ponta; texto "Dias corridos
  acontecem. Sua raiz de 12 dias está dormindo, e acorda com 3 focos até
  quinta." Barra 0/3. Sem háptico, sem som.
- **"Replantada."** No 3º foco do replantio: a lua some, a gota desce, a raiz
  volta a crescer (Q1–Q4) e o contador rola de 12 para 13.

---

## 6. A cadeia de celebração pós-sessão e a coleta de recompensas

### 6.1 O que se sabe do Duolingo

- [F2] Ordem pós-lição: XP → pequena celebração → "Continuar" → ofensiva
  ([teardown](https://duolingo.deconstructoroffun.com/mechanics/streaks)).
- [F] Personagens têm animação própria a cada acerto e há "animações de meio
  de lição" que recompensam acertos seguidos; o fim de lição tem animação de
  personagens atravessando a tela ([building character](https://blog.duolingo.com/building-character/)).
- [F2] Missões diárias concluídas abrem baús; amigos e missões mensais somam
  pontos para o selo do mês ([App Store](https://apps.apple.com/id/iphone/story/id1688543383);
  [Duoplanet](https://newsletter.duoplanet.com/posts/how-many-quests-duolingo)).
- **Não achei** documentação oficial da anatomia completa da sequência (ordem
  exata de missões, liga, baú) nem de seus tempos. O que segue para o Baru é
  proposta.

### 6.2 Princípios para o Baru

[I] Cada recompensa tem seu segundo de palco, uma por vez; só aparece a
etapa que tem novidade (nunca tela vazia); a animação acontece **na tela que
a pessoa está olhando**, a partir de um retrato "antes" tirado na conclusão
(corrige o problema de agosto em que a home animava por baixo); a sequência é
curta (3–7 s típicos) e cada etapa aceita toque para avançar depois de
~700 ms; e o fim é **fechamento**, não convite a mais tela.

### 6.3 Anatomia de cada tela

| Etapa | Mostra quando | Conteúdo | Ação |
|---|---|---|---|
| E1 Sessão concluída | sempre | Pet sai da atividade (sai da água, acorda); "+10 folhas" contando de 0 com folhinhas voando para o selo de folhas no topo; barra de XP enchendo "+12 XP" e, se for a 1ª do dia, "+5 da raiz" | auto/toque |
| E2 Raiz | 1ª presença do dia | Cena da seção 5 | "Continuar" |
| E3 Missões | alguma missão avançou | Só as missões tocadas por esta sessão; cada barra anda do valor antigo ao novo; as que fecharam viram "Pronta para colher" com a **toca embutida** | "Colher" (toca) ou "Depois" |
| E4 Marco / nível | se houver | `Celebracao` com toca, como etapa final — nunca véu sobre E1 | toca |
| E5 Fecho | sempre | Uma frase sobre o que falta **ou** "Dia feito" | "Voltar ao habitat" |

**E5 — o fecho que só o Baru pode ter.** [I] Se raiz e principal do dia
estão feitas: pet se acomoda para dormir, texto "Dia feito. Pode largar o
telefone, o Baru cuida do resto." e um botão só. Se não: o próximo passo
**mais perto do fim** (meta próxima): "Falta 10 min para 'Some 60 min de
foco' (+22 folhas)". Nunca "mais uma sessão?" logo após uma sessão longa.

### 6.4 Storyboard — sequência de fim de sessão (sessão de 25 min, 1ª do dia, uma missão fechada)

| t (ms) | Tela | Imagem | Som | Háptico |
|---|---|---|---|---|
| 0 | Foco | O anel do tempo fecha; o pet sai da água e sacode | `fim` (já existe) | batida firme (`heavyImpact`) — mesmo instante do som |
| 0–350 | → E1 | Transição: a cena da sessão encolhe para o topo (container transform) | — | — |
| 350–1350 | E1 | "+10" conta 0→10 em 600 ms (*easeOut*); 10 folhinhas saem do número e voam em arco para o selo de folhas, que pulsa a cada chegada | "tic" suave a cada 3 folhas (no máximo 4 tics) | tick leve com os tics (força 0,3) |
| 1350–2100 | E1 | Barra de XP enche "+12 XP"; depois "+5" num segundo segmento, de outra cor, com o rótulo "raiz" | "swish" curto | — |
| 2100 | E1 | Aparece "Continuar"; toque ou 1,5 s de espera | — | `selectionClick` no toque |
| 2100–4500 | E2 | Cena "raiz cresceu hoje" (seção 5) | ver 5 | ver 5 |
| 4500–4850 | E3 | Entram os cartões das 2 missões tocadas | — | — |
| 4850–5650 | E3 | "Faça uma sessão de foco" 0/1→1/1 (barra 500 ms) e vira laranja "Pronta para colher"; "Some 60 min" 25/60→50/60 | `resgate` baixo quando a primeira fecha | tick quando a barra encosta no fim |
| 5650+ | E3 | Toca embutida no cartão pronto: 3 gestos de cavar | `cavar` ×3, `premio` | 3 ticks crescentes + batida (já existe em `toca.dart`) |
| após o prêmio | E3 | "+10 folhas · +10 XP" sobe da toca e voa para o selo | `resgate` | tick |
| +400 | E5 | "Falta 10 min para 'Some 60 min de foco'." ou "Dia feito." | — | — |

Com "reduzir movimento": cada etapa vira um cartão estático com os valores
finais, um som por etapa, e todas as etapas numa só rolagem.

### 6.5 Coleta de recompensas — clara e gratificante

- **Colher tudo de uma vez** (U12). Na aba Missões, quando houver 2+ prontas,
  um único cartão "3 para colher" abre **uma** toca; cada gesto revela um
  prêmio, na ordem do menor para o maior (o último é o maior — fecha em alta).
  Hoje são 3 gestos × N missões em folhas separadas (`missoes_screen.dart:650-700`).
- **Indicador na aba**: ponto laranja com número em "Missões" quando houver o
  que colher (não existe hoje — grep sem `Badge` em `app.dart`).
- **Colher onde se ganhou**: na E3 da sequência, sem mandar a pessoa para a
  aba.
- **Nada expira sem aviso**: à noite, se algo pronto ainda não foi colhido,
  colher automaticamente à meia-noite e mostrar na abertura seguinte
  "Guardei para você: +22 folhas" [I] — prêmio pronto nunca se perde (regra 1).

---

## 7. Missões: Duolingo × Baru

### 7.1 Comparação

| Aspecto | Duolingo | Baru hoje [O] |
|---|---|---|
| Diárias | 3 por dia, renovam a cada 24 h; cada uma abre um baú [F2] | 3 sorteadas de 13 + a "principal" (descanso) + "retomada" no dia da volta (`missoes.dart:159-307`) |
| Semanais | Friends Quest: 5 dias, par com um amigo, desafio aleatório, recompensa maior [F](https://blog.duolingo.com/friends-quests/) | 2 de 6, individuais (`missoes.dart:324-376`) |
| Mensais | Selo do mês por pontos de missão [F2] | Não existe |
| Progresso visível | No fim da lição e na aba [F2] | Só na aba |
| Resgate | Baú por missão [F2] | Toca com 3 gestos por missão (`toca.dart:47`) |
| Clareza | Título curto + barra | Título de ação + "como" + barra + recompensa + prazo — **melhor que o Duolingo** (`04-missoes.png`) |
| Dia jogável sem permissão | n/a | 6 de 13 diárias exigem permissão de uso (R18 de agosto, aberta) |

### 7.2 O que fazer

- **U10 — Missão mensal com selo** (substitui R20 de agosto com detalhe).
  "Outubro: colha 20 missões" ou, alinhado à raiz, "20 dias presentes em
  outubro". Selo desenhado por mês (folha/flor do bioma), guardado num
  "herbário" no perfil do pet. Não expira de forma punitiva: o selo do mês
  passado incompleto fica como "broto" (não some). Abre no dia 1 — [F] o
  início do mês é um marco temporal que aumenta comportamento aspiracional
  (Dai, Milkman & Riis, 2014).
- **U11 — Missões no fim da sessão** (E3 da seção 6).
- **U12 — Colher tudo + indicador na aba** (6.5).
- **U13 — Missões que se ajustam ao dia**: R18 (sorteio jogável) + uma das 3
  diárias sempre do tamanho mínimo ("um foco de 10 min"), para o dia ruim ter
  vitória possível.
- **Não fazer agora**: missões com amigos — exigem social (SC-01), e o
  roadmap deixou para depois.

---

## 8. Psicologia: o que usar, e como não manipular

| Conceito | O que a pesquisa diz | Uso no Baru | Limite ético |
|---|---|---|---|
| Hábito por repetição em contexto | [F] Mediana de 66 dias até a automaticidade estabilizar (18–254); perder uma oportunidade **não** prejudicou materialmente a formação do hábito (Lally et al., 2010, [doi](https://doi.org/10.1002/ejsp.674); citação via [cobertura](https://nextbigideaclub.com/magazine/james-clear-science-habit-formation-different-weve-told/6203/)) | Congelamento e replantio são **cientificamente** coerentes: um dia faltado não desfaz o hábito, então o app não deve fingir que desfaz | Não vender "21 dias" ou garantias |
| Folga planejada | [F] Metas com "reserva de emergência" aumentaram a retomada após falha (55% vs 37% no estudo de campo de passos) (Sharif & Shu, *OBHDP* 2019, [pdf](https://anderson-review.ucla.edu/wp-content/uploads/2021/03/Sharif-Shu_EmergencyReserveFailure_OBHDP2019.pdf)) | Congelamento como reserva visível e equipável | — |
| Sequência quebrada | [F] Sequência intacta aumenta o engajamento seguinte; quebrada reduz; efeito maior quando a pessoa se culpa, menor quando dá para reparar (Silverman & Barasch, *JCR* 2023, [resumo](https://www.colorado.edu/business/faculty-research/2023/04/19/or-track-how-broken-streaks-affect-consumer-decisions)) | Replantio; texto com atribuição externa; raiz guardada | Não usar a quebra como ameaça |
| Meta próxima (goal gradient) | [F] Clientes compram mais rápido perto do prêmio; progresso "dado" acelera; quem acelera retém mais (Kivetz, Urminsky & Zheng, *JMR* 2006, [pdf](https://business.columbia.edu/sites/default/files-efs/pubfiles/1200/goalgradient.pdf)) | "Faltam 2 dias para o galho"; "falta 10 min"; ordenar missões pela proximidade (já feito em `missoes_screen.dart`) | Não inventar progresso falso |
| Progresso dotado | [F] Cartão com 2 de 10 carimbos já preenchidos: 34% de resgate vs 19% (Nunes & Drèze, 2006, via [Wharton](https://knowledge.wharton.upenn.edu/podcast/knowledge-at-wharton-podcast/the-lowdown-on-customer-loyalty-programs-which-are-the-most-effective-and-why/)) | Selo do mês começa com o dia 1 já marcado se a pessoa abriu no dia 1 (presença real) | Só dotar com algo verdadeiro |
| Recomeço (fresh start) | [F] Segunda, início de mês e aniversário aumentam metas e idas à academia (Dai, Milkman & Riis, 2014, [pdf](https://faculty.wharton.upenn.edu/wp-content/uploads/2014/06/Dai_Fresh_Start_2014_Mgmt_Sci.pdf)) | Convite de segunda e de dia 1; volta pós-ausência apresentada como "semana nova" | — |
| Autodeterminação (SDT) | [F] Autonomia, competência e vínculo sustentam motivação intrínseca (Ryan & Deci, 2000, [doi](https://doi.org/10.1037/0003-066X.55.1.68)); em jogos, prever prazer e retorno pela satisfação dessas três (Ryan, Rigby & Przybylski, 2006, [doi](https://doi.org/10.1007/s11031-006-9051-8)); recompensas tangíveis esperadas tendem a minar a motivação intrínseca (Deci, Koestner & Ryan, 1999, [doi](https://doi.org/10.1037/0033-2909.125.6.627)) | **Autonomia**: escolher duração, horário do lembrete, desligar cada tipo; **competência**: raiz e missões mostram progresso real; **vínculo**: o pet reage a você, nome próprio, gesto da espécie | Folhas/XP não podem ser o único motivo; o texto fala do **tempo longe da tela**, não só do prêmio |
| Recompensa variável | [F2] Base do modelo "Hooked" (Eyal, 2014, livro) | Variar **o que o pet faz** e **a frase**, não o valor da recompensa | Sem caixa de loot com valor aleatório; prêmio de missão sempre o mesmo e anunciado antes (o contrato §8C já exige "recompensa exata") |
| Notificações e atenção | [F] Uma semana com alertas ligados aumentou sintomas de desatenção e hiperatividade em 221 pessoas (Kushlev, Proulx & Dunn, CHI 2016, [pdf](https://www.interruptions.net/literature/Kushlev-CHI16.pdf)); receber em 3 lotes por dia melhorou atenção e sensação de controle; desligar tudo aumentou ansiedade/FoMO (Fitz et al., 2019, [Duke](https://scholars.duke.edu/publication/1402953)) | Poucas notificações, em horários previsíveis, nunca no dia já cumprido | Um app de reduzir tela que vira fonte de interrupção quebra a própria promessa |

**Checklist anti-dark-pattern para cada recurso novo** [I]: (1) a pessoa
pode recusar sem perder o que já tem? (2) o texto descreve um fato
verdadeiro? (3) existe caminho de volta grátis? (4) o recurso aumenta tempo
**longe** da tela ou só tempo **no** app? (5) funciona igual com som,
vibração e notificação desligados? Um "não" bloqueia.

---

## 9. Notificações de lembrete

### 9.1 O que se sabe publicamente do sistema do Duolingo

- [F] Lembretes vêm de **pools de modelos escritos à mão**, com lacunas
  (ofensiva, idioma). Modelos têm **critérios de elegibilidade** (ex.: só
  para ofensiva 3+; só para quem tem aposta de ofensiva; só segunda-feira).
- [F] O algoritmo é o **Recovering Difference Softmax**, um bandit "dormente"
  (braços inelegíveis em certas rodadas) e "recuperável" (o efeito de
  novidade some com a repetição e volta com o tempo). Cada modelo é avaliado
  pela diferença entre a taxa de sucesso quando é escolhido e quando estava
  elegível mas outro foi escolhido; aplica-se uma **penalidade de recência**
  com meia-vida. Sucesso = completar uma lição em **até 2 horas** após o
  envio. Resultado em produção: **+0,5% de DAU total e +2% de retenção de
  novos usuários** sobre uma linha de base forte (Yancey & Settles, KDD 2020,
  [pdf](https://research.duolingo.com/papers/yancey.kdd20.pdf)).
- [F] O paper registra que testes A/B anteriores de modelos novos mostravam
  ganho que sumia no longo prazo — origem da hipótese de novidade. Os modelos
  são traduzidos para 25 idiomas de interface, e o desempenho de cada um varia
  por idioma ([paper](https://research.duolingo.com/papers/yancey.kdd20.pdf);
  [blog](https://blog.duolingo.com/hi-its-duo-the-ai-behind-the-meme/)).
- [F] Modelos novos são testados em pouca gente antes de entrar no pool
  ([blog](https://blog.duolingo.com/hi-its-duo-the-ai-behind-the-meme/)).
- [F2] A mensagem "Estes lembretes não parecem estar funcionando. Vamos parar
  de enviar por enquanto" é relatada por usuários desde 2020
  ([Medium](https://debugger.medium.com/duolingo-needs-to-chill-8f1832745ca0)).
  **Não achei** fonte oficial sobre a regra de parada.
- **Não achei** fonte primária para a regra popular de "lembrete 23,5 h após a
  última lição" — não usar como fato.
- [F2] O "Duo triste"/passivo-agressivo é tom de marca e meme, criticado por
  incomodar parte do público ([University XP](https://www.universityxp.com/news/2025/7/25/we-havent-seen-you-in-a-while-duolingos-passive-aggressive-strategy-for-keeping-users-hooked)).
  Não serve ao Baru (regra 1).

### 9.2 Limites da plataforma

- [F] Android 13+: `POST_NOTIFICATIONS` é permissão de execução e as
  notificações **nascem desligadas** em instalação nova; a orientação é pedir
  **no contexto** de uma ação da pessoa ou depois de algumas aberturas, com
  tela de justificativa ([Android](https://developer.android.com/develop/ui/views/notifications/notification-permission)).
  [O] O Baru pede no lote de permissões do onboarding (R6 de agosto, aberta).
- [F] Canais: "crie um canal para cada tipo de notificação"; depois de
  criado, importância e comportamento ficam com o usuário
  ([Android](https://developer.android.com/develop/ui/views/notifications/channels)).
  [O] Achado A7.
- [F] Alarmes inexatos (`setAndAllowWhileIdle`, que é o que o
  `inexactAllowWhileIdle` do plugin usa) disparam **até 1 hora depois** do
  horário no Android 12+; `SCHEDULE_EXACT_ALARM` não vem concedida em
  instalação nova para apps que miram API 33+
  ([Android](https://developer.android.com/develop/background-work/services/alarms/schedule)).
  [I] Consequência para o texto: nunca prometer hora exata ("em 1 hora a raiz
  dorme"); agendar o último aviso até 21h45 para chegar antes das 23h no pior
  caso.
- [F] iOS tem níveis de interrupção (`passive`, `active`, `timeSensitive`,
  `critical`) em `UNNotificationInterruptionLevel`. Não consegui ler a página
  de diretrizes da Apple (renderização em JS). [I] Usar `passive` para
  relatório e volta, `active` para convite e raiz; nunca `timeSensitive`.

### 9.3 Calendário proposto para o Baru

Regras gerais [I]:

- Janela permitida: **8h–22h30**, sempre. (Hoje o descanso herda a hora do
  hábito sem teto — R30 de agosto.)
- **Dia cumprido = silêncio.** Se a raiz já cresceu hoje, nenhum lembrete de
  retenção; só o relatório da noite, se a pessoa ligou.
- Teto: **2 por dia**, 3 h entre eles (o plano atual já faz isso em
  `descanso_retencao.dart:306-364`).
- Toda notificação abre a tela da ação (deep link) e carrega o id do modelo.
- Reprogramar ao **concluir** foco/descanso (corrige A5) e ao **sair** do app
  (agenda a escada de ausência; cancela tudo ao abrir — corrige R28/B4).

| Gatilho | Horário | Canal | Condição | Deep link |
|---|---|---|---|---|
| Convite do dia | hora do hábito (aprendida; padrão 19h) | "Lembrete diário" | raiz ainda não cresceu hoje | home com CTA em foco |
| Raiz em risco | hábito + 1 h, entre 19h e 21h45 | "Raiz" | não presente, raiz ≥ 2, **sem** congelamento disponível. Com congelamento, o convite carrega a informação e este não sai | home, com "foco de 10 min" pré-selecionado |
| Ainda dá tempo (opt-in, ligado por padrão para raiz ≥ 7) | 21h45 | "Raiz" | igual ao anterior, e o anterior não foi aberto | idem |
| Relatório da noite (opt-in, já existe) | 21h (configurável) | "Relatório" (`passive` no iOS) | ligado | `/report` |
| Volta D+1 | hábito | "Volta" | raiz adormeceu | tela da raiz (replantio) |
| Volta D+2 | hábito | "Volta" | ainda no prazo de replantio | idem |
| Volta D+3 | 10h | "Volta" | último dia de replantio | idem |
| Volta D+7, D+14 | hábito | "Volta" | sem abrir | home |
| Volta D+30 | hábito | "Volta" | sem abrir | home; **último envio** — depois, silêncio até a pessoa voltar |
| Semana nova | segunda, hora do hábito (substitui o convite) | "Lembrete diário" | — | `/missoes` |
| Mês novo | dia 1 (substitui o convite) | "Lembrete diário" | — | selo do mês |

**Recuo automático** [I]: se 3 convites seguidos não forem abertos em 2 h,
passar a dia sim, dia não, por uma semana; se a pessoa abre, volta ao normal.

**Missão quase pronta não vira push.** Entra como variante elegível do
convite ("Falta um foco para colher 'Dois focos hoje'"). Um app de tempo de
tela não deve interromper por causa de folhas.

### 9.4 Textos de exemplo (pt-BR)

Variáveis: `{pet}` nome; `{acao}` gesto da espécie; `{n}` dias de raiz; `{m}`
próximo marco; `{f}` dias que faltam; `{k}` folhas. Cada linha é título ·
corpo. Precisam nascer nos 4 idiomas (regra 2); en/es/zh ficam como
`TODO-i18n` até revisão nativa.

`{acao}` por espécie: Baru "boiando na lagoa"; Rio "mergulhando no igarapé";
Toco "tomando sol na pedra"; Nina "pousada no galho"; Lume "brilhando no
fundo do lago"; Nino "deslizando no gelo"; Mel "cochilando na janela";
Faísca "farejando a trilha"; Bolota "roncando no tapete".

**Convite do dia** (raiz ≥ 1, não presente)
1. "{pet} está {acao}" · "Quando quiser, 10 min de foco fazem a raiz crescer."
2. "Hora do seu foco" · "{pet} guardou um lugar do seu lado. A raiz de {n} dias espera um gole de água."
3. "Um pouco longe da tela?" · "Um foco curto hoje, e {pet} cuida do resto."
4. "Raiz de {n} dias" · "Ela cresce com qualquer foco de 10 min ou com o descanso do dia."
5. "{pet} achou uma sombra boa" · "Que tal 25 min de foco por lá?"
6. (véspera de marco) "Faltam {f} dias para o galho de {m}" · "Hoje conta. 10 min bastam."

**Convite sem raiz (raiz 0, dia normal)**
1. "{pet} está {acao}" · "Comece uma raiz nova hoje com 10 min de foco."
2. "Um dia bom para plantar" · "Um foco curto e a primeira raiz já nasce."

**Raiz em risco** (sem congelamento)
1. "Sua raiz de {n} dias ainda pode crescer hoje" · "Um foco de 10 min ou o descanso já seguram."
2. "{pet} deixou a terra regada" · "Falta só o seu foco de hoje para a raiz de {n} dias."
3. "Ainda dá tempo hoje" · "10 min de foco e a raiz de {n} dias continua."
4. (véspera de marco) "A {f} dias do galho de {m}" · "Um foco curto hoje mantém o caminho."

**Com congelamento disponível** (entra no convite, não sai sozinho)
1. "Raiz de {n} dias protegida" · "Se hoje não der, o congelamento segura. Se der, ela cresce."

**Ainda dá tempo** (21h45, opt-in)
1. "Antes de dormir" · "10 min de foco e a raiz de {n} dias cresce hoje."
2. "Último foco do dia?" · "{pet} já está {acao}. Dá para fechar o dia com 10 min."

**Volta** (sem culpa, com caminho)
- D+1: "Sua raiz está dormindo" · "Dias corridos acontecem. 3 focos até {dia} acordam a raiz de {n} dias."
- D+2: "A raiz de {n} dias ainda acorda" · "Faltam {r} focos. {pet} está {acao}."
- D+3: "Último dia para acordar a raiz" · "Se não der, ela fica guardada no bosque, com os {n} dias."
- D+7: "Guardei seu lugar" · "{pet} continua {acao}. Volte quando quiser — tem +{k} folhas esperando."
- D+14: "Semana nova, raiz nova" · "Uma raiz nova começa com um foco de 10 min."
- D+30: "Vou ficar quietinho" · "Não mando mais lembretes. Quando quiser voltar, {pet} vai estar aqui."

**Semana / mês**
- "Missões novas da semana" · "Duas novas, e a primeira começa com um foco."
- "Outubro começou" · "O selo do mês é uma folha de ipê. 20 dias presentes e ela é sua."

**Relatório da noite** (já existe; variar por estado)
- presente: "Dia feito" · "Raiz de {n} dias. {pet} já foi dormir."
- abaixo da meta: "Abaixo da meta hoje" · "Seu tempo de tela ficou {x} abaixo. +15 folhas amanhã cedo."
- colheita pendente: "Tem folha na mesa" · "{c} missões prontas para colher. Eu guardo para você."

### 9.5 Rotação e "bandit" no aparelho

[I] O Baru não precisa de servidor para a parte que mais rende no paper do
Duolingo — a **penalidade de recência**:

- Escolha determinística por (conta, dia, tipo), excluindo modelos usados
  nos últimos 5 envios daquele tipo; entre os elegíveis, sorteio ponderado.
- Registro local por modelo: enviados; abertos em até 2 h (pelo `payload`
  do toque, ou abertura do app até 2 h depois do horário agendado — o mesmo
  critério do paper).
- Pontuação: taxa local de abertura (com prior igual para todos) − γ·0,5^(dias
  desde o último uso / h), com γ e h fixos (ex.: γ = 0,05, h = 7 dias).
- Um **bandit global** (aprender entre usuários) exige mandar contagens para
  o servidor, o que esbarra em "nada sai do aparelho além do necessário".
  Se for feito, só com agregados anônimos e consentimento — decisão de
  produto, registrar em ADR.

### 9.6 Como fazer (Flutter/Android)

- Canais: `baru_raiz`, `baru_convite`, `baru_relatorio`, `baru_volta`
  (mais o `baru_sessao` atual). Migração: apagar `baru_reminders` uma vez e
  recriar (a preferência do usuário daquele canal se perde — aceitável uma
  vez, anunciar na nota da versão).
- `payload` em todo `zonedSchedule` com `rota|idDoModelo`;
  `onDidReceiveNotificationResponse` e `getNotificationAppLaunchDetails`
  (já usado para ações em `notification_service.dart:214-240`) levam a
  `app.abreRota`.
- Agendar a escada de ausência em `AppLifecycleState.paused` (ids 1100–1110),
  cancelar tudo em `resumed`. Reprogramar retenção em `_concluiSessao` e na
  conclusão do descanso.
- Corrigir `_agendaRaiz` para montar o texto do "amanhã" com o estado de
  amanhã (raiz + 1 se presente hoje; raiz adormecida se não).
- Pedir `POST_NOTIFICATIONS` depois do primeiro resultado celebrado: "Quer
  que eu te avise se a raiz precisar de você? No máximo 2 por dia." (R6).

**Critério de aceite do bloco de notificações.** Testes de unidade do plano:
(a) dia com presença → zero agendamentos de retenção; (b) concluir sessão
cancela `raizHojeId`; (c) nenhum agendamento fora de 8h–22h30; (d) mesmo
modelo não se repete em 5 envios do tipo; (e) toda notificação tem
`payload`; (f) cada tipo em seu canal. Em aparelho (roteiro como o BL-09):
concluir foco às 20h, fechar o app, confirmar que nada chega às 21h.

---

## 10. Jornada de ponta a ponta

| Momento | O que a pessoa vive hoje [O] | Onde o Baru perde [I] | O que colocar |
|---|---|---|---|
| **Dia 0** (instalação) | Login antes de tudo, ~15 toques, quiz, revelação estática, 4 permissões, paywall sem saída (agosto, R1–R6, ainda abertos); home sem CTA visível (`01-home.png`) | Antes do primeiro valor | Primeira sessão guiada **de 10 min** (R2 com duração menor); fim com a sequência da seção 6 e a **primeira raiz nascendo** (variante "semente brota" da cena 5); permissão de notificação pedida ali |
| **Dia 1** | Abre e vê "Você voltou" com som de conquista (A9); faixa da semana sem eco do dia anterior se virou segunda (A3) | Se não abrir, só o convite do descanso (texto fixo); o lembrete de raiz pode não existir (A6) | Convite variado no horário do hábito; ao abrir, a home diz o que fazer hoje em uma linha ("Raiz de 1 dia · 10 min fazem ela crescer") com o CTA fixo (R9) |
| **Dias 2–6** | Raiz conta, mas não cresce na tela; missões pedem ir até a aba | A rotina sem eco: nada muda visivelmente | Cena diária da raiz; véspera do marco de 3 e de 7 ("faltam 2 dias para o galho"); colher na sequência |
| **Dia 7** | Nada acontece (sem celebração de marco) | O marco que mais prevê continuidade no Duolingo [F] (2,4× mais chance de voltar no dia seguinte) passa em branco | Marco 7 com galho, adereço no pet e cartão de compartilhar |
| **Semana 2–4** | Primeira falta sem congelamento zera a raiz | Quebra é o maior risco de abandono [F: Silverman & Barasch] | Raiz adormecida + replantio; congelamento extra ganho na missão semanal |
| **Mês 1** | Loja quase esgotada (~28 dias engajados, agosto); sem objetivo mensal | Folhas sem destino | Selo do mês; marco 30 vira árvore no "Bosque"; trilha mostra o próximo bioma (R24) |
| **Mês 2–3** | Trilha termina por volta do dia 67 (estimativa em `progressao.dart:300-301`); "Trilha inteira percorrida" | Fim de conteúdo | Antes de lançar: horizonte pós-trilha (R22); crescimento do pet por **dias juntos** (acumulado, não sequência) para o laudo de pets; selos mensais continuam |
| **Mês 3+** | Nível máximo só em ~393 dias; nada recomeça | Repetição sem novidade | Estações (itens sazonais), marcos 100/180/365 no Bosque, "raízes entrelaçadas" quando houver social |

**Quando a trilha acaba** [I]: (1) celebrar o fim como marco grande (o pet
"chega" ao último bioma), (2) abrir imediatamente o horizonte seguinte, nunca
um estado vazio — selo do mês e Bosque já resolvem o "próximo" sem conteúdo
novo; (3) quando houver conteúdo, "estações" de 8–10 passos por atualização.
O pet nunca "termina": o crescimento visível por espécie (ovo → adulto, laudo
de pets) deve ter estágios até pelo menos 365 dias juntos.

---

## 11. Recomendações detalhadas

Esforço: P (até 3 dias), M (1–2 semanas), G (3+ semanas). Impacto é
qualitativo — só cito números com fonte.

**U1 — Cena "raiz cresceu hoje".** O quê: seção 5. Por quê: A1, achado 2 do
sumário; [F] a animação de marco do Duolingo deu +1,7% de retenção D7 em
novatos. Como: seção 5. Esforço M. Impacto: alto (é o reforço diário do
hábito). Aceite: seção 5.

**U2 — Marcos de raiz celebrados (substitui R13).** O quê: variante de marco
da seção 5, com galho, adereço e compartilhamento. Por quê: 4.1. Como:
`RaizViva.marcos` já define os dias; `CartaoDaRaiz` já existe. Esforço M.
Impacto: alto. Aceite: em teste, raiz 6→7 dispara `Celebracao`/cena de marco
uma única vez; 7→8 não.

**U3 — Barra mínima da raiz: foco de 10 min ou descanso.** O quê: duração
"10 min" nos chips e nos Ajustes; presença = foco ≥10 min **ou** descanso
cumprido. Por quê: A4, A8; [F] "uma lição basta" no Duolingo (+3,3% D14,
+40% em ofensivas 7+). Como: `durations` em `models.dart:102` ganha 10;
`sessionReward(10)` = 5 pela regra livre; `resgataODescanso`/conclusão do
descanso chama o mesmo `_registraPresenca()` que `_concluiSessao`. **Exige
ADR** (muda a regra de presença; §5 já cobre a recompensa por `floor(min×0,5)`).
Esforço P/M. Impacto: alto. Aceite: teste — descanso concluído sem foco
incrementa `streak` uma vez; foco de 10 min idem; dois no mesmo dia, uma vez.

**U4 — Faixa da semana honesta e uma só gramática visual.** O quê: hoje vira
✓ assim que há presença; faixa mostra **os últimos 7 dias** (não a semana
ISO); mesmos símbolos na home e na raiz (✓ verde = presente, floco = congelado,
anel = hoje, lua = adormecida). Por quê: A1, A2, A3. Como: derivar a faixa do
histórico de presenças em vez do vetor `week` zerado na segunda
(`state.dart:2100-2103`); um widget `PontoDoDia` compartilhado. Esforço P.
Impacto: médio-alto (clareza). Aceite: golden da home e da raiz com os mesmos
4 estados; teste "raiz de 4 dias numa segunda" mostra 4 ✓.

**U5 — Raiz adormecida e replantio por esforço (substitui R17).** O quê:
4.4. Por quê: regra 1; [F] Silverman & Barasch (reparo atenua o efeito da
quebra); [F2] Duolingo, jun/2026: recuperação por 3 lições, 15+ milhões. Como:
estado `RaizEstado {crescendo, adormecida(ate, faltam), guardada}` em
`AppState`; `_advanceDay` deixa de zerar e passa a adormecer; histórico de
raízes guardadas persistido e sincronizado. **Exige ADR e mudança em
PRODUCT §7.** Esforço M. Impacto: alto (o momento de maior abandono).
Aceite: testes de domínio para os 3 caminhos (acorda em 3 focos; não acorda e
guarda; congelamento tem precedência).

**U6 — Congelamento como objeto.** O quê: até 2 guardados (1 semanal grátis +
1 extra ganho na missão semanal "3 dias presentes" ou comprado com folhas,
**sem** ser a única via); mostrado na pílula da raiz e na cena 5.3. Por quê:
[F] 2 equipáveis no Duolingo, +0,38% DAU sem aumentar folgas; Sharif & Shu.
Como: `freezesLeft` vira `congelamentos` com teto 2; a reposição de segunda
não apaga o extra. Comprar com folhas é sumidouro (R25), mas **exige revisar
§5** ("comprar é a única ação que muda a cena"). Esforço P/M. Aceite: teste
de teto 2; segunda repõe só o semanal.

**U7 — Cadeia de fim de sessão (refina R8).** O quê: seção 6 (E1–E5), com
retrato "antes" e fecho "Dia feito". Por quê: R8 aberta; [F2] ordem
XP→celebração→ofensiva no Duolingo. Como: `ResumoDaSessao` capturado em
`_concluiSessao` (folhas/XP/raiz/missões antes e depois); `ResultScreen`
vira um `PageView` sem rolagem manual com etapas geradas do resumo. Esforço M.
Impacto: alto. Aceite: teste de widget percorre as etapas e confere que só
aparecem as que têm novidade; a home não anima por baixo (contadores da home
param enquanto `AppScreen.result` está no topo).

**U8 — Bosque: marcos e raízes guardadas como coleção permanente.** O quê:
marcos 30/100/365 viram árvores no habitat e uma tela "Bosque" lista raízes
guardadas e marcos. Por quê: [F] Streak Society como pertencimento; regra 1
(nada se perde). Como: camada no `habitat.dart` acima dos itens comprados;
dados no snapshot. Esforço M. Aceite: árvore do marco 30 aparece na cena e
persiste após quebra da raiz.

**U9 — Widget do Baru com o estado do dia.** O quê: o widget existente mostra
"raiz cresceu hoje ✓" ou "raiz de {n} dias · 10 min fazem crescer", e o pet
muda de pose ao longo do dia (acordado → sentado esperando → aconchegado),
**sem desespero**. Por quê: [F] widget do Duolingo — metade dos usuários com
widget tem 6+ meses de ofensiva. Como: `widget_service.dart` já publica PNG;
acrescentar estado e 3 poses por espécie; atualizar em
`_concluiSessao` e por `WorkManager` às 12h/18h/21h. Esforço M. Aceite:
widget muda para ✓ em até 5 s após concluir a sessão.

**U10 — Selo do mês.** Seção 7.2. Esforço M. Impacto: médio-alto (horizonte
entre o dia e a trilha). Aceite: teste "20 presenças em outubro" concede o
selo uma vez; mês incompleto mostra broto, não vazio.

**U11 — Missões no fim da sessão.** Seção 6 E3. Por quê: A10. Esforço P (com U7). Impacto: médio (progresso visto onde foi ganho). Aceite:
sessão que fecha "um_foco" mostra a barra de 0/1 a 1/1 na E3.

**U12 — Colher tudo + indicador na aba + colheita automática à meia-noite.**
Seção 6.5. Por quê: A10. Como: `Toca` aceita lista de prêmios; badge no item
de navegação; `_advanceDay` credita prontas não colhidas e cria `guardadas`
para mostrar na abertura. Esforço P/M. Impacto: médio (coleta clara, nada parado). Aceite: com 3 prontas, 3 gestos
abrem os 3 prêmios; à meia-noite o saldo sobe e a abertura mostra o recado.

**U13 — Dia sempre ganhável.** R18 + uma diária mínima. Por quê: 7.1 (6 de 13 diárias exigem permissão). Esforço P. Impacto: médio. Aceite:
sem permissão de uso, as 3 diárias são executáveis em 100% de 10.000 sementes
sorteadas no teste.

**U14 — Notificações: canais, deep link, reprogramação e correções A5/A6.**
Seção 9.6. Esforço M. Impacto: alto (hoje há risco de mensagem falsa).
Aceite: seção 9.6.

**U15 — Calendário e pools de texto.** Seções 9.3–9.5, nos 4 idiomas.
Esforço M. Impacto: médio-alto; [F] no Duolingo, a escolha do modelo com
recência rendeu +0,5% DAU e +2% retenção de novos. Aceite: testes do
plano (9.6) e paridade de chaves (`test/l10n_test.dart`).

**U16 — Revisão de tom.** O quê: trocar "passou o dia esperando por isso"
(`l10n.dart:719`), "Senti sua falta" (`l10n.dart:1029-1030`) e corrigir
"Toque em Focar"/"fique com o Baru" (`l10n.dart:748`); saudação diária sem
som de conquista e sem véu (um aceno do pet na própria home). Por quê: A9,
A11, 4.3. Esforço P. Impacto: médio (confiança no tom). Aceite: lista de palavras proibidas (4.3) vira teste
sobre os catálogos.

**U17 — Instrumentação local antes de mexer.** O quê: contadores no aparelho
(e sincronizados só se a pessoa permitir): presença por dia, quebras,
replantios, aberturas em 2 h por modelo, etapas vistas/puladas da sequência.
Por quê: sem medir não dá para validar nada disto. Esforço P/M. Impacto: indireto, habilita todas as outras. Aceite:
painel de depuração (já existe em modo debug) mostra os contadores.

---

## 12. As 10 recomendações mais importantes, em ordem

1. **U14** — consertar notificações que podem mentir (A5/A6), canais por
   tipo, deep link, reprogramar ao concluir. (M)
2. **U3** — raiz cresce com foco de 10 min ou descanso. (P/M, ADR)
3. **U1** — cena "raiz cresceu hoje". (M)
4. **U7 + U11** — cadeia de fim de sessão com missões e fecho "Dia feito". (M)
5. **U5** — raiz adormecida e replantio por esforço. (M, ADR)
6. **U4** — faixa dos últimos 7 dias, hoje vira ✓, mesma gramática visual. (P)
7. **U2** — marcos de raiz celebrados e compartilháveis. (M)
8. **U15 + U16** — calendário enxuto, pools de texto com recência, revisão de tom. (M)
9. **U12** — colher tudo, indicador na aba, nada pronto se perde. (P/M)
10. **U10** — selo do mês. (M)

(U6 congelamento-objeto, U8 Bosque e U9 widget entram logo depois; U17
deve acompanhar o item 1.)

---

## 13. O que **não** fazer

- **Reparo pago** da raiz (gemas/folhas para desfazer a quebra) —
  padrão catalogado como enganoso e contrário à regra 1.
- **Duo triste/passivo-agressivo**, pet "desesperado" no widget, "última
  chance", contagem regressiva para a perda.
- **Perfect Streak** ou qualquer segunda régua que transforme o congelamento
  em defeito.
- **Ligas e placares de estranhos.**
- **Push por missão quase pronta** ou por folhas — interrupção por moeda
  contradiz a promessa do app.
- **Notificação em dia cumprido** (exceto relatório opt-in).
- **Recompensa de valor aleatório** (baú com sorte). Variar a cena, não o prêmio.
- **Prometer hora exata** em lembrete agendado de forma inexata.
- **Sequência de celebração longa e obrigatória**: sem pular, ela vira pedágio.
- **Encerrar a sessão com convite a outra sessão** como padrão; o fecho é
  "dia feito".

---

## 14. Riscos e dúvidas em aberto

1. **U3 e U5 mudam regras do contrato** (§7 e, para comprar congelamento, §5).
   Precisam de ADR. Risco: a raiz "ficar fácil" e perder valor — mitigado
   pelos marcos e pelo Bosque. Medir antes/depois (U17).
2. **A5 é inferência do código**; confirmar em aparelho antes de anunciar o
   conserto. A ordem de `reconcileSession` × `syncPermissionsFromOs` no
   `resumed` pode, em alguns caminhos, já corrigir o caso.
3. **Números do Duolingo não se transferem.** Os efeitos citados valem para
   o produto, o público e a escala deles. Servem de direção, não de previsão.
4. **Fontes secundárias**: a anatomia da cena de extensão, a aplicação
   silenciosa do congelamento, a Streak Society e a regra de parada das
   notificações vêm de análises de terceiros; o evento de junho de 2026 vem de
   imprensa e de resumo de teleconferência (a carta deu 403).
5. **Bandit global × privacidade**: aprender entre usuários exige mandar
   dados; decisão de produto.
6. **Inexatidão do alarme**: em aparelhos com economia agressiva de bateria
   (alguns fabricantes), lembretes podem atrasar mais que 1 h; testar em
   Xiaomi/Samsung.
7. **Háptico rico** só existe em parte dos aparelhos; o fallback precisa ser
   bom por si.
8. **Sem iOS Screen Time**, a presença por descanso depende de medição que o
   iOS ainda não tem (BL-06) — no iOS, a U3 vale só para o foco de 10 min.
9. **Não achei**: fonte primária para "23,5 h", para os tempos/sons da cena
   do Duolingo, para as vantagens da Streak Society e para a página de
   notificações da Apple (não renderizou).

---

## 15. Fontes

**Duolingo (primárias)**
- Improving the streak — https://blog.duolingo.com/improving-the-streak/
- How the Duolingo streak builds habit — https://blog.duolingo.com/how-duolingo-streak-builds-habit/
- Streak milestone design & animation — https://blog.duolingo.com/streak-milestone-design-animation/
- Streak celebration parties — https://blog.duolingo.com/streak-celebration-parties/
- Widget feature — https://blog.duolingo.com/widget-feature/
- Friends Quests — https://blog.duolingo.com/friends-quests/
- Product lessons: Friend Streak — https://blog.duolingo.com/product-lessons-friend-streak/
- Hi, it's Duo: the AI behind the meme — https://blog.duolingo.com/hi-its-duo-the-ai-behind-the-meme/
- Building character — https://blog.duolingo.com/building-character/
- World character visemes (Rive) — https://blog.duolingo.com/world-character-visemes
- Yancey & Settles, *A Sleeping, Recovering Bandit Algorithm for Optimizing Recurring Notifications*, KDD 2020 — https://research.duolingo.com/papers/yancey.kdd20.pdf

**Duolingo (secundárias)**
- Deconstructor of Fun, teardown de ofensivas — https://duolingo.deconstructoroffun.com/mechanics/streaks
- Lenny's Podcast, Behind the product: Duolingo streaks — https://www.lennysnewsletter.com/p/behind-the-product-duolingo-streaks
- Android Authority, evento de recuperação de ofensiva (jun/2026) — https://www.androidauthority.com/p-3673004/
- Resumo da teleconferência do 2º tri/2026 — https://longbridge.com/news/295028818.md
- App Store, Friends Quests — https://apps.apple.com/id/iphone/story/id1688543383
- Duoplanet, missões e selo mensal — https://newsletter.duoplanet.com/posts/how-many-quests-duolingo
- Deceptive Design, reparo de ofensiva — https://www.deceptive.design/articles/when-a-user-uses-duolingo-on-a-series-of-consecutive-days-this-is-called-a-streak-if-users-miss-a-day-they-can-pay-to-repair-it
- Medium, "Duolingo needs to chill" — https://debugger.medium.com/duolingo-needs-to-chill-8f1832745ca0
- University XP, tom passivo-agressivo — https://www.universityxp.com/news/2025/7/25/we-havent-seen-you-in-a-while-duolingos-passive-aggressive-strategy-for-keeping-users-hooked

**Plataforma**
- Android — permissão de notificação — https://developer.android.com/develop/ui/views/notifications/notification-permission
- Android — canais — https://developer.android.com/develop/ui/views/notifications/channels
- Android — alarmes — https://developer.android.com/develop/background-work/services/alarms/schedule
- Android — princípios de háptica — https://developer.android.com/develop/ui/views/haptics/haptics-principles
- Flutter `Durations` (tokens M3) — https://api.flutter.dev/flutter/material/Durations-class.html

**Pesquisa**
- Lally et al. (2010), *European Journal of Social Psychology* 40(6) — https://doi.org/10.1002/ejsp.674
- Sharif & Shu (2019), *OBHDP* — https://anderson-review.ucla.edu/wp-content/uploads/2021/03/Sharif-Shu_EmergencyReserveFailure_OBHDP2019.pdf
- Silverman & Barasch (2023), *JCR* 49(6) — https://doi.org/10.1093/jcr/ucac029
- Kivetz, Urminsky & Zheng (2006), *JMR* 43(1) — https://business.columbia.edu/sites/default/files-efs/pubfiles/1200/goalgradient.pdf
- Nunes & Drèze (2006), *JCR* 32(4) — resumo em https://knowledge.wharton.upenn.edu/podcast/knowledge-at-wharton-podcast/the-lowdown-on-customer-loyalty-programs-which-are-the-most-effective-and-why/
- Dai, Milkman & Riis (2014), *Management Science* — https://faculty.wharton.upenn.edu/wp-content/uploads/2014/06/Dai_Fresh_Start_2014_Mgmt_Sci.pdf
- Ryan & Deci (2000), *American Psychologist* — https://doi.org/10.1037/0003-066X.55.1.68
- Ryan, Rigby & Przybylski (2006), *Motivation and Emotion* — https://doi.org/10.1007/s11031-006-9051-8
- Deci, Koestner & Ryan (1999), *Psychological Bulletin* — https://doi.org/10.1037/0033-2909.125.6.627
- Kushlev, Proulx & Dunn (2016), CHI — https://www.interruptions.net/literature/Kushlev-CHI16.pdf
- Fitz et al. (2019), *Computers in Human Behavior* — https://scholars.duke.edu/publication/1402953
- Eyal, N. (2014), *Hooked* (livro) — referência conceitual, sem número citado

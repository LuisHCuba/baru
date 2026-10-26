# Auditoria independente: reauditoria dos itens 7 e 8, e item 12 (notificações). Commit `8422e9c`

Não participei do código. Verifiquei tudo num worktree descartável do commit
`8422e9c` (`/tmp/claude-0/aud12`, removido no fim), fora da árvore em que
outra pessoa trabalha. Copiei `.env.example` para `.env` e
`.flutter-plugins-dependencies` da árvore principal, e rodei
`flutter pub get --offline`. As referências `arquivo:linha` são de
`baru_app/` nesse commit. As imagens estão em
`docs/auditoria/onda-2-reauditoria-e-item-12/`.

Antes de começar, li `docs/auditoria/onda-2-item-7-e-sons.md` e
`onda-2-item-8.md` (com as "Respostas às ressalvas"),
`docs/pesquisa/01-ux-retencao-duolingo.md` §4.3 e §9 (9.1–9.6),
`docs/DECISIONS.md` (ADR-025) e `docs/PRODUCT.md` §1–2.

## Resumo

| Frente | Veredito |
|---|---|
| 1. Reauditoria dos itens 7 e 8 | **APROVADO COM RESSALVAS**. R1–R6, 7.1, 3.1, 3.2, 1.1, 4.1 e 6.1 estão feitos e funcionam no cenário original. Ficam três ressalvas: a correção do S1 provavelmente não resolve o defeito (só o aparelho confirma); o novo "voltar" abriu um caminho de erro; e a correção do R3 deixou um caso espelhado |
| 2. Item 12, notificações | **APROVADO COM RESSALVAS**. A reprogramação ao concluir a sessão, os canais, as rotas, a janela de 8 a 21 h e o texto de amanhã com o estado de amanhã funcionam. Há quatro problemas médios: aviso durante ou depois de uma sessão concluída fora do app; o aviso de amanhã nunca sai na configuração padrão; "Senti sua falta" é disparado na abertura; e uma combinação de texto que faz o bicho "quebrar" |

Problemas altos e médios:

| # | Sev. | Frente | Problema |
|---|---|---|---|
| S1' | **alta (provável, só o aparelho confirma)** | 1 / som | As três vozes não resolvem o S1. No `audioplayers_android` 5.2.1 em `lowLatency`, um player que já tocou fica com `playing=true` para sempre, porque o SoundPool não avisa quando o som acaba. O `resume` seguinte não faz nada. Pela leitura do plugin, cada processo toca no máximo 3 sons (um por voz). Daí em diante tudo fica mudo, até que algum `para()` dê `stop` |
| V1 | média | 1 | "Voltar" numa celebração que pede cavar e ainda não foi cavada dispara a asserção "Looking up a deactivated widget's ancestor is unsafe" (`celebracao.dart:142`, `_c` *lazy* criado no `dispose`). O auditor anterior não tinha achado um caminho real para isso. O R1 o criou |
| V2 | média | 1 | Com a cena sobre a tela de resultado (`[home, result]`), o 1º "voltar" não fecha a cena: ele tira a tela de resultado de baixo dela (`navegacao.dart:290`). Só o 2º fecha a cena. A pessoa perde a E3 e a colheita ali sem ver |
| R3' | média (borda) | 1 | Sessão de 23:40 a 00:05 com o app fechado: a cena "cresceu **hoje**" acende, mas a presença vai para **ontem** e hoje fica sem presença (`state.dart:2140`) |
| N1 | média | 2 | `startSession` não cancela o aviso da raiz de hoje. Uma sessão das 20:45 às 21:10 recebe "Sua raiz… quebra à meia-noite" às 21:00, no meio do foco. Se a sessão terminar com o processo parado (morto ou CPU dormindo), o aviso chega com o dia já feito |
| N2 | média | 2 | Na configuração padrão (relatório ligado às 21 h), o aviso de amanhã **nunca** é agendado (`state.dart:1615`). Sem hábito, o convite também nunca existe. A correção do A6 não chega a quem não mexeu nos ajustes, e quem está ausente perdeu o aviso de amanhã que tinha antes deste commit |
| N3 | média | 2 | "Senti sua falta / Nina sentiu sua falta hoje" é postado **na abertura** do app, depois de ≥ 2 dias fora (`notification_service.dart:1014-1027`). Chega justamente quando a pessoa voltou, e com o tom de cobrança que o laudo 01 (A9, §4.3 regra 2) pede para tirar |
| N4 | média | 2 | Combinação de texto: "Nina deixou a terra regada" + "Faltam 2 dias para o marco de 7. **Ela quebra à meia-noite.**" Lido assim, quem quebra é o bicho. Medido no canal (cenário A). Acontece num terço das vésperas de marco. Em en/es/zh o sujeito também fica ambíguo |

---

## Comandos executados (no worktree de `8422e9c`)

```
$ flutter analyze --no-pub
No issues found! (ran in 5.4s)

$ flutter test --no-pub
01:56 +1075 ~26: All tests passed!
```

Também escrevi três testes temporários, apagados junto com o worktree:

- `zz_aud12_notif_test.dart` registra o `AndroidFlutterLocalNotificationsPlugin`, finge o canal
  `dexterous.com/flutter/local_notifications` e o de permissões, e imprime
  cada `zonedSchedule`, `show`, `cancel` e `createNotificationChannel` reais.
  O fuso do processo e o `tz.local` foram `Europe/Moscow` (UTC+3), para o
  relógio real do teste marcar ~20:20 de uma segunda-feira, 26/10.
- `zz_aud12_cenas_test.dart` monta o `BaruApp` inteiro ou a `CenaDaRaiz` isolada, com fontes
  Nunito, e finge os canais do `share_plus` e do `path_provider`.
- `zz_aud12_estado_test.dart` cobre R3, R5 e 7.1 no `AppState`.

Não havia aparelho nem emulador. Nada nativo foi executado.

---

## Frente 1: reauditoria dos itens 7 e 8

**Veredito: APROVADO COM RESSALVAS.**

### Item 7

**R1 (alta): corrigido. Também abriu dois caminhos novos (V1, V2).**

A parte de baixo da cena virou `SingleChildScrollView`
(`cena_da_raiz.dart:247`), e `AppState.voltar` fecha qualquer cena
(`state.dart:1239`).

- **App inteiro, 360×640.** O `AppFrame` limita a fonte a 1,25
  (`app_frame.dart:50`), então "1,3" e "2,0" viram 1,25. O botão começa
  abaixo da dobra: `bottom = 700,6` com viewport até 640 no marco, e
  `652,6` no dia comum. `scrollUntilVisible` o alcança e o toque fecha a
  cena (`raizACelebrar=null`) em pt e es, no marco e no dia comum. Nenhum
  `RenderFlex overflowed`.
- **Cena isolada sem o limite (o cenário do auditor anterior).** Fonte 1,3
  pt/marco e 2,0 es/marco e pt/comum, a 360×640: zero transbordamento, e o
  botão é alcançado rolando
  (`r1-isolado-360x640-es-7d-fonte2.0.png` → `…-rolado.png`).
- **Baixa:** no primeiro quadro nada indica que dá para rolar. Só o texto
  cortado ("Eso solo lo construye el…") sugere que há mais.

Duas consequências novas do R1:

- **V1 (média): "voltar" numa celebração com toca dispara uma asserção.**
  - Reprodução: subi de nível com a toca na tela (`toca=1`) e chamei
    `handlePopRoute`. `celebrou()` marcou o nível como celebrado, a toca saiu
    e o `dispose` criou o `AnimationController` *lazy*
    (`celebracao.dart:60`, `:142`). Resultado: *"Looking up a deactivated
    widget's ancestor is unsafe"*.
  - O mesmo acontece no marco da trilha.
  - **Prêmio não se perde:** `celebrou()` não credita nada, e as folhas do
    marco já entram em `_colheMarcos`. No teste, `folhas=137` antes e
    depois. Perde-se só o ritual que o próprio widget promete
    (`celebracao.dart:104-106`: "quem está cavando não pode perder o prêmio
    por encostar fora do buraco"). Em *release* a asserção não roda; o
    efeito ali não foi verificado.
  - *Correção:* em `dispose`, não tocar em `_c` se ele nunca foi criado
    (guardar um `bool`, ou criar no `initState`). Decidir se o "voltar" deve
    abrir a toca (revelar e creditar à vista) em vez de descartá-la.
- **V2 (média): o 1º "voltar" tira o resultado de baixo da cena.**
  - `popRoute` dá preferência ao `Navigator` (`navegacao.dart:290`): com
    pilha `[home, result]`, `canPop` é verdadeiro.
  - Medido: antes, `pilha=[home, result] raiz=5 cena=1`; 1º voltar,
    `pilha=[home] raiz=5 cena=1`; 2º voltar, `raiz=null cena=0`
    (`voltar-1x-cena-continua-resultado-sumiu.png`).
  - Não prende ninguém, mas o gesto tem efeito escondido: a E3 e o "Colher"
    da tela de resultado somem.
  - *Correção:* em `popRoute`, verificar a celebração pendente **antes** de
    `nav.canPop()`.

**R2 (média): corrigido.** No marco, tocar "Compartilhar minha raiz" mandou
pelo canal do `share_plus`: `method=share`, `text="Construída com Nina, no
Baru."`, `paths=[…/habitat.png]`, `mimeTypes=[image/png]` (PNG de 18 979
bytes; `r2-cartao-compartilhado.png`, com "7 / dias presente" e a raiz com
galhos). Baixa (texto anterior a este commit): "7 dias presente" deveria
concordar ("presentes").

**R3 (média): corrigido no cenário original, com um caso espelhado aberto
(R3').**

- *Original:* sessão das 22:30 às 22:55 de ontem, app aberto hoje. Saiu
  `raizACelebrar=null`, `streak=5`, `completedToday=0`, tela `home`.
- **R3' (média, borda):** sessão das 23:40 de ontem às 00:05 de hoje, com o
  app fechado.
  - Saiu `raizACelebrar=5`, `screen=result`, `completedToday=0` e
    `ultimos7=[…, present, today]`.
  - Ou seja, a cena diz "cresceu hoje" e a faixa força o ✓ em hoje
    (`_Faixa`), mas a presença foi contada para **ontem**: a sessão entra no
    dia de `lastOpenDate`, antes de `applyCalendar`.
  - O mesmo vale para o app aberto atravessando a meia-noite (`_tick`), e
    hoje à noite o aviso "raiz em risco" pode sair.
  - *Correção:* concluir a sessão no dia de `em` (avançar o calendário até
    `dateOnly(em)` antes de somar) ou, no mínimo, comparar `dateOnly(em)`
    com `dateOnly(lastOpenDate)`.

**R4 (média): corrigido.** Coruja no ovo, 1ª sessão: `estagio=filhote` e
`estagioJaVisto=inicio`, e o `PetView` da cena recebe `inicio`
(`r4-ovo-cena-da-raiz.png`).

**R5 (média): corrigido.** Simulei 16 dias seguidos, uma quebra de 2 dias
(`recordeAnterior=16`) e uma nova raiz de 19 dias.

- "Recorde" aparece **uma vez**, aos 17 dias da segunda raiz.
- Antes disso as linhas variam: "Faltam N dias para o próximo galho" e as
  cinco que se revezam.

Residual **baixo:** `recordeAnterior` só existe no aparelho, e quem já tinha
uma raiz quebrada antes desta versão começa com 0. Para essa pessoa o
recorde só volta depois da próxima quebra. Reinstalar o app também zera o
valor.

**R6 (média): corrigido.** Com "reduzir movimento", no app inteiro:
`inicio@0, fim@0, folhas@50, raiz@300`. A raiz toca.

**S1 (média → S1', alta provável): a correção declarada não resolve, pela
leitura do plugin.** `som_service.dart:296-314` cria até 3 `AudioPlayer` e
depois os reusa em rodízio (`:305`), sempre com `play` e sem `stop` antes.
Em `audioplayers_android-5.2.1`:

- `WrappedPlayer.play()` só age se `!playing`
  (`player/WrappedPlayer.kt:211-219`);
- `playing` só volta a `false` em `pause`, `stop`, `release` ou
  `source = null` (`:30-38`, `:263-268`), e trocar a fonte não o zera;
- `onCompletion` só existe no `MediaPlayerWrapper`
  (`MediaPlayerWrapper.kt:17`); o `SoundPoolPlayer` (modo `lowLatency`) não
  tem evento de fim, e `reset()` é um TODO vazio
  (`SoundPoolPlayer.kt:194-196`).

Consequência provável: cada voz toca **o primeiro som** que recebe, e os
seguintes são ignorados até um `SomService.para()` (pular a cena da raiz).
Na prática, o processo tocaria os três primeiros sons (ex.: `inicio`, `fim`,
`folhas`) e depois ficaria mudo. A versão de um player só tinha o mesmo
defeito, com um som.

**Não verifiquei em aparelho.** O teste do app troca o `tocador` e não
exercita o plugin. *Correção:* `await p.stop()` antes de cada `play`, ou o
`AudioPool` do próprio `audioplayers`, ou `PlayerMode.mediaPlayer`.
Verificar com `AudioLogger.logLevel = AudioLogLevel.info` tocando 5 sons
seguidos. Continua valendo a parte do S1 original de que `para()` corta
**todas** as vozes: pular a cena entre 600 e 1900 ms ainda corta a cauda do
`fim`. Baixa.

**Baixos declarados:** conferi três.

- O rótulo acompanha o número (`cena_da_raiz.dart:236-240`).
- Sem gota com movimento reduzido (`:194-195`).
- "Falta pouco para nascer" saiu sem gênero.

Não conferi visualmente a gota no modo reduzido.

### Item 8

**7.1 (alta): corrigido.** A tela gravada como `result` reabre em `home`, com
`pilha=[home]` e `aborted=false`.

**3.1 (média): corrigido.** O fecho fica em `y = 381–427` de 892, logo abaixo
do XP, antes das missões (`item8-resultado-fecho-e-saldo.png`).

**3.2 (média): corrigido como foi declarado** (`result_screen.dart:389-393`):
"Dia feito" exige `completedToday ≥ 1`, principal ok e
`missoesResgataveis == 0`. Sem permissão de uso, a principal conta como
"indisponível = ok". Isso é uma decisão, coerente com o texto da resposta.

Ressalva baixa: logo depois da sessão, o fecho diz "Próximo: 'Foque em 2
períodos…' (1/2), +22 folhas", com "Faça uma sessão de foco — Pronta para
colher [Colher]" logo abaixo. O passo mais perto de fechar é colher, e o
fecho sugere outro.

**1.1 (média): corrigido.** O selo chega a `app.leaves`: 192 =
137 + 10 + marcos `primeiro_foco` e `primeiro_dia_abaixo`.

Ressalva baixa: durante a E1, a pílula diz "+10 folhas" enquanto o selo sobe
55. A explicação (as cenas dos marcos) só vem depois.

**4.1 (média): corrigido no retrato e no "Colher tudo".** A retomada entra em
`quadro()` (`state.dart:2121`) e no `_ColherTudo`
(`missoes_screen.dart:165-175`).

Residual baixo: o sufixo do bloco "A colher" ainda conta só `aColher.length`
(`:160`). Com 1 missão + a retomada, o bloco diz "1 para colher" e o cartão
logo abaixo diz "Colher as 2".

**6.1 (média): corrigido.** "No habitat a partir de agora: {i}." nos 4
idiomas. `compraSubRoupa` ficou como estava; era baixa.

**8.1: corrigido** pela isenção dos sons de cena: `folhas@50` depois de
`fim@0`, no modo reduzido.

---

## Frente 2: item 12, notificações

**Veredito: APROVADO COM RESSALVAS.**

### O que funciona (medido no canal do plugin)

**Concluir a sessão com o app aberto cancela o aviso de hoje.**

- Cenário A: padrão, raiz de 5 dias, ausente, sem congelamento, 20:21.
  Antes: `SCHEDULE 1007 21:00 canal=baru_raiz payload=home`. Depois de
  concluir: `CANCEL 1007` e `CANCEL 1008`.
- Cenário B: relatório desligado. Depois de concluir, o convite vai para
  amanhã às 19:00 (`pulaHoje`).
- Isto cumpre os itens (a) e (b) do critério de aceite do laudo 01 §9.6, para
  a sessão concluída em primeiro plano.

**Janela de 8 h a 21 h.** O convite fica em `clamp(8, 21)`
(`descanso_retencao.dart:354`) e a raiz entre 19 e 21 h. O relatório é
escolhido pela pessoa (0–23 h): fora da regra, por decisão dela.

**Aviso de amanhã com o estado de amanhã:**

- presente hoje (C): "Sua raiz de **5** dias", com o número certo para
  amanhã;
- ausente (B, D, H): sem número ("Nina guardou um lugar para você — Uma
  sessão de foco hoje faz a raiz crescer.");
- segunda-feira: a regra prevê 1 congelamento amanhã, e isso confere com
  `_advanceDay`, que julga o domingo antes de recarregar (`state.dart:2347-2366`).
  Não deu para medir com relógio de domingo (o teste usa o relógio real, que
  marcava segunda).

**Congelamento.** Cenário D: "Seu congelamento entra hoje — A raiz de 5 dias
continua.", verdadeiro se a pessoa não aparecer. É um desvio do §9.3, que
pede que o congelamento não gere aviso próprio; ver N9.

**Canais.**

- `init` apaga `baru_reminders` e cria os 6 de recado, mais `baru_sessao`.
- `nomeiaCanais` os renomeia a cada sincronização: pt "Sessão concluída /
  Raiz / Convite do dia / Relatório da noite / Quando você está longe /
  Conta e assinatura", e o equivalente em en, es e zh, medido.
- Todo `AndroidNotificationDetails` aponta para um canal criado no `init`:
  `_detalhesDeLembrete(canal)` em `:905` e `canalSessao` em `:568`. Nenhum
  aponta para canal inexistente.
- Recriar com o mesmo id só troca nome e descrição; o plugin só cria o canal
  no `show`/`schedule` se ele não existir (`FlutterLocalNotificationsPlugin.java:455-473`).
- Os agendamentos antigos no canal apagado são refeitos na primeira
  sincronização, com os mesmos ids (1001, 1003, 1006–1008).

**Rotas.**

| Aviso | Rota |
|---|---|
| raiz, volta, conta | `home` |
| convite | `missoes` |
| relatório | `report` |

- Um toque com a sessão em andamento é ignorado: a tela continua `session`.
- No onboarding também é ignorado (`companionshipStarted=false`).
- No resultado, `missoes` substitui a pilha.
- No arranque a frio, a rota espera em `_rotaPendente` até o `AppState`
  ligar.

**Textos nos 4 idiomas:** nenhum placeholder cru (teste do commit e saída
real). O giro troca o texto a cada dia.

### Problemas

**N1 (média): a sessão não silencia o aviso de hoje.** `startSession`
(`state.dart:2002`) não toca em `raizHojeId` (cenário G: nenhum `CANCEL 1007`
ao começar).

- **Durante a sessão (determinístico):** sessão das 20:45 às 21:10. Às
  21:00 o recado "Sua raiz de N dias — Ela quebra à meia-noite" toca no meio
  do foco, num canal com som.
- **Depois (depende do processo):** o cancelamento depende de o `_tick` em
  Dart rodar antes das 21:00. Com o processo morto (sem a permissão de
  sobreposição não há serviço em primeiro plano), ou com a CPU dormindo, o
  aviso chega com o dia já cumprido. Essa é a mentira que o A5 queria
  eliminar.

O roteiro de aparelho do §9.6 ("concluir foco às 20h, fechar o app") só
cobre o caso em que o app viu a conclusão. *Correção:* cancelar `raizHojeId`
(e adiar o convite) em `startSession`, e reagendar em `abandon`.

**N2 (média): na configuração padrão, o aviso de amanhã não existe.**
`state.dart:1611-1617` descarta o aviso de amanhã se ele cair a menos de 3 h
do convite ou do relatório. Instalação nova vem com relatório às 21 h
(`app_snapshot.dart:278`, `state.dart:610-613`), e a hora da raiz é sempre de
19 a 21 h. A conta dá sempre menos de 3 h, então `textoDeAmanha = null` para
todo usuário padrão (cenário A: `CANCEL 1008` antes e depois).

Pelo mesmo motivo, sem hábito o convite das 19 h nunca cabe:

- com risco hoje, ele é **cancelado**, e o convite repetido some até a
  próxima abertura;
- presente hoje: também `CANCEL 1006` no cenário A.

Antes deste commit, quem estava ausente recebia o aviso de amanhã (com o
número errado). Agora não recebe nada além do relatório. O A6 só alcança
quem desligou o relatório ou tem hábito até 16 h (cenários B, C, H).

*Correção:* se o aviso de amanhã é a rede de quem não vai abrir o app, ele
deveria substituir o relatório naquele dia, ou ir para um horário que caiba,
em vez de sumir. Outra saída: decidir com o dono e registrar no ADR que,
com o relatório ligado, não há aviso de amanhã.

**N3 (média): "Senti sua falta" chega quando a pessoa volta.**
`_maybeShowMissed` faz `show` imediato (`notification_service.dart:1014-1027`),
e `syncSchedules` só roda com o app aberto. Cenário F (3 dias fora):
`SHOW id=1002 canal=baru_volta | Senti sua falta — Nina sentiu sua falta
hoje.` na abertura.

- O canal "Quando você está longe" só toca quando a pessoa **não** está
  longe.
- O texto é a cobrança que o laudo 01 (A9; §4.3 regra 2: o bicho não "sente
  falta" como cobrança) e o `PRODUCT.md` §1 ("nunca culpa") pedem para tirar.

É anterior a este commit, mas está no escopo de "nenhuma notificação
mente". *Correção:* agendar a escada de ausência ao sair do app (§9.6, ids
1100–1110, ainda não feita) e nunca postar na abertura. Trocar o texto por
um da lista "Volta" do §9.4.

**N4 (média): o sujeito do texto vira o bicho.**

- Na véspera de marco, o corpo é sempre `raizRiscoMarco` ("… Ela quebra à
  meia-noite.", `l10n_descanso.dart:36-37`), mas o título gira.
- Com o título 3, "{p} deixou a terra regada" (`:47`), sai "Nina deixou a
  terra regada — Faltam 2 dias para o marco de 7. Ela quebra à meia-noite."
  (medido, cenário A).
- es: "Nina dejó la tierra regada — … Se rompe a medianoche."; en: "Nina
  watered the soil — … They break at midnight."; zh: "它会在午夜断掉".

*Correção:* nomear a raiz no corpo ("A raiz quebra à meia-noite") ou girar
título e corpo do marco em par.

Também em `raizRiscoMarco`: com 1 dia para o marco (raiz de 6 dias), sai
"Faltam **1 dias**" / "**1 days** to the 7-day mark" / "Faltan **1 días**"
(baixa, anterior ao commit).

### Baixos

- **N5: o teto conta só retenção.** O relatório ocupa hora mas não entra no
  teto de 2. Cenário C (hábito às 12 h, relatório às 9 h): amanhã são **3**
  recados, às 9, 12 e 19 h. Hoje pode acontecer o mesmo
  (`descanso_retencao.dart:326-369`). E, por desenho, raiz que vai quebrar +
  relatório saem **no mesmo minuto** (21:00) na configuração padrão
  (`:333`), contra o "3 h entre eles" do §9.3.
- **N6: convite sem permissão de uso.** Sem acesso ao uso (cenário E), o
  convite do descanso é agendado ("Um respiro longe da tela? Nina está
  esperando para descansar com você.") e leva a uma missão que mostra "Sem o
  acesso ao uso eu não sei se o telefone ficou parado". O plano não olha
  `missaoDoDescanso.disponivel` (`state.dart:1576`).
- **N7: rotação e payload.**
  - O texto gira só quando o app abre. O convite repetido
    (`matchDateTimeComponents.time`) repete o mesmo texto todo dia para quem
    não abre.
  - São 3 variações por tipo: o critério (d) do §9.6 ("não se repete em 5
    envios") não é atendido.
  - O `payload` leva só a rota, sem o id do modelo, então não dá para medir
    abertura por modelo (§9.5).
  - O aviso de sessão concluída (`agendaFimDaSessao`) vai sem `payload`, e o
    critério (e) pede `payload` em todos.
  - No réveillon o giro repete (364+2026·7 ≡ 0+2027·7 mod 3). Com horário de
    verão, `inDays` pode repetir um dia.
- **N8: idioma.**
  - O canal da sessão se chama "Sessão de foco" em pt para todos
    (`notification_service.dart:336`, `:568`), e o comentário do Kotlin
    (`VigiaDaSessao.kt:546`) diz o contrário.
  - `setLang` (`state.dart:1308`) não reprograma: nomes de canal e textos
    agendados ficam no idioma antigo até a próxima volta ao app.
- **N9: congelamento com aviso próprio.** O §9.3 diz "com congelamento, o
  convite carrega a informação e este não sai". O app manda "Seu
  congelamento entra hoje" quando cabe. O texto é verdadeiro. O desvio não
  está no ADR-025.
- **N10: toque descartado.** Uma rota tocada durante a sessão ou o
  onboarding é descartada, não guardada para depois. Aceitável.
- **"Quebra à meia-noite" ainda existe**, em `raizRiscoCorpo` (1 de 3
  variações) e em `raizRiscoMarco` (sempre, na véspera).
  - **Avaliação:** aceitável como fato. Ele segue a regra 1 do §4.3 (fato +
    ação mínima + tempo, "Uma sessão curta segura"), não acusa e não usa
    palavra proibida, e a raiz de fato zera (`PRODUCT.md` não tem "raiz
    adormecida", e o ADR-025 diz isso).
  - É, porém, enquadramento de perda, que os exemplos do §9.4 evitam ("ainda
    pode crescer hoje"). Agrava o N4.
  - Recomendo deixar só as variações 2 e 3 ("ainda cresce hoje") e dizer a
    meia-noite sem o verbo quebrar.

### O que só o aparelho confirma

- **N1:** se o `_tick` roda entre o fim da sessão e as 21:00 com a tela
  desligada (com e sem o serviço do vigia), e o horário real de entrega dos
  alarmes inexatos (até +1 h).
- Renomear os canais e apagar `baru_reminders` nos ajustes do sistema, e
  se um agendamento antigo dispara entre a atualização e a primeira
  abertura.
- Abrir a rota a partir do arranque a frio (`getNotificationAppLaunchDetails`)
  e com o app em segundo plano.
- **S1':** se o 4º som em diante toca.
- **V1 em *release*.**
- Textos em chinês na tela: o `flutter_tester` não tem fonte CJK.

## O que não verifiquei

- iOS (níveis de interrupção, `DarwinNotificationDetails`).
- O cenário de domingo, com relógio real de domingo.
- A sincronização com o Supabase de `recordeAnterior`: ele é só local, por
  desenho, e o merge usa o maior.
- TalkBack.

## Arquivos de evidência

`docs/auditoria/onda-2-reauditoria-e-item-12/`:

| Arquivo | Conteúdo |
|---|---|
| `r1-app-360x640-*.png` | cena no app inteiro (fonte limitada a 1,25), antes de rolar |
| `r1-isolado-360x640-*.png`, `*-rolado.png` | cena isolada com fonte 1,3 e 2,0: antes e depois de rolar até o botão |
| `voltar-1x-cena-continua-resultado-sumiu.png` | V2 |
| `r2-cartao-compartilhado.png` | o PNG que chegou ao canal do `share_plus` |
| `r4-ovo-cena-da-raiz.png` | coruja no ovo na cena da raiz |
| `item8-resultado-fecho-e-saldo.png` | fecho à vista e saldo real (192) |

---

## Resposta às ressalvas (implementador)

Todas as altas e médias foram tratadas. Cada correção tem teste que falha sem
ela, salvo S1', que depende do plugin nativo.

| Achado | O que mudou | Prova |
|---|---|---|
| **S1'** (alta) | `som_service.dart`: `await p.stop()` antes de cada `play`. Conferi no código do `audioplayers_android` 5.2.1: `WrappedPlayer.play()` só age com `!playing`, e só `pause`/`stop` zeram a flag; `stop()` chama `pause()` e depois `seekTo(0)`, que no `SoundPoolPlayer` zera o `streamId`, e o `start()` seguinte toca de novo. | **Não verificado em aparelho**: este ambiente não tem KVM para emulador. Fica para o teste em aparelho (5 sons seguidos com `AudioLogger.logLevel = info`). |
| **V1** | `celebracao.dart`: o `AnimationController` nasce no `initState`, não preguiçoso. | `test/cena_e_voltar_test.dart` (V1) falha sem a correção com "Looking up a deactivated widget's ancestor". |
| **V2** | `navegacao.dart`: `popRoute` fecha a cena antes de deixar o `Navigator` tirar uma página (`app.cenaNaFrente`). | `test/cena_e_voltar_test.dart` (V2): a tela de resultado continua e a raiz fecha. |
| **R3'** | `state.dart`: a cena "cresceu hoje" só acende quando a presença é contada hoje (`lastOpenDate == hoje`). A sessão das 23:40 às 00:05 com o app fechado conta para ontem e não ganha cena. | `test/session_test.dart` ("cruza a meia-noite"), falha sem a correção. |
| **N1** | Sessão em curso conta como presente para os avisos; `startSession` e a desistência ressincronizam a agenda. | Leitura do código; o caminho do processo morto continua só verificável em aparelho. |
| **N2** | Convite sem hábito passa a 17h (cabe a 3 h do relatório das 21h); o aviso da raiz nunca cai na hora do relatório (vai para 20h); o aviso de amanhã segue a regra de hoje: a raiz que vai quebrar passa mesmo colada no relatório. | `test/notificacoes_test.dart` (configuração padrão). |
| **N3** | O recado de volta não é mais postado na abertura. Cada abertura o agenda para daqui a dois dias, no horário do convite: só toca se a pessoa sumir, uma vez. Texto novo sem "senti sua falta" nos 4 idiomas ("A beira do lago está quieta / {n} guardou um lugar para você."). | `test/notificacoes_test.dart` (textos). |
| **N4** | "Ela quebra à meia-noite" no texto do marco virou "A raiz quebra à meia-noite" (pt/en/es/zh). | `test/notificacoes_test.dart` (textos). |

**Não tratado agora (baixos):** o teto de 2 por dia continua sem contar o
relatório (num dia de risco podem sair convite, raiz e relatório); convite
sem permissão de uso; rodízio de 3 textos; aviso de fim de sessão sem
payload; nome do canal da sessão fixo em português; `para()` cortando a
cauda do `fim`.

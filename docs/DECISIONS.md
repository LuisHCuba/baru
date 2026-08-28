# Decisões de arquitetura (ADRs)

Ordem cronológica. Formato: Contexto / Decisão / Alternativas descartadas /
Consequências e como reverter.

---

## ADR-001 — Colocar o projeto sob git antes de qualquer mudança (2026-08-26)

**Contexto.** O diretório `C:\LHCX\baru` não era um repositório git: nenhum
histórico, nenhuma forma de reverter. O repositório remoto
`github.com/LuisHCuba/baru` existia, público e vazio.

**Decisão.** `git init` na raiz (englobando `Baru App v2.dc.html` e `baru_app/`),
commit de baseline sem mudança funcional, branch de trabalho
`night/2026-08-26`, push de `main` e da branch.

**Alternativas descartadas.** Iniciar git dentro de `baru_app/` — quebraria a
referência `../Baru App v2.dc.html` que o GO_LIVE usa como fonte de verdade de
UI. Trabalhar sem git — inaceitável antes de mexer em schema.

**Consequências.** Ciclos passam a ser reversíveis. O repositório é **público**:
qualquer coisa commitada é publicada. Reverter: `git remote remove origin` e
apagar `.git/` restaura o estado anterior sem tocar nos arquivos.

---

## ADR-002 — Adotar `rls_auto_enable()` em migration em vez de removê-la (2026-08-26)

**Contexto.** O banco real tem `public.rls_auto_enable()`, um event trigger
`SECURITY DEFINER` que habilita RLS automaticamente em toda tabela nova criada
no schema `public`. Não está em nenhuma migration do repositório: o schema não
é reproduzível a partir do repo, o que o §5 do mandato proíbe. O linter do
Supabase sinaliza que `anon` e `authenticated` têm `EXECUTE` sobre ela.

**Decisão.** Adotar: migration que recria a função e o event trigger de forma
idempotente, mais `revoke execute ... from public, anon, authenticated`. A
função é uma rede de segurança útil — mantém a garantia de RLS mesmo se uma
migration futura esquecer o `enable row level security`.

**Alternativas descartadas.** (a) `drop function` — removeria uma proteção real
e mexeria em objeto que o humano pode ter criado de propósito; destrutivo.
(b) Ignorar a divergência — deixaria o banco irreprodutível.

**Consequências.** Um banco limpo criado a partir das migrations passa a ser
igual ao remoto. O `revoke` fecha o aviso do linter sem alterar comportamento
(funções que retornam `event_trigger` não são chamáveis por RPC). Reverter:
`grant execute on function public.rls_auto_enable() to authenticated, anon`.

---

## ADR-003 — Migrations idempotentes por SQL dinâmico (2026-08-26)

**Contexto.** A migration 5 (`..._migrate_and_slim_profiles.sql`) protege cada
`insert` com `where exists (select 1 from information_schema.columns ...)`. O
guard não funciona: as colunas legadas aparecem na lista de `select`, então o
comando falha no **parse** quando elas já foram removidas. Reexecutar a
migration — fluxo documentado no próprio README ("SQL Editor, um arquivo por
vez") — quebra com `column "species" does not exist`.

**Decisão.** Reescrever os blocos legados da migration 5 dentro de
`do $$ ... execute format(...) ... $$`, para que a checagem de existência
aconteça em tempo de execução e o SQL só seja compilado quando as colunas
existirem.

**Alternativas descartadas.** (a) Deixar como está e documentar "rode só uma
vez" — frágil, e o §10 exige que as migrations apliquem do zero. (b) Dividir em
duas migrations (migrar / contrair) — correto pelo expand→migrate→contract, mas
a contração já foi aplicada no remoto; dividir agora criaria divergência nova.

**Consequências.** As 5 migrations passam a ser reexecutáveis em qualquer ordem
de reaplicação. O SQL fica menos legível. Reverter: restaurar o arquivo pelo
histórico do git.

---

## ADR-004 — Remover e-mail pessoal do repositório público (2026-08-26)

**Contexto.** `supabase/README.md` documentava a conta de teste com o e-mail
pessoal do dono. O remote é público.

**Decisão.** Substituir por ponteiro para `supabase/SEED_TEST_USER.local.md`
(gitignored) **antes** do primeiro commit, para que o dado nunca entre no
histórico. Manter no repositório a URL e o ref do projeto Supabase: são
descobríveis em qualquer binário do app e estão protegidos por RLS verificada.

**Alternativas descartadas.** Commitar e limpar depois — histórico público é
indexável; limpar exigiria reescrever histórico, proibido pelo §4.

**Consequências.** O README público perde a informação de qual conta usar; quem
tem o repo clonado localmente continua com o arquivo local. Reverter: não deve
ser revertido.

---

## ADR-005 — Bônus de meta é pago na virada do dia, não durante o dia (2026-08-26)

**Contexto.** O contrato de produto §5 prevê "+15 por fechar o dia abaixo da
meta". A quest na home e a linha "Bônus por ficar abaixo" no relatório já
exibiam +15, mas nenhum código creditava folhas: a promessa era decorativa.

**Decisão.** Creditar em `_advanceDay`, no fechamento do dia, quando
`companionshipStarted && usageAccess && usage < goal`. O aviso ao usuário sai no
primeiro frame seguinte, via `flushPendingNotices()`.

**Alternativas descartadas.** (a) Creditar assim que a condição fosse verdadeira
durante o dia: o tempo de tela começa em zero, então o bônus cairia todo dia de
manhã e não significaria nada. (b) Creditar durante o dia e estornar se o uso
passasse da meta: proibido pelo §1 do contrato — o usuário nunca perde nada.

**Consequências.** O bônus chega no dia seguinte, o que dá ao relatório da noite
um motivo para existir. Dias de ausência longa não pagam: só o primeiro
`_advanceDay` de um avanço recebe `creditBonus`, porque os seguintes têm `usage`
sintético em zero e pagar por eles seria inventar medição. Sem permissão de uso
não há bônus — não há o que medir, e o app não finge. Reverter: remover a
chamada em `_advanceDay`.

Nota relacionada: o "+10" da quest de sessão **não** é um crédito separado — é a
recompensa da própria sessão de 25 min. Pagar de novo seria duplicar.

---

## ADR-006 — Calendário derivado da data, não de contadores (2026-08-26)

**Contexto.** Dois bugs medidos na auditoria, ambos com a mesma raiz — o estado
do calendário era mantido por incremento em vez de ser derivado da data:

1. `_advanceDay` fazia `todayIndex = (todayIndex + 1) % 7` e sobrescrevia só o
   dia corrente. Ao passar de domingo para segunda, os índices 1..6 mantinham as
   marcas da semana anterior. Medido: depois de 7 dias com sessão, a faixa ficava
   `[today, present, present, present, present, present, present]` — dias que
   ainda não aconteceram apareciam como presentes.
2. `applyCalendar` reconstrói no máximo 21 dias. Numa ausência de 30 dias o
   índice avançava 21 (≡ 0 mod 7) enquanto a data avançava 30, e o ponto de
   "hoje" passava a apontar o dia errado. Medido: dia real quarta (2),
   `todayIndex` = 0.

**Decisão.** Os índices da faixa passam a sair da data: `_advanceDay(de:, para:)`
usa `weekdayIndex()` das duas pontas. Segunda-feira zera a faixa e recarrega o
congelamento. Ausência acima do teto realinha a faixa com a data real em vez de
reconstruir. `_alinhaHoje()` corrige um snapshot que chegue com índice defasado
— de outro aparelho, outro fuso ou versão antiga.

`daysAway` também deixa de ser contador e passa a ser fato de data:
`hoje - lastOpenDate - 1`. Isso alinha o app ao contrato §3, que define
`missing_you` como "≥2 dias sem abrir": antes o congelamento zerava `daysAway`,
então `missing_you` só aparecia no terceiro dia.

**Alternativas descartadas.** (a) Guardar a data de início da semana e comparar:
mais estado para sincronizar sem ganho — o dia da semana já é derivável.
(b) Zerar a faixa por ISO week em vez de "índice do próximo dia é 0": equivalente
para semanas que começam na segunda, e a semana do Baru começa na segunda por
definição.

**Consequências.** `_advanceDay` passa a exigir as duas datas, então o
`nextDay()` do painel de debug avança `lastOpenDate` junto — o que também torna
o debug mais fiel. Um teste antigo passava por coincidência (fixava
`todayIndex = 2` e rodava numa quarta-feira); foi ancorado numa data fixa.
Reverter: o commit é isolado.

---

## ADR-007 — Falha de sincronização devolve a intenção, não a descarta (2026-08-26)

**Contexto.** `AppState._persistNow()` zerava `_syncMask` **antes** dos pushes e
envolvia os cinco domínios num único `try` com `await` sequencial. Duas
consequências: uma falha no primeiro domínio abortava os quatro seguintes, e a
intenção de sincronizar era apagada — sem retry, sem fila, sem rastro. O dado
sobrevivia no aparelho, mas o remoto ficava permanentemente atrasado até que
aquele mesmo domínio mudasse de novo por acaso.

**Decisão.** Cada domínio ganha `try/catch` próprio. O bit do domínio que
falhou volta para `_syncMask`, então a próxima gravação tenta de novo.
`retryPendingSync()` é chamado quando o app volta do background — o momento em
que a rede costuma ter voltado. O aviso ao usuário sai **uma vez por episódio**
de falha, não por gravação. Um flag `_persisting` impede que o debounce dispare
um segundo envio com um anterior ainda em voo.

**Alternativas descartadas.** (a) Fila persistida de operações pendentes: é a
solução completa, mas exige modelar operação, ordem e deduplicação — grande
demais para o ganho, dado que a máscara já expressa "este domínio está sujo".
(b) Retry com backoff em timer próprio: mais código e mais bateria para cobrir
um caso que a próxima interação do usuário já cobre. (c) `Future.wait` nos cinco
domínios: paralelizaria, mas o gateway compartilha um único cliente e a ordem
importa para o pet (que empurra loja junto).

**Consequências.** Nenhuma mudança de esquema, nenhuma mudança de UI. A máscara
vira a fila de pendências, o que é suficiente enquanto o app for
offline-first-com-um-dispositivo. Se um dia houver multi-dispositivo com
resolução de conflito, isto precisa virar fila de verdade. Reverter: o commit é
isolado.

Efeito colateral bem-vindo: `BaruRepositories` passou a aceitar repositórios
injetados, o que finalmente permite testar falha de rede por domínio.

---

## ADR-008 — A sessão de foco é medida pelo relógio de parede (2026-08-26)

**Contexto.** A sessão era contada por `Timer.periodic`, decrementando um campo
a cada tique. Três consequências, todas no caminho core do produto:

1. Um `Timer` de app suspenso atrasa ou para. O app pede que o usuário largue o
   telefone — ou seja, a sessão bem-sucedida é justamente a que roda em
   background.
2. `didChangeAppLifecycleState(resumed)` não reconciliava `remaining`: voltar
   ao app mostrava o contador congelado no segundo da saída.
3. `_schedulePersist` pulava a gravação enquanto `running`, e `toSnapshot()`
   mapeia `session → home`. App morto no meio da sessão = sessão perdida sem
   recompensa e sem rastro.

**Decisão.** `sessionStartedAt` e `sessionEndsAt` passam a ser estado
persistido. O `Timer` só repinta a tela; quem decide o fim é o relógio.
`reconcileSession()` roda ao voltar do background e o construtor retoma (ou
conclui) uma sessão que atravessou o fechamento do app.

Sessão cujo prazo venceu com o app fechado **conta**: o usuário cumpriu o tempo
longe do telefone, que é exatamente o pedido. Se terminou num dia anterior, ela
é creditada antes do avanço de calendário, então fecha aquele dia como presente
— mas não abre a tela de resultado, que seria sobre um dia já passado.

**Alternativas descartadas.** (a) Notificação agendada para o fim e conclusão só
ao abrir: o app já precisa reconciliar ao abrir de qualquer jeito; a notificação
é complemento, não mecanismo. (b) Serviço em primeiro plano no Android: peso
grande, uma permissão a mais e nada resolve no iOS. (c) Guardar só o fim e
deduzir a duração pela flag de debug 60×: quebra se a flag mudar entre gravar e
ler — encontrado por teste durante a implementação, e o motivo de guardar as
duas pontas.

**Consequências.** A folha de desistência ("está no meio de um banho") deixa de
pausar o relógio: o tempo corre enquanto ela está aberta. É mais honesto — olhar
a folha já é mexer no telefone — e evita usar a folha como pausa infinita.
Sessão em curso é local por natureza (não continua em outro aparelho), então
os dois campos ficam fora do Supabase: **nenhuma migração de schema**.

Ponto em aberto, registrado no backlog: como não há valor real em jogo (sem
IAP), creditar uma sessão longa que venceu com o app fechado é generoso de
propósito. No dia em que houver receita, isto vira validação de servidor.
Reverter: o commit é isolado.

---

## ADR-009 — Tempo de tela é contabilidade, não soma (2026-08-27)

**Contexto.** O app somava `totalTimeInForeground` de todo pacote devolvido por
`queryAndAggregateUsageStats`. Isso conta launcher, system UI, teclado, o
próprio Baru e — o caso que quebra a credibilidade inteira — Spotify tocando
com o celular no bolso. A meta diária é comparada contra esse número; se o
usuário não confia nele, não confia em nada no app.

**Decisão.** Trocar a soma por **reconstrução de intervalos** a partir de
`queryEvents`, os eventos crus do Android. Máquina de estados com três chaves —
tela ligada, aparelho desbloqueado, app em primeiro plano — e um intervalo só
corre quando as três valem. Exclusões fixas para launcher, system UI, teclado,
telas do sistema, discador em chamada e o próprio Baru.

Cada app entra numa categoria de produto: **dispersivo**, **neutro**,
**produtivo** ou **passivo** (áudio). A meta compara apenas dispersivo + neutro.
O usuário pode discordar e reclassificar; a escolha persiste e sincroniza
(tabela `baru_app_categories`, migration 7).

**Alternativas descartadas.** (a) Manter o agregado e subtrair uma lista de
pacotes: não resolve o áudio com a tela apagada, que é o caso principal, porque
o agregado não sabe o estado da tela. (b) Deixar o usuário definir a meta sobre
o total: transfere para ele o trabalho de entender um número errado. (c) Pedir
Digital Wellbeing: não há API pública.

**Consequências.** O estado inicial da máquina é "tela apagada e bloqueado":
sem evidência, não conta. Errar para menos é honesto; errar para mais é a
mentira que estamos consertando. Por isso a consulta pede 12 horas antes da
meia-noite, para o estado real ser estabelecido antes do recorte do dia. O
número que o usuário via vai **diminuir** — e passa a ser auditável na tela
nova, app por app. Sem permissão o app mostra estado vazio com um caminho de um
toque, e não estima nada. Reverter: o commit é isolado.

---

## ADR-010 — Missões sorteadas de forma determinística, não sincronizadas (2026-08-27)

**Contexto.** As missões do dia precisam ser iguais em qualquer aparelho do
mesmo usuário. O caminho óbvio é sortear no servidor e sincronizar a escolha —
o que exige tabela, escrita no login e um caso de erro novo (o que mostrar
quando o sorteio ainda não chegou).

**Decisão.** Sortear no cliente, de forma determinística, a partir de
`(identificador da conta, data)`. Embaralhamento de Fisher-Yates com gerador
estável. O mesmo dia dá as mesmas missões em qualquer aparelho, sem nenhuma
sincronização.

O que **é** sincronizado é o resgate, numa chave que inclui o período
(`um_foco@2026-08-27`, `semana_dez_focos@w2026-08-24`). Resgatar ontem não
resgata hoje, e a semanal segue a semana, não o dia.

**Alternativas descartadas.** (a) Sorteio no servidor: mais infraestrutura para
o mesmo resultado, e um estado de carregamento a mais numa tela que precisa
abrir instantânea. (b) Sorteio aleatório local: o usuário veria missões
diferentes em dois aparelhos no mesmo dia.

**Consequências.** Mudar o pool de missões muda o sorteio de todos os dias
futuros — e também dos passados, se alguém reabrir uma data antiga. Como
missão expirada não é recuperável, isso não tem efeito prático. A semente é o
e-mail da conta; em modo offline é a constante `local`, então dois usuários
offline no mesmo aparelho veriam as mesmas missões — aceitável, já que offline
não tem conta. Reverter: o commit é isolado.

---

## ADR-011 — Contagem da sessão desenhada pelo Android, não pelo app (2026-08-27)

**Contexto.** O §6 pede notificação persistente com contagem regressiva ao
vivo. A solução canônica é um serviço em primeiro plano no Android, que exige
código nativo, uma permissão a mais e declaração de tipo de serviço — e não
resolve o iOS, onde a Live Activity depende de entitlement.

**Decisão.** Usar `usesChronometer` + `chronometerCountDown` do
`flutter_local_notifications`, com `when` no instante de término. **O Android
desenha a contagem**, a partir do timestamp: ela continua andando com o app em
background ou morto, sem nenhum processo do Baru vivo. A conclusão é uma
notificação **agendada**, não disparada na hora, pelo mesmo motivo.

**Alternativas descartadas.** (a) Serviço em primeiro plano: peso alto,
permissão extra, política de loja mais restrita, e nada disso no iOS.
(b) Atualizar o texto da notificação a cada segundo pelo app: para junto com o
app, que é exatamente o momento em que a contagem importa.

**Consequências.** Não há barra de progresso rica nem controle de pausa na
notificação — o cronômetro do sistema é texto. A ação "Desistir" funciona
porque é um `AndroidNotificationAction`, não um controle de mídia. O aviso de
conclusão usa alarme exato e **cai para inexato** quando a permissão é negada:
alguns minutos de atraso são melhores que nada, e a conclusão em si é
reconciliada pelo relógio quando o app abre (ADR-008). Verificação em aparelho
está em BL-09. Reverter: o commit é isolado.

## ADR-012 — Credencial lembrada no Keystore, biometria como cadeado (2026-08-28)

**Contexto.** O login era um formulário vazio a cada visita. O pedido foi
lembrar e-mail e senha, e entrar pela autenticação do aparelho.

**Decisão.** A credencial vai para o `flutter_secure_storage` — Keystore no
Android, Keychain no iOS —, **nunca** para o `shared_preferences`, onde o
snapshot do app já mora em texto puro e entra em backup do aparelho. A
biometria não é o segredo: ela destranca o cofre, e é a senha guardada que
entra no Supabase. O `local_auth` roda com `biometricOnly: false`, então
digital, rosto **e** PIN servem.

**Alternativas descartadas.** (a) Guardar só a sessão do Supabase e renovar:
o refresh token é revogado ao sair, e depois disso não há como entrar sem
digitar — some justamente o recurso pedido. (b) Exigir biometria de verdade:
deixaria de fora quem não cadastrou digital e aparelhos sem sensor, sem
ganho de segurança real, porque o PIN do aparelho protege o mesmo Keystore.

**Consequências.** `MainActivity` teve de virar `FlutterFragmentActivity` —
o `BiometricPrompt` do AndroidX precisa de um `FragmentActivity` para se
ancorar. `minSdk` passa a ser efetivamente 23 (o do
`flutter_secure_storage`); o projeto já está em 24. Quem troca o bloqueio de
tela perde a chave do Keystore e volta a digitar: tratado como "não há nada
guardado", não como erro. Credencial **recusada pelo servidor** esvazia o
cofre; falta de rede ou de configuração não esvazia, porque o erro não diz
nada sobre a senha e apagá-la ali seria perder o que estava certo. Em ambos
os casos a tela cai no formulário, para ninguém ficar repetindo uma digital
que nunca vai funcionar. Reverter: o commit é isolado, e sem o cofre a tela
volta a abrir no formulário.

## ADR-013 — `INTERNET` no manifesto principal, com teste (2026-08-28)

**Contexto.** O primeiro APK de release exportado instalava, abria e falhava
em toda chamada de rede. O template do Flutter declara
`android.permission.INTERNET` apenas em `android/app/src/debug/` e
`.../profile/`, porque é disso que o hot reload precisa. O build de release
funde só o `main`.

**Decisão.** Declarar `INTERNET` (e `ACCESS_NETWORK_STATE`) no `main`, e
travar com `test/manifest_release_test.dart`, que além de exigir a permissão
compara as duas listas: qualquer permissão que exista só no debug falha o
teste.

**Consequências.** O erro era invisível em desenvolvimento — `flutter run`
sempre funcionou — e só aparecia no aparelho de quem instalava o APK. O
teste move essa descoberta para a suíte. Nenhum efeito em runtime além da
permissão, que é normal e não pede diálogo.

## ADR-014 — Serviço em primeiro plano vigiando a sessão (2026-08-28)

**Contexto.** O ADR-011 descartou serviço em primeiro plano: "peso alto,
permissão extra, política de loja mais restrita, e nada disso no iOS".
Escolheu o cronômetro do sistema na notificação, que resolve a **contagem**
com o app fechado.

Só que a contagem nunca foi o ponto. O relato foi direto: sessão de 25
minutos iniciada, app fechado, TikTok aberto — e nada. Nem aviso, nem
chamada de volta. O ADR-011 resolveu o problema errado.

**A causa.** Com o app em segundo plano, **o Flutter não executa**. Todo o
gatilho do companheiro morava em `_talvezApareceSobreOsApps`, chamado por
`syncPermissionsFromOs`, chamado por `didChangeAppLifecycleState` — que só
dispara quando a pessoa **volta**. Chegava sempre tarde demais. E o gatilho
era "estourou a meta do dia", não "saiu durante o foco": duas condições
diferentes.

**Decisão.** `VigiaDaSessao`, um `Service` com `startForeground`, de pé
apenas enquanto a sessão corre. A cada 2 s pergunta ao `UsageStatsManager`
qual pacote está na frente; se não for o Baru nem sistema/launcher/teclado,
manda o `OverlayDoBaru` aparecer. Um minuto de descanso entre aparições.

`foregroundServiceType="specialUse"`: nenhum tipo da lista descreve isto —
não é mídia, não é localização, não é chamada. A `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`
explica em texto, que é o que a revisão da Play lê.

**Alternativas descartadas.** (a) `WorkManager`: mínimo de 15 minutos entre
execuções — inútil para "você acabou de sair". (b) `AccessibilityService`:
vê o app da frente sem polling, mas é a permissão mais invasiva do Android e
a Play exige justificativa em vídeo; para este uso seria desproporcional.
(c) Continuar sem nada: é o que havia, e não funciona.

**Consequências.** Uma notificação fixa em `IMPORTANCE_LOW` durante a
sessão — que é honesto: algo está rodando, e a pessoa tem de poder ver. O
polling a cada 2 s custa bateria, limitado à duração da sessão. Depende de
duas permissões que já existiam (acesso ao uso e desenhar sobre outros
apps); sem elas o vigia sobe e não faz nada, em silêncio, sem quebrar a
sessão. O iOS continua sem equivalente — não há API para saber o app da
frente, e não vai haver. Verificação em aparelho em BL-12.

## ADR-015 — O ícone do app é o bicho, por espécie e não por humor (2026-08-28)

**Contexto.** O APK saía com o ícone padrão do Flutter, na gaveta e na barra
de notificações. O pedido foi que fosse o pet escolhido, mudando também com
o humor.

**Decisão.** Um `activity-alias` por espécie, cada um com seu `mipmap`, e
exatamente um ligado por vez; `pickSpecies` troca. Os PNGs são gerados pelo
**mesmo `CustomPainter` que desenha o bicho no app**, por
`test/gera_icone_test.dart` (`flutter test --tags icone`).

**Espécie sim, humor não.** Trocar o componente de LAUNCHER faz muitos
launchers removerem e recolocarem o atalho, e em alguns ele some da tela
inicial. Uma troca quando a pessoa escolhe o bicho é aceitável. Uma a cada
mudança de humor faria o ícone piscar o dia inteiro, e o humor muda várias
vezes por dia. O humor aparece onde custa zero: habitat, notificação e
overlay.

**Por que gerar em vez de desenhar.** Um ícone feito à mão num editor seria
um segundo desenho do Baru, que envelheceria em silêncio a cada ajuste no
painter. Gerando, a fonte é uma só.

**Consequências.** A `MainActivity` perdeu o `intent-filter` de LAUNCHER —
quem responde agora são os aliases. Oito PNGs a mais por densidade (~80 KB
no total). `DONT_KILL_APP` na troca, senão o Android encerra o processo
enquanto a pessoa está escolhendo o bicho.

## ADR-016 — Persistencia, nunca bloqueio (2026-08-28)

**Contexto.** A missao diaria principal e o descanso: ficar longe do
telefone por um tempo. A pergunta era se o app deveria impedir a pessoa de
sair para outro app durante a missao.

**Decisao do dono do produto:** nada de bloqueio. So persistencia.

**Por que e a decisao certa, e nao so a decisao dele.** O Android nao
permite que um app bloqueie outro — nao existe API para isso. O unico
caminho que chega perto e `AccessibilityService`, que existe para leitores
de tela e pode ler tudo o que aparece na tela de qualquer app. A Play exige
justificativa em video para publicar com ela e recusa a maioria dos usos que
nao sejam acessibilidade de verdade. Um app de habitos que pede
`AccessibilityService` arrisca a propria publicacao e pede a pessoa uma
permissao desproporcional ao que entrega.

Alem da regra da loja: um app que trava o telefone de alguem nao e
companhia, e cadeado. O produto se chama Baru porque e um bicho que espera
— e um bicho que espera nao tranca a porta.

**O que persistencia quer dizer aqui.** O companheiro aparece por cima do
app onde a pessoa esta (ADR-014), o progresso da missao para de correr
enquanto ela esta fora, e a perda fica visivel. O atrito e emocional e
informativo, nunca tecnico.

**Consequencias.** Nenhuma permissao nova. Nada que arrisque a revisao da
Play. Quem quiser escapar escapa — e essa e a diferenca entre um app que a
pessoa mantem instalado e um que ela desinstala com raiva.

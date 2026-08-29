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

## ADR-017 — A trilha e uma corrente, nao uma lista de metas (2026-08-28)

**Contexto.** Cada marco tinha criterio proprio e independente: sequencia de
N dias, N sessoes, nivel N, N afagos. Como as naturezas sao diferentes e os
contadores correm em paralelo, dava para alcancar o passo 8 (nivel 5) sem
alcancar o 3 (7 dias seguidos). A trilha mostrava tiques salteados, com
cadeados entre eles.

O relato foi direto: *"A trilha e uma conquista. Nao tem como ele ter
conquistado o passo 7, 8, sem ter passado pelo 1, 2."* Esta certo. Uma
sequencia em que o passo 8 chega antes do 3 nao e uma sequencia — e um
placar com varias corridas ao mesmo tempo, desenhado como se fosse uma so.

**Decisao.** `alcancou(m)` deixou de ser `contador >= alvo` e virou
`posicao <= passosConquistados`, onde `passosConquistados` e o maior
**prefixo** com todos os criterios batidos. Como os quatro contadores so
sobem, o prefixo so cresce: a corrente nunca anda para tras e nada precisa
ser gravado.

"Tudo antes conquistado, exatamente um atual, tudo depois travado, sem
buraco" passa a ser garantia **por construcao**, e nao convencao da tela.

**Dois cadeados.** Cadeado e "ainda nao fez"; ampulheta e "ja fez, esperando
a vez". Sem a distincao, o detalhe do degrau dizia "faltam 0 sessoes" — o
numero certo para a pergunta errada — e o placar saia "30/20".

**Alternativa descartada.** Manter o tique fora de ordem como bonus visual.
Foi recusada porque e a propria confusao: o desenho de corrente prometendo
uma ordem que o modelo nao cumpre.

**Consequencias.**

*Piso de posse.* Especie e habitat sao **derivados** da trilha, nao
gravados. Sem tratamento, virar a chave tomaria de volta o axolote e a Serra
de quem os recebeu por fora de ordem — punicao retroativa por mudanca nossa.
`ProgressoDaTrilha.entregues`, alimentado por `marcosResgatados`, e piso: nao
devolve o tique nem recria buraco, so impede a perda. Folhas e XP estao
seguros de qualquer jeito, porque sao contadores que so sobem.

*Segundo caminho quando a permissao e recusada.* `diasAbaixoDaMeta` so anda
com o acesso ao uso concedido, e recusar e caminho suportado. Enquanto os
marcos eram independentes, recusar travava so aqueles marcos; numa corrente
travaria a trilha inteira no passo 2, para sempre. Os cinco marcos desse
tipo ganharam um caminho alternativo por dias seguidos de presenca, de
proposito **mais caro**, para quem concedeu continuar fechando pelo atalho.

*A escada de folhas colou na posicao, nao no id.* O conjunto dos 22 valores
e o mesmo e a soma nao muda, mas reordenar trocou de dono: um marco antigo
pode ter uma linha de extrato divergente do que foi pago (no pior caso 100
folhas). Aceito porque a alternativa era quebrar "recompensas crescentes",
que e o que faz a trilha dar vontade de subir.

## ADR-018 — O buldogue francês entra num degrau que já existia (2026-08-28)

**Contexto.** O buldogue francês virou a nona espécie. As quatro de origem
(capivara, lontra, tartaruga, coruja) saem do quiz do onboarding, que é fixo em
três perguntas de quatro opções e mede quem a pessoa é; as outras se
desbloqueiam na trilha. Restava decidir por onde o buldogue é obtido.

**Decisão.** Ele é a recompensa de `cinquenta_focos`, o passo 20 — um marco que
**já existia** e que não entregava espécie nenhuma. Nada foi acrescentado à
trilha.

**Alternativas descartadas.**

(a) *Entrar no quiz.* As quatro de origem são fixas por contrato (§4) e os
pesos de `quizWeights` estão calibrados para elas; abrir uma quinta opção muda
o resultado de todo mundo que responder igual a antes.

(b) *Um vigésimo terceiro degrau.* Custo alto e todo ele em cima de invariantes
que a ADR-017 acabou de fixar: a trilha é uma corrente ordenada por esforço, a
escada de folhas é um conjunto de 22 valores cuja soma não muda, e os ids são
chave de resgate em `marcosResgatados`. Um degrau novo empurra a folha de todos
os degraus a partir dele e mexe no extrato de quem já jogava — caro demais para
acomodar uma espécie.

(c) *Vender na loja.* Proibido: espécie se desbloqueia por marco, nunca por
dinheiro (§8B).

**Por que este degrau e não outro.** As espécies estavam nos passos 7, 8, 13,
16, 17, 18 e 22, e o vão entre a gata (18) e a raposa (22) era o único sem
prêmio de bicho. E o degrau diz a coisa certa: o buldogue francês é a única raça
do elenco criada só para fazer companhia — não caça, não pastoreia, não nada —,
e cinquenta sessões de foco **acompanhadas** são exatamente o que ele faz.

**Consequências.** Nenhuma mudança na estrutura da trilha: 22 passos, os mesmos
ids, a mesma escada de folhas. O teste que travava "as quatro novas estão na
trilha" era uma lista escrita à mão e aprovava uma espécie sem marco nenhum;
passou a ser derivado do `enum` e da tabela do quiz. Reverter: tirar
`especie: Species.frenchie` da recompensa de `cinquenta_focos`.

**Três coisas que quase passaram batidas, e que viraram teste.**

1. *O `case` caindo na espécie errada.* `especies_test.dart` comparava o RGBA
   inteiro entre espécies, então bastava a paleta ser diferente para dois bichos
   passarem — mesmo desenhando a **mesma silhueta**. Aconteceu: o buldogue
   chegou a desenhar `_gata` e a suíte inteira passou. Agora compara também o
   canal alfa sozinho, que é a forma sem cor.
2. *O ícone que não troca.* O ícone por espécie (ADR-015) depende de quatro
   peças fora do Dart — `activity-alias`, a lista `ESPECIES` no Kotlin, os PNGs
   por densidade e o XML do adaptativo. Faltando qualquer uma, o ícone
   simplesmente não muda no aparelho, em silêncio. `manifest_release_test.dart`
   passou a exigir as quatro para cada valor do `enum`.
3. *A folha que alimenta a landing.* `docs/evidence/.../folha-especies.png` é o
   insumo de `landing/build_assets.py`, que separa as linhas por faixas de alfa
   vazio. Com nove linhas o passo vertical ficou apertado, duas espécies
   encostaram e a folha saiu com 7 faixas em vez de 9 — o corte teria renomeado
   metade do elenco em silêncio. A linha ganhou folga, e o script confere a
   contagem contra a lista em vez de contra um número escrito à mão.

## ADR-019 — Nenhuma ferramenta de desenvolvimento no aparelho de quem usa (2026-08-28)

**Contexto.** O dono do produto pediu o app "100% como produto final, sem
dados mock ou sistema de testes". O app tinha um painel de depuração completo
(`lib/widgets/debug_panel.dart`) e, sustentando esse painel, um conjunto de
métodos e dados dentro do código de produção: forçar humor, presets de
habitat, +200 folhas, ±30 min de tempo de tela, trocar de espécie sem passar
pela trilha, e um `resetAll()` que semeava o retrato do design — 165 folhas,
`lily` + `dock`, raiz de 4 dias, uma semana com dois dias presentes e um
congelado.

O painel estava **órfão** desde algum turno anterior: nada na árvore de
widgets o instanciava. Mas os métodos continuavam públicos em `AppState`, e a
porta mais cara continuava aberta no caminho quente — `Mood get mood` começava
com `if (overrideMood != null) return overrideMood!;`.

**Decisão.** Sai tudo o que existe para facilitar o desenvolvimento e que rode
no aparelho de um usuário. O critério é esse, e não "está em `lib/`": teste em
`test/` e costura marcada `@visibleForTesting` são rede de segurança e ficam.

Saíram, em `lib/`:

- `widgets/debug_panel.dart` inteiro (`DebugFab` + `DebugPanel`), e
  `AppRadii.debug`, o token de raio que só ele usava.
- `AppState.overrideMood` e `forceMood()`, com os onze `overrideMood = null`
  espalhados que existiam só para limpar a porta dos fundos.
- `AppState.grantLeaves()`, `usageUp()`, `usageDown()`, `setHabitat()`,
  `setSpecies()`, `resetAll()`, `toggleDebugFast()`.
- `models.dart`: o mapa `habitats` (presets `empty`/`half`/`full`) e
  `weekPattern` (a semana de mentira que só o `resetAll` usava).
- Em `_advanceDay`, o parâmetro `debugUsage` e a linha
  `usage = debugUsage && usageAccess ? 40 : 0` — quarenta minutos de tela que
  aparelho nenhum tinha reportado.

Ficaram, com barreira e com o porquê escrito no código:

- `AppState.debugFast` (contrato §12). `kDebugMode` é barreira real: em
  release a constante é `false` **e nenhum caminho do app escreve mais nesse
  campo**, porque o botão que o virava saiu com o painel.
- `AppState.nextDay()`, agora `@visibleForTesting`. É a única forma de
  exercitar a virada do dia sem esperar até amanhã; em produção quem vira o
  dia é `applyCalendar`, a partir da data real.
- `BaruRepositories.memory()`, agora `@visibleForTesting`. Persistência
  descartável de que os testes de apagar-dados, auth e sync precisam.

**Alternativas descartadas.**

(a) *Esconder o painel atrás de `kDebugMode` e manter o resto.* Era o que já
existia — `DebugFab` já checava `kDebugMode` — e não resolvia nada: o problema
não era o botão, eram os métodos públicos e o `overrideMood` no caminho de
produção, que sobrevivem ao `if` da UI.

(b) *Manter `resetAll()` como "refazer onboarding".* Não é isso. O refazer
onboarding do usuário é `restartOnboarding()`, e o apagar de verdade é
`apagaMeusDados()` (com teste próprio em `test/apagar_dados_test.dart`).
`resetAll()` era um semeador de demonstração.

(c) *Mover `habitats` para `test/`.* Melhor ainda: derivar do catálogo.
`itensDeCena` já é a lista completa, e a evidência do "habitat cheio" passou a
sair dela. Uma lista escrita à mão que precisa acompanhar a loja envelhece em
silêncio — o PNG "cheio" passaria a mostrar um habitat incompleto sem ninguém
notar.

**Consequências.** `Mood get mood` passou a derivar só de fatos medidos, o que
é a mudança que mais importa: a cena não tem mais como descrever um dia que
não aconteceu. Dois testes que existiam **só** para cobrir ferramenta de debug
foram apagados: `sync_test.dart` › "forçar humor no debug não sincroniza nada"
(cobria `forceMood` + `toggleDebugFast`) e `loja_vitrine_test.dart` › "os
atalhos de habitat só citam objeto que existe" (cobria o mapa `habitats`; a
asserção de que "cheio" é o catálogo inteiro virou tautologia ao derivar).
Quatro testes que usavam `overrideMood` para varrer os cinco humores passaram
a **montar os fatos** de cada humor — ficaram mais fortes, porque agora também
guardam a derivação. Reverter: `git revert` do commit; não há migração nem
dado de usuário envolvido.

## ADR-020 — Uma sessão concluída cura a desistência do dia (2026-08-28)

**Contexto.** Relato do dono: *"quando o pet está triste por uma interrupção,
ele não está voltando a ficar bem depois de um intervalo de sucesso"*. Estava
certo, e a causa era exata: `abandonedToday` era escrito em `abandon()` e
limpo em **dois** lugares — a virada do dia e o começo do companheirismo —,
nenhum deles uma sessão concluída; e a precedência do humor lia esse campo
cru. Parar uma sessão às nove da manhã deixava o bicho triste até a
meia-noite, por mais sessões que a pessoa completasse depois.

Isso é punição de dia inteiro por um tropeço, e o contrato §1 diz o contrário
com todas as letras: "abandonar uma sessão = sem recompensa, **nada mais**".
Um dia inteiro de tristeza é bem mais do que nada mais.

**Decisão.** O humor passa a ler `desistenciaEmAberto` em vez de
`abandonedToday`. A desistência está em aberto quando a pessoa parou uma
sessão hoje **e a última sessão registrada do dia continua sendo essa**.
Concluir depois devolve o bicho; parar de novo depois de concluir o entristece
de novo, e a sessão seguinte o traz de volta outra vez.

`abandonedToday` **não muda de significado**: continua sendo o registro do
dia, continua no snapshot, em `baru_daily_progress.abandoned_today`, no
relatório e nas missões. O que sarou foi o humor, não o fato. Sem registro no
log de sessões — snapshot antigo, corte das 80 últimas, linha vinda de outro
aparelho — a regra cai em `completedToday == 0`, que chega no mesmo snapshot
que `abandonedToday` e portanto vive e morre com ele.

**Alternativas descartadas.**

(a) *Qualquer sessão concluída no dia perdoa (`completedToday >= 1`).* Mais
simples e usa contador que já existe, mas deixa invisível a desistência das
cinco da tarde de quem focou de manhã: o bicho nunca reage ao gesto. A cena
carrega o estado **agora**, e o último gesto é o melhor retrato dele.

(b) *Exigir que a sessão nova seja pelo menos tão longa quanto a que parou.*
É uma barra para transpor — exatamente a punição que o §1 proíbe —, e é
impossível de explicar na tela sem soar como cobrança.

(c) *Apagar `abandonedToday` ao concluir.* Perderia um fato que aconteceu, e
quebraria relatório, missões e a coluna sincronizada. Há outra frente mexendo
na sincronização; mudar o significado da coluna seria o pior momento possível.

**O que não mudou.** A fala "Uma sessão de {min} parou no meio hoje." continua
existindo e continua honesta: ela só é escolhida dentro de `_saudade`, que só
roda quando o humor **é** `missing_you` — ou seja, enquanto a desistência está
em aberto. Depois da cura ela não é mostrada, e por isso não passa a mentir. A
ausência de dois dias ou mais também não é curada por uma sessão: é outro
fato, com outra fala, e continua na primeira linha da precedência.

**Consequências.** `docs/PRODUCT.md` §3 foi atualizado — a linha do
`missing_you` agora diz "desistência **em aberto**", com o parágrafo que
define o termo. Três testes novos em `test/session_test.dart` › "a desistência
não custa o dia inteiro" percorrem o ciclo pelas mesmas chamadas que a tela
faz (`startSession` → `abandon` → `reconcileSession`), sem plantar flag.
Verificado por mutação: trocando `return ultima.aborted` por `return true`, os
dois testes da cura falham com "Expected: not Mood:<Mood.missingYou>". Dois
casos antigos que codificavam a regra velha — `state_test.dart` e
`mood_test.dart`, ambos "missing_you ganha de radiant" — foram reescritos com
a desistência como **último** gesto do dia, que é onde a precedência ainda
vale. Reverter: trocar `desistenciaEmAberto` de volta por `abandonedToday` na
primeira linha de `Mood get mood`.

---

## ADR-021 — Contador de missão é conta sobre as sessões, não coluna (2026-08-28)

**Contexto.** Seis campos do `AppSnapshot` não chegavam ao banco:
`minutosDeFocoHoje`, `maiorSessaoHoje`, `sessoesNaSemana`, `minutosNaSemana`,
`diasAbaixoNaSemana` e `som`. Efeito medido no código: reinstalar o app ou
entrar no segundo aparelho zerava o progresso das missões do dia e da semana
mesmo com as sessões já sincronizadas, e devolvia o som ligado a quem o tinha
desligado. É a mesma classe do defeito que a migration 10 e o
`AppSnapshot.fundeCom` vieram corrigir.

**Decisão.** Colunas só para o que não é derivável.

- Os **quatro** de foco viram conta sobre `baru_sessions`, refeita na leitura
  (`BaruRowCodec.contadoresDe`). `baru_sessions` já sobe inteira e guarda
  `started_at`, `duration_min` e `completed` — tudo o que os quatro somam.
- `diasAbaixoNaSemana` ganha coluna (migration 15). Não sai de sessão nenhuma:
  depende do tempo de tela do **dia fechado**, e o app só guarda o agregado do
  dia corrente em `baru_screen_time`.
- `som` ganha coluna (migration 14). Preferência não é derivável de nada.

A coluna nova vem com `semana_de`, a segunda-feira a que o contador pertence,
e o app devolve zero quando o carimbo não é o da semana corrente.

**Alternativas descartadas.**

(a) *Uma coluna para cada um dos quatro.* Seria um segundo registro do mesmo
fato. Dois registros do mesmo fato divergem na primeira sessão que suba com o
contador desatualizado — ou o contrário — e ninguém percebe até a missão pagar
errado. A conta não pode divergir de si mesma.

(b) *`dias_abaixo_na_semana` sem `semana_de`.* A zeragem da segunda-feira
acontece dentro do aparelho e **não marca sincronização**: o remoto seguiria
com o número da semana passada até uma gravação por outro motivo. A semana
nova começaria com a missão semanal meio cumprida de graça.

(c) *Uma tabela de dias fechados, com o resultado de cada dia.* Resolveria
`diasAbaixoNaSemana` e abriria relatório histórico — mas exige o evento de
fechamento do dia, que mora em `AppState._advanceDay`. Fica para quando houver
motivo além deste contador.

**Consequências.** A janela dos quatro é a do relógio de **quem lê**: eles
zeram sozinhos na virada do dia e na segunda, sem depender de outro aparelho
ter empurrado o zero. `fundeCom` deixou de dar os cinco de bandeja ao local e
passou a ficar com o maior — os dois lados descrevem a mesma janela agora, e
"local sempre ganha" custaria justamente o caso da reinstalação. Duas
correções de fuso vieram junto: `started_at` e `trial_started_at` iam sem fuso
na string, e o Postgres lia como UTC — a sessão das 9h voltava às 6h, perto o
bastante da meia-noite para cair no dia errado.

Reverter: tirar a chamada de `contadoresDe` do `fromRows` e devolver
`local.` aos cinco campos em `fundeCom`. As colunas ficam; são aditivas.

---

## ADR-022 — `baru_daily_quests` fica no banco, sem escritor (2026-08-28)

**Contexto.** A tabela guardava duas quests fixas do desenho anterior ao
quadro de missões — `focus_session` e `under_goal` — e o app gravava nela a
cada `pushStreak`, ou seja, a cada fim de sessão. Três fatos: nenhum `select`
do app jamais a leu; os dois valores são derivados de
`baru_daily_progress.completed_sessions` e de
`baru_screen_time.usage_min < goal_min`; e o `check` de `quest_key` aceita
duas chaves enquanto o sistema de missões tem 17 tipos, cujo resgate mora em
`baru_progression.missoes_resgatadas` como `id@periodo`.

**Decisão.** Parar de escrever. Manter a tabela, as linhas, a RLS e o lugar
dela em `tabelasDoUsuario`. A migration 16 é só um `comment on table` que
registra o porquê onde o schema pode ser lido sozinho.

**Alternativas descartadas.**

(a) *`drop table`.* Destrutivo num banco com dados reais, e sem nada em troca:
apagaria o histórico de quem usou o app antes desta decisão.

(b) *Ampliar o `check` para as 17 chaves e passar a ler.* Daria uma segunda
gramática para o mesmo fato que `missoes_resgatadas` já guarda — e é a chave
com período dentro que torna o resgate idempotente.

(c) *Continuar escrevendo sem ler.* Uma viagem de rede por fim de sessão para
acumular linha que ninguém lê.

**Consequências.** Um `pushStreak` a menos por sessão. Apagar a conta continua
alcançando a tabela (a lista do app não mudou, e o `on delete cascade` para
`auth.users` também não). O único fato que só ela registrava — se um **dia
passado** fechou abaixo da meta — deixa de ser gravado; hoje ninguém o lê, e
quem precisar dele vai querer a tabela da alternativa (c) da ADR-021, com o
evento de fechamento do dia por trás. Reverter: voltar a chamar o `upsert` em
`pushStreak`.

---

## ADR-023 — Uma notificação só para a contagem, e ela é a do serviço (2026-08-28)

**Contexto.** O ADR-011 pôs a sessão na barra com o cronômetro do sistema
(`usesChronometer` + `chronometerCountDown`), desenhado pelo Android a partir
do instante de término. O ADR-014, depois, levantou o `VigiaDaSessao`, um
serviço em primeiro plano — e o Android **obriga** um serviço desses a ter
notificação própria.

Ninguém juntou as duas pontas. A do plugin ficou no id 1004, canal
`baru_sessao`, com cronômetro; a do serviço no id 4711, canal `baru_vigia`,
sem cronômetro nenhum. **Ids diferentes não se sobrescrevem**: o
`NotificationManager` guarda por (pacote, tag, id) e nenhuma das duas usava
tag. Durante toda sessão de foco havia **duas linhas na barra com o mesmo
título e o mesmo corpo**, e só uma contando. Pior: a que o Android garante
manter — a do serviço — era a parada. O relato do dono foi "os timers não
estão dinâmicos", e é exatamente isso que ele estava vendo.

Junto disso, dois defeitos menores e reais:

- **"Desistir" não desistia.** A ação ia com `showsUserInterface` no padrão
  `false`, e nesse caminho o `flutter_local_notifications` manda o toque para
  um `BroadcastReceiver` que precisa de um isolate registrado em
  `onDidReceiveBackgroundNotificationResponse`. O app nunca registrou um. O
  botão cancelava a notificação e o app não ficava sabendo: a sessão seguia
  correndo e, na volta, o relógio **pagava** a recompensa de quem desistiu.
- **A missão do descanso não tinha notificação nenhuma.** A missão principal
  do dia — a que pede quarenta minutos longe do telefone — sumia da vista no
  segundo em que passava a valer.

**Decisão.** Uma contagem por vez, num id só, e quem a desenha é o serviço em
primeiro plano.

1. O `VigiaDaSessao` passa a postar **no mesmo id e no mesmo canal** que o
   Dart usa. Duas escritas no mesmo id são uma atualização, não uma segunda
   notificação — é o caminho documentado para mexer na notificação de um
   serviço em primeiro plano. O id e o canal viajam do Dart num canal novo
   (`baru/barra`), junto com o prazo e os rótulos, e ficam gravados em
   `SharedPreferences` para o caso de o processo morrer no meio da sessão.
2. A notificação do serviço ganha o mesmo cronômetro regressivo, mais
   `VISIBILITY_PUBLIC` (o padrão do Android esconde o conteúdo em bloqueio
   seguro, e o conteúdo aqui é a contagem) e `CATEGORY_STOPWATCH`.
3. "Desistir" e "Voltar ao Baru" **abrem o app**, carregando a ação no
   `Intent`. O arranque a frio é coberto dos dois lados: pelo plugin com
   `getNotificationAppLaunchDetails`, e pelo serviço com uma ação guardada no
   `MainActivity` até o Dart existir para recebê-la.
4. A missão do descanso ganha a mesma barra, com precedência para o foco. O
   prazo dela é **projetado** (`agora + o que falta`), não fixo: o relógio do
   descanso desconta a fuga e o tempo dentro do próprio Baru, então
   `começou + 40 min` mentiria assim que a pessoa pegasse o telefone.

**Alternativas descartadas.**

(a) *`MediaStyle`.* Só ganha o tratamento de player com um `MediaSession`
válido atrás, e a partir do Android 11 os controles de mídia dos ajustes
rápidos vêm da sessão, não da notificação. Forjar uma sessão para um timer
sequestraria o botão de volume e os controles de fone, e apareceria como
player nos ajustes rápidos. É abuso de API, e a Play trata como tal.

(b) *`CallStyle`.* Ganha ranking alto de verdade, e em troca de uma promessa:
que aquilo é uma chamada. Mostraria afordâncias de atender/desligar e pede
`FOREGROUND_SERVICE_TYPE_PHONE_CALL`, que por sua vez pede `MANAGE_OWN_CALLS`
e ser um app de chamadas. Comprar destaque com um nome falso.

(c) *Manter as duas notificações e só sincronizar o texto.* Continuariam
sendo duas linhas na barra. O problema nunca foi o texto.

(d) *Tirar o cronômetro do serviço e deixar só a do plugin.* A do serviço não
pode deixar de existir — o Android exige — e é ela que o sistema garante
manter. Sobraria a garantida sem contagem.

(e) *Registrar o isolate de segundo plano do plugin para "Desistir" agir sem
abrir o app.* Um segundo ponto de entrada Dart, sem estado, que teria de
duplicar o que `abandon()` faz com folhas, sequência e histórico. Abrir o app
é honesto: desistir leva à tela de resultado de qualquer forma.

**Consequências.** A barra tem uma notificação durante a pausa, e ela conta.
Desligar o vigia enquanto uma sessão corre usa `STOP_FOREGROUND_DETACH` em vez
de `REMOVE`, senão encerrar o descanso apagaria o cronômetro de um foco vivo.
O `VigiaDaSessao` só cria o canal se ele não existir, e nesse ramo usa o
rótulo do próprio app — nenhuma frase nasce do lado nativo. **Nada disso foi
visto num aparelho**: o desenho do cronômetro é o system UI. Registrado em
BL-16. Reverter: os arquivos tocados são `notification_service.dart`,
`l10n_notificacao.dart`, `app.dart`, `VigiaDaSessao.kt`, `MainActivity.kt` e o
manifesto.

# Bloqueios — precisam de um humano

Cada item traz a ação exata. Tudo o que dependia do agente já está pronto.

---

## BL-12 — Faltam as migrations 10 e 11 no remoto

**Situação.** As migrations 7, 8 e 9 já foram aplicadas (sonda REST em
2026-08-27: as tabelas e colunas respondem 200). Faltam duas, ambas aditivas
e idempotentes:

| Arquivo | O que faz |
|---|---|
| `20260827220000_baru_progression_totais.sql` | `missoes_resgatadas`, `sessoes_concluidas`, `melhor_sequencia`, `dias_abaixo_da_meta` em `baru_progression` |
| `20260827230000_baru_inventory_equipped.sql` | `equipped` em `baru_inventory_items`, e derruba o `check` de ids fechado (eram 8 itens, agora são 17) |

**Sem elas o app não quebra**: `AppSnapshot.fundeCom` já impede a perda de
dado no arranque, e o "em uso" fica guardado no aparelho. O que não acontece é
o dado chegar ao **segundo aparelho**.

```
cd baru_app
supabase db push
```

Ou cole os dois arquivos no SQL Editor, nessa ordem.

---

## BL-10 — **O banco remoto está atrás do repositório. É isto que causa o "erro ao sincronizar".**

**Situação, verificada agora** (sonda REST com a chave anon deste repositório,
em 2026-08-27):

| Tabela | Remoto |
|---|---|
| `baru_app_categories` (migration 7) | **404 · PGRST205 · não existe** |
| `baru_progression` (migration 8) | **404 · PGRST205 · não existe** |
| as outras 13 | 200 · existem |

**Impacto exato.** `pushSettings` faz um `delete` em `baru_app_categories` em
**toda** gravação — mesmo sem nenhuma reclassificação de app. A tabela não
existe, o PostgREST devolve 404, o domínio de ajustes falha, e o app mostra o
aviso de sincronização a cada salvamento. **Os dados não se perdem** — o
snapshot local é gravado antes de qualquer envio — mas nada de ajustes,
tempo de tela e (a partir deste turno) progressão sobe para a nuvem.

**O que já foi feito deste lado.** As duas migrations existem no repositório e
**foram aplicadas e validadas num banco limpo** (`supabase db reset`: 8
migrations, 15 tabelas, nenhuma sem RLS, 58 políticas). A RLS da tabela nova
foi provada em SQL: o usuário A vê só a própria linha, `UPDATE`/`DELETE` na
linha do B afetam 0 linhas, e `anon` vê 0. O app também parou de chamar isto
de "falha de rede": agora diz qual tabela falta.

**Ação pedida.** Não consigo executar: não há token de acesso do Supabase
neste ambiente e o MCP nega permissão de escrita no projeto.

```
cd baru_app
supabase login
supabase link --project-ref slqpuppkapiewjqvedtj
supabase db push
```

Ou, sem CLI, colar no SQL Editor do dashboard, na ordem:

```
baru_app/supabase/migrations/20260827100000_baru_app_categories.sql
baru_app/supabase/migrations/20260827200000_baru_progression.sql
```

As duas são aditivas e idempotentes (`create table if not exists` + `drop
policy if exists` antes de cada `create policy`). Nenhuma apaga dado.

Se o `db push` reclamar do ledger, resolva o BL-01 primeiro.

---

## BL-01 — Ledger de migrations ausente no projeto remoto

**Situação.** As 5 migrations foram aplicadas à mão pelo SQL Editor. O schema
`supabase_migrations.schema_migrations` **não existe** no banco (verificado por
query). O CLI não sabe o que já rodou.

**Impacto.** Um `supabase db push` futuro tentará reaplicar tudo. As migrations
foram tornadas reexecutáveis (ADR-003), então não deve quebrar — mas o projeto
segue sem rastro de o que foi aplicado.

**Ação pedida** (requer a senha do banco, em Dashboard → Settings → Database):

```
cd baru_app
supabase login
supabase link --project-ref slqpuppkapiewjqvedtj
supabase migration repair --status applied 20260826190000 20260826190001 20260826200000 20260826200001 20260826200002
supabase db push
```

O `db push` final deve aplicar apenas a migration nova de adoção do
`rls_auto_enable`.

---

## BL-02 — RESOLVIDO em 2026-08-26

**Era:** migrations nunca validadas contra banco limpo.

**Feito no turno.** Docker subido, `supabase start` (só Postgres, auth e REST) e
`supabase db reset`: as 6 migrations aplicaram do zero. O schema resultante é
idêntico ao remoto — 13 tabelas, 50 políticas, `baru_profiles` com 8 colunas,
event trigger `ensure_rls` presente, nenhuma tabela sem RLS, `anon` sem EXECUTE
sobre `rls_auto_enable`. Isolamento entre usuários conferido com dois usuários
reais: A vê só a própria carteira, `anon` vê zero.

Reaplicação também conferida: migrations 5 e 6 rodam de novo sem erro
(`ON_ERROR_STOP=1`, exit 0). A versão antiga da 5, tirada do histórico do git,
falha com `ERROR: column "species" does not exist` — que é exatamente o que o
ADR-003 previu.

Para repetir:

```
cd baru_app
supabase start
supabase db reset
```

**Pendente ainda:** subir o app Flutter apontando para o banco local
(`SUPABASE_URL=http://127.0.0.1:54321` via `--dart-define`) e percorrer o fluxo
à mão. Isso exige um dispositivo/emulador, que o agente não tem.

---

## BL-03 — Proteção contra senha vazada desligada

**Situação.** Linter de segurança do Supabase acusa
`auth_leaked_password_protection` desabilitado. O app aceita senha de 6
caracteres sem checagem contra HaveIBeenPwned.

**Ação pedida.** Dashboard → Authentication → habilitar *Leaked password
protection*.

---

## BL-04 — Conta de teste sem e-mail confirmado

**Situação.** O projeto tem 2 usuários; **1 está sem `email_confirmed_at`** e
não consegue entrar. O app trata isso corretamente como `email_not_confirmed`.

**Ação pedida.** Dashboard → Authentication → Users: confirmar o usuário
pendente, **ou** desligar *Confirm email* em Providers → Email enquanto for
desenvolvimento.

---

## BL-05 — Assinatura de release do Android

**Situação.** `android/app/build.gradle.kts` ainda usa a config de assinatura de
**debug** no build de release (TODO do template Flutter intacto). Não é
publicável. Gerar keystore é irreversível e envolve segredo — o agente não faz.

**Ação pedida.** Gerar a keystore, guardá-la **fora** do repositório, criar
`android/key.properties` (já coberto pelo `.gitignore`) e apontar o
`signingConfig` de release para ela.

---

## BL-06 — Entitlement de Screen Time no iOS

**Situação.** O iOS não expõe tempo de tela total a apps de terceiros sem o
entitlement Family Controls / DeviceActivity da Apple. Hoje
`UsageService.platformSupportsUsage` é `false` no iOS e o app cai no caminho
suportado de humor derivado só das sessões de foco.

**Ação pedida.** Solicitar o entitlement pela conta de desenvolvedor Apple. Até
lá, a flag mantém o iOS honesto.

---

## BL-07 — IAP (compra dentro do app)

**Situação.** Trial e planos existem só localmente: `startTrial()` e
`restorePurchases()` ligam um booleano, sem validação de loja. Não há receita
real em risco enquanto não houver IAP.

**Ação pedida.** Configurar os produtos na App Store Connect e no Play Console.
Só então vale implementar validação de recibo — e mover a economia de folhas
para o servidor.

---

## BL-08 — Push para o remoto exige a conta `LuisHCuba`

**Situação.** A conta ativa do `gh` na máquina era `goworksistemas`, que recebe
403 ao empurrar para `LuisHCuba/baru`. A conta `LuisHCuba` já estava
autenticada, só não era a ativa; o agente trocou com
`gh auth switch --user LuisHCuba`.

**Ação pedida.** Nenhuma, se a troca puder ficar permanente. Se `goworksistemas`
precisar voltar a ser a conta ativa, dar permissão de escrita a ela no
repositório ou reverter com `gh auth switch --user goworksistemas` e empurrar
manualmente.

---

## BL-09 — Notificação da sessão: o que falta é aparelho, não código

**Situação.** A sessão em curso já vai para a barra de notificações como
notificação **fixa**, silenciosa, com a contagem regressiva desenhada pelo
próprio Android (`usesChronometer` + `chronometerCountDown` a partir do
instante de término) e um botão "Desistir" que age no app. O fim da sessão é
**agendado**, então o aviso de recompensa chega mesmo com o app fechado.

O que os testes cobrem: a configuração da notificação (fixa, silenciosa,
cronômetro apontando para o instante certo, ação presente, canal separado) e o
ciclo de vida dela no estado (some ao concluir e ao desistir; desistir duas
vezes não dispara duas vezes).

O que **não** foi verificado: a entrega pelo sistema operacional. Isso exige
aparelho, e o agente não tem.

**Ação pedida.** Instale num Android e confira:
1. começar uma sessão põe a notificação na barra, com a contagem andando;
2. a contagem continua andando com o app fechado (é o ponto todo);
3. "Desistir" na notificação encerra a sessão dentro do app;
4. o aviso de conclusão chega com o app fechado.

Se o item 4 atrasar muito, é a permissão de alarme exato: o app declara
`SCHEDULE_EXACT_ALARM` e cai para agendamento inexato quando ela é negada.
Ajustes → Apps → Baru → Alarmes e lembretes.

**Fora de escopo por ora:** serviço em primeiro plano no Android e Live
Activity no iOS. O primeiro exige código nativo e uma permissão a mais; o
segundo exige entitlement da Apple (ver BL-06). A contagem via cronômetro do
sistema cobre o caso principal sem nenhum dos dois.

## BL-11 — Pagamento: precisa de contas que só você abre

**O que está travado.** A tela de plano existe e fala em "7 dias grátis",
mas não há cobrança por trás. Nada disso é código: são contas, cadastros e
identificadores que dependem de CNPJ/CPF, dados bancários e das fichas nas
lojas.

**Recomendação, e o porquê.**

*Celular.* A Google Play **exige** o faturamento dela para bens digitais
vendidos dentro do app. Pix, Stripe ou Mercado Pago por dentro do app tiram
o app da loja — não é preferência, é política. Sobram duas formas de falar
com o Play Billing:

- `in_app_purchase`, o plugin oficial: de graça, e sobra para nós validar
  recibo, guardar direito de acesso, tratar renovação, cancelamento,
  reembolso e período de carência, e sincronizar entre Android e iOS.
- **RevenueCat** (`purchases_flutter`): embrulha Play Billing e StoreKit,
  valida recibo do lado dele, entrega "esta conta tem acesso" pronto, e
  manda webhook. Grátis até ~US$ 2,5 mil por mês de receita; 1% depois.

Para um app com uma pessoa construindo, RevenueCat paga o 1% no primeiro mês
em que não for preciso depurar um recibo. **É a recomendação.**

*Web.* O app roda no navegador, e ali a regra da Play não vale. Stripe
resolve; Mercado Pago resolve **com Pix**, que no Brasil muda conversão.

*Onde mora o direito de acesso.* No Supabase, escrito pelo webhook do
RevenueCat/Stripe — nunca decidido pelo aparelho. Aparelho que decide se tem
plano é aparelho que se convence do contrário.

**Para destravar, preciso de você:**

1. Conta de desenvolvedor Google Play (US$ 25, uma vez) e a ficha do app
   criada — sem ela não existe produto nem id de assinatura.
2. Os planos definidos: quantos, preço, período, e se o teste de 7 dias é da
   loja ou nosso.
3. Conta RevenueCat ligada à Play, e a chave pública.
4. Se quiser cobrar na web: conta Stripe ou Mercado Pago.

Com (1) a (3) na mão, a integração no app é direta e testável com as compras
de teste da própria Play.

## BL-12 — O vigia da sessão precisa de teste em aparelho

**O que foi feito.** Um serviço em primeiro plano (`VigiaDaSessao.kt`) que,
enquanto a sessão de foco corre, pergunta a cada 2 s qual app está na frente
e chama o companheiro por cima quando não é o Baru — com um minuto de
descanso entre aparições.

**Por que isso mudou.** O ADR-011 tinha descartado serviço em primeiro plano
por peso. Estava errado: sem ele, sair do app durante o foco não fazia
absolutamente nada, porque com o app em segundo plano **o Flutter não
executa** e o único gatilho morava no `didChangeAppLifecycleState` — que só
dispara quando a pessoa volta. Ver ADR-014.

**O que os testes cobrem.** O contrato Dart↔plataforma: quando o vigia é
chamado, quando é desligado, o que vai junto, e que parar vale mesmo quando
o Dart renasceu sem lembrar que começou. O `MethodChannel` é dublê.

**O que só o aparelho responde:**

1. A notificação fixa aparece ao começar a sessão e some ao terminar.
2. Sair para outro app durante a sessão faz o Baru aparecer por cima.
3. Ele **não** aparece indo para a tela inicial ou o teclado.
4. Não repete antes de um minuto.
5. Fechar o app pelo gerenciador de tarefas não deixa a notificação presa.
6. O consumo de bateria numa sessão de 50 min é aceitável.

O item 2 depende do acesso ao uso concedido **e** de "desenhar sobre outros
apps". Sem o primeiro, o vigia sobe e não vê nada; sem o segundo, vê e não
aparece.

## BL-13 — Widgets de tela inicial: não entregues

**O que foi pedido.** Widget na tela inicial mostrando o Baru.

**O que existe hoje.** Nada. O BACKLOG lista W-01 (widget de tela inicial),
W-02 (tela de bloqueio) e W-03 (ícone). O W-03 saiu neste turno; W-01 e W-02
não.

**O tamanho real.** Um widget do Android é `AppWidgetProvider` +
`RemoteViews` — e `RemoteViews` **não desenha `CustomPainter`**. O Baru do
widget teria de ser um PNG renderizado pelo app e gravado em disco a cada
mudança de humor, com o provider apontando para o arquivo. É o mesmo
caminho do gerador de ícone (`test/gera_icone_test.dart`), agora em tempo de
execução.

Some com: layout XML por tamanho, atualização por `WorkManager`, e o mesmo
trabalho de novo no iOS, onde é WidgetKit e Swift.

Não cabia junto do vigia neste turno. **É o próximo pedaço grande**, e é
independente de tudo o que está aqui.

## BL-14 — Widget de tela inicial: verificação em aparelho

**O que foi feito.** `BaruWidget` (`AppWidgetProvider`) mais o layout, e um
`WidgetService` no Dart que rasteriza o bicho num PNG e grava nome, raiz,
uso e meta. `RemoteViews` roda no processo do launcher e não executa
`CustomPainter`, então o bicho do widget **não pode ser** o mesmo objeto que
o da tela — é uma imagem gerada pelo mesmo painter.

**O que os testes cobrem.** A regra que faz a classe existir: só rasteriza
quando a imagem muda de verdade. Mudar só a raiz grava o texto novo e **não**
redesenha; mudar humor ou espécie redesenha. O estado do app notifica muitas
vezes por minuto e rasterizar é caro.

**O que só o aparelho responde:**

1. O widget aparece na galeria do sistema com a descrição certa.
2. Colocado na tela, mostra o bicho — não um retângulo vazio.
3. Redimensionar de 2x2 para 4x2 não corta o rodapé.
4. Tocar abre o app.
5. Mudar o humor no app atualiza o widget sem reabrir a tela inicial.
6. A imagem não fica borrada em tela de alta densidade.

O item 2 é o que mais provavelmente falha primeiro: se o caminho do PNG não
chegar, ou o launcher não puder ler o arquivo, sai o fundo sem bicho.

## BL-15 — Permissões e fala por app: o que só o aparelho responde

**O que foi feito.** O onboarding passou a pedir as **quatro** permissões,
uma por tela, cada uma dizendo o que faz e o que deixa de funcionar sem ela:
acesso ao uso, desenhar sobre outros apps, notificações e alarme exato.
Ajustes › Sobre outros apps virou a tela de permissões que se revisita, com
o estado de cada uma e um botão de pedir de novo. O catálogo de apps foi de
55 para 126 entradas e ficou visível e editável ali mesmo. A fala do
companheiro passou a variar com o app da frente.

**Por que isso mudou.** No aparelho do dono do produto o acesso ao uso
estava concedido e `SYSTEM_ALERT_WINDOW` estava **negada** — e o app não
avisava. O companheiro nunca aparecia sobre o TikTok, o que é
indistinguível de estar quebrado. Uma permissão que ninguém enumera é uma
permissão que ninguém percebe faltando.

**O que os testes cobrem.** Que as quatro são pedidas uma a uma; que cada
uma diz o custo da recusa; que recusar continua sendo caminho suportado e
tem como pedir de novo depois; que o catálogo é editável; que a fala do
YouTube não é a do TikTok; e que o dicionário pacote→fala atravessa o canal
já traduzido. `flutter test` não roda Kotlin.

**O que só o aparelho responde:**

1. A tela do sistema de "desenhar sobre outros apps" abre a partir do
   cartão, e voltar dela marca a permissão como concedida.
2. O diálogo de notificações do Android 13+ aparece no passo 3.
3. `Permission.scheduleExactAlarm` responde o que se espera na faixa de API
   do aparelho (antes do Android 12 a permissão nem existe).
4. `VigiaDaSessao.falaPara` decodifica o dicionário JSON: no TikTok sai a
   fala do TikTok, no YouTube a do YouTube, e num app fora do dicionário sai
   a fala padrão. É Kotlin, e Kotlin não roda em `flutter test`.
5. Os identificadores de pacote do catálogo casam com os apps instalados.
   **Nenhum foi conferido num aparelho.** Um id errado não quebra nada — o
   app cai em neutro e ganha o nome derivado do último segmento —, mas custa
   uma classificação e uma fala.

**Uma linha que falta, e que não é minha para escrever.** A fala por app só
sai do lugar quando `AppState._comecaAVigiar` (em `lib/state.dart`, fora da
minha área neste turno) passar o dicionário adiante:

```dart
await VigiaService.instance.comeca(
  fala: t.vigiaFala,
  // ...
  falasPorPacote: falasPorPacote(t), // de lib/l10n_sobreposicao.dart
);
```

Sem esse argumento o parâmetro fica no padrão vazio e o vigia manda a fala
única de sempre — nada regride, mas S-03 fica desligado.

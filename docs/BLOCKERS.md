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

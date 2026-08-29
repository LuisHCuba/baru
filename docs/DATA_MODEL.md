# Modelo de dados — Baru (Supabase / Postgres 17)

**15 tabelas**, todas com RLS habilitada. O projeto remoto é `Baru`
(`slqpuppkapiewjqvedtj`, sa-east-1).

Migrações: `baru_app/supabase/migrations/`. As migrations 10, 11, 14, 15 e 16
**não estão aplicadas no remoto** — ver BL-12 e BL-16 em
[BLOCKERS.md](BLOCKERS.md). O app funciona sem elas (§ "Degradação por
coluna"); o que não acontece é o dado chegar ao segundo aparelho.

A última contagem executada contra banco limpo é a registrada em BL-10: 15
tabelas, 58 políticas, nenhuma tabela sem RLS. As migrations 14, 15 e 16 são
aditivas e não criam tabela nem política, então não mexem nesses números —
mas isso não foi reexecutado.

## Princípio

O app mantém um snapshot local único (`AppSnapshot`) e o **decompõe** em
tabelas de domínio no push (`BaruRowCodec`). Cada tabela tem `user_id` como
chave (ou parte dela) com FK para `auth.users(id) on delete cascade`: apagar a
conta apaga tudo, sem job de limpeza.

Humor e atividade do pet **não são persistidos** — são derivados no app a partir
de uso, meta e sessões (ver [PRODUCT.md](PRODUCT.md) §3).

### O que não vira coluna

Duas regras, nesta ordem:

1. **Derivável não vira coluna.** Os contadores das missões do dia e da semana
   — `minutosDeFocoHoje`, `maiorSessaoHoje`, `sessoesNaSemana`,
   `minutosNaSemana` — são somas sobre `baru_sessions`, que já sobe inteira.
   `BaruRowCodec.contadoresDe` refaz a conta na leitura. Coluna para eles seria
   um segundo registro do mesmo fato, e dois registros do mesmo fato divergem
   sem ninguém notar. Ver ADR-021.
2. **Efêmero de aparelho não vira coluna.** A sessão de foco em curso
   (`sessionStartedAt`, `sessionEndsAt`, `sessionDur`) e a tentativa de
   descanso (`descansoComecouEm`, `descansoTelaNoInicio`,
   `descansoNoAppSegundos`, `melhorDescansoMinutos`): nenhuma continua em outro
   telefone, e o melhor descanso zera à meia-noite.

Todo o resto do `AppSnapshot` tem coluna. `test/ida_e_volta_test.dart`
enumera os campos a partir do próprio `toJson()` e falha quando aparece um
campo que não está de nenhum dos dois lados — é o teste que impede o próximo
buraco.

### Fuso

`timestamptz` guarda instante, não relógio de parede. O codec escreve
`started_at` e `trial_started_at` com `.toUtc()` **antes** do ISO: sem o fuso
na string, o Postgres assume UTC e o instante escorrega pelo tamanho do fuso
de quem estava usando o app. Na volta, `.toLocal()`, porque o resto do app
compara com `DateTime.now()`.

### Degradação por coluna

O repositório anda na frente da migração — é o normal deste projeto. O push
usa `BaruSupabase._upsertTolerante`: a coluna recusada com `PGRST204`/`42703`
sai do corpo e a linha sobe sem ela, em vez de o domínio inteiro falhar.
Degrada **só** pelo que está declarado em `BaruSupabase.colunasOpcionais`, que
lista exatamente as colunas acrescentadas depois das tabelas base; coluna que
sempre existiu continua estourando, porque sumir seria defeito de schema. A
recusa é lembrada por sessão, e vale também para a leitura.

Na leitura, coluna ausente cai no padrão do app: som ligado, contador da
semana zero, e `equipados` **vazio** — sem a coluna o remoto não tem opinião
sobre o que está em uso, e `fundeCom` mantém a do aparelho.

## Tabelas

### Conta e navegação

**`baru_profiles`** — PK `user_id`
| Coluna | Tipo | Papel |
|---|---|---|
| `user_id` | uuid NOT NULL | FK `auth.users` |
| `device_id` | text NOT NULL | uuid gerado no dispositivo (`baru_device_id` em prefs) |
| `screen` | text NOT NULL | última tela (`session` nunca é gravada; vira `home`) |
| `onb` | integer NOT NULL | passo do onboarding |
| `lang` | text NOT NULL | `pt`/`en`/`es`/`zh` |
| `companionship_started` | boolean NOT NULL | primeiro dia real já ocorreu |
| `last_open_date` | date NOT NULL | base do avanço de calendário |
| `updated_at` | timestamptz NOT NULL | |

Era monolítica na migration 1 e foi reduzida a estas 8 colunas na migration 5.
O gateway detecta o formato legado testando `species`/`leaves` na linha.

**`baru_onboarding_answers`** — PK `user_id` · `q0`, `q1`, `q2` (text),
`respostas` jsonb, `updated_at`

`respostas` é `{id_da_pergunta: id_da_opcao}` com ids estáveis que nunca são
traduzidos (migration 13). As três colunas antigas continuam sendo escritas,
agora com o id — apagá-las seria migração destrutiva num banco com dados
reais. A dívida que isso pagou: o label dependia do idioma, então trocar de
idioma invalidava a correspondência com os pesos do quiz, e havia um `if` no
`setLang` apagando as três de propósito.

### Pet e economia

**`baru_pets`** — PK `user_id`
`species`, `pet_name`, `coat` (check 0–8), `sexo`
(check `naoDito|macho|femea`), `updated_at`.

O `check` de `species` caiu na migration 12: o catálogo vive no app e valor
desconhecido cai na capivara pelo `parseSpecies`.

O `check` de `coat` **fica**. As nove paletas têm seis tons cada, então o
índice máximo hoje é 5 e sobram três de folga; `setColor` e `pickSpecies` já
prendem o índice ao tamanho da paleta **da espécie**. O risco não é o de hoje:
uma paleta de dez tons deixaria `setColor(9)` passar no app e o banco recusaria
a **linha inteira** — nome, espécie e sexo junto — com um "erro ao sincronizar"
que não diz o que houve. `test/ida_e_volta_test.dart` falha no dia em que
alguma paleta passar do teto, o que torna o `check` seguro de deixar como está.

**`baru_wallets`** — PK `user_id` · `leaves` integer (check ≥ 0), `updated_at`.

**`baru_inventory_items`** — PK `(user_id, item_id)`
`item_id` (o check de ids fechado caiu na migration 11: eram 8 itens, agora são
17, e quem tem o catálogo é o app), `equipped` boolean default true,
`acquired_at` timestamptz. Índice `baru_inventory_user_idx (user_id)`.
O push usa `resolution=ignore-duplicates`, então `acquired_at` de item que já
está no inventário é preservado — antes todo push reescrevia a data real da
compra e embaralhava a ordem em que o habitat foi montado. Um segundo `upsert`
manda só `equipped`, porque `ignore-duplicates` não atualiza linha existente.

A leitura pede `item_id, equipped`. Pedia **só** `item_id`, e sem a chave no
mapa o codec tratava todo item possuído como em uso: `equipped` era escrito e
nunca lido, e tirar uma peça do habitat não sobrevivia ao arranque seguinte.

### Foco e presença

**`baru_sessions`** — PK `id` (uuid gerado no app)
`user_id`, `started_at`, `duration_min`, `completed`, `aborted`, `reward`,
`created_at`. Índice `baru_sessions_user_started_idx (user_id, started_at desc)`.
O app mantém as **últimas 80** sessões no snapshot local.

**`baru_streaks`** — PK `user_id`
`streak`, `today_index` (check 0–6), `freezes_left`, `days_away`, `updated_at`.

**`baru_week_calendar`** — PK `(user_id, day_index)`
`day_index` 0–6 (segunda = 0), `kind` check `present|frozen|today|empty`.

**`baru_daily_progress`** — PK `user_id`
`completed_sessions`, `abandoned_today`, `updated_at`. Estado do dia corrente.

**`baru_daily_quests`** — PK `(user_id, quest_date, quest_key)` — **sem
escritor desde 2026-08-28**
`quest_key` check `focus_session|under_goal`, `completed`, `completed_at`.
Índice `baru_daily_quests_user_date_idx (user_id, quest_date desc)`.

Fóssil do desenho anterior ao quadro de missões. O app escrevia nela a cada
`pushStreak` e **nunca leu**: os dois valores são derivados de
`baru_daily_progress.completed_sessions` e de
`baru_screen_time.usage_min < goal_min`, e o registro de missão que o produto
usa é `baru_progression.missoes_resgatadas`, com o período dentro da chave
(`id@periodo`) — que é o que torna o resgate idempotente. O `check` aceita duas
chaves; o sistema de missões tem 17 tipos.

Não foi derrubada: o banco tem dados reais, `drop table` apagaria o histórico
de quem usou o app antes e não devolveria nada. A RLS não mudou, o
`on delete cascade` continua valendo, e a tabela segue em `tabelasDoUsuario`,
então apagar a conta continua alcançando-a. Ver ADR-022 e a migration 16.

### Progressão e vínculo

**`baru_progression`** — PK `user_id`
`xp`, `nivel_celebrado`, `afeto`, `carinhos_hoje`, `marcos_resgatados` text[],
`missoes_resgatadas` text[], `sessoes_concluidas`, `melhor_sequencia`,
`dias_abaixo_da_meta`, `dias_abaixo_na_semana`, `semana_de` date,
`updated_at`.

Quase tudo aqui só sobe, e é por isso que `fundeCom` fica com o maior de cada
um: nenhum pode diminuir por sincronização. `marcos_resgatados` e
`missoes_resgatadas` viram união — conquista não se retira.

`dias_abaixo_na_semana` é a exceção que zera, e por isso anda com `semana_de`,
a segunda-feira da semana a que pertence. A zeragem acontece na virada da
segunda **dentro do aparelho** e não marca sincronização; sem o carimbo, o
número da semana passada continuaria valendo e a semana nova começaria com a
missão semanal meio cumprida. Carimbo de outra semana — ou ausente — vale zero.

Ele é o único dos cinco contadores de missão que virou coluna: os quatro de
foco saem de `baru_sessions` (ver "O que não vira coluna"), e este depende do
tempo de tela de **cada dia fechado**, que o app não guarda em lugar nenhum.

`carinhos_hoje` é do dia e **não** tem carimbo de dia. Numa fusão logo depois
da virada, o valor de ontem pode voltar e comer o teto de XP por carinho do
dia novo — o custo é um afago que não paga, e nunca dado perdido. Se virar
incômodo, o remédio é o mesmo `semana_de`, com o dia no lugar da semana.

### Tela e assinatura

**`baru_settings`** — PK `user_id`
`evening_notif`, `evening_hour` (0–23), `evening_minute` (0–59),
`missed_notif`, `usage_access`, `default_duration_min` (check em 25/45/50/90),
`som` (default true), `updated_at`.

`som` entrou na migration 14. Estava no snapshot local desde sempre e em lugar
nenhum do banco: o interruptor marcava o domínio de ajustes para sincronizar, a
linha subia, e o som não ia junto porque não havia coluna. Quem desligava o som
reinstalava o app e ele voltava ligado.

**`baru_screen_time`** — PK `user_id`
`usage_min` (≥0), `goal_min` (>0), `avg_min` (>0), `updated_at`.
**Só o agregado diário.** Nunca por aplicativo, nunca conteúdo — ver
[PRODUCT.md](PRODUCT.md) §8.

**`baru_subscriptions`** — PK `user_id`
`trial_active`, `pay_plan` (check `annual|monthly`), `trial_started_at`,
`updated_at`.

### Categorias de app

**`baru_app_categories`** — PK `(user_id, package_name)`
`category` com check `dispersivo|neutro|produtivo|passivo`, `updated_at`.
Índice `baru_app_categories_user_idx (user_id)`.

Guarda as reclassificações que o usuário fez à mão; elas ganham da tabela
embutida no app. Quem usa o YouTube para estudar precisa poder discordar, e a
discordância tem de sobreviver a trocar de aparelho.

O **detalhamento** de tempo de tela (por app, por categoria) **não** é
persistido: é recalculado a cada leitura dos eventos do sistema. Só o agregado
do dia vai para `baru_screen_time`.

## RLS

Todas as 15 tabelas com `row level security` habilitada, **58 políticas**:

- `baru_profiles` e `baru_sessions`: `select`, `insert`, `update` (3 cada).
- As 13 tabelas de domínio: `select`, `insert`, `update`, `delete` (4 cada) —
  `delete` existe porque o push da loja remove itens que saíram do inventário.

Padrão de toda política: papel `authenticated`, predicado `auth.uid() = user_id`
em `using` e `with check`. Nenhuma política para `anon`. `service_role` nunca é
usado no cliente.

### Verificação executada

Rodada no banco real (dentro de transação, com `rollback`):

| Cenário | Resultado |
|---|---|
| `set role anon` → `select count(*) from baru_profiles` | 0 linhas |
| `set role authenticated` com `sub` de outro uuid → profiles/wallets/sessions/inventory | 0, 0, 0, 0 |

## Divergências entre repositório e banco

1. **`public.rls_auto_enable()`** existe no banco (event trigger,
   `SECURITY DEFINER`, liga RLS automaticamente em tabela nova criada em
   `public`) e **não estava em nenhuma migration**. Adotada em migration —
   ver ADR-002.
2. **Não existe `supabase_migrations.schema_migrations`**: as migrations foram
   aplicadas à mão pelo SQL Editor, sem ledger. Ver BL-01 em
   [BLOCKERS.md](BLOCKERS.md).

## Validação

### Contra banco limpo — última execução: 6 migrations (2026-08-26)

`supabase start` + `supabase db reset` aplicaram as **6 migrations de então**
do zero. O schema resultante era idêntico ao remoto: 13 tabelas, 50 políticas,
`baru_profiles` com 8 colunas, event trigger `ensure_rls` presente, nenhuma
tabela sem RLS, `anon` sem `EXECUTE` sobre `rls_auto_enable`.

Reaplicação: migrations 5 e 6 rodam de novo sem erro (`ON_ERROR_STOP=1`). A
versão antiga da 5, tirada do histórico do git, falha com
`column "species" does not exist` — a previsão do ADR-003.

**As migrations 7 a 16 não passaram por esse ciclo completo.** A 7 e a 8 foram
validadas contra banco limpo (BL-10); de 9 em diante, não. Repetir exige
Docker.

### Sem banco, a cada `flutter test`

`test/ida_e_volta_test.dart` prova o que não precisa de Postgres, e é o que
impede o próximo buraco:

- todo campo do `AppSnapshot` está classificado — sincroniza ou tem razão
  escrita para ficar no aparelho — e a lista sai do `toJson()`, então campo
  novo quebra o teste até alguém decidir;
- o snapshot cheio (valor não-padrão em cada campo) é decomposto em linhas e
  remontado, e cada campo sincronizado volta idêntico;
- o que é local por desenho **não** volta;
- toda coluna que o codec escreve existe em alguma migration — o arquivo
  `.sql` é lido de verdade;
- toda coluna acrescentada por migration está declarada em
  `BaruSupabase.colunasOpcionais`, senão o push não degrada;
- o índice de pelagem cabe no `check` de `baru_pets.coat`.

### Contra Postgres de verdade

`test/integration/supabase_roundtrip_test.dart` escreve as **14 tabelas** que
o app grava com o token de um usuário comum e reconstrói o snapshot pela
leitura, o que exercita schema, CHECKs, RLS e o codec nas duas direções. Pede
`BARU_TEST_URL` e `BARU_TEST_KEY`; sem elas é pulado, e a suíte normal não
depende de Docker.

## Seed

`supabase/seed.sql` popula as tabelas de domínio para uma conta que já exista
em `auth.users`. Roda sozinho em `supabase db reset` e é idempotente. Não cria
usuário: criar conta por SQL depende de colunas internas do gotrue, que mudam
entre versões.

## Avisos do linter de segurança do Supabase

| Aviso | Situação |
|---|---|
| `anon`/`authenticated` podem executar `rls_auto_enable()` | Risco prático baixo: função de event trigger não é invocável via RPC. Mitigado com `revoke execute` na migration de adoção (ADR-002). |
| Proteção contra senha vazada desligada | Ação de dashboard — ver [BLOCKERS.md](BLOCKERS.md). |

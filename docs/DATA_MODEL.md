# Modelo de dados — Baru (Supabase / Postgres 17)

Verificado contra o banco real do projeto `Baru`
(`slqpuppkapiewjqvedtj`, sa-east-1) — 13 tabelas, todas com RLS habilitada.

Migrações: `baru_app/supabase/migrations/`.

## Princípio

O app mantém um snapshot local único (`AppSnapshot`) e o **decompõe** em
tabelas de domínio no push (`BaruRowCodec`). Cada tabela tem `user_id` como
chave (ou parte dela) com FK para `auth.users(id) on delete cascade`: apagar a
conta apaga tudo, sem job de limpeza.

Humor e atividade do pet **não são persistidos** — são derivados no app a partir
de uso, meta e sessões (ver [PRODUCT.md](PRODUCT.md) §3).

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

**`baru_onboarding_answers`** — PK `user_id` · `q0`, `q1`, `q2` (text), `updated_at`
Respostas do quiz **como labels localizados**. Dívida: o label depende do
idioma, então trocar de idioma invalida a correspondência com os pesos.

### Pet e economia

**`baru_pets`** — PK `user_id`
`species` (check: capybara/otter/tortoise/owl), `pet_name`, `coat`
(check 0–8; o app usa 0–3), `updated_at`.

**`baru_wallets`** — PK `user_id` · `leaves` integer (check ≥ 0), `updated_at`.

**`baru_inventory_items`** — PK `(user_id, item_id)`
`item_id` com check para os 8 itens da loja; `acquired_at` timestamptz.
Índice `baru_inventory_user_idx (user_id)`.
Dívida: o codec regrava `acquired_at = now()` a cada push, apagando a data real.

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

**`baru_daily_quests`** — PK `(user_id, quest_date, quest_key)`
`quest_key` check `focus_session|under_goal`, `completed`, `completed_at`.
Índice `baru_daily_quests_user_date_idx (user_id, quest_date desc)`.

### Tela e assinatura

**`baru_settings`** — PK `user_id`
`evening_notif`, `missed_notif`, `usage_access`, `default_duration_min`
(check em 25/45/50/90), `updated_at`.

**`baru_screen_time`** — PK `user_id`
`usage_min` (≥0), `goal_min` (>0), `avg_min` (>0), `updated_at`.
**Só o agregado diário.** Nunca por aplicativo, nunca conteúdo — ver
[PRODUCT.md](PRODUCT.md) §8.

**`baru_subscriptions`** — PK `user_id`
`trial_active`, `pay_plan` (check `annual|monthly`), `trial_started_at`,
`updated_at`.

## RLS

Todas as 13 tabelas com `row level security` habilitada, **50 políticas**:

- `baru_profiles` e `baru_sessions`: `select`, `insert`, `update` (3 cada).
- As 11 tabelas de domínio: `select`, `insert`, `update`, `delete` (4 cada) —
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
2. **Não existe `supabase_migrations.schema_migrations`**: as 5 migrations
   foram aplicadas à mão pelo SQL Editor, sem ledger. Ver
   [BLOCKERS.md](BLOCKERS.md).

## Avisos do linter de segurança do Supabase

| Aviso | Situação |
|---|---|
| `anon`/`authenticated` podem executar `rls_auto_enable()` | Risco prático baixo: função de event trigger não é invocável via RPC. Mitigado com `revoke execute` na migration de adoção (ADR-002). |
| Proteção contra senha vazada desligada | Ação de dashboard — ver [BLOCKERS.md](BLOCKERS.md). |

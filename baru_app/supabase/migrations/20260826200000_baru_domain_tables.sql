-- 3/5 — Domínio Baru normalizado (além de baru_profiles monolítico do 000).
-- Requer 20260826190000_create_baru_tables.sql.
-- Separa pet, loja, settings, streak, tempo de tela, assinatura e quests.
-- O 005 reduz baru_profiles à conta/navegação e migra dados legados.
-- Aplicar localmente (Dashboard ou CLI). Agente NÃO aplica no remoto.

-- ---------------------------------------------------------------------------
-- Pet (espécie, nome, pelagem)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_pets (
  user_id uuid primary key references auth.users (id) on delete cascade,
  species text not null default 'capybara'
    check (species in ('capybara', 'otter', 'tortoise', 'owl')),
  pet_name text not null default '',
  coat integer not null default 0 check (coat >= 0 and coat <= 8),
  updated_at timestamptz not null default now()
);

comment on table public.baru_pets is 'Identidade visual do pet por usuário.';

-- ---------------------------------------------------------------------------
-- Onboarding / quiz (3 respostas → espécie)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_onboarding_answers (
  user_id uuid primary key references auth.users (id) on delete cascade,
  q0 text,
  q1 text,
  q2 text,
  updated_at timestamptz not null default now()
);

comment on table public.baru_onboarding_answers is 'Respostas do quiz de onboarding (labels localizados).';

-- ---------------------------------------------------------------------------
-- Moeda (folhas)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_wallets (
  user_id uuid primary key references auth.users (id) on delete cascade,
  leaves integer not null default 0 check (leaves >= 0),
  updated_at timestamptz not null default now()
);

comment on table public.baru_wallets is 'Saldo de folhas (currency do habitat).';

-- ---------------------------------------------------------------------------
-- Inventário / loja (itens possuídos)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_inventory_items (
  user_id uuid not null references auth.users (id) on delete cascade,
  item_id text not null
    check (item_id in ('lily', 'bamboo', 'rock', 'dock', 'lantern', 'tree', 'boat', 'bridge')),
  acquired_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

create index if not exists baru_inventory_user_idx
  on public.baru_inventory_items (user_id);

comment on table public.baru_inventory_items is 'Itens comprados e colocados no habitat.';

-- ---------------------------------------------------------------------------
-- Settings (notificações, permissão de uso, duração padrão de sessão)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  evening_notif boolean not null default true,
  missed_notif boolean not null default true,
  usage_access boolean not null default false,
  default_duration_min integer not null default 25
    check (default_duration_min in (25, 45, 50, 90)),
  updated_at timestamptz not null default now()
);

comment on table public.baru_settings is 'Preferências de notificação, permissão de screen time e duração padrão.';

-- ---------------------------------------------------------------------------
-- Meta de tempo de tela (usage / goal / avg do dia corrente)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_screen_time (
  user_id uuid primary key references auth.users (id) on delete cascade,
  usage_min integer not null default 0 check (usage_min >= 0),
  goal_min integer not null default 180 check (goal_min > 0),
  avg_min integer not null default 240 check (avg_min > 0),
  updated_at timestamptz not null default now()
);

comment on table public.baru_screen_time is 'Uso diário de tela e metas configuradas pelo usuário.';

-- ---------------------------------------------------------------------------
-- Streak / calendário semanal
-- ---------------------------------------------------------------------------
create table if not exists public.baru_streaks (
  user_id uuid primary key references auth.users (id) on delete cascade,
  streak integer not null default 0 check (streak >= 0),
  today_index integer not null default 0 check (today_index between 0 and 6),
  freezes_left integer not null default 1 check (freezes_left >= 0),
  days_away integer not null default 0 check (days_away >= 0),
  updated_at timestamptz not null default now()
);

comment on table public.baru_streaks is 'Contadores de presença, freeze e dias ausente.';

create table if not exists public.baru_week_calendar (
  user_id uuid not null references auth.users (id) on delete cascade,
  day_index integer not null check (day_index between 0 and 6),
  kind text not null default 'empty'
    check (kind in ('present', 'frozen', 'today', 'empty')),
  primary key (user_id, day_index)
);

comment on table public.baru_week_calendar is 'Estado visual de cada dia da semana (seg=0 … dom=6).';

-- ---------------------------------------------------------------------------
-- Progresso do dia (sessões completadas hoje, abandono)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_daily_progress (
  user_id uuid primary key references auth.users (id) on delete cascade,
  completed_sessions integer not null default 0 check (completed_sessions >= 0),
  abandoned_today boolean not null default false,
  updated_at timestamptz not null default now()
);

comment on table public.baru_daily_progress is 'Estado do dia corrente (reseta ao avançar calendário).';

-- ---------------------------------------------------------------------------
-- Quests diárias (foco + meta de tela)
-- ---------------------------------------------------------------------------
create table if not exists public.baru_daily_quests (
  user_id uuid not null references auth.users (id) on delete cascade,
  quest_date date not null default (timezone('utc', now()))::date,
  quest_key text not null
    check (quest_key in ('focus_session', 'under_goal')),
  completed boolean not null default false,
  completed_at timestamptz,
  primary key (user_id, quest_date, quest_key)
);

create index if not exists baru_daily_quests_user_date_idx
  on public.baru_daily_quests (user_id, quest_date desc);

comment on table public.baru_daily_quests is 'Quests do dia: uma sessão de foco e fechar abaixo da meta.';

-- ---------------------------------------------------------------------------
-- Assinatura / trial
-- ---------------------------------------------------------------------------
create table if not exists public.baru_subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  trial_active boolean not null default false,
  pay_plan text not null default 'annual'
    check (pay_plan in ('annual', 'monthly')),
  trial_started_at timestamptz,
  updated_at timestamptz not null default now()
);

comment on table public.baru_subscriptions is 'Trial de 7 dias e plano de pagamento escolhido.';

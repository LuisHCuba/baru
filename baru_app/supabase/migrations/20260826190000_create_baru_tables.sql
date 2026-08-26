-- 1/2 — Tabelas do habitat Baru (perfil + histórico de sessões).
-- Ainda sem RLS: o arquivo seguinte liga as políticas.
-- Aplicar ANTES de 20260826190001_baru_rls.sql.
-- O usuário aplica (Dashboard SQL Editor ou CLI). Não rodar contra produção por agente.

create table if not exists public.baru_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  device_id text not null,
  screen text not null default 'onb',
  onb integer not null default 0,
  lang text not null default 'pt',
  species text not null default 'capybara',
  q0 text,
  q1 text,
  q2 text,
  leaves integer not null default 0,
  streak integer not null default 0,
  usage_min integer not null default 0,
  goal_min integer not null default 180,
  avg_min integer not null default 240,
  pet_name text not null default '',
  coat integer not null default 0,
  owned text[] not null default '{}',
  dur integer not null default 25,
  completed_today integer not null default 0,
  abandoned_today boolean not null default false,
  days_away integer not null default 0,
  trial boolean not null default false,
  evening boolean not null default true,
  missed boolean not null default true,
  pay_plan text not null default 'annual',
  usage_access boolean not null default false,
  companionship_started boolean not null default false,
  week text[] not null default '{}',
  today_index integer not null default 0,
  freezes_left integer not null default 1,
  trial_started_at timestamptz,
  last_open_date date not null default current_date,
  updated_at timestamptz not null default now()
);

create table if not exists public.baru_sessions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  started_at timestamptz not null,
  duration_min integer not null,
  completed boolean not null default false,
  aborted boolean not null default false,
  reward integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists baru_sessions_user_started_idx
  on public.baru_sessions (user_id, started_at desc);

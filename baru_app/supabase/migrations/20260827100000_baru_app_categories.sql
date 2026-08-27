-- 7/7 — Reclassificação de apps feita pelo usuário.
--
-- O app classifica cada pacote em dispersivo / neutro / produtivo / passivo
-- para decidir o que entra na meta diária. A tabela embutida cobre os apps
-- mais comuns, mas quem usa o YouTube para estudar precisa poder discordar —
-- e a discordância tem de sobreviver a trocar de aparelho.
--
-- Idempotente: pode ser reaplicada sem erro.

create table if not exists public.baru_app_categories (
  user_id uuid not null references auth.users (id) on delete cascade,
  package_name text not null,
  category text not null
    check (category in ('dispersivo', 'neutro', 'produtivo', 'passivo')),
  updated_at timestamptz not null default now(),
  primary key (user_id, package_name)
);

create index if not exists baru_app_categories_user_idx
  on public.baru_app_categories (user_id);

comment on table public.baru_app_categories is
  'Reclassificacoes de app feitas pelo usuario. Ganham da tabela embutida no app.';

-- O event trigger `ensure_rls` (migration 6) já liga RLS em tabela nova de
-- public, mas deixar explícito é o que torna o arquivo auditável sozinho.
alter table public.baru_app_categories enable row level security;

drop policy if exists baru_app_categories_select on public.baru_app_categories;
drop policy if exists baru_app_categories_insert on public.baru_app_categories;
drop policy if exists baru_app_categories_update on public.baru_app_categories;
drop policy if exists baru_app_categories_delete on public.baru_app_categories;

create policy baru_app_categories_select
  on public.baru_app_categories for select to authenticated
  using (auth.uid() = user_id);

create policy baru_app_categories_insert
  on public.baru_app_categories for insert to authenticated
  with check (auth.uid() = user_id);

create policy baru_app_categories_update
  on public.baru_app_categories for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy baru_app_categories_delete
  on public.baru_app_categories for delete to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete
  on public.baru_app_categories to authenticated;

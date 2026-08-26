-- 2/2 — RLS do habitat Baru.
-- Requer as tabelas de 20260826190000_create_baru_tables.sql.
-- Papel `authenticated` (inclui sign-in anônimo). UPDATE também tem SELECT.
-- Sem policies para `anon` não autenticado. Sem service_role no client.

alter table public.baru_profiles enable row level security;
alter table public.baru_sessions enable row level security;

drop policy if exists baru_profiles_select on public.baru_profiles;
drop policy if exists baru_profiles_insert on public.baru_profiles;
drop policy if exists baru_profiles_update on public.baru_profiles;
drop policy if exists baru_sessions_select on public.baru_sessions;
drop policy if exists baru_sessions_insert on public.baru_sessions;
drop policy if exists baru_sessions_update on public.baru_sessions;

create policy baru_profiles_select
  on public.baru_profiles for select to authenticated
  using (auth.uid() = user_id);

create policy baru_profiles_insert
  on public.baru_profiles for insert to authenticated
  with check (auth.uid() = user_id);

create policy baru_profiles_update
  on public.baru_profiles for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy baru_sessions_select
  on public.baru_sessions for select to authenticated
  using (auth.uid() = user_id);

create policy baru_sessions_insert
  on public.baru_sessions for insert to authenticated
  with check (auth.uid() = user_id);

create policy baru_sessions_update
  on public.baru_sessions for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update on public.baru_profiles to authenticated;
grant select, insert, update on public.baru_sessions to authenticated;

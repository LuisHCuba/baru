-- 4/5 — RLS das tabelas de domínio (20260826200000).
-- Requer policies base de 20260826190001_baru_rls.sql.
-- Padrão: auth.uid() = user_id; UPDATE exige SELECT + UPDATE.
-- Sem policies para anon; sem service_role no client.

alter table public.baru_pets enable row level security;
alter table public.baru_onboarding_answers enable row level security;
alter table public.baru_wallets enable row level security;
alter table public.baru_inventory_items enable row level security;
alter table public.baru_settings enable row level security;
alter table public.baru_screen_time enable row level security;
alter table public.baru_streaks enable row level security;
alter table public.baru_week_calendar enable row level security;
alter table public.baru_daily_progress enable row level security;
alter table public.baru_daily_quests enable row level security;
alter table public.baru_subscriptions enable row level security;

-- Helper: políticas idempotentes por tabela
do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'baru_pets',
    'baru_onboarding_answers',
    'baru_wallets',
    'baru_inventory_items',
    'baru_settings',
    'baru_screen_time',
    'baru_streaks',
    'baru_week_calendar',
    'baru_daily_progress',
    'baru_daily_quests',
    'baru_subscriptions'
  ]
  loop
    execute format('drop policy if exists %I_select on public.%I', tbl, tbl);
    execute format('drop policy if exists %I_insert on public.%I', tbl, tbl);
    execute format('drop policy if exists %I_update on public.%I', tbl, tbl);
    execute format('drop policy if exists %I_delete on public.%I', tbl, tbl);

    execute format(
      'create policy %I_select on public.%I for select to authenticated using (auth.uid() = user_id)',
      tbl, tbl
    );
    execute format(
      'create policy %I_insert on public.%I for insert to authenticated with check (auth.uid() = user_id)',
      tbl, tbl
    );
    execute format(
      'create policy %I_update on public.%I for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)',
      tbl, tbl
    );
    execute format(
      'create policy %I_delete on public.%I for delete to authenticated using (auth.uid() = user_id)',
      tbl, tbl
    );

    execute format(
      'grant select, insert, update, delete on public.%I to authenticated',
      tbl
    );
  end loop;
end $$;

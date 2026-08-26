-- 5/5 — Migra dados do baru_profiles monolítico (000) → tabelas de domínio;
-- depois remove colunas redundantes, deixando só conta/navegação.
-- Seguro para banco novo (000+001+002+003) ou já populado só com 000/001.
-- Aplicar por último na ordem lexicográfica.
--
-- Idempotência (ADR-003): a cópia legado → domínio roda dentro de um bloco
-- `do $$ ... execute ... $$`. Guardas com `where exists (information_schema)`
-- em SQL estático NÃO funcionam aqui: as colunas legadas aparecem na lista de
-- `select`, então o comando falharia no *parse* — antes de qualquer guarda ser
-- avaliada — assim que elas fossem removidas. Com `execute`, o SQL só é
-- compilado quando as colunas existem, e reaplicar o arquivo é inofensivo.
--
-- Todas as colunas legadas nasceram juntas na migration 000 e são removidas
-- juntas no `alter table` do fim deste arquivo, então testar uma (`species`)
-- decide por todas.

do $$
declare
  tem_legado boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'baru_profiles'
      and column_name = 'species'
  ) into tem_legado;

  if not tem_legado then
    raise notice 'baru: baru_profiles ja esta slim; nada a copiar';
    return;
  end if;

  -- Pet -----------------------------------------------------------------
  execute $sql$
    insert into public.baru_pets (user_id, species, pet_name, coat, updated_at)
    select user_id, species, pet_name, coat, coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      species = excluded.species,
      pet_name = excluded.pet_name,
      coat = excluded.coat,
      updated_at = excluded.updated_at
  $sql$;

  -- Onboarding ----------------------------------------------------------
  execute $sql$
    insert into public.baru_onboarding_answers (user_id, q0, q1, q2, updated_at)
    select user_id, q0, q1, q2, coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      q0 = excluded.q0,
      q1 = excluded.q1,
      q2 = excluded.q2,
      updated_at = excluded.updated_at
  $sql$;

  -- Carteira ------------------------------------------------------------
  execute $sql$
    insert into public.baru_wallets (user_id, leaves, updated_at)
    select user_id, leaves, coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      leaves = excluded.leaves,
      updated_at = excluded.updated_at
  $sql$;

  -- Inventário ----------------------------------------------------------
  execute $sql$
    insert into public.baru_inventory_items (user_id, item_id, acquired_at)
    select p.user_id, unnest(p.owned), coalesce(p.updated_at, now())
    from public.baru_profiles p
    where p.owned is not null
      and cardinality(p.owned) > 0
    on conflict (user_id, item_id) do nothing
  $sql$;

  -- Settings ------------------------------------------------------------
  execute $sql$
    insert into public.baru_settings (
      user_id, evening_notif, missed_notif, usage_access, default_duration_min, updated_at
    )
    select
      user_id,
      coalesce(evening, true),
      coalesce(missed, true),
      coalesce(usage_access, false),
      coalesce(dur, 25),
      coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      evening_notif = excluded.evening_notif,
      missed_notif = excluded.missed_notif,
      usage_access = excluded.usage_access,
      default_duration_min = excluded.default_duration_min,
      updated_at = excluded.updated_at
  $sql$;

  -- Tempo de tela -------------------------------------------------------
  execute $sql$
    insert into public.baru_screen_time (user_id, usage_min, goal_min, avg_min, updated_at)
    select
      user_id,
      coalesce(usage_min, 0),
      coalesce(goal_min, 180),
      coalesce(avg_min, 240),
      coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      usage_min = excluded.usage_min,
      goal_min = excluded.goal_min,
      avg_min = excluded.avg_min,
      updated_at = excluded.updated_at
  $sql$;

  -- Streak --------------------------------------------------------------
  execute $sql$
    insert into public.baru_streaks (
      user_id, streak, today_index, freezes_left, days_away, updated_at
    )
    select
      user_id,
      coalesce(streak, 0),
      coalesce(today_index, 0),
      coalesce(freezes_left, 1),
      coalesce(days_away, 0),
      coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      streak = excluded.streak,
      today_index = excluded.today_index,
      freezes_left = excluded.freezes_left,
      days_away = excluded.days_away,
      updated_at = excluded.updated_at
  $sql$;

  -- Calendário da semana ------------------------------------------------
  execute $sql$
    insert into public.baru_week_calendar (user_id, day_index, kind)
    select p.user_id, gs.idx, coalesce(p.week[gs.idx + 1], 'empty')
    from public.baru_profiles p
    cross join generate_series(0, 6) as gs(idx)
    on conflict (user_id, day_index) do update set
      kind = excluded.kind
  $sql$;

  -- Progresso do dia ----------------------------------------------------
  execute $sql$
    insert into public.baru_daily_progress (
      user_id, completed_sessions, abandoned_today, updated_at
    )
    select
      user_id,
      coalesce(completed_today, 0),
      coalesce(abandoned_today, false),
      coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      completed_sessions = excluded.completed_sessions,
      abandoned_today = excluded.abandoned_today,
      updated_at = excluded.updated_at
  $sql$;

  -- Assinatura ----------------------------------------------------------
  execute $sql$
    insert into public.baru_subscriptions (
      user_id, trial_active, pay_plan, trial_started_at, updated_at
    )
    select
      user_id,
      coalesce(trial, false),
      coalesce(pay_plan, 'annual'),
      trial_started_at,
      coalesce(updated_at, now())
    from public.baru_profiles
    on conflict (user_id) do update set
      trial_active = excluded.trial_active,
      pay_plan = excluded.pay_plan,
      trial_started_at = excluded.trial_started_at,
      updated_at = excluded.updated_at
  $sql$;

  -- Quests derivadas do estado legado (dia corrente) ---------------------
  execute $sql$
    insert into public.baru_daily_quests (user_id, quest_date, quest_key, completed, completed_at)
    select
      p.user_id,
      coalesce(p.last_open_date, current_date),
      'focus_session',
      coalesce(p.completed_today, 0) >= 1,
      case when coalesce(p.completed_today, 0) >= 1 then coalesce(p.updated_at, now()) end
    from public.baru_profiles p
    on conflict (user_id, quest_date, quest_key) do update set
      completed = excluded.completed,
      completed_at = excluded.completed_at
  $sql$;

  execute $sql$
    insert into public.baru_daily_quests (user_id, quest_date, quest_key, completed, completed_at)
    select
      p.user_id,
      coalesce(p.last_open_date, current_date),
      'under_goal',
      coalesce(p.usage_access, false) and coalesce(p.usage_min, 0) < coalesce(p.goal_min, 180),
      case
        when coalesce(p.usage_access, false) and coalesce(p.usage_min, 0) < coalesce(p.goal_min, 180)
        then coalesce(p.updated_at, now())
      end
    from public.baru_profiles p
    on conflict (user_id, quest_date, quest_key) do update set
      completed = excluded.completed,
      completed_at = excluded.completed_at
  $sql$;
end $$;

-- Remove colunas duplicadas de baru_profiles (mantém conta/navegação).
-- `if exists` já torna este bloco reexecutável.
alter table public.baru_profiles
  drop column if exists species,
  drop column if exists q0,
  drop column if exists q1,
  drop column if exists q2,
  drop column if exists leaves,
  drop column if exists streak,
  drop column if exists usage_min,
  drop column if exists goal_min,
  drop column if exists avg_min,
  drop column if exists pet_name,
  drop column if exists coat,
  drop column if exists owned,
  drop column if exists dur,
  drop column if exists completed_today,
  drop column if exists abandoned_today,
  drop column if exists days_away,
  drop column if exists trial,
  drop column if exists evening,
  drop column if exists missed,
  drop column if exists pay_plan,
  drop column if exists usage_access,
  drop column if exists week,
  drop column if exists today_index,
  drop column if exists freezes_left,
  drop column if exists trial_started_at;

comment on table public.baru_profiles is
  'Conta Baru: navegação, onboarding, idioma, device_id e última abertura. Demais domínios em tabelas dedicadas.';

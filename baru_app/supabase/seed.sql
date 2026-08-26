-- Seed de desenvolvimento do Baru.
--
-- Roda sozinho em `supabase db reset` (convenção do CLI) e também pode ser
-- colado no SQL Editor. Popula as tabelas de domínio para uma conta que já
-- exista em auth.users — o seed **não cria usuário**: crie a conta pelo app ou
-- pelo Dashboard e rode isto depois.
--
-- Idempotente: reexecutar apenas atualiza as mesmas linhas.
--
-- NÃO rode contra produção com uma conta real: sobrescreve carteira,
-- inventário, streak e assinatura da conta escolhida.

do $$
declare
  alvo uuid;
  email_alvo text := coalesce(
    current_setting('baru.seed_email', true),
    ''
  );
begin
  if email_alvo <> '' then
    select id into alvo from auth.users where email = email_alvo;
    if alvo is null then
      raise notice 'baru seed: nenhum usuario com email %; nada feito', email_alvo;
      return;
    end if;
  else
    select id into alvo from auth.users order by created_at limit 1;
  end if;

  if alvo is null then
    raise notice 'baru seed: auth.users esta vazio. Crie a conta pelo app (ou pelo Dashboard) e rode de novo.';
    return;
  end if;

  raise notice 'baru seed: populando o usuario %', alvo;

  insert into public.baru_profiles (user_id, device_id, screen, onb, lang, companionship_started, last_open_date)
  values (alvo, 'seed', 'home', 5, 'pt', true, current_date)
  on conflict (user_id) do update set
    screen = excluded.screen, onb = excluded.onb, lang = excluded.lang,
    companionship_started = excluded.companionship_started,
    last_open_date = excluded.last_open_date, updated_at = now();

  insert into public.baru_pets (user_id, species, pet_name, coat)
  values (alvo, 'capybara', 'Baru', 0)
  on conflict (user_id) do update set
    species = excluded.species, pet_name = excluded.pet_name,
    coat = excluded.coat, updated_at = now();

  insert into public.baru_onboarding_answers (user_id, q0, q1, q2)
  values (alvo, 'Água', 'À tarde', 'Uma rotina')
  on conflict (user_id) do update set
    q0 = excluded.q0, q1 = excluded.q1, q2 = excluded.q2, updated_at = now();

  insert into public.baru_wallets (user_id, leaves)
  values (alvo, 120)
  on conflict (user_id) do update set leaves = excluded.leaves, updated_at = now();

  insert into public.baru_inventory_items (user_id, item_id)
  values (alvo, 'lily'), (alvo, 'bamboo')
  on conflict (user_id, item_id) do nothing;

  insert into public.baru_settings (user_id, evening_notif, missed_notif, usage_access, default_duration_min)
  values (alvo, true, true, false, 25)
  on conflict (user_id) do update set
    evening_notif = excluded.evening_notif, missed_notif = excluded.missed_notif,
    usage_access = excluded.usage_access,
    default_duration_min = excluded.default_duration_min, updated_at = now();

  insert into public.baru_screen_time (user_id, usage_min, goal_min, avg_min)
  values (alvo, 96, 150, 240)
  on conflict (user_id) do update set
    usage_min = excluded.usage_min, goal_min = excluded.goal_min,
    avg_min = excluded.avg_min, updated_at = now();

  insert into public.baru_streaks (user_id, streak, today_index, freezes_left, days_away)
  values (alvo, 3, extract(isodow from current_date)::int - 1, 1, 0)
  on conflict (user_id) do update set
    streak = excluded.streak, today_index = excluded.today_index,
    freezes_left = excluded.freezes_left, days_away = excluded.days_away,
    updated_at = now();

  -- Semana com os dias anteriores presentes e hoje marcado.
  insert into public.baru_week_calendar (user_id, day_index, kind)
  select
    alvo,
    gs.idx,
    case
      when gs.idx < extract(isodow from current_date)::int - 1 then 'present'
      when gs.idx = extract(isodow from current_date)::int - 1 then 'today'
      else 'empty'
    end
  from generate_series(0, 6) as gs(idx)
  on conflict (user_id, day_index) do update set kind = excluded.kind;

  insert into public.baru_daily_progress (user_id, completed_sessions, abandoned_today)
  values (alvo, 1, false)
  on conflict (user_id) do update set
    completed_sessions = excluded.completed_sessions,
    abandoned_today = excluded.abandoned_today, updated_at = now();

  insert into public.baru_daily_quests (user_id, quest_date, quest_key, completed, completed_at)
  values (alvo, current_date, 'focus_session', true, now()),
         (alvo, current_date, 'under_goal', false, null)
  on conflict (user_id, quest_date, quest_key) do update set
    completed = excluded.completed, completed_at = excluded.completed_at;

  insert into public.baru_subscriptions (user_id, trial_active, pay_plan, trial_started_at)
  values (alvo, true, 'annual', now())
  on conflict (user_id) do update set
    trial_active = excluded.trial_active, pay_plan = excluded.pay_plan,
    trial_started_at = excluded.trial_started_at, updated_at = now();

  insert into public.baru_sessions (id, user_id, started_at, duration_min, completed, aborted, reward)
  values (
    md5(alvo::text || 'seed-1')::uuid,
    alvo, now() - interval '3 hours', 25, true, false, 10
  )
  on conflict (id) do nothing;

  raise notice 'baru seed: pronto';
end $$;

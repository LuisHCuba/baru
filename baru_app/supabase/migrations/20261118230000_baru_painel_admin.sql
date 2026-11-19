-- Painel admin do Baru (meubaru.com/admin): cortesia, teste estendido,
-- usuários um a um, pedidos do Asaas, atividade e auditoria.
--
-- A base de métricas (baru_admins, baru_e_admin, views baru_admin_*,
-- baru_admin_resumo/retencao/promove/rebaixa) veio da migration baru_admin de
-- 2026-08-29. Aqui entra o que faltava para operar conta por conta.
--
-- Cortesia e teste estendido ficam em tabelas próprias, fora de
-- baru_assinaturas: aquela tabela é do Asaas (só as Edge Functions escrevem),
-- e misturar status manual lá faria o webhook e o checkout tropeçarem.
-- Toda função confere baru_e_admin() por dentro e deixa rastro em baru_admin_log.

-- ---------------------------------------------------------------- tabelas

create table if not exists public.baru_cortesias (
  user_id uuid primary key references auth.users (id) on delete cascade,
  ate date,
  nota text,
  definido_por uuid references auth.users (id) on delete set null,
  definido_em timestamptz not null default now()
);
alter table public.baru_cortesias enable row level security;
revoke all on table public.baru_cortesias from anon, authenticated;
comment on table public.baru_cortesias is
  'Acesso liberado sem cobrança. ate nulo = vitalícia. Sem policy: só o painel admin (funções SECURITY DEFINER) escreve e lê.';

create table if not exists public.baru_testes_estendidos (
  user_id uuid primary key references auth.users (id) on delete cascade,
  ate timestamptz not null,
  definido_por uuid references auth.users (id) on delete set null,
  definido_em timestamptz not null default now()
);
alter table public.baru_testes_estendidos enable row level security;
revoke all on table public.baru_testes_estendidos from anon, authenticated;
comment on table public.baru_testes_estendidos is
  'Fim de teste dado no painel admin. Vale o maior entre este e os 7 dias normais.';

create table if not exists public.baru_admin_log (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users (id) on delete set null,
  acao text not null,
  alvo_id uuid,
  detalhe jsonb,
  em timestamptz not null default now()
);
create index if not exists baru_admin_log_em_idx on public.baru_admin_log (em desc);
alter table public.baru_admin_log enable row level security;
revoke all on table public.baru_admin_log from anon, authenticated;
comment on table public.baru_admin_log is 'Auditoria do painel admin: quem fez o quê com qual conta.';

-- ---------------------------------------------------------------- acesso

-- Regra de acesso de qualquer conta. Interna: baru_meu_acesso e o painel usam.
create or replace function public.baru_acesso_de(p_uid uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  ligada timestamptz;
  criado timestamptz;
  estendido timestamptz;
  teste_ate timestamptz;
  a public.baru_assinaturas%rowtype;
  c public.baru_cortesias%rowtype;
  hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  pago boolean;
  cortesia boolean;
begin
  select ligada_em into ligada from public.baru_cobranca where id = 1;
  select created_at into criado from auth.users where id = p_uid;
  select * into a from public.baru_assinaturas where user_id = p_uid;
  select * into c from public.baru_cortesias where user_id = p_uid;
  select t.ate into estendido from public.baru_testes_estendidos t where t.user_id = p_uid;
  pago := a.pago_ate is not null and a.pago_ate >= hoje;
  cortesia := c.user_id is not null and (c.ate is null or c.ate >= hoje);
  if ligada is not null then
    teste_ate := greatest(greatest(criado, ligada) + interval '7 days', estendido);
  end if;
  return jsonb_build_object(
    'liberado', ligada is null or now() < teste_ate or pago or cortesia,
    -- Com cortesia não há prazo de teste para contar: o app mostraria "teste".
    'testeAte', case when cortesia then null else teste_ate end,
    'pagoAte', a.pago_ate,
    'status', case when cortesia and not pago then 'cortesia' else a.status end,
    'plano', a.plano,
    'cortesia', cortesia,
    'cortesiaAte', c.ate
  );
end;
$$;
revoke all on function public.baru_acesso_de(uuid) from public, anon, authenticated;

create or replace function public.baru_meu_acesso()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'sem sessão' using errcode = '28000';
  end if;
  return public.baru_acesso_de(uid);
end;
$$;
revoke all on function public.baru_meu_acesso() from public, anon;
grant execute on function public.baru_meu_acesso() to authenticated;

-- ---------------------------------------------------------------- leitura

create or replace function public.baru_admin_usuarios()
returns table (
  id uuid, email text, provedor text, criado_em timestamptz, ultimo_login timestamptz,
  ultimo_dia_ativo date, idioma text, especie text, bicho text, xp integer,
  sessoes_concluidas integer, sequencia integer, folhas integer, em_toca boolean,
  admin boolean, acesso jsonb, assinatura_status text, valor_centavos integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  return query
  select u.id, u.email::text, coalesce(u.raw_app_meta_data ->> 'provider', 'email'),
         u.created_at, u.last_sign_in_at,
         (select max(d.dia) from public.baru_admin_dias_ativos d where d.user_id = u.id),
         p.lang, pet.species, pet.pet_name, pr.xp, pr.sessoes_concluidas, st.streak, w.leaves,
         exists (select 1 from public.baru_toca_membros m where m.user_id = u.id and m.saiu_em is null),
         exists (select 1 from public.baru_admins ad where ad.user_id = u.id),
         public.baru_acesso_de(u.id), a.status, a.valor_centavos
    from auth.users u
    left join public.baru_profiles p on p.user_id = u.id
    left join public.baru_pets pet on pet.user_id = u.id
    left join public.baru_progression pr on pr.user_id = u.id
    left join public.baru_streaks st on st.user_id = u.id
    left join public.baru_wallets w on w.user_id = u.id
    left join public.baru_assinaturas a on a.user_id = u.id
   order by u.created_at desc;
end;
$$;
revoke all on function public.baru_admin_usuarios() from public, anon;
grant execute on function public.baru_admin_usuarios() to authenticated;

create or replace function public.baru_admin_usuario(p_uid uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v jsonb;
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'id', u.id, 'email', u.email,
    'provedor', coalesce(u.raw_app_meta_data ->> 'provider', 'email'),
    'criado_em', u.created_at, 'ultimo_login', u.last_sign_in_at,
    'email_confirmado', u.email_confirmed_at is not null,
    'admin', exists (select 1 from public.baru_admins ad where ad.user_id = u.id),
    'acesso', public.baru_acesso_de(u.id),
    'perfil', (select jsonb_build_object('idioma', p.lang, 'tela', p.screen, 'onboarding', p.onb,
        'ultima_abertura', p.last_open_date, 'faixa_idade', p.declaracao_de_idade ->> 'faixa',
        'regiao', p.declaracao_de_idade ->> 'regiao')
      from public.baru_profiles p where p.user_id = u.id),
    'bicho', (select jsonb_build_object('especie', b.species, 'nome', b.pet_name, 'sexo', b.sexo, 'pelagem', b.coat)
      from public.baru_pets b where b.user_id = u.id),
    'progresso', (select jsonb_build_object('xp', pr.xp, 'afeto', pr.afeto, 'humor', pr.humor,
        'sessoes_concluidas', pr.sessoes_concluidas, 'melhor_sequencia', pr.melhor_sequencia,
        'adotado_em', pr.adotado_em, 'dias_bons_seguidos', pr.dias_bons_seguidos)
      from public.baru_progression pr where pr.user_id = u.id),
    'sequencia', (select jsonb_build_object('dias', s.streak, 'congelamentos', s.freezes_left, 'dias_fora', s.days_away)
      from public.baru_streaks s where s.user_id = u.id),
    'folhas', (select w.leaves from public.baru_wallets w where w.user_id = u.id),
    'tempo_de_tela', (select jsonb_build_object('uso_min', t.usage_min, 'meta_min', t.goal_min, 'media_min', t.avg_min, 'em', t.updated_at)
      from public.baru_screen_time t where t.user_id = u.id),
    'ajustes', (select jsonb_build_object('lembrete_noite', s.evening_notif, 'hora', s.evening_hour,
        'minuto', s.evening_minute, 'duracao_padrao', s.default_duration_min, 'som', s.som, 'acesso_uso', s.usage_access)
      from public.baru_settings s where s.user_id = u.id),
    'sessoes_30d', coalesce((select jsonb_agg(jsonb_build_object('dia', x.dia, 'sessoes', x.n, 'concluidas', x.c, 'minutos', x.m) order by x.dia)
      from (select se.started_at::date dia, count(*) n, count(*) filter (where se.completed) c,
                   coalesce(sum(se.duration_min) filter (where se.completed), 0) m
              from public.baru_sessions se
             where se.user_id = u.id and se.started_at > now() - interval '30 days'
             group by 1) x), '[]'::jsonb),
    'sessoes_total', (select jsonb_build_object('total', count(*), 'concluidas', count(*) filter (where se.completed),
        'abandonadas', count(*) filter (where se.aborted), 'minutos', coalesce(sum(se.duration_min) filter (where se.completed), 0),
        'ultima', max(se.started_at))
      from public.baru_sessions se where se.user_id = u.id),
    'tocas', coalesce((select jsonb_agg(jsonb_build_object('nome', t.nome, 'entrou_em', m.entrou_em, 'saiu_em', m.saiu_em,
        'arquivada', t.arquivada_em is not null,
        'membros', (select count(*) from public.baru_toca_membros x where x.toca_id = t.id and x.saiu_em is null)) order by m.entrou_em desc)
      from public.baru_toca_membros m join public.baru_tocas t on t.id = m.toca_id where m.user_id = u.id), '[]'::jsonb),
    'assinatura', (select to_jsonb(a) - 'asaas_cliente_id' from public.baru_assinaturas a where a.user_id = u.id),
    'eventos_asaas', coalesce((select jsonb_agg(jsonb_build_object('quando', e.recebido_em, 'tipo', e.tipo,
        'valor', e.payload -> 'payment' ->> 'value', 'status', e.payload -> 'payment' ->> 'status',
        'forma', e.payload -> 'payment' ->> 'billingType') order by e.recebido_em desc)
      from public.baru_asaas_eventos e join public.baru_assinaturas a
        on a.asaas_assinatura_id = coalesce(e.payload -> 'payment' ->> 'subscription', e.payload -> 'subscription' ->> 'id')
     where a.user_id = u.id), '[]'::jsonb),
    'cortesia', (select jsonb_build_object('ate', c.ate, 'nota', c.nota, 'em', c.definido_em,
        'por', (select x.email from auth.users x where x.id = c.definido_por))
      from public.baru_cortesias c where c.user_id = u.id),
    'teste_estendido', (select jsonb_build_object('ate', t.ate, 'em', t.definido_em)
      from public.baru_testes_estendidos t where t.user_id = u.id),
    'historico_admin', coalesce((select jsonb_agg(jsonb_build_object('em', l.em, 'acao', l.acao, 'detalhe', l.detalhe,
        'por', (select x.email from auth.users x where x.id = l.admin_id)) order by l.em desc)
      from public.baru_admin_log l where l.alvo_id = u.id), '[]'::jsonb)
  ) into v
  from auth.users u
  where u.id = p_uid;
  return v;
end;
$$;
revoke all on function public.baru_admin_usuario(uuid) from public, anon;
grant execute on function public.baru_admin_usuario(uuid) to authenticated;

-- Assinaturas do Asaas (linha a linha) e os últimos eventos do webhook.
create or replace function public.baru_admin_pedidos()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'cobranca_ligada_em', (select ligada_em from public.baru_cobranca where id = 1),
    'assinaturas', coalesce((select jsonb_agg(jsonb_build_object('user_id', a.user_id, 'email', u.email,
        'plano', a.plano, 'status', a.status, 'valor_centavos', a.valor_centavos, 'forma', a.forma_pagamento,
        'pago_ate', a.pago_ate, 'criado_em', a.criado_em, 'cancelada_em', a.cancelada_em) order by a.criado_em desc)
      from public.baru_assinaturas a left join auth.users u on u.id = a.user_id), '[]'::jsonb),
    'cortesias', coalesce((select jsonb_agg(jsonb_build_object('user_id', c.user_id, 'email', u.email,
        'ate', c.ate, 'nota', c.nota, 'em', c.definido_em) order by c.definido_em desc)
      from public.baru_cortesias c left join auth.users u on u.id = c.user_id), '[]'::jsonb),
    'eventos', coalesce((select jsonb_agg(x order by x.quando desc) from (
        select e.recebido_em quando, e.tipo, u.email, a.plano,
               e.payload -> 'payment' ->> 'value' valor, e.payload -> 'payment' ->> 'billingType' forma,
               e.payload -> 'payment' ->> 'status' status, e.payload -> 'payment' ->> 'dueDate' vencimento,
               e.processado_em is not null processado
          from public.baru_asaas_eventos e
          left join public.baru_assinaturas a
            on a.asaas_assinatura_id = coalesce(e.payload -> 'payment' ->> 'subscription', e.payload -> 'subscription' ->> 'id')
          left join auth.users u on u.id = a.user_id
         order by e.recebido_em desc limit 200) x), '[]'::jsonb)
  );
end;
$$;
revoke all on function public.baru_admin_pedidos() from public, anon;
grant execute on function public.baru_admin_pedidos() to authenticated;

-- Linha do tempo: cadastros, assinaturas, eventos do Asaas, Tocas e ações do painel.
create or replace function public.baru_admin_atividade(p_limite integer default 100)
returns table (quando timestamptz, tipo text, user_id uuid, email text, detalhe text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  return query
  select * from (
    select u.created_at, 'cadastro'::text, u.id, u.email::text,
           coalesce(u.raw_app_meta_data ->> 'provider', 'email')
      from auth.users u
    union all
    select a.criado_em, 'assinatura'::text, a.user_id, u.email::text, a.plano || ' · ' || a.status
      from public.baru_assinaturas a left join auth.users u on u.id = a.user_id
    union all
    select e.recebido_em, 'asaas'::text, a.user_id, u.email::text, e.tipo
      from public.baru_asaas_eventos e
      left join public.baru_assinaturas a
        on a.asaas_assinatura_id = coalesce(e.payload -> 'payment' ->> 'subscription', e.payload -> 'subscription' ->> 'id')
      left join auth.users u on u.id = a.user_id
    union all
    select m.entrou_em, 'toca'::text, m.user_id, u.email::text, 'entrou em ' || t.nome
      from public.baru_toca_membros m join public.baru_tocas t on t.id = m.toca_id
      left join auth.users u on u.id = m.user_id
    union all
    select l.em, 'admin'::text, l.alvo_id, u.email::text, l.acao
      from public.baru_admin_log l left join auth.users u on u.id = l.alvo_id
  ) x
  order by 1 desc
  limit greatest(1, least(coalesce(p_limite, 100), 500));
end;
$$;
revoke all on function public.baru_admin_atividade(integer) from public, anon;
grant execute on function public.baru_admin_atividade(integer) to authenticated;

create or replace function public.baru_admin_auditoria(p_limite integer default 200)
returns table (em timestamptz, admin text, acao text, alvo text, detalhe jsonb)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  return query
  select l.em, ad.email::text, l.acao, al.email::text, l.detalhe
    from public.baru_admin_log l
    left join auth.users ad on ad.id = l.admin_id
    left join auth.users al on al.id = l.alvo_id
   order by l.em desc
   limit greatest(1, least(coalesce(p_limite, 200), 1000));
end;
$$;
revoke all on function public.baru_admin_auditoria(integer) from public, anon;
grant execute on function public.baru_admin_auditoria(integer) to authenticated;

create or replace function public.baru_admin_lista_admins()
returns table (user_id uuid, email text, nota text, criado_em timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  return query
  select a.user_id, u.email::text, a.nota, a.criado_em
    from public.baru_admins a left join auth.users u on u.id = a.user_id
   order by a.criado_em;
end;
$$;
revoke all on function public.baru_admin_lista_admins() from public, anon;
grant execute on function public.baru_admin_lista_admins() to authenticated;

-- ---------------------------------------------------------------- ações

create or replace function public.baru_admin_definir_cortesia(p_uid uuid, p_ate date default null, p_nota text default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  antes public.baru_cortesias%rowtype;
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  if not exists (select 1 from auth.users where id = p_uid) then
    raise exception 'Conta não encontrada.' using errcode = 'P0002';
  end if;
  if p_ate is not null and p_ate < (now() at time zone 'America/Sao_Paulo')::date then
    raise exception 'A data da cortesia já passou.';
  end if;
  select * into antes from public.baru_cortesias where user_id = p_uid;
  insert into public.baru_cortesias (user_id, ate, nota, definido_por)
  values (p_uid, p_ate, nullif(trim(p_nota), ''), auth.uid())
  on conflict (user_id) do update
     set ate = excluded.ate, nota = excluded.nota, definido_por = excluded.definido_por, definido_em = now();
  insert into public.baru_admin_log (admin_id, acao, alvo_id, detalhe)
  values (auth.uid(), 'cortesia_definida', p_uid, jsonb_build_object(
    'ate', p_ate, 'nota', nullif(trim(p_nota), ''),
    'antes', case when antes.user_id is null then null else jsonb_build_object('ate', antes.ate, 'nota', antes.nota) end));
  return public.baru_acesso_de(p_uid);
end;
$$;
revoke all on function public.baru_admin_definir_cortesia(uuid, date, text) from public, anon;
grant execute on function public.baru_admin_definir_cortesia(uuid, date, text) to authenticated;

create or replace function public.baru_admin_remover_cortesia(p_uid uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  antes public.baru_cortesias%rowtype;
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  delete from public.baru_cortesias where user_id = p_uid returning * into antes;
  if antes.user_id is null then
    raise exception 'Esta conta não tem cortesia.';
  end if;
  insert into public.baru_admin_log (admin_id, acao, alvo_id, detalhe)
  values (auth.uid(), 'cortesia_removida', p_uid, jsonb_build_object('ate', antes.ate, 'nota', antes.nota));
  return public.baru_acesso_de(p_uid);
end;
$$;
revoke all on function public.baru_admin_remover_cortesia(uuid) from public, anon;
grant execute on function public.baru_admin_remover_cortesia(uuid) to authenticated;

create or replace function public.baru_admin_estender_teste(p_uid uuid, p_dias integer)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  atual timestamptz;
  novo timestamptz;
begin
  if not public.baru_e_admin() then
    raise exception 'apenas admin' using errcode = '42501';
  end if;
  if p_dias is null or p_dias < 1 or p_dias > 90 then
    raise exception 'Entre 1 e 90 dias.';
  end if;
  if not exists (select 1 from auth.users where id = p_uid) then
    raise exception 'Conta não encontrada.' using errcode = 'P0002';
  end if;
  atual := (public.baru_acesso_de(p_uid) ->> 'testeAte')::timestamptz;
  novo := greatest(now(), coalesce(atual, now())) + make_interval(days => p_dias);
  insert into public.baru_testes_estendidos (user_id, ate, definido_por)
  values (p_uid, novo, auth.uid())
  on conflict (user_id) do update set ate = excluded.ate, definido_por = excluded.definido_por, definido_em = now();
  insert into public.baru_admin_log (admin_id, acao, alvo_id, detalhe)
  values (auth.uid(), 'teste_estendido', p_uid, jsonb_build_object('dias', p_dias, 'antes', atual, 'ate', novo));
  return public.baru_acesso_de(p_uid);
end;
$$;
revoke all on function public.baru_admin_estender_teste(uuid, integer) from public, anon;
grant execute on function public.baru_admin_estender_teste(uuid, integer) to authenticated;

-- promove/rebaixa passam a deixar rastro.
create or replace function public.baru_admin_promove(p_email text, p_nota text default null)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if not public.baru_e_admin() then
    raise exception 'baru_admin_promove: apenas admin' using errcode = '42501';
  end if;
  select u.id into v_id from auth.users u where lower(u.email) = lower(trim(p_email)) limit 1;
  if v_id is null then
    raise exception 'Conta não encontrada.' using errcode = 'P0002';
  end if;
  insert into public.baru_admins (user_id, nota) values (v_id, p_nota)
  on conflict (user_id) do update set nota = coalesce(excluded.nota, baru_admins.nota);
  insert into public.baru_admin_log (admin_id, acao, alvo_id, detalhe)
  values (auth.uid(), 'admin_promovido', v_id, jsonb_build_object('nota', p_nota));
  return v_id;
end;
$$;

create or replace function public.baru_admin_rebaixa(p_email text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if not public.baru_e_admin() then
    raise exception 'baru_admin_rebaixa: apenas admin' using errcode = '42501';
  end if;
  if (select count(*) from public.baru_admins) <= 1 then
    raise exception 'Não dá para remover o último admin.' using errcode = '23514';
  end if;
  select u.id into v_id from auth.users u where lower(u.email) = lower(trim(p_email)) limit 1;
  if v_id is null then
    return false;
  end if;
  delete from public.baru_admins a where a.user_id = v_id;
  insert into public.baru_admin_log (admin_id, acao, alvo_id, detalhe)
  values (auth.uid(), 'admin_rebaixado', v_id, null);
  return true;
end;
$$;
revoke all on function public.baru_admin_promove(text, text) from public, anon;
revoke all on function public.baru_admin_rebaixa(text) from public, anon;
grant execute on function public.baru_admin_promove(text, text) to authenticated;
grant execute on function public.baru_admin_rebaixa(text) to authenticated;

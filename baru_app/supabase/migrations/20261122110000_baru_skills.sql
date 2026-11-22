-- Skills do pet: Saudável (meta de tela), Inteligente (leitura e estudo) e
-- Forte (exercício). XP e nível calculados só no servidor.
--   Inteligente: 1 XP por página ou 2 XP a cada 5 min de estudo.
--   Forte: 2 XP a cada 5 min de exercício.
--   Saudável: 20 XP por dia dentro da meta de tela.
--   Teto: 200 XP por dia em cada skill. Nível n exige 100 × n XP para subir.
--   Registro manual editável (ou apagável) por 24 horas.

create table if not exists public.baru_habitos (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  skill text not null check (skill in ('saudavel', 'inteligente', 'forte')),
  atividade text not null check (atividade in ('leitura', 'estudo', 'corrida', 'luta', 'academia', 'outro', 'meta')),
  quantidade numeric not null check (quantidade > 0 and quantidade <= 1440),
  unidade text not null check (unidade in ('paginas', 'minutos', 'dia')),
  distancia_km numeric check (distancia_km is null or (distancia_km > 0 and distancia_km <= 500)),
  dia date not null,
  xp integer not null check (xp >= 0),
  criado_em timestamptz not null default now(),
  apagado_em timestamptz
);
create index if not exists baru_habitos_user_dia on public.baru_habitos (user_id, dia) where apagado_em is null;
create unique index if not exists baru_habitos_saudavel_unico on public.baru_habitos (user_id, dia)
  where skill = 'saudavel' and apagado_em is null;
alter table public.baru_habitos enable row level security;
drop policy if exists "baru habitos: ler os meus" on public.baru_habitos;
create policy "baru habitos: ler os meus" on public.baru_habitos for select to authenticated using (user_id = auth.uid());
-- Sem insert/update/delete pelo cliente: só pelas funções.

create or replace function public.baru_hoje_sp() returns date
language sql stable set search_path = pg_catalog, pg_temp as $$
  select (now() at time zone 'America/Sao_Paulo')::date;
$$;

-- XP bruto de um registro, antes do teto diário.
create or replace function public.baru_xp_bruto(p_skill text, p_unidade text, p_quantidade numeric)
returns integer language sql immutable set search_path = pg_catalog, pg_temp as $$
  select case
    when p_skill = 'inteligente' and p_unidade = 'paginas' then floor(p_quantidade)::int
    when p_skill in ('inteligente', 'forte') and p_unidade = 'minutos' then (floor(p_quantidade / 5) * 2)::int
    when p_skill = 'saudavel' then 20
    else 0 end;
$$;

-- Nível a partir do XP total: chegar ao nível L custa 50 × L × (L − 1).
create or replace function public.baru_nivel(p_xp integer) returns integer
language sql immutable set search_path = pg_catalog, pg_temp as $$
  select greatest(1, floor((1 + sqrt(1 + 0.08 * greatest(p_xp, 0))) / 2)::int);
$$;

create or replace function public.baru_minhas_skills() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid(); hoje date := public.baru_hoje_sp();
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  return jsonb_build_object(
    'skills', (select jsonb_agg(jsonb_build_object(
        'skill', s.skill, 'xp', s.xp, 'nivel', public.baru_nivel(s.xp),
        'xpDoNivel', 50 * public.baru_nivel(s.xp) * (public.baru_nivel(s.xp) - 1),
        'xpProximo', 50 * (public.baru_nivel(s.xp) + 1) * public.baru_nivel(s.xp),
        'hoje', s.hoje) order by s.ordem)
      from (select k.skill, k.ordem,
                   coalesce((select sum(h.xp) from public.baru_habitos h where h.user_id = uid and h.skill = k.skill and h.apagado_em is null), 0)::int as xp,
                   coalesce((select sum(h.xp) from public.baru_habitos h where h.user_id = uid and h.skill = k.skill and h.apagado_em is null and h.dia = hoje), 0)::int as hoje
              from (values ('saudavel', 1), ('inteligente', 2), ('forte', 3)) as k(skill, ordem)) s),
    'registros', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', h.id, 'skill', h.skill, 'atividade', h.atividade, 'quantidade', h.quantidade, 'unidade', h.unidade,
        'distanciaKm', h.distancia_km, 'dia', h.dia, 'xp', h.xp, 'criadoEm', h.criado_em,
        'editavel', h.skill <> 'saudavel' and h.criado_em > now() - interval '24 hours') order by h.criado_em desc), '[]'::jsonb)
      from (select * from public.baru_habitos h where h.user_id = uid and h.apagado_em is null order by h.criado_em desc limit 60) h),
    'tetoDiario', 200
  );
end;
$$;

-- XP que cabe no dia (teto 200 por skill), sem contar o registro p_exceto.
create or replace function public.baru_xp_que_cabe(p_uid uuid, p_skill text, p_dia date, p_bruto integer, p_exceto bigint default null)
returns integer language sql stable security definer set search_path = public, pg_temp as $$
  select greatest(0, least(p_bruto, 200 - coalesce((select sum(xp) from public.baru_habitos
    where user_id = p_uid and skill = p_skill and dia = p_dia and apagado_em is null
      and (p_exceto is null or id <> p_exceto)), 0)::int));
$$;

create or replace function public.baru_registra_habito(
  p_skill text, p_atividade text, p_quantidade numeric, p_unidade text,
  p_distancia_km numeric default null, p_dia date default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid(); v_dia date := coalesce(p_dia, public.baru_hoje_sp());
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if p_skill not in ('inteligente', 'forte') then raise exception 'Skill inválida.'; end if;
  if v_dia < public.baru_hoje_sp() - 1 or v_dia > public.baru_hoje_sp() then
    raise exception 'Dá para registrar hoje ou ontem.';
  end if;
  if (p_skill = 'inteligente' and p_atividade not in ('leitura', 'estudo'))
     or (p_skill = 'forte' and p_atividade not in ('corrida', 'luta', 'academia', 'outro')) then
    raise exception 'Atividade inválida.';
  end if;
  if (p_skill = 'forte' and p_unidade <> 'minutos') or (p_skill = 'inteligente' and p_unidade not in ('paginas', 'minutos')) then
    raise exception 'Unidade inválida.';
  end if;
  insert into public.baru_habitos (user_id, skill, atividade, quantidade, unidade, distancia_km, dia, xp)
  values (uid, p_skill, p_atividade, p_quantidade, p_unidade,
          case when p_skill = 'forte' then p_distancia_km end, v_dia,
          public.baru_xp_que_cabe(uid, p_skill, v_dia, public.baru_xp_bruto(p_skill, p_unidade, p_quantidade)));
  return public.baru_minhas_skills();
end;
$$;

create or replace function public.baru_edita_habito(p_id bigint, p_quantidade numeric, p_distancia_km numeric default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid(); h public.baru_habitos%rowtype;
begin
  select * into h from public.baru_habitos where id = p_id and user_id = uid and apagado_em is null;
  if not found or h.skill = 'saudavel' then raise exception 'Registro não encontrado.'; end if;
  if h.criado_em < now() - interval '24 hours' then raise exception 'Só dá para editar nas primeiras 24 horas.'; end if;
  if p_quantidade is null or p_quantidade <= 0 or p_quantidade > 1440 then raise exception 'Quantidade inválida.'; end if;
  update public.baru_habitos set quantidade = p_quantidade,
    distancia_km = case when h.skill = 'forte' then p_distancia_km end,
    xp = public.baru_xp_que_cabe(uid, h.skill, h.dia, public.baru_xp_bruto(h.skill, h.unidade, p_quantidade), h.id)
  where id = p_id;
  return public.baru_minhas_skills();
end;
$$;

create or replace function public.baru_apaga_habito(p_id bigint)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid(); h public.baru_habitos%rowtype;
begin
  select * into h from public.baru_habitos where id = p_id and user_id = uid and apagado_em is null;
  if not found or h.skill = 'saudavel' then raise exception 'Registro não encontrado.'; end if;
  if h.criado_em < now() - interval '24 hours' then raise exception 'Só dá para apagar nas primeiras 24 horas.'; end if;
  update public.baru_habitos set apagado_em = now() where id = p_id;
  return public.baru_minhas_skills();
end;
$$;

-- Saudável: o app avisa que o dia ficou dentro da meta (hoje ou ontem); 20 XP, uma vez por dia.
create or replace function public.baru_saudavel_do_dia(p_dia date default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid(); v_dia date := coalesce(p_dia, public.baru_hoje_sp());
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if v_dia < public.baru_hoje_sp() - 1 or v_dia > public.baru_hoje_sp() then raise exception 'Dia inválido.'; end if;
  insert into public.baru_habitos (user_id, skill, atividade, quantidade, unidade, dia, xp)
  values (uid, 'saudavel', 'meta', 1, 'dia', v_dia, 20)
  on conflict do nothing;
  return public.baru_minhas_skills();
end;
$$;

revoke all on function public.baru_minhas_skills() from public, anon;
revoke all on function public.baru_registra_habito(text, text, numeric, text, numeric, date) from public, anon;
revoke all on function public.baru_edita_habito(bigint, numeric, numeric) from public, anon;
revoke all on function public.baru_apaga_habito(bigint) from public, anon;
revoke all on function public.baru_saudavel_do_dia(date) from public, anon;
revoke all on function public.baru_xp_que_cabe(uuid, text, date, integer, bigint) from public, anon, authenticated;
grant execute on function public.baru_minhas_skills() to authenticated;
grant execute on function public.baru_registra_habito(text, text, numeric, text, numeric, date) to authenticated;
grant execute on function public.baru_edita_habito(bigint, numeric, numeric) to authenticated;
grant execute on function public.baru_apaga_habito(bigint) to authenticated;
grant execute on function public.baru_saudavel_do_dia(date) to authenticated;

-- Modo família: controles a mais para o responsável (app e meubaru.com/painel).
--
-- - meta diferente no fim de semana (meta_fds_min; nulo = igual aos dias de aula);
-- - horários sem tela livres, com nome (noite, escola, jantar…);
-- - tempo extra só hoje e "pausar agora até";
-- - quais avisos o responsável quer ver sobre cada criança.
--
-- A meta que vale hoje é calculada no banco (baru_familia_meta_hoje), para o
-- app, o site e os eventos de meta concordarem.

alter table public.baru_familia_regras
  add column if not exists meta_fds_min integer check (meta_fds_min is null or meta_fds_min between 0 and 1440),
  add column if not exists extra_min integer not null default 0 check (extra_min between 0 and 480),
  add column if not exists extra_dia date,
  add column if not exists pausa_ate timestamptz,
  add column if not exists avisos jsonb not null default
    '{"meta_75": true, "meta_batida": true, "meta_passou": true, "autorizacao": true, "regras": false}'::jsonb
    check (jsonb_typeof(avisos) = 'object');

alter table public.baru_familia_eventos drop constraint if exists baru_familia_eventos_tipo_check;
alter table public.baru_familia_eventos add constraint baru_familia_eventos_tipo_check check (tipo in (
  'entrou', 'saiu', 'meta_75', 'meta_batida', 'meta_passou', 'regras_mudaram',
  'autorizacao_revogada', 'tempo_extra', 'pausa'));

-- ---------------------------------------------------------------- meta de hoje

create or replace function public.baru_familia_meta_hoje(r public.baru_familia_regras)
returns integer language sql stable set search_path = public, pg_temp as $$
  select (case when extract(isodow from public.baru_familia_hoje()) in (6, 7)
               then coalesce(r.meta_fds_min, r.meta_min) else r.meta_min end)
       + (case when r.extra_dia = public.baru_familia_hoje() then r.extra_min else 0 end);
$$;
revoke all on function public.baru_familia_meta_hoje(public.baru_familia_regras) from public, anon, authenticated;

-- Regras como o app e o site leem: com a meta de hoje e a pausa só se ainda vale.
create or replace function public.baru_familia_regras_json(r public.baru_familia_regras)
returns jsonb language sql stable set search_path = public, pg_temp as $$
  select (to_jsonb(r) - 'familia_id' - 'crianca_id' - 'atualizado_por')
    || jsonb_build_object(
         'meta_hoje', public.baru_familia_meta_hoje(r),
         'extra_hoje', case when r.extra_dia = public.baru_familia_hoje() then r.extra_min else 0 end,
         'pausa_ate', case when r.pausa_ate > now() then r.pausa_ate end);
$$;
revoke all on function public.baru_familia_regras_json(public.baru_familia_regras) from public, anon, authenticated;

-- ---------------------------------------------------------------- salvar regras

-- Tudo de uma vez, por jsonb: só as chaves presentes mudam.
-- {"meta_min":120,"meta_fds_min":180,"horarios_sem_tela":[{"nome":"Noite","dias":[1..7],"inicio":"21:00","fim":"07:00"}],
--  "pausar_ao_estourar":true,"filtro_sites":false,"avisos":{"meta_75":true,...}}
create or replace function public.baru_familia_salvar_regras(p_crianca uuid, p_regras jsonb)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(p_crianca);
  r public.baru_familia_regras%rowtype;
  h jsonb;
begin
  if v_familia is null or public.baru_familia_papel(v_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só o responsável da família muda as regras.' using errcode = '42501';
  end if;
  if jsonb_typeof(p_regras) <> 'object' then raise exception 'Regras inválidas.'; end if;
  if p_regras ? 'horarios_sem_tela' then
    if jsonb_typeof(p_regras->'horarios_sem_tela') <> 'array' or jsonb_array_length(p_regras->'horarios_sem_tela') > 8 then
      raise exception 'No máximo 8 horários sem tela.';
    end if;
    for h in select * from jsonb_array_elements(p_regras->'horarios_sem_tela') loop
      if not (h->>'inicio' ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' and h->>'fim' ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
         or jsonb_typeof(h->'dias') <> 'array' or jsonb_array_length(h->'dias') = 0
         or exists (select 1 from jsonb_array_elements_text(h->'dias') d where d !~ '^[1-7]$') then
        raise exception 'Horário sem tela inválido.';
      end if;
    end loop;
  end if;
  update public.baru_familia_regras set
    meta_min = coalesce((p_regras->>'meta_min')::int, meta_min),
    meta_fds_min = case when p_regras ? 'meta_fds_min' then (p_regras->>'meta_fds_min')::int else meta_fds_min end,
    horarios_sem_tela = coalesce(p_regras->'horarios_sem_tela', horarios_sem_tela),
    pausar_ao_estourar = coalesce((p_regras->>'pausar_ao_estourar')::boolean, pausar_ao_estourar),
    filtro_sites = coalesce((p_regras->>'filtro_sites')::boolean, filtro_sites),
    avisos = case when jsonb_typeof(p_regras->'avisos') = 'object' then avisos || (p_regras->'avisos') else avisos end,
    atualizado_por = uid, atualizado_em = now()
  where crianca_id = p_crianca
  returning * into r;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (v_familia, p_crianca, 'regras_mudaram', jsonb_build_object('meta_min', r.meta_min, 'meta_fds_min', r.meta_fds_min,
          'horarios', jsonb_array_length(r.horarios_sem_tela), 'pausar', r.pausar_ao_estourar, 'filtro_sites', r.filtro_sites));
  return public.baru_familia_regras_json(r);
end;
$$;

-- ---------------------------------------------------------------- ações do dia

-- Soma minutos à meta só hoje. p_min negativo tira (nunca abaixo de zero).
create or replace function public.baru_familia_tempo_extra(p_crianca uuid, p_min integer)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(p_crianca);
  hoje date := public.baru_familia_hoje();
  r public.baru_familia_regras%rowtype;
begin
  if v_familia is null or public.baru_familia_papel(v_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só o responsável dá tempo extra.' using errcode = '42501';
  end if;
  if p_min is null or p_min = 0 or abs(p_min) > 240 then raise exception 'Entre 1 e 240 minutos.'; end if;
  update public.baru_familia_regras set
    extra_min = least(480, greatest(0, (case when extra_dia = hoje then extra_min else 0 end) + p_min)),
    extra_dia = hoje, atualizado_por = uid, atualizado_em = now()
  where crianca_id = p_crianca returning * into r;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (v_familia, p_crianca, 'tempo_extra', jsonb_build_object('min', p_min, 'extra_hoje', r.extra_min, 'por', uid));
  return public.baru_familia_regras_json(r);
end;
$$;

-- Pausa a tela agora até p_ate (nulo = retoma). Máximo de 24 h à frente.
create or replace function public.baru_familia_pausar(p_crianca uuid, p_ate timestamptz)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(p_crianca);
  r public.baru_familia_regras%rowtype;
begin
  if v_familia is null or public.baru_familia_papel(v_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só o responsável pausa a tela.' using errcode = '42501';
  end if;
  if p_ate is not null and (p_ate <= now() or p_ate > now() + interval '24 hours') then
    raise exception 'A pausa vai de agora até no máximo 24 horas.';
  end if;
  update public.baru_familia_regras set pausa_ate = p_ate, atualizado_por = uid, atualizado_em = now()
  where crianca_id = p_crianca returning * into r;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (v_familia, p_crianca, 'pausa', jsonb_build_object('ate', p_ate, 'por', uid));
  return public.baru_familia_regras_json(r);
end;
$$;

-- ---------------------------------------------------------------- o dia usa a meta de hoje

create or replace function public.baru_familia_registrar_dia(
  p_plataforma text, p_minutos integer default null, p_limiar_max_min integer default null,
  p_focos integer default null, p_pausas integer default null, p_dia date default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(uid);
  v_dia date := coalesce(p_dia, public.baru_familia_hoje());
  rg public.baru_familia_regras%rowtype;
  v_meta int;
  antes public.baru_familia_dia%rowtype;
  v_uso_antes int;
  v_uso int;
begin
  if v_familia is null then raise exception 'Este aparelho não está numa família.' using errcode = '42501'; end if;
  if v_dia < public.baru_familia_hoje() - 2 or v_dia > public.baru_familia_hoje() then raise exception 'Dia fora do intervalo.'; end if;
  if p_plataforma not in ('ios', 'android') then raise exception 'Plataforma inválida.'; end if;
  select * into rg from public.baru_familia_regras where crianca_id = uid;
  v_meta := public.baru_familia_meta_hoje(rg);
  select * into antes from public.baru_familia_dia where crianca_id = uid and dia = v_dia;

  insert into public.baru_familia_dia as d (crianca_id, dia, plataforma, minutos, limiar_max_min, meta_min, focos, pausas)
  values (uid, v_dia, p_plataforma, p_minutos, p_limiar_max_min, v_meta, coalesce(p_focos, 0), coalesce(p_pausas, 0))
  on conflict (crianca_id, dia) do update set
    plataforma = excluded.plataforma,
    minutos = greatest(d.minutos, excluded.minutos),
    limiar_max_min = greatest(d.limiar_max_min, excluded.limiar_max_min),
    meta_min = excluded.meta_min,
    focos = greatest(d.focos, excluded.focos),
    pausas = greatest(d.pausas, excluded.pausas),
    atualizado_em = now();

  v_uso_antes := greatest(coalesce(antes.minutos, 0), coalesce(antes.limiar_max_min, 0));
  v_uso := greatest(coalesce(p_minutos, 0), coalesce(p_limiar_max_min, 0), v_uso_antes);
  if v_meta > 0 and v_dia = public.baru_familia_hoje() then
    if v_uso_antes < v_meta * 0.75 and v_uso >= v_meta * 0.75 and v_uso < v_meta then
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe) values (v_familia, uid, 'meta_75', jsonb_build_object('uso', v_uso, 'meta', v_meta));
    end if;
    if v_uso_antes < v_meta and v_uso >= v_meta then
      update public.baru_familia_dia set meta_batida_em = now() where crianca_id = uid and dia = v_dia;
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe) values (v_familia, uid, 'meta_batida', jsonb_build_object('uso', v_uso, 'meta', v_meta));
    end if;
    if v_uso_antes < v_meta * 1.5 and v_uso >= v_meta * 1.5 then
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe) values (v_familia, uid, 'meta_passou', jsonb_build_object('uso', v_uso, 'meta', v_meta));
    end if;
  end if;
  return public.baru_familia_regras_json(rg);
end;
$$;

-- As regras antigas (app já instalado) continuam funcionando e devolvem o formato novo.
create or replace function public.baru_familia_definir_regras(
  p_crianca uuid, p_meta_min integer default null, p_horarios jsonb default null,
  p_pausar boolean default null, p_filtro_sites boolean default null)
returns jsonb language sql volatile security definer set search_path = public, pg_temp as $$
  select public.baru_familia_salvar_regras(p_crianca, jsonb_strip_nulls(jsonb_build_object(
    'meta_min', p_meta_min, 'horarios_sem_tela', p_horarios, 'pausar_ao_estourar', p_pausar, 'filtro_sites', p_filtro_sites)));
$$;

-- ---------------------------------------------------------------- leitura com os campos novos

create or replace function public.baru_familia_minha()
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  hoje date := public.baru_familia_hoje();
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  return jsonb_build_object(
    'souCrianca', public.baru_familia_da_crianca(uid) is not null,
    'minhasRegras', (select public.baru_familia_regras_json(r) - 'avisos' from public.baru_familia_regras r where r.crianca_id = uid),
    'familias', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', f.id, 'nome', f.nome, 'meuPapel', eu.papel,
        'responsaveis', (select coalesce(jsonb_agg(jsonb_build_object('id', m.user_id, 'apelido', m.apelido,
             'email', (select u.email from auth.users u where u.id = m.user_id)) order by m.entrou_em), '[]'::jsonb)
           from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'responsavel' and m.saiu_em is null),
        'criancas', case when eu.papel = 'responsavel' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', m.user_id, 'apelido', m.apelido, 'plataforma', m.plataforma, 'entrouEm', m.entrou_em,
            'bicho', (select jsonb_build_object('especie', p.species, 'nome', p.pet_name) from public.baru_pets p where p.user_id = m.user_id),
            'regras', (select public.baru_familia_regras_json(r) from public.baru_familia_regras r where r.crianca_id = m.user_id),
            'hoje', (select to_jsonb(d) - 'crianca_id' from public.baru_familia_dia d where d.crianca_id = m.user_id and d.dia = hoje),
            'semana', (select coalesce(jsonb_agg(to_jsonb(d) - 'crianca_id' order by d.dia), '[]'::jsonb)
                         from public.baru_familia_dia d where d.crianca_id = m.user_id and d.dia > hoje - 7)
          ) order by m.entrou_em), '[]'::jsonb)
          from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'crianca' and m.saiu_em is null)
          else (select coalesce(jsonb_agg(jsonb_build_object('apelido', m.apelido)), '[]'::jsonb)
                  from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'crianca' and m.saiu_em is null) end,
        'eventos', case when eu.papel = 'responsavel' then (
          select coalesce(jsonb_agg(x order by x.em desc), '[]'::jsonb) from (
            select e.em, e.tipo, e.crianca_id, e.detalhe from public.baru_familia_eventos e
             where e.familia_id = f.id order by e.em desc limit 50) x) end
      ) order by f.criada_em)
      from public.baru_familias f
      join public.baru_familia_membros eu on eu.familia_id = f.id and eu.user_id = uid and eu.saiu_em is null
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.baru_familia_salvar_regras(uuid, jsonb) from public, anon;
revoke all on function public.baru_familia_tempo_extra(uuid, integer) from public, anon;
revoke all on function public.baru_familia_pausar(uuid, timestamptz) from public, anon;
grant execute on function public.baru_familia_salvar_regras(uuid, jsonb) to authenticated;
grant execute on function public.baru_familia_tempo_extra(uuid, integer) to authenticated;
grant execute on function public.baru_familia_pausar(uuid, timestamptz) to authenticated;

-- Localização da família (docs/CONTROLE_PARENTAL.md, "Localização").
--
-- O responsável liga a localização de uma criança (com o consentimento dele
-- registrado; a criança vê um aviso fixo no celular enquanto estiver ligada).
-- O celular da criança manda a posição com a chave do aparelho, sem depender
-- do login: ao abrir o app, de tempos em tempos, quando o responsável pede
-- ("onde está agora?"), ao chegar ou sair de um lugar e no SOS.
--
-- Lugares (casa, escola…) são círculos. Quem decide se a criança chegou ou
-- saiu é o banco, a partir das posições: o app e o site só mostram.
--
-- Guardamos o rastro por 7 dias; depois disso as posições somem. Tirar a
-- criança da família apaga tudo dela na hora.
--
-- Avisos para o responsável: cada celular do responsável pede uma chave
-- própria. No iPhone chega push da Apple; no Android o app confere os avisos
-- novos em segundo plano com essa chave.

-- ---------------------------------------------------------------- regras

alter table public.baru_familia_regras
  add column if not exists localizacao boolean not null default false,
  add column if not exists localizacao_em timestamptz,
  add column if not exists localizacao_por uuid references auth.users (id) on delete set null,
  add column if not exists local_pedido_em timestamptz;

alter table public.baru_familia_eventos drop constraint if exists baru_familia_eventos_tipo_check;
alter table public.baru_familia_eventos add constraint baru_familia_eventos_tipo_check check (tipo in (
  'entrou', 'saiu', 'meta_75', 'meta_batida', 'meta_passou', 'regras_mudaram',
  'autorizacao_revogada', 'tempo_extra', 'pausa',
  'localizacao', 'chegou', 'saiu_de', 'sos'));
alter table public.baru_familia_eventos add column if not exists push_em timestamptz;

-- ---------------------------------------------------------------- tabelas

create table if not exists public.baru_familia_lugares (
  id uuid primary key default gen_random_uuid(),
  familia_id uuid not null references public.baru_familias (id) on delete cascade,
  nome text not null check (length(trim(nome)) between 1 and 40),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  raio_m integer not null default 150 check (raio_m between 50 and 2000),
  criado_por uuid references auth.users (id) on delete set null,
  criado_em timestamptz not null default now()
);
create index if not exists baru_familia_lugares_familia_idx on public.baru_familia_lugares (familia_id);

-- Última posição de cada criança e o lugar onde ela está agora.
create table if not exists public.baru_familia_local_atual (
  crianca_id uuid primary key references auth.users (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  precisao_m integer,
  bateria smallint,
  motivo text not null,
  em timestamptz not null default now(),
  lugar_id uuid references public.baru_familia_lugares (id) on delete set null,
  lugar_desde timestamptz
);

-- Rastro dos últimos 7 dias.
create table if not exists public.baru_familia_posicoes (
  id bigint generated always as identity primary key,
  crianca_id uuid not null references auth.users (id) on delete cascade,
  em timestamptz not null default now(),
  lat double precision not null,
  lng double precision not null,
  precisao_m integer,
  bateria smallint,
  motivo text not null check (motivo in ('abriu', 'periodico', 'pedido', 'lugar', 'sos'))
);
create index if not exists baru_familia_posicoes_crianca_idx on public.baru_familia_posicoes (crianca_id, em desc);
create index if not exists baru_familia_posicoes_em_idx on public.baru_familia_posicoes (em);

-- Celulares dos responsáveis, para os avisos (SOS, chegou, saiu, meta).
create table if not exists public.baru_familia_resp_aparelhos (
  chave_hash text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  plataforma text check (plataforma in ('ios', 'android')),
  idioma text not null default 'pt' check (idioma in ('pt', 'en', 'es', 'zh')),
  push_token text,
  push_ambiente text check (push_ambiente in ('producao', 'sandbox')),
  criado_em timestamptz not null default now(),
  visto_em timestamptz
);
create index if not exists baru_familia_resp_aparelhos_user_idx on public.baru_familia_resp_aparelhos (user_id);

alter table public.baru_familia_lugares enable row level security;
alter table public.baru_familia_local_atual enable row level security;
alter table public.baru_familia_posicoes enable row level security;
alter table public.baru_familia_resp_aparelhos enable row level security;
revoke all on table public.baru_familia_lugares, public.baru_familia_local_atual, public.baru_familia_posicoes,
  public.baru_familia_resp_aparelhos from anon, authenticated;
comment on table public.baru_familia_posicoes is 'Rastro de 7 dias das crianças com localização ligada. Sem policy: só as funções baru_familia_* usam.';

-- ---------------------------------------------------------------- auxiliares

-- Distância em metros (haversine).
create or replace function public.baru_familia_metros(a_lat double precision, a_lng double precision, b_lat double precision, b_lng double precision)
returns double precision language sql immutable set search_path = pg_catalog, pg_temp as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(b_lat - a_lat) / 2), 2)
    + cos(radians(a_lat)) * cos(radians(b_lat)) * power(sin(radians(b_lng - a_lng) / 2), 2)));
$$;

create or replace function public.baru_familia_crianca_da_chave(p_chave text)
returns uuid language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare v uuid;
begin
  if p_chave is null or length(p_chave) <> 64 then return null; end if;
  update public.baru_familia_aparelhos set visto_em = now()
   where chave_hash = encode(digest(p_chave, 'sha256'), 'hex') returning crianca_id into v;
  if v is null or public.baru_familia_da_crianca(v) is null then return null; end if;
  return v;
end;
$$;
revoke all on function public.baru_familia_crianca_da_chave(text) from public, anon, authenticated;

create or replace function public.baru_familia_so_responsavel(p_crianca uuid)
returns uuid language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_familia uuid := public.baru_familia_da_crianca(p_crianca);
begin
  if v_familia is null or public.baru_familia_papel(v_familia, auth.uid()) is distinct from 'responsavel' then
    raise exception 'Só o responsável da família vê e muda a localização.' using errcode = '42501';
  end if;
  return v_familia;
end;
$$;
revoke all on function public.baru_familia_so_responsavel(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------- responsável

-- Liga ou desliga a localização de uma criança. Ligar registra quem consentiu e quando.
create or replace function public.baru_familia_localizacao(p_crianca uuid, p_ligada boolean)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  v_familia uuid := public.baru_familia_so_responsavel(p_crianca);
  r public.baru_familia_regras%rowtype;
begin
  update public.baru_familia_regras set
    localizacao = coalesce(p_ligada, false),
    localizacao_em = now(), localizacao_por = auth.uid(),
    local_pedido_em = case when p_ligada then now() else null end,
    atualizado_por = auth.uid(), atualizado_em = now()
  where crianca_id = p_crianca returning * into r;
  if not coalesce(p_ligada, false) then
    -- Desligou: some a posição atual e o rastro.
    delete from public.baru_familia_local_atual where crianca_id = p_crianca;
    delete from public.baru_familia_posicoes where crianca_id = p_crianca;
  end if;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (v_familia, p_crianca, 'localizacao', jsonb_build_object('ligada', r.localizacao, 'por', auth.uid()));
  return public.baru_familia_regras_json(r);
end;
$$;

-- "Onde está agora?": o celular da criança recebe o pedido (push no iPhone,
-- busca de 1 em 1 minuto no Android) e manda a posição.
create or replace function public.baru_familia_pedir_local(p_crianca uuid)
returns timestamptz language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  r public.baru_familia_regras%rowtype;
begin
  perform public.baru_familia_so_responsavel(p_crianca);
  select * into r from public.baru_familia_regras where crianca_id = p_crianca;
  if not r.localizacao then raise exception 'A localização desta criança está desligada.'; end if;
  if r.local_pedido_em > now() - interval '20 seconds' then return r.local_pedido_em; end if;
  update public.baru_familia_regras set local_pedido_em = now(), atualizado_em = now()
   where crianca_id = p_crianca returning * into r;
  return r.local_pedido_em;
end;
$$;

-- Cria (p_id nulo) ou muda um lugar.
create or replace function public.baru_familia_lugar_salvar(
  p_familia uuid, p_id uuid, p_nome text, p_lat double precision, p_lng double precision, p_raio integer default 150)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare l public.baru_familia_lugares%rowtype;
begin
  if public.baru_familia_papel(p_familia, auth.uid()) is distinct from 'responsavel' then
    raise exception 'Só o responsável cria lugares.' using errcode = '42501';
  end if;
  if p_id is null then
    if (select count(*) from public.baru_familia_lugares where familia_id = p_familia) >= 20 then
      raise exception 'No máximo 20 lugares por família.';
    end if;
    insert into public.baru_familia_lugares (familia_id, nome, lat, lng, raio_m, criado_por)
    values (p_familia, trim(p_nome), p_lat, p_lng, coalesce(p_raio, 150), auth.uid()) returning * into l;
  else
    update public.baru_familia_lugares set nome = trim(p_nome), lat = p_lat, lng = p_lng, raio_m = coalesce(p_raio, raio_m)
     where id = p_id and familia_id = p_familia returning * into l;
    if not found then raise exception 'Lugar não encontrado.'; end if;
  end if;
  return to_jsonb(l) - 'familia_id' - 'criado_por';
end;
$$;

create or replace function public.baru_familia_lugar_apagar(p_id uuid)
returns boolean language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare v_familia uuid;
begin
  select familia_id into v_familia from public.baru_familia_lugares where id = p_id;
  if v_familia is null or public.baru_familia_papel(v_familia, auth.uid()) is distinct from 'responsavel' then
    raise exception 'Só o responsável apaga lugares.' using errcode = '42501';
  end if;
  delete from public.baru_familia_lugares where id = p_id;
  return true;
end;
$$;

-- Mapa da família: lugares e onde cada criança está.
create or replace function public.baru_familia_mapa(p_familia uuid)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if public.baru_familia_papel(p_familia, auth.uid()) is distinct from 'responsavel' then
    raise exception 'Só o responsável vê o mapa.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'lugares', (select coalesce(jsonb_agg(to_jsonb(l) - 'familia_id' - 'criado_por' order by l.criado_em), '[]'::jsonb)
                  from public.baru_familia_lugares l where l.familia_id = p_familia),
    'criancas', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', m.user_id, 'apelido', m.apelido, 'plataforma', m.plataforma,
        'localizacao', coalesce(r.localizacao, false), 'pedidoEm', r.local_pedido_em,
        'atual', (select jsonb_build_object('lat', a.lat, 'lng', a.lng, 'precisao_m', a.precisao_m, 'bateria', a.bateria,
                    'motivo', a.motivo, 'em', a.em, 'lugar', (select l.nome from public.baru_familia_lugares l where l.id = a.lugar_id),
                    'lugar_desde', a.lugar_desde)
                  from public.baru_familia_local_atual a where a.crianca_id = m.user_id)
      ) order by m.entrou_em), '[]'::jsonb)
      from public.baru_familia_membros m
      left join public.baru_familia_regras r on r.crianca_id = m.user_id
      where m.familia_id = p_familia and m.papel = 'crianca' and m.saiu_em is null)
  );
end;
$$;

-- Rastro de uma criança nas últimas p_horas (até 7 dias).
create or replace function public.baru_familia_rastro(p_crianca uuid, p_horas integer default 24)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  perform public.baru_familia_so_responsavel(p_crianca);
  return (select coalesce(jsonb_agg(jsonb_build_object('lat', x.lat, 'lng', x.lng, 'em', x.em, 'motivo', x.motivo, 'precisao_m', x.precisao_m) order by x.em), '[]'::jsonb)
            from (select * from public.baru_familia_posicoes p
                   where p.crianca_id = p_crianca and p.em > now() - make_interval(hours => least(greatest(coalesce(p_horas, 24), 1), 168))
                   order by p.em desc limit 2000) x);
end;
$$;

-- ---------------------------------------------------------------- celular da criança

-- Manda a posição. Fora do SOS, só vale com a localização ligada pelo responsável.
-- Devolve as regras (o app aproveita para saber se ainda deve mandar).
create or replace function public.baru_familia_posicao(
  p_chave text, p_lat double precision, p_lng double precision,
  p_precisao integer default null, p_bateria integer default null, p_motivo text default 'periodico')
returns jsonb language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare
  v_crianca uuid := public.baru_familia_crianca_da_chave(p_chave);
  v_familia uuid;
  r public.baru_familia_regras%rowtype;
  antes public.baru_familia_local_atual%rowtype;
  v_lugar public.baru_familia_lugares%rowtype;
  v_motivo text := case when p_motivo in ('abriu', 'periodico', 'pedido', 'lugar', 'sos') then p_motivo else 'periodico' end;
begin
  if v_crianca is null then return null; end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'Posição inválida.';
  end if;
  v_familia := public.baru_familia_da_crianca(v_crianca);
  select * into r from public.baru_familia_regras where crianca_id = v_crianca;
  if not coalesce(r.localizacao, false) and v_motivo <> 'sos' then
    return public.baru_familia_regras_json(r) - 'avisos';
  end if;

  -- Lugar onde a posição cai (o mais perto, se houver mais de um). Posição
  -- imprecisa (> 200 m) não muda o lugar: evita "saiu" e "chegou" de mentira.
  select * into v_lugar from public.baru_familia_lugares l
   where l.familia_id = v_familia and public.baru_familia_metros(l.lat, l.lng, p_lat, p_lng) <= l.raio_m
   order by public.baru_familia_metros(l.lat, l.lng, p_lat, p_lng) limit 1;
  select * into antes from public.baru_familia_local_atual where crianca_id = v_crianca;

  if coalesce(p_precisao, 0) <= 200 then
    if antes.lugar_id is not null and antes.lugar_id is distinct from v_lugar.id then
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
      select v_familia, v_crianca, 'saiu_de', jsonb_build_object('lugar', l.nome, 'lugar_id', l.id)
        from public.baru_familia_lugares l where l.id = antes.lugar_id;
    end if;
    if v_lugar.id is not null and v_lugar.id is distinct from antes.lugar_id then
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
      values (v_familia, v_crianca, 'chegou', jsonb_build_object('lugar', v_lugar.nome, 'lugar_id', v_lugar.id));
    end if;
  else
    v_lugar.id := antes.lugar_id;
  end if;

  insert into public.baru_familia_local_atual as a (crianca_id, lat, lng, precisao_m, bateria, motivo, em, lugar_id, lugar_desde)
  values (v_crianca, p_lat, p_lng, p_precisao, least(greatest(p_bateria, 0), 100), v_motivo, now(), v_lugar.id,
          case when v_lugar.id is not null then now() end)
  on conflict (crianca_id) do update set
    lat = excluded.lat, lng = excluded.lng, precisao_m = excluded.precisao_m, bateria = excluded.bateria,
    motivo = excluded.motivo, em = excluded.em, lugar_id = excluded.lugar_id,
    lugar_desde = case when a.lugar_id is not distinct from excluded.lugar_id then a.lugar_desde else excluded.lugar_desde end;

  insert into public.baru_familia_posicoes (crianca_id, lat, lng, precisao_m, bateria, motivo)
  values (v_crianca, p_lat, p_lng, p_precisao, least(greatest(p_bateria, 0), 100), v_motivo);
  delete from public.baru_familia_posicoes where em < now() - interval '7 days';

  if v_motivo = 'sos' then
    insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
    values (v_familia, v_crianca, 'sos', jsonb_build_object('lat', p_lat, 'lng', p_lng, 'precisao_m', p_precisao, 'bateria', p_bateria));
  end if;
  return public.baru_familia_regras_json(r) - 'avisos';
end;
$$;

-- ---------------------------------------------------------------- celular do responsável

create or replace function public.baru_familia_chave_do_responsavel(p_chave_antiga text default null, p_idioma text default 'pt')
returns text language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_chave text;
begin
  if not exists (select 1 from public.baru_familia_membros where user_id = uid and papel = 'responsavel' and saiu_em is null) then
    raise exception 'Só o responsável recebe avisos da família.' using errcode = '42501';
  end if;
  if p_chave_antiga is not null then
    delete from public.baru_familia_resp_aparelhos where chave_hash = encode(digest(p_chave_antiga, 'sha256'), 'hex') and user_id = uid;
  end if;
  delete from public.baru_familia_resp_aparelhos where chave_hash in (
    select chave_hash from public.baru_familia_resp_aparelhos where user_id = uid order by criado_em desc offset 4);
  v_chave := encode(gen_random_bytes(32), 'hex');
  insert into public.baru_familia_resp_aparelhos (chave_hash, user_id, idioma)
  values (encode(digest(v_chave, 'sha256'), 'hex'), uid, case when p_idioma in ('pt', 'en', 'es', 'zh') then p_idioma else 'pt' end);
  return v_chave;
end;
$$;

create or replace function public.baru_familia_resp_push_token(p_chave text, p_token text, p_plataforma text, p_ambiente text default 'producao', p_idioma text default null)
returns boolean language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
begin
  if p_chave is null or length(p_chave) <> 64 then return false; end if;
  if p_token is not null and p_token !~ '^[0-9a-fA-F]{32,200}$' then return false; end if;
  update public.baru_familia_resp_aparelhos set
    push_token = p_token,
    plataforma = case when p_plataforma in ('ios', 'android') then p_plataforma end,
    push_ambiente = case when p_ambiente = 'sandbox' then 'sandbox' else 'producao' end,
    idioma = case when p_idioma in ('pt', 'en', 'es', 'zh') then p_idioma else idioma end,
    visto_em = now()
  where chave_hash = encode(digest(p_chave, 'sha256'), 'hex');
  return found;
end;
$$;

-- Avisos novos (id > p_depois) das famílias em que o dono da chave é responsável,
-- respeitando o que ele marcou em "avisos" para cada criança. Usado pelo Android.
create or replace function public.baru_familia_avisos_do_responsavel(p_chave text, p_depois bigint default 0)
returns jsonb language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare v_user uuid;
begin
  if p_chave is null or length(p_chave) <> 64 then return null; end if;
  update public.baru_familia_resp_aparelhos set visto_em = now()
   where chave_hash = encode(digest(p_chave, 'sha256'), 'hex') returning user_id into v_user;
  if v_user is null then return null; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', e.id, 'tipo', e.tipo, 'em', e.em, 'detalhe', e.detalhe,
            'crianca', m.apelido) order by e.id), '[]'::jsonb)
    from public.baru_familia_eventos e
    join public.baru_familia_membros eu on eu.familia_id = e.familia_id and eu.user_id = v_user and eu.papel = 'responsavel' and eu.saiu_em is null
    left join public.baru_familia_membros m on m.familia_id = e.familia_id and m.user_id = e.crianca_id
    left join public.baru_familia_regras r on r.crianca_id = e.crianca_id
    where e.id > coalesce(p_depois, 0) and e.em > now() - interval '1 day'
      and public.baru_familia_aviso_ligado(e.tipo, r.avisos));
end;
$$;

-- Qual chave de "avisos" decide se o tipo de evento vira aviso. SOS sempre avisa.
create or replace function public.baru_familia_aviso_ligado(p_tipo text, p_avisos jsonb)
returns boolean language sql immutable set search_path = pg_catalog, pg_temp as $$
  select case p_tipo
    when 'sos' then true
    when 'chegou' then coalesce((p_avisos->>'lugares')::boolean, true)
    when 'saiu_de' then coalesce((p_avisos->>'lugares')::boolean, true)
    when 'meta_75' then coalesce((p_avisos->>'meta_75')::boolean, true)
    when 'meta_batida' then coalesce((p_avisos->>'meta_batida')::boolean, true)
    when 'meta_passou' then coalesce((p_avisos->>'meta_passou')::boolean, true)
    when 'autorizacao_revogada' then coalesce((p_avisos->>'autorizacao')::boolean, true)
    else false end;
$$;

-- Evento que vira aviso → função de push (só se algum responsável tem iPhone com token).
create or replace function public.baru_familia_avisa_responsavel() returns trigger
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if not public.baru_familia_aviso_ligado(new.tipo, (select r.avisos from public.baru_familia_regras r where r.crianca_id = new.crianca_id)) then
    return new;
  end if;
  if not exists (select 1 from public.baru_familia_resp_aparelhos a
                   join public.baru_familia_membros m on m.user_id = a.user_id and m.familia_id = new.familia_id
                    and m.papel = 'responsavel' and m.saiu_em is null
                  where a.push_token is not null and a.plataforma = 'ios') then
    return new;
  end if;
  perform net.http_post(
    url := 'https://slqpuppkapiewjqvedtj.supabase.co/functions/v1/familia-push',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('evento_id', new.id)
  );
  return new;
end;
$$;
drop trigger if exists baru_familia_avisa_responsavel on public.baru_familia_eventos;
create trigger baru_familia_avisa_responsavel after insert on public.baru_familia_eventos
  for each row execute function public.baru_familia_avisa_responsavel();

-- Criança saiu da família: some a posição e o rastro dela.
create or replace function public.baru_familia_apaga_local() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.papel = 'crianca' and new.saiu_em is not null and old.saiu_em is null then
    delete from public.baru_familia_local_atual where crianca_id = new.user_id;
    delete from public.baru_familia_posicoes where crianca_id = new.user_id;
  end if;
  if new.papel = 'responsavel' and new.saiu_em is not null and old.saiu_em is null
     and not exists (select 1 from public.baru_familia_membros where user_id = new.user_id and papel = 'responsavel' and saiu_em is null) then
    delete from public.baru_familia_resp_aparelhos where user_id = new.user_id;
  end if;
  return new;
end;
$$;
drop trigger if exists baru_familia_apaga_local on public.baru_familia_membros;
create trigger baru_familia_apaga_local after update on public.baru_familia_membros
  for each row execute function public.baru_familia_apaga_local();

-- ---------------------------------------------------------------- permissões

revoke all on function public.baru_familia_metros(double precision, double precision, double precision, double precision) from public, anon, authenticated;
revoke all on function public.baru_familia_aviso_ligado(text, jsonb) from public, anon, authenticated;
revoke all on function public.baru_familia_avisa_responsavel() from public, anon, authenticated;
revoke all on function public.baru_familia_apaga_local() from public, anon, authenticated;

revoke all on function public.baru_familia_localizacao(uuid, boolean) from public, anon;
revoke all on function public.baru_familia_pedir_local(uuid) from public, anon;
revoke all on function public.baru_familia_lugar_salvar(uuid, uuid, text, double precision, double precision, integer) from public, anon;
revoke all on function public.baru_familia_lugar_apagar(uuid) from public, anon;
revoke all on function public.baru_familia_mapa(uuid) from public, anon;
revoke all on function public.baru_familia_rastro(uuid, integer) from public, anon;
revoke all on function public.baru_familia_chave_do_responsavel(text, text) from public, anon;
grant execute on function public.baru_familia_localizacao(uuid, boolean) to authenticated;
grant execute on function public.baru_familia_pedir_local(uuid) to authenticated;
grant execute on function public.baru_familia_lugar_salvar(uuid, uuid, text, double precision, double precision, integer) to authenticated;
grant execute on function public.baru_familia_lugar_apagar(uuid) to authenticated;
grant execute on function public.baru_familia_mapa(uuid) to authenticated;
grant execute on function public.baru_familia_rastro(uuid, integer) to authenticated;
grant execute on function public.baru_familia_chave_do_responsavel(text, text) to authenticated;

-- Com chave de aparelho, sem login.
revoke all on function public.baru_familia_posicao(text, double precision, double precision, integer, integer, text) from public;
revoke all on function public.baru_familia_resp_push_token(text, text, text, text, text) from public;
revoke all on function public.baru_familia_avisos_do_responsavel(text, bigint) from public;
grant execute on function public.baru_familia_posicao(text, double precision, double precision, integer, integer, text) to anon, authenticated;
grant execute on function public.baru_familia_resp_push_token(text, text, text, text, text) to anon, authenticated;
grant execute on function public.baru_familia_avisos_do_responsavel(text, bigint) to anon, authenticated;

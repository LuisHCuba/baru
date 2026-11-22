-- Responsáveis no mapa da família (como no Life360): cada responsável escolhe
-- mostrar a própria localização. Só a posição atual fica guardada (sem
-- histórico), e só quem é responsável na mesma família vê.

create table if not exists public.baru_familia_resp_local (
  user_id uuid primary key references auth.users (id) on delete cascade,
  ligada boolean not null default false,
  consentido_em timestamptz,
  lat double precision,
  lng double precision,
  precisao_m integer,
  bateria integer,
  em timestamptz
);
alter table public.baru_familia_resp_local enable row level security;
-- Sem políticas: só pelas funções abaixo.

-- Distância em metros (haversine), para dizer "em casa" sem PostGIS.
create or replace function public.baru_distancia_m(a_lat double precision, a_lng double precision, b_lat double precision, b_lng double precision)
returns double precision language sql immutable set search_path = pg_catalog, pg_temp as $$
  select 6371000 * 2 * asin(sqrt(
    power(sin(radians(b_lat - a_lat) / 2), 2) +
    cos(radians(a_lat)) * cos(radians(b_lat)) * power(sin(radians(b_lng - a_lng) / 2), 2)));
$$;

-- Liga ou desliga "mostrar minha localização". Desligar apaga a posição.
create or replace function public.baru_familia_meu_local(p_ligada boolean)
returns boolean language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if not exists (select 1 from public.baru_familia_membros where user_id = uid and papel = 'responsavel' and saiu_em is null) then
    raise exception 'Só responsáveis aparecem no mapa.' using errcode = '42501';
  end if;
  insert into public.baru_familia_resp_local (user_id, ligada, consentido_em)
  values (uid, coalesce(p_ligada, false), case when p_ligada then now() end)
  on conflict (user_id) do update set
    ligada = excluded.ligada,
    consentido_em = case when excluded.ligada then now() else null end,
    lat = case when excluded.ligada then baru_familia_resp_local.lat end,
    lng = case when excluded.ligada then baru_familia_resp_local.lng end,
    precisao_m = case when excluded.ligada then baru_familia_resp_local.precisao_m end,
    bateria = case when excluded.ligada then baru_familia_resp_local.bateria end,
    em = case when excluded.ligada then baru_familia_resp_local.em end;
  return coalesce(p_ligada, false);
end;
$$;

-- A posição deste celular de responsável (só vale com "mostrar" ligado).
create or replace function public.baru_familia_minha_posicao(
  p_lat double precision, p_lng double precision, p_precisao integer default null, p_bateria integer default null)
returns boolean language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  if uid is null then return false; end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'Posição inválida.';
  end if;
  update public.baru_familia_resp_local set
    lat = p_lat, lng = p_lng,
    precisao_m = case when p_precisao between 0 and 100000 then p_precisao end,
    bateria = case when p_bateria between 0 and 100 then p_bateria end,
    em = now()
  where user_id = uid and ligada;
  return found;
end;
$$;

revoke all on function public.baru_familia_meu_local(boolean) from public, anon;
revoke all on function public.baru_familia_minha_posicao(double precision, double precision, integer, integer) from public, anon;
grant execute on function public.baru_familia_meu_local(boolean) to authenticated;
grant execute on function public.baru_familia_minha_posicao(double precision, double precision, integer, integer) to authenticated;

-- O mapa passa a trazer os responsáveis.
CREATE OR REPLACE FUNCTION public.baru_familia_mapa(p_familia uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
        'foto', (select ft.atualizada_em from public.baru_fotos ft where ft.user_id = m.user_id),
        'atual', (select jsonb_build_object('lat', a.lat, 'lng', a.lng, 'precisao_m', a.precisao_m, 'bateria', a.bateria,
                    'motivo', a.motivo, 'em', a.em, 'lugar', (select l.nome from public.baru_familia_lugares l where l.id = a.lugar_id),
                    'lugar_desde', a.lugar_desde)
                  from public.baru_familia_local_atual a where a.crianca_id = m.user_id),
        'aparelho', (select jsonb_build_object('plataforma', ap.plataforma, 'visto_em', ap.visto_em,
                    'local_estado', ap.local_estado, 'local_estado_em', ap.local_estado_em, 'versao', ap.versao)
                  from public.baru_familia_aparelhos ap where ap.crianca_id = m.user_id
                  order by ap.visto_em desc nulls last limit 1)
      ) order by m.entrou_em), '[]'::jsonb)
      from public.baru_familia_membros m
      left join public.baru_familia_regras r on r.crianca_id = m.user_id
      where m.familia_id = p_familia and m.papel = 'crianca' and m.saiu_em is null),
    -- Responsáveis: aparecem com posição só se escolheram mostrar.
    'responsaveis', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', m.user_id,
        'apelido', coalesce(m.apelido, split_part((select u.email from auth.users u where u.id = m.user_id), '@', 1)),
        'eu', m.user_id = auth.uid(),
        'ligada', coalesce(rl.ligada, false),
        'foto', (select ft.atualizada_em from public.baru_fotos ft where ft.user_id = m.user_id),
        'atual', case when rl.ligada and rl.lat is not null then jsonb_build_object(
            'lat', rl.lat, 'lng', rl.lng, 'precisao_m', rl.precisao_m, 'bateria', rl.bateria, 'em', rl.em, 'motivo', 'periodico',
            'lugar', (select l.nome from public.baru_familia_lugares l
                       where l.familia_id = p_familia and public.baru_distancia_m(l.lat, l.lng, rl.lat, rl.lng) <= l.raio_m
                       order by public.baru_distancia_m(l.lat, l.lng, rl.lat, rl.lng) limit 1)) end
      ) order by (m.user_id = auth.uid()) desc, m.entrou_em), '[]'::jsonb)
      from public.baru_familia_membros m
      left join public.baru_familia_resp_local rl on rl.user_id = m.user_id
      where m.familia_id = p_familia and m.papel = 'responsavel' and m.saiu_em is null)
  );
end;
$function$;

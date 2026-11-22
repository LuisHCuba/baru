-- Estado do celular da criança, para o responsável saber POR QUE não há posição.
--
-- Antes o painel só dizia "Ainda sem posição". Agora o celular conta, com a
-- chave dele (sem login), a permissão de localização ("sempre", "quando_usa",
-- "negada", "desligada", "nao_pedida") e a versão do app. O mapa da família
-- devolve, para cada criança, o aparelho visto por último.

alter table public.baru_familia_aparelhos
  add column if not exists local_estado text
    check (local_estado in ('sempre', 'quando_usa', 'negada', 'desligada', 'nao_pedida')),
  add column if not exists local_estado_em timestamptz,
  add column if not exists versao text;

create or replace function public.baru_familia_aparelho_estado(p_chave text, p_local text default null, p_versao text default null)
returns boolean language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare v uuid;
begin
  if p_chave is null or length(p_chave) <> 64 then return false; end if;
  update public.baru_familia_aparelhos set
    visto_em = now(),
    local_estado = case when p_local in ('sempre', 'quando_usa', 'negada', 'desligada', 'nao_pedida') then p_local else local_estado end,
    local_estado_em = case when p_local in ('sempre', 'quando_usa', 'negada', 'desligada', 'nao_pedida') then now() else local_estado_em end,
    versao = coalesce(left(p_versao, 40), versao)
   where chave_hash = encode(digest(p_chave, 'sha256'), 'hex')
   returning crianca_id into v;
  return v is not null;
end;
$$;
revoke all on function public.baru_familia_aparelho_estado(text, text, text) from public;
grant execute on function public.baru_familia_aparelho_estado(text, text, text) to anon, authenticated;

-- Mapa da família: igual ao anterior, mais o aparelho visto por último de cada criança.
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
                  from public.baru_familia_local_atual a where a.crianca_id = m.user_id),
        'aparelho', (select jsonb_build_object('plataforma', ap.plataforma, 'visto_em', ap.visto_em,
                    'local_estado', ap.local_estado, 'local_estado_em', ap.local_estado_em, 'versao', ap.versao)
                  from public.baru_familia_aparelhos ap where ap.crianca_id = m.user_id
                  order by ap.visto_em desc nulls last limit 1)
      ) order by m.entrou_em), '[]'::jsonb)
      from public.baru_familia_membros m
      left join public.baru_familia_regras r on r.crianca_id = m.user_id
      where m.familia_id = p_familia and m.papel = 'crianca' and m.saiu_em is null)
  );
end;
$$;

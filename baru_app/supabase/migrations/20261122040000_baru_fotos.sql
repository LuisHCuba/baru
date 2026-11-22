-- Foto de perfil das pessoas da família (aparece nas bolinhas do mapa).
-- Arquivo no Storage, bucket privado "baru-fotos", caminho "<user_id>.jpg".
-- Vê a foto: a própria pessoa e quem está numa família com ela.
-- Troca a foto: a própria pessoa, ou um responsável da família da criança.

create table if not exists public.baru_fotos (
  user_id uuid primary key references auth.users (id) on delete cascade,
  atualizada_em timestamptz not null default now()
);
alter table public.baru_fotos enable row level security;
-- Sem políticas: só pelas funções abaixo.

create or replace function public.baru_pode_ver_foto(p_dono uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select auth.uid() is not null and (
    p_dono = auth.uid() or exists (
      select 1 from public.baru_familia_membros eu
      join public.baru_familia_membros ele on ele.familia_id = eu.familia_id and ele.user_id = p_dono and ele.saiu_em is null
      where eu.user_id = auth.uid() and eu.saiu_em is null));
$$;

create or replace function public.baru_pode_trocar_foto(p_dono uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select auth.uid() is not null and (
    p_dono = auth.uid() or exists (
      select 1 from public.baru_familia_membros eu
      join public.baru_familia_membros ele on ele.familia_id = eu.familia_id and ele.user_id = p_dono
        and ele.papel = 'crianca' and ele.saiu_em is null
      where eu.user_id = auth.uid() and eu.papel = 'responsavel' and eu.saiu_em is null));
$$;

-- Depois de subir (ou apagar) o arquivo: marca a hora, que vira a "versão" da foto.
create or replace function public.baru_foto_marca(p_dono uuid, p_removida boolean default false)
returns timestamptz language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare v timestamptz;
begin
  if not public.baru_pode_trocar_foto(p_dono) then
    raise exception 'Sem permissão para trocar esta foto.' using errcode = '42501';
  end if;
  if p_removida then
    delete from public.baru_fotos where user_id = p_dono;
    return null;
  end if;
  insert into public.baru_fotos (user_id, atualizada_em) values (p_dono, now())
  on conflict (user_id) do update set atualizada_em = excluded.atualizada_em
  returning atualizada_em into v;
  return v;
end;
$$;

create or replace function public.baru_minha_foto()
returns timestamptz language sql stable security definer set search_path = public, pg_temp as $$
  select atualizada_em from public.baru_fotos where user_id = auth.uid();
$$;

revoke all on function public.baru_pode_ver_foto(uuid) from public, anon;
revoke all on function public.baru_pode_trocar_foto(uuid) from public, anon;
revoke all on function public.baru_foto_marca(uuid, boolean) from public, anon;
revoke all on function public.baru_minha_foto() from public, anon;
grant execute on function public.baru_pode_ver_foto(uuid) to authenticated;
grant execute on function public.baru_pode_trocar_foto(uuid) to authenticated;
grant execute on function public.baru_foto_marca(uuid, boolean) to authenticated;
grant execute on function public.baru_minha_foto() to authenticated;

-- Bucket privado: JPEG, PNG ou WebP, até 1 MB (o app manda 512 px).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('baru-fotos', 'baru-fotos', false, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = false, file_size_limit = 1048576, allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "baru fotos: ver" on storage.objects;
drop policy if exists "baru fotos: enviar" on storage.objects;
drop policy if exists "baru fotos: trocar" on storage.objects;
drop policy if exists "baru fotos: apagar" on storage.objects;
create policy "baru fotos: ver" on storage.objects for select to authenticated
  using (bucket_id = 'baru-fotos' and name ~ '^[0-9a-f-]{36}\.jpg$'
         and public.baru_pode_ver_foto(split_part(name, '.', 1)::uuid));
create policy "baru fotos: enviar" on storage.objects for insert to authenticated
  with check (bucket_id = 'baru-fotos' and name ~ '^[0-9a-f-]{36}\.jpg$'
              and public.baru_pode_trocar_foto(split_part(name, '.', 1)::uuid));
create policy "baru fotos: trocar" on storage.objects for update to authenticated
  using (bucket_id = 'baru-fotos' and name ~ '^[0-9a-f-]{36}\.jpg$'
         and public.baru_pode_trocar_foto(split_part(name, '.', 1)::uuid))
  with check (bucket_id = 'baru-fotos' and name ~ '^[0-9a-f-]{36}\.jpg$'
              and public.baru_pode_trocar_foto(split_part(name, '.', 1)::uuid));
create policy "baru fotos: apagar" on storage.objects for delete to authenticated
  using (bucket_id = 'baru-fotos' and name ~ '^[0-9a-f-]{36}\.jpg$'
         and public.baru_pode_trocar_foto(split_part(name, '.', 1)::uuid));

-- O mapa e "minha família" passam a dizer a versão da foto de cada pessoa.
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
      where m.familia_id = p_familia and m.papel = 'crianca' and m.saiu_em is null)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.baru_familia_minha()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
             'email', (select u.email from auth.users u where u.id = m.user_id),
             'foto', (select ft.atualizada_em from public.baru_fotos ft where ft.user_id = m.user_id)) order by m.entrou_em), '[]'::jsonb)
           from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'responsavel' and m.saiu_em is null),
        'criancas', case when eu.papel = 'responsavel' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', m.user_id, 'apelido', m.apelido, 'plataforma', m.plataforma, 'entrouEm', m.entrou_em,
            'foto', (select ft.atualizada_em from public.baru_fotos ft where ft.user_id = m.user_id),
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
$function$;

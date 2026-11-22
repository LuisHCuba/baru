-- Laço com regra única: três níveis.
--   administrador: gerencia o laço (adiciona, tira, sobe e desce nível) e cuida
--                  dos dependentes (tempo de tela, regras, pausa, histórico).
--   membro:        adulto lado a lado; vê o mapa e recebe o SOS.
--   dependente:    abaixo dos administradores (papel 'crianca' no banco).
-- O tipo de laço (família, amigos, confiança) deixa de importar.
--
-- Por dentro: adulto = papel 'responsavel'; "admin" diz se é administrador.
-- baru_familia_papel devolve 'membro' para o adulto que não é administrador,
-- então toda trava "só o responsável" vira "só o administrador" sozinha.

alter table public.baru_familia_membros add column if not exists admin boolean not null default false;
-- Quem já era responsável tinha todos os poderes: vira administrador.
update public.baru_familia_membros set admin = true where papel = 'responsavel' and not admin;

create or replace function public.baru_familia_papel(p_familia uuid, p_uid uuid)
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select case when m.papel = 'responsavel' and not m.admin then 'membro' else m.papel end
    from public.baru_familia_membros m
   where m.familia_id = p_familia and m.user_id = p_uid and m.saiu_em is null;
$$;

-- Quem cria o laço é o primeiro administrador.
create or replace function public.baru_familia_criar(p_nome text, p_tipo text default 'familia')
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_id uuid;
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if public.baru_familia_da_crianca(uid) is not null then
    raise exception 'Esta conta é dependente num laço. Saia dele antes de criar um laço.';
  end if;
  if (select count(*) from public.baru_familia_membros where user_id = uid and papel = 'responsavel' and saiu_em is null) >= 10 then
    raise exception 'Limite de 10 laços por pessoa.';
  end if;
  insert into public.baru_familias (nome, criada_por) values (trim(p_nome), uid) returning id into v_id;
  insert into public.baru_familia_membros (familia_id, user_id, papel, admin) values (v_id, uid, 'responsavel', true);
  return v_id;
end;
$$;

-- Convidar: só administrador (adulto entra como membro; dependente, como dependente).
create or replace function public.baru_familia_convidar(p_familia uuid, p_papel text default 'crianca', p_apelido text default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_codigo text;
  letras constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  i int;
begin
  if public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só um administrador do laço convida.' using errcode = '42501';
  end if;
  if p_papel not in ('responsavel', 'crianca') then raise exception 'Papel inválido.'; end if;
  delete from public.baru_familia_convites where familia_id = p_familia and usado_em is null and expira_em < now();
  loop
    v_codigo := '';
    for i in 1..6 loop
      v_codigo := v_codigo || substr(letras, 1 + floor(random() * length(letras))::int, 1);
    end loop;
    exit when not exists (select 1 from public.baru_familia_convites where codigo = v_codigo);
  end loop;
  insert into public.baru_familia_convites (codigo, familia_id, papel, apelido, criado_por)
  values (v_codigo, p_familia, p_papel, nullif(trim(p_apelido), ''), uid);
  return jsonb_build_object('codigo', v_codigo, 'expiraEm', now() + interval '30 minutes', 'papel', p_papel);
end;
$$;

-- Subir e descer de nível: só administrador; o laço nunca fica sem administrador.
create or replace function public.baru_laco_nivel(p_familia uuid, p_user uuid, p_nivel text)
returns text language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_atual text := public.baru_familia_papel(p_familia, p_user);
begin
  if public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só um administrador muda o nível das pessoas.' using errcode = '42501';
  end if;
  if p_nivel not in ('admin', 'membro', 'dependente') then raise exception 'Nível inválido.'; end if;
  if v_atual is null then raise exception 'Esta pessoa não está no laço.'; end if;
  if v_atual = 'responsavel' and p_nivel <> 'admin' and (select count(*) from public.baru_familia_membros
       where familia_id = p_familia and papel = 'responsavel' and admin and saiu_em is null) <= 1 then
    raise exception 'O laço precisa de pelo menos um administrador.';
  end if;
  if p_nivel = 'dependente' then
    if p_user = uid then raise exception 'Você não pode se tornar dependente.'; end if;
    if exists (select 1 from public.baru_familia_membros
                where user_id = p_user and familia_id <> p_familia and saiu_em is null) then
      raise exception 'Esta pessoa está em outro laço. Um dependente fica em um laço só.';
    end if;
    update public.baru_familia_membros set papel = 'crianca', admin = false
     where familia_id = p_familia and user_id = p_user and saiu_em is null;
    insert into public.baru_familia_regras (crianca_id, familia_id, atualizado_por)
    values (p_user, p_familia, uid)
    on conflict (crianca_id) do update set familia_id = excluded.familia_id;
  else
    update public.baru_familia_membros set papel = 'responsavel', admin = (p_nivel = 'admin')
     where familia_id = p_familia and user_id = p_user and saiu_em is null;
    -- Deixou de ser dependente: as regras do celular dele deixam de valer.
    if v_atual = 'crianca' then delete from public.baru_familia_regras where crianca_id = p_user; end if;
  end if;
  return p_nivel;
end;
$$;
revoke all on function public.baru_laco_nivel(uuid, uuid, text) from public, anon;
grant execute on function public.baru_laco_nivel(uuid, uuid, text) to authenticated;

CREATE OR REPLACE FUNCTION public.baru_familia_mapa(p_familia uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  -- Adultos do laço (administrador ou membro) veem o mapa; dependente não.
  if public.baru_familia_papel(p_familia, auth.uid()) not in ('responsavel', 'membro')
     or public.baru_familia_papel(p_familia, auth.uid()) is null then
    raise exception 'Só adultos do laço veem o mapa.' using errcode = '42501';
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
        'admin', m.admin,
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
        'id', f.id, 'nome', f.nome, 'meuPapel', eu.papel, 'souAdmin', eu.papel = 'responsavel' and eu.admin,
        'responsaveis', (select coalesce(jsonb_agg(jsonb_build_object('id', m.user_id, 'apelido', m.apelido, 'admin', m.admin,
             'email', (select u.email from auth.users u where u.id = m.user_id),
             'foto', (select ft.atualizada_em from public.baru_fotos ft where ft.user_id = m.user_id)) order by m.entrou_em), '[]'::jsonb)
           from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'responsavel' and m.saiu_em is null),
        'criancas', case when eu.papel = 'responsavel' and eu.admin then (
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
          else (select coalesce(jsonb_agg(jsonb_build_object('apelido', m.apelido, 'id', case when eu.papel = 'responsavel' then m.user_id end)), '[]'::jsonb)
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

-- Tirar do laço: só administrador tira os outros; o laço nunca fica sem administrador.
create or replace function public.baru_familia_remover(p_familia uuid, p_user uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_papel text := public.baru_familia_papel(p_familia, p_user);
begin
  if v_papel is null then raise exception 'Esta pessoa não está no laço.'; end if;
  if p_user = uid then
    if v_papel = 'crianca' then raise exception 'Peça a um administrador para tirar este aparelho do laço.' using errcode = '42501'; end if;
  elsif public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só um administrador tira pessoas do laço.' using errcode = '42501';
  end if;
  if v_papel = 'responsavel' and (select count(*) from public.baru_familia_membros
       where familia_id = p_familia and papel = 'responsavel' and admin and saiu_em is null) <= 1 then
    raise exception 'O laço precisa de pelo menos um administrador.';
  end if;
  update public.baru_familia_membros set saiu_em = now() where familia_id = p_familia and user_id = p_user and saiu_em is null;
  if v_papel = 'crianca' then
    delete from public.baru_familia_regras where crianca_id = p_user;
  end if;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (p_familia, case when v_papel = 'crianca' then p_user end, 'saiu', jsonb_build_object('papel', v_papel, 'por', uid));
end;
$$;

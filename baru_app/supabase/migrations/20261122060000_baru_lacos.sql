-- Laços: o que era "família" vira um laço com tipo. Família (crianças,
-- regras, tempo de tela), amigos ou pessoas de confiança (só mapa e SOS).

alter table public.baru_familias add column if not exists tipo text not null default 'familia';
do $$ begin
  alter table public.baru_familias add constraint baru_familias_tipo_check check (tipo in ('familia', 'amigos', 'confianca'));
exception when duplicate_object then null; end $$;

drop function if exists public.baru_familia_criar(text);
create or replace function public.baru_familia_criar(p_nome text, p_tipo text default 'familia')
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_id uuid;
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if coalesce(p_tipo, 'familia') not in ('familia', 'amigos', 'confianca') then raise exception 'Tipo de laço inválido.'; end if;
  if public.baru_familia_da_crianca(uid) is not null then
    raise exception 'Esta conta está num laço como criança. Saia dele antes de criar um laço.';
  end if;
  if (select count(*) from public.baru_familia_membros where user_id = uid and papel = 'responsavel' and saiu_em is null) >= 10 then
    raise exception 'Limite de 10 laços por pessoa.';
  end if;
  insert into public.baru_familias (nome, criada_por, tipo) values (trim(p_nome), uid, coalesce(p_tipo, 'familia')) returning id into v_id;
  insert into public.baru_familia_membros (familia_id, user_id, papel) values (v_id, uid, 'responsavel');
  return v_id;
end;
$$;
revoke all on function public.baru_familia_criar(text, text) from public, anon;
grant execute on function public.baru_familia_criar(text, text) to authenticated;

create or replace function public.baru_familia_convidar(p_familia uuid, p_papel text default 'crianca', p_apelido text default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_codigo text;
  letras constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  i int;
begin
  if public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só um adulto do laço convida.' using errcode = '42501';
  end if;
  if p_papel not in ('responsavel', 'crianca') then raise exception 'Papel inválido.'; end if;
  if p_papel = 'crianca' and (select tipo from public.baru_familias where id = p_familia) <> 'familia' then
    raise exception 'Crianças entram só em laços de família.';
  end if;
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
        'id', f.id, 'nome', f.nome, 'tipo', f.tipo, 'meuPapel', eu.papel,
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

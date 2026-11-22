-- Plano família de um laço, para a web de gestão e o app: qual plano cobre o
-- laço, quantas vagas tem e quantas estão usadas, quem paga e até quando.
-- Qualquer pessoa do laço lê (é a mesma informação que ela já vê no app).

create or replace function public.baru_laco_plano(p_familia uuid)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  s public.baru_assinaturas_loja%rowtype;
  usadas integer;
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if not exists (select 1 from public.baru_familia_membros
                  where familia_id = p_familia and user_id = uid and saiu_em is null) then
    raise exception 'Você não está neste laço.' using errcode = '42501';
  end if;
  select count(*) into usadas from public.baru_familia_membros where familia_id = p_familia and saiu_em is null;
  select * into s from public.baru_assinaturas_loja
   where laco_id = p_familia and produto in ('baru_familia', 'baru_familia_mais')
     and revogada_em is null and expira_em > now()
   order by expira_em desc limit 1;
  if s.user_id is null then
    return jsonb_build_object('plano', null, 'usadas', usadas, 'limite', 6);
  end if;
  return jsonb_build_object(
    'plano', case when s.produto = 'baru_familia_mais' then 'familia_mais' else 'familia' end,
    'planoBase', s.plano_base,
    'loja', s.loja,
    'limite', case when s.produto = 'baru_familia_mais' then 10 else 6 end,
    'usadas', usadas,
    'souPagante', s.user_id = uid,
    'pagante', coalesce((select m.apelido from public.baru_familia_membros m
                          where m.familia_id = p_familia and m.user_id = s.user_id),
                        split_part((select u.email from auth.users u where u.id = s.user_id), '@', 1)),
    'ate', s.expira_em,
    'renova', s.renova
  );
end;
$$;

revoke all on function public.baru_laco_plano(uuid) from public, anon;
grant execute on function public.baru_laco_plano(uuid) to authenticated;

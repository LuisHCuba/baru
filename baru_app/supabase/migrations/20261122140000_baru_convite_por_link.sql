-- Convite por link (meubaru.com/convite/?c=CÓDIGO): o código vale 48 horas,
-- tempo para a pessoa instalar o app, e passa a ter 8 caracteres (32^8, mais
-- de um trilhão de combinações) para compensar o prazo maior.
-- baru_convite_info mostra na página do convite o nome do laço e quem
-- convidou, só para um código válido.

create or replace function public.baru_familia_convidar(p_familia uuid, p_papel text default 'crianca', p_apelido text default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_codigo text;
  letras constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  i int;
  v_expira timestamptz := now() + interval '48 hours';
begin
  if public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só um administrador do laço convida.' using errcode = '42501';
  end if;
  if p_papel not in ('responsavel', 'crianca') then raise exception 'Papel inválido.'; end if;
  delete from public.baru_familia_convites where familia_id = p_familia and usado_em is null and expira_em < now();
  loop
    v_codigo := '';
    for i in 1..8 loop
      v_codigo := v_codigo || substr(letras, 1 + floor(random() * length(letras))::int, 1);
    end loop;
    exit when not exists (select 1 from public.baru_familia_convites where codigo = v_codigo);
  end loop;
  insert into public.baru_familia_convites (codigo, familia_id, papel, apelido, criado_por, expira_em)
  values (v_codigo, p_familia, p_papel, nullif(trim(p_apelido), ''), uid, v_expira);
  return jsonb_build_object('codigo', v_codigo, 'expiraEm', v_expira, 'papel', p_papel,
                            'link', 'https://meubaru.com/convite/?c=' || v_codigo);
end;
$$;

create or replace function public.baru_convite_info(p_codigo text)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare c public.baru_familia_convites%rowtype;
begin
  if p_codigo is null or length(trim(p_codigo)) not between 6 and 8 then
    return jsonb_build_object('valido', false);
  end if;
  select * into c from public.baru_familia_convites where codigo = upper(trim(p_codigo));
  if not found or c.usado_em is not null or c.expira_em < now() then
    return jsonb_build_object('valido', false);
  end if;
  return jsonb_build_object(
    'valido', true,
    'laco', (select f.nome from public.baru_familias f where f.id = c.familia_id),
    'papel', c.papel,
    'apelido', c.apelido,
    'convidadoPor', coalesce((select m.apelido from public.baru_familia_membros m
                               where m.familia_id = c.familia_id and m.user_id = c.criado_por),
                             split_part((select u.raw_user_meta_data->>'full_name' from auth.users u where u.id = c.criado_por), ' ', 1)),
    'expiraEm', c.expira_em
  );
end;
$$;

revoke all on function public.baru_convite_info(text) from public;
grant execute on function public.baru_convite_info(text) to anon, authenticated;

-- O código passou a ter 8 caracteres (os antigos, de 6, seguem valendo até vencer).
alter table public.baru_familia_convites drop constraint if exists baru_familia_convites_codigo_check;
alter table public.baru_familia_convites add constraint baru_familia_convites_codigo_check
  check (codigo ~ '^[A-Z2-9]{6,8}$');

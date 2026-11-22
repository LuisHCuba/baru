-- Revisão de segurança e desempenho antes da produção (22/11/2026).
--
-- 1. Funções de gatilho sem EXECUTE para ninguém (o gatilho roda com o dono).
-- 2. Selos: a política lia baru_familia_membros, que o usuário não lê; agora
--    usa baru_sou_do_laco (responde só sobre a própria pessoa).
-- 3. Políticas com auth.uid() passam a usar (select auth.uid()): o Postgres
--    calcula uma vez por consulta, não uma vez por linha (advisor
--    auth_rls_initplan). Quem vê o quê não muda.
--
-- As views baru_admin_* seguem SECURITY DEFINER de propósito: todas filtram por
-- baru_e_admin(), e quem não é admin recebe zero linhas. baru_toca_anel e
-- baru_toca_habitat filtram pela toca da própria pessoa.

do $$
declare f record;
begin
  for f in select p.oid::regprocedure as sig from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.prorettype = 'trigger'::regtype loop
    execute format('revoke execute on function %s from public, anon, authenticated', f.sig);
  end loop;
end $$;

create or replace function public.baru_sou_do_laco(p_familia uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.baru_familia_membros m
                  where m.familia_id = p_familia and m.user_id = auth.uid() and m.saiu_em is null);
$$;
revoke all on function public.baru_sou_do_laco(uuid) from public, anon;
grant execute on function public.baru_sou_do_laco(uuid) to authenticated;

drop policy if exists "baru selos: membros do laço" on public.baru_selos_semanais;
create policy "baru selos: membros do laço" on public.baru_selos_semanais for select to authenticated
  using (public.baru_sou_do_laco(familia_id));

do $$
declare p record; q text; c text;
begin
  for p in select * from pg_policies where schemaname = 'public'
            and (qual ~ 'auth\.uid\(\)' or with_check ~ 'auth\.uid\(\)') loop
    q := regexp_replace(p.qual, 'auth\.uid\(\)', '(select auth.uid())', 'g');
    c := regexp_replace(p.with_check, 'auth\.uid\(\)', '(select auth.uid())', 'g');
    if q is not null and c is not null then
      execute format('alter policy %I on %I.%I using (%s) with check (%s)', p.policyname, p.schemaname, p.tablename, q, c);
    elsif q is not null then
      execute format('alter policy %I on %I.%I using (%s)', p.policyname, p.schemaname, p.tablename, q);
    else
      execute format('alter policy %I on %I.%I with check (%s)', p.policyname, p.schemaname, p.tablename, c);
    end if;
  end loop;
end $$;

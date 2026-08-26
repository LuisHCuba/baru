-- 6/6 — Adota no repositório o que já existia só no banco remoto.
--
-- Contexto: o projeto remoto tem `public.rls_auto_enable()` e o event trigger
-- `ensure_rls` (dono: postgres), que ligam RLS automaticamente em toda tabela
-- nova criada no schema `public`. Nenhuma migration os descrevia, então o
-- schema não era reproduzível a partir deste repositório. Ver ADR-002.
--
-- Também fecha os avisos `anon_security_definer_function_executable` e
-- `authenticated_security_definer_function_executable` do linter do Supabase,
-- revogando EXECUTE de quem nunca precisou dele.
--
-- Idempotente: pode ser reaplicada sem erro.

create or replace function public.rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path to 'pg_catalog'
as $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$;

comment on function public.rls_auto_enable() is
  'Event trigger: liga RLS em toda tabela criada em public. Rede de seguranca caso uma migration esqueca o enable row level security.';

-- Ninguem chama esta funcao diretamente: o event trigger a executa no contexto
-- do dono. Verificado no banco real, dentro de transacao revertida: com o
-- EXECUTE revogado, `create table` ainda saiu com RLS ligada.
revoke execute on function public.rls_auto_enable() from public;
revoke execute on function public.rls_auto_enable() from anon;
revoke execute on function public.rls_auto_enable() from authenticated;

-- `create event trigger` nao aceita `if not exists`.
do $$
begin
  if not exists (select 1 from pg_event_trigger where evtname = 'ensure_rls') then
    create event trigger ensure_rls
      on ddl_command_end
      when tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      execute function public.rls_auto_enable();
  end if;
end $$;

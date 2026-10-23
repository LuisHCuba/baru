-- Exclusão da conta pelo próprio usuário, de dentro do app (exigência da
-- Google Play para apps com cadastro).
--
-- "Apagar meus dados" limpava as tabelas do app mas deixava o login em
-- auth.users. Esta função apaga o login de quem a chama — só dele: o id vem
-- de auth.uid(), nunca de parâmetro. As 15 tabelas com user_id caem junto
-- pelo `on delete cascade` de cada uma.

create or replace function public.baru_excluir_minha_conta()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'sem sessão' using errcode = '28000';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.baru_excluir_minha_conta() from public, anon;
grant execute on function public.baru_excluir_minha_conta() to authenticated;

-- Posição do adulto com o Baru fechado: o celular manda pela chave do
-- aparelho do responsável (a mesma dos avisos), sem sessão aberta. Só grava se
-- a própria pessoa escolheu aparecer no mapa ("mostrar minha localização").
create or replace function public.baru_familia_resp_posicao(
  p_chave text, p_lat double precision, p_lng double precision,
  p_precisao integer default null, p_bateria integer default null)
returns boolean language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare v_user uuid;
begin
  if p_chave is null or length(p_chave) <> 64 then return false; end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then return false; end if;
  update public.baru_familia_resp_aparelhos set visto_em = now()
   where chave_hash = encode(digest(p_chave, 'sha256'), 'hex') returning user_id into v_user;
  if v_user is null then return false; end if;
  update public.baru_familia_resp_local set
    lat = p_lat, lng = p_lng,
    precisao_m = case when p_precisao between 0 and 100000 then p_precisao end,
    bateria = case when p_bateria between 0 and 100 then p_bateria end,
    em = now()
  where user_id = v_user and ligada;
  return found;
end;
$$;
revoke all on function public.baru_familia_resp_posicao(text, double precision, double precision, integer, integer) from public;
grant execute on function public.baru_familia_resp_posicao(text, double precision, double precision, integer, integer) to anon, authenticated;

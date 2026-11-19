-- Push para o iPhone da criança: regra mudou → push silencioso → o iPhone busca
-- as regras com a chave do aparelho e aplica (pausa, horários, meta), mesmo
-- com o Baru fechado. No Android o guarda já busca sozinho a cada 2 minutos.
--
-- Fluxo: trigger em baru_familia_regras → pg_net chama a Edge Function
-- familia-push → ela confere que a regra acabou de mudar, assina o JWT da
-- Apple com a chave .p8 (segredo da função) e envia para cada token da criança.

create extension if not exists pg_net with schema extensions;

alter table public.baru_familia_aparelhos
  add column if not exists plataforma text check (plataforma in ('ios', 'android')),
  add column if not exists push_token text,
  add column if not exists push_ambiente text check (push_ambiente in ('producao', 'sandbox'));

-- O aparelho registra o token de push (com a própria chave, sem login).
create or replace function public.baru_familia_push_token(p_chave text, p_token text, p_plataforma text, p_ambiente text default 'producao')
returns boolean language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
begin
  if p_chave is null or length(p_chave) <> 64 then return false; end if;
  if p_token is not null and p_token !~ '^[0-9a-fA-F]{32,200}$' then return false; end if;
  update public.baru_familia_aparelhos set
    push_token = p_token,
    plataforma = case when p_plataforma in ('ios', 'android') then p_plataforma end,
    push_ambiente = case when p_ambiente = 'sandbox' then 'sandbox' else 'producao' end,
    visto_em = now()
  where chave_hash = encode(digest(p_chave, 'sha256'), 'hex');
  return found;
end;
$$;
revoke all on function public.baru_familia_push_token(text, text, text, text) from public;
grant execute on function public.baru_familia_push_token(text, text, text, text) to anon, authenticated;

-- Regra mudou: avisa a função de push (só se houver token iOS dessa criança).
create or replace function public.baru_familia_avisa_push() returns trigger
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if not exists (select 1 from public.baru_familia_aparelhos
                  where crianca_id = new.crianca_id and push_token is not null and plataforma = 'ios') then
    return new;
  end if;
  perform net.http_post(
    url := 'https://slqpuppkapiewjqvedtj.supabase.co/functions/v1/familia-push',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('crianca_id', new.crianca_id)
  );
  return new;
end;
$$;
revoke all on function public.baru_familia_avisa_push() from public, anon, authenticated;
drop trigger if exists baru_familia_avisa_push on public.baru_familia_regras;
create trigger baru_familia_avisa_push after update on public.baru_familia_regras
  for each row execute function public.baru_familia_avisa_push();

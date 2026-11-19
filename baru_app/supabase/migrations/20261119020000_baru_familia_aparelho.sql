-- Chave do aparelho da criança: o guarda do Android lê as regras sozinho,
-- de poucos em poucos minutos, sem depender do login (que expira em 1 h e
-- não pode ser renovado fora do app sem derrubar a sessão).
--
-- A chave é aleatória (32 bytes), mostrada uma vez ao aparelho; no banco fica
-- só o hash. Ela lê apenas as regras daquela criança, e para de valer quando a
-- criança sai da família.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.baru_familia_aparelhos (
  chave_hash text primary key,
  crianca_id uuid not null references auth.users (id) on delete cascade,
  criado_em timestamptz not null default now(),
  visto_em timestamptz
);
create index if not exists baru_familia_aparelhos_crianca_idx on public.baru_familia_aparelhos (crianca_id);
alter table public.baru_familia_aparelhos enable row level security;
revoke all on table public.baru_familia_aparelhos from anon, authenticated;
comment on table public.baru_familia_aparelhos is 'Chaves dos aparelhos das crianças (só o hash). Sem policy: só as funções baru_familia_* usam.';

-- O aparelho da criança pede a chave (troca a anterior deste aparelho).
create or replace function public.baru_familia_chave_do_aparelho(p_chave_antiga text default null)
returns text language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_chave text;
begin
  if public.baru_familia_da_crianca(uid) is null then
    raise exception 'Este aparelho não está numa família.' using errcode = '42501';
  end if;
  if p_chave_antiga is not null then
    delete from public.baru_familia_aparelhos
     where chave_hash = encode(digest(p_chave_antiga, 'sha256'), 'hex') and crianca_id = uid;
  end if;
  -- No máximo 5 aparelhos por criança: os mais antigos saem.
  delete from public.baru_familia_aparelhos where chave_hash in (
    select chave_hash from public.baru_familia_aparelhos where crianca_id = uid order by criado_em desc offset 4);
  v_chave := encode(gen_random_bytes(32), 'hex');
  insert into public.baru_familia_aparelhos (chave_hash, crianca_id) values (encode(digest(v_chave, 'sha256'), 'hex'), uid);
  return v_chave;
end;
$$;

-- O guarda lê as regras com a chave. Sem família, devolve nulo (o guarda desliga).
create or replace function public.baru_familia_regras_do_aparelho(p_chave text)
returns jsonb language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare
  v_crianca uuid;
  r public.baru_familia_regras%rowtype;
begin
  if p_chave is null or length(p_chave) <> 64 then return null; end if;
  update public.baru_familia_aparelhos set visto_em = now()
   where chave_hash = encode(digest(p_chave, 'sha256'), 'hex')
   returning crianca_id into v_crianca;
  if v_crianca is null or public.baru_familia_da_crianca(v_crianca) is null then return null; end if;
  select * into r from public.baru_familia_regras where crianca_id = v_crianca;
  if not found then return null; end if;
  return public.baru_familia_regras_json(r) - 'avisos';
end;
$$;

-- Tirar a criança da família apaga as chaves dela.
create or replace function public.baru_familia_apaga_chaves() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.papel = 'crianca' and new.saiu_em is not null and old.saiu_em is null then
    delete from public.baru_familia_aparelhos where crianca_id = new.user_id;
  end if;
  return new;
end;
$$;
drop trigger if exists baru_familia_apaga_chaves on public.baru_familia_membros;
create trigger baru_familia_apaga_chaves after update on public.baru_familia_membros
  for each row execute function public.baru_familia_apaga_chaves();
revoke all on function public.baru_familia_apaga_chaves() from public, anon, authenticated;

revoke all on function public.baru_familia_chave_do_aparelho(text) from public, anon;
grant execute on function public.baru_familia_chave_do_aparelho(text) to authenticated;
revoke all on function public.baru_familia_regras_do_aparelho(text) from public;
grant execute on function public.baru_familia_regras_do_aparelho(text) to anon, authenticated;

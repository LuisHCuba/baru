-- 12/12 — Lista de espera do site.
--
-- Primeira tabela do projeto que **não** é por usuário: quem entra na lista
-- não tem conta ainda. Por isso ela foge do padrão das outras treze e exige
-- um desenho de acesso próprio.
--
-- O problema: a landing é um site estático servido pelo Netlify, e a única
-- credencial que ele pode carregar é a chave publicável (anon). Se a tabela
-- aceitasse `insert` direto do anon via PostgREST, duas coisas ruins:
--
--   1. o unique em `email` devolveria 409 num e-mail repetido, e isso é
--      enumeração — dá para descobrir quem já se cadastrou;
--   2. qualquer policy de leitura vazaria a lista inteira de e-mails.
--
-- A solução: a tabela não recebe policy nenhuma (RLS ligada + zero policies
-- = ninguém acessa por PostgREST) e o único caminho de entrada é a função
-- `baru_waitlist_entrar`, que é SECURITY DEFINER — roda como dona da tabela,
-- passa por cima da RLS, e devolve sempre a mesma resposta com ou sem
-- e-mail repetido.
--
-- Idempotente: pode ser reaplicada sem erro.

create table if not exists public.baru_waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  idioma text not null default 'pt' check (idioma in ('pt', 'en', 'es', 'zh')),
  origem text not null default 'landing',
  ip inet,
  criado_em timestamptz not null default now(),
  avisado_em timestamptz
);

comment on table public.baru_waitlist is
  'Lista de espera do site. Sem user_id: quem entra ainda nao tem conta. '
  'Escrita so pela funcao baru_waitlist_entrar; leitura so pelo dashboard.';

comment on column public.baru_waitlist.email is
  'Ja normalizado em minuscula e sem espacos pela funcao de entrada.';

comment on column public.baru_waitlist.ip is
  'So para conter abuso. Nao sai daqui e nao vai para lugar nenhum.';

comment on column public.baru_waitlist.avisado_em is
  'Quando o convite do teste aberto foi enviado. Nulo = ainda na fila.';

create index if not exists baru_waitlist_criado_em_idx
  on public.baru_waitlist (criado_em desc);

-- RLS ligada e **nenhuma** policy: PostgREST nega tudo para anon e
-- authenticated. Quem lê a lista é o dashboard, com a service_role.
alter table public.baru_waitlist enable row level security;

revoke all on table public.baru_waitlist from anon, authenticated;

-- A porta de entrada. Sempre devolve o mesmo texto, exista o e-mail ou não.
create or replace function public.baru_waitlist_entrar(
  p_email text,
  p_idioma text default 'pt'
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_email  text := lower(trim(coalesce(p_email, '')));
  v_idioma text := coalesce(nullif(trim(coalesce(p_idioma, '')), ''), 'pt');
  v_ip     inet;
  v_recentes integer;
begin
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]{2,}$'
     or length(v_email) > 254 then
    raise exception 'email invalido' using errcode = '22023';
  end if;

  if v_idioma not in ('pt', 'en', 'es', 'zh') then
    v_idioma := 'pt';
  end if;

  -- Freio de abuso por IP. O cabeçalho pode não existir (chamada fora do
  -- PostgREST, proxy sem x-forwarded-for): nesse caso não trava nada, só
  -- deixa de contar. Um formulário público sem nenhum freio é convite.
  begin
    v_ip := split_part(
      current_setting('request.headers', true)::json ->> 'x-forwarded-for',
      ',', 1
    )::inet;
  exception when others then
    v_ip := null;
  end;

  if v_ip is not null then
    select count(*) into v_recentes
      from public.baru_waitlist
     where ip = v_ip
       and criado_em > now() - interval '1 hour';

    if v_recentes >= 5 then
      raise exception 'muitas tentativas' using errcode = '54000';
    end if;
  end if;

  insert into public.baru_waitlist (email, idioma, ip)
  values (v_email, v_idioma, v_ip)
  on conflict (email) do nothing;

  -- Mesma resposta nos dois casos: e-mail novo e e-mail repetido.
  return 'ok';
end;
$$;

comment on function public.baru_waitlist_entrar(text, text) is
  'Unica porta de entrada da lista de espera. SECURITY DEFINER para o anon '
  'inserir sem poder ler, e resposta constante para nao vazar quem ja entrou.';

revoke all on function public.baru_waitlist_entrar(text, text) from public;
grant execute on function public.baru_waitlist_entrar(text, text)
  to anon, authenticated;

-- Assinaturas do Baru no Asaas: 7 dias grátis e depois tudo pago.
--
-- Fonte da verdade do acesso. `baru_subscriptions` (o trial local do app)
-- continua como está, mas o app escreve nela: não serve para liberar nada.
-- Aqui só a Edge Function escreve; a pessoa só lê a própria linha.

-- Chave geral da cobrança. Enquanto `ligada_em` for nulo, ninguém é bloqueado:
-- o app pode ir para a loja antes de o Asaas estar configurado. O teste de quem
-- já tinha conta conta a partir daqui, não da data do cadastro.
create table if not exists public.baru_cobranca (
  id smallint primary key default 1 check (id = 1),
  ligada_em timestamptz
);
insert into public.baru_cobranca (id) values (1) on conflict (id) do nothing;
alter table public.baru_cobranca enable row level security;
comment on table public.baru_cobranca is 'Chave geral da cobrança (linha única). Sem policy: muda só por SQL Editor ou migration.';

create table if not exists public.baru_assinaturas (
  user_id uuid primary key references auth.users (id) on delete cascade,
  plano text not null check (plano in ('monthly', 'annual')),
  status text not null default 'pendente'
    check (status in ('pendente', 'ativa', 'atrasada', 'cancelada')),
  asaas_cliente_id text,
  asaas_assinatura_id text unique,
  valor_centavos integer,
  link_pagamento text,
  cobranca_id text,
  forma_pagamento text check (forma_pagamento in ('PIX', 'BOLETO', 'CREDIT_CARD')),
  pago_ate date,
  cancelada_em timestamptz,
  termos_aceitos_em timestamptz,
  termos_versao text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
alter table public.baru_assinaturas enable row level security;
drop policy if exists "baru_assinaturas_le_a_propria" on public.baru_assinaturas;
create policy "baru_assinaturas_le_a_propria" on public.baru_assinaturas
  for select to authenticated using (auth.uid() = user_id);
comment on table public.baru_assinaturas is 'Assinatura no Asaas. Escrita só por service_role (asaas-assinatura e asaas-webhook).';

create table if not exists public.baru_asaas_eventos (
  id text primary key,
  tipo text not null,
  payload jsonb not null,
  recebido_em timestamptz not null default now(),
  processado_em timestamptz
);
alter table public.baru_asaas_eventos enable row level security;
comment on table public.baru_asaas_eventos is 'Eventos do webhook do Asaas já vistos. A PK é a idempotência. Sem policy: só service_role.';

create or replace function public.baru_meu_acesso()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  ligada timestamptz;
  criado timestamptz;
  teste_ate timestamptz;
  a public.baru_assinaturas%rowtype;
  hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  pago boolean;
begin
  if uid is null then
    raise exception 'sem sessão' using errcode = '28000';
  end if;
  select ligada_em into ligada from public.baru_cobranca where id = 1;
  select created_at into criado from auth.users where id = uid;
  select * into a from public.baru_assinaturas where user_id = uid;
  pago := a.pago_ate is not null and a.pago_ate >= hoje;
  if ligada is not null then
    teste_ate := greatest(criado, ligada) + interval '7 days';
  end if;
  return jsonb_build_object(
    'liberado', ligada is null or now() < teste_ate or pago,
    'testeAte', teste_ate,
    'pagoAte', a.pago_ate,
    'status', a.status,
    'plano', a.plano
  );
end;
$$;

revoke all on function public.baru_meu_acesso() from public, anon;
grant execute on function public.baru_meu_acesso() to authenticated;

-- Assinatura comprada dentro do app: Google Play (Android) e App Store (iPhone).
--
-- Uma assinatura só, mensal, R$ 14,90 (igual no site). Quem grava é só o
-- servidor (função loja-assinatura), depois de conferir a compra com a loja.
-- O acesso (baru_acesso_de) passa a valer também com a compra na loja.

create table if not exists public.baru_assinaturas_loja (
  user_id uuid primary key references auth.users(id) on delete cascade,
  loja text not null check (loja in ('google', 'apple')),
  produto text not null,
  -- Google: purchaseToken. Apple: originalTransactionId.
  compra_id text not null unique,
  expira_em timestamptz not null,
  renova boolean not null default true,
  revogada_em timestamptz,
  teste boolean not null default false,
  atualizado_em timestamptz not null default now()
);
alter table public.baru_assinaturas_loja enable row level security;
-- Sem políticas: só o servidor lê e grava.

create or replace function public.baru_acesso_de(p_uid uuid)
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
declare
  ligada timestamptz;
  criado timestamptz;
  estendido timestamptz;
  teste_ate timestamptz;
  a public.baru_assinaturas%rowtype;
  c public.baru_cortesias%rowtype;
  l public.baru_assinaturas_loja%rowtype;
  hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  pago boolean;
  pago_loja boolean;
  cortesia boolean;
begin
  select ligada_em into ligada from public.baru_cobranca where id = 1;
  select created_at into criado from auth.users where id = p_uid;
  select * into a from public.baru_assinaturas where user_id = p_uid;
  select * into c from public.baru_cortesias where user_id = p_uid;
  select * into l from public.baru_assinaturas_loja where user_id = p_uid;
  select t.ate into estendido from public.baru_testes_estendidos t where t.user_id = p_uid;
  pago := a.pago_ate is not null and a.pago_ate >= hoje;
  pago_loja := l.user_id is not null and l.revogada_em is null and l.expira_em > now();
  cortesia := c.user_id is not null and (c.ate is null or c.ate >= hoje);
  if ligada is not null then
    teste_ate := greatest(greatest(criado, ligada) + interval '7 days', estendido);
  end if;
  return jsonb_build_object(
    'liberado', ligada is null or now() < teste_ate or pago or pago_loja or cortesia,
    -- Com cortesia não há prazo de teste para contar: o app mostraria "teste".
    'testeAte', case when cortesia then null else teste_ate end,
    'pagoAte', case when pago_loja then greatest(a.pago_ate, (l.expira_em at time zone 'America/Sao_Paulo')::date) else a.pago_ate end,
    'status', case when cortesia and not pago and not pago_loja then 'cortesia'
                   when pago_loja then case when l.renova then 'ativa' else 'cancelada' end
                   else a.status end,
    'plano', case when pago_loja then 'mensal' else a.plano end,
    'cortesia', cortesia,
    'cortesiaAte', c.ate,
    'loja', case when l.user_id is not null then l.loja end,
    'lojaExpiraEm', l.expira_em
  );
end;
$function$;

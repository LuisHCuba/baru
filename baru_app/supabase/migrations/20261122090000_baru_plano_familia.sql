-- Plano família: uma assinatura paga pelo administrador libera o premium para
-- as primeiras 6 pessoas do laço dele (entrou_em), enquanto valer.
-- Assinatura individual anual: mesmo produto da mensal (baru_assinatura),
-- plano base "anual".

alter table public.baru_assinaturas_loja
  add column if not exists laco_id uuid references public.baru_familias (id) on delete set null,
  add column if not exists plano_base text;

create index if not exists baru_assinaturas_loja_laco on public.baru_assinaturas_loja (laco_id) where laco_id is not null;

-- O laço com plano família ativo que cobre esta pessoa (e até quando).
create or replace function public.baru_familia_cobertura(p_uid uuid)
returns table (laco_id uuid, pagante uuid, expira_em timestamptz)
language sql stable security definer set search_path = '' as $$
  select s.laco_id, s.user_id, s.expira_em
    from public.baru_assinaturas_loja s
    join public.baru_familia_membros eu on eu.familia_id = s.laco_id and eu.user_id = p_uid and eu.saiu_em is null
   where s.produto = 'baru_familia' and s.revogada_em is null and s.expira_em > now()
     and (select count(*) from public.baru_familia_membros m
           where m.familia_id = s.laco_id and m.saiu_em is null and m.entrou_em <= eu.entrou_em) <= 6
   order by s.expira_em desc
   limit 1;
$$;
revoke all on function public.baru_familia_cobertura(uuid) from public, anon, authenticated;

create or replace function public.baru_acesso_de(p_uid uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  ligada timestamptz;
  criado timestamptz;
  estendido timestamptz;
  teste_ate timestamptz;
  a public.baru_assinaturas%rowtype;
  c public.baru_cortesias%rowtype;
  l public.baru_assinaturas_loja%rowtype;
  fam record;
  hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  pago boolean;
  pago_loja boolean;
  pago_familia boolean;
  cortesia boolean;
begin
  select ligada_em into ligada from public.baru_cobranca where id = 1;
  select created_at into criado from auth.users where id = p_uid;
  select * into a from public.baru_assinaturas where user_id = p_uid;
  select * into c from public.baru_cortesias where user_id = p_uid;
  select * into l from public.baru_assinaturas_loja where user_id = p_uid;
  select * into fam from public.baru_familia_cobertura(p_uid);
  select t.ate into estendido from public.baru_testes_estendidos t where t.user_id = p_uid;
  pago := a.pago_ate is not null and a.pago_ate >= hoje;
  pago_loja := l.user_id is not null and l.revogada_em is null and l.expira_em > now();
  pago_familia := fam.laco_id is not null;
  cortesia := c.user_id is not null and (c.ate is null or c.ate >= hoje);
  if ligada is not null then
    teste_ate := greatest(greatest(criado, ligada) + interval '7 days', estendido);
  end if;
  return jsonb_build_object(
    'liberado', ligada is null or now() < teste_ate or pago or pago_loja or pago_familia or cortesia,
    'testeAte', case when cortesia then null else teste_ate end,
    'pagoAte', case
                 when pago_loja then greatest(a.pago_ate, (l.expira_em at time zone 'America/Sao_Paulo')::date)
                 when pago_familia then greatest(a.pago_ate, (fam.expira_em at time zone 'America/Sao_Paulo')::date)
                 else a.pago_ate end,
    'status', case when cortesia and not pago and not pago_loja and not pago_familia then 'cortesia'
                   when pago_loja then case when l.renova then 'ativa' else 'cancelada' end
                   when pago_familia then 'ativa'
                   else a.status end,
    'plano', case when pago_loja and l.produto = 'baru_familia' then 'familia'
                  when pago_loja then coalesce(l.plano_base, 'mensal')
                  when pago_familia then 'familia'
                  else a.plano end,
    'cortesia', cortesia,
    'cortesiaAte', c.ate,
    'loja', case when l.user_id is not null then l.loja end,
    'lojaExpiraEm', l.expira_em,
    -- Coberto pelo plano família de outra pessoa do laço.
    'familia', case when pago_familia then jsonb_build_object('laco', fam.laco_id, 'pagante', fam.pagante,
                 'souPagante', fam.pagante = p_uid, 'ate', fam.expira_em) end,
    -- Tem plano individual na loja e também é coberto pelo família: sugerir cancelar o individual.
    'individualDuplicado', pago_loja and l.produto <> 'baru_familia' and pago_familia and fam.pagante <> p_uid
  );
end;
$$;

-- Família+: igual ao família, mas cobre até 10 pessoas do laço.
create or replace function public.baru_familia_cobertura(p_uid uuid)
returns table (laco_id uuid, pagante uuid, expira_em timestamptz)
language sql stable security definer set search_path = '' as $$
  select s.laco_id, s.user_id, s.expira_em
    from public.baru_assinaturas_loja s
    join public.baru_familia_membros eu on eu.familia_id = s.laco_id and eu.user_id = p_uid and eu.saiu_em is null
   where s.produto in ('baru_familia', 'baru_familia_mais') and s.revogada_em is null and s.expira_em > now()
     and (select count(*) from public.baru_familia_membros m
           where m.familia_id = s.laco_id and m.saiu_em is null and m.entrou_em <= eu.entrou_em)
         <= case when s.produto = 'baru_familia_mais' then 10 else 6 end
   order by s.expira_em desc
   limit 1;
$$;
revoke all on function public.baru_familia_cobertura(uuid) from public, anon, authenticated;

-- O crescimento do bicho, por espécie.
--
-- O bicho passou a nascer (ovo ou recém-nascido no ninho) e crescer em cinco
-- estágios, e a régua é **quantas sessões de foco a pessoa concluiu com
-- aquela espécie**. Isso é um contador por espécie, e não cabe em
-- `sessoes_concluidas`, que é da conta inteira. Ver ADR-024.
--
-- Duas colunas jsonb, ambas mapas `{"owl": 7, "capybara": 3}`:
--
-- - `sessoes_por_especie`: contador que só sobe. O app funde por chave
--   ficando com o maior (`Crescimento.fundeMaior`), como já faz com os
--   outros contadores desta tabela.
-- - `estagio_celebrado`: o último estágio cuja cena (eclosão, crescimento)
--   a pessoa já viu, por espécie. Sem ele, reinstalar o app repetiria a cena
--   do ovo chocando para um bicho adulto.
--
-- Aditiva e idempotente: `add column if not exists`, com default `{}`.
-- Nenhuma linha existente é reescrita; o app novo funciona contra um banco
-- ainda sem a migration (`SupabaseGateway.colunasOpcionais`).

alter table public.baru_progression
  add column if not exists sessoes_por_especie jsonb not null default '{}'::jsonb,
  add column if not exists estagio_celebrado jsonb not null default '{}'::jsonb;

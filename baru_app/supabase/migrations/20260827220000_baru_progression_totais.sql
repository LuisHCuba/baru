-- 10/10 — Os totais da trilha e as missões resgatadas.
--
-- **Isto é correção de perda de dado.** O arranque do app grava por cima do
-- snapshot local o snapshot montado das linhas do remoto. Todo campo sem
-- coluna remota voltava ao padrão a cada vez que o app abria:
--
--   * `missoes_resgatadas` — missões resgatadas reapareciam por resgatar;
--   * `sessoes_concluidas`, `melhor_sequencia`, `dias_abaixo_da_meta` — os
--     três contadores que a trilha inteira lê, então a trilha zerava.
--
-- O app já parou de perder isso sozinho (`AppSnapshot.fundeCom` funde em vez
-- de sobrescrever, e contador que só sobe fica com o maior). Estas colunas são
-- o outro lado: sem elas o dado nunca chega ao segundo aparelho.
--
-- Aditiva e idempotente: `add column if not exists`, com default. Nenhuma
-- linha existente é tocada.

alter table public.baru_progression
  add column if not exists sessoes_concluidas integer not null default 0,
  add column if not exists melhor_sequencia integer not null default 0,
  add column if not exists dias_abaixo_da_meta integer not null default 0,
  add column if not exists missoes_resgatadas text[] not null default '{}';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'baru_progression_totais_ck'
  ) then
    alter table public.baru_progression
      add constraint baru_progression_totais_ck
      check (
        sessoes_concluidas >= 0
        and melhor_sequencia >= 0
        and dias_abaixo_da_meta >= 0
      );
  end if;
end $$;

comment on column public.baru_progression.missoes_resgatadas is
  'Chaves id@periodo das missoes ja resgatadas. Resgate e idempotente.';

comment on column public.baru_progression.sessoes_concluidas is
  'Total de sessoes de foco concluidas. So sobe: alimenta a trilha.';

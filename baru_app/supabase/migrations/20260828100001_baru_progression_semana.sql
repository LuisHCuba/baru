-- 15/15 — Os dias abaixo da meta **desta semana**, com a semana junto.
--
-- **Correção de perda de dado, da mesma família da migration 10.** Cinco
-- contadores de missão só existiam no aparelho. Quatro deles —
-- `minutosDeFocoHoje`, `maiorSessaoHoje`, `sessoesNaSemana`,
-- `minutosNaSemana` — **não ganham coluna aqui de propósito**: cada um é uma
-- soma sobre `baru_sessions`, que já sobe inteira, e o app passou a refazer a
-- conta na leitura (`BaruRowCodec.contadoresDe`). Coluna para eles seria um
-- segundo registro do mesmo fato, e dois registros do mesmo fato divergem sem
-- que ninguém perceba até a missão pagar errado.
--
-- O quinto não é derivável de nada: "fechar o dia abaixo da meta" depende do
-- tempo de tela **daquele dia fechado**, e o app só guarda o agregado do dia
-- corrente em `baru_screen_time`. Sem esta coluna, reinstalar o app zerava o
-- progresso da missão semanal `semana_tres_abaixo` mesmo com tudo o mais
-- sincronizado.
--
-- **Por que a coluna vem acompanhada de `semana_de`.** O contador zera na
-- segunda-feira dentro do aparelho, e essa zeragem não marca sincronização —
-- o remoto seguiria com o número da semana passada até a próxima gravação por
-- outro motivo. O carimbo diz a que semana o número pertence; o app devolve
-- zero quando ele não é o da semana corrente. Sem isso, a semana nova
-- começaria com a missão semanal meio cumprida de graça.
--
-- `semana_de` é sempre uma segunda-feira, a mesma âncora da faixa da home e
-- de `QuadroDeMissoes`. Fica anulável porque a linha que já existe não tem
-- semana nenhuma a declarar, e inventar uma seria afirmar o que não se sabe:
-- o app já lê carimbo ausente como zero.
--
-- Aditiva e idempotente: `add column if not exists`, com default. Nenhuma
-- linha existente é tocada.

alter table public.baru_progression
  add column if not exists dias_abaixo_na_semana integer not null default 0,
  add column if not exists semana_de date;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'baru_progression_semana_ck'
  ) then
    alter table public.baru_progression
      add constraint baru_progression_semana_ck
      check (
        dias_abaixo_na_semana >= 0
        and dias_abaixo_na_semana <= 7
        -- `extract(isodow)` = 1 é segunda-feira. O carimbo que não for
        -- segunda descreveria uma janela que o app não sabe ler, e o
        -- contador voltaria valendo para uma semana que nunca existiu.
        and (semana_de is null or extract(isodow from semana_de) = 1)
      );
  end if;
end $$;

comment on column public.baru_progression.dias_abaixo_na_semana is
  'Dias fechados abaixo da meta na semana de `semana_de`. Zera na segunda.';

comment on column public.baru_progression.semana_de is
  'Segunda-feira da semana a que `dias_abaixo_na_semana` pertence.';

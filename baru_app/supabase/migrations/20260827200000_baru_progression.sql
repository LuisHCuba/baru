-- 8/8 — Progressão e vínculo.
--
-- XP, nível celebrado e marcos resgatados existiam **só no aparelho**: foram
-- adicionados ao snapshot local sem coluna remota, então desinstalar o app
-- zerava a trilha inteira. Trocar de telefone também.
--
-- O vínculo entra na mesma tabela porque é da mesma natureza: um número que
-- só sobe e que descreve o quanto a relação avançou.
--
-- `afeto` é o total de afagos completos de todos os tempos. `carinhos_hoje`
-- é o contador do dia, que zera quando o calendário vira — fica aqui, e não
-- em `baru_daily_progress`, porque quem lê o vínculo quer os dois juntos.
--
-- Idempotente: pode ser reaplicada sem erro.

create table if not exists public.baru_progression (
  user_id uuid primary key references auth.users (id) on delete cascade,
  xp integer not null default 0 check (xp >= 0),
  nivel_celebrado integer not null default 1 check (nivel_celebrado >= 1),
  afeto integer not null default 0 check (afeto >= 0),
  carinhos_hoje integer not null default 0 check (carinhos_hoje >= 0),
  marcos_resgatados text[] not null default '{}',
  updated_at timestamptz not null default now()
);

comment on table public.baru_progression is
  'XP, nivel celebrado, marcos resgatados e vinculo (afagos). So sobe.';

comment on column public.baru_progression.afeto is
  'Afagos completos de todos os tempos.';

comment on column public.baru_progression.carinhos_hoje is
  'Afagos que ja renderam XP hoje. Zera na virada do calendario.';

-- O event trigger `ensure_rls` (migration 6) já liga RLS em tabela nova de
-- public, mas deixar explícito é o que torna o arquivo auditável sozinho.
alter table public.baru_progression enable row level security;

drop policy if exists baru_progression_select on public.baru_progression;
drop policy if exists baru_progression_insert on public.baru_progression;
drop policy if exists baru_progression_update on public.baru_progression;
drop policy if exists baru_progression_delete on public.baru_progression;

create policy baru_progression_select
  on public.baru_progression for select to authenticated
  using (auth.uid() = user_id);

create policy baru_progression_insert
  on public.baru_progression for insert to authenticated
  with check (auth.uid() = user_id);

create policy baru_progression_update
  on public.baru_progression for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy baru_progression_delete
  on public.baru_progression for delete to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete
  on public.baru_progression to authenticated;

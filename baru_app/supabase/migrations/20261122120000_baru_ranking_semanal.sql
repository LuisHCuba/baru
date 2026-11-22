-- Ranking semanal do laço: quem mais ganhou XP em cada skill (e no geral) de
-- segunda a domingo, no fuso America/Sao_Paulo. Mostra só totais; os registros
-- continuam privados. Recurso do plano família (Família ou Família+ ativo no
-- laço); sem plano, o app mostra só a prévia bloqueada.
--
-- A semana fecha sozinha (pg_cron, de hora em hora, idempotente): grava os selos
-- dos vencedores e pede o aviso ao familia-push.

alter table public.baru_familia_membros
  add column if not exists fora_do_ranking boolean not null default false;

create table if not exists public.baru_selos_semanais (
  familia_id uuid not null references public.baru_familias (id) on delete cascade,
  semana date not null,
  skill text not null check (skill in ('saudavel', 'inteligente', 'forte', 'geral')),
  user_id uuid not null references auth.users (id) on delete cascade,
  xp integer not null check (xp > 0),
  avisado_em timestamptz,
  criado_em timestamptz not null default now(),
  primary key (familia_id, semana, skill, user_id)
);
create index if not exists baru_selos_user on public.baru_selos_semanais (user_id);
alter table public.baru_selos_semanais enable row level security;
drop policy if exists "baru selos: membros do laço" on public.baru_selos_semanais;
create policy "baru selos: membros do laço" on public.baru_selos_semanais for select to authenticated
  using (exists (select 1 from public.baru_familia_membros m
                  where m.familia_id = baru_selos_semanais.familia_id and m.user_id = auth.uid() and m.saiu_em is null));
-- Escrita só pelo servidor.

create table if not exists public.baru_semanas_fechadas (
  semana date primary key,
  fechada_em timestamptz not null default now()
);
alter table public.baru_semanas_fechadas enable row level security;
-- Sem policy: só o servidor lê e grava.

-- Segunda-feira da semana de p_dia.
create or replace function public.baru_semana_de(p_dia date) returns date
language sql immutable set search_path = pg_catalog, pg_temp as $$
  select p_dia - (extract(isodow from p_dia)::int - 1);
$$;

create or replace function public.baru_laco_tem_plano_familia(p_familia uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.baru_assinaturas_loja s
                  where s.laco_id = p_familia and s.produto in ('baru_familia', 'baru_familia_mais')
                    and s.revogada_em is null and s.expira_em > now());
$$;

-- Totais da semana por pessoa do laço (sem quem saiu do ranking).
create or replace function public.baru_totais_da_semana(p_familia uuid, p_semana date)
returns table (user_id uuid, saudavel int, inteligente int, forte int, total int, paginas int, minutos int)
language sql stable security definer set search_path = '' as $$
  select m.user_id,
         coalesce(sum(h.xp) filter (where h.skill = 'saudavel'), 0)::int,
         coalesce(sum(h.xp) filter (where h.skill = 'inteligente'), 0)::int,
         coalesce(sum(h.xp) filter (where h.skill = 'forte'), 0)::int,
         coalesce(sum(h.xp), 0)::int,
         coalesce(sum(h.quantidade) filter (where h.unidade = 'paginas'), 0)::int,
         coalesce(sum(h.quantidade) filter (where h.unidade = 'minutos'), 0)::int
    from public.baru_familia_membros m
    left join public.baru_habitos h
      on h.user_id = m.user_id and h.apagado_em is null and h.dia between p_semana and p_semana + 6
   where m.familia_id = p_familia and m.saiu_em is null and not m.fora_do_ranking
   group by m.user_id;
$$;

create or replace function public.baru_ranking_semanal(p_familia uuid, p_semana date default null)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  atual date := public.baru_semana_de(public.baru_hoje_sp());
  v_semana date := public.baru_semana_de(coalesce(p_semana, public.baru_hoje_sp()));
  eu public.baru_familia_membros%rowtype;
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  select * into eu from public.baru_familia_membros where familia_id = p_familia and user_id = uid and saiu_em is null;
  if not found then raise exception 'Você não está neste laço.' using errcode = '42501'; end if;
  if v_semana > atual or v_semana < atual - 7 * 12 then v_semana := atual; end if;

  if not public.baru_laco_tem_plano_familia(p_familia) then
    return jsonb_build_object('bloqueado', true, 'semana', v_semana, 'euFora', eu.fora_do_ranking,
      'membros', (select coalesce(jsonb_agg(jsonb_build_object(
          'id', m.user_id, 'papel', m.papel, 'eu', m.user_id = uid,
          'apelido', coalesce(m.apelido, split_part((select u.email from auth.users u where u.id = m.user_id), '@', 1)))), '[]'::jsonb)
        from public.baru_familia_membros m where m.familia_id = p_familia and m.saiu_em is null and not m.fora_do_ranking));
  end if;

  return jsonb_build_object(
    'bloqueado', false,
    'semana', v_semana,
    'atual', v_semana = atual,
    'euFora', eu.fora_do_ranking,
    'membros', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', t.user_id, 'papel', m.papel, 'eu', t.user_id = uid,
        'apelido', coalesce(m.apelido, split_part((select u.email from auth.users u where u.id = t.user_id), '@', 1)),
        'saudavel', t.saudavel, 'inteligente', t.inteligente, 'forte', t.forte, 'total', t.total,
        'paginas', t.paginas, 'minutos', t.minutos,
        'selos', (select count(*) from public.baru_selos_semanais s where s.familia_id = p_familia and s.user_id = t.user_id))
        order by t.total desc, m.entrou_em), '[]'::jsonb)
      from public.baru_totais_da_semana(p_familia, v_semana) t
      join public.baru_familia_membros m on m.familia_id = p_familia and m.user_id = t.user_id and m.saiu_em is null),
    'historico', (select coalesce(jsonb_agg(jsonb_build_object('semana', s.semana, 'skill', s.skill, 'id', s.user_id, 'xp', s.xp)
        order by s.semana desc, s.skill), '[]'::jsonb)
      from public.baru_selos_semanais s where s.familia_id = p_familia and s.semana >= atual - 7 * 8)
  );
end;
$$;

-- Sair (ou voltar) do ranking sem sair do laço.
create or replace function public.baru_ranking_participar(p_familia uuid, p_participa boolean)
returns boolean language plpgsql volatile security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  update public.baru_familia_membros set fora_do_ranking = not coalesce(p_participa, true)
   where familia_id = p_familia and user_id = auth.uid() and saiu_em is null;
  if not found then raise exception 'Você não está neste laço.' using errcode = '42501'; end if;
  return coalesce(p_participa, true);
end;
$$;

-- Fecha a semana anterior (uma vez): selos para quem venceu cada skill e o
-- geral (empate: todos os empatados levam), só nos laços com plano família.
create or replace function public.baru_fecha_semana() returns integer
language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
declare
  v_semana date := public.baru_semana_de(public.baru_hoje_sp()) - 7;
  n integer := 0;
begin
  insert into public.baru_semanas_fechadas (semana) values (v_semana) on conflict do nothing;
  if not found then return 0; end if;

  with lacos as (
    select distinct s.laco_id as familia_id from public.baru_assinaturas_loja s
     where s.laco_id is not null and s.produto in ('baru_familia', 'baru_familia_mais')
       and s.revogada_em is null and s.expira_em > now()
  ), totais as (
    select l.familia_id, t.* from lacos l cross join lateral public.baru_totais_da_semana(l.familia_id, v_semana) t
  ), por_skill as (
    select familia_id, user_id, k.skill, k.xp
      from totais cross join lateral (values ('saudavel', saudavel), ('inteligente', inteligente),
                                             ('forte', forte), ('geral', total)) as k(skill, xp)
  ), vencedores as (
    select p.* from por_skill p
     where p.xp > 0 and p.xp = (select max(q.xp) from por_skill q where q.familia_id = p.familia_id and q.skill = p.skill)
  )
  insert into public.baru_selos_semanais (familia_id, semana, skill, user_id, xp)
  select familia_id, v_semana, skill, user_id, xp from vencedores
  on conflict do nothing;
  get diagnostics n = row_count;

  if n > 0 then
    perform net.http_post(
      url := 'https://slqpuppkapiewjqvedtj.supabase.co/functions/v1/familia-push',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := jsonb_build_object('selos_semana', v_semana));
  end if;
  return n;
end;
$$;

revoke all on function public.baru_semana_de(date) from public, anon;
revoke all on function public.baru_laco_tem_plano_familia(uuid) from public, anon, authenticated;
revoke all on function public.baru_totais_da_semana(uuid, date) from public, anon, authenticated;
revoke all on function public.baru_ranking_semanal(uuid, date) from public, anon;
revoke all on function public.baru_ranking_participar(uuid, boolean) from public, anon;
revoke all on function public.baru_fecha_semana() from public, anon, authenticated;
grant execute on function public.baru_semana_de(date) to authenticated;
grant execute on function public.baru_ranking_semanal(uuid, date) to authenticated;
grant execute on function public.baru_ranking_participar(uuid, boolean) to authenticated;

create extension if not exists pg_cron;
select cron.unschedule(jobid) from cron.job where jobname = 'baru-fecha-semana';
select cron.schedule('baru-fecha-semana', '7 * * * *', 'select public.baru_fecha_semana()');

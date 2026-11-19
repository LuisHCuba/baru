-- Modo família do Baru (docs/CONTROLE_PARENTAL.md, fase 3).
--
-- Um responsável cria a família, gera um código, e o celular da criança entra
-- com ele. O responsável define as regras (meta diária, horários sem tela,
-- pausa ao estourar, filtro de sites) e acompanha o dia de cada criança.
--
-- Tudo passa por funções SECURITY DEFINER: as tabelas não têm policy nenhuma,
-- então ninguém lê nem escreve direto pela API. Cada função confere o papel
-- de quem chamou.
--
-- O que a criança manda do aparelho:
--   Android: minutos de tela do dia (com o acesso ao uso concedido).
--   iOS:     só o maior limiar da meta atingido hoje — a Apple não deixa o
--            dado de Screen Time sair do aparelho além disso.

-- ---------------------------------------------------------------- tabelas

create table if not exists public.baru_familias (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(trim(nome)) between 1 and 60),
  criada_por uuid references auth.users (id) on delete set null,
  criada_em timestamptz not null default now()
);

create table if not exists public.baru_familia_membros (
  familia_id uuid not null references public.baru_familias (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  papel text not null check (papel in ('responsavel', 'crianca')),
  apelido text check (apelido is null or length(trim(apelido)) between 1 and 40),
  plataforma text check (plataforma in ('ios', 'android', 'web')),
  entrou_em timestamptz not null default now(),
  saiu_em timestamptz,
  primary key (familia_id, user_id)
);
-- Uma criança está em uma família por vez.
create unique index if not exists baru_familia_uma_por_crianca
  on public.baru_familia_membros (user_id) where papel = 'crianca' and saiu_em is null;
create index if not exists baru_familia_membros_user_idx on public.baru_familia_membros (user_id);

create table if not exists public.baru_familia_convites (
  codigo text primary key check (codigo ~ '^[A-Z2-9]{6}$'),
  familia_id uuid not null references public.baru_familias (id) on delete cascade,
  papel text not null default 'crianca' check (papel in ('responsavel', 'crianca')),
  apelido text,
  criado_por uuid references auth.users (id) on delete set null,
  criado_em timestamptz not null default now(),
  expira_em timestamptz not null default now() + interval '30 minutes',
  usado_por uuid references auth.users (id) on delete set null,
  usado_em timestamptz
);

create table if not exists public.baru_familia_regras (
  crianca_id uuid primary key references auth.users (id) on delete cascade,
  familia_id uuid not null references public.baru_familias (id) on delete cascade,
  meta_min integer not null default 120 check (meta_min between 0 and 1440),
  -- [{"dias":[1,2,3,4,5],"inicio":"21:00","fim":"07:00"}], dias ISO (1 = segunda)
  horarios_sem_tela jsonb not null default '[]'::jsonb check (jsonb_typeof(horarios_sem_tela) = 'array'),
  pausar_ao_estourar boolean not null default false,
  filtro_sites boolean not null default false,
  atualizado_por uuid references auth.users (id) on delete set null,
  atualizado_em timestamptz not null default now()
);

create table if not exists public.baru_familia_dia (
  crianca_id uuid not null references auth.users (id) on delete cascade,
  dia date not null,
  plataforma text check (plataforma in ('ios', 'android')),
  minutos integer check (minutos between 0 and 1440),
  limiar_max_min integer check (limiar_max_min between 0 and 2880),
  meta_min integer,
  meta_batida_em timestamptz,
  focos integer not null default 0 check (focos >= 0),
  pausas integer not null default 0 check (pausas >= 0),
  atualizado_em timestamptz not null default now(),
  primary key (crianca_id, dia)
);

create table if not exists public.baru_familia_eventos (
  id bigint generated always as identity primary key,
  familia_id uuid not null references public.baru_familias (id) on delete cascade,
  crianca_id uuid references auth.users (id) on delete cascade,
  tipo text not null check (tipo in ('entrou', 'saiu', 'meta_75', 'meta_batida', 'meta_passou', 'regras_mudaram', 'autorizacao_revogada')),
  em timestamptz not null default now(),
  detalhe jsonb
);
create index if not exists baru_familia_eventos_familia_idx on public.baru_familia_eventos (familia_id, em desc);

alter table public.baru_familias enable row level security;
alter table public.baru_familia_membros enable row level security;
alter table public.baru_familia_convites enable row level security;
alter table public.baru_familia_regras enable row level security;
alter table public.baru_familia_dia enable row level security;
alter table public.baru_familia_eventos enable row level security;
revoke all on table public.baru_familias, public.baru_familia_membros, public.baru_familia_convites,
  public.baru_familia_regras, public.baru_familia_dia, public.baru_familia_eventos from anon, authenticated;

comment on table public.baru_familias is 'Modo família. Sem policy: só as funções baru_familia_* leem e escrevem.';
comment on table public.baru_familia_dia is 'Dia de cada criança. Android manda minutos; iOS só o maior limiar da meta atingido (regra da Apple).';

-- ---------------------------------------------------------------- auxiliares (internas)

create or replace function public.baru_familia_papel(p_familia uuid, p_uid uuid)
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select m.papel from public.baru_familia_membros m
   where m.familia_id = p_familia and m.user_id = p_uid and m.saiu_em is null;
$$;
revoke all on function public.baru_familia_papel(uuid, uuid) from public, anon, authenticated;

create or replace function public.baru_familia_da_crianca(p_crianca uuid)
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select m.familia_id from public.baru_familia_membros m
   where m.user_id = p_crianca and m.papel = 'crianca' and m.saiu_em is null;
$$;
revoke all on function public.baru_familia_da_crianca(uuid) from public, anon, authenticated;

create or replace function public.baru_familia_hoje()
returns date language sql stable set search_path = pg_catalog, pg_temp
as $$ select (now() at time zone 'America/Sao_Paulo')::date $$;

-- ---------------------------------------------------------------- responsável

create or replace function public.baru_familia_criar(p_nome text)
returns uuid language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_id uuid;
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  if public.baru_familia_da_crianca(uid) is not null then
    raise exception 'Esta conta está numa família como criança. Saia dela antes de criar uma família.';
  end if;
  if (select count(*) from public.baru_familia_membros where user_id = uid and papel = 'responsavel' and saiu_em is null) >= 3 then
    raise exception 'Limite de 3 famílias por responsável.';
  end if;
  insert into public.baru_familias (nome, criada_por) values (trim(p_nome), uid) returning id into v_id;
  insert into public.baru_familia_membros (familia_id, user_id, papel) values (v_id, uid, 'responsavel');
  return v_id;
end;
$$;

create or replace function public.baru_familia_convidar(p_familia uuid, p_papel text default 'crianca', p_apelido text default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_codigo text;
  letras constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  i int;
begin
  if public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só o responsável convida.' using errcode = '42501';
  end if;
  if p_papel not in ('responsavel', 'crianca') then raise exception 'Papel inválido.'; end if;
  -- Convites antigos e não usados desta família deixam de valer.
  delete from public.baru_familia_convites where familia_id = p_familia and usado_em is null and expira_em < now();
  loop
    v_codigo := '';
    for i in 1..6 loop
      v_codigo := v_codigo || substr(letras, 1 + floor(random() * length(letras))::int, 1);
    end loop;
    exit when not exists (select 1 from public.baru_familia_convites where codigo = v_codigo);
  end loop;
  insert into public.baru_familia_convites (codigo, familia_id, papel, apelido, criado_por)
  values (v_codigo, p_familia, p_papel, nullif(trim(p_apelido), ''), uid);
  return jsonb_build_object('codigo', v_codigo, 'expiraEm', now() + interval '30 minutes', 'papel', p_papel);
end;
$$;

create or replace function public.baru_familia_definir_regras(
  p_crianca uuid, p_meta_min integer default null, p_horarios jsonb default null,
  p_pausar boolean default null, p_filtro_sites boolean default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(p_crianca);
  r public.baru_familia_regras%rowtype;
begin
  if v_familia is null or public.baru_familia_papel(v_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só o responsável da família muda as regras.' using errcode = '42501';
  end if;
  if p_horarios is not null and jsonb_typeof(p_horarios) <> 'array' then raise exception 'Horários inválidos.'; end if;
  update public.baru_familia_regras set
    meta_min = coalesce(p_meta_min, meta_min),
    horarios_sem_tela = coalesce(p_horarios, horarios_sem_tela),
    pausar_ao_estourar = coalesce(p_pausar, pausar_ao_estourar),
    filtro_sites = coalesce(p_filtro_sites, filtro_sites),
    atualizado_por = uid, atualizado_em = now()
  where crianca_id = p_crianca
  returning * into r;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (v_familia, p_crianca, 'regras_mudaram', jsonb_build_object('meta_min', r.meta_min, 'pausar', r.pausar_ao_estourar, 'filtro_sites', r.filtro_sites));
  return to_jsonb(r) - 'familia_id';
end;
$$;

create or replace function public.baru_familia_remover(p_familia uuid, p_user uuid)
returns void language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_papel text := public.baru_familia_papel(p_familia, p_user);
begin
  if v_papel is null then raise exception 'Esta pessoa não está na família.'; end if;
  -- Remover outra pessoa exige ser responsável. Sair por conta própria: a criança não sai sozinha.
  if p_user = uid then
    if v_papel = 'crianca' then raise exception 'Peça ao responsável para tirar este aparelho da família.' using errcode = '42501'; end if;
  elsif public.baru_familia_papel(p_familia, uid) is distinct from 'responsavel' then
    raise exception 'Só o responsável remove pessoas.' using errcode = '42501';
  end if;
  if v_papel = 'responsavel' and (select count(*) from public.baru_familia_membros
       where familia_id = p_familia and papel = 'responsavel' and saiu_em is null) <= 1 then
    raise exception 'A família precisa de pelo menos um responsável.';
  end if;
  update public.baru_familia_membros set saiu_em = now() where familia_id = p_familia and user_id = p_user and saiu_em is null;
  if v_papel = 'crianca' then
    delete from public.baru_familia_regras where crianca_id = p_user;
  end if;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (p_familia, case when v_papel = 'crianca' then p_user end, 'saiu', jsonb_build_object('papel', v_papel, 'por', uid));
end;
$$;

-- ---------------------------------------------------------------- aparelho da criança

create or replace function public.baru_familia_entrar(p_codigo text, p_plataforma text default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  c public.baru_familia_convites%rowtype;
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  select * into c from public.baru_familia_convites where codigo = upper(trim(p_codigo)) for update;
  if not found or c.usado_em is not null or c.expira_em < now() then
    raise exception 'Código inválido ou vencido. Peça um novo ao responsável.';
  end if;
  if public.baru_familia_papel(c.familia_id, uid) is not null then
    raise exception 'Esta conta já está nesta família.';
  end if;
  if c.papel = 'crianca' then
    if public.baru_familia_da_crianca(uid) is not null then
      raise exception 'Esta conta já está em outra família.';
    end if;
    if exists (select 1 from public.baru_familia_membros where user_id = uid and papel = 'responsavel' and saiu_em is null) then
      raise exception 'Esta conta é de um responsável. Use a conta da criança neste aparelho.';
    end if;
  end if;
  insert into public.baru_familia_membros (familia_id, user_id, papel, apelido, plataforma)
  values (c.familia_id, uid, c.papel, c.apelido, case when p_plataforma in ('ios', 'android', 'web') then p_plataforma end)
  on conflict (familia_id, user_id) do update
     set papel = excluded.papel, apelido = coalesce(excluded.apelido, baru_familia_membros.apelido),
         plataforma = excluded.plataforma, entrou_em = now(), saiu_em = null;
  if c.papel = 'crianca' then
    insert into public.baru_familia_regras (crianca_id, familia_id, atualizado_por)
    values (uid, c.familia_id, c.criado_por)
    on conflict (crianca_id) do update set familia_id = excluded.familia_id;
  end if;
  update public.baru_familia_convites set usado_por = uid, usado_em = now() where codigo = c.codigo;
  insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe)
  values (c.familia_id, case when c.papel = 'crianca' then uid end, 'entrou', jsonb_build_object('papel', c.papel, 'plataforma', p_plataforma));
  return public.baru_familia_minha();
end;
$$;

-- O aparelho da criança manda o dia. Gera os eventos de meta para o responsável.
create or replace function public.baru_familia_registrar_dia(
  p_plataforma text, p_minutos integer default null, p_limiar_max_min integer default null,
  p_focos integer default null, p_pausas integer default null, p_dia date default null)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(uid);
  v_dia date := coalesce(p_dia, public.baru_familia_hoje());
  v_meta int;
  antes public.baru_familia_dia%rowtype;
  v_uso_antes int;
  v_uso int;
begin
  if v_familia is null then raise exception 'Este aparelho não está numa família.' using errcode = '42501'; end if;
  if v_dia < public.baru_familia_hoje() - 2 or v_dia > public.baru_familia_hoje() then raise exception 'Dia fora do intervalo.'; end if;
  if p_plataforma not in ('ios', 'android') then raise exception 'Plataforma inválida.'; end if;
  select meta_min into v_meta from public.baru_familia_regras where crianca_id = uid;
  select * into antes from public.baru_familia_dia where crianca_id = uid and dia = v_dia;

  insert into public.baru_familia_dia as d (crianca_id, dia, plataforma, minutos, limiar_max_min, meta_min, focos, pausas)
  values (uid, v_dia, p_plataforma, p_minutos, p_limiar_max_min, v_meta, coalesce(p_focos, 0), coalesce(p_pausas, 0))
  on conflict (crianca_id, dia) do update set
    plataforma = excluded.plataforma,
    -- Uso do dia só cresce: um envio atrasado não apaga o que já chegou.
    minutos = greatest(d.minutos, excluded.minutos),
    limiar_max_min = greatest(d.limiar_max_min, excluded.limiar_max_min),
    meta_min = excluded.meta_min,
    focos = greatest(d.focos, excluded.focos),
    pausas = greatest(d.pausas, excluded.pausas),
    atualizado_em = now();

  v_uso_antes := greatest(coalesce(antes.minutos, 0), coalesce(antes.limiar_max_min, 0));
  v_uso := greatest(coalesce(p_minutos, 0), coalesce(p_limiar_max_min, 0), v_uso_antes);
  if v_meta > 0 and v_dia = public.baru_familia_hoje() then
    if v_uso_antes < v_meta * 0.75 and v_uso >= v_meta * 0.75 and v_uso < v_meta then
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe) values (v_familia, uid, 'meta_75', jsonb_build_object('uso', v_uso, 'meta', v_meta));
    end if;
    if v_uso_antes < v_meta and v_uso >= v_meta then
      update public.baru_familia_dia set meta_batida_em = now() where crianca_id = uid and dia = v_dia;
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe) values (v_familia, uid, 'meta_batida', jsonb_build_object('uso', v_uso, 'meta', v_meta));
    end if;
    if v_uso_antes < v_meta * 1.5 and v_uso >= v_meta * 1.5 then
      insert into public.baru_familia_eventos (familia_id, crianca_id, tipo, detalhe) values (v_familia, uid, 'meta_passou', jsonb_build_object('uso', v_uso, 'meta', v_meta));
    end if;
  end if;
  return (select to_jsonb(r) - 'familia_id' from public.baru_familia_regras r where r.crianca_id = uid);
end;
$$;

-- O aparelho da criança avisa quando a autorização do Screen Time / acesso ao uso some.
create or replace function public.baru_familia_avisar_autorizacao(p_ativa boolean)
returns void language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  v_familia uuid := public.baru_familia_da_crianca(uid);
begin
  if v_familia is null then return; end if;
  if not p_ativa then
    insert into public.baru_familia_eventos (familia_id, crianca_id, tipo) values (v_familia, uid, 'autorizacao_revogada');
  end if;
end;
$$;

-- ---------------------------------------------------------------- leitura

-- Tudo o que o app precisa, do ponto de vista de quem chamou.
create or replace function public.baru_familia_minha()
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  hoje date := public.baru_familia_hoje();
begin
  if uid is null then raise exception 'sem sessão' using errcode = '28000'; end if;
  return jsonb_build_object(
    'souCrianca', public.baru_familia_da_crianca(uid) is not null,
    'minhasRegras', (select to_jsonb(r) - 'familia_id' - 'atualizado_por' from public.baru_familia_regras r where r.crianca_id = uid),
    'familias', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', f.id, 'nome', f.nome, 'meuPapel', eu.papel,
        'responsaveis', (select coalesce(jsonb_agg(jsonb_build_object('id', m.user_id, 'apelido', m.apelido,
             'email', (select u.email from auth.users u where u.id = m.user_id)) order by m.entrou_em), '[]'::jsonb)
           from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'responsavel' and m.saiu_em is null),
        -- A criança só vê os nomes da família; quem vê o dia de cada uma é o responsável.
        'criancas', case when eu.papel = 'responsavel' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', m.user_id, 'apelido', m.apelido, 'plataforma', m.plataforma, 'entrouEm', m.entrou_em,
            'bicho', (select jsonb_build_object('especie', p.species, 'nome', p.pet_name) from public.baru_pets p where p.user_id = m.user_id),
            'regras', (select to_jsonb(r) - 'familia_id' - 'crianca_id' from public.baru_familia_regras r where r.crianca_id = m.user_id),
            'hoje', (select to_jsonb(d) - 'crianca_id' from public.baru_familia_dia d where d.crianca_id = m.user_id and d.dia = hoje),
            'semana', (select coalesce(jsonb_agg(to_jsonb(d) - 'crianca_id' order by d.dia), '[]'::jsonb)
                         from public.baru_familia_dia d where d.crianca_id = m.user_id and d.dia > hoje - 7)
          ) order by m.entrou_em), '[]'::jsonb)
          from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'crianca' and m.saiu_em is null)
          else (select coalesce(jsonb_agg(jsonb_build_object('apelido', m.apelido)), '[]'::jsonb)
                  from public.baru_familia_membros m where m.familia_id = f.id and m.papel = 'crianca' and m.saiu_em is null) end,
        'eventos', case when eu.papel = 'responsavel' then (
          select coalesce(jsonb_agg(x order by x.em desc), '[]'::jsonb) from (
            select e.em, e.tipo, e.crianca_id, e.detalhe from public.baru_familia_eventos e
             where e.familia_id = f.id order by e.em desc limit 50) x) end
      ) order by f.criada_em)
      from public.baru_familias f
      join public.baru_familia_membros eu on eu.familia_id = f.id and eu.user_id = uid and eu.saiu_em is null
    ), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------- permissões

revoke all on function public.baru_familia_criar(text) from public, anon;
revoke all on function public.baru_familia_convidar(uuid, text, text) from public, anon;
revoke all on function public.baru_familia_definir_regras(uuid, integer, jsonb, boolean, boolean) from public, anon;
revoke all on function public.baru_familia_remover(uuid, uuid) from public, anon;
revoke all on function public.baru_familia_entrar(text, text) from public, anon;
revoke all on function public.baru_familia_registrar_dia(text, integer, integer, integer, integer, date) from public, anon;
revoke all on function public.baru_familia_avisar_autorizacao(boolean) from public, anon;
revoke all on function public.baru_familia_minha() from public, anon;
grant execute on function public.baru_familia_criar(text) to authenticated;
grant execute on function public.baru_familia_convidar(uuid, text, text) to authenticated;
grant execute on function public.baru_familia_definir_regras(uuid, integer, jsonb, boolean, boolean) to authenticated;
grant execute on function public.baru_familia_remover(uuid, uuid) to authenticated;
grant execute on function public.baru_familia_entrar(text, text) to authenticated;
grant execute on function public.baru_familia_registrar_dia(text, integer, integer, integer, integer, date) to authenticated;
grant execute on function public.baru_familia_avisar_autorizacao(boolean) to authenticated;
grant execute on function public.baru_familia_minha() to authenticated;

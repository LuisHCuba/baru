-- Avisos da App Store já tratados (App Store Server Notifications V2).
-- A Apple pode reenviar o mesmo aviso; o id dele aqui impede tratar duas vezes.
create table if not exists public.baru_apple_notificacoes (
  id text primary key,
  tipo text not null,
  recebida_em timestamptz not null default now()
);
alter table public.baru_apple_notificacoes enable row level security;
-- Sem políticas: só o servidor lê e grava.

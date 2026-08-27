-- 9/9 — Horário do relatório da noite, e o sexo do companheiro.
--
-- O relatório da noite estava fixo em 21h **no código**: quem dorme às 22h
-- recebia no meio da noite e quem dorme às 20h nunca via. Vira preferência.
--
-- `sexo` não muda o desenho. Muda o pronome: em português e espanhol
-- "ele te esperou" e "ela te esperou" são frases diferentes, e o app estava
-- chamando toda companheira de "ele".
--
-- Idempotente e aditiva: `add column if not exists`, com default. Nenhuma
-- linha existente é tocada.

alter table public.baru_settings
  add column if not exists evening_hour integer not null default 21,
  add column if not exists evening_minute integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'baru_settings_evening_hour_ck'
  ) then
    alter table public.baru_settings
      add constraint baru_settings_evening_hour_ck
      check (evening_hour between 0 and 23);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'baru_settings_evening_minute_ck'
  ) then
    alter table public.baru_settings
      add constraint baru_settings_evening_minute_ck
      check (evening_minute between 0 and 59);
  end if;
end $$;

comment on column public.baru_settings.evening_hour is
  'Hora do relatorio da noite (0-23). Era fixo em 21 no codigo.';

alter table public.baru_pets
  add column if not exists sexo text not null default 'naoDito';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'baru_pets_sexo_ck'
  ) then
    alter table public.baru_pets
      add constraint baru_pets_sexo_ck
      check (sexo in ('naoDito', 'macho', 'femea'));
  end if;
end $$;

comment on column public.baru_pets.sexo is
  'Sexo do companheiro. Define o pronome, nao o desenho.';

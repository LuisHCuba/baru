-- 14/14 — A preferência de som.
--
-- `AppSnapshot.som` existia desde sempre no snapshot local e **em lugar
-- nenhum do banco**. O interruptor de som em Ajustes marcava o domínio de
-- ajustes para sincronizar, o push subia a linha inteira de `baru_settings`,
-- e o som não ia junto porque não havia coluna. Consequência exata: quem
-- desligava o som reinstalava o app — ou entrava no segundo aparelho — e o
-- som voltava ligado, sem nada no app explicando o porquê.
--
-- `default true` porque ligado é o padrão de quem nunca mexeu: marcar as
-- linhas existentes como `false` silenciaria o app de todo mundo que já usa.
--
-- Aditiva e idempotente: `add column if not exists`, com default. Nenhuma
-- linha existente é tocada.

alter table public.baru_settings
  add column if not exists som boolean not null default true;

comment on column public.baru_settings.som is
  'Som do app ligado. Padrao ligado: e o estado de quem nunca mexeu.';

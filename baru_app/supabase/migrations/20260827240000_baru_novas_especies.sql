-- 12/12 — Quatro espécies novas.
--
-- Axolote, pinguim, gata e raposa. As quatro se desbloqueiam na trilha, não
-- no quiz do onboarding — quiz é quem você é, trilha é o que você conquistou.
--
-- O `check` de `baru_pets.species` era uma lista fechada de quatro. Cada
-- espécie nova exigiria uma migração, então ele sai: quem tem o catálogo é o
-- app, e um valor desconhecido aqui não corrompe nada — o `parseSpecies` do
-- Dart já cai na capivara quando não reconhece.
--
-- Aditiva e idempotente. Nenhuma linha é tocada.

alter table public.baru_pets
  drop constraint if exists baru_pets_species_check;

comment on column public.baru_pets.species is
  'Especie do companheiro. O catalogo vive no app; valor desconhecido cai na capivara.';

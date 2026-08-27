-- 11/11 — Ter deixou de ser o mesmo que estar usando.
--
-- A loja passou a ter três naturezas de item: objeto de cena (quantos
-- quiser), cenário (um por vez) e roupa (uma peça por lugar do corpo). Comprar
-- coloca; o usuário pode tirar depois. Sem esta coluna, trocar de aparelho
-- devolvia tudo para a cena.
--
-- `default true` de propósito: o inventário que já existe foi comprado quando
-- comprar era o mesmo que colocar. Marcar como não-equipado esvaziaria o
-- habitat de quem já tinha itens.
--
-- Aditiva e idempotente.

alter table public.baru_inventory_items
  add column if not exists equipped boolean not null default true;

comment on column public.baru_inventory_items.equipped is
  'Item em uso: no habitat, no bicho ou como cenario. Ter nao e usar.';

-- A lista de ids fechada em `check` não cabe mais: eram oito objetos, agora
-- há roupas e cenários, e cada item novo exigiria uma migração. O id passa a
-- ser validado pelo app, que é quem tem o catálogo.
alter table public.baru_inventory_items
  drop constraint if exists baru_inventory_items_item_id_check;

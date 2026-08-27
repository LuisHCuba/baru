-- 13/13 — As respostas do quiz, inteiras.
--
-- `baru_onboarding_answers` tinha três colunas de texto — `q0`, `q1`, `q2` —
-- e guardava o **rótulo traduzido**. Dois problemas nisso:
--
--   1. Trocar de idioma invalidava a resposta. Havia até um `if` no
--      `setLang` do app apagando as três de propósito.
--   2. Cada pergunta nova exigiria uma coluna nova.
--
-- Agora as respostas vão num `jsonb` de `{id_da_pergunta: id_da_opcao}`, com
-- ids estáveis que nunca são traduzidos. As três colunas antigas continuam
-- sendo escritas, agora com o id, porque apagá-las seria migração destrutiva
-- num banco com dados reais.
--
-- Aditiva e idempotente.

alter table public.baru_onboarding_answers
  add column if not exists respostas jsonb not null default '{}'::jsonb;

comment on column public.baru_onboarding_answers.respostas is
  'Respostas do quiz: {id_da_pergunta: id_da_opcao}. Ids estaveis, nunca traduzidos.';

comment on column public.baru_onboarding_answers.q0 is
  'Legado: a primeira resposta. Hoje guarda o id, nao o rotulo. Ver `respostas`.';

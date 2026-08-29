-- 16/16 — `baru_daily_quests` fica, sem escritor.
--
-- **O que ela era.** Duas quests fixas — `focus_session` e `under_goal` — do
-- desenho anterior ao quadro de missões. O app gravava nela a cada
-- `pushStreak`, ou seja, a cada fim de sessão.
--
-- **Por que parou de ser gravada.**
--
--   1. Ninguém lia. Nenhum `select` no app tocava nesta tabela; o dado
--      entrava e não voltava, que é o contrário do que o modelo pede.
--   2. Os dois valores eram **derivados** do que já sobe: `focus_session` é
--      `baru_daily_progress.completed_sessions >= 1` e `under_goal` é
--      `baru_screen_time.usage_min < goal_min`. Dois registros do mesmo fato
--      divergem, e ninguém percebe até um deles ser lido.
--   3. O `check` de `quest_key` aceita duas chaves. O sistema de missões tem
--      17 tipos, e o resgate mora em `baru_progression.missoes_resgatadas`
--      como `id@periodo` — com o período dentro da chave, que é o que torna
--      o resgate idempotente. Ampliar o `check` daria uma segunda gramática
--      para a mesma coisa.
--
-- **Por que a tabela não é derrubada.** O banco tem dados reais, e um
-- `drop table` apaga o histórico de quem usou o app antes desta decisão sem
-- devolver nada em troca. As linhas continuam alcançáveis pelo dono delas
-- (a RLS não muda) e o `on delete cascade` para `auth.users` continua
-- valendo: apagar a conta segue apagando isto junto. A tabela também
-- continua na lista `tabelasDoUsuario` do app, que é quem apaga dado a
-- pedido.
--
-- Reverter é escrever nela de novo — nada aqui impede.
--
-- Esta migration **não muda schema**: só registra a decisão onde o schema
-- pode ser lido sozinho. É idempotente por natureza.

comment on table public.baru_daily_quests is
  'Historico das duas quests do desenho antigo (focus_session, under_goal). '
  'Sem escritor desde 2026-08-28: os dois valores sao derivados de '
  'baru_daily_progress e baru_screen_time, e o registro de missao vive em '
  'baru_progression.missoes_resgatadas. Mantida pelos dados que ja tem.';

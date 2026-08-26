# Decisões de arquitetura (ADRs)

Ordem cronológica. Formato: Contexto / Decisão / Alternativas descartadas /
Consequências e como reverter.

---

## ADR-001 — Colocar o projeto sob git antes de qualquer mudança (2026-08-26)

**Contexto.** O diretório `C:\LHCX\baru` não era um repositório git: nenhum
histórico, nenhuma forma de reverter. O repositório remoto
`github.com/LuisHCuba/baru` existia, público e vazio.

**Decisão.** `git init` na raiz (englobando `Baru App v2.dc.html` e `baru_app/`),
commit de baseline sem mudança funcional, branch de trabalho
`night/2026-08-26`, push de `main` e da branch.

**Alternativas descartadas.** Iniciar git dentro de `baru_app/` — quebraria a
referência `../Baru App v2.dc.html` que o GO_LIVE usa como fonte de verdade de
UI. Trabalhar sem git — inaceitável antes de mexer em schema.

**Consequências.** Ciclos passam a ser reversíveis. O repositório é **público**:
qualquer coisa commitada é publicada. Reverter: `git remote remove origin` e
apagar `.git/` restaura o estado anterior sem tocar nos arquivos.

---

## ADR-002 — Adotar `rls_auto_enable()` em migration em vez de removê-la (2026-08-26)

**Contexto.** O banco real tem `public.rls_auto_enable()`, um event trigger
`SECURITY DEFINER` que habilita RLS automaticamente em toda tabela nova criada
no schema `public`. Não está em nenhuma migration do repositório: o schema não
é reproduzível a partir do repo, o que o §5 do mandato proíbe. O linter do
Supabase sinaliza que `anon` e `authenticated` têm `EXECUTE` sobre ela.

**Decisão.** Adotar: migration que recria a função e o event trigger de forma
idempotente, mais `revoke execute ... from public, anon, authenticated`. A
função é uma rede de segurança útil — mantém a garantia de RLS mesmo se uma
migration futura esquecer o `enable row level security`.

**Alternativas descartadas.** (a) `drop function` — removeria uma proteção real
e mexeria em objeto que o humano pode ter criado de propósito; destrutivo.
(b) Ignorar a divergência — deixaria o banco irreprodutível.

**Consequências.** Um banco limpo criado a partir das migrations passa a ser
igual ao remoto. O `revoke` fecha o aviso do linter sem alterar comportamento
(funções que retornam `event_trigger` não são chamáveis por RPC). Reverter:
`grant execute on function public.rls_auto_enable() to authenticated, anon`.

---

## ADR-003 — Migrations idempotentes por SQL dinâmico (2026-08-26)

**Contexto.** A migration 5 (`..._migrate_and_slim_profiles.sql`) protege cada
`insert` com `where exists (select 1 from information_schema.columns ...)`. O
guard não funciona: as colunas legadas aparecem na lista de `select`, então o
comando falha no **parse** quando elas já foram removidas. Reexecutar a
migration — fluxo documentado no próprio README ("SQL Editor, um arquivo por
vez") — quebra com `column "species" does not exist`.

**Decisão.** Reescrever os blocos legados da migration 5 dentro de
`do $$ ... execute format(...) ... $$`, para que a checagem de existência
aconteça em tempo de execução e o SQL só seja compilado quando as colunas
existirem.

**Alternativas descartadas.** (a) Deixar como está e documentar "rode só uma
vez" — frágil, e o §10 exige que as migrations apliquem do zero. (b) Dividir em
duas migrations (migrar / contrair) — correto pelo expand→migrate→contract, mas
a contração já foi aplicada no remoto; dividir agora criaria divergência nova.

**Consequências.** As 5 migrations passam a ser reexecutáveis em qualquer ordem
de reaplicação. O SQL fica menos legível. Reverter: restaurar o arquivo pelo
histórico do git.

---

## ADR-004 — Remover e-mail pessoal do repositório público (2026-08-26)

**Contexto.** `supabase/README.md` documentava a conta de teste com o e-mail
pessoal do dono. O remote é público.

**Decisão.** Substituir por ponteiro para `supabase/SEED_TEST_USER.local.md`
(gitignored) **antes** do primeiro commit, para que o dado nunca entre no
histórico. Manter no repositório a URL e o ref do projeto Supabase: são
descobríveis em qualquer binário do app e estão protegidos por RLS verificada.

**Alternativas descartadas.** Commitar e limpar depois — histórico público é
indexável; limpar exigiria reescrever histórico, proibido pelo §4.

**Consequências.** O README público perde a informação de qual conta usar; quem
tem o repo clonado localmente continua com o arquivo local. Reverter: não deve
ser revertido.

---

## ADR-005 — Bônus de meta é pago na virada do dia, não durante o dia (2026-08-26)

**Contexto.** O contrato de produto §5 prevê "+15 por fechar o dia abaixo da
meta". A quest na home e a linha "Bônus por ficar abaixo" no relatório já
exibiam +15, mas nenhum código creditava folhas: a promessa era decorativa.

**Decisão.** Creditar em `_advanceDay`, no fechamento do dia, quando
`companionshipStarted && usageAccess && usage < goal`. O aviso ao usuário sai no
primeiro frame seguinte, via `flushPendingNotices()`.

**Alternativas descartadas.** (a) Creditar assim que a condição fosse verdadeira
durante o dia: o tempo de tela começa em zero, então o bônus cairia todo dia de
manhã e não significaria nada. (b) Creditar durante o dia e estornar se o uso
passasse da meta: proibido pelo §1 do contrato — o usuário nunca perde nada.

**Consequências.** O bônus chega no dia seguinte, o que dá ao relatório da noite
um motivo para existir. Dias de ausência longa não pagam: só o primeiro
`_advanceDay` de um avanço recebe `creditBonus`, porque os seguintes têm `usage`
sintético em zero e pagar por eles seria inventar medição. Sem permissão de uso
não há bônus — não há o que medir, e o app não finge. Reverter: remover a
chamada em `_advanceDay`.

Nota relacionada: o "+10" da quest de sessão **não** é um crédito separado — é a
recompensa da própria sessão de 25 min. Pagar de novo seria duplicar.

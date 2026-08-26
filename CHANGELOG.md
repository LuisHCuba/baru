# Changelog

Formato: entradas por data, agrupadas em Adicionado / Corrigido / Alterado /
Removido. Datas em AAAA-MM-DD.

## 2026-08-26 — turno noturno

### Adicionado
- Controle de versão: repositório git na raiz, branch `night/2026-08-26`,
  remote `LuisHCuba/baru` (ADR-001).
- `.gitattributes` normalizando fim de linha.
- Documentação viva: `README.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`,
  `docs/DATA_MODEL.md`, `docs/DECISIONS.md`, `docs/BACKLOG.md`,
  `docs/BLOCKERS.md`, `docs/STATE.md` e este arquivo.

### Corrigido
- `.gitignore` do app deixava `android/build/` e `**/.cxx/` entrarem no
  versionamento.

### Removido
- E-mail pessoal da conta de teste em `supabase/README.md` — o repositório
  remoto é público (ADR-004).

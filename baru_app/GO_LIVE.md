# Baru — Go-Live / quality gate

“Goignate” não é um produto (busca no repo e no Notion não achou ferramenta/board). Este arquivo é o **Going Live / quality gate** do app.

Espelho no Notion: [Baru — Go-Live / qualidade](https://app.notion.com/p/3c8c3598383a813fa57adfb328cabc6e)

Fonte de verdade de UI: `../Baru App v2.dc.html`. Conceito: **habitat, não timer**.

> Este arquivo é o gate da **fase 1**. O retrato do agora, com os portões
> executados e a fila do próximo turno, está em [`../docs/STATE.md`](../docs/STATE.md).

## Fidelidade ao design

- [x] 8 telas (onboarding, habitat, sessão, resultado, relatório, loja, ajustes, paywall)
- [x] Copy pt / en / es / zh — sem string fixa de UI
- [x] Precedência do humor (`missing_you` > `radiant` > `content` > `neutral` > `sleepy`)
- [x] Quiz de 3 perguntas → capivara / lontra / tartaruga / coruja
- [x] Loja v1: 8 itens, 40–400 folhas, posições fixas
- [x] Paywall anual/mensal + trial local (sem Store IAP)
- [x] Onboarding: idioma primeiro, 6 passos, habitat vazio no 1º dia
- [x] Meta −25% da média, arredondada em 15 min
- [x] Freeze semanal; AppFrame 412×892 no desktop
- [x] Privacidade e Termos abrem texto (não são no-op)
- [x] Overflow e a11y no frame 412 px (header, loja, paywall, onboarding, ajustes)

## Qualidade

- [x] `flutter analyze` limpo (26/08/2026)
- [x] `flutter test` 151 passando + 1 pulado (26/08/2026, turno noturno)
- [x] Suíte de integração contra Supabase real, 5/5 (`test/integration`)
- [x] Migrations aplicam do zero em banco limpo (`supabase db reset`)
- [x] Auditoria 8 telas (412×892, overflow, semantics; agente ea248b9e)
- [x] Testes de estado + telas (`test/state_test.dart`, `test/quality_test.dart`)
- [x] Semantics em botões, tabs e toggles
- [x] Overflow no Chrome 412 px (header flex, loja ellipsis, paywall Wrap, ajustes Row)

## Produto

- [x] Share do habitat (screenshot + fallback texto)
- [x] Persistência local
- [x] Debug vs primeiro dia vazio (`startCompanionship` zera; `resetAll` só no debug)
- [x] Feedback se o share falhar (SnackBar)
- [x] Plural de streak / freeze

- [x] Perfil editável nos ajustes (CompanionCard: nome, pelagem, espécie)
- [x] Toggle permissão de uso nos ajustes (toggleUsageAccess)
- [x] Perfil/ajustes → persistência local + sync remoto (baru_pets, baru_settings) via repositórios

## Supabase

Migrations locais em `supabase/migrations/` — **você aplica o SQL** (agente não aplica remoto).

### Ordem (5 arquivos)

| # | Arquivo | O que faz |
|---|---|---|
| 1 | `20260826190000_create_baru_tables.sql` | `baru_profiles` (monolítico) + `baru_sessions` |
| 2 | `20260826190001_baru_rls.sql` | RLS base (`auth.uid() = user_id`) |
| 3 | `20260826200000_baru_domain_tables.sql` | 11 tabelas de domínio normalizadas |
| 4 | `20260826200001_baru_domain_rls.sql` | RLS das novas tabelas |
| 5 | `20260826200002_baru_migrate_and_slim_profiles.sql` | Migra legado → domínio; slim `baru_profiles` |

### Como aplicar

Na raiz do app (`baru_app/`), com Supabase CLI linkado ao projeto:

```bash
supabase db push
```

Ou pelo Dashboard → SQL Editor, executando cada arquivo na ordem acima.

### Auth (feito no app)

- [x] `AuthGate` + `AuthScreen` (login / criar conta)
- [x] `signInWithPassword` / `signUp` / `signOut` — **sem auth anônimo**
- [x] Logout em Ajustes (`canSignOut`)
- [x] Pós-login: limpa snapshot local → pull remoto → onboarding vazio se conta nova
- [x] Sync push debounced por domínio; falha remota não apaga local

Dashboard → **Authentication → Providers → Email → ON** (desative “Confirm email” em dev, se quiser).

Nunca `service_role` no Flutter. Detalhes das 13 tabelas: `supabase/README.md`.

**Projeto remoto:** `baru` · ref `slqpuppkapiewjqvedtj` · sa-east-1

### Pendente (você — remoto)

- [ ] Confirmar `.env` aponta para o projeto `slqpuppkapiewjqvedtj` (ref canônico no repo)
- [ ] Aplicar as 5 migrations no projeto Supabase (se ainda não aplicadas)
- [ ] Habilitar provider **Email** no Dashboard
- [ ] Criar conta de teste no app e rodar `supabase/seed.sql` (SQL Editor)

## Fora desta fase

- [x] Permissão nativa de uso implementada no Android (`usage_stats` + `PACKAGE_USAGE_STATS`); **não verificada em aparelho** neste turno. iOS depende de entitlement (BL-06)
- [ ] Store IAP
- [ ] Arte Rive original

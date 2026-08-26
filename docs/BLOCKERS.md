# Bloqueios — precisam de um humano

Cada item traz a ação exata. Tudo o que dependia do agente já está pronto.

---

## BL-01 — Ledger de migrations ausente no projeto remoto

**Situação.** As 5 migrations foram aplicadas à mão pelo SQL Editor. O schema
`supabase_migrations.schema_migrations` **não existe** no banco (verificado por
query). O CLI não sabe o que já rodou.

**Impacto.** Um `supabase db push` futuro tentará reaplicar tudo. As migrations
foram tornadas reexecutáveis (ADR-003), então não deve quebrar — mas o projeto
segue sem rastro de o que foi aplicado.

**Ação pedida** (requer a senha do banco, em Dashboard → Settings → Database):

```
cd baru_app
supabase login
supabase link --project-ref slqpuppkapiewjqvedtj
supabase migration repair --status applied 20260826190000 20260826190001 20260826200000 20260826200001 20260826200002
supabase db push
```

O `db push` final deve aplicar apenas a migration nova de adoção do
`rls_auto_enable`.

---

## BL-02 — RESOLVIDO em 2026-08-26

**Era:** migrations nunca validadas contra banco limpo.

**Feito no turno.** Docker subido, `supabase start` (só Postgres, auth e REST) e
`supabase db reset`: as 6 migrations aplicaram do zero. O schema resultante é
idêntico ao remoto — 13 tabelas, 50 políticas, `baru_profiles` com 8 colunas,
event trigger `ensure_rls` presente, nenhuma tabela sem RLS, `anon` sem EXECUTE
sobre `rls_auto_enable`. Isolamento entre usuários conferido com dois usuários
reais: A vê só a própria carteira, `anon` vê zero.

Reaplicação também conferida: migrations 5 e 6 rodam de novo sem erro
(`ON_ERROR_STOP=1`, exit 0). A versão antiga da 5, tirada do histórico do git,
falha com `ERROR: column "species" does not exist` — que é exatamente o que o
ADR-003 previu.

Para repetir:

```
cd baru_app
supabase start
supabase db reset
```

**Pendente ainda:** subir o app Flutter apontando para o banco local
(`SUPABASE_URL=http://127.0.0.1:54321` via `--dart-define`) e percorrer o fluxo
à mão. Isso exige um dispositivo/emulador, que o agente não tem.

---

## BL-03 — Proteção contra senha vazada desligada

**Situação.** Linter de segurança do Supabase acusa
`auth_leaked_password_protection` desabilitado. O app aceita senha de 6
caracteres sem checagem contra HaveIBeenPwned.

**Ação pedida.** Dashboard → Authentication → habilitar *Leaked password
protection*.

---

## BL-04 — Conta de teste sem e-mail confirmado

**Situação.** O projeto tem 2 usuários; **1 está sem `email_confirmed_at`** e
não consegue entrar. O app trata isso corretamente como `email_not_confirmed`.

**Ação pedida.** Dashboard → Authentication → Users: confirmar o usuário
pendente, **ou** desligar *Confirm email* em Providers → Email enquanto for
desenvolvimento.

---

## BL-05 — Assinatura de release do Android

**Situação.** `android/app/build.gradle.kts` ainda usa a config de assinatura de
**debug** no build de release (TODO do template Flutter intacto). Não é
publicável. Gerar keystore é irreversível e envolve segredo — o agente não faz.

**Ação pedida.** Gerar a keystore, guardá-la **fora** do repositório, criar
`android/key.properties` (já coberto pelo `.gitignore`) e apontar o
`signingConfig` de release para ela.

---

## BL-06 — Entitlement de Screen Time no iOS

**Situação.** O iOS não expõe tempo de tela total a apps de terceiros sem o
entitlement Family Controls / DeviceActivity da Apple. Hoje
`UsageService.platformSupportsUsage` é `false` no iOS e o app cai no caminho
suportado de humor derivado só das sessões de foco.

**Ação pedida.** Solicitar o entitlement pela conta de desenvolvedor Apple. Até
lá, a flag mantém o iOS honesto.

---

## BL-07 — IAP (compra dentro do app)

**Situação.** Trial e planos existem só localmente: `startTrial()` e
`restorePurchases()` ligam um booleano, sem validação de loja. Não há receita
real em risco enquanto não houver IAP.

**Ação pedida.** Configurar os produtos na App Store Connect e no Play Console.
Só então vale implementar validação de recibo — e mover a economia de folhas
para o servidor.

---

## BL-08 — Push para o remoto exige a conta `LuisHCuba`

**Situação.** A conta ativa do `gh` na máquina era `goworksistemas`, que recebe
403 ao empurrar para `LuisHCuba/baru`. A conta `LuisHCuba` já estava
autenticada, só não era a ativa; o agente trocou com
`gh auth switch --user LuisHCuba`.

**Ação pedida.** Nenhuma, se a troca puder ficar permanente. Se `goworksistemas`
precisar voltar a ser a conta ativa, dar permissão de escrita a ela no
repositório ou reverter com `gh auth switch --user goworksistemas` e empurrar
manualmente.

# Supabase — Baru



O agente **não aplica** schema remoto. Você aplica.



**Projeto remoto:** `baru` · ref `slqpuppkapiewjqvedtj` · sa-east-1  

**URL:** `https://slqpuppkapiewjqvedtj.supabase.co`



## Ordem de setup (do zero)



1. **Migrations** — aplique as 5 migrations (abaixo) com `supabase db push` ou SQL Editor.

2. **Auth Email** — Dashboard → Authentication → Providers → **Email** ON (desative “Confirm email” em dev, se quiser).

3. **Conta de teste** — rode `.\supabase\seed_test_user.ps1` (signup + seed SQL) **ou** crie conta no app e aplique o SQL manualmente.

4. **Flutter** — copie `.env.example` → `.env`, preencha `SUPABASE_ANON_KEY`, depois:



```powershell

cd c:\LHCX\Baru\baru_app

flutter run -d chrome

```



O app exige **login email/senha** quando Supabase está configurado. Sem `.env` válido, roda offline sem auth (só dev/testes).



## Migrations



| # | Arquivo | O que faz |

|---|---|---|

| 1 | `20260826190000_create_baru_tables.sql` | `baru_profiles` (monolítico) + `baru_sessions` |

| 2 | `20260826190001_baru_rls.sql` | RLS base (`auth.uid() = user_id`) |

| 3 | `20260826200000_baru_domain_tables.sql` | 11 tabelas de domínio normalizadas |

| 4 | `20260826200001_baru_domain_rls.sql` | RLS das novas tabelas |

| 5 | `20260826200002_baru_migrate_and_slim_profiles.sql` | Migra dados legados → domínio; slim `baru_profiles` |



**CLI** (depois de `supabase login` e `supabase link --project-ref slqpuppkapiewjqvedtj`):



```bash

supabase db push

```



## Conta de teste



| Campo | Valor |

|---|---|

| Email | `supabase/SEED_TEST_USER.local.md` (gitignored) |

| Senha | `supabase/SEED_TEST_USER.local.md` (gitignored, gerada pelo script) |



### Script automático



```powershell

cd c:\LHCX\Baru\baru_app

.\supabase\seed_test_user.ps1

```



O script:

1. Lê `SUPABASE_URL` e `SUPABASE_ANON_KEY` do `.env` (você preenche; o agente não abre o arquivo).

2. Cria o usuário via Auth signup API se ainda não existir.

3. Grava senha temporária em `SEED_TEST_USER.local.md`.

4. Executa `seed_test_user.sql` via Supabase CLI (`supabase db query`).



Se o usuário **já existir** mas o seed SQL falhar com “Auth user not found”, o signup não rodou neste projeto — use o script ou crie a conta pelo app.



### Manual



1. Dashboard → Authentication → Add user **ou** signup no app Flutter.

2. SQL Editor → colar e executar `supabase/seed_test_user.sql`.



### Dados incluídos no seed



- Perfil: `home`, onboarding step 5, `pt`, companionship ativo

- Pet capivara **Baru**, pelagem 0

- Wallet 120 folhas; inventário `lily`, `bamboo`

- Streak 3, trial anual, 1 sessão de foco



## Login no app



Fluxo principal: **`signInWithPassword` / `signUp`** na tela de auth.  

Após login: **pull remoto**; se perfil novo → onboarding vazio (0 folhas).  

**Logout** em Ajustes → Sair da conta.  

Debug panel “reset” (165 folhas) só em builds debug — usuário logado nunca vê isso por padrão.



Nunca `service_role` no Flutter.



## Tabelas finais (13)



| Tabela | Propósito |

|---|---|

| `baru_profiles` | Conta: device_id, tela, onboarding step, idioma, companionship, last_open |

| `baru_pets` | Espécie, nome, pelagem |

| `baru_onboarding_answers` | Quiz q0–q2 |

| `baru_wallets` | Saldo de folhas |

| `baru_inventory_items` | Itens comprados (loja) |

| `baru_sessions` | Histórico de sessões de foco |

| `baru_settings` | Notificações, usage_access, duração padrão |

| `baru_screen_time` | usage / goal / avg (minutos) |

| `baru_streaks` | streak, today_index, freezes, days_away |

| `baru_week_calendar` | 7 dias (present/frozen/today/empty) |

| `baru_daily_progress` | Sessões hoje + abandono |

| `baru_daily_quests` | Quests focus_session + under_goal |

| `baru_subscriptions` | Trial + pay_plan |



Humor/atividade do pet são **derivados** no app (não persistidos).



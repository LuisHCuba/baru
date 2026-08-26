# Arquitetura — Baru

Estado deste documento: reflete o código em `baru_app/lib/` no commit atual.

## Stack real

| Camada | Escolha |
|---|---|
| Framework | Flutter 3.35.2 (stable), Dart SDK `^3.9.0` |
| Estado | `ChangeNotifier` (`AppState`) exposto por `InheritedNotifier` (`AppScope`) |
| Navegação | Máquina de estados por `enum AppScreen` — **sem `Navigator`/rotas** |
| i18n | Catálogo Dart em `lib/l10n.dart` (sem `intl`/`arb`) |
| Persistência local | `shared_preferences`, um JSON único (`baru_snapshot_v1`) |
| Backend | Supabase (Postgres + Auth email/senha), 13 tabelas com RLS |
| Tipografia | `google_fonts` (Nunito, baixada em runtime — ver dívida abaixo) |
| Notificações | `flutter_local_notifications` + `timezone` + `flutter_timezone` |
| Tempo de tela | `usage_stats` (Android), stub em web/iOS |

## Fluxo de dados

```
main()
 ├─ BaruEnv.load()            .env.example <- .env <- --dart-define
 ├─ BaruRepositories.local()  SharedPreferences
 ├─ BaruSupabase.attach()     Supabase.initialize (se credenciais válidas)
 └─ AuthGate
      ├─ sem Supabase  -> carrega snapshot local -> BaruApp (offline, sem login)
      └─ com Supabase  -> exige sessão email/senha
             ├─ sem sessão  -> AuthScreen
             └─ com sessão  -> pull remoto -> salva local -> BaruApp
                                    └─ perfil inexistente = conta nova (onboarding vazio)

BaruApp
 └─ AppState (ChangeNotifier)
      ├─ notifyListeners() -> _schedulePersist() (debounce 280 ms)
      │      └─ _persistNow(): salva snapshot local, depois empurra
      │         os domínios marcados em _syncMask para o Supabase
      └─ _Shell: switch(screen) -> uma das 8 telas
```

### Regra central: o snapshot é a unidade de verdade local

`AppSnapshot` (`lib/data/app_snapshot.dart`) é o estado inteiro serializável.
`AppState.toSnapshot()` / `_applySnapshot()` fazem a ponte. O store local grava
esse JSON inteiro; o remoto o **decompõe** em 13 tabelas via `BaruRowCodec`
(`lib/data/row_codec.dart`) e o recompõe no pull.

Consequência intencional: a fonte de verdade offline é única e atômica; o banco
é normalizado para consulta e evolução. Consequência aceita: um push toca
várias tabelas.

### Máscara de sincronização

`AppState._syncMask` marca quais domínios mudaram (`pet`, `shop`, `session`,
`settings`, `trial`). `_persistNow()` empurra só os marcados. Máscara zerada
significa "origem desconhecida" e dispara push completo.

## Camadas

```
lib/
├── main.dart              bootstrap (env, repos, supabase, timezone)
├── auth_gate.dart         porteiro: sessão -> bootstrap -> app
├── app.dart               MaterialApp, AppScope, shell de 8 telas, snackbars
├── state.dart             AppState: TODA a lógica de domínio
├── models.dart            enums, tabelas do design (loja, quiz, durações), fórmulas puras
├── l10n.dart              T + catálogo pt/en/es/zh
├── theme.dart             cores, raios, sombras, TextTheme
├── data/
│   ├── app_snapshot.dart  estado serializável + SessionRecord
│   ├── local_store.dart   SnapshotStore: Prefs e Memory
│   ├── repositories.dart  fachada por domínio sobre o mesmo store
│   ├── supabase_gateway.dart  auth + push/pull por domínio
│   ├── row_codec.dart     AppSnapshot <-> linhas das 13 tabelas
│   ├── baru_env.dart      SUPABASE_URL / ANON_KEY / ENABLED
│   ├── auth_errors.dart   erro do Supabase -> mensagem nos 4 idiomas
│   └── remote_result.dart resultado de pull/push
├── screens/               8 telas, todas StatelessWidget lendo AppScope
├── widgets/               design system + habitat + pet (CustomPainter)
├── services/              notificações e tempo de tela (com stub para web)
└── share/                 captura do habitat em PNG + share_plus
```

**Regra de dependência:** `screens/` e `widgets/` só leem `AppState`; nenhuma
tela fala com Supabase ou com o store diretamente.

## Renderização do pet e do habitat

Sem Rive e sem assets de imagem: `PetView` e `HabitatScene` são `CustomPainter`
e `Positioned` calculados a partir de `ShapePart` em `models.dart`, escalados
sobre o frame de design 372×296. Trocar por arte real é substituir esses dois
widgets, não o estado.

## Feature flags e ambientes

| Flag | Onde | Efeito |
|---|---|---|
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | `.env` ou `--dart-define` | credenciais; ausentes = app offline sem login |
| `SUPABASE_ENABLED=false` | `--dart-define` **apenas** | desliga o backend mesmo com credenciais |
| `AppState.debugFast` | runtime, default `kDebugMode` | timer 60× |
| `DebugFab` / `DebugPanel` | `kDebugMode` | painel de debug |
| `UsageService.platformSupportsUsage` | plataforma | Android `true`, iOS/web `false` |

## Cliente vs. servidor

Tudo roda no cliente. Não há Edge Function, trigger de negócio nem RPC: o
Postgres guarda e isola (RLS), não decide. Consequência: a economia de folhas é
autoritativa no dispositivo. Aceitável enquanto não há IAP nem ranking; vira
problema no dia em que houver valor real em jogo (ver BACKLOG).

## Dívidas arquiteturais conhecidas

- **Camada de repositório meio morta.** `pullRemote()`, `saveLocal()`,
  `appendLocal()` e `saveOwnedLocal()` dos 5 repositórios nunca são chamados;
  só `pushRemote()` é. Os 5 compartilham o mesmo `SnapshotStore`.
- **`AppState` com 800+ linhas** acumula domínio, plataforma e persistência.
- **Fontes em runtime.** `google_fonts` baixa Nunito na primeira execução: um
  app offline-first que depende de rede para a tipografia.
- **Sem servidor autoritativo** para economia e trial.

# Baru — Focus Capybara

App mobile (iOS + Android) de redução de tempo de tela e foco. Você ganha
sessões de foco; o habitat de um animal de estimação reage ao seu
comportamento. Sem punição, sem culpa: o bicho nunca morre nem perde nada.

Conceito: **habitat, não timer**.

> Estado atual: MVP funcional em 4 idiomas com backend Supabase ligado.
> Ainda **não publicável** — ver [docs/BLOCKERS.md](docs/BLOCKERS.md).
> Retrato do agora: [docs/STATE.md](docs/STATE.md).

## Stack

- **Flutter 3.35.2** (stable) · Dart SDK `^3.9.0`
- Estado: `ChangeNotifier` + `InheritedNotifier` (sem Provider/Riverpod/Bloc)
- Backend: **Supabase** — Postgres 17, Auth email/senha, 13 tabelas com RLS
- Persistência local: `shared_preferences` (um snapshot JSON)
- i18n próprio em `lib/l10n.dart` — pt, en, es, zh
- Notificações locais, tempo de tela via `usage_stats` (Android)

Detalhe das camadas: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Pré-requisitos

| Ferramenta | Versão usada |
|---|---|
| Flutter | 3.35.2 stable |
| Android SDK | via Android Studio; JDK 17 |
| Xcode | só para build iOS |
| Supabase CLI | 2.x (opcional, para migrations) |
| Docker | opcional, para Supabase local |

## Setup do zero

```
git clone https://github.com/LuisHCuba/baru.git
cd baru/baru_app
flutter pub get
```

### 1. Variáveis de ambiente

O app lê credenciais em runtime, nesta precedência:
`--dart-define` > `.env` > `.env.example`.

```
cp .env.example .env
```

Preencha `SUPABASE_ANON_KEY` com a chave **publishable/anon** do projeto
(Dashboard → Settings → API). Nunca a `service_role`.

`.env` é gitignored **e** está declarado como asset no `pubspec.yaml`: sem o
arquivo o build falha. Se quiser rodar sem backend, deixe a chave como
`your-anon-key` — o app entra em modo offline, sem tela de login.

Variáveis reconhecidas:

| Chave | Onde funciona | Efeito |
|---|---|---|
| `SUPABASE_URL` | `.env` ou `--dart-define` | URL do projeto |
| `SUPABASE_ANON_KEY` | `.env` ou `--dart-define` | chave publishable |
| `SUPABASE_ENABLED=false` | `.env` ou `--dart-define` | desliga o backend mesmo com credenciais; o dart-define tem precedência |

### 2. Banco

As migrations vivem em `baru_app/supabase/migrations/` e são aplicadas por você
— o agente não aplica schema em projeto remoto.

```
cd baru_app
supabase link --project-ref <ref-do-projeto>
supabase db push
```

Ou cole cada arquivo no SQL Editor, **na ordem do nome**. Depois: Dashboard →
Authentication → Providers → **Email** ligado.

Schema comentado e políticas RLS: [docs/DATA_MODEL.md](docs/DATA_MODEL.md).

### 3. Rodar

```
flutter run                    # dispositivo/emulador conectado
flutter run -d chrome          # web (sem tempo de tela nem notificações)
flutter run --release
```

Sem backend configurado o app abre direto no onboarding. Com backend, exige
login por e-mail e senha.

## Testes e verificação

```
cd baru_app
flutter analyze                # análise estática
flutter test                   # suíte completa
flutter test test/mood_test.dart
```

Há também uma suíte de integração que roda contra um Supabase de verdade —
escreve as 13 tabelas com o token de um usuário comum e reconstrói o snapshot
pela leitura, exercitando schema, CHECKs, RLS e o codec nas duas direções.
Precisa de Docker:

```
cd baru_app
supabase start
supabase db reset
flutter test test/integration ^
  --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 ^
  --dart-define=BARU_TEST_KEY=<publishable key que o supabase start imprime>

# numa linha só, se preferir:
flutter test test/integration --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 --dart-define=BARU_TEST_KEY=<chave>
```

Sem essas variáveis os casos se pulam sozinhos: a suíte normal não depende de
Docker.

Todo item só é considerado pronto com analyze limpo e testes verdes — ver a
definição de pronto em [docs/BACKLOG.md](docs/BACKLOG.md).

## Estrutura

```
baru/
├── Baru App v2.dc.html      fonte de verdade de UI (protótipo, 8 telas)
├── docs/                    documentação viva (ver abaixo)
└── baru_app/                o app Flutter
    ├── lib/
    │   ├── main.dart        bootstrap
    │   ├── auth_gate.dart   sessão -> bootstrap -> app
    │   ├── app.dart         MaterialApp + shell das 8 telas
    │   ├── state.dart       AppState: toda a lógica de domínio
    │   ├── models.dart      enums, tabelas do design, fórmulas puras
    │   ├── l10n.dart        catálogo pt/en/es/zh
    │   ├── theme.dart       cores, raios, sombras
    │   ├── data/            snapshot, store local, repositórios, Supabase
    │   ├── screens/         8 telas
    │   ├── widgets/         design system, habitat, pet
    │   ├── services/        notificações, tempo de tela
    │   └── share/           captura do habitat em PNG
    ├── test/
    └── supabase/migrations/ SQL versionado
```

## Documentação

| Documento | Para quê |
|---|---|
| [docs/STATE.md](docs/STATE.md) | retrato do agora — **comece por aqui** |
| [docs/PRODUCT.md](docs/PRODUCT.md) | regras de produto (fonte de verdade) |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | camadas, fluxo de dados, flags |
| [docs/DATA_MODEL.md](docs/DATA_MODEL.md) | schema e RLS comentados |
| [docs/DECISIONS.md](docs/DECISIONS.md) | ADRs |
| [docs/BACKLOG.md](docs/BACKLOG.md) | fila priorizada |
| [docs/BLOCKERS.md](docs/BLOCKERS.md) | o que só um humano destrava |
| [CHANGELOG.md](CHANGELOG.md) | histórico por data |
| [baru_app/GO_LIVE.md](baru_app/GO_LIVE.md) | checklist de qualidade da fase 1 |

## Licença

Projeto privado. Sem licença de distribuição definida.

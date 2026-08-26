# Estado — 2026-08-26, fim do turno noturno

Branch: `night/2026-08-26`, integrada em `main` | Build: **verde**

Portões, com resultado de execução real:

| Portão | Resultado |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 151 passando, 1 pulado (integração) |
| `flutter test test/integration` (stack local) | 5/5 |
| `supabase db reset` em banco limpo | 6 migrations aplicadas |

## Pronto e funcionando

- MVP das 8 telas em pt/en/es/zh com backend Supabase.
- **Sessão de foco sobrevive a background e a kill** — era o caminho core mais
  frágil do app. Relógio de parede, sessão persistida, retomada ao abrir.
- **Bônus de +15 por fechar abaixo da meta** existe de fato; antes a UI
  prometia e nada creditava.
- **Aviso de 24h antes do fim do trial** agendado; antes só a copy prometia.
- i18n consistente nos 4 idiomas, travado por teste de paridade. As 5 chaves
  que só existiam em pt derrubavam o app em en/es/zh.
- Calendário derivado da data: a semana zera na virada, `todayIndex` não
  desanda, `daysAway` é fato de data.
- Sincronização que não perde intenção: falha por domínio volta para a fila.
- Schema reproduzível a partir do repositório e validado em banco limpo.
- Projeto sob git com histórico, remote e documentação viva.

## Em andamento

Nada pela metade. Todos os ciclos do turno fecharam com portões verdes.

**Próximo passo exato:** B-15 — assinatura de release do Android. O lado do
agente é preparar o `signingConfig` lendo `android/key.properties`; a keystore
em si é do humano (BL-05).

## Próximos 5 itens da fila

1. B-15 — assinatura de release do Android (bloqueia publicação).
2. B-14 — Nunito empacotada: hoje um app offline-first baixa a própria fonte.
3. B-22 — fuso horário e virada de dia.
4. B-23 — `textScaler` travado em 1.25× (acessibilidade).
5. B-19 — chip "Livre" promete escolha e entrega 45 min fixos.

## Riscos e dívidas conhecidas

- **Economia autoritativa no cliente.** Sem valor real em jogo hoje; vira
  problema no dia do IAP (B-26).
- **Sem ledger de migrations no remoto** (BL-01): `supabase db push` tentaria
  reaplicar tudo. As migrations agora aguentam, mas o rastro não existe.
- **`AppState` com mais de 900 linhas** concentra domínio, plataforma e
  persistência (B-27).
- **Camada de repositório meio morta**: `pullRemote`, `saveLocal`,
  `appendLocal`, `saveOwnedLocal` nunca são chamados.
- **`_legacyId` colidível entre usuários** (B-24) — teórico, análise no backlog.
- **Nada foi aplicado no Supabase remoto.** As migrations novas existem no
  repositório e foram validadas localmente; aplicar é do humano.

## Bloqueios para o humano

| # | O quê |
|---|---|
| BL-01 | Ledger de migrations ausente no projeto remoto |
| BL-03 | Proteção contra senha vazada desligada no Dashboard |
| BL-04 | Um dos dois usuários de teste está sem e-mail confirmado |
| BL-05 | Keystore de release do Android |
| BL-06 | Entitlement de Screen Time no iOS |
| BL-07 | Produtos de IAP nas lojas |
| BL-08 | Conta do `gh` com permissão de push (contornado no turno) |

BL-02 (validar migrations em banco limpo) foi **resolvido** no turno.
Detalhes em [BLOCKERS.md](BLOCKERS.md).

## Comandos para rodar e validar agora

```
cd baru_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Integração (precisa de Docker):

```
supabase start
supabase db reset
flutter test test/integration \
  --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 \
  --dart-define=BARU_TEST_KEY=<publishable key que o supabase start imprime>
```

# Backlog — Baru

Priorizado pela função objetivo do §3 do mandato: nada quebrado → segurança e
integridade de dados → fluxo core end-to-end → corretude das regras de produto →
cobertura de teste → robustez → performance → polimento → features novas.

Legenda de esforço: **P** ≤30 min · **M** 30–90 min · **G** > 90 min (quebrar).

---

## Fila — próximo turno, em ordem

| # | Item | Valor | Esforço | Risco | Pronto quando |
|---|---|---|---|---|---|
| B-15 | Assinatura de release do Android | **Bloqueia publicação** | M | Alto | Keystore fora do repo, `key.properties`, build release assinado. Depende do humano: ver BL-05 |
| B-14 | Nunito empacotada no app | Alto — app offline-first que depende de rede para a própria tipografia, e faz request ao Google no primeiro launch | M | Baixo | `.ttf` no `pubspec`; `GoogleFonts` só como fallback; primeiro launch sem rede com a fonte certa |
| B-22 | Fuso horário e virada de dia | Médio — `DateTime.now()` local, sem tratamento de mudança de fuso ou horário de verão | M | Médio | Virada de dia correta ao cruzar fuso; teste com fuso fixo |
| B-23 | `textScaler` limitado a 1.25× | Médio — acessibilidade travada por fidelidade ao design | M | Médio | Fontes grandes sem overflow nas 8 telas, ou o limite justificado em ADR |
| B-19 | Chip "Livre" abre duração customizada | Médio — o rótulo promete escolha e entrega 45 min fixos | M | Baixo | Seletor real, ou rótulo honesto |
| B-25 | Relatório do dia é sempre "hoje" | Médio — `repDate` usa `DateTime.now()`, mas o relatório da noite chega às 21h e pode ser aberto no dia seguinte | P | Baixo | A data do relatório é a do dado que ele mostra |
| B-24 | `SessionRecord._legacyId` é colidível entre usuários | Baixo — teórico | P | Baixo | Ver análise abaixo antes de mexer |
| B-26 | Economia autoritativa no servidor | Baixo hoje, **crítico no dia do IAP** | G | Alto | Folhas e trial validados fora do dispositivo |
| B-27 | `AppState` com mais de 900 linhas | Baixo — dívida de forma, não de comportamento | G | Médio | Domínio, plataforma e persistência separados, sem mudar comportamento |

### Nota sobre B-24

`SessionRecord.fromJson` gera um uuid v5 determinístico a partir de
`(data, duração, recompensa, concluída)` quando o registro não tem id — o que
só acontece em snapshots gravados antes de o campo existir. Como
`baru_sessions.id` é chave primária **global**, dois usuários com o mesmo id
colidem: o upsert do segundo bate na policy de UPDATE do primeiro e volta 403.

Descoberto pelo teste de integração, que reproduzia o cenário por usar ids
fixos entre casos. Na prática exige dois usuários com sessão no mesmo
microssegundo, mesma duração, mesma recompensa e mesmo resultado — e o app
ainda não foi publicado, então snapshots legados basicamente não existem.
Trocar por v4 resolveria a colisão mas quebraria a estabilidade do id entre
duas leituras do mesmo JSON, criando linhas duplicadas no remoto. Deixado
documentado de propósito: a correção certa é dar escopo de usuário ao id, e
isso é migração numa tabela com dados.

## Fora do MVP — não começar antes do core

- IAP real (App Store / Play Billing) sobre `baru_subscriptions`.
- iOS Screen Time via Family Controls (depende de entitlement — ver BL-06).
- Arte Rive no lugar dos `CustomPainter`.
- Tela de histórico de foco. **Descartada por ora**: a tela de relatório do
  design tem exatamente as chaves já implementadas (`repUsed`, `repGoal`,
  `repSessions`, `repBonus`, `repPresent`, `repFreeze`), sem histórico nem
  gráfico. As 80 sessões guardadas existem para o registro remoto e para quando
  o produto pedir a tela — construir agora seria feature fora do MVP.

---

## Concluído no turno de 2026-08-26

| # | Item | Onde |
|---|---|---|
| B-01 | Documentação base | `docs/`, `README.md`, `CHANGELOG.md` |
| B-02 | Migrations reconciliadas com o banco real | ADR-002, ADR-003, migration 6 |
| B-03 | Crash de i18n em en/es/zh | `l10n.dart`, `test/l10n_test.dart` |
| B-04 | Bônus de +15 por fechar abaixo da meta | ADR-005, `test/economy_test.dart` |
| B-05 | Virada de semana e `todayIndex` | ADR-006, `test/calendar_test.dart` |
| B-06 | Máscara de sync não é mais perdida em falha | ADR-007, `test/sync_test.dart` |
| B-07 | Sessão sobrevive a background e kill | ADR-008, `test/session_test.dart` |
| B-08 | Aviso 24h antes do fim do trial | `notification_service.dart`, `test/trial_test.dart` |
| B-09 | Moldura de desktop fora do celular + retrato travado | `test/app_frame_test.dart` |
| B-10 | Login no idioma do usuário | `auth_gate.dart`, `test/auth_lang_test.dart` |
| B-11 | Push de sessões em lote | `supabase_gateway.dart` |
| B-12 | `acquired_at` preservado | `supabase_gateway.dart` |
| B-13 | Pull remoto em paralelo | `supabase_gateway.dart` |
| B-16 | Mudança efêmera não dispara push | `state.dart`, `test/sync_test.dart` |
| B-18 | `_ready` reage à expiração de sessão | `supabase_gateway.dart` |
| B-20 | Seed prometido passa a existir | `supabase/seed.sql` |
| B-21 | `SUPABASE_ENABLED` funciona pelo `.env` | `baru_env.dart` |
| — | Cobertura da tabela de humor, quiz e formatação | `test/mood_test.dart` |
| — | Round-trip real contra Supabase | `test/integration/` |

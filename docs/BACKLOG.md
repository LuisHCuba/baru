# Backlog — Baru

Priorizado pela função objetivo do §3 do mandato: nada quebrado → segurança e
integridade de dados → fluxo core end-to-end → corretude das regras de produto →
cobertura de teste → robustez → performance → polimento → features novas.

Legenda de esforço: **P** ≤30 min · **M** 30–90 min · **G** > 90 min (quebrar).

---

## Em execução neste turno

| # | Item | Valor | Esforço | Risco | Pronto quando |
|---|---|---|---|---|---|
| B-01 | Documentação base (§7) | Alto — sem ela nenhum turno é retomável | M | Baixo | README + 8 docs existem e refletem o código |
| B-02 | Reconciliar migrations × banco real | Crítico — schema irreprodutível | M | Médio | `rls_auto_enable` em migration; migration 5 reexecutável; `config.toml` no repo |
| B-03 | Crash de i18n em en/es/zh | Crítico — 3 de 4 idiomas quebram no handler de erro | P | Baixo | 5 chaves nos 4 catálogos + teste de paridade |
| B-04 | Bônus de +15 por fechar abaixo da meta | Alto — regra de produto §5 não implementada | M | Baixo | Credita uma vez por dia, com teste |
| B-05 | Virada de semana e `todayIndex` | Alto — relatório aponta o dia errado | M | Médio | Semana limpa na virada; `todayIndex` = weekday real; testes |
| B-06 | Máscara de sync não pode ser perdida | Alto — perda silenciosa de dado remoto | P | Baixo | Falha restaura a máscara; domínios isolados; teste |

## Fila (próximo turno, em ordem)

| # | Item | Valor | Esforço | Risco | Pronto quando |
|---|---|---|---|---|---|
| B-07 | Sessão sobrevive a background e kill | Crítico — caminho core do app de foco | G | Alto | Relógio de parede, sessão em curso persistida, retomada ao voltar; testes |
| B-08 | Aviso 24h antes do fim do trial | Alto — a copy promete (`payRemind`) | M | Baixo | Notificação agendada para `paidPlanStart - 24h`, cancelada ao sair do trial |
| B-09 | Travar retrato e corrigir AppFrame em landscape | Médio — moldura de desktop aparece no celular deitado | P | Baixo | Celular deitado não mostra bezel; teste de widget |
| B-10 | Login no idioma do usuário | Médio — §2 exige 4 idiomas de primeira classe | M | Baixo | AuthGate usa idioma salvo, senão locale do device |
| B-11 | Push de sessões em lote | Médio — até 80 round-trips por sync | P | Baixo | Um upsert com lista; delete da loja com filtro negativo |
| B-12 | Preservar `acquired_at` do inventário | Médio — apaga a data real de compra a cada push | P | Baixo | Push não regrava `acquired_at` de item existente |
| B-13 | Pull remoto em paralelo | Baixo — cerca de 11 queries sequenciais no login | P | Baixo | `Future.wait`; login mensuravelmente mais rápido |
| B-14 | Nunito empacotada no app | Médio — offline-first dependendo de rede para a fonte | M | Baixo | Fonte no pubspec; `GoogleFonts` só como fallback |
| B-15 | Assinatura de release do Android | Bloqueia publicação | M | Alto | Keystore fora do repo, `key.properties`, build release assinado (ver BL-05) |
| B-16 | Debug panel não pode sincronizar | Médio — `resetAll`/`setHabitat` empurram estado falso para a conta | P | Baixo | Ações de debug não disparam push remoto |
| B-17 | Relatório usa o histórico de sessões | Médio — 80 sessões guardadas e nunca lidas | M | Baixo | Relatório mostra série real, não só `completedToday` |
| B-18 | `_ready` do gateway reage à expiração de sessão | Médio — push tentado com sessão morta | P | Baixo | `onAuthStateChange` atualiza `_ready` |
| B-19 | Chip "Livre" abre duração customizada | Baixo — hoje é 45 min fixo com rótulo enganoso | M | Baixo | Seletor real ou rótulo honesto |
| B-20 | Scripts de seed citados e inexistentes | Baixo — README promete arquivos que não estão no repo | P | Baixo | Scripts existem ou as menções somem |
| B-21 | `SUPABASE_ENABLED` no `.env` é inerte | Baixo — só o `--dart-define` é lido | P | Baixo | `.env` respeitado ou `.env.example` corrigido |
| B-22 | Fuso horário e virada de dia | Médio — `DateTime.now()` local sem tratamento de mudança de fuso | M | Médio | Virada de dia correta ao cruzar fuso; teste |
| B-23 | `textScaler` limitado a 1.25× | Médio — acessibilidade | M | Médio | Fontes grandes sem overflow, ou limite justificado em ADR |

## Fora do MVP (não começar antes do core)

- IAP real (App Store / Play Billing) sobre `baru_subscriptions`.
- iOS Screen Time via Family Controls (depende de entitlement — ver BL-06).
- Arte Rive no lugar dos `CustomPainter`.
- Economia autoritativa no servidor.

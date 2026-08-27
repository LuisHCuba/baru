# Backlog — Baru

Priorizado pela função objetivo do mandato de produto: o app não mente → o app
é sentido → o app enriquece → nada quebrado → retomável.

Legenda de esforço: **P** ≤30 min · **M** 30–90 min · **G** > 90 min (quebrar).

---

## Pedido em 2026-08-27 e **não** entregue

Está aqui em vez de num commit porque cada um é trabalho nativo de verdade,
não um ajuste de tela. O que foi entregue no mesmo pedido: a correção da
perda de dado, o overlay sobre outros apps (Android nativo) e a tela de
permissão com pré-visualização.

| # | Item | Por que não saiu ainda |
|---|---|---|
| W-01 | **Widget de tela inicial** (Android AppWidget) | Precisa de `AppWidgetProvider`, `RemoteViews`, layouts XML e um provedor de dados que leia o snapshot fora do processo Flutter. É um turno inteiro sozinho. |
| W-02 | **Widget de tela de bloqueio** | No Android, widget de bloqueio só existe de novo no **Android 15+** (`WIDGET_CATEGORY_LOCK_SCREEN` voltou em preview); entre o 5 e o 14 a API não existe. No iOS seria WidgetKit, e o app ainda não tem alvo iOS configurado. **Prometer isso para "o celular" hoje seria mentira.** O que dá para fazer nesta faixa é a notificação persistente, que já existe. |
| W-03 | **Ícone do launcher** | O `ic_launcher` ainda é o padrão do Flutter. Fazer certo é gerar as densidades, o adaptativo (fore/background) e o monocromático do Android 13. |
| ~~W-04~~ | ~~As espécies do `baru-pets.html`~~ | **Feito em 2026-08-27.** Axolote, pinguim, gata e raposa — painter, paleta, nome em 4 idiomas, desbloqueio na trilha e migration 12. Baru, Rio, Tuca e Kiwi já eram a capivara, a lontra, a tartaruga e a coruja. |

---

## Fila — próximo turno, em ordem

| # | Item | Valor | Esforço | Risco | Pronto quando |
|---|---|---|---|---|---|
| C-01 | ~~Rotas de verdade e transições (§4B)~~ | **Feito em 2026-08-27** — `lib/navegacao.dart`, 17 testes | — | — | — |
| C-02 | Assinatura de release do Android | **Bloqueia publicação** | M | Alto | Keystore fora do repo, `key.properties`, build assinado (BL-05) |
| C-03 | Estágios de habitat visíveis | Alto — o dado existe e a cena ignora | M | Baixo | `estagioDoHabitat` muda a cena: mais vegetação, companheiros visitantes, água mais viva |
| C-04 | Lembretes com propósito (§6) | Alto — o app só fala quando a sessão roda | M | Baixo | Sequência em risco, missão quase concluída, marco ao alcance; cada um cancelado quando o motivo some; ajuste por categoria respeitado |
| C-05 | Onboarding e paywall no design system | Médio — são as duas telas com valores soltos | M | Baixo | Nenhum valor de cor, espaço ou raio fora dos tokens; transições entre passos |
| C-06 | Som | Médio — o §7 pede som curto na celebração | M | Médio | Conquista, resgate e fim de sessão com som; respeitando o modo silencioso |
| C-07 | Relatório usa o histórico de sessões | Médio — 80 sessões guardadas e nunca lidas | M | Baixo | Série real da semana no relatório |
| C-08 | Verificação em aparelho | **Alto** — nada deste turno rodou num telefone | M | — | Roteiro do BL-09 executado, mais as animações e a permissão de uso |
| C-09 | `textScaler` travado em 1.25× | Médio — acessibilidade | M | Médio | Fonte ampliada sem quebrar layout, ou o limite justificado em ADR |
| C-10 | Fuso horário e virada de dia | Médio | M | Médio | Virada correta ao cruzar fuso; teste com fuso fixo |
| C-11 | `AppState` com mais de 1200 linhas | Baixo — forma, não comportamento | G | Médio | Domínio, plataforma e persistência separados, sem mudar comportamento |
| C-12 | Economia autoritativa no servidor | Baixo hoje, **crítico no dia do IAP** | G | Alto | Folhas, XP e trial validados fora do dispositivo |
| C-13 | `SessionRecord._legacyId` colidível | Baixo — teórico | P | Baixo | Ver a análise antes de mexer (abaixo) |

### Nota sobre C-13

`SessionRecord.fromJson` gera um uuid v5 determinístico de
`(data, duração, recompensa, concluída)` quando o registro não tem id — só em
snapshots gravados antes de o campo existir. Como `baru_sessions.id` é chave
primária global, dois usuários com o mesmo id colidem e o upsert do segundo
volta 403. Exige dois usuários com sessão no mesmo microssegundo; o app não foi
publicado, então snapshots legados basicamente não existem. Trocar por v4
resolveria a colisão mas quebraria a estabilidade do id, duplicando linhas no
remoto. A correção certa é dar escopo de usuário ao id — migração em tabela com
dados.

## Fora do MVP

- IAP real (App Store / Play Billing) sobre `baru_subscriptions`.
- iOS Screen Time via Family Controls (entitlement — BL-06).
- Serviço em primeiro plano no Android / Live Activity no iOS (ADR-011
  explica por que o cronômetro do sistema cobre o caso principal).
- Arte Rive no lugar dos `CustomPainter`.

---

## Concluído no turno de 2026-08-27

| Fatia | Onde |
|---|---|
| Fundação: tokens, movimento e Nunito empacotada | `lib/design/`, `assets/fonts/` |
| Companheiro vivo e habitat com hora do dia | `pet.dart`, `habitat.dart`, `pet_vivo_test`, `habitat_vivo_test` |
| Tempo de tela verdadeiro + tela de detalhamento | `tempo_de_tela.dart`, `tempo_screen.dart`, ADR-009, migration 7 |
| Nível, XP e trilha de marcos | `progressao.dart`, `trilha_screen.dart`, `celebracao.dart` |
| Missões com anatomia completa que creditam | `missoes.dart`, `missoes_screen.dart`, ADR-010 |
| Notificação viva da sessão | `notification_service.dart`, ADR-011 |
| Home para de mentir sobre o nível | `home_screen.dart` |

## Concluído no turno de 2026-08-26

Documentação viva, migrations reconciliadas, crash de i18n em en/es/zh, bônus
da meta, calendário derivado da data, máscara de sync, sessão resiliente a
background e kill, aviso de trial, moldura em landscape, login no idioma do
usuário, push em lote, pull em paralelo, seed. Detalhe no CHANGELOG.

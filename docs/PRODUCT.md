# Baru — contrato de produto

Fonte de verdade das regras de produto. Mudança aqui exige ADR em
[DECISIONS.md](DECISIONS.md). Referência visual: `Baru App v2.dc.html` na raiz.

Baru é um app mobile (iOS + Android) de redução de tempo de tela e foco, com um
animal de estimação que reage ao comportamento do usuário. Tom: caloroso, sem
culpa, sem punição. Conceito: **habitat, não timer**.

## Regras invioláveis

### 1. Sem punição
O animal nunca morre, nunca perde nada, nunca culpa o usuário. Não existe
punição, decaimento de progresso, perda de moeda ou linguagem acusatória.
Abandonar uma sessão = sem recompensa, nada mais.

### 2. Quatro idiomas de primeira classe
`pt`, `en`, `es`, `zh`. A escolha de idioma é o primeiro passo do onboarding e
vive nos ajustes. Zero string fixa em componente — tudo via `lib/l10n.dart`.
Toda chave nova nasce nos 4 idiomas. Tradução incerta entra marcada `TODO-i18n`
e registrada no backlog, nunca omitida.

Travado por teste: `test/l10n_test.dart` (paridade de chaves entre catálogos).

### 3. Precedência de humor (ordem estrita)
`missing_you` > `radiant` > `content` > `neutral` > `sleepy`

| Humor | Condição |
|---|---|
| `missing_you` | abandonou sessão hoje **ou** ≥2 dias sem abrir |
| `radiant` | uso < meta **e** ≥1 sessão completa hoje |
| `content` | uso < meta **ou** ≥1 sessão completa |
| `neutral` | uso ≤ meta × 1,2 |
| `sleepy` | acima disso |

Sem permissão de uso concedida, o humor deriva só das sessões de foco
(`radiant` com ≥1 sessão, senão `content`) — recusar a permissão é caminho
suportado, não degradado.

A cena carrega o estado; a legenda diz em palavras.

Atividade derivada: `sleepy`/`neutral` → `nap`, `radiant` → `swim`,
`content` → `graze`, resto → `idle`.

### 4. Espécies
`capybara` (Baru), `otter` (Rio), `tortoise` (Toco), `owl` (Nina). Definidas por
quiz de 3 perguntas com pesos; trocáveis depois nos ajustes. Nome do pet é
editável (máx. 18 caracteres).

### 5. Economia — folhas

| Sessão | Recompensa |
|---|---|
| 25 min | 10 |
| 50 min | 25 |
| 90 min | 50 |
| livre | `floor(min × 0,5)` |

Bônus de **+15** por fechar o dia abaixo da meta (uma vez por dia).

Loja: 8 itens de posição fixa no habitat — 40, 70, 110, 150, 190, 240, 300, 400
folhas. Comprar é a única ação que muda a cena.

Nível do habitat = `1 + floor(itens/3)`.

### 6. Meta diária
`média informada × 0,75`, arredondada para múltiplo de 15 min.

### 7. Streak e presença
Contabiliza dias presentes, com 1 congelamento por semana. Faltar um dia não
zera de forma punitiva — o congelamento absorve a falta.

### 8. Permissão de uso
Lê **apenas o total diário** de tempo de tela. Nunca quais apps, nunca conteúdo.
Nada sai do aparelho além do agregado necessário.

- Android: Usage Access (`PACKAGE_USAGE_STATS`).
- iOS: Screen Time atrás de feature flag até o entitlement Family Controls
  existir. Ver [BLOCKERS.md](BLOCKERS.md).
- Recusar é caminho suportado (ver §3).

### 9. Monetização
Trial de 7 dias; plano anual (destacado como melhor valor) e mensal; restaurar
compras; **avisar 24h antes do fim do trial**.

### 10. Telas do MVP
Onboarding (idioma → promessa → quiz → revelação → meta → permissão),
habitat/home, sessão de foco, resultado, relatório do dia, loja, ajustes,
paywall. Tabs: Habitat, Loja, Relatório, Ajustes.

### 11. Paleta e tipografia

| Papel | Cor |
|---|---|
| Fundo/canvas | `#EDE3D2` |
| Texto (ink) | `#3E2F23` |
| Verde primário | `#5C8A4E` (hover `#486D3D`) |
| Verde claro | `#6E9C5E` |
| Laranja | `#EF8354` |
| Creme | `#FAF1E3` |
| Madeira | `#A0764C` / `#8A6440` |
| Pedra | `#A79A8C` |

Fonte: Nunito (ou equivalente arredondada). Nunca introduzir estilo que quebre
esse tom.

### 12. Tempo real em produção
Em produção o timer roda em tempo real. A aceleração de 60× do protótipo só
existe atrás da flag de debug (`AppState.debugFast`, default `kDebugMode`).

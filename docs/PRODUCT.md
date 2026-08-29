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
| `missing_you` | desistência **em aberto** hoje **ou** ≥2 dias sem abrir |
| `radiant` | uso < meta **e** ≥1 sessão completa hoje |
| `content` | uso < meta **ou** ≥1 sessão completa |
| `neutral` | uso ≤ meta × 1,2 |
| `sleepy` | acima disso |

A tabela é lida **de cima para baixo, com a primeira que casar vencendo**, e
isso muda a faixa real de duas linhas:

- `neutral` tem piso implícito. Abaixo da meta o `content` já casou, então a
  faixa efetiva é `[meta, meta × 1,2]` **e sem sessão concluída** — com meta
  de 150 min, exatamente `[150, 180]`.
- `sleepy` é **inalcançável com qualquer sessão concluída**, porque `content`
  casa com "≥1 sessão" antes dele. Doze horas de tela com uma sessão de 25
  min dão `content`. A regra é intencional — o produto não pune quem
  apareceu —, mas a **legenda** precisa dizer o fato, e não "um dia decente".

**Desistência em aberto** quer dizer: parou uma sessão no meio hoje e **a
última sessão do dia continua sendo essa**. Concluir uma sessão depois devolve
o bicho ao humor que os fatos mandam; parar de novo depois de concluir o
entristece de novo. A desistência continua registrada no dia (relatório,
missões, `baru_daily_progress.abandoned_today`) — o que sarou foi o humor, não
o fato. Ver ADR-020.


Sem permissão de uso concedida, o humor deriva só das sessões de foco
(`radiant` com ≥1 sessão, senão `content`) — recusar a permissão é caminho
suportado, não degradado.

A cena carrega o estado; a legenda diz em palavras.

Atividade derivada: `sleepy`/`neutral` → `nap`, `radiant` → `swim`,
`content` → `graze`, resto → `idle`.

### 4. Espécies

**As quatro de origem**, e só elas, saem do quiz de 3 perguntas com pesos:
`capybara` (Baru), `otter` (Rio), `tortoise` (Toco), `owl` (Nina). Essa lista é
fixa — abrir uma quinta opção mudaria o resultado de quem já respondeu.

**As conquistáveis** se desbloqueiam na trilha, nunca por dinheiro (§8B):
`axolotl` (Lume), `penguin` (Nino), `cat` (Mel), `fox` (Faísca) e
`frenchie` (Bolota, o buldogue francês — passo 20, ver ADR-018).

Todas são trocáveis nos ajustes depois de liberadas. Nome do pet é editável
(máx. 18 caracteres).

Toda espécie nova nasce nos quatro idiomas (nome curto e frase), com paleta de
pelagem própria de mais de um tom, desenho próprio em `widgets/pet.dart` e ícone
de app próprio. Travado por `test/l10n_especies_test.dart`,
`test/especies_test.dart` e `test/manifest_release_test.dart`.

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

### 8. Permissão de uso e o que conta como tempo de tela

Lê **apenas o agregado do aparelho**, nunca conteúdo. Nada sai do aparelho além
do necessário.

O tempo é **contabilizado**, não somado (ADR-009). Só conta o intervalo em que:
a tela está ligada, o aparelho está desbloqueado e um app contável está em
primeiro plano. Launcher, system UI, teclado, telas do sistema, discador em
chamada e o próprio Baru nunca contam.

Cada app entra numa categoria de produto:

| Categoria | O que é | Entra na meta? |
|---|---|---|
| **dispersivo** | social, vídeo curto, jogo | sim |
| **neutro** | mensagem, navegador, mapa | sim |
| **produtivo** | leitura, estudo, trabalho | não |
| **passivo** | áudio | não |

Áudio com a tela apagada **nunca conta**. Com a tela ligada conta como passivo,
e passivo não entra na meta. O usuário pode reclassificar qualquer app; a
escolha persiste e sincroniza.

Sem permissão o app **não estima nem inventa**: mostra estado vazio com um
caminho de um toque para conceder.

- Android: Usage Access (`PACKAGE_USAGE_STATS`).
- iOS: Screen Time atrás de feature flag até o entitlement Family Controls
  existir. Ver [BLOCKERS.md](BLOCKERS.md).
- Recusar é caminho suportado (ver §3).

### 8B. Progressão: XP, nível e trilha

O companheiro ganha XP por sessão concluída (12/30/60 conforme a duração), por
dia fechado abaixo da meta (20), por missão (10 diária, 40 semanal) e por dia
de sequência (5). **O nível nunca cai.**

A **trilha** é a sequência ordenada e visível de vinte e dois marcos, do
primeiro foco aos cem dias. Cada marco tem requisito claro, recompensa
concreta e prévia.

Ela é uma **corrente**: um passo só conquista depois do anterior, e um marco
cujo critério já foi batido espera a vez em vez de se antecipar. Antes cada
marco tinha critério independente, e como os critérios são de naturezas
diferentes — dias, sessões, nível, afagos — dava para ter o passo 8
conquistado com o 3 pendente. Ver ADR-017.

Marco conquistado nunca é retirado, e o que já foi **entregue** também não:
espécie e habitat são derivados da trilha, e um piso de posse impede que a
corrente tome de volta o que uma conta antiga já recebeu.

As espécies extras se desbloqueiam por marco, **nunca por dinheiro**, e cada
marco de habitat abre um cenário novo — do jeito que a arena do Clash Royale
troca.

Todos os números vivem em `lib/data/progressao.dart`.

### 8C. Missões

Três diárias e duas semanais, sorteadas de pools de forma **determinística** por
conta e data (ADR-010) — o mesmo dia dá as mesmas missões em qualquer aparelho.

Toda missão mostra, sem abrir nada: título em linguagem de ação, progresso
numérico e em barra, recompensa exata em folhas e XP, prazo e estado. Resgate é
idempotente. Expirar à meia-noite **não pune**. Missão que depende de permissão
não concedida vira convite para conceder, nunca missão impossível.

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

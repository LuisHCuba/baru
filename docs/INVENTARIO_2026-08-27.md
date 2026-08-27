# Inventário — o que está estático, quadrado, mudo ou mentiroso

Feito antes de qualquer edição, tela por tela, conforme §2. É o insumo do plano
do turno.

## Mentiras da UI (dívida de confiança — atacar primeiro)

| Onde | A mentira |
|---|---|
| Home / Relatório | O número de "tempo de tela" soma foreground de **todo** pacote, incluindo launcher, system UI e áudio em background. Spotify no bolso conta como tempo de tela. |
| Home | "Habitat nível N" é `1 + itens/3`. Não existe nível: é o contador de itens com outro nome. Não há XP, não há progressão. |
| Home | Quests mostram progresso binário (feito/não feito). Sem x de y, sem prazo, sem estado de resgate. |
| Ajustes | "Restaurar compras" liga um booleano sem consultar loja nenhuma. |
| Paywall | Preços fixos em texto, sem produto de loja atrás. |

## Estático (o conceito é "habitat", a execução é wallpaper)

- **O companheiro não se move.** `PetView` é `CustomPainter` sem `AnimationController`. Não respira, não pisca, não reage ao toque. As quatro atividades (`nap`, `swim`, `graze`, `idle`) mudam a pose desenhada, não o movimento.
- **O habitat não tem camadas nem profundidade.** Fundo chapado, itens posicionados em `Positioned` absoluto, sem paralaxe.
- **A cena não conhece a hora.** O habitat às 22h é idêntico ao das 9h.
- **Nada celebra.** Completar sessão, comprar item, subir "nível": nenhum tem partícula, som ou háptico.
- **Contadores saltam.** Folhas mudam de valor sem animar. Barras aparecem no valor final.

## Quadrado

- `_dot()` da semana, `QuestMark`, `ItemSwatch`: retângulos e círculos duros.
- Itens da loja no habitat são `Container` com `borderRadius` — blocos de cor.
- Sem gradiente, sem vinheta com profundidade real, sem elevação em camadas.
- Valores de cor, raio e espaço espalhados: `nunito(size: 15.5)`, `EdgeInsets.fromLTRB(26, 20, 26, 34)`, `Radius.circular(18)` — dezenas de números soltos fora de qualquer token.
- Tipografia baixada em runtime (`google_fonts`): app offline-first que depende de rede para a própria letra.

## Mudo

- **Nenhuma transição entre telas.** `_Shell` faz `switch(screen)` e troca o widget: corte seco em 100% das navegações.
- **Sem rotas.** Navegação é variável de estado. Botão voltar do Android não faz nada. Sem histórico, sem deep link.
- **Sem barra persistente real**: `BottomTabs` some em sessão, resultado, onboarding e paywall — e são 4 destinos que não incluem trilha nem missões, porque elas não existem.
- **Sem presença fora do app.** Sessão em curso não tem notificação; o app fechado é invisível.
- Toque em chip, card e item da loja não dá retorno visual nem háptico.

## O que não existe e o produto pede

- Trilha de marcos.
- Nível e XP.
- Missões com anatomia (progresso x/y, recompensa, prazo, resgate).
- Estágios de habitat.
- Espécies desbloqueáveis por marco.
- Detalhamento de tempo de tela por app e categoria.

## Plano do turno, na ordem do §11

1. Fundação: tokens de design e sistema de movimento (§7, §7B).
2. Espinha de navegação: rotas reais, barra fixa de 4 destinos, transições (§4B).
3. Fatia — companheiro vivo e habitat em camadas com hora do dia (§7).
4. Fatia — tempo de tela verdadeiro, com tela de detalhamento (§3).
5. Fatia — nível, XP e trilha (§4).
6. Fatia — missões que creditam de verdade (§5).
7. Notificação viva de sessão (§6).

# Briefing da pesquisa — Baru, outubro de 2026

Pedido do dono do produto (palavras dele, resumidas): o app precisa de
"infinitas melhorias". Problemas apontados:

1. Experiência do usuário
2. Elementos gráficos desconexos e amadores
3. Efeitos sonoros pobres e sem sentido
4. Animações extremamente limitadas
5. Jornada limitada
6. Não dá para acompanhar o crescimento dos pets; a diferença tem de ser
   **extremamente visível** (ex.: a coruja começa como **ovo**, e assim por
   diante, conforme a espécie)
7. O pet que aparece sobre os outros apps tem de ser **o mesmo pet da pessoa**
   (hoje é um desenho genérico feito à parte em Kotlin)

Ele quer pesquisas massivas e detalhadas, com **laudos**, sobre: experiência do
usuário; apps relacionados e Duolingo; visual e estética; elementos sonoros;
uma pesquisa dedicada para cada pet; uma jornada dedicada com visuais
dedicados para cada pet; itens que podem ser comprados; elementos gráficos;
comportamento do usuário e como gratificá-lo (como a animação da ofensiva do
Duolingo); notificação de lembrete; como fazer a pessoa abrir o app ao menos
uma vez por dia e cumprir a missão; mais clareza nas missões e na coleta de
recompensas; revisão do visual dos animais e das emoções, com muito mais
qualidade.

## O produto

Baru: app Android (Flutter) de foco e redução de tempo de tela com um
bichinho virtual. Sessões de foco viram folhas (moeda) e XP; o tempo de tela é
contado por categoria; há trilha de 22 passos, missões diárias/semanais, loja
de itens do habitat e roupas, 9 espécies, 5 humores, habitat que muda com a
hora do dia, raiz (= ofensiva/streak) com 1 congelamento por semana,
sobreposição que chama a pessoa de volta quando ela sai do app durante o foco.
4 idiomas (pt, en, es, zh).

**Regras invioláveis** (docs/PRODUCT.md — toda recomendação tem de respeitar):
sem punição (o bicho nunca morre, nunca perde nada, nunca culpa), 4 idiomas de
primeira classe, nada sai do aparelho além do necessário, espécies se liberam
na trilha **nunca por dinheiro**. Se uma recomendação exigir mudar uma regra,
diga isso explicitamente e justifique.

## Onde olhar

- Repositório: `/home/user/baru` (app em `baru_app/`, documentos em `docs/`)
- Contrato de produto: `docs/PRODUCT.md`; estado: `docs/STATE.md`;
  roadmap: `docs/ROADMAP.md`; decisões: `docs/DECISIONS.md`
- **Relatório de UX anterior (agosto): `docs/RELATORIO_UX_DUOLINGO.md`** —
  leia antes; não repita, aprofunde e atualize.
- Bicho: `baru_app/lib/widgets/pet.dart` (CustomPainter, ~4000 linhas),
  `lib/widgets/pet_profile.dart`; habitat `lib/widgets/habitat.dart`;
  progressão `lib/data/progressao.dart`; missões `lib/data/missoes.dart`;
  notificações `lib/services/notification_service.dart`; sons
  `lib/services/som_service.dart` + `assets/sons/*.wav`; celebração
  `lib/widgets/celebracao.dart`; sobreposição nativa
  `android/app/src/main/kotlin/com/lhcx/baru_app/OverlayDoBaru.kt`
- **Capturas atuais do app** (1080 × 2400): `play-store/telas/pt/*.png`
  (home de cada espécie em 4 horários: `home-<especie>[-amanhecer|-entardecer|-noite].png`)
- **Os 9 bichos em 4 humores** (1200 × 960, transparentes):
  `play-store/arte/pet-<especie>-<radiante|contente|sono|saudade>.png`
- Evidências antigas: `docs/evidence/2026-08-27/` e `2026-08-28/`
  (atividades quadro a quadro, reações, celebração)
- Espécies: capybara (Baru, capivara), otter (Rio, lontra), tortoise (Toco,
  tartaruga), owl (Nina, coruja), axolotl (Lume, axolote), penguin (Nino,
  pinguim), cat (Mel, gata), fox (Faísca, raposa), frenchie (Bolota, buldogue
  francês)

Use a ferramenta Read nas imagens para **ver** o app; não opine sobre o visual
sem olhar.

## Regras do laudo

- **Fontes reais, citadas com link.** Nada inventado. Se não achou, diga que
  não achou. Separe **fato com fonte**, **observação do app (arquivo:linha ou
  imagem)** e **inferência/opinião sua**.
- Números (retenção, efeito de streak, etc.) só com fonte. Sem fonte, não use.
- Seja específico para o Baru: cada recomendação diz **o quê**, **por quê**
  (com a evidência), **como** (técnica em Flutter/Android quando couber),
  **esforço** (P/M/G) e **impacto esperado**, e um **critério de aceite**
  verificável.
- Português do Brasil, direto, sem enfeite.
- Termine com: (1) as 10 recomendações mais importantes, priorizadas;
  (2) o que **não** fazer; (3) riscos e dúvidas em aberto.
- Escreva o laudo em `docs/pesquisa/<arquivo indicado>.md`. Não altere código
  do app nem outros documentos.

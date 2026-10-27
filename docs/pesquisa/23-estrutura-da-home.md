# 23 — Estrutura da home: o mundo, um indicador, um painel

Pedido: a home virou o mundo do bicho, mas ficou feia. Tinha muito
botão embaixo, chips de zona no alto parecendo uma barra de abas e, em
cima deles, mais três pílulas fora de padrão. O pedido é refatorar a tela
inteira e pesquisar como deve ser uma estrutura coerente, funcional e
amigável.

## O que estava na tela (antes)

Eram 17 alvos de toque soltos por cima da cena, em 5 estilos diferentes:

| Lugar | Elementos |
|---|---|
| Alto | avatar com anel de nível, pílula de folhas, pílula da raiz |
| Logo abaixo | 4 chips de zona (Toca, Brinquedos, Margem, Lagoa) |
| Lateral direita | 3 botões redondos (petisco, decorar, foto) |
| Embaixo | pílula "Seu dia", pílula da duração, botão "Começar foco" |
| Pé da tela | barra de abas flutuante (4 destinos) |

## O que as fontes dizem

- **Abas só navegam.** A Apple HIG diz "Use a tab bar to support
  navigation, not to provide actions" e manda pôr os controles que agem
  na tela numa toolbar.
  - Os chips de zona tinham cara de aba e agiam na câmera: misturavam os
    dois papéis.
  - A HIG descreve ainda a barra de abas "with an attached accessory, like
    the MiniPlayer in Music". É o modelo de uma ação presa às abas.
  - Fonte: <https://developer.apple.com/design/human-interface-guidelines/tab-bars>
- **Folhas redimensionáveis têm alça e divulgação progressiva.** A HIG
  pede um grabber em folha redimensionável ("drag the sheet to resize it;
  they can also tap it") e um único nível de folha por vez.
  - Fonte: <https://developer.apple.com/design/human-interface-guidelines/sheets>
- **Bottom sheet: curta, sem empilhar, e alcance não é argumento.**
  - A NN/g recomenda folhas para tarefas curtas e diz para não empilhar.
  - Chama de "common (but largely incorrect)" a ideia de que a folha
    melhora o alcance.
  - Por isso a folha "Seu dia" esconde o painel ao abrir: não há folha
    espremida entre o mundo e as abas.
  - Fonte: <https://www.nngroup.com/articles/bottom-sheet/>
- **Minimalismo é tirar ruído, não achatar.** A heurística 8 da NN/g diz
  que cada unidade a mais de informação compete com a relevante. A
  divulgação progressiva adia o que é raro para um segundo nível. Mais de
  2 níveis costuma ter baixa usabilidade.
  - Fontes:
    - <https://www.nngroup.com/articles/aesthetic-minimalist-design/>
    - <https://www.nngroup.com/articles/progressive-disclosure/>
- **Em jogo, a informação vai para os cantos e o controle aparece no
  contexto.**
  - A NN/g, aplicando as heurísticas a jogos, cita o Mario Kart 8: a
    posição e o mapa ficam nos cantos e o foco fica na pista.
  - Cita também o Red Dead Redemption 2, que só mostra os controles do
    cavalo perto do cavalo.
  - Fonte: <https://www.nngroup.com/articles/usability-heuristics-applied-video-games/>
- **Interface diegética.** O quadro de Fagerholt e Lorentzon ("Beyond the
  HUD", 2009) separa elementos diegéticos, que existem no mundo, dos não
  diegéticos. O pote de petiscos e a bola são objetos do mundo, e não
  botões sobre ele.
- **Foco com um botão.** A crítica de design do Forest (Pratt IxD, 2022)
  elogia o timer que começa com um toque e a tela principal com só o
  essencial. Critica as opções que só aparecem ao tocar na tela.
  - Fonte: <https://ixd.prattsi.org/2022/09/design-critique-forest-ios-app/>
- **Botão dividido.** O Material 3 Expressive traz o split button: a ação
  à esquerda e, colado nela, o menu que a ajusta. É assim que a duração
  fica junto do "Começar foco", sem ser outro botão solto.
  - Fonte: <https://gitea.com/784622644/material-components-android/src/branch/master/docs/components/SplitButton.md>
- **Finch como contraexemplo.** A crítica do Finch (Pratt IxD, 2025)
  aponta o hub lotado (checklist, loja, jornadas, comunidade e upsell)
  como o que enfraquece o mapeamento natural.
  - Fonte: <https://ixd.prattsi.org/2025/09/design-critique-finch-ios-app-2/>
- **Pegada.** Hoober observou mais de 1.300 pessoas: 49% usam uma mão,
  36% apoiam o aparelho numa mão e tocam com a outra, e 15% usam os dois
  polegares. O próprio Hoober alerta que os diagramas de "zona do
  polegar" foram lidos como regra rígida. A ação principal vai embaixo
  por convenção e hábito, não por um mapa de calor.
  - Fonte: <https://smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users>

## A estrutura (depois)

Três camadas, cada uma com um papel:

1. **Alto, canto direito: um indicador.**
   - A raiz e as folhas, num vidro só.
   - É informação; cada metade leva à sua tela, como no topo do Duolingo.
   - O nível saiu daqui e foi para o "Seu dia", onde já havia o cartão.
2. **Meio: o mundo.**
   - Tudo o que se faz com ele se faz nele: carinho no bicho, a bola no
     canto dos brinquedos e o pote de petiscos no chão da margem.
   - Nada flutua sobre a cena além da fala dele, que se recolhe sozinha
     em 8 s.
   - Os chips de zona saíram: passeia-se arrastando, e a câmera volta
     sozinha para ele.
3. **Pé: um painel, que é a barra de abas com acessório.**
   - A alça "Seu dia", que se toca ou se puxa.
   - "Começar foco" com a duração colada (botão dividido).
   - As 4 abas padrão, presas à borda.
   - É uma superfície só, opaca, com cantos de cima arredondados.

O "Seu dia" guarda o que é de segundo nível: crescimento, relatório,
semana, tempo de tela, nível, missões, próximo item e a foto para
compartilhar. Ao abrir, o painel sai da frente.

Contagem: os 17 alvos soltos em 5 estilos viraram:
- 2 no indicador;
- 3 objetos do mundo;
- 1 alça;
- 1 botão dividido;
- 4 abas.

O mundo se arruma na parte visível acima do painel: o chão, a lagoa, o
horizonte e o tamanho do bicho seguem essa altura. Em 320×640 o chão a
70% da tela caía atrás do painel.

# Auditoria independente — Onda 3, item 11 (11a e 11b)

Data: 2026-10-26. Escopo: commits `aefa12b` (11a: humor no corpo, respiração,
transição de humor) e `edf6483` (11b: espécies redesenhadas, ADR-026).
Auditei num worktree próprio de `edf6483` (`/tmp/claude-0/aud11`, removido no
fim). Não editei o app e não fiz commit. As imagens e medidas estão em
`docs/auditoria/onda-3-item-11/`. Elas foram geradas por um teste temporário
fora do repositório, que renderiza `PetView`, `HabitatScene`, `SessionScreen`,
`QuadrosDoBicho.cena` e `CenaDoCrescimento`. Uma cópia dele está em
`harness_aud_test.dart.txt`.

## Vereditos

| Item | Veredito |
|---|---|
| **11a** — humor no corpo, respiração, transição | **APROVADO COM RESSALVAS** |
| **11b** — espécies redesenhadas (ADR-026) | **APROVADO COM RESSALVAS** |

Não achei nenhum problema alto. Os problemas médios estão abaixo, com cenário
e correção. Nenhum deles quebra uma tela ou dado, mas três afetam o que o
item prometia: a transição sem salto, a respiração legível sem deformar e a
coruja "de chão".

## O que foi verificado e como

- `flutter analyze --no-pub`: **sem problemas**.
- `flutter test --no-pub`: **1077 passaram, 26 pulados, 0 falhas**. Os pulados
  são de integração e captura e dependem de variáveis de ambiente.
- Grades renderizadas, cada uma com a caixa de 200×150 do `PetView` em
  contorno vermelho para mostrar o que vaza dela:
  - `grade-humor-estagio-<espécie>.png`: 5 humores × 5 estágios (início,
    filhote, jovem, adulto, pleno), em ócio e quadro fixo;
  - `grade-atividade-<espécie>.png`: 4 atividades × 5 humores, mais filhote
    e pleno;
  - `pelagens.png`: 3 pelagens por espécie (a padrão, a mais escura e a mais
    clara; no buldogue, fulvo, preto e creme), sobre `Cores.habitat`;
  - `roupas.png` e `roupas-humores.png`: gorro, chapéu de palha, coroa,
    cachecol, óculos, tudo junto, pleno com chapéu, filhote com roupa e
    roupa em saudade, sono e radiante;
  - `zoom-*.png`: recortes ampliados.
- Medidas numéricas:
  - `medidas.txt`: caixa do desenho de 9 espécies × 5 estágios × 4
    atividades × 5 humores, mais 3 chapéus por estágio e o fôlego (respiro
    −1 e +1);
  - `medidas-sono.txt`, `medidas-transicao.txt` e `medidas-habitat.txt` (o
    humor efetivo e a atividade de cada célula do habitat).
- Contextos renderizados:
  - habitat com 9 espécies × 5 humores (`habitat-especie-humor.png` e os
    recortes da coruja e do pinguim);
  - sessão de foco de 6 espécies (`sessao-6-especies.png`);
  - quadros da sobreposição de 9 espécies × 2 estágios
    (`sobreposicao-quadros.png`);
  - cena de crescimento ovo/ninho→filhote e jovem→adulto de 6 espécies
    (`crescimento-coruja-pinguim-axolote.png`).
- Transição de humor em quadros de 0 a 400 ms, com e sem "reduzir movimento"
  (`transicao.png`, `transicao-reduzido.png`). Também o pulinho do radiante
  (`pulinho-radiante.png`) e a brincadeira da coruja
  (`coruja-brincadeira.png`).

**Não verificado:**
- Não houve teste com pessoas. O reconhecimento de espécie e de humor abaixo é
  a minha leitura das imagens, e os critérios de aceite dos laudos ("≥4 de 5
  pessoas dizem coruja", "≥80% acertam o humor") seguem sem medição.
- Não rodei o app num aparelho. A transição na home real não foi observada em
  execução: em particular, não confirmei se o `PetView` da home continua
  montado quando o humor muda.
- Não renderizei o widget da tela inicial. Só calculei, pelas caixas medidas,
  que o desenho cabe em 300×260 com escala 1,25.
- Não verifiquei a animação nativa (Kotlin) dos quadros da sobreposição, a
  cena à noite e ao entardecer, o desempenho (`Opacity` cria `saveLayer`
  durante 350 ms) nem as capturas da Play, que o ADR-026 manda regerar.

---

## 11a — humor no corpo, respiração, transição

### O que está certo

- **Postura por humor** (`pet.dart:1746-1776`):
  - na saudade, a cabeça desce 7 e inclina 0,12, e o tronco murcha
    (1,03×0,93);
  - no sono, a cabeça desce 5;
  - no radiante, a cabeça sobe 3 e o tronco estica (0,98×1,04).

  Nas 9 espécies, a saudade agora lê como tristeza ou abatimento pelo corpo,
  e não só pela boca. Fora a coruja (ver 11b-M2), nenhuma saudade lê como
  raiva ou dor: a sobrancelha ergue a ponta interna e a cabeça cai de lado
  (`grade-humor-estagio-*.png`, linha `missingYou`).
- **"Reduzir movimento" desliga a transição.** Com `disableAnimations`, há
  0 `Opacity` aos 175 ms nos 5 casos testados, e a troca é seca
  (`medidas-transicao.txt`, `transicao-reduzido.png`;
  `pet.dart:508-512`).
- **O pulinho do radiante não é exagerado.** São no máximo 4 px de subida e
  só entram em ócio com movimento normal (`pet.dart:1487-1490`,
  `pulinho-radiante.png`).
- **A amplitude do fôlego cumpre a letra do laudo 05 R4.** No adulto
  acordado, a altura do desenho varia 7–9 px entre respiro −1 e +1, numa
  caixa de 150 (`medidas.txt`, linhas `FOLEGO`). O aceite pedia ≥6 px num
  bicho de 200 px.

### Problemas

**11a-M1 · Médio · O meio da transição mostra dois bichos deslocados e
translúcidos.**
- **Onde.** `pet.dart:813-828`: cada humor é desenhado por inteiro e esmaecido
  com `Opacity` (`1 - t` e `t`). Como a postura agora muda com o humor, os dois
  desenhos não coincidem.
- **Cenário.** Contente→saudade na capivara, na coruja e na raposa; saudade→
  radiante no pinguim; sono→radiante na gata. Entre 100 e 250 ms aparecem
  duas cabeças com 7–10 px de diferença, quatro orelhas, duas caudas e dois
  pares de olhos. Por volta de 175 ms, as duas camadas a ~50% deixam o fundo
  vazar e o bicho fica "fantasma" (`transicao.png`, colunas 3 a 5).
- **Correção.** O laudo 05 R5 pede interpolar parâmetros, não quadros
  inteiros. Interpolar com `t`, num só painter:
  - `_cabecaDoHumor`, `_inclinaDoHumor` e `_posturaDoHumor`;
  - os ângulos `abre` das orelhas da gata e da raposa;
  - `ergue` e `topoX/topoY/gancho` das caudas.

  Esmaecer só os traços do rosto. Paliativo mínimo: desenhar o humor antigo
  opaco e só o novo com `Opacity(t)` por cima, o que elimina a translucidez,
  embora não elimine a dupla posição.

**11a-M2 · Médio · Na home, o humor e a atividade mudam juntos, e a
transição só suaviza o humor.**
- **Onde.** A atividade da home sai do humor (`state.dart:1087-1099`:
  radiante→nado, contente→pasto, neutro e sono→cochilo, saudade→ócio). A
  altura do bicho no habitat sai da atividade (`habitat.dart:609-620`). Os
  dois `_pintado` da transição usam a atividade **nova**.
- **Cenário.** Contente→radiante: a altura no habitat (62→34) e a ação (pasto→
  nado, com água por cima) trocam num quadro, e só o rosto e a postura
  esmaecem por cima da cena já trocada. É a mudança mais visível, e ela
  continua com corte seco.
- **Não verificado.** Não confirmei em execução com que frequência o humor
  muda com a home montada (ao voltar de uma sessão, a cena pode ser
  remontada, e aí não há transição nenhuma).
- **Correção.** Animar também a altura no habitat (`AnimatedPositioned`, ou
  interpolar o `bottom`) e manter a ação antiga até a metade da transição.

**11a-M3 · Médio · A respiração escala o corpo inteiro, cabeça e olhos
incluídos, e no sono deforma o rosto.**
- **Onde.** `pet.dart:1558` e `1566-1570`: `canvas.scale` no espaço do corpo
  inteiro, com pivô no centro do corpo e fator `fundura` 2,1 no sono.
- **Cenário.**
  - Acordado, a cabeça achata junto com o tronco (−1 × +1 em
    `respiracao.png`), e o comentário "agora se vê o peito" não corresponde.
  - No cochilo, a amplitude chega a ±7,1% de largura e ±5,5% de altura (cerca
    de 14% e 11% de pico a pico). Na capivara, no buldogue e na tartaruga, a
    cabeça e os olhos fechados visivelmente esmagam e esticam
    (`respiracao-sono.png`). No axolote, na raposa e na lontra, a largura
    varia 16–21 px durante o sono, contando a cauda (`medidas-sono.txt`).
  - Os pés sobem e descem cerca de 3 px em relação ao chão, porque o pivô é o
    centro, não os pés.
- **Correção.** O laudo 05 R4 pede "respiração do tronco 3,5% com cabeça
  atrasada ~15% da fase". Aplicar a escala só ao tronco (antes de desenhar a
  cabeça), mover a cabeça por translação atrasada e baixar `fundura` para
  ~1,3–1,5.

**11a-B1 · Baixo · O pulinho é contínuo e quase nunca aparece onde
importa.**
- **Onde.** O comentário diz "de vez em quando", mas `sin(ciclo·6π)` num
  ciclo de 7,4 s (`pet.dart:208`) dá uma subida e descida de 1,2 s a cada
  2,5 s, sem parar. Lê mais como flutuar do que como pular.
- **Cenário.** Na home, o radiante está sempre em nado ou brincadeira, nunca
  em ócio, então o pulinho só aparece em telas com ócio e radiante (por
  exemplo, o resultado da sessão).
- **Correção.** Envelope que pula 2 ou 3 vezes e descansa, ou levar o
  pulinho para a ação real do radiante.

**11a-B2 · Baixo · Trocar de humor durante a transição dá um salto.**
- **Onde.** `pet.dart:511`: `_humorAnterior = antigo.mood` pega o alvo da
  transição interrompida, não a mistura que estava na tela.
- **Correção.** Com a interpolação de parâmetros do M1, partir do valor
  interpolado atual.

**11a-B3 · Baixo · O teste do humor no corpo mede pouca coisa.**
- **Onde.** `test/humor_corpo_test.dart` conta a fração de pixels que muda.
  Uma translação de 7 px já passa dos 10% sem dizer nada sobre a
  legibilidade.
- **O que não cobre.**
  - Não cobre "reduzir movimento" na transição (verifiquei à parte: funciona).
  - O teste de transição só conta `Opacity` e não pegaria o quadro fantasma
    do M1.

**11a-B4 · Baixo · No radiante, orelhas passam do topo da caixa.**
- **Onde.** Postura radiante na gata, na raposa e no buldogue: as orelhas
  passam 1–3 px do topo da caixa de 200×150 (`medidas.txt`, `idle radiant`
  com y0 entre −3 e −1).
- **Efeito.** Nenhum recorte nos contextos verificados: a sobreposição usa
  200×170 e o humor contente, e o widget tem folga.
- **Risco.** Só se alguém puser o bicho num `ClipRect` justo.

---

## 11b — espécies redesenhadas (ADR-026)

### Biologia: o que eu vejo (sem teste com pessoas)

| Espécie | Leitura | Observação |
|---|---|---|
| Coruja (buraqueira) | **Lê como coruja e plausivelmente como buraqueira.** Sem tufo, olho todo amarelo sem esclera, sobrancelha e babador brancos, pintas claras na cabeça, pernas longas e claras com dedos | Laudo 07 R4: "sem tufos, olho amarelo, sobrancelha e babador brancos, pernas longas, pintas" está cumprido. O montinho com toca não foi feito (fora do ADR). A coruja cabe na caixa com as pernas longas: o pé fica em y=147 de 150, e em 200×170 sobra folga (`sobreposicao-quadros.png`). |
| Pinguim (magalhães) | **Lê como pinguim. Como magalhães, aproximado.** Bico e pés escuros, pés com manchas rosadas, pele rosa entre olho e bico, faixas no peito só em adulto e pleno, olho inteiro no escuro | R6 cumprido em parte. "Nenhum laranja no adulto" ✓, mas o pleno tem crista amarela (ver M3). "O olho não cruza a máscara" ✓. "Estágio 4 sem faixas, 5 com duas" ✓. Ver B1 para a faixa em C e o "pino único". |
| Axolote | **Lê como axolote.** Guelras com haste e filamentos (3 no filhote, 4 no jovem, 6 no adulto, 7 no pleno), cauda com barbatana clara visível em todos os humores | Os aceites de R5 "cauda visível em todos os humores" e "≥6 filamentos por ramo no adulto" estão cumpridos. A guelra não cobre o olho em nenhum humor nem estágio. Segue de pé, de frente: a vista 3/4 deitada do laudo não foi feita (fora do ADR). |
| Raposa | **Lê como raposa-vermelha.** Máscara branca nas bochechas e no queixo, babador branco em V, cauda ruiva com ponta branca, orelhas de ponta escura | R5 cumprido no essencial. O branco não vaza: a máscara é recortada pelo contorno da cabeça, `pet.dart:2997-3014`. O "focinho em V" é branco sobre branco e não aparece, mas a máscara faz o trabalho. Faltam as meias escuras (fora do ADR). |
| Gata | **Lê como gata malhada.** "M" na testa, listras nas têmporas, cauda tubular na cor do pelo com anéis, gancho no radiante, orelhas de ponta fina | R6 cumprido: a cauda não usa `sombraForte`. Na pelagem creme (5), o "M" e os anéis quase somem (`pelagens.png`). |
| Lontra | **Mais esguia e de cabeça chata, mas o corpo é de ursinho em pé.** | O IoU de silhueta capivara × lontra (contente, adulto) caiu para **0,70**. O laudo 06 media 0,83 por método parecido (o meu é por cor numa grade, não idêntico). A lontra fica 95% dentro da silhueta da capivara. A cauda continua a fita fina com estrangulamento perto da base, que o laudo 06 apontou. Faltam a garganta clara e o focinho prateado. |

Pelos mesmos critérios, as outras IoU são: capivara × coruja 0,69, lontra ×
gata 0,72, gata × raposa 0,57 e coruja × pinguim 0,73.

### Humores por espécie

Radiante, contente, neutro, sono e saudade se distinguem pelo corpo e pelo
rosto em todas as 9 espécies. Os canais são:
- **orelhas** em gata, raposa e buldogue;
- **cauda** em gata e raposa;
- **cabeça e postura** em todas.

Em gata e raposa, na saudade a orelha gira para o lado ("avião"), nunca para
trás, como R4 pede.

Fora a coruja (M2), as saudades leem como tristeza ou abatimento. O neutro de
várias espécies (lontra, raposa, gata) parece um pouco emburrado por causa da
pálpebra reta, mas isso é anterior ao item.

### Contextos

- **Habitat.**
  - Nadadoras (capivara, lontra, tartaruga, axolote, pinguim): na água com
    lâmina no radiante, como antes.
  - Coruja: não paira mais, mas ver M1.
- **Sessão.** A coruja aparece como "BRINCADEIRA DE 25 MIN · Nina está
  brincando na beira", coerente com o desenho. Não há chão desenhado, como
  na gata e na raposa (`sessao-6-especies.png`).
- **Sobreposição.** As 9 espécies em filhote e adulto cabem em 200×170, e
  a coruja e o pinguim novos aparecem (`sobreposicao-quadros.png`).
- **Ovo, ninho e crescimento.**
  - Coruja: ovo no ninho de capim.
  - Pinguim: ovo sobre seixos.
  - Axolote: cacho de ovos.
  - Gata, raposa e lontra: recém-nascido no ninho.
  - Jovem→adulto do pinguim: as faixas aparecem só no adulto.

  A cena funciona com os desenhos novos
  (`crescimento-coruja-pinguim-axolote.png`).
- **Roupas.**
  - Nenhum chapéu vaza o topo em espécie ou estágio (`medidas.txt`,
    `chapeu=`).
  - Gorro, palha e coroa assentam nas cabeças novas da coruja, do pinguim,
    do axolote (as guelras ficam por fora do gorro), da gata e da raposa.
  - O cachecol assenta no pinguim e na coruja.

  Ver B3 e B4 para os desvios.

### Problemas

**11b-M1 · Médio · A coruja "de chão" fica de pé dentro da lagoa no radiante
da home.**
- **Onde.** `habitat.dart:609-620` posiciona pela atividade. No radiante, a
  atividade é nado (altura 34, dentro da faixa d'água), e a coruja agora faz
  `brincadeira` ali mesmo, sem lâmina d'água.
- **Cenário.** Nina radiante na home: pés na água, no meio da lagoa
  (`recorte-habitat-coruja.png`, 1º quadro). O aceite literal de R4 ("não
  paira") está cumprido, mas o ADR diz "é de chão".
- **Origem.** É o mesmo defeito já aberto para gata, raposa e buldogue
  (laudo 08 R8). A coruja passou a fazer parte dele.
- **Correção.** `_alturaDoPet` por ação, com brincadeira na altura da margem
  (56–62), ou um apoio de chão para quem não nada.

**11b-M2 · Médio · A saudade da coruja lê como "desconfiada" ou
"entediada".**
- **Onde.** A sobrancelha branca fixa (`pet.dart:2336-2348`) tem a ponta
  interna mais baixa que a externa, um V suave. Na saudade, a sobrancelha de
  humor (marrom) é desenhada por cima dela, e a pálpebra cor de pelo cobre
  metade do olho amarelo. Com a cabeça inclinada, o resultado é um olhar de
  lado, meio fechado (`zoom-coruja-contente-saudade-radiante.png`, centro).
- **Regra afetada.** O laudo 03 §3.2 proíbe que qualquer humor seja lido como
  "desconfiado". Não verificado com pessoas.
- **Correção.** Na saudade, curvar a própria mancha branca com a ponta
  interna para cima (ela é o canal de sobrancelha da buraqueira), não
  desenhar a sobrancelha marrom sobre a branca e usar uma pálpebra mais fina
  ou clara no olho amarelo.

**11b-M3 · Médio · O pinguim pleno tem crista dourada, que o magalhães não
tem.**
- **Onde.** `pet.dart:3913-3933` (e o comentário em `3887`): três penas
  amarelas no topo da cabeça.
- **Por que é problema.** Crista amarela é de pinguim-saltador ou de
  macaroni. Contradiz o ADR-026 ("Nino é um pinguim-de-magalhães") e o
  sentido do R6, que pedia "nenhum laranja" e marcas reais.
- **Correção.** Trocar por uma marca real do adulto no auge, por exemplo a
  pele rosa maior e mais viva perto do olho (Wiki-Magellanic, no período
  reprodutivo) ou a borda branca da cabeça mais larga.

**11b-M4 · Médio · O 11b não tem nenhum teste das decisões de desenho.**
- **Onde.** O commit só ajusta `atividades_test.dart`: a coruja passa de voo
  a brincadeira, e a asa não abre.
- **O que não é testado.**
  - "faixas do pinguim só no adulto e no pleno";
  - "coruja sem tufo" e "olho amarelo";
  - "nenhum laranja no pinguim";
  - "filamentos por estágio";
  - "cauda da gata na cor do pelo";
  - "branco da raposa recortado na cabeça".

  Qualquer uma delas pode regredir em silêncio.
- **Testes que perderam o sentido.** `test/pet_vivo_test.dart:288-292` usa
  a coruja "de propósito" porque "o tufo dela responde de forma linear a
  `orelha`". O tufo não existe mais, e o teste perdeu o poder de detectar o
  defeito que descreve. `test/buldogue_test.dart:211` também fala em tufos.
- **Correção.** Testes de pixel em faixas, no estilo de `atividades_test`:
  1. faixa escura no peito do pinguim em `adulto` e ausente em `jovem`;
  2. nenhum pixel acima da cabeça da coruja no adulto;
  3. nenhum pixel "laranja" (matiz de 20–40°) no pinguim adulto e no pleno;
  4. trocar a espécie do teste de "nada fica preso" para gata ou raposa, que
     agora têm orelha dependente de humor e de `orelha`.

**11b-B1 · Baixo · A cabeça do pinguim lê como capacete.**
- A faixa branca em C forma um anel quase fechado em volta do rosto e lê
  como capacete ou fone de ouvido em tamanho de home
  (`recorte-habitat-pinguim.png`).
- As duas metades se encontram no queixo com uma costura vertical visível
  (`pet.dart:2626-2633`, `lineTo(0, 25.5)`).
- Cabeça e corpo continuam duas bolas com "pescoço", e não o "pino único" de
  R6.
- **Correção.** Abrir o C no topo e na nuca (começar mais baixo, acima do
  olho, e terminar na garganta sem fechar o anel), desenhar a faixa como um
  `Path` só, sem duas metades, e fundir a cabeça e o corpo num contorno.

**11b-B2 · Baixo · Na lontra, as roupas e a flor seguem medidas da cabeça
antiga.**
- **Onde.** `_veste(canvas, 84, 74)` (`pet.dart:2003`) não acompanhou a
  cabeça nova de 78×62.
- **Cenário.**
  - O gorro fica cerca de 6 px acima do contorno.
  - A flor do pleno aparece por baixo do gorro, à esquerda
    (`zoom-pinguim-gorro-lontra-oculos-lontra-gorro-pleno.png`, 3º quadro).
  - Os óculos ficam abaixo dos olhos (2º quadro). Os óculos desalinhados são
    um problema anterior e geral (ver B3), mas na lontra pioraram.
- **Duplicação.** Há um comentário duplicado e contraditório: as linhas
  1952-1953 dizem "pequenas e altas" e logo depois "pequenas e baixas".
- **Correção.** `_veste(canvas, 78, 62)` e esconder a flor do pleno quando há
  chapéu, como a capivara e o pinguim já fazem.

**11b-B3 · Baixo · Óculos desalinhados dos olhos em várias espécies
(anterior ao 11b).**
- **Onde.** `_oculos` (`pet.dart:4271-4290`) põe as lentes em ±0,30w e
  −0,16h. Na coruja (olhos ±19,+2), na lontra (±21,−12), na capivara e na
  gata, as lentes ficam para dentro ou acima dos olhos
  (`zoom-coruja-oculos-gorro-pinguim-oculos.png`).
- **Origem.** Anterior ao 11b, mas a coruja nova evidencia o defeito.
- **Correção.** Passar a posição dos olhos de cada espécie para `_veste`.

**11b-B4 · Baixo · A coruja dorme inclinada sobre as pernas longas.**
- **Onde.** O cochilo gira o corpo em −0,16 (`pet.dart:1522`) com as pernas
  longas juntas.
- **Cenário.** Um pé fica mais baixo que o outro e passa 3–4 px da caixa, e a
  coruja parece tombando
  (`zoom-coruja-cochilo-pinguim-cachecol-coruja-cachecol.png`, 1º quadro;
  `recorte-habitat-coruja.png`, 3º e 4º).
- **Correção.** No cochilo da coruja, sem giro, pernas recolhidas e a cabeça
  afundando nos ombros, como o laudo 07 §1.4 descreve.

**11b-B5 · Baixo · Pelagens escuras apagam o olho fechado no sono.**
- **Cenário.** No buldogue preto (pelagem 5) e na lontra mais escura
  (pelagem 3), o olho fechado do sono (traço escuro) some no rosto escuro, e
  o sono perde o canal do olho, ficando só a postura e o "zZ"
  (`recorte-buldogue-preto.png`, `recorte-lontra-escura.png`, 4º quadro).
- **Origem.** É anterior ao item no buldogue. Fora isso, o contraste das
  pelagens escuras é suficiente (olhos abertos com esclera clara, máscara da
  raposa, faixas do pinguim na pelagem 3).
- **Correção.** Traço do olho fechado em tom claro (`luz`) quando a
  luminância do pelo cair abaixo de um limiar.

**11b-B6 · Baixo · Ficou código morto do voo.**
- **Onde.** `AcaoDoBicho.voo` não é mais retornado por `acaoDoBicho`
  (`pet.dart:113-150`), mas continuam:
  - os ramos de voo no painter (`pet.dart:1176`, `1482`, `1528`, `2165`, a
    asa aberta em `2224`);
  - o ciclo `_cicloDoVoo`;
  - as chaves `petFazendo_voo` e `petSessao_voo` (`l10n_pet.dart:24`, `33`).
- **Correção.** Remover, ou anotar que fica reservado.

---

## Resumo dos problemas por severidade

| # | Sev. | Item | Problema |
|---|---|---|---|
| 11a-M1 | Médio | 11a | Transição por *crossfade*: no meio, dois bichos deslocados e translúcidos |
| 11a-M2 | Médio | 11a | Na home, a atividade e a posição trocam secas; só o humor esmaece |
| 11a-M3 | Médio | 11a | Respiração escala o corpo todo; no sono (×2,1) deforma cabeça e olhos |
| 11b-M1 | Médio | 11b | Coruja "de chão" de pé dentro da lagoa no radiante da home |
| 11b-M2 | Médio | 11b | Saudade da coruja lê como desconfiada (sobrancelha branca em V + pálpebra) |
| 11b-M3 | Médio | 11b | Pinguim pleno com crista dourada, que o magalhães não tem |
| 11b-M4 | Médio | 11b | Nenhum teste das decisões de desenho; teste da coruja "por causa do tufo" sem sentido |
| 11a-B1…B4, 11b-B1…B6 | Baixo | — | Pulinho contínuo; salto ao interromper a transição; teste por % de pixels; orelhas 1–3 px acima da caixa; pinguim "capacete" e costura; roupas e flor da lontra; óculos desalinhados (anterior); coruja dormindo tombada; olho fechado some em pelagem escura; código morto do voo |

---

## Resposta às ressalvas (implementador)

Os sete médios foram tratados. Os testes novos foram rodados contra o
`pet.dart` anterior e falham nele.

| Achado | O que mudou | Prova |
|---|---|---|
| **11a-M1** | A troca de humor não esmaece mais dois bichos. O painter ganhou `corpoDe`/`corpoPara`/`mistura`: postura, cabeça, inclinação, pulinho, orelhas (gata, raposa, buldogue) e caudas (gata, raposa) são **interpolados** num desenho só. Os dois desenhos da troca têm o mesmo corpo; só o rosto difere, e o de baixo fica opaco (sem fundo vazando). | `humor_corpo_test.dart` ("no meio da troca não há dois bichos nem bicho translúcido"): no código antigo a área ocupada no meio da troca passa 13% da maior das duas pontas e o teste falha. |
| **11a-M2** | A altura do bicho no habitat (e a sombra e o "+XP") anda com `AnimatedPositioned` de 450 ms. | Leitura; a ação (pasto → nado) continua trocando no quadro da mudança, o que não resolvi. |
| **11a-M3** | O fôlego escala só o tronco, com pivô nos pés (os pés não sobem mais). A cabeça desfaz a escala (`_cabecaSemFolego`, nas 9 espécies) e é levada pelo peito. Sono: fator 2,1 → 1,5. | Suíte de respiração (`pet_vivo_test`, `atividades_test`) passa; a deformação da cara não tem teste de pixel. |
| **11b-M1** | A altura no habitat sai da **ação** da espécie: quem não nada (coruja, gata, raposa, buldogue, e qualquer um no ovo ou no ninho) brinca na margem (62), não dentro da lagoa (34). Resolve também o laudo 08 R8. | `pet_grande_test.dart` ("quem não nada fica na altura da margem"). |
| **11b-M2** | A mancha branca da coruja é a sobrancelha dela e muda com o humor: ponta de dentro sobe na saudade (e um pouco no sono), reta nos outros; sem a sobrancelha marrom por cima; pálpebra mais fina e mais clara sobre o olho amarelo. | Grade renderizada conferida; leitura com pessoas não feita. |
| **11b-M3** | Crista dourada removida. No pleno, a pele rosa entre o olho e o bico cresce e aviva (marca real da época de ninho). | `especies_desenho_test.dart` ("o pinguim não tem laranja nem crista"), falha no código antigo. |
| **11b-M4** | `test/especies_desenho_test.dart`: olho amarelo da buraqueira; pinguim sem laranja e sem amarelo em 4 estágios; faixas do peito só no adulto (cortes na barriga pela coluna do meio, imune ao porte); brancos da raposa. `pet_vivo_test` passou a usar a gata (orelha linear em `orelha`) no lugar do tufo que não existe; comentário do `buldogue_test` corrigido. | A suíte inteira: 1131 aprovados. |

**Não tratado agora (baixos):** pulinho contínuo do radiante; salto ao
trocar de humor no meio da troca (B2); orelhas 1–3 px acima da caixa;
cabeça do pinguim "capacete"; medidas antigas de roupa da lontra; óculos
desalinhados; coruja dormindo inclinada; olho fechado sumindo no pelo
escuro; código morto do voo. Também não testei filamentos das guelras por
estágio nem a cauda da gata na cor do pelo.

# Auditoria independente — Onda 4 (missão em cena, sessão no habitat, arte dos itens)

Data: 2026-10-27. Escopo: os commits `5ecd2cc` ("Sessão dentro do habitat,
viva ao toque; margem de terra; raiz e loja da home") e `2584b0f` ("Missão
cumprida em cena; arte dos 22 itens; desistência no habitat; ajustes"), ou
seja, `git diff f161493 2584b0f`. Julguei as mudanças pelo que o dono do
produto pediu, não pelo que as mensagens de commit dizem.

Os números de linha se referem aos arquivos **no commit `2584b0f`**, lidos
com `git show 2584b0f:<arquivo>`. A árvore de trabalho tem mudanças não
commitadas em 17 arquivos de `lib/`, de outro processo, e elas ficaram fora
desta auditoria.

## Como foi feito

- Li o diff inteiro e os arquivos tocados no estado do commit: `state.dart`,
  `app.dart`, `l10n.dart`, `session_screen.dart`, `result_screen.dart`,
  `home_screen.dart`, `settings_screen.dart`, `sobreposicao_screen.dart`,
  `habitat.dart`, `arte_dos_itens.dart`, `cena_da_missao.dart`, `pet.dart`,
  `pet_profile.dart`, `common.dart`, `loja_vitrine.dart` e os testes novos.
- Vi as capturas já geradas: `build/visual/v9/*.png` (depois) e `v3` (antes).
- **Não rodei** `flutter analyze` nem `flutter test`: outro processo estava
  compilando no mesmo diretório. As medidas de transbordo abaixo são **contas
  feitas no papel** a partir dos tokens (`Espaco`, `Tipo`, `BotaoBaru.alturaPadrao
  = 56`, escala de texto limitada a 1,25 em `app_frame.dart:50`). Não são
  renderização. Antes de corrigir, confirme cada uma num teste de widget de
  320×640 e de 360×640.
- Não editei nada em `lib/` nem em `test/`, e não fiz commit.

## Veredito por pedido do dono

| # | Pedido | Veredito |
|---|---|---|
| 1 | Pop-up animado de missão cumprida, estilo Duolingo | **Entregue, com um bug alto**: "Colher agora" engole a próxima celebração (A1). Só dispara para missões fechadas por **sessão** (M5) |
| 2 | Sessão: bicho vivo, fofo e interativo (dedo, toque) | **Entregue no essencial**: habitat em tela cheia, olhar que segue o dedo e a borboleta, folhinhas no toque, carinho, pausas à toa, broto que cresce. Há ressalvas de layout e de custo (M2, M6, B3) |
| 3 | Cenário feio após desistir; itens amadores | **Bem melhor**: a desistência acontece no habitat e os 22 itens têm arte própria. Ressalvas: a arte fica esticada na vertical (M7), neve, fagulhas e pétalas andam ao contrário metade do tempo (B1), e a sombra do bicho vira uma faixa escura atrás do corpo (B2) |
| 4 | Home: "faltam 0 folhas", espaço antes dos botões, raiz de 3 dias apagada | **Os três corrigidos**, mas a nova faixa de 7 dias pinta um dia a mais quando há congelamento (M1) |
| 5 | Ajustes e permissões | **Melhor visualmente.** O nome editável no cartão novo perde o foco a cada letra (A2). As permissões ainda têm "Ele não trava nada" (B5) |
| 6 | Espaçamento padronizado | **Parcial**: o código novo usa `Espaco`, mas sobram literais nas telas tocadas (B7) |
| — | "Ele continua aqui" para a Nina | **Corrigido** em `resLostSub` e, de forma geral, por `comPronome` com o nome. A troca de `{p}` não quebra nenhuma string numérica (ver "O que está certo") |

---

## Achados

### A1 — "Colher agora" pula a celebração seguinte (crescimento, nível, marco ou chegada) — **alta**

`state.dart:330-333` e `state.dart:371-380`:

```dart
void colheAsCumpridas() {
  resgataTodas(missoesACumprir);   // as missões deixam de ser `resgatavel`
  celebrou();
}
...
if (missoesCumpridas.isNotEmpty) {
  final havia = missoesACumprir.isNotEmpty;   // agora é false
  missoesCumpridas = const [];
  if (havia) { notifyListeners(); return; }  // não retorna...
}
if (cresceuSemCelebrar) { ...marca como celebrado...; return; }  // ...e consome o próximo
```

`resgataTodas` grava a chave de resgate, então `missoesACumprir` já está vazia
quando `celebrou()` roda. `havia` dá `false`, e o fluxo cai no próximo item
da fila e o marca como celebrado **sem mostrá-lo**.

**Cenário realista:** a sessão fecha "Faça uma sessão de foco" e completa as
sessões que fazem o bicho crescer. A sequência fica raiz → missão; a pessoa
toca "Colher agora" e a cena do crescimento, que é o clímax, nunca aparece.
O mesmo acontece quando o XP da própria colheita sobe de nível
(`subiuDeNivel`), que é justamente o caso que o comentário em
`state.dart:369-370` diz querer mostrar "na sequência". Também acontece com
o primeiro marco da trilha que a colheita destravar (as folhas são
creditadas e a cena some) e com a chegada do dia.

"Colho depois" não tem o bug: aí `havia` dá `true`.

Os testes não pegam o problema. O de `fim_de_sessao_test.dart` ("a sessão que
fecha missão acende a cena") confere só as folhas e a lista vazia depois de
`colheAsCumpridas`, e o caso "colhida pela tela de missões" testa
justamente o caminho em que cair para o próximo item é o certo.

**Correção:** `colheAsCumpridas` não deve chamar `celebrou()`. Deve fazer
`resgataTodas(...)`, depois `missoesCumpridas = const []` e
`notifyListeners()`. Junto, vale um teste: sessão que fecha missão **e**
cresce, depois `colheAsCumpridas()`, e então `cresceuSemCelebrar` continua
`true`.

### A2 — O nome no cartão novo de Ajustes perde o foco a cada tecla — **alta** (herdado, mas agora em destaque)

`pet_profile.dart:340`:
`PetNameField(key: ValueKey('${app.speciesKey}-${app.displayName}'), onChanged: app.setName, ...)`.

`setName` notifica (`state.dart:1876-1880`), `displayName` muda e a chave
muda junto. O Flutter descarta o `State` do campo e cria outro com um
`TextEditingController` e um `FocusNode` novos. Resultado: depois da
primeira letra o teclado fecha, ou o cursor salta.

Apagar o nome inteiro também não funciona. Com `petName` vazio,
`displayName` volta ao nome padrão da espécie (`state.dart:1094`), a chave
muda de novo e o campo é recriado já preenchido com "Baru".

O defeito já existia no cartão completo (`pet_profile.dart:273`). O commit
copiou o padrão para o cartão compacto, que agora é a peça principal de
Ajustes e é anunciado como "cartão do bicho com nome editável". Nenhum teste
digita no campo.

**Correção:** usar `ValueKey(app.speciesKey)`. O `didUpdateWidget` do
`PetNameField` já sincroniza o `initial`.

### M1 — Com congelamento, a faixa de 7 dias pinta um dia a mais — **média**

`state.dart:767-770` não desconta o dia congelado de `faltam`, e o comentário
em `state.dart:748-750` diz que esses dias "não contam na raiz". Mas contam:
`_advanceDay` faz `streak += 1` ao congelar (`state.dart:2553-2556`).

**Cenário:** segunda com foco, terça congelada, quarta com foco. A raiz vale
3. O laço faz: quarta presente (faltam 2), terça congelada (faltam continua
2), segunda presente (faltam 1), domingo presente (faltam 0). O domingo, que
não teve foco, aparece pintado. É o inverso do bug que o dono relatou, e
igualmente mentiroso. O teste novo de `calendar_test.dart` não tem
congelamento.

**Correção:** no ramo `frozen`, fazer `faltam--`.

### M2 — Telas sem rolagem transbordam em aparelho pequeno — **média**

Três colunas fixas, sem `SingleChildScrollView`. Contas para 360×640 com
barra de navegação de 3 botões, o que deixa cerca de 568 dp úteis:

- **Cena da missão** (`cena_da_missao.dart:159-285`). Altura útil de cerca de
  532 dp depois do padding. Com **2 missões** e texto em 1,0, o conteúdo
  soma uns 573 dp: bicho 190, título, 2 cartões de cerca de 76, prêmios e
  botões 112. Sobram cerca de 40 dp para fora. Com **3 missões**, "Colher
  agora" fica inteiro fora da tela, e o toque não acerta filho fora da caixa
  do pai. No Android o "voltar" fecha a cena (`state.dart:1370`). No iOS não
  há saída além dos botões.
- **Sessão** (`session_screen.dart:231-232`). A cena usa 56% da altura **da
  tela**, `MediaQuery.sizeOf`, e não da área útil. Sobram cerca de 210 dp
  para cerca de 213 dp de conteúdo em 1,0, e uns 235 dp com fonte em 1,25.
  Quem fica cortado é o **"Desistir"**, a única saída da sessão.
- **Desistência** (`result_screen.dart:64`). Com fonte em 1,25, ou com um nome
  longo que quebre o título em 2 linhas, os dois botões passam da borda em
  cerca de 5 a 60 dp.

**Correção:** envolver as colunas em `LayoutBuilder` com
`SingleChildScrollView` e `ConstrainedBox(minHeight)`, como em outras telas
do app. Na sessão, medir a altura da cena pelas restrições do pai.

### M3 — `Pelagem` em Ajustes indexa a paleta sem trava — **média/baixa**

`settings_screen.dart:70`: `AppColors.coatDe(app.species)[app.color]`.
`_applySnapshot` restaura `color = s.color` sem `clamp` (`state.dart:2820`).
Um snapshot antigo ou corrompido com índice 6 ou mais dá `RangeError` e
derruba a tela de Ajustes. Já existe `AppColors.pelagemDe(especie, indice)`,
que trava o índice. Basta usá-la.

### M4 — A sessão reconstrói o habitat inteiro a cada quadro, por 25 minutos — **média** (desempenho e bateria)

O `AnimatedBuilder(animation: _voo)` de `session_screen.dart:270` envolve o
`HabitatScene`. Isso faz o `build` do habitat rodar a cada quadro, enquanto
`_voo.repeat()` estiver rodando, e cada `build` faz o seguinte:

- `_sincronizaChegadas` e `itensDeCena.where(...)` alocam listas e conjuntos;
- o rótulo de `Semantics` chama `app.falaDoHumor` **duas vezes**, e com ela
  `escolheAFala`, `garanteTextosDoHumor` e `fill` (`habitat.dart:505-506`);
- `Listenable.merge([...])` cria um objeto novo, e o `AnimatedBuilder`
  interno troca os ouvintes;
- o `PetView` passa por `didUpdateWidget`.

Além disso, `_ObjetoPintado.shouldRepaint` compara `fase`
(`habitat.dart:731-736`). Assim **todos** os itens possuídos se repintam a
cada quadro da deriva, inclusive os que não se movem (pedra, deque, ponte,
árvore). A cada repintura eles recriam `Path`, `Paint`, `Gradient` e
`MaskFilter.blur` (a sombra de contato em `arte_dos_itens.dart:140-147`).
Com o habitat cheio são 22 itens.

**Sugestão:**
- passar o olhar ao bicho por um `ValueListenable<Offset>`, e não por
  reconstrução;
- separar os itens estáticos (`shouldRepaint` sem `fase`, dentro do próprio
  `RepaintBoundary`) dos animados;
- fixar o rótulo de semântica fora do quadro a quadro.

### M5 — A cena de missão só existe para missões fechadas por sessão de foco — **média** (lacuna em relação ao pedido 1)

`missoesCumpridas` só é preenchida em `_concluiSessao` (`state.dart:2375`).
Missões que fecham por outro caminho continuam fechando em silêncio:
carinho (`msCarinho`), descanso (`resgataODescanso`) e as semanais que fecham
fora da sessão. O pedido foi "completar uma missão deve disparar o pop-up",
sem restrição de origem.

### M6 — O broto da sessão nasce em cima dos itens do habitat — **média/baixa** (visual)

`session_screen.dart:292` posiciona o broto em `left: cena.width * 0.70`,
`bottom: 30 * sy`. O comentário diz "na margem à esquerda", mas o broto
fica à direita, exatamente onde fica a pedra (`rock`). Nas capturas
`v9/s1-sessao-coruja.png` e `v9/s2-sessao-capivara.png`, o montinho de terra
e o caule aparecem desenhados **sobre a pedra**. Na capivara, que está nadando
e portanto sem margem, o broto ainda boia na água.

### M7 — A arte dos itens é esticada na vertical — **média/baixa** (visual)

`_ObjetoPintado.paint` faz `canvas.scale(sx, sy)` (`habitat.dart:718`) com
`sx` diferente de `sy`. A arte nova é feita de círculos, flores, peixes e
chamas, e por isso distorce bem mais que os retângulos de antes:

- na home (372 de altura) a razão é cerca de 1,26;
- na sessão de um telefone 1080×2400, `sy` é cerca de 1,73 e `sx` cerca de
  1,1, uma razão de cerca de 1,6.

A pedra e o lampião ficam visivelmente altos demais em `v9/s1`. O bicho usa
`min(sx, sy)`, e é por isso que só os objetos parecem errados.

**Sugestão:** posicionar pela caixa em `sx`/`sy`, mas desenhar com escala
uniforme a partir da base da caixa.

### B1 — Neve, fagulhas e pétalas sobem metade do tempo — **baixa**

A `fase` vem de `_deriva.repeat(reverse: true)` (`habitat.dart:411`) e vai de
0 a 1 e volta. As quedas usam `fase * k % 1` como se a fase sempre
avançasse:

- neve, `arte_dos_itens.dart:819`;
- fagulhas, `arte_dos_itens.dart:905`;
- pétalas da cerejeira, `arte_dos_itens.dart:958`.

Na volta da deriva, a neve e as pétalas sobem e as fagulhas descem para
dentro do fogo. A neve, além disso, só percorre 14 unidades em 14 s, o que
parece um balanço e não uma queda.

**Sugestão:** usar um relógio monotônico próprio para as partículas, ou
`fase` de um controller sem `reverse`.

### B2 — A sombra do bicho vira uma faixa escura atrás do corpo — **baixa** (visual, mais visível agora)

Em `v9/s1`, `v9/r1` e `v9/r2`, a sombra de `habitat.dart:575-588` aparece
cerca de 45 dp **acima** dos pés da coruja, como uma barra translúcida
cruzando o corpo. Sobre a margem de grama nova ela chama atenção, e em cena
alta (com `sy` grande) a distância cresce. Vale ancorar a sombra pela mesma
conta que posiciona os pés de cada espécie.

### B3 — A sessão não respeita "reduzir movimento" por inteiro — **baixa**

O vento e o voo param (`session_screen.dart:105-111`), mas não somem:

- a borboleta fica **congelada no ar** no centro da cena, em `_voo.value = 0`;
- as folhinhas do toque e o susto da borboleta seguem animando, embora sejam
  respostas a um gesto, o que é aceitável;
- a cutucada em `pet.dart` (`_toque.forward`) não consulta
  `Movimento.reduzido`.

Com movimento reduzido, é melhor esconder a borboleta.

### B4 — Acessibilidade das cenas novas — **baixa**

- `CenaDaMissao` não bloqueia a semântica da tela de baixo (falta
  `BlockSemantics` ou uma barreira modal), então o leitor de tela continua
  lendo a tela de resultado por trás. "Colho depois" é um `GestureDetector`
  sem `Semantics(button: true)` (`cena_da_missao.dart:264`).
- Na sessão, o `HabitatScene` leva o rótulo da **fala do humor da home**
  (`habitat.dart:503-506`), não o que está acontecendo ("Nina brincando na
  beira"). O carinho só existe como gesto, sem `customSemanticsActions` no
  bicho.

### B5 — "Ele" fixo na tela de permissões — **baixa**

`l10n_sobreposicao.dart:55`: "Deixar {n} dar um oi num cantinho da tela… **Ele**
não trava nada, não fecha nada." É o mesmo erro relatado ("Ele continua aqui"
para a Nina), numa das telas que o dono pediu para melhorar. Sugestão: "Não
trava nada, não fecha nada." O espanhol usa a mesma estrutura e convém
conferir.

### B6 — "Colher agora" e o "Colher" da tela de resultado repetem a mesma ação — **baixa** (UX)

A tela de resultado ainda mostra "MISSÕES QUE ANDARAM" com "Pronta para
colher" e "Colher", e logo depois a cena oferece o mesmo prêmio. Não paga
duas vezes: `resgataTodas` é idempotente pela chave. Mas são dois convites
seguidos. Quem colhe na tela de resultado no primeiro segundo nem vê a
festa.

### B7 — Espaçamento: padronização parcial — **baixa**

O código novo usa `Espaco` e `Raio`. Mas, nas mesmas telas, continuam:

- `+ 40` na posição da dica (`session_screen.dart:367`). Com fonte grande,
  o selo cresce e a dica pode encostar nele;
- `_QuitSheet` com 26/32/40/16/8/22 (`session_screen.dart:672-704`);
- `const SizedBox(height: 16)` ao lado do novo `Espaco.xl` em
  `home_screen.dart`;
- os 22 px da amostra de pelagem.

Não houve uma passada geral pelo app.

---

## O que está certo

- **Fila de celebração, fora do A1.** A ordem do `_Casca` (`app.dart:349-381`)
  bate com a de `celebrou()`: raiz → missão → crescimento → nível → marcos →
  chegada. Uma `missoesCumpridas` "velha", de missões já colhidas pela tela
  de missões, é limpa no próximo `celebrou()` sem engolir nada, e há teste
  para isso. "Colho depois" fecha sem pagar e o prêmio continua na tela de
  missões. **Não há pagamento duplo**, porque `resgataTodas` grava a chave
  antes de creditar, e **não há festa para missão já colhida**, porque
  `missoesACumprir` filtra por `resgatavel`. Como `missoesCumpridas` só é
  preenchida no mesmo dia da sessão, uma sessão de ontem concluída hoje não
  ganha festa.
- **"Focar de novo"** (`result_screen.dart:103-108`). `voltar()` tira o
  resultado da pilha, que volta a ser `[home]`, e `startSession()` faz de
  `session` a raiz do fluxo, pelo mesmo caminho da home. O rótulo usa
  `app.dur`, que é o mesmo valor que `startSession` usa. Uma cena de
  conquista na frente cobre a tela, então o botão não chega a ser tocado
  nesse caso.
- **Ouvintes e dispose.**
  - `_SessionScreenState.dispose` cancela os dois `Timer` e descarta os
    quatro controllers e o `ValueNotifier`. O `Future.delayed` confere
    `mounted`.
  - `PetView` troca o ouvinte de `cutucadas` em `didUpdateWidget` e o remove
    em `dispose` (`pet.dart:531-534`, `pet.dart:807`). Como os filhos
    desmontam antes do pai, o `removeListener` acontece antes de
    `_cutucadas.dispose()`.
  - `CenaDaMissao` descarta os dois controllers.
- **`shouldRepaint`.**
  - `_Borboleta`, `_Broto`, `_Raios`, `_Estouro`, `_AmostraDoItem` e
    `CenaEmMiniatura` comparam os campos certos.
  - `_LuzAmbiente` compara `LuzDaCena`, que são instâncias `const`.
  - `_Vinheta` devolve `false`, o que está correto.
  - `_FolhinhasDoToque` devolve sempre `true`, o que é aceitável porque só
    anima por cerca de 1 s depois de um toque.
  - O problema de desempenho é o descrito em M4, não um `shouldRepaint`
    errado.
- **Pronome (`l10n.dart:342-358`).** `{p}`, `{P}` e `{d}` com sentido
  numérico (`setMetaAjuda`, `resProximo`, `telaSub`, `planTrialSub`,
  `raizRiscoMarco`, `voltaCorpo`) e `{p}` como nome (`msCarinho`,
  `raizAmanhaTitulo`) passam todos por `t.fill`, **nunca** por `app.frase` ou
  `comPronome`. A troca pelo nome não os atinge. As frases que passam por
  `frase` (`sairB`, `vinculoTeto`, as falas do humor) leem bem com o nome em
  pt e es ("Nina espera a próxima", "Nina se quedó en el hábitat"). Inglês
  e chinês mantêm "they" e "它".
- **i18n.** Todas as chaves novas existem nas 4 línguas: `missaoCumprida`,
  `missoesCumpridas`, `colherAgora`, `colherDepois`, `resDeNovo`,
  `unlockPronto` e `sessaoDicaCarinho`.
- **Home.** "Já dá para levar {i}" quando há folhas suficientes, `Espaco.xl`
  antes da duração e de "Começar foco", e a faixa de 7 dias pintada pela raiz
  vinda da conta, conferida em `v9/h2-home-rolada.png` (fora o caso de M1).
- **Arte dos itens.** Os 22 ids da loja têm arte (`arte_dos_itens.dart:70-93`).
  Os acessos a peças passam por `_Pincel.operator[]`, que trava o índice, e
  um id sem arte cai nas peças cruas, nunca some. A mesma função desenha o
  habitat, a loja e a amostra da home.
- **Desistência** (`v9/r1-desistiu.png`). O bicho fica no habitat, contente,
  com a margem de terra, e a frase não usa pronome. Está claramente melhor
  que `v3`.
- **Permissões.** "Permitir" vira o botão principal só enquanto a permissão
  não foi concedida, e o contador perdeu o vermelho de alerta.

## Prioridade sugerida

1. A1 e A2: uma linha cada, mais um teste cada.
2. M1, M2 e M3.
3. M4, M5, M6 e M7.
4. Os baixos.

---

## Situação das correções (2026-10-27)

| Achado | Situação | Onde |
|---|---|---|
| A1 "Colher agora" engolia a próxima cena | Corrigido; teste falha no código antigo | `state.dart` `colheAsCumpridas`; `fim_de_sessao_test` |
| A2 nome perdia o foco a cada letra | Corrigido (`ValueKey(speciesKey)`); teste falha no código antigo | `pet_profile.dart`; `ajustes_test` |
| M1 dia congelado pintava um dia a mais | Corrigido; teste falha no código antigo | `state.dart` `ultimos7Dias`; `calendar_test` |
| M2 transbordo em 360×640 | Cena da missão rola e mantém os botões fixos; sessão mede a área útil e reduz o relógio quando aperta | `cena_da_missao.dart`, `session_screen.dart` |
| M3 pelagem sem trava | Corrigido (`pelagemDe`) | `settings_screen.dart` |
| M4 habitat reconstruído a cada quadro | O olhar segue a borboleta por `ValueNotifier` em degraus de 0,05; o habitat só reconstrói quando o degrau muda. Itens animados continuam repintando com a deriva (não tratado) | `session_screen.dart` |
| M5 pop-up só para missão da sessão | Vigia genérico no `notifyListeners`: carinho, tela e semanais acendem a cena; o descanso também | `state.dart`, `app.dart`; testes novos |
| M6 broto em cima da pedra | Broto num vaso em primeiro plano, no canto | `session_screen.dart` |
| M7 arte esticada | Escala única ancorada no pé (ou no alto, para o que pende do céu) | `habitat.dart` |
| Neve/fagulhas subindo | Fase contada para a frente (0..2) e períodos que dividem 2 | `habitat.dart`, `arte_dos_itens.dart` |
| Sombra como faixa | Elipse nos pés; nenhuma dentro d'água | `habitat.dart` |
| Borboleta parada com "reduzir movimento" | Não aparece | `session_screen.dart` |
| Leitor de tela | Cena da missão bloqueia a tela de baixo; "Colho depois" é botão; a sessão tem rótulo próprio | `cena_da_missao.dart`, `habitat.dart` |
| "Ele não trava nada" | Trocado por "Isso não trava nada" | `l10n_sobreposicao.dart` |
| "Colher" duas vezes | Botão do resultado trocado por um selo de folha | `result_screen.dart` |
| Espaçamento parcial | Passada geral (187 literais) em 6eca04e; a dica da sessão usa tokens | vários |

# Auditoria independente — Onda 1 (commit `7429ef0`)

Auditor sem vínculo com o código. Objetivo: tentar derrubar cada item.
Base: `docs/pesquisa/BRIEF.md`, `docs/pesquisa/00-SINTESE.md` (Onda 1, itens 1–4),
laudos `03-visual-estetica.md` (R-V1), `04-som.md` (#1) e `09-*.md` (R4).

## Resumo

| # | Item | Veredito | Alta | Média | Baixa |
|---|---|---|---|---|---|
| 1 | Rosto da saudade/neutro | **APROVADO COM RESSALVAS** | 0 | 3 | 4 |
| 2 | Som que não pausa a música | **APROVADO COM RESSALVAS** | 0 | 1 | 3 |
| 3 | Faixa dos últimos 7 dias | **APROVADO COM RESSALVAS** | 0 | 0 | 6 |
| 4 | Próximo item | **APROVADO COM RESSALVAS** | 0 | 0 | 3 |

Nenhum problema de severidade alta. O que o commit promete, ele faz. As
ressalvas médias são: (1a) desistir ainda deixa o bicho triste na home e no
widget, (1b) não há teste que trave a geometria do rosto, (1c) a pálpebra
da coruja é um retângulo de outra cor e (2a) não há teste do contexto de
áudio.

### Como verifiquei

- `flutter analyze`: **No issues found**.
- `flutter test --no-pub` (suíte inteira): **+1009 ~26: All tests passed!**
  (26 ignorados são os de captura/evidência com tag). Depois rodei
  `git checkout -- docs/evidence`.
- **Atenção:** durante a auditoria outro agente começou a mexer na árvore de
  trabalho (`pet.dart`, `state.dart`, `OverlayDoBaru.kt`, `quadros_do_bicho.dart`,
  Onda 2). Para isolar o que foi auditado, **as imagens foram geradas a
  partir de `git archive 7429ef0` e `git archive 7429ef0^`** em pasta
  temporária, não da árvore de trabalho. A suíte inteira rodou quando a
  árvore ainda estava limpa (só `docs/evidence` alterado no `git status`).
- Testes temporários (renderização 9 × 5 e casos de borda da faixa) foram
  escritos em `test/`, executados e **apagados**. O de renderização está
  guardado como referência em `docs/auditoria/onda-1/render_9x5_test.dart.txt`.
  As imagens foram renderizadas com `disableAnimations: true` para tirar a
  piscada aleatória do quadro: sem isso, um olho no meio de uma piscada
  parece defeito, mas não é.

---

## 1. Rosto da saudade/neutro — APROVADO COM RESSALVAS

### Critério
Nas 9 espécies, na saudade, as pontas internas das duas sobrancelhas ficam
acima das externas e as pálpebras caem para fora, espelhadas. Sem lágrima. O
pelo não escurece. Desistir não mostra cara triste.

### Evidências
- Geometria (`pet.dart:3613-3645` em `7429ef0`): `dentro = o.dx < 0 ? 1 : -1`.
  - Pálpebra: na saudade, o lado de dentro fica em `y = -0,82r` e o de fora
    em `-0,30r`, então o lado de fora fica mais baixo e cai para fora. No
    neutro, os dois lados ficam em `-0,42r` e a pálpebra sai reta.
  - Sobrancelha: ponta interna em `(dentro·0,35r, -1,85r)` e externa em
    `(-dentro·0,95r, -1,25r)`, então a interna fica 0,6r mais alta. O sinal
    de `x` vem de `dentro`, por isso os dois olhos saem espelhados.
  - As 9 espécies chamam `_olho` com pares simétricos `±x` (linhas 1603,
    1712, 1851, 2047, 2154, 2259, 2415, 2542, 2896), então a regra
    `o.dx < 0` vale para todas.
- Olho fechado: o `return` antecipado em `f > 0.94` (`pet.dart:3561`) vem
  antes da pálpebra e da sobrancelha. Sono, cochilo e piscada não mudaram,
  e as imagens confirmam isso.
- Buldogue: `sobrancelha: false` (`pet.dart:2896-2897`) continua tirando o
  traço genérico. A pálpebra espelhada agora também vale para ele, porque
  antes era a pálpebra que deixava um olho "bravo"; as sobrancelhas
  próprias dele já tinham a ponta interna erguida.
- Lágrima: `_pingo` foi removido, e as imagens não mostram lágrima.
- Pelo: `missingYou → coat`, sem escurecer (`pet.dart:1165`).
- Tela de resultado: `result_screen.dart:29` usa `won ? radiant : content`.
- **Imagens (olhadas uma a uma, rostos ampliados):**
  - `onda-1/grade-9x5-antes.png` e `onda-1/grade-9x5-depois.png`: 9 espécies
    × 5 humores (radiante, contente, neutro, sono, saudade), `Activity.idle`.
  - `onda-1/rostos-neutro-saudade-antes-depois-{1,2,3}.png`: rostos ampliados,
    antes e depois, no neutro e na saudade. No "antes", o olho esquerdo fica
    triste e o direito fica bravo nas 9 espécies. No "depois", os dois olhos
    ficam tristes e espelhados nas 9.
  - `onda-1/rostos-radiante-contente-sono-depois-{1,2,3}.png`: nenhuma regressão
    nos outros três humores.
  - `onda-1/grade-9x5-depois-pelagem-escura.png`: última pelagem de cada
    espécie.
  - `onda-1/grade-9x5-depois-atividade-da-home.png`: cada humor com a
    atividade que a home usa (`state.dart` `activity`). Neutro e sono cochilam
    de olho fechado, então **na home a pálpebra do neutro não aparece**.
  - `onda-1/zoom-coruja-neutro-saudade-pinguim-saudade.png`,
    `onda-1/zoom-pelagem-escura-buldogue-pinguim-lontra.png`.

Pelo que se vê nas imagens, a saudade lê como "pidona/triste" nas 9 espécies.
A cara de bravo sumiu.

### Problemas

**1a — Média — Desistir ainda mostra cara triste, só que fora da tela de resultado.**
`state.dart:953` mantém `desistenciaEmAberto → Mood.missingYou`. Um teste
temporário (`abandon()` e depois `mood`) devolveu `Mood.missingYou`. A pessoa
desiste, vê o bicho contente no resultado, aperta "continuar" e encontra na
home o bicho com a sobrancelha pidona e a fala "Uma sessão de {min} parou no
meio hoje". O widget da tela inicial (`widget_service.dart:226`, com
`Activity.idle`) mostra o mesmo rosto. A troca na tela de resultado chega a
deixar a sequência incoerente: contente e logo depois triste. Isso não é bug
de código. É o contrato (`docs/PRODUCT.md:30`: `missing_you` = "desistência
em aberto hoje"), e mudar o contrato é decisão do dono.
*Correção sugerida:* levar ao dono e decidir uma de duas coisas. Ou a
desistência sai da regra de `missing_you` (o humor cai para `content` ou
`neutral`, e a fala continua dizendo o fato), ou a síntese registra que "sem
cara triste" vale só para a tela de resultado. Até lá, o critério está
cumprido **parcialmente**.

**1b — Média — Não existe teste que trave a geometria.**
A síntese (Onda 1, item 1) pede "golden por espécie com as pontas internas
das duas sobrancelhas acima das externas na saudade". O R-V1 pede um "golden
test que falha se as duas sobrancelhas tiverem inclinação de mesmo sinal".
O commit não adicionou nenhum teste de rosto: `grep -rn sobrancelha test/`
não acha nada, e os únicos testes alterados foram `calendar_test` e
`carteira_proximo_test`. Uma refatoração que inverta `dentro` volta a deixar
a cara brava sem quebrar nada.
*Correção sugerida:* extrair os pontos para uma função pura
`@visibleForTesting` (por exemplo
`(Offset interna, Offset externa) sobrancelhaDaSaudade(Offset o, double r)`
e `palpebra(...)`) e testar os dois olhos de cada espécie: interna.dy <
externa.dy e x espelhado. Outra opção é um teste de pixel que mede a
inclinação do traço nas 9 espécies.

**1c — Média — Coruja: a pálpebra é um retângulo de outra cor sobre o disco facial.**
A pálpebra é um quadrilátero de `±1,05r` × até `-1,35r` pintado com `pelo`
(`pet.dart:3616-3627`). Na coruja o olho fica no disco facial, que é mais
claro que `pelo`. O resultado são dois blocos marrons retangulares, uma
"viseira" (`onda-1/zoom-coruja-neutro-saudade-pinguim-saudade.png`). No
neutro, agora reto, a coruja lê como entediada ou robótica. Na saudade a
inclinação está certa, mas o bloco continua aparecendo. O defeito já existia
antes, então não é regressão, mas o pedido mandava olhar a coruja e ela é a
pior das 9. O pinguim tem o mesmo efeito, mais brando: o olho fica na borda
entre a cabeça escura e a máscara clara.
*Correção sugerida:* recortar a pálpebra pelo círculo do olho
(`canvas.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: r)))`
antes de desenhar a pálpebra). Assim ela nunca sai do contorno do olho e a
cor do entorno deixa de importar. Isso resolve as 9 espécies de uma vez.
Alternativa: passar `corDaPalpebra` (o disco facial, no caso da coruja).

**1d — Baixa — O neutro de olho aberto lê como tédio ou meio sono.**
A pálpebra reta a `-0,42r` corta cerca de 30% do olho e passa "entediado".
Esse rosto só aparece onde o neutro tem `Activity.idle`, ou seja, no widget
da tela inicial. Na home o neutro cochila. *Correção:* subir a pálpebra do
neutro (por exemplo `-0,65r`) ou tirá-la. Um teste de 5 s com pessoas, como
manda o R-V1 3.2, decide.

**1e — Baixa — O pelo ainda escurece em sono (4%) e neutro (5%)** (`pet.dart:1163-1168`).
O R-V1 pedia remover todos exceto o radiante. Na imagem quase não se nota.
*Correção:* `coat` nos dois, ou registrar o motivo de manter.

**1f — Baixa — Os retratos da loja não foram regenerados.**
`play-store/arte/pet-*-saudade.png` ainda mostram a cara antiga, brava. O
R-V1 pede "retratos regenerados". *Correção:* rodar
`CAPTURAS=1 flutter test test/arte_loja_test.dart` e conferir.

**1g — Baixa (já existia) — Buldogue de pelagem escura: as sobrancelhas próprias quase somem**
(`onda-1/zoom-pelagem-escura-buldogue-pinguim-lontra.png`). A saudade dele
fica sustentada só pela pálpebra.

---

## 2. Som — APROVADO COM RESSALVAS

### Critério
Não pausar a música de outro app e respeitar o modo silencioso.

### Evidências (código do plugin, `audioplayers_android-5.2.1`, `audioplayers_platform_interface-7.1.1`)
- **Diagnóstico do bug antigo confirmado.** Sem contexto, o padrão é
  `usageType = USAGE_MEDIA` e `audioFocus = AUDIOFOCUS_GAIN`
  (`AudioContextAndroid.kt:29-30`; no lado Dart, `audio_context.dart:97-98`).
  `GAIN` é o pedido de foco permanente, e o Android manda o Spotify e afins
  pausarem.
- **`audioFocus: none` não pede foco.** Com `AUDIOFOCUS_NONE`, o
  `updateAudioFocusRequest` deixa o pedido nulo (`FocusManager.kt:136`
  moderno e `:90` legado). Por isso `maybeRequestAudioFocus` cai no `else` e
  chama `onGranted()` **sem** `requestAudioFocus` (`FocusManager.kt:36-46`).
  O `play()` passa por esse caminho (`WrappedPlayer.kt:223-224`) nos dois
  modos de player.
- **O modo `lowLatency` (SoundPool) respeita o uso.** O SoundPool é criado com
  `setAudioAttributes(audioContext.buildAttributes())`
  (`SoundPoolPlayer.kt:228-233`), e o contexto do `WrappedPlayer` já é o
  novo quando o `setPlayerMode` cria o player.
- **Ordem das chamadas.** `setAudioContext` vem antes do primeiro
  `setPlayerMode`/`play` (`som_service.dart:194-198`). Os métodos Dart
  esperam o mesmo `creatingCompleter`, então mesmo dois sons simultâneos
  chegam ao canal na ordem certa.
- **Silencioso.** Pelo funcionamento da plataforma (não verificado neste
  ambiente), `USAGE_ASSISTANCE_SONIFICATION` vai para o `STREAM_SYSTEM`,
  que está entre os fluxos calados pelo modo de campainha (silencioso e
  vibrar). Em telefones, esse volume costuma acompanhar o de toque.

### O que só um aparelho confirma
1. Spotify ou YouTube Music tocando, tocar no bicho, concluir uma sessão,
   resgatar uma missão: a música **não pausa e não abaixa**. Testar em
   Android 8+ (`ModernFocusManager`) e, se houver aparelho, num Android 7
   (`LegacyFocusManager`).
2. Modo silencioso e modo vibrar: nenhum som. Não perturbe: conferir também.
3. Volume: qual controle muda o som do app (toque/sistema, e não mídia) e se
   um volume de toque baixo deixa o som inaudível.
4. Fones Bluetooth: para onde o som vai.
5. Fabricantes com política própria para "sons do sistema" (Samsung One UI,
   Xiaomi): a chave "sons do sistema/toque" pode calar o app mesmo com o
   aparelho no modo normal.
6. Tablets sem telefonia, onde o `STREAM_SYSTEM` pode ser apelidado de
   `STREAM_MUSIC`: o silencioso ainda cala?

### Problemas

**2a — Média — Nenhum teste trava o contexto.**
`_contexto` é privado e `test/som_test.dart` não o verifica. A correção
inteira do item é uma constante, e se alguém tirar ou trocar essa constante,
a música volta a pausar e a suíte continua verde.
*Correção:* expor `@visibleForTesting static AudioContext get contexto` e
testar `android.audioFocus == AndroidAudioFocus.none` e
`android.usageType == AndroidUsageType.assistanceSonification`.

**2b — Baixa — Um contexto que falhe uma vez falha para sempre.**
`_player` é atribuído **antes** de `await p.setAudioContext(...)`
(`som_service.dart:194-195`). Se o `setAudioContext` lançar exceção ou
estourar o `timeout` de 2 s em `toca`, o player fica guardado sem contexto.
Todos os sons seguintes passam a usar o padrão (mídia + foco `GAIN`), ou
seja, o bug original volta, em silêncio, até o processo morrer.
*Correção:* guardar o player só depois do contexto aplicado (ou usar um flag
`_contextoAplicado` e tentar de novo).

**2c — Baixa — Efeito colateral novo, global.**
`updateAudioContext` executa `audioManager.mode = MODE_NORMAL` e
`audioManager.isSpeakerphoneOn = false` (`WrappedPlayer.kt:171-172`). Antes
do commit, `setAudioContext` nunca era chamado, então isso não acontecia.
Agora acontece no **primeiro som do processo**. Se a pessoa estiver numa
chamada de VoIP no viva-voz e tocar no bicho, a chamada pode ir para o fone
de ouvido. É raro, mas vale testar no aparelho.
*Correção:* aplicar o contexto ao armar o serviço (`arma()`, na abertura do
app) e não no meio do uso. Ou aceitar o risco e registrar a decisão.

**2d — Baixa (produto) — O volume do app saiu da mídia.**
Com o app aberto e nenhum som tocando, os botões de volume mexem na mídia.
A pessoa abaixa o volume e o som do bicho continua igual, porque segue o
volume de toque/sistema.
*Correção:* uma linha em Ajustes ("os sons seguem o volume de toque e calam
no silencioso").

(iOS: `ambient` + `mixWithOthers` está correto, mas o app é Android. Não
audito o iOS.)

---

## 3. Faixa dos últimos 7 dias — APROVADO COM RESSALVAS

### Critério
Uma raiz de N dias numa segunda mostra N marcas. Hoje vira ✓ na hora. As
letras batem com a posição. O congelamento ainda recarrega na segunda. Uma
ausência longa realinha a faixa. Os 4 idiomas.

### Evidências
- `ultimos7Dias` (`state.dart:526-535`): `i = (todayIndex - k + 7) % 7` com
  `k` de 6 a 0. A letra é `t.days[i]` e a marca é `week[i]`, então letra e
  marca saem do **mesmo** índice e não podem desalinhar.
  `k == 0 && completedToday >= 1 → present`.
- `_advanceDay` (`state.dart:2083-2123`): a segunda só recarrega
  `freezesLeft`, e a faixa não é apagada. A recarga vem **depois** de fechar
  o domingo, então o congelamento de domingo ainda é da semana anterior, o
  que está correto.
- Teste temporário (resultado real, uma linha por N; a letra é o dia da
  semana em pt, a última posição é hoje, segunda 31/08):

  ```
  N=1 marcas=1  T:empty Q:empty Q:empty S:empty S:empty D:present S:today
  N=2 marcas=2  ...                     S:present D:present S:today
  N=4 marcas=4  T:empty Q:empty Q:present S:present S:present D:present S:today
  N=6 marcas=6  T:present Q:present Q:present S:present S:present D:present S:today
  ausência > teto (45 d): S:empty S:empty D:empty S:empty T:empty Q:empty Q:today
  primeiro dia:           T:empty Q:empty Q:empty S:empty S:empty D:empty S:today
  ```
  Uma raiz de N dias (1–6) mostra N marcas. Ausência acima do teto fica com
  um único "hoje", no dia certo. `calendar_test.dart` cobre os 6 + hoje e o
  "hoje vira presente na hora".
- Outros usos de `week`: `grep` em `lib/` só acha `home_screen.dart`,
  `sequencia_screen.dart` (as duas trocadas), `row_codec.dart:237-247` e
  `app_snapshot.dart`. Os dois últimos só persistem os 7 slots por índice de
  dia da semana; o formato não mudou e o servidor só guarda as linhas
  (`supabase/migrations`). O widget da tela inicial, o compartilhamento, o
  relatório e as missões **não** leem `week`. Nada ficou com a suposição
  antiga.
- 4 idiomas: `weekT`/`seqSemana` foram trocados em pt, en, es e zh
  (`l10n.dart:695/898, 1201/1402, 1697/1900, 2194/2377`). Os textos de
  congelamento ("nesta semana", "volta a cada segunda") e das missões
  semanais continuam semanais **de propósito**, porque essas regras seguem
  de segunda a domingo. É coerente.

### Problemas

**3a — Baixa — Letras ambíguas numa janela móvel.**
O pt usa `['S','T','Q','Q','S','S','D']` (`l10n.dart:903`) e o en tem `T` e
`S` repetidos. Antes, a ordem fixa de segunda a domingo dava o contexto.
Agora uma quinta mostra "S S D S T Q Q", e não dá para saber qual "Q" é
qual. *Correção:* trocar a última letra por "Hoje / Today / Hoy / 今天", ou
usar abreviações de 3 letras (SEG, TER…).

**3b — Baixa — No primeiro dia aparecem 6 pontos de "faltou".**
Os dias antes de a pessoa começar usam o mesmo cinza `empty` de um dia
perdido. Num produto sem culpa, o primeiro dia não deveria parecer uma
semana faltada. *Correção:* um estado `antes` (sem ponto ou pontilhado)
para datas anteriores ao início do companheirismo.

**3c — Baixa — Transição.**
Snapshots gravados antes da atualização vêm com a semana zerada pela regra
antiga da segunda. Por até 6 dias, quem já usava vê buracos onde esteve
presente. O app está em teste interno, então o impacto é pequeno; vale
registrar.

**3d — Baixa (já existia, fora do commit) — Fuso ou relógio para trás.**
Teste temporário: sessão concluída na quarta e relógio voltando para terça
às 23 h. `_alinhaHoje` move "hoje" para terça e a sessão passa a contar
para a terça. Quando o relógio volta à quarta, `completedToday` é zerado e
a quarta fica sem marca. Sem outra sessão, isso vira falta (ou consome um
congelamento). *Correção:* comparar com `lastOpenDate` e não andar para trás
(tratar `today < lastOpenDate` como o mesmo dia).

**3e — Baixa (já existia, agora visível) — Congelamento gasto no meio de uma ausência.**
Numa ausência de 10 dias, a recarga de segunda é consumida na própria
segunda. A raiz vai de 0 para 1 e aparece um ❄ isolado entre dias vazios
(`S:empty D:empty S:frozen T:empty Q:empty Q:today`). Antes, o zeramento de
segunda escondia isso. *Correção:* não gastar congelamento quando `streak`
já é 0.

**3f — Baixa (já existia) — Sem rótulo de acessibilidade.**
A faixa não tem `Semantics`, e o leitor de tela lê só letras soltas.

---

## 4. Próximo item — APROVADO COM RESSALVAS

### Critério
Sugerir o mais barato que falta. Conferir se a tela considera itens que a
pessoa ainda não pode comprar (trava por estágio ou trilha) e se o texto da
tela continua coerente.

### Evidências
- `carteira.dart:138-145`: o laço pega o menor `price`, e no empate fica o
  primeiro do catálogo (`<` estrito).
- **Não existe trava na loja.** `AppState.buy` (`state.dart:1749-1750`) só
  confere `owned` e `leaves`. O filtro da loja (`shop_screen.dart:130-135`)
  mostra os 31 itens, sem condição de trilha, estágio ou espécie, e a
  assinatura não restringe nada (laudo 09, E7). Por isso o item sugerido é
  sempre comprável, desde que haja saldo. Quando houver estágios (Onda 2) ou
  itens por trilha, `proximoItem` vai precisar do mesmo filtro.
- Teste temporário: comprei em sequência sempre o sugerido pela carteira e
  comparei com `AppState.nextItem` (home) nos 31 passos. Resultado:
  **0 divergências**.
- Texto (`folhas_screen.dart:180-200`): "Faltam {x} para {i}" / "Dá para
  comprar {i} agora", coerente nos 4 idiomas (`l10n.dart:685-687, 1191-1193,
  1687-1689, 2184-2186`).

### Problemas

**4a — Baixa — Ainda há duas fontes da verdade.**
O R4 pedia "uma fonte só com `nextItem`". A home usa `AppState.nextItem`
(`state.dart:1057-1061`, com `List.sort`) e a tela de folhas usa
`Carteira.proximoItem`. Hoje dão o mesmo resultado. Mas o `List.sort` do
Dart **não é estável** acima de 32 elementos (até 32 usa ordenação por
inserção, que é estável), e o catálogo tem 31 itens com vários preços
empatados (70, 90, 120, 220, 260, 280). O R6 prevê catálogo maior. No item
33, home e folhas podem sugerir itens diferentes no empate.
*Correção:* `nextItem => Carteira(toSnapshot()).proximoItem` (ou uma função
compartilhada).

**4b — Baixa — Três regras de "alvo" na mesma economia.**
O destaque da loja (`shop_screen.dart:355-366`) sugere o **mais caro**
dentro do saldo. A tela de folhas e a home sugerem o **mais barato**. Com
300 folhas, a tela de folhas diz "Dá para comprar Chapéu de palha agora" e
a loja destaca o Barco (300). Nenhuma das duas está errada, mas o alvo
muda de tela para tela. Além disso, quando o mais barato já cabe no saldo,
a barra fica cheia e para de mostrar um objetivo. *Correção (produto):*
quando o mais barato couber, mostrar como alvo o mais barato que **ainda não
cabe** ("Faltam X para Y").

**4c — Baixa — Cobertura de teste.**
`carteira_proximo_test.dart` não testa o empate nem o aceite do R4
("`owned = {lily}` devolve `chapeu_palha` nas duas telas"). *Correção:*
testar empate de preço (vale a ordem do catálogo) e a igualdade
`nextItem == proximoItem`.

---

## Arquivos desta auditoria

- `docs/auditoria/onda-1.md` (este laudo)
- `docs/auditoria/onda-1/grade-9x5-antes.png`, `grade-9x5-depois.png`,
  `grade-9x5-depois-pelagem-escura.png`, `grade-9x5-depois-atividade-da-home.png`
- `docs/auditoria/onda-1/rostos-neutro-saudade-antes-depois-{1,2,3}.png`
  (por linha: espécie; colunas: neutro antes, neutro depois, saudade antes,
  saudade depois)
- `docs/auditoria/onda-1/rostos-radiante-contente-sono-depois-{1,2,3}.png`
- `docs/auditoria/onda-1/zoom-coruja-neutro-saudade-pinguim-saudade.png`
- `docs/auditoria/onda-1/zoom-pelagem-escura-buldogue-pinguim-lontra.png`
- `docs/auditoria/onda-1/render_9x5_test.dart.txt` (o teste temporário que
  gerou as grades, para reproduzir)

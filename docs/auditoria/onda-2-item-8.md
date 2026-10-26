# Auditoria independente — Onda 2, item 8 (commit `49194b9`)

Auditor sem participação no código. Tudo foi verificado num worktree
descartável do commit `49194b9` (`/tmp/claude-0/aud8`, já removido), não na
árvore de trabalho. Referências `arquivo:linha` são de `baru_app/` no commit
`49194b9`. Imagens geradas pela auditoria: `docs/auditoria/onda-2-item-8/`.

Lido antes: `docs/pesquisa/00-SINTESE.md` (item 8), `01-ux-retencao-duolingo.md`
§6 (6.2–6.5) e §11 U7/U11/U12, `09-economia-e-loja.md` §3.8, R1 e R3,
`05-animacao-e-tecnica.md` R7 e R8, `docs/PRODUCT.md` (§1 sem punição, §2 quatro
idiomas).

## Veredito: **REPROVADO**

Um defeito alto, regressão deste commit, de correção pequena e localizada
(7.1): reabrir o app na tela de resultado de uma sessão **concluída** mostra a
tela de desistência, com "Sem folhas desta vez". O resto funciona: a ordem com
a casca está certa e a espera não trava, colher tudo é idempotente, a compra só
celebra compra de verdade, análise e testes passam. Há, porém, várias
ressalvas médias, a principal delas o fecho (E5) que fica fora da tela.

| # | Sev. | Problema |
|---|---|---|
| 7.1 | **alta** | App reaberto na tela de resultado (processo morto, app tirado dos recentes) mostra "Baru sentiu sua falta. Sem folhas desta vez" depois de uma sessão **concluída** |
| 3.1 | média | O fecho (E5) fica abaixo da dobra numa tela 412×892: com as 4 missões tocadas de uma 1ª sessão típica, só aparece rolando |
| 3.2 | média | "Dia feito" mente em dois casos: com permissão de uso, sai com a **principal (descanso) em aberto** se as diárias sorteadas estão colhidas; sem permissão, sai depois de **qualquer** sessão, inclusive com missão pronta e não colhida logo acima (e pronta não colhida expira à meia-noite) |
| 1.1 | média | O saldo da tela de resultado fica errado depois de um marco: o marco credita 20 a 160 folhas por cima da tela, que continua mostrando `folhasAntes + ganho` (147 com saldo real de 167/192 no teste) |
| 4.1 | média | Missão de retomada: fecha com a sessão, mas não entra na E3 nem no "Colher tudo"; a aba diz "2" e a tela de Missões diz "1 para colher" |
| 6.1 | média | Concordância: "Vitórias-régias já está no habitat", "Cogumelos já está…", "Water lilies is already…", "Nenúfares ya está…" (7 de 22 objetos e cenários têm nome no plural, inclusive o item mais barato da loja) |
| 8.1 | média | Limitador de 400 ms do `SomService`: com "reduzir movimento", o som `folhas` sai no mesmo quadro do `fim` e é **sempre** engolido; tocar para adiantar nos primeiros 400 ms também o engole. O teste novo não pega isso porque o relógio falso anda 1 s por som |
| 9.1 | média | Partes do item 8 da síntese não foram entregues: 09 R1 (prévia ao vivo, queda, olhar do bicho, "Desfazer"), 09 R3 / 05 R7 na coleta de missões (folhas voando do cartão), 05 R8 (bicho no centro da celebração de nível) e U12 (um prêmio por gesto; colheita à meia-noite). O commit cita "laudo 05, R8" para a compra, mas R8 é a celebração de nível |

As baixas estão na seção "Problemas baixos".

---

## Comandos executados (no worktree de `49194b9`)

O worktree não tem `.env` (está no `.gitignore`); copiei `.env.example` para
`.env` só no worktree, sem segredo. Faltava a resolução de pacotes no worktree,
então rodei `flutter pub get --offline` antes.

```
$ flutter analyze --no-pub
No issues found! (ran in 4.9s)

$ flutter test --no-pub
01:45 +1066 ~26: All tests passed!
```

Para as imagens e os cenários escrevi três testes temporários
(`test/zz_auditoria8*_test.dart`, só no worktree, apagados junto com ele). Eles
montam o `BaruApp` inteiro (casca, navegador, celebrações) a 412×892 lógicos,
dpr 2, com e sem `FakeAccessibilityFeatures(disableAnimations: true)`, terminam
a sessão pelo caminho de verdade (`reconcileSession()` com `sessionEndsAt` no
passado, que é o caminho da volta do segundo plano) e gravam quadros nos
instantes pedidos. O `SomService` usou o relógio falso do teste
(`tester.binding.clock`) e um `tocador` que registra o som e o instante. Assim o
limitador de verdade funciona, ao contrário do teste do commit. Montei as grades
com PIL.

Cenários: (A) 1ª sessão do dia, fecha "Faça uma sessão de foco", movimento
normal; (B) igual, reduzido; (C) 2ª do dia; (D) sessão que sobe do nível 1 ao 2;
(E) sobe de nível, reduzido; (F) toque aos 300 ms; (G) arranque a frio com
sessão já vencida, no mesmo dia e com virada de dia; (H) app morto e reaberto
na tela de resultado. Mais casos lógicos: fecho com e sem permissão, retomada,
colher tudo, espera depois de sair no meio da E1 e frases da compra nos
4 idiomas.

---

## 1. A sequência no tempo (E1 → cenas → E3 → E5)

Imagens: `a-primeira-do-dia-E1-0-2400ms.png`, `a-primeira-do-dia-cenas-e-E3.png`,
`c-d-segunda-do-dia-e-troca-de-nivel.png`, `b-e-reduzir-movimento.png`.

O que confere (cenário A, ms desde a conclusão):

| t | saldo | "+N" | XP | espera |
|---|---|---|---|---|
| 0–700 | 137 | 0 → 8 | vazio | sim |
| 900 | 138 | 10 | — | sim |
| 1100 / 1300 | 140 / 144 | 10 | — | sim |
| 1600 | 147 | 10 | "+12 XP" enchendo | sim |
| 1900 | 147 | 10 | "+5 da raiz" | sim |
| 2150 | 147 | 10 | cheio | **liberada** → cena da raiz |

- As folhas saem do "+N" e chegam ao selo do saldo, em arco
  (`result_screen.dart:337-354`, `_Voo`). O saldo só começa a subir depois da
  primeira chegada (650 ms) e termina exato em `folhasAntes + ganho` (147).
- A troca de nível na barra funciona: em D, "Nível 1" com a barra quase cheia
  aos 1300 ms e "Nível 2" com a barra perto de zero aos 1600 ms
  (`d-1300ms-nivel1.png`, `d-1600ms-nivel2.png`). Depois vem a celebração de
  nível, cavada.
- Nenhum `RenderFlex overflowed` em nenhum cenário. **Mas** o fecho fica
  fora da área visível (3.1).
- A E3 anda do antes ao depois (0/1 → "Pronta para colher" + "Colher";
  25/60; 1/2; 25/300), e só depois de a última cena fechar.
- Reduzido: a E1 já nasce nos valores finais, sem voo; as cenas entram por
  cima logo no primeiro quadro; a E3 também já está no valor final. Isso
  atende "cada etapa vira cartão estático".

Divergências do storyboard 6.4 que encontrei:

- **1.1 (média) — saldo defasado depois de marco.** `ganhaXp` →
  `_colheMarcos` credita `m.recompensa.folhas` (`state.dart:376-383`) na mesma
  conclusão, mas a tela desenha `r.folhasAntes + r.folhasDaSessao`
  (`result_screen.dart:244`) e nunca relê `app.leaves`. Em A o saldo da tela
  ficou em 147 com `leaves` real 192, mesmo depois da cena "Marco alcançado"
  passar por cima (`a-marco-sobre-saldo-defasado.png`). Correção: guardar no
  `ResumoDaSessao` as folhas de marco e, depois da cena do marco, levar o selo
  a `app.leaves`. Outra saída: mostrar o selo com `app.leaves` a partir da E3.
- **Barra de XP (baixa).** Não há "segundo segmento": a barra inteira troca de
  verde para laranja (`result_screen.dart:498`, `cor: raiz > 0 ? …`). E `raiz`
  é a fração de tempo 1800–2100 ms, não o bônus. Por isso a barra fica
  **laranja também na 2ª sessão do dia, sem bônus de raiz** (C e D aos 1900 ms).
  Correção: `resumo.xpDaRaiz > 0 && raiz > 0`, ou melhor, dois segmentos.
- **Baixa.** A primeira folha sai aos 230 ms (`_chegadaDa(0) - 420`), antes de
  a contagem começar (350 ms): o quadro de 300 ms mostra "+0 folhas" com uma
  folha já voando. Durante a contagem aparece "+1 folhas" ou "+1 leaves" por um
  quadro (`reward` sem plural).
- **Baixa.** O pulso do selo é `sin(((ms-650) % 85)/85·π)`
  (`result_screen.dart:248`): escala de até 12% oscilando a ~12 Hz por 0,6 s.
  Nas fotos não chega a incomodar, mas é tremor, não pulso por chegada.
- **Baixa.** Em C, "Faça uma sessão de foco" já estava pronta desde a 1ª sessão
  (progresso 1 → 2 de alvo 1). Aparece em "MISSÕES QUE ANDARAM" e vira
  "Pronta para colher" como se tivesse fechado agora. `tocadas` compara
  `progresso`, que não é limitado ao alvo (`resumo_da_sessao.dart:58`).
  Correção: comparar `fracao` ou ignorar `antes.concluida`.

## 2. Ordem real com a casca e caminhos em que a espera trava ou some

- **Ordem: certa.** `_Casca` só desenha a celebração com
  `temCelebracaoPendente && !celebracoesEmEspera` (`app.dart:309-310`). Em
  A/C/D a espera ficou `true` até 1900 ms e caiu aos 2150 ms (`_terminouE1` →
  `liberaCelebracoes`). A E3 só começou depois da última cena
  (`result_screen.dart:223-231`). Nenhuma cena apareceu por cima da E1 no
  movimento normal.
- **Arranque a frio com a sessão vencida (G, mesmo dia):** pilha
  `[home, result]`, espera `true` até a E1 acabar, depois as cenas. OK.
- **Sair no meio da E1 (aba Missões):** a espera "some sozinha" porque o getter
  exige `screen == result` (`state.dart:256`), e as cenas aparecem na aba. OK.
  Mas `_emEspera` continua `true`. Na próxima vez que a tela de resultado abrir
  sem passar pela `_Sequencia` (uma **desistência**), qualquer conquista
  pendente fica escondida enquanto a tela de desistência estiver aberta. Isso
  foi reproduzido (`espera=true` em `AppScreen.result` com `aborted`). É
  **baixa**, porque sair da tela solta. Correção: zerar `_emEspera` em `abandon()`
  e sempre que a pilha deixar `result`.
- **Volta do segundo plano na tela de resultado:** não executei em aparelho. Pelo
  código não trava: o `AnimationController` com `vsync` só para de receber
  quadros, e na volta o primeiro quadro completa a E1 e chama
  `liberaCelebracoes`. **Não verificado em aparelho.**
- **Sessão que vira o dia** (G com `lastOpenDate` ontem): a sessão conta para
  ontem (regra anterior ao commit), `completedToday` zera ao avançar o dia, a
  E3 mostra missões **do quadro de ontem**, inclusive semanais de outro
  sorteio, e "Colher" leva a uma aba onde elas já não existem. Baixa (borda
  rara).
- **7.1 (alta) — reabrir na tela de resultado.** Ver a seção 7.

## 3. O fecho "Dia feito" e o "Próximo"

Definição do laudo (01 §6.3, E5): "Se raiz e principal do dia estão feitas →
Dia feito. Se não: o próximo passo mais perto do fim". Código
(`result_screen.dart:374-394`):
`completedToday >= 1 && (principalOk || abertas.isEmpty)` com
`principalOk = !d.disponivel || d.concluida || d.resgatada`.

- **3.1 (média) — o fecho não se vê.** Com 4 missões tocadas (o normal numa
  1ª sessão de 25 min: `um_foco`, `uma_hora`, `foco_em_dois_periodos` e a
  semanal de minutos), o texto fica em `top = 815` de 892, por baixo dos dois
  botões fixos, dentro do `SingleChildScrollView`. Isso foi medido com
  `tester.getRect` em todos os casos lógicos, e nenhuma foto de E3 o mostra
  (`a-E3-final-fecho-fora-da-tela.png`). A etapa que o laudo chama de "o fecho
  que só o Baru pode ter" exige rolar para ser lida. Correção: tirar o fecho da
  rolagem (logo acima dos botões) ou rolar até ele quando a E3 termina.
- **3.2 (média) — "Dia feito" mente.**
  - *Com permissão, principal aberta:* com as diárias sorteadas colhidas e o
    descanso **não** cumprido, sai "Dia feito. Pode largar o telefone…". O
    disjunto `|| abertas.isEmpty` contradiz a definição e o próprio comentário
    de `missoes_screen.dart` ("dizer 'tudo feito' com a principal em aberto
    seria mentira").
  - *Sem permissão de uso:* `!d.disponivel` torna `principalOk` sempre
    verdadeiro, e "Dia feito" sai depois de **qualquer** sessão, até de uma de
    10 min às 9 h. Nos cenários A, B, D, E e no 3 isso aconteceu com "Faça uma
    sessão de foco — Pronta para colher [Colher]" logo acima. Mandar largar o
    telefone com prêmio pago e não colhido é ruim, e as diárias prontas não
    colhidas **expiram à meia-noite**: a colheita automática de U12 não existe;
    `_advanceDay` não credita missões. O ramo "Próximo" fica inalcançável para
    quem não deu permissão. O ramo `resWonSub` (`:386`) é código morto.
  - Correção: "Dia feito" só sem nada pronto para colher, e
    `(principalOk && raiz)` sem o `|| abertas.isEmpty`. Sem permissão, decidir
    com o dono o que é "principal" (talvez as 3 diárias).
- **"Próximo" factível:** filtra `m.disponivel`, então missões que exigem
  permissão nunca são sugeridas. OK. Com permissão e diárias abertas sugeriu
  "Foque em 2 períodos diferentes do dia (1/2), +22 folhas", que só se cumpre em
  outro período do dia. Ordenar por `fracao` (0,5) deixou "Some 60 min" (25/60,
  faltam 35 min) para trás. É defensável. Baixa.

## 4. Colher tudo

- **Idempotência: OK.** `resgataTodas` confere a chave por missão antes de
  creditar (`state.dart:521-532`). Chamar duas vezes não paga duas vezes (teste
  do commit e o meu). Um som só (`resgate`).
- **Soma exibida = soma creditada: OK.** "+{f} folhas" é a soma de `m.folhas`
  das mesmas missões passadas a `resgataTodas`. Medi folhas +soma e XP +soma
  dos `m.xp`.
- **Sons pela toca (normal e reduzido):** `cavar`, `cavar`, `premio` e
  `resgate` ≥ 720 ms depois. Nada engolido.
- **4.1 (média) — retomada.** `missaoDeRetomada` fica fora de `missoes`
  (`state.dart:489-497`). Por isso: (a) a sessão do dia da volta fecha a
  retomada (0/1 → 1/1, +22 folhas), mas ela **não aparece na E3**
  (`ResumoDaSessao.tocadas(missoesAntes, missoes)`, `state.dart:2036/2086`);
  (b) `missoesResgataveis` conta a retomada (`state.dart:506-508`), mas a tela
  de Missões calcula `aColher` sem ela (`missoes_screen.dart:62`). Medido:
  aba "2", bloco "1 para colher", nenhum cartão "Colher tudo" com duas coisas
  prontas. Correção: incluir a retomada na lista do retrato e em `aColher`, ou
  excluí-la do distintivo, mas nos três lugares do mesmo jeito.
- O descanso pronto (a principal) também não entra no distintivo nem no
  "Colher tudo". Baixa; pode ser intencional, mas o comentário do distintivo
  diz que "prêmio parado sem ninguém ver é prêmio perdido".
- U12 pedia "cada gesto revela um prêmio, do menor para o maior". Hoje é uma
  toca com a soma. Ver 9.1.

## 5. Indicador na aba

- **Número: correto** em relação a `missoesResgataveis`. Some depois de colher:
  medido `badge depois=0` no caminho de colher tudo. Com retomada, diverge da
  tela (4.1).
- **Acessibilidade (baixa):** o rótulo vira `"Missões, 2"`
  (`common.dart:656-658`, lido na árvore de semântica). O número sai sem
  sentido para o leitor de tela. Correção: usar `mqQuantasColher`
  ("Missões, 2 para colher").

## 6. Compra celebrada

Imagem: `compra-celebrada.png` (cogumelos 150/450/1000 ms, gorro, entardecer,
reduzido).

- **Só na compra: OK.** O diálogo abre depois de `app.buy(item)` e só se o item
  passou a ser seu (`shop_screen.dart:811-817`). "Colocar/Tirar" vai por
  `alternaEquipado` e não abre nada.
- **"Já está no habitat / vestindo" é verdade:** `buy` equipa na hora
  (`state.dart:1864-1865`). Conferido nos três tipos: objeto, roupa e cenário.
- **"Ver no habitat":** fecha o diálogo e `go(home)`, que é destino e zera a
  pilha: `[home, shop]` vira `[home]`, sem modal empilhado. "Continuar na loja"
  e o voltar do sistema fecham só o diálogo (`popRoute` → `maybePop`,
  `navegacao.dart:283-287`).
- **Reduzido:** sem escala e sem folhas, valor final. OK.
- **6.1 (média) — concordância.** `compraSubObjeto` é `'{i} já está no
  habitat.'` (`l10n.dart:805`, en `:1357`, es `:1899`). Com nome no plural sai
  errado nos três idiomas com flexão: "Vitórias-régias já está no habitat",
  "Cogumelos já está…", "Vaga-lumes já está…", "Nuvens já está…", "Water
  lilies is already…", "Fireflies is…", "Nenúfares ya está…", "Setas ya
  está…". São 7 dos 22 itens que não são roupa, entre eles a vitória-régia, o
  item de 40 folhas, provavelmente a primeira compra de quase todo mundo.
  Correção: frase que não concorde com o nome ("Novo no habitat: {i}") ou
  marcar número por item.
- Baixa: `compraSubRoupa` pt "Nina já está vestindo." fica sem objeto; es
  "ya **lo** lleva puesto" usa um pronome fixo masculino e singular para todas
  as peças; en "wearing it" serve mal para óculos.
- Acessibilidade: `barrierLabel` existe ("Continuar na loja"), o título e o
  subtítulo são texto e os botões têm rótulo. Não há `liveRegion` nem
  `namesRoute`, e **não verifiquei com TalkBack** se a abertura é anunciada.

## 7. Textos nos 4 idiomas e regressões de tela

- Todas as chaves novas (`res*`, `compra*`, `mqColherTudo*`) existem em pt, en,
  es e zh, sem cair na própria chave. "Colher as {n}" só aparece com n ≥ 2, e
  as folhas de missão são ≥ 10, então o plural está correto. "Pronta para
  colher" e "Lista para recoger" concordam com missão. Problemas de gênero e
  número: 6.1 e as baixas da seção 6.
- **7.1 (alta) — regressão: reabrir na tela de resultado diz que a pessoa
  desistiu.** `toSnapshot` grava `screen: result` (`state.dart:2419-2420`) e
  `_applySnapshot` a restaura (`:2497-2498`, só `session` vira `home`). Mas
  `ultimoResumo` não é persistido, e `ResultScreen` faz
  `if (app.aborted || resumo == null) return const _Desistencia();`
  (`result_screen.dart:39`). Cenário reproduzido (H): sessão de 25 min
  concluída, +10 folhas, app tirado dos recentes ou morto pelo sistema na tela
  de resultado, reaberto. A tela mostra "**Baru sentiu sua falta. Sem folhas
  desta vez, e nada foi perdido.**" (`h-reaberto-na-tela-de-resultado.png`).
  O app afirma o contrário do que aconteceu, com o texto de desistência, no
  momento em que a pessoa voltou depois de focar. O `ResultScreen` antigo
  mostrava a versão de "ganhou" nesse caso. Correção pequena: mapear `result`
  para `home` na restauração, como já se faz com `session`, ou separar
  "desistiu" (`aborted`) de "sem resumo" e não mostrar a desistência sem
  `aborted`.
- Estatísticas removidas: o `ResultScreen` antigo mostrava "folhas" (total) e
  "presente/raiz" (streak). O total virou o selo do topo. A raiz só aparece
  pela cena na 1ª sessão do dia, e na 2ª sessão o número de dias não está mais
  na tela. Nenhuma outra tela dependia desses widgets; `presentLbl` ficou sem
  uso fora de `l10n.dart`. O teste temporário `test/zz_visual_tmp_test.dart`,
  apagado pelo commit, era uma cópia de `capturas_loja_test.dart` marcada
  `capturas` e não é perda.

## 8. Limitador de 400 ms do `SomService`

O limitador é global para tudo menos `cavar` (`som_service.dart:162-219`).
Linha do tempo medida com relógio falso:

| Cenário | Tocados (ms) | Engolido |
|---|---|---|
| A normal | fim@0, folhas@1100, raiz@3600, cavar, cavar, premio, marco | — |
| B reduzido | fim@0, raiz@400 | **folhas** |
| E reduzido + nível | fim@0, raiz@400, cavar, cavar, premio, conquista | **folhas** |
| F toque aos 300 ms | fim@0, raiz@1850 | **folhas** |
| Colher tudo (normal/reduzido) | cavar, cavar, premio, resgate | — |
| Compra | compra | — |

- **8.1 (média).** No modo reduzido, `didChangeDependencies` toca `folhas` no
  primeiro quadro da tela (`result_screen.dart:156`), dentro dos 400 ms do `fim`
  tocado em `_concluiSessao`. Acontece sempre: a E1 reduzida é muda, contra o
  "um som por etapa" do laudo. O mesmo vale para `_toque` antes de 400 ms
  (`:191-193`). O teste do commit avança o relógio 1 s a cada som
  (`fim_de_sessao_test.dart:34-38`) e por isso não vê. Correção: adiar o
  `folhas` reduzido para ≥ 400 ms depois do `fim` (ou para o fim da transição),
  ou pôr `folhas` na lista de exceções do limitador.
- `crescimento` não apareceu nos meus registros porque fechei a cena antes do
  clarão. É artefato do roteiro e não indica defeito.

## 9. Cobertura do plano (item 8 da síntese)

| Ref. | Pedido | Entregue |
|---|---|---|
| 01 U7 | retrato "antes", etapas só com novidade, cenas depois da E1, fecho | sim, com 1.1, 3.1 e 3.2; não é `PageView` (aceitável) |
| 01 U11 | barra 0/1 → 1/1 na E3 | sim; "colher onde se ganhou" virou atalho para a aba |
| 01 U12 | colher tudo, distintivo, colheita à meia-noite | colher tudo e distintivo sim; um prêmio por gesto e meia-noite **não** |
| 05 R7 | folhas voando até o saldo | na E1 sim; no resgate de missão **não** |
| 05 R8 | bicho no centro da celebração de nível | **não** (a celebração de nível continua com ícone) |
| 09 R1 | prévia ao vivo, queda com mola, olhar do bicho, "Desfazer" 5 s | parcial: cartão com escala `easeOutBack`, folhas, som e háptico; sem prévia ao vivo, sem queda, sem olhar, sem desfazer |
| 09 R3 | folhas voando e recibos na coleta | **não** |

**9.1 (média):** o que falta precisa estar registrado como pendência, e não
dado como feito. O commit atribui a compra ao "laudo 05, R8", que trata de
outra coisa.

## Problemas baixos (resumo)

- Barra de XP laranja inteira e laranja também sem raiz (seção 1).
- "+0 folhas" com folha já voando; "+1 folhas" durante a contagem (seção 1).
- Pulso do selo a ~12 Hz (seção 1).
- Missão já pronta listada como "andou" (seção 1).
- `_emEspera` fica armado depois de sair no meio da E1 e esconde conquistas na
  tela de desistência (seção 2).
- Sessão que vira o dia: E3 com missões do quadro de ontem (seção 2).
- Rótulo da aba "Missões, 2" (seção 5).
- `compraSubRoupa` pt/es/en (seção 6).
- E3 sem som nem háptico ao fechar uma missão, previstos no storyboard 6.4.
- Fora deste commit, mas exposto pelo roteiro: `_CelebracaoState.dispose`
  (`widgets/celebracao.dart:142`) cria o `AnimationController` *lazy* no
  `dispose` quando a celebração com toca é removida antes de cavar e dispara a
  asserção "deactivated widget's ancestor". Não achei caminho real que remova
  uma celebração não cavada, então registro só como observação.

## O que não verifiquei

- Nada em aparelho: volta real do segundo plano, háptico, áudio real, TalkBack.
- Fonte CJK: o `flutter_tester` não tem fonte chinesa. Os textos zh foram
  conferidos como string, não como imagem.
- Tamanhos de texto ampliados e telas menores que 412×892.
- `crescimento` na sequência sonora (seção 8).
- Sincronização com Supabase dos créditos de `resgataTodas`: só conferi que o
  `_markSync` inclui progresso, loja e sessão.

---

## Resposta às ressalvas (commit seguinte)

- **7.1 (alta) — corrigido.** `AppSnapshot.parseScreen` restaura `result` como
  `home`, como já fazia com `session`. Teste: "reabrir o app não volta para a
  tela de resultado".
- **3.1 (média) — corrigido.** O fecho fica logo abaixo da barra de XP, à
  vista sem rolar.
- **3.2 (média) — corrigido.** "Dia feito" exige raiz crescida, principal
  cumprida (ou indisponível) **e** nada pronto para colher.
- **1.1 (média) — corrigido.** O saldo anima até o saldo real (inclui o marco
  pago junto).
- **4.1 (média) — corrigido.** A missão de retomada entra no retrato da sessão
  e no "Colher tudo".
- **6.1 (média) — corrigido.** "No habitat a partir de agora: {i}." (sem
  concordância com o nome do item), nos 4 idiomas.
- **8.1 (média) — corrigido** pela isenção dos sons de cena no limitador global.
- Baixos corrigidos: barra de XP só fica laranja com bônus da raiz; rótulo de
  acessibilidade da aba "Missões, 2 para colher".
- **9.1 — pendente, dito com clareza:** compra com prévia ao vivo/"Desfazer",
  folhas voando na coleta de missões, bicho no centro da celebração de nível,
  um prêmio por gesto e colheita automática à meia-noite não foram feitos nesta
  rodada.

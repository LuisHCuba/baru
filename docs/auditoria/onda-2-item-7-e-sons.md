# Auditoria independente: Onda 2, item 7 (cena da raiz), reauditoria dos itens 5 e 6 e sons (commit `13f5ba5`)

Não participei do código. Toda a verificação foi feita num worktree
descartável do commit `13f5ba5` (`/tmp/claude-0/aud7`, já removido), fora da
árvore em que outra pessoa trabalha. As referências `arquivo:linha` apontam
para esse commit. As imagens geradas estão em
`docs/auditoria/onda-2-item-7-e-sons/`.

Antes de começar, li `docs/pesquisa/00-SINTESE.md`,
`01-ux-retencao-duolingo.md` §4.2–§5.3 (o storyboard), `04-som.md` §4–§5.6,
`docs/PRODUCT.md` e `docs/auditoria/onda-2-itens-5-6.md` (incluindo a
"Resposta às ressalvas").

**Aviso.** Não consigo ouvir. Os sons foram medidos com FFT, com o
`ffmpeg ebur128` e por análise de envelope. Timbre, agrado, cliques sutis e
a sincronia real no aparelho dependem de audição; a lista está no fim.

## Resumo

| Frente | Veredito |
|---|---|
| 1. Reauditoria dos itens 5 e 6 | **APROVADO COM RESSALVAS**: as quatro correções do item 6 e a 5.1 estão feitas e funcionam; a 5.2 ficou parcial, como a própria resposta declara |
| 2. Item 7: cena "a raiz cresceu hoje" | **REPROVADO**: um defeito alto (a cena pode prender a pessoa sem saída) e cinco médios |
| 3. Sons | **APROVADO COM RESSALVAS** para os arquivos (notas, loudness, pico, formato e reprodutibilidade, tudo certo). A integração tem dois problemas médios |

Problemas altos e médios:

| # | Sev. | Frente | Problema |
|---|---|---|---|
| R1 | **alta** | 7 | O "Continuar" sai da tela em celular de 360 dp com fonte do sistema ≥ 1,15 (no marco) ou ≥ 1,3, e com fonte 2,0 em qualquer tela. Ele é a **única** saída da cena: tocar fora só pula a animação, e o "voltar" do Android não fecha a cena. A pessoa fica presa |
| R2 | média | 7 | "Compartilhar minha raiz" (no marco) compartilha **só o texto** "Construída com Nina, no Baru.", sem o cartão: a `GlobalKey` nunca é ligada a nada |
| R3 | média | 7 | A sessão termina ontem com o app fechado. Hoje, a cena "cresceu hoje" abre com a raiz de ontem e o ✓ de **hoje** marcado sem presença hoje |
| R4 | média | 7 | Na 1ª sessão de quem está no ovo ou no ninho, a cena da raiz (que vem antes) já mostra o bicho **nascido**. Isso estraga a cena de nascimento logo a seguir |
| R5 | média | 7 | A linha "recorde" ocupa tudo: numa primeira sequência sem quebra, todo dia não-marco a partir do 2º diz "A mais funda que você já teve.". A linha "falta X para o galho" e as 5 linhas que se revezam nunca aparecem |
| R6 | média | 7 / som | Com "reduzir movimento", o som da cena nunca toca: o limitador global de 400 ms o descarta (o `fim` toca 200 ms antes). Medido no fluxo real |
| S1 | média | som | Há um único `AudioPlayer` em `lowLatency`. A raiz, aos 700 ms, cai em cima do `fim` (1,9 s). Pular a cena chama `para()` e corta o `fim`. Pela leitura do plugin, o segundo som pode até nem tocar. Só o aparelho confirma |

---

## Comandos executados (no worktree de `13f5ba5`)

```
$ flutter analyze --no-pub
No issues found! (ran in 4.7s)

$ flutter test --no-pub
01:45 +1057 ~28: All tests passed!

$ flutter build apk --debug --no-pub --dart-define=SUPABASE_ENABLED=false
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

A primeira tentativa de build falhou em `BaruWidget.kt` ("Unresolved
reference 'es'"). A causa foi o worktree, não o código: faltava o arquivo
`.flutter-plugins-dependencies`. Copiei esse arquivo da árvore principal e o
build passou, então o Kotlin novo (`QuadrosDoBicho.kt`, `MainActivity.kt`)
compila. Não havia aparelho nem emulador, e **nada nativo foi executado**.

Também criei um teste de auditoria temporário (`test/zz_aud7_test.dart`,
apagado junto com o worktree). Ele renderiza a `CenaDaRaiz` isolada a
412×892 e o `BaruApp` inteiro, e faz quatro coisas:

- injeta o relógio do teste no `SomService` (`agora`) e registra cada som
  com o seu instante;
- simula o mock do `share_plus` (só para observar o que é compartilhado);
- percorre uma matriz de transbordamento (4 idiomas × 7 telas × escalas de
  fonte de 1,0 a 2,0);
- mede o desenho dos estágios.

Para os sons, regerei os arquivos com `tool/sons/gera_sons.py` numa cópia
isolada. **Os 26 WAV saíram idênticos byte a byte** aos do commit.

---

## Frente 1: reauditoria dos itens 5 e 6

**Veredito: APROVADO COM RESSALVAS.**

### 6.1 (alta): linha d'água. **Corrigido.**
`item6-nado-filhote-jovem-adulto-pleno.png` mostra capivara, lontra,
tracajá, axolote e pinguim nadando (humor radiante) como filhote, jovem,
adulto e pleno. Pus uma linha vermelha em `PetView.linhaDaguaEm`. Em todas
as 20 figuras os olhos ficam **acima** da lâmina, e a altura relativa dos
olhos é a mesma do adulto. O teste novo (`crescimento_test.dart`, "na água o
filhote não afunda") passa.

### 6.2 (média): textos da sessão. **Corrigido.**
`acaoNoEstagio` (`pet.dart:250`) é a fonte única. Saída medida para as 9
espécies nos 4 idiomas:

- no início, o rótulo é "foco de 25 min" e a frase é "está no ovo, quase
  pronto para nascer" ou "está dormindo no ninho";
- a coruja filhote fica com "foco de 25 min" / "Nina está por aí." (não voa);
- as outras espécies filhotes mantêm "banho" ou "brincadeira".

Ressalva **baixa**: em pt e es, "quase pronto" e "casi listo" são
masculinos fixos. O app tem `Sexo` (`models.dart:120`) e `comPronome`, então
com uma companheira fêmea a frase sai "Nina está no ovo, quase pronto para
nascer.". Sugestão neutra: "está no ovo, quase na hora de nascer." / "está
en el huevo, a punto de nacer.".

### 6.3 (média): pleno com detalhe. **Corrigido, com o detalhe pequeno.**
`item6-adulto-x-pleno.png` mostra o adulto (em cima) e o pleno (embaixo).
Como a imagem tem sobreposição entre linhas, o enfeite do pleno invade a
célula de cima. Medi a área diferente entre adulto e pleno, a 200×150:

| capivara | lontra | tracajá | coruja | axolote | pinguim | gata | raposa | buldogue |
|---|---|---|---|---|---|---|---|---|
| 274 dp² (2,6 %) | 154 (1,7 %) | 122 (1,2 %) | 228 (2,3 %) | 912 (9,1 %) | 104 (1,2 %) | 197 (2,2 %) | 81 (0,8 %) | 198 (1,7 %) |

Antes eram 0 dp² em 7 espécies. Hoje todas têm diferença, mas na raposa ela
é uma joaninha de ~9×9 dp. O ADR-024 assume que o detalhe é pequeno.
Residual **baixo**: a cena ainda anuncia "AGORA: PLENO" para uma diferença
quase invisível na silhueta.

**Achado novo, baixa:** `_PetPainter.shouldRepaint` (`pet.dart:4657-4680`)
não compara `estagio`. A comparação de `roupas` também é só pelo tamanho da
coleção. Medi trocando o estágio de um `PetView` montado (mesmo elemento,
sem animação): a imagem continua a do estágio anterior, com **0 px** de
diferença. Com "reduzir movimento" não há ticker que force a repintura.
Cenário: o bicho cresce numa sessão que não muda o humor (por exemplo a 5ª
sessão do dia), e a home continua desenhando a forma antiga. *Correção:*
incluir `estagio` e o conteúdo de `roupas` no `shouldRepaint`.

### 6.4 (média): frequência da alternância. **Corrigido.**
`crescimento.dart:322-350` usa `ciclos = segundos·(u+u²)` sobre 1,38 s. A
derivada dá frequência instantânea de 1 + 2u Hz, ou seja, de 1 a 3 Hz. A
troca é por opacidade contínua (`Opacity` cruzada), sem troca seca.
Ressalva **baixa**: no fim do trecho a mistura está em ~47 % e salta para
100 % "antes" durante os 184 ms anteriores ao clarão. É um pequeno degrau.

### 5.1 (média): arquivos por leva e troca das preferências. **Corrigido.**

- Nomes novos por leva: `quadros_do_bicho.dart`, prefixo
  `baru_bicho_<FNV(chave|instante)>`.
- O Android confere que os arquivos existem antes de trocar as
  preferências. A troca é um `commit()` só, e os arquivos da leva anterior
  são apagados depois (`QuadrosDoBicho.kt:55-75`).
- `quadrosChave` evita redesenhar o que já está lá e devolve `null` quando a
  versão do app mudou (`QuadrosDoBicho.kt:85-89`).
- Os testes novos passam.

Residuais **baixos** (não reproduzidos em aparelho):

1. Se a rasterização falhar no meio, ou se `grava` recusar, os PNGs já
   escritos daquela leva ficam órfãos em `filesDir/home_widget`. Nada os
   apaga.
2. `carrega` lê os caminhos e só depois decodifica. Se o `commit` e a
   remoção dos antigos caírem entre essas duas etapas, a sobreposição que
   está surgindo cai na reserva. A janela é de milissegundos.

### 5.2 (média): quando rasterizar. **Corrigido em parte, como a resposta declara.**
A rasterização agora acontece só em `hidden` (`app.dart:159`). Faltam o
adiamento, o filtro por `canDrawOverlays` e a rasterização no início da
sessão. A justificativa da resposta é plausível, mas não foi verificada em
aparelho.

---

## Frente 2: item 7, cena "a raiz cresceu hoje"

**Veredito: REPROVADO.** O esqueleto do storyboard está lá, com os quadros
nos tempos certos:

| Momento | O que acontece |
|---|---|
| 0–400 ms | entrada |
| 400–550 ms | a gota se forma |
| 550–750 ms | a gota cai |
| 750 ms | clarão de 24 px |
| 750–1350 ms | a raiz cresce |
| 1150–1400 ms | odômetro com `easeOutBack`, de tinta para acento, pulso de 1,15 |
| 1200–1650 ms | pulinho e 7 folhinhas |
| 1450–2050 ms | texto e ✓ |
| a partir de 2000 ms | botão |

Os hápticos caem em 750, 850, 1000, 1150, 1200 e 1750 ms. Pular só vale a
partir de 600 ms. O som é disparado por limiar do controlador, e a ordem na
fila é raiz → crescimento → nível → marcos → chegada (testado).

Os critérios de aceite do laudo que o teste do commit cobre passam: N aos
1100 ms, N+1 aos 1500 ms, som único e variante de marco. O que reprova são
os defeitos abaixo.

Quadros renderizados (412×892):

| Arquivo | O que mostra |
|---|---|
| `cena-comum-5-dias.png` | 16 instantes de 0 a 2400 ms |
| `cena-marco-7-dias.png` | 16 instantes de 0 a 3300 ms |
| `cena-1-dia-e-reduzir-movimento.png` | raiz de 1 dia; 5 dias e 7 dias com "reduzir movimento" |

### R1 (ALTA): o "Continuar" sai da tela e a cena não tem outra saída
A coluna de baixo é um `Expanded(flex: 36)` com conteúdo fixo
(`cena_da_raiz.dart:242-301`, `Column` em `:246`). Ela não rola nem encolhe.

Transbordamento medido (`FlutterError`, sem contar barra de status e de
navegação, que no aparelho tiram ainda mais espaço):

| Tela | Fonte 1,0 | 1,15 | 1,3 | 1,5 | 2,0 |
|---|---|---|---|---|---|
| 412×892 | — | — | — | — | marco 44 px |
| 412×915 | — | — | — | — | marco 36 px |
| 393×851 | — | — | — | marco 12 px | 11 px; marco 59 px |
| 360×800 | — | — | marco 9 px | marco 30 px | 94 px; marco 77 px (es 189) |
| 360×640 | marco 16 px (es 39) | marco 54 px | 19 px; marco 67 px | 40; marco 88 px | 152 px; marco 135 px (es 247) |
| 320×568 | marco 65 px | — | 45; marco 93 px | — | 178; marco 273 px |

(— = sem transbordamento. Em zh os números são menores, mas o
`flutter_tester` não tem fonte CJK.)

Em `transbordamento-continuar-escondido.png` (360×640 com fonte 1,3 no
marco, e outros casos) o botão fica **inteiro** abaixo da borda.

A pior parte é que esse botão é a única saída:

- o `GestureDetector` da cena só pula para o fim (`:152-158`);
- `popRoute` (`navegacao.dart:288-292`) não conhece celebração;
- `raizACelebrar` vive em memória enquanto o processo vive.

Diferente da `Celebracao`, a cena da raiz não fecha sozinha. Quem usa fonte
grande (público comum em quem quer reduzir tela) e celular de 360 dp fica
com o app tomado pela cena até o sistema matar o processo.

*Correção:* pôr a parte de baixo num `SingleChildScrollView` (ou usar
`flex` e `FittedBox` no título), garantir o botão fora da área que pode
transbordar e deixar o "voltar" e o toque depois do fim fecharem a cena. A
`Celebracao` já fecha sozinha. Travar com teste em 360×640 e fonte 1,3,
pt/es, marco.

### R2 (média): compartilhar no marco envia só texto
`BotaoDeCompartilharRaizRaizState._borda` (`cartao_da_raiz.dart:167`) é
passada a `HabitatShare.share`, mas não está ligada a widget nenhum: o
`CartaoDaRaiz` (`:202`) usa a própria `Key` constante. Por isso
`capturePng` devolve `null` (`habitat_share.dart:12-13`) e o compartilhamento
cai no texto.

Medido com o canal do `share_plus` simulado: a chamada recebida foi
`{text: Construída com Nina, no Baru.}`, sem `paths` e sem erro. A frase
sozinha não diz o número de dias.

O defeito veio da `sequencia_screen.dart` (o código foi movido), mas agora
também está no marco da cena, que o storyboard descreve como "gera o
`CartaoDaRaiz` existente". *Correção:* `CartaoDaRaiz(key: _borda, …)`, ou
envolver o cartão num `RepaintBoundary(key: _borda)`. Testar que `paths`
chega ao canal.

### R3 (média): a sessão de ontem é comemorada hoje, com ✓ falso
Tanto no construtor (`state.dart:52-53`) quanto na volta ao app
(`app.dart:170-171`), `_restauraSessao`/`reconcileSession` roda **antes** de
`applyCalendar`. Uma sessão que terminou ontem com o app fechado dispara
`raizACelebrar` (`state.dart:2016`), e o comentário de `:247-254` diz que
isso não deveria acontecer ("Gravar isto para o dia seguinte seria
comemorar ontem").

Cenário medido: sessão das 22:30 às 22:55 de ontem, app aberto hoje. O
resultado foi `raizACelebrar=5`, `completedToday=0` e
`ultimos7=[…, present, today]`. Mesmo assim, a cena desenha o ✓ laranja em
**hoje** (`_Faixa` força o último ponto, `cena_da_raiz.dart:638-652`).

Na mesma tela (`sessao-de-ontem-cena-hoje.png`):

- as abas ficam visíveis e tocáveis por baixo da cena;
- o SnackBar "Ontem você fechou abaixo da meta" cobre o "Continuar" por
  ~5 s.

*Correção:* acender `raizACelebrar` só quando a sessão concluída é de hoje
(`dateOnly(em) == dateOnly(agora)`). Se a decisão for comemorar a presença
de ontem na abertura, a faixa precisa marcar o dia certo e o título não
pode dizer "hoje".

### R4 (média): a cena da raiz estraga o nascimento
A fila põe a raiz antes do crescimento (`state.dart:287-295`), mas o
`PetView` da cena usa `app.estagio` (`cena_da_raiz.dart:366`), que já é o
estágio novo.

Cenário medido (`fluxo-ovo-raiz-mostra-filhote.png`): coruja no ovo, 1ª
sessão concluída. A cena da raiz mostra a corujinha **já nascida**. A
`CenaDoCrescimento` vem depois para revelar o nascimento, que o ADR-024
chama de "o 'aha' do começo".

*Correção:* com `cresceuSemCelebrar`, a cena da raiz deve desenhar
`app.estagioJaVisto`.

### R5 (média): "recorde" monopoliza a linha do dia
`state.dart:2013` marca recorde sempre que `streak+1 > melhorSequencia`,
e `linhaDaRaiz` dá prioridade máxima ao recorde. Numa primeira sequência
sem quebra, todo dia é recorde. Medido de 16 dias seguidos:

| Dia | Linha |
|---|---|
| 1 | "Faltam 2 dias para o próximo galho." |
| 2, 4, 5, 6, 8–13, 15, 16 | "A mais funda que você já teve." |
| 3, 7, 14 | "Galho novo!" |

A linha de meta próxima, que o próprio storyboard põe em 2º lugar pelo
efeito de meta próxima, e as 5 linhas que se revezam não aparecem no
primeiro mês de quem nunca quebrou. Quem só usa a cena nesse período vê a
mesma frase todo dia.

*Correção:* recorde só no dia em que a sequência **ultrapassa** uma melhor
marca de uma sequência anterior (por exemplo, guardar o recorde no início
da sequência atual), ou só a cada N dias. Também seria bom a linha de galho
vencer o recorde quando falta 1 dia.

### R6 (média): com "reduzir movimento" o som da cena some
Ver Frente 3. Medido no app inteiro com acessibilidade simulada:
`sons=[inicio@0ms, fim@2000ms]`, sem a raiz. Sem "reduzir movimento", a
sequência foi `inicio@0, fim@2000, raiz@2750`.

### Baixos

- **R7: a raiz quase não cresce depois de algumas semanas.** O comprimento
  satura (`1-exp(-d/26)`). Entre N e N+1, a ponta desce cerca de 12 px aos 5
  dias (com o zoom de 1,8), cerca de 3 px aos 30 e cerca de 1 px aos 60. O
  Q3 ("a raiz alonga") passa a ser carregado só pela gota e pelo contador.
  Considerar um zoom na ponta, ou destacar o segmento novo.
- **R8: "reduzir movimento".**
  - O esmaecer de 0 a 200 ms mostra o quadro **inicial** (terra fora do
    lugar, contador em N−1) e corta seco para o final aos 200 ms. O laudo
    pede esmaecer **para** o quadro final.
  - Na variante reduzida, a gota e o rastro ficam pintados na ponta durante
    todo o quadro final: `gotaForma = 1` e `clarao = 0` em `:193-196`, e o
    `_Gota` pinta quando `clarao == 0`. Ver `red5-2400` e `red7-3300`.
  - Toca o arquivo inteiro (gota, toc, arpejo) e não só o "plim".
- **R9: raiz de 1 dia.**
  - O rótulo vem do número final, então durante 0–1250 ms aparece "0 dia" /
    "0 day" (`:235-237`).
  - A raiz passa de semente para 30 % do comprimento num único quadro
    (pintor: `fundo = … 0.30 + …` assim que `exatos > 0`).
  - O resto está certo: "Raiz de 1 dia", "Faltam 2 dias para o próximo
    galho", sem recorde e ✓ de hoje.
- **R10: a variante de marco ficou incompleta.** O galho brota junto com o
  alongamento (750–1350 ms), e não depois. Entre 1350 e 2350 ms só há o
  tremor de 3 px. Faltam a árvore-semente na grama, o adereço do bicho e o
  háptico de "subida".
- **R11: diferenças do storyboard.**
  - O ponto de hoje não começa como anel: começa invisível (escala 0).
  - Faltam os grãos de terra.
  - O gesto de alegria é genérico (o mesmo pulinho em todas as espécies).
  - Falta o golden do quadro final para as 9 espécies.
  - Em telas baixas (320×568) o bicho é cortado no topo do céu, que ocupa
    24 % da altura.
- **R12: higiene.**
  - `test/zz_visual_tmp_test.dart` entrou no commit. É uma cópia temporária
    do teste de capturas, com casos da raiz.
  - Nome `BotaoDeCompartilharRaizRaizState`.
  - O odômetro mantém os dois números na árvore. Não verifiquei com
    TalkBack se lê "4 5".

### O que está certo e não foi citado acima

- Os textos estão nos 4 idiomas, com plural (`streakLabel` e
  `raizDia/DiasRotulo`) e gênero feminino da raiz (pt/es "Mais funda", "La
  más profunda").
- Nenhuma palavra da lista proibida do laudo 01 §4.3 aparece.
- `l10n_test` passa.
- A cena só acende na 1ª sessão do dia e não na 2ª (testado).
- "Apagar dados" zera o estado da cena.
- Pular antes da gota não deixa som atrasado.
- O caminho "sessão concluída com o app fechado, no **mesmo** dia" mostra a
  cena na abertura, antes da chegada.
- A cena se perde só se o processo morrer entre a conclusão e a cena. Isso é
  declarado e aceitável.

---

## Frente 3: sons

**Veredito: APROVADO COM RESSALVAS.**

### Medições (todas por mim, nos 26 arquivos do commit)

Script de FFT, `ffmpeg -af apad=pad_dur=0.5,ebur128=peak=true+sample`, e
análise de início e fim:

- **Formato:** 26/26 em WAV PCM 16 bits, **mono, 48 000 Hz**.
- **Pico:** o maior é **−1,3 dBTP** (`crescimento`). Todos ficam ≤ −1 dBTP.
  O true peak difere do sample peak em no máximo 0,1 dB.
- **Loudness momentânea máxima** contra o alvo do laudo §4.4:

| Som | LUFS-M | Alvo do laudo | | Som | LUFS-M | Alvo |
|---|---|---|---|---|---|---|
| fim | −14,0 | −14 (herói) | | resgate_1..3 | −16,0 | −16 |
| conquista (nível) | −13,0 | −13 (+1) | | premio | −16,0 | −16 |
| marco | −14,0 | −14 | | raiz | −16,0 | −16 (2b) |
| crescimento | −13,0 | −13/−14 | | raiz_marco | −14,0 | herói |
| inicio | −20,0 | −20 (−6) | | folhas, compra | −19,0 | −19 |
| desistencia | −24,0 | −24 (−10) | | cavar_1..4 | −24,0 | −24 |
| carinho_1..3 | −18,0 | −18 (voz) | | toque_1..4, chegada | −19,0 | −18 (voz, −4) |

  `toque` e `chegada` ficam 1 dB abaixo do nível "voz" do laudo, dentro da
  tolerância de ±1 LU (§5.6 item 4). O script os pôs, de propósito, no
  nível primário.
- **Notas (picos espectrais entre 150 e 2000 Hz, até −20 dB do maior):**
  todas as fundamentais estão em Fá maior pentatônica, com erro ≤ 1 cent.
  As notas de cada som:

| Som | Notas |
|---|---|
| fim | A4 C5 F5 A5 C6 |
| conquista | F3 A4 C5 F5 A5 F6 |
| marco | A4 C5 F5 A5 C6 D6 |
| raiz | F3 C4 F4 F5 F6 |
| desistencia | C5 → A4 |
| toque | F5, A5, C6, D6 |
| carinho | F5+A5, A5+C6, C6+F6 |
| chegada | F5 A5 |
| compra | G5 C6 |
| folhas | C6 F6 |
| resgate | C5-F5-A5, A4-C5-F5, F5-A5-C6 |
| inicio | F4 |

  Ficam fora da escala, por desenho:
  - `cavar` (ruído de terra, atonal);
  - os parciais inarmônicos da kalimba (5,93×) e da marimba (9,9×);
  - o glissando da gota, que termina em ~1500 Hz na raiz e ~1900 Hz nos
    demais. Ele não tem altura definida, mas a "água" do laudo não é nota.
- **Início e fim:**
  - o 1º sample fica ≤ 0,011 (−39 dBFS, `crescimento`) e os demais ≤ 0,005;
  - o último sample é 0, com fade de 20 ms;
  - o ataque fica em ≤ 3 ms, exceto `premio` (14 ms, terra) e `inicio` (o
    sopro vem antes da nota aos 312 ms, de propósito).
- **Sincronia do arquivo da raiz:** `fecha()` corta o silêncio inicial, e o
  arquivo começa na gota.

| Evento | No arquivo | Na cena (+700 ms) | Storyboard |
|---|---|---|---|
| gota | 0 ms | 700 ms | 700 ms |
| toc de madeira | 50 ms | 750 ms | 750 ms |
| F3 | 150 ms | 850 ms | 850 ms |
| C4 | 300 ms | 1000 ms | 1000 ms |
| F4 | 450 ms | 1150 ms | 1150 ms |
| plim F5 | 500 ms | 1200 ms | 1200 ms |

  Os inícios de F3, C4, F4 e F5 foram medidos por envelope em banda
  (150 / 298 / 449 / 500 ms). Gota e toc saem da receita
  (`gera_sons.py:282-283`); o toc não dá para separar da gota por banda, e
  o detector achou 9 ms. No `raiz_marco`, o motivo A4–C5–F5 entra em
  798/918/1038 ms do arquivo, ou 1500/1620/1740 ms da cena, dentro do bloco
  de marco. Espectrogramas: `espectrograma-raiz.png` e
  `espectrograma-raiz-marco.png`.

### Usos novos (conferidos no código)

| Uso | Onde |
|---|---|
| compra | `state.dart:1837` |
| desistência | `state.dart:2126`; a ação da notificação abre o app (`showsUserInterface: true`), então não soa por cima de outro app |
| início | `state.dart:1892` |
| chegada | `app.dart:366`, deixou de usar `conquista` |
| marco da trilha | `app.dart:378` |
| crescimento | `crescimento.dart:232` |
| raiz | `cena_da_raiz.dart:130`, 145 |

O volume é 1 (`som_service.dart:278-281`). A variação é sorteada
(`:279`). `para()` existe (`:135-139`).

### R6 / limitador global: sequências reais

O limitador (`som_service.dart:162`, `:199-211`) descarta qualquer som que
não seja `cavar` se ele vier menos de 400 ms depois do anterior.

| Sequência | Resultado |
|---|---|
| Fim da sessão → cena da raiz (normal) | `fim`@0, `raiz`@+750 ms: passa (medido) |
| Fim da sessão → cena da raiz (**reduzir movimento**) | `raiz` aos +200 ms: **descartado** (medido: só `inicio` e `fim` tocam) |
| Raiz → crescimento → nível | separados por toque em "Continuar" e pela cena (o `crescimento` toca aos 3,2 s da cena): passa |
| Compra | só `compra`: passa |
| Cavar ×2 → prêmio → nível/marco | `cavar` é exceção; o `premio` sai na 3ª cavada e a conquista ~720 ms depois: passa |
| Toque no bicho → afago completo < 400 ms | o `carinho` é engolido (comportamento antigo, documentado) |

*Correção do R6:* tirar a raiz do limitador global (limite por som, como o
laudo §4.5 e §5.5 passo 2 pedem), ou tocar o som reduzido aos ≥ 400 ms.

### S1 (média): um player só

`_tocaDeVerdade` usa um único `AudioPlayer` em `PlayerMode.lowLatency`
(`som_service.dart:258-282`). Pela documentação do `audioplayers`, um
player toca um som por vez. Consequências:

- a raiz, aos 700 ms, toma o lugar do `fim` (1,9 s de duração);
- pular a cena (`para()`, `cena_da_raiz.dart:156`) entre 600 e 1900 ms
  corta o `fim`;
- o `marco` corta a cauda do `premio` (1,3 s) aos ~720 ms.

Lendo `audioplayers_android-5.2.1`:

- `SoundPoolPlayer.reset()` é um TODO vazio, e o `streamId` antigo não é
  limpo ao trocar a fonte;
- `WrappedPlayer.play()` não faz nada se `playing` já é `true`;
- o SoundPool não tem evento de fim.

Por esse caminho, um segundo som no mesmo player pode **nem tocar**.
**Não consegui confirmar.** Isso exige aparelho e afeta também sons da
Onda 1.

*Correção:* o pool do laudo §5.5 passo 2 (≥ 3 players pré-carregados com
`setSource`, round-robin) ou um player por som. Verificar em aparelho com o log do plugin
ligado (`AudioLogger.logLevel = AudioLogLevel.info`).

### Baixos (sons)

- **S2: a sincronia é implícita.**
  - O comentário de `gera_sons.py:276-279` diz que o arquivo "começa no
    instante em que a gota se forma (400 ms)". Na verdade começa na gota
    (700 ms), porque `fecha()` (`:116-124`) corta o silêncio inicial.
    Mudar o limiar de corte desalinha a cena sem nenhum teste acusar.
  - Não há pré-carga: o 1º `play` de cada arquivo no processo faz
    `soundPool.load` assíncrono, e a raiz toca uma vez por dia, ou seja,
    quase sempre "fria". O atraso real precisa de medição em aparelho.
- **S3: cortes secos de camada dentro dos arquivos.** Os geradores truncam
  cada nota em `d` sem fade. Achei degraus em banda larga (passa-alta de
  10 kHz):

| Arquivo | Degraus (instante, nível) |
|---|---|
| `raiz` | 1302 ms −48 dBFS e 1652 ms −51 dBFS (fim do C4 e do F4) |
| `premio` | 829 ms −46 e 1269 ms −44 dBFS |
| `crescimento` | 1020 ms −46 dBFS |
| `conquista` | 1640 ms −49 dBFS |
| `carinho_*` | ~900 ms −48 a −50 dBFS |
| `resgate_*` | 600 / 690 ms −51 a −53 dBFS |

  Ficam 30 a 45 dB abaixo do pico do próprio som. Só a audição diz se viram
  "tique". *Correção:* fade de 5–10 ms no fim de cada camada em `mix()`, ou
  durações até o envelope cair a −60 dB.
- **S4: variação.** O sorteio é sem memória (`:279`). O `toque` repete a
  mesma tomada em 25 % das vezes, e não há jitter de altura. O laudo §4.1.7
  e §5.6.5 pedem nunca repetir a última.
- **S5: higiene.**
  - `folhas.wav` é gerado e empacotado, mas nada o toca (fica para o item
    8).
  - `AppState.anunciaCelebracao` não é chamado.
  - O cabeçalho de `som_service.dart:3-5` ("cada som dura menos de 0,6 s")
    não vale mais: os sons vão de 0,3 a 2,6 s.

---

## O que só o aparelho (e o ouvido) confirma

- Se o 2º som no mesmo player toca, corta o anterior ou some (S1). Isso
  decide se a raiz soa depois do `fim`.
- Latência real do 1º `play` da raiz, comparada com a animação aos 700 ms
  (gravação de tela com áudio).
- Timbre da marimba em F3/C4 em alto-falante de celular. O F3 de 175 Hz
  quase não sai, e só o parcial de 4× (F5) carrega a nota.
- Se os degraus de S3 e o degrau inicial do `crescimento` (−39 dBFS) se
  ouvem.
- Hierarquia percebida (fim > raiz > compra > desistência), música de fundo
  sem pausa e modo silencioso.
- Hápticos (`HapticFeedback.*`) e se o ritmo deles casa com o som.
- O item 5 inteiro do lado nativo: sobreposição com os quadros novos,
  remoção dos antigos e `renderFlutterWidget` em `hidden`.
- Textos em chinês na tela: o ambiente de teste não tem fonte CJK.

## Arquivos de evidência

`docs/auditoria/onda-2-item-7-e-sons/`:

| Arquivo | Conteúdo |
|---|---|
| `cena-comum-5-dias.png` | 16 instantes de 0 a 2400 ms (capivara adulta) |
| `cena-marco-7-dias.png` | 16 instantes de 0 a 3300 ms (raposa) |
| `cena-1-dia-e-reduzir-movimento.png` | raiz de 1 dia (corujinha); 5 e 7 dias com "reduzir movimento" (R8, R9) |
| `transbordamento-continuar-escondido.png` | R1 |
| `fluxo-ovo-raiz-mostra-filhote.png` | R4, app inteiro |
| `sessao-de-ontem-cena-hoje.png` | R3, app inteiro |
| `item6-nado-filhote-jovem-adulto-pleno.png` | 6.1, com a linha d'água em vermelho |
| `item6-adulto-x-pleno.png` | 6.3 |
| `espectrograma-raiz.png`, `espectrograma-raiz-marco.png` | sincronia do som da raiz |

Na faixa dos 7 dias das imagens da cena isolada, os dias anteriores aparecem
vazios porque o snapshot de teste usa `freshWeek`. **Não é defeito do app.**

---

## Resposta às ressalvas (commit seguinte)

- **R1 (alta) — corrigido.** O "voltar" do sistema fecha qualquer cena de
  conquista (`AppState.voltar`), e a parte de baixo da cena da raiz rola.
- **R2 (média) — corrigido.** O cartão da raiz agora fica dentro do
  `RepaintBoundary` com a chave que a captura procura; o defeito vinha da tela
  da sequência, de antes desta onda.
- **R3 (média) — corrigido.** A cena só acende se a sessão terminou hoje.
- **R4 (média) — corrigido.** O bicho da cena da raiz é o do estágio já visto;
  a forma nova fica para a cena do crescimento.
- **R5 (média) — corrigido.** `recordeAnterior` guarda a melhor raiz que
  quebrou; "recorde" só no dia em que a atual a passa. A primeira raiz não é
  recorde todo dia.
- **R6 e S1 (médias) — corrigidos.** Sons de cena não esperam o limitador global
  (só o limite por som), e o serviço tem três vozes em rodízio, então um som
  não corta o anterior.
- Baixos corrigidos: rótulo "0 dias/1 dia" acompanha o número à vista; sem gota
  pintada com movimento reduzido; "quase pronto" virou "Falta pouco para
  nascer" (sem gênero); `zz_visual_tmp_test.dart` removido.
- Sem mudança: redesenho quando só o estágio muda com "reduzir movimento";
  marco sem árvore-semente/adereço; cortes de −44 a −56 dBFS nos arquivos
  (precisa de audição).

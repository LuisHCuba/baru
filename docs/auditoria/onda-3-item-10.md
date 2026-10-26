# Auditoria independente — Onda 3, item 10 (commit `8bc1258`)

Auditor sem participação no código. Tudo foi verificado em worktrees
descartáveis: `/tmp/aud10` (commit `8bc1258`) e `/tmp/aud10_antes` (commit
`9112074`, o anterior), ambos removidos ao fim. Não houve commit nem push, e a
árvore de trabalho principal não foi tocada. Referências `arquivo:linha` são
de `baru_app/` no commit `8bc1258`. As imagens e os dados da auditoria estão em
`docs/auditoria/onda-3-item-10/`.

Lido antes: ADR-027 (`docs/DECISIONS.md`) e `docs/pesquisa/03-visual-estetica.md`
§1.4–1.7, §4.4, §4.5, §4.8, R-V2, R-V3 e R-V4.

## Veredito: **APROVADO COM RESSALVAS**

O núcleo do item está entregue e funciona. A folha agora tem um desenho e uma
cor. O laranja saiu da interface e ficou só na raiz e na arte. O texto
secundário passou a `tinta700` opaco (5,2–5,9:1 sobre todos os fundos do app).
`PrimaryButton`, `GhostButton` e `_BotaoCompacto` sumiram, e o `BotaoBaru`
afunda, cancela ao arrastar para fora, tem háptico e respeita "reduzir
movimento". **A arte do bicho e do cenário ficou idêntica pixel a pixel.**
`flutter analyze` está limpo e os 1120 testes passam.

Não achei nenhum defeito alto. Achei, porém, sete ressalvas médias. Duas são
regressões deste commit: o rótulo cortado em botões que antes cabiam e o
contraste pior na celebração de nível. As outras cinco são partes do R-V2/R-V3
que o commit não entregou, embora o ADR dê o item como feito:

- a raiz continua **verde** no cartão de compartilhar e na cena da raiz;
- o `GlifoXp` existe mas não é usado em lugar nenhum;
- o glifo da raiz não lê como raiz;
- o selo "Seu" da loja ainda reprova no contraste;
- os testes novos deixam passar recaídas óbvias.

| # | Sev. | Problema |
|---|---|---|
| 1 | média | Regressão: o `BotaoBaru` ganhou 20 dp de padding lateral e peso w800, então rótulos que cabiam agora saem cortados com "…". "Teste ativo — contin…" no paywall (pt/en a 320 dp, es a 360 dp, com a fonte do sistema no máximo que o app aceita) e "Compartilhar o h…" no resultado |
| 2 | média | A raiz continua **verde** no cartão de compartilhar (número e desenho) e na cena da raiz. É exatamente o caso que o laudo 03 §1.4 aponta e que o R-V2 pede para corrigir ("uma raiz, um glifo, uma cor") |
| 3 | média | `GlifoXp` foi criado mas não tem nenhum uso em `lib/`: "+10 XP" continua só texto. O item 1 ("glifos folha, raiz, XP") foi entregue pela metade |
| 4 | média | O glifo da raiz, de 12 a 18 px, não lê como raiz: lê como um bonequinho de braços abertos, um "X" ou uma mandrágora |
| 5 | média | Celebração: o rótulo do prêmio na toca de nível é `folha600` sobre o véu escuro (**1,45:1**; antes era 1,86:1). O ícone creme sobre o círculo `mel400` do marco dá **1,66:1** (antes 2,33:1). As duas são regressões |
| 6 | média | O selo "Seu" da loja (texto creme sobre tinta a 55% em cima da miniatura) fica em 3,0–3,8:1, abaixo de 4,5:1. A linha foi mexida pelo commit e o selo continua translúcido |
| 7 | média | Os testes novos não pegam: texto `mel400` numa tela, `Cores.tinta.withValues(alpha: 0.45)` como texto, barra "acima da meta" de volta ao laranja, `Icons.energy_savings_leaf` laranja no lugar da folha, nem a retirada do `onTapCancel`. Testei cada uma dessas mudanças e todos os testes novos continuaram passando |
| 8 | baixa | O "hoje" da semana continua com cores diferentes conforme a tela: anel verde na home, anel `raiz500` em "Sua raiz", e `raiz600`/verde/azul `#9CC3D5` na faixa da cena da raiz. O laudo 03 §1.4 aponta exatamente isso |
| 9 | baixa | A barra de XP do resultado fica inteira `raiz500` quando entra o bônus da raiz: 2,55:1 contra o trilho e contra a regra "toda barra é verde" do ADR |
| 10 | baixa | Botão compacto de 44 dp ("Colher" no resultado) e de 46 dp (missões): abaixo de `Toque.minimo` = 48 e dos 48 dp da própria especificação 4.8 |
| 11 | baixa | `dispersivo` e `alerta` são o mesmo hex (`#A8433A`): a categoria "Dispersivo" fica com a cor de erro. No simulador de deuteranopia, dispersivo × produtivo dá 1,16:1 (antes 1,77:1) |
| 12 | baixa | Mel fora de recompensa: o selo "MELHOR VALOR" do paywall é `mel400` |
| 13 | baixa | Restam três textos em tinta translúcida a 70% (passam por pouco, 4,5–4,75:1, mas contrariam a regra do ADR) e textos informativos em `tinta500` (3,4–4,3:1): o "Faltam N" da pílula desabilitada, os degraus travados da trilha e o "Entrando…" do botão desabilitado |
| 14 | baixa | Anéis de progresso dos nós da trilha: `mel600` sobre o trilho dá 2,0:1 e `primariaClara` dá 2,4:1, ambos abaixo de 3:1 (o segundo já vinha de antes) |
| 15 | baixa | A ação de toque do leitor de tela chama `aoTocar` sem háptico. O comportamento é aceitável, mas não está documentado nem testado |

---

## Comandos executados

```
git -C /home/user/baru worktree add /tmp/aud10 8bc1258
git -C /home/user/baru worktree add /tmp/aud10_antes 9112074
export PATH=/opt/flutter/bin:$PATH
flutter pub get --offline                 # ok nos dois worktrees
touch .env                                # vazio, só no worktree (o pubspec declara o asset)
flutter analyze --no-pub                  # 8bc1258: só o aviso do .env ausente; com .env: "No issues found!"
flutter test --no-pub                     # 8bc1258: "+1120 ~26: All tests passed!"
```

Também escrevi testes temporários, só dentro do worktree e apagados com ele:

- `aud_capturas_test.dart`: cópia do harness de capturas com a pasta de
  saída, a escala de fonte, a largura e um filtro configuráveis, e telas a
  mais (resultado, desistência, onboarding 0–4, paywall, conta,
  sobreposição, confirmação de desistir). Rodei com
  `CAPTURAS=1 TZ=America/Sao_Paulo`.
- `aud_glifos_test.dart`: folha de glifos a 12–32 px, com DPR 1, 2, 2,625 e 3.
- `aud_botao_test.dart`: arrastar para fora, ação do leitor de tela,
  desabilitar no meio do aperto e lista rolável.
- `aud_rotulos_test.dart`: mede com `TextPainter` se cada rótulo cabe no
  botão antigo e no novo, em pt/en/es, a 320/360/393 dp, com fonte 1,0 e 1,25.
- `aud_celebracao_test.dart`: as celebrações de nível e de marco com as cores
  de produção.

---

## 1. Glifos

### O que está certo

- `Icons.eco` e `LeafMark` não aparecem mais em `lib/`, a não ser na doc de
  `glifos.dart`. Na home, nas missões, na loja, em "Suas folhas", no resultado
  e na pílula de preço é o mesmo `GlifoFolha` verde. Nas pílulas o glifo é
  creme sobre o verde, com nervura escura. Ver
  `antes-depois-01-home.png`, `-04-missoes.png`, `-06-loja.png`,
  `-10-folhas.png` e `-11-resultado.png`.
- A folha lê como folha em todos os tamanhos medidos. A 12 px com DPR 1 vira
  uma gota verde, mas a forma continua reconhecível
  (`glifos-dpr1-ampliado-3x.png`).

### Achado 4 (média): o glifo da raiz não lê como raiz

Minha leitura honesta, olhando `glifos-dpr2.625.png`, `glifos-dpr3.png` e a
home (`antes-depois-01-home.png`, o selo "Raiz de 4 dias"):

- de 12 a 16 px parece um **"X"/asterisco** ou um **bonequinho de braços
  abertos**;
- a 18 px, que é o tamanho na home, parece uma **figura humana estilizada**
  ou uma **mandrágora**;
- só a 32 px se vê "duas folhinhas, uma semente e raízes".

O comentário do próprio código (`glifos.dart`, `_PintorDaRaiz`) diz que a
linha de chão foi tirada porque o desenho "lia como um bonequinho". Sem ela,
continua lendo assim. A especificação 4.5 pede "broto com duas folhas saindo
de um **montinho de terra**". O desenho entregue não tem a terra, e é a terra
que diz "isto está embaixo do chão". O ADR admite que a leitura não foi
verificada.

- **Reproduzir:** renderizar `GlifoRaiz` a 12/14/16/18 px (o teste
  temporário está descrito acima) ou abrir a home.
- **Correção sugerida:** pôr de volta um arco de terra baixo e largo, que não
  cruze o caule, abaixo do broto, com as raízes saindo por baixo dele. Na
  home, usar 20–22 px. Testar com 5 pessoas antes de fechar.

### Achado 3 (média): `GlifoXp` sem nenhum uso

`grep -rn GlifoXp lib` só encontra a definição (`glifos.dart:51`). "+10 XP"
nas missões, "+12 XP" no resultado e "255 XP" na trilha continuam como texto
`mel700` puro. O R-V2 e a especificação 4.6 pedem "números de recompensa
sempre … + glifo próprio à esquerda". O desenho em si é bom (estrela de
quatro pontas, lê bem até 12 px).

- **Correção:** usar `GlifoXp(tamanho: 14)` à esquerda de cada "+N XP"
  (`missoes_screen.dart` `_Recompensa`, `result_screen.dart` `_BarraDeXp` e
  `trilha_screen.dart` `CartaoNivel`) e incluir o glifo no `glifos_test`.

### Achado 2 (média): a raiz continua verde

- `cartao_da_raiz.dart:72`: o número herói do cartão usa
  `Cores.primariaEscura`.
- `cartao_da_raiz.dart:87`: o desenho usa `RaizViva(cor:
  Cores.primariaEscura)`.
- `raiz.dart:32`: o padrão de `RaizViva` é `Cores.primariaEscura`, que é o que
  a cena da raiz usa (`cena_da_raiz.dart:434`, sem `cor`).

Resultado: a raiz é terracota em "Sua raiz" e na home, e **verde** no cartão
de compartilhar e na cena que celebra a raiz
(`raiz-verde-no-cartao-e-terracota-na-cena.png`, à esquerda o cartão). O
laudo 03 §1.4 cita justamente "a raiz **verde** do cartão de compartilhar", e
o aceite do R-V2 é "uma raiz, um glifo, uma cor". As partículas de folha
desses dois lugares (`cena_da_raiz.dart:613`, `crescimento.dart:507`) são
verdes, e isso está certo, porque são folhas.

- **Correção:** trocar o padrão de `RaizViva` para `Cores.raiz600` e, no
  cartão, número e desenho para `raiz600` (o par passa: 5,1:1 sobre a
  superfície).

---

## 2. Paleta e contraste

Calculei todos os pares com a fórmula WCAG 2.x (luminância relativa,
`(L1+0,05)/(L2+0,05)`), compondo os tons translúcidos sobre o fundo real. Os
números batem com `Cores.contraste`.

### O que está certo

| Par | Contraste |
|---|---|
| `tinta700` sobre superfície / habitat / foco (sessão) / canvas / trilho / creme / folha de compartilhar | 5,89 / 5,34 / 5,49 / 5,18 / 4,99 / 5,39 / 5,75 |
| Creme sobre `folha600` (botão primário, pílula da loja) | 4,64 |
| Tinta sobre `mel400` (recompensa, "Resgatar", selo da aba, selo do paywall) | 6,90 |
| Creme sobre `raiz600` / `alerta` sobre creme (destrutivo) | 5,09 / 4,87 |
| `raiz600` sobre raiz a 10% (selo da home) | 4,61 |
| `mel700` sobre mel a 20% (próximo passo) / a 24% (missão pronta) | 4,97 / 4,86 |
| `folha700` sobre folha a 12% (o "+10 folhas") | 6,03 |
| `mel700` sobre a superfície / o foco | 5,49 / 5,12 |
| `folha600` como texto sobre a superfície / o cartão | 4,64 / 5,03 |
| Barra `folha600` contra o trilho / o tingido verde | 3,9 / 4,2 |

- O laranja saiu da interface. As únicas ocorrências que restam de
  `Cores.acento` e `AppColors.orange` estão na arte (`pet.dart`, `models.dart`
  ShapePart). "Acima da meta" virou neutro (`tinta500`) na home, no relatório
  e no tempo de tela. A missão pronta mantém a barra verde e o "pronta" fica
  com a etiqueta e o botão mel.
- `Etiqueta` escolhe o rótulo legível sozinha (`faceDaEtiqueta`,
  `legivelSobre`), e isso funciona para todas as cores que testei.

### Achado 5 (média): celebração com contraste pior que antes

A toca e a celebração aparecem sobre um véu de tinta a 82%, que composto sobre
a superfície dá `#605246`:

- **O rótulo do prêmio na toca** é `Text(rotulo, style:
  estilo(Tipo.subtitulo, color: cor))` (`toca.dart:204`):
  - no nível, com `cor: Cores.folha600` (`app.dart:353`), dá **1,45:1**
    (antes `primaria`, 1,86:1);
  - no marco (`mel400`), dá 4,04:1 em 16 px w700, que não conta como texto
    grande. Também reprova, mas melhorou em relação aos 2,88 de antes.
- **O ícone do círculo aberto** é creme sobre `mel400` (`celebracao.dart:189`
  e `:202`): **1,66:1**. É um gráfico, então o mínimo é 3:1. Antes, com
  `acento`, dava 2,33:1 (`celebracao-nivel-e-marco.png`, quarto quadro; o
  ícone aparece como quadrado porque o teste não carrega a fonte de ícones).

- **Reproduzir:** conferir as contas acima ou subir de nível.
- **Não capturei** o quadro exato do rótulo do prêmio, que é transitório,
  entre a terra abrir e a celebração assumir. O valor vem do código e do
  cálculo.
- **Correção:** o rótulo do prêmio sobre o véu deve ser sempre `tintaClara`.
  Sobre o círculo, usar `Cores.textoSobre(cor)` (tinta sobre mel, creme sobre
  verde).

### Achado 6 (média): selo "Seu" da loja

`shop_screen.dart:667` e `:739` usam `cor: Cores.tinta.withValues(alpha:
0.55)` no `SeloDaLoja`, com texto `superficie` de 11,5 px. Composto sobre a
miniatura (fundos medidos de `#C8D8B8` a `#FFFBF2`), dá **3,0–3,8:1**. O
commit editou essas linhas (só o ramo "em uso") e deixou o translúcido.

- **Correção:** usar `Cores.tinta700` opaco (creme sobre ele dá 5,9:1).

### Achado 13 (baixa): o que ainda está translúcido ou em `tinta500`

- **Tinta a 70% como texto:**
  - `onboarding_screen.dart:209`: 4,75:1;
  - `result_screen.dart:327`: 4,75:1;
  - `sobreposicao_screen.dart:260`: 4,75:1 sobre a superfície; sobre o
    habitat, 4,50:1, no limite.

  Passam, mas contrariam a regra "texto secundário é `tinta700` opaco". O
  `glifos_test` não pega esses casos porque a regex só procura alfa de 0,3 a
  0,69.
- **`tinta500` como texto informativo** (sobre superfície/cartão dá
  3,97/4,31; sobre o trilho do botão desabilitado, 3,37):
  - o "Faltam N" da pílula desabilitada (`loja_vitrine.dart:369`; 3,88);
  - o rótulo do degrau travado (`trilha_screen.dart:535`);
  - "Entrando…" e "Desbloqueando…" no `BotaoBaru` desabilitado.

  O WCAG isenta componente inativo, mas "Faltam 30" é informação. A
  especificação 4.4 limita `tinta500` a "texto ≥ 18 px ou desabilitado".

### Achados 9, 14 (baixa): barras e anéis

- **XP do resultado** (`result_screen.dart:508`): a barra inteira vira
  `raiz500` quando o bônus da raiz chega (2,55:1 contra o trilho). O
  comentário fala em "noutro tom", mas a barra toda muda de cor e contradiz o
  ADR ("Toda barra de progresso é verde"). Sugestão: barra verde com o trecho
  do bônus em `raiz600` (que contra o trilho dá ~4,3:1).
- **Nós da trilha** (`trilha_screen.dart:799`): o anel `mel600` sobre
  tinta 10% dá 2,0:1, e o `primariaClara` dá 2,4:1.

### Semântica

- **Laranja fora da raiz:** não encontrei nenhum na interface.
- **Mel:**
  - **Correto** no XP, no nível, no "colher", na trilha (próximo passo, nó
    atual, "Aqui"), no selo da aba "a colher" e no marco.
  - **Achado 12 (baixa):** o selo "MELHOR VALOR" do paywall
    (`paywall_screen.dart:171`) é preço, não recompensa. Sugestão: tinta
    sobre creme, ou verde.
- **Achado 11 (baixa):** `Cores.dispersivo` e `Cores.alerta` têm o mesmo valor
  (`tokens.dart:243` e `:90`).
  - "Instagram — Dispersivo" fica na cor de erro, o que contradiz o espírito
    de "acima da meta é neutro".
  - Para daltonismo vermelho-verde, simulei com a matriz de Machado 2009 e
    severidade 1,0. Dispersivo × produtivo dá **1,16:1** em deuteranopia
    (antes 1,77:1) e 1,29:1 em protanopia. O rótulo de texto salva o
    SC 1.4.1, mas a cor sozinha deixou de distinguir as duas categorias.
- **Achado 8 (baixa):** o "dia de hoje" da semana tem três cores:
  - `home_screen.dart:330`: anel verde;
  - `sequencia_screen.dart:236`: anel `raiz500`;
  - `cena_da_raiz.dart:665-667`: presente em verde e congelado em
    `#9CC3D5` escrito à mão, quando o resto do app usa `ceu600`.

  É o caso que o laudo 03 §1.4 descreve.
- **Céu = congelamento:** correto na home e em "Sua raiz".
- **"Não concedida"** em `alerta` (sobreposição) é um pouco forte para
  "permissão ainda não dada", mas é defensável.

---

## 3. `BotaoBaru`

### O que está certo (verificado por teste temporário)

| Comportamento | Resultado |
|---|---|
| Afunda 4 dp ao tocar e volta; `lightImpact` uma vez | ok (teste do commit) |
| **Arrastar para fora** (200 px) cancela: `aoTocar` não roda, sem háptico, a face volta | ok |
| Arrastar dentro de `ListView` rola e não toca | ok |
| Desabilitar no meio do aperto e reabilitar | a face volta ao lugar (0 dp) |
| Desabilitado: sem lábio, sem toque, sem háptico, `enabled: false` na semântica | ok |
| Leitor de tela: rótulo = texto do botão, ação *tap* chama `aoTocar` | ok (sem háptico, ver achado 15) |
| "Reduzir movimento": não se move, só escurece | ok |
| **Háptico duplicado:** nenhum call site do `BotaoBaru` chama háptico. O `mediumImpact` da loja está na `PilulaDaLoja`, que não é `BotaoBaru` | ok |
| Botões lado a lado | não existem no app (nenhum `BotaoBaru` dentro de `Row` com `expande: true`) |
| Overflow a 320 dp com fonte 1,3 e 2,0, em pt/es | nenhum `RenderFlex overflowed` nas telas capturadas |

Observação: o app limita a escala de texto a **1,25×** (`app_frame.dart:50`).
Por isso, nas capturas "2,0", o efetivo é 1,25.

### Achado 1 (média): regressão de rótulo cortado

O `BotaoBaru` põe `padding: horizontal: Espaco.lg` (20 + 20 dp,
`botao_baru.dart:165`) e peso w800 (`:144`), mantendo `maxLines: 1`
(`:141`). O `PrimaryButton` antigo não tinha padding lateral e usava w700, e
o `GhostButton` usava 16 px. Por isso, rótulos que cabiam passaram a cortar.
Medido com `TextPainter` (arquivo `rotulos-que-cortam-a-1.25.txt`) e
confirmado nas capturas reais (`botao-rotulo-cortado-antes-depois.png`,
`pt-320dp-fonte-max-g2.png`, `es-320dp-fonte-max-g0.png`):

| Idioma, largura, fonte | Rótulo | Antes | Depois |
|---|---|---|---|
| pt 320 dp ×1,25 | "Teste ativo — continuar" (paywall) | cabe | **"Teste ativo — contin…"** |
| en 320 dp ×1,25 | "Trial active — continue" | cabe | **"Trial active — contin…"** |
| es 360 dp ×1,25 | "Prueba activa — continuar" | cabe | **"Prueba activa — continu…"** |
| pt 320 dp ×1,25 | "Compartilhar o habitat" (resultado) | cabe | **"Compartilhar o h…"** |
| es 320 dp ×1,25 | "Compartir el hábitat" | cabe | **"Compartir el hábi…"** |
| es 320 dp ×1,25 | "Quedarme un poco más" (folha de saída) | cabe | corta |

- O paywall é a CTA de pagamento; cortar o rótulo justamente ali é o pior
  lugar.
- A 393 dp e com fonte 1,0, nada corta.
- **Correção:** com `expande: true`, reduzir o padding para 12 dp. Com
  `maxLines: 2`, deixar a altura crescer (`ConstrainedBox(minHeight:
  altura)` no lugar de `SizedBox(height:)`), ou usar
  `FittedBox(fit: BoxFit.scaleDown)` no rótulo. Incluir no `botao_baru_test`
  os rótulos reais mais longos a 320 dp ×1,25.

### Achado 10 (baixa): alvos de 44 e 46 dp

- `BotaoBaru.alturaCompacta = 44` (`botao_baru.dart:85`), usado no "Colher"
  do resultado (`result_screen.dart:614`).
- As missões usam 46 dp (`missoes_screen.dart:425`, `:437`, `:446`).
- A especificação 4.8 diz 48 dp no compacto, e o próprio app define
  `Toque.minimo = 48`.

### Outras observações (sem severidade)

- O "Resgatar" das missões continua uma `Etiqueta` que parece botão. O R-V4
  pedia migrar o chip "Resgatar".
- O botão de compra em destaque da loja ("260", largura toda) segue chapado
  (`PilulaDaLoja`). O ADR exclui a pílula de preço, mas essa tem cara de CTA
  principal e destoa do resto.
- `PapelDoBotao.raiz` não tem uso.
- A face creme do secundário contra a superfície dá 1,09:1. O lábio ajuda a
  ver o botão, e o rótulo o identifica.

---

## 4. Arte do bicho e do cenário

**Idêntica.** Rodei os sete `evidencia_*_test` nos dois commits e comparei os
PNGs pixel a pixel (`comparacao-pixel-evidencias-antes-depois.txt`):

- 124 das 178 imagens são **iguais pixel a pixel**, entre elas todas as
  `habitat-*` (inclusive `habitat-cheio`, com os itens da loja),
  `especie-*`, `elenco-nove`, `buldogue-*`, `pet-*`, `respiracao-*` e quase
  todas as `atividade-*`.
- As cinco imagens de bicho que diferem (`atividade-ocio-raposa-5`,
  `atividade-petisco-lontra-7`, `reacao-4/5/6`) **também diferem entre duas
  rodadas do commit antigo** (`nao-determinismo-antes-vs-antes.txt`). É
  animação não determinística, não mudança de arte.
- Nas capturas do app inteiro, a região da cena da home tem **0 pixels
  diferentes**. Nas faixas do bicho em resultado, desistência, sessão,
  onboarding e paywall, também **0**.

Ficou certo, portanto, o cuidado de mover `AppColors.green` →
`Cores.primaria` nos `ShapePart` da loja e `acentoForte`/`acentoTexto` →
`terracotaDaArte`/`ferrugemDaArte` no `pet.dart`.

Mudaram de propósito, e não são bicho nem cenário:

- a cor das partículas de folha nas cenas da raiz e do crescimento;
- a raiz desenhada em "Sua raiz" (`#B8502A` → `#A64C27`);
- a gota e o odômetro da cena da raiz (`#EF8354` → `#D86F32`).

---

## 5. Os testes novos pegam regressão?

Mutações aplicadas uma por vez, rodando `contraste_test`, `glifos_test` e
`botao_baru_test`:

| Mutação | Testes novos |
|---|---|
| Face do primário `folha600` → `folha500` | **falha** (pega) |
| Rótulo semântico do botão vazio | **falha** (pega) |
| Sem lábio | **falha** (pega) |
| Texto `mel700` → `mel400` na trilha (1,9:1) | **passa** (não pega) |
| `Cores.tinta.withValues(alpha: 0.45)` como texto nas missões | **passa** |
| Barra "acima da meta" de volta a `Cores.acento` | **passa** |
| Folha da loja trocada por `Icon(Icons.energy_savings_leaf, color: raiz500)` | **passa** |
| `onTapCancel` removido | **passa** |

### Achado 7 (média)

O `contraste_test` verifica os **tokens**, não o uso nas telas: qualquer tela
pode usar um par reprovado sem que o teste falhe. A regex do `glifos_test`
só reconhece `inkA(...)`/`tintaA(...)` de 0,3 a 0,69 e não vê
`.withValues(alpha:)`. Faltam ainda:

- os goldens "5 variantes × 3 estados" que o aceite do R-V4 pede;
- um teste de arrastar para fora;
- um teste de rótulo longo.

Sugestões:

- teste de fonte que proíba `Cores.acento`/`mel400`/`raiz500` como `color:`
  de `TextStyle`;
- regex que pegue também `.withValues(alpha:` em estilos de texto;
- goldens do `BotaoBaru`;
- teste de cancelamento ao arrastar;
- teste de rótulo a 320 dp ×1,25.

---

## 6. Capturas antes × depois

Todas em pt, 1080×2400 a 2,625, `TZ=America/Sao_Paulo`, lado a lado (antes à
esquerda, depois à direita): `antes-depois-01-home`, `-02-sessao`,
`-03-trilha`, `-04-missoes`, `-05-tempo`, `-06-loja`, `-07-relatorio`,
`-08-sequencia`, `-09-ajustes`, `-10-folhas`, `-11-resultado`,
`-12-desistencia`, `-13-onboarding-idioma`, `-13-onboarding-revelacao`,
`-14-paywall`, `-15-conta`, `-16-sobreposicao` e `-17-sessao-desistir`.
Narrow/fonte máxima: `es-320dp-fonte-max-g0/g2`, `pt-320dp-fonte-max-g0/g2`.

Leitura geral:

- **Coesão:** as telas ficaram mais coesas. A folha é uma só, o pêssego
  sumiu da trilha e das missões, o texto secundário ficou mais legível e as
  abas inativas ficaram legíveis.
- **Botões:** os botões ficaram claramente "de apertar".
- **Missões:** o mel no "Resgatar" e no "PRONTAS PARA COLHER" separa
  "recompensa" de "ação". "A PRINCIPAL DE HOJE" virou etiqueta verde cheia,
  com a mesma cor do botão logo abaixo; isso é aceitável, mas a etiqueta
  agora compete um pouco com o botão.

---

## O que não verifiquei

- Leitura dos glifos por pessoas: só a minha leitura, em capturas.
- Aparelho real: háptico físico, TalkBack/VoiceOver de verdade, tela de
  densidade real e fonte do sistema acima de 1,25 (o app limita).
- Chinês (`zh`): o harness não tem fonte CJK.
- O quadro transitório do rótulo do prêmio na toca de nível (achado 5) e o
  ícone da celebração renderizado com a fonte de ícones, que o teste não
  carrega.
- Contraste do texto sobre a ilustração do cenário (balões da sobreposição,
  miniaturas) além do selo "Seu".
- Telas de autenticação, legal sheet e compartilhar: lidas no diff e com as
  cores calculadas, mas não capturadas.
- Se a suíte inteira, e não só os três testes novos, pega as mutações da
  seção 5.

## Resumo

**APROVADO COM RESSALVAS.** Arte intacta (verificada pixel a pixel), suíte
verde e análise limpa. O laranja saiu da interface, o texto secundário passa
de 5:1 e o botão 3D se comporta bem (toque, cancelamento, desabilitado,
semântica, reduzir movimento, sem háptico duplicado). Não há achado alto.

Achados médios:

1. Regressão: rótulos cortados no `BotaoBaru` ("Teste ativo — contin…" no
   paywall, "Compartilhar o h…").
2. A raiz continua verde no cartão de compartilhar e na cena da raiz.
3. `GlifoXp` sem uso.
4. O glifo da raiz lê como bonequinho/"X" a 12–18 px.
5. Celebração: prêmio de nível a 1,45:1 e ícone creme sobre mel a 1,66:1
   (ambos pioraram).
6. Selo "Seu" da loja a 3,0–3,8:1.
7. Os testes novos não pegam texto em cor clara, tinta translúcida via
   `withValues`, barra laranja de volta, ícone de folha paralelo nem a perda
   do cancelamento.

---

## Resposta às ressalvas (implementador)

| Achado | O que mudou |
|---|---|
| **1. Rótulos cortados** | `BotaoBaru`: o rótulo encolhe (`FittedBox`) em vez de virar "…"; padding lateral de 20 para 16 dp. |
| **2. Raiz verde** | `RaizViva` passou a `raiz600` por padrão; o cartão de compartilhar (número e raiz) também. A cena da raiz herda o padrão. |
| **3. GlifoXp sem uso** | O "+N XP" das missões, a linha de XP do resultado e o cartão de nível (trilha e home) usam o glifo. O cartão de nível passou a mel (fundo e XP em `mel700`), com a barra verde. |
| **4. Glifo da raiz** | Redesenhado com o montinho de terra da especificação 4.5, como cúpula cheia: o broto fica em cima, as raízes saem por baixo, e nenhum traço cruza o caule. **Ressalva mantida:** abaixo de 16 px ele continua ambíguo sem o rótulo; não fiz teste com pessoas. |
| **5. Contraste na celebração** | O nome do prêmio na toca da celebração é creme sobre o véu (`Toca.corDoRotulo`). O ícone sobre o mel usa `textoSobre` (tinta) desde `bf65c95`. Nível passou a mel. |
| **6. Selo "Seu"** | Fundo em tinta a 86% (creme sobre ele > 7:1 mesmo sobre miniatura clara). |
| **7. Testes frouxos** | `glifos_test`: proíbe mel 400/600 como cor de texto, tinta translúcida também por `withValues`, laranja antigo (`acento`/`orange`) em telas e componentes fora da arte, e ícones de folha do Material com outros nomes (`spa`, `grass`, `energy_savings_leaf`). `botao_baru_test`: arrastar para fora cancela o aperto e não toca. Goldens de 5 papéis × 3 estados **não** foram feitos. |

Baixos tratados: botões compactos com 48 dp; barra de XP do resultado
sempre verde; selo "melhor valor" do paywall em tinta (não mel); `alerta`
com hex próprio, distinto do `dispersivo`. Baixos não tratados: cores do
"dia de hoje" entre telas, deuteranopia dispersivo × produtivo, textos
informativos em `tinta500`, anéis dos nós da trilha abaixo de 3:1, háptico
na ação do leitor de tela.

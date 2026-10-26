# Auditoria independente — Onda 2, itens 5 e 6 (commit `a6d1e18`)

Auditor sem participação no código. Tudo foi verificado num worktree
descartável do commit `a6d1e18` (`/tmp/claude-0/aud56`, já removido), não na
árvore de trabalho. Referências `arquivo:linha` são do commit `a6d1e18`.
Imagens geradas pela auditoria: `docs/auditoria/onda-2-itens-5-6/`.

Lido antes: `docs/pesquisa/00-SINTESE.md`, `05-animacao-e-tecnica.md` §4 e §5,
tabelas de estágio de 06/07/08, `docs/DECISIONS.md` ADR-024, `docs/PRODUCT.md`.

## Resumo

| Item | Veredito |
|---|---|
| 5 — bicho real na sobreposição | **APROVADO COM RESSALVAS** |
| 6 — crescimento do ovo ao pleno | **REPROVADO** (um defeito alto, de correção pequena e localizada; o resto está sólido) |

Problemas altos e médios:

| # | Sev. | Item | Problema |
|---|---|---|---|
| 6.1 | **alta** | 6 | Filhote e jovem das espécies que nadam ficam com a linha d'água nos olhos ou acima deles (parecem afogados) na sessão de foco e na home em dia "radiante" |
| 6.2 | média | 6 | A tela da sessão ignora o estágio: ovo ou ninho "VOO DE 25 MIN · Nina está voando", ninho e ovo boiando na lagoa com "está nadando"; corujinha "voando" pousada |
| 6.3 | média | 6 | Adulto → pleno não muda nada no desenho em 7 das 9 espécies, mas a cena de crescimento roda inteira ("Nina cresceu! AGORA: PLENO") sobre duas silhuetas idênticas |
| 5.1 | média | 5 | Corrida de escrita: os PNGs são regravados no mesmo caminho, sem atomicidade, no mesmo instante em que a sobreposição pode aparecer |
| 5.2 | média | 5 | Momento de rasterizar diferente do laudo e da síntese (ao sair do app e não ao iniciar a sessão, e sem o adiamento que o `WidgetService` documenta como correção) |
| 6.4 | média | 6 | O pisca-pisca da cena roda de ~9 a 30 trocas/s (limitado pela taxa de quadros), não de 4 a 12 Hz como diz o comentário; é cintilação de alto contraste |

---

## Comandos executados (no worktree de `a6d1e18`)

O worktree não tem `.env` (está no `.gitignore`); copiei `.env.example` para
`.env` só no worktree, sem segredo nenhum.

```
$ flutter analyze --no-pub
No issues found! (ran in 2.4s)

$ flutter test --no-pub
02:00 +1037 ~26: All tests passed!

$ flutter build apk --debug --no-pub --dart-define=SUPABASE_ENABLED=false
✓ Built build/app/outputs/flutter-apk/app-debug.apk   (1ª tentativa, sem 429)
```

O Kotlin novo (`QuadrosDoBicho.kt`, `OverlayDoBaru.kt`, `MainActivity.kt`)
compila. Não havia emulador nem aparelho: **nada do lado nativo foi
executado**; o que só um aparelho confirma está listado no fim.

Para as imagens escrevi um teste temporário (`test/zz_auditoria_test.dart`,
só no worktree, apagado junto com ele) que renderiza `PetView`,
`QuadrosDoBicho.cena`, `CenaDoCrescimento` e o `BaruApp` inteiro, e montei as
grades com PIL.

---

## Item 5 — bicho real na sobreposição

**Veredito: APROVADO COM RESSALVAS.**

### O que está certo (com evidência)

- **Mesmo desenho da home.** `QuadrosDoBicho.cena`
  (`lib/services/quadros_do_bicho.dart:121-137`) usa o próprio `PetView` com
  `quadro: QuadroFixo(...)`. Medi o quadro de respiro neutro contra o
  `PetView` parado (reduzir movimento) do buldogue tigrado de gorro, estágio
  filhote: 382 px diferentes em 136 mil (borda de antisserrilhado). Imagem:
  `overlay-quadros-buldogue-tigrado-gorro-filhote.png` (6 quadros de fôlego,
  a piscada e, por último, o bicho como a home desenha).
- **Sem relógio no modo quadro.** Com `quadro != null` o `PetView` não liga
  `repeat` nem agenda piscada (`lib/widgets/pet.dart:413` e `:427`), o que
  importa porque `HomeWidget.renderFlutterWidget` nunca desmonta a árvore
  fora da tela (`home_widget-0.9.2+1/lib/src/home_widget.dart:345-435`).
  Sobram 7 `State` presos à `WidgetsBinding` por desenho, sem ticker ativo:
  vazamento pequeno e limitado.
- **Chave da aparência** inclui espécie, estágio, pelagem, peça de cabeça e
  roupas ordenadas (`quadros_do_bicho.dart:55-63`). Roupa, estágio, espécie
  ou pelagem nova levam a quadros novos na saída seguinte. Atualização do app:
  `_ultimaChave` vive em memória, então a primeira saída de cada processo
  sempre redesenha (`:12-16`, `:145`). Com isso o desenho novo de uma versão
  nova chega à sobreposição.
- **Funciona com o processo morto (no projeto do código).** Os caminhos vão
  para `SharedPreferences` (`QuadrosDoBicho.kt:43-61`) e os PNGs ficam em
  `filesDir/home_widget/`. O `OverlayDoBaru` os lê sem Dart
  (`OverlayDoBaru.kt:104-107`), e o `VigiaDaSessao` continua iniciando o
  overlay por `startService` (`VigiaDaSessao.kt:385-391`).
- **Reserva.** `carrega` devolve `null` se falta caminho, arquivo ou
  decodificação (`QuadrosDoBicho.kt:71-100`), e o `onDraw` cai em
  `desenhaBicho` (`OverlayDoBaru.kt:391-396`). O Dart nunca lança
  (`quadros_do_bicho.dart:181-183`, testado em `quadros_do_bicho_test.dart:148`).
- **Respira e pisca.** O `ValueAnimator` em laço funde dois quadros vizinhos
  pela fase (`OverlayDoBaru.kt:280-289`, `:407-437`). A piscada sai em
  intervalo de 1,8 a 6,4 s, às vezes dupla (`:297-308`).
- **Acessibilidade.** Com "remover animações" (`areAnimatorsEnabled() ==
  false`) o bicho fica parado no meio do fôlego e não pisca (`:274-279`). A
  entrada com `OvershootInterpolator` vai direto ao fim nessa escala.
- **Sem vazamento de Handler/Animator.** `onDetachedFromWindow` cancela o
  animador e limpa o `Handler` (`:314-319`), e `esconde()` tira o `sumir`
  (`:170-179`). O animador de entrada, de 420 ms, não é cancelado, mas
  termina sozinho.
- **Recorte.** Simulei a janela (largura 248 dp, bicho de 120 dp de altura,
  centro em x = 178 dp): o retângulo do bitmap vai de 107,4 a 248,6 dp (0,6 dp
  de área transparente além da borda). O que é **pintado** fica entre 132,8
  e 234,1 dp nas 9 espécies (ovo e adulto, peito vazio e cheio): nada é
  cortado. Imagem: `overlay-simulacao-3x.png`.
- **Memória (cálculo, não medição).** São 7 bitmaps de 400×340 ARGB_8888, ou
  3,8 MB decodificados. `inSampleSize` nunca reduz nos aparelhos de 2× e 3×
  (340 px < 2 × altura alvo). O total fica abaixo de 5 MB enquanto só uma
  leva estiver viva (ver 5.5).

### Problemas

**5.1 — média — Corrida de escrita dos PNGs com a sobreposição aparecendo.**
Cada leva grava em caminhos fixos (`baru_bicho_0..5`, `baru_bicho_pisca`,
`quadros_do_bicho.dart:161-173`) com `File.writeAsBytes`, que trunca e
reescreve no lugar (`home_widget.dart:271-276`). As preferências só mudam
depois das 7 gravações (`:175-180`). Durante a regravação, as preferências
apontam para arquivos que estão sendo sobrescritos. A chave gravada em
`K_CHAVE` nunca é conferida na leitura (`QuadrosDoBicho.kt:71-87`).

*Cenário:* a pessoa inicia a sessão, troca o gorro por um chapéu e sai para o
Instagram. Ou então é a primeira saída do processo, que sempre redesenha. O
`VigiaDaSessao` consulta a cada 2 s (`VigiaDaSessao.kt:187`) e levanta o
overlay na primeira rodada. Se as 7 rasterizações e gravações ainda não
acabaram, o overlay pode ler um PNG truncado: `decodeFile` devolve `null`, e
aparece a reserva. Pode ler também metade da leva nova e metade da antiga, e
a respiração alterna entre chapéu e gorro durante os 12 s.

*Correção:* gravar cada leva em nomes próprios (por exemplo
`baru_bicho_<hash da chave>_<n>`), trocar as preferências por último e apagar
a leva anterior depois. Ou gravar em `.tmp` e renomear (`rename` é atômico no
mesmo sistema de arquivos). No Kotlin, conferir que todos os arquivos são da
mesma chave.

**5.2 — média — Quando rasterizar.** A síntese e o laudo 05 §5.3, passos 3 e
4, pedem rasterizar **ao iniciar a sessão, antes de `vigiaComeca`**, com o
app aberto e "adiado e em repouso, como `WidgetService` faz". O commit
rasteriza em toda transição que não é `resumed` (`lib/app.dart:151-156`),
inclusive `inactive` (puxar a cortina de notificações, abrir o seletor de
apps), e **sem** o adiamento de 1 s que `widget_service.dart:110-118` chama
de "não é otimização, é correção". Com `quadro` o `PetView` não liga
tickers, então o mecanismo exato documentado ali provavelmente não se repete.
Só que isso **não foi verificado em aparelho**. Rasterizar na saída também
aumenta a janela de 5.1 e faz todo usuário, mesmo sem permissão de
sobreposição, rasterizar 7 quadros na primeira saída de cada processo.

*Correção:* chamar `QuadrosDoBicho.atualiza` em `startSession` (antes de
`vigiaComeca`) e quando a aparência muda com sessão em curso. Manter a saída
só como rede de segurança, com o mesmo `Timer` de adiamento, e só se
`Settings.canDrawOverlays`.

**5.3 — baixa — A piscada dá um tranco no corpo.** O quadro de piscar é
desenhado com respiro 0 (`quadros_do_bicho.dart:169-173`). Mostrado no
pico do fôlego, o corpo volta ao meio por 150 ms. Medi 3.256 px diferentes
entre a piscada e o quadro de peito vazio, contra 4.112 entre o peito vazio e
o cheio: o tranco é quase do tamanho do fôlego inteiro. *Correção:* gerar a
piscada em 2 ou 3 fases do fôlego, ou recortar só a região dos olhos.

**5.4 — baixa — O bicho real fica pequeno e longe do balão nos estágios
iniciais.** O quadro tem 200×170 lógicos, e o filhote ocupa só 37 % × 55 %
dele, encostado embaixo. Na janela, o buldogue filhote tem 52×66 dp e fica a
cerca de 50 dp abaixo do balão, com o rabicho apontando para o vazio
(`overlay-simulacao-3x.png`). O ovo tem de 44 a 55 dp de altura. *Correção:*
recortar o PNG pela caixa pintada (ou guardar a caixa junto) e ancorar o
bicho pelo topo do desenho.

**5.5 — baixa — Memória e thread.** `mostra()` decodifica 7 PNGs na thread
principal do serviço (`OverlayDoBaru.kt:104`). Mostrado de novo antes de
um GC, convivem duas levas (7,6 MB), porque não há `recycle()` em
`esconde()`. *Correção:* `recycle()` dos bitmaps em `onDetachedFromWindow`,
ou guardar o `Quadros` no serviço enquanto a chave não mudar.

**5.6 — baixa — Prévia dentro do app diverge do overlay real.** A
`sobreposicao_screen.dart:614-621` desenha `app.mood`, mas o overlay real é
sempre contente (`quadros_do_bicho.dart:126`). Com saudade, a prévia mostra o
bicho triste e o overlay, contente.

**5.7 — baixa — Testes.** Não há teste do lado Kotlin (o laudo 05 §5.3,
passo 9, pede o da reserva sem arquivo) nem teste de que o estágio muda a
chave (`quadros_do_bicho_test.dart:25-42` cobre espécie, pelagem, roupa e
cabeça).

### O que só um aparelho confirma (não verificado)

- O overlay mostra de fato os quadros (log `overlay: bicho real`), respira e
  pisca a ≤ 30 fps sem engasgo.
- Com o processo do app morto (`am kill`) durante a sessão, o vigia
  ressuscitado mostra o bicho certo.
- `HomeWidget.renderFlutterWidget` em `inactive`/`hidden`/`paused` completa
  (Impeller/Skia, Android 8–15) e não derruba asserção de `AnimationController`
  em build de debug.
- Memória extra ≤ 5 MB no Profiler, e tempo de decodificação dos 7 PNGs.
- Comportamento com restauração de backup em outro perfil de usuário: os
  caminhos absolutos não batem e cai na reserva até a próxima saída
  (deduzido do código, `QuadrosDoBicho.kt:89-90`).

---

## Item 6 — crescimento

**Veredito: REPROVADO.** Dado, régua, sincronização, migração, fila de
celebração e textos estão corretos. O desenho por estágio cria um defeito
visual alto no fluxo principal e duas incoerências médias.

### O que está certo (com evidência)

- **Régua e "nunca regride".** `Crescimento.estagioPara` com limiares
  0/1/5/15/40 (`lib/data/crescimento.dart:37-45`). O contador só sobe na
  conclusão (`lib/state.dart:1989-1994`); desistir não conta
  (`crescimento_test.dart:113`). A fusão fica com o maior por chave nos dois
  mapas (`app_snapshot.dart:426-431`, `crescimento.dart:95-102`).
- **Migração (semente).** Roda em `_applySnapshot` depois de todos os campos
  de que `especiesLiberadas` depende (`state.dart:2460-2480`). Semeia todas
  as liberadas com o total da conta e marca o estágio como já celebrado
  (`:120-131`). Conta nova (0 sessões) não é semeada, e um mapa existente não
  é sobrescrito (testado).
- **Casos de borda revisados no código:**
  - Reinstalação com banco migrado: o local vazio não semeia (0 sessões), e o
    pull traz os mapas por máximo, sem cena repetida, porque
    `estagio_celebrado` também é sincronizado.
  - Remoto sem a coluna: `select()` sem a chave dá `{}`
    (`row_codec.dart:395-398`), a gravação tira a coluna
    (`supabase_gateway.dart:244-246`), e reinstalar semeia de novo (de forma
    generosa, nunca regressiva).
  - Troca de espécie: cada uma conta a sua; a nova começa no ovo/ninho
    (ADR-024 §5).
  - Espécie liberada depois: começa do zero.
  - Apagar dados zera os dois mapas (`state.dart:1559-1560`).
- **Migration** aditiva e idempotente
  (`supabase/migrations/20261026120000_baru_crescimento.sql`), na tabela
  `baru_progression`, que já está em `tabelasDoUsuario` (apagar a conta
  alcança a linha). O dado novo é derivável das sessões e não sai nada novo
  do aparelho: minimização ok. **Não verifiquei** se ela foi aplicada no
  banco remoto.
- **Celebração.** `cresceuSemCelebrar` vem antes do nível na fila
  (`state.dart:258-262`, `app.dart:323-332`). A chave da cena muda por
  estágio, `celebrou()` grava e sincroniza (`state.dart:272-281`), e a cena
  não repete (testado em `crescimento_test.dart:89`). Como o contador só
  muda na conclusão, a cena não aparece durante a sessão, exceto se uma
  sincronização trouxer crescimento de outro aparelho no meio dela (borda,
  baixa).
- **Textos nos 4 idiomas.** 22 chaves novas em pt/en/es/zh
  (`l10n.dart:741-762`, `:1269-1290`, `:1787-1808`, `:2306-2327`).
  `l10n_test` passa. Os placeholders `{a}`, `{n}` e `{e}` batem em todas as
  línguas. O plural tem chave de 1 e de N, e `faltamPara` nunca devolve 0.
  Os verbos são neutros ("nasceu", "abriu os olhos", "cresceu").
- **"Nunca se compra"**: a loja não mexe no crescimento. A vitrine da loja
  mostra o filhote quando o bicho é ovo (`loja_vitrine.dart:324-327`).
- **Onde o estágio chega.** Revisei todos os `PetView(`. Recebem o estágio:
  habitat, sessão (duas), resultado, relatório, saída, perfil, sobreposição
  (prévia), widget da tela inicial, quadros do overlay e paywall. Ficam
  adultos de propósito: onboarding (`onboarding_screen.dart:184`, `:302`) e
  login (`auth_screen.dart:585`).
- **Desenho dos 5 estágios × 9 espécies** (grades geradas):
  `grade-9x5-idle.png`, `grade-9x5-swim.png` (humor radiante, atividade
  nadar/voar), `grade-9x5-saudade.png` e `grade-9x5-gorro.png`. Ovo e ninho
  seguem a biologia pedida (coruja no ninho de gravetos, pinguim nas
  pedrinhas, tracajá na areia, cacho de ovos do axolote, mamíferos de olho
  fechado no ninho). O tamanho cresce nitidamente do filhote ao adulto, e o
  tufo da coruja cresce. Testado: filhote < jovem < adulto e filhote < 0,75
  do adulto nas 9 espécies.
- **"Reduzir movimento" na cena**: sem tremor, pisca-pisca, clarão nem
  folhas; um esmaecer de 690 ms (`crescimento.dart:308-313`). Imagens
  `cena-*-red.png`.

### Problemas

**6.1 — ALTA — Filhote e jovem "afogados" na água.** O porte do estágio
encolhe o corpo pelos pés (`pet.dart:1466-1473`, pivô `_pes = 60`), mas a
lâmina d'água fica fixa nas coordenadas do widget
(`linhaDagua = PetView.linhaDaguaEm(size.height)`, `pet.dart:1404`, `:290`).
Ela pinta o tom da água sobre tudo o que está abaixo dela (`:1510-1523`).
Quanto menor o bicho, mais fundo ele afunda.

*Cenário concreto:* conta nova de capivara, lontra, tracajá, axolote ou
pinguim, da 1ª à 14ª sessão (filhote e jovem). Durante **toda sessão de foco**
(a sessão sempre usa `Activity.swim`, `session_screen.dart:36`) e na home
depois da 1ª sessão do dia (humor radiante → nadar):

- capivara e lontra filhotes têm a linha d'água sobre os olhos, com os olhos
  tingidos de verde;
- o axolote filhote fica submerso até o topo da cabeça;
- o pinguim jovem fica com a água nos olhos.

O próprio código recusa desenhar bicho "afogado" (`session_screen.dart:104-107`).

*Evidência:* `app-filhote-na-agua.png` (sessão de capivara, axolote e
pinguim; home de capivara e axolote em dia radiante) e `grade-9x5-swim.png`,
colunas 1 e 2.

*Correção:* no `nado`, aplicar o porte com pivô na linha d'água (ou logo
abaixo dos olhos), ou compensar o `afunda` pelo estágio, para que a cabeça
do filhote fique acima da lâmina como a do adulto. Travar com teste: em
`nado`, o centro dos olhos fica acima de `linhaDaguaEm` em todos os
estágios e espécies que nadam.

**6.2 — média — Tela da sessão ignora o estágio.** `session_screen.dart:73`
calcula a ação com `acaoDoBicho(app.species, atividade)`, sem o estágio. Mas
o `PetView` troca a ação para ovo/ninho (ocioso/cochilo) e para a corujinha
(sem voo) (`pet.dart:455-468`). O resultado: rótulo "VOO DE 25 MIN" ou
"BANHO DE 25 MIN" (`:90`), lagoa desenhada atrás (`:108`), e legenda e
`Semantics` "Nina está voando." / "Nina está nadando." (`:138`, `:166`)
sobre um ovo, um ninho ou uma corujinha pousada.

*Cenário:* **a primeira sessão de todo usuário novo** acontece no estágio de
começo. O ovo da coruja "voa", e a capivara recém-nascida dorme num ninho
boiando na lagoa enquanto o texto diz que ela nada. O leitor de tela lê o
texto errado.

*Evidência:* `app-home-e-sessao-inicio.png`.

*Correção:* expor a ação efetiva (a mesma regra de `_acao`) numa função
pública (`acaoDoBicho(especie, atividade, estagio)`) e usá-la na sessão.
Para ovo e ninho, rótulo genérico `petSessao_foco` e legenda própria
("está chocando" / "está dormindo no ninho", nos 4 idiomas).

**6.3 — média — Pleno sem diferença visível em 7 espécies, mas com a cena
inteira.** `_marcasDoEstagio` só desenha algo no pleno da capivara
(passarinho, e só sem chapéu) e da coruja (sobrancelha)
(`pet.dart:3546-3570`). Em lontra, tracajá, axolote, pinguim, gata, raposa e
buldogue, adulto e pleno são idênticos: a área que muda entre as silhuetas
mede 0 dp² na raposa. Na 40ª sessão a cena faz antecipação, alterna duas
silhuetas iguais, solta o clarão e anuncia "Nina cresceu! AGORA: PLENO" sem
mudança nenhuma. A barra da home mostra como "próxima forma" uma silhueta
igual à atual. O ADR-024 registra o limite, mas o pedido do dono era
"extremamente visível", e a síntese (item 6) fala em "5 estágios × 9
espécies no painter".

*Evidência:* `cena-fox-34-mov.png` e as colunas 3/4 de `grade-9x5-idle.png`.

*Correção:* um detalhe mínimo de pleno por espécie já agora (o laudo 05
§4.1 sugere listra forte ou musgo no tracajá, crista ou gravata no pinguim,
guelras que brilham no axolote, cauda cheia na raposa). Ou, até lá, não
rodar a cena de transformação nessas espécies e trocá-la por uma
comemoração sem "antes/depois".

**6.4 — média — Cintilação da cena acima do especificado.** A fase
`u·(4+8u)·2,6` (`crescimento.dart:326-328`) dá, nos 1,38 s do trecho, de
~8,7 a ~30 trocas de forma por segundo. A 60 fps, no fim, troca a cada
quadro (`frequencia.txt` do teste: 4, 6, 10, 11, 14 e 11 trocas por janela
de 230 ms). O comentário e o laudo falam em 4 → 12 Hz. É silhueta creme
sobre véu escuro a 93 %. Pela minha estimativa, a área que muda (2 a 6 mil
dp²) fica abaixo do limiar geral de flash do WCAG 2.3.1 (~21 mil dp² a
30 cm), mas a cena roda para quem não ligou "reduzir movimento", inclusive
pessoas fotossensíveis, e acima de 3 flashes/s. *Correção:* trocar o fator
para chegar a ~6 trocas/s (`fase = u·(2+2u)·…`), ou alternar por opacidade
contínua em vez de troca seca.

**6.5 — baixa — "Penugem" em quem não tem.** O topete de filhote
(`pet.dart:3521-3543`) é desenhado em **todas** as espécies, inclusive
tracajá e axolote (`grade-9x5-idle.png`, coluna 1). Tartaruga recém-nascida
tem casco liso, e larva de axolote não tem tufo (laudo 05 §4.1). Isso
contradiz o critério biológico do próprio arquivo (`crescimento.dart:15-17`).
O buldogue recém-nascido de olho fechado aparece com dentes. *Correção:*
topete só em mamíferos e aves; tirar os dentes do ninho e do filhote.

**6.6 — baixa — Escala da cena.** O bicho da cena tem 220×180 sem ampliação.
O ovo ocupa cerca de 50 dp numa tela escura inteira (`cena-owl-01-*.png`). O
laudo pede escala 1,4. *Correção:* `Transform.scale(1.4)` no palco.

**6.7 — baixa — Textos.**
- pt "Sigam juntos." e es "Sigan juntos." usam masculino genérico, e o app
  tem sexo do companheiro. Sugestão: "Sigam lado a lado." / "Sigan a la
  par.".
- zh "少年" (adolescente humano) para "jovem"; "亚成体" ou "青年" leem melhor
  para bicho (sugestão; confirmar com falante nativo).
- "ADULTO · Faltam 20 sessões para crescer" num bicho adulto soa estranho.
  Considerar "para o auge" a partir do adulto.

**6.8 — baixa — Paywall contra o ADR.** O ADR-024 §7 diz que paywall é
vitrine e segue adulto, mas `paywall_screen.dart:32` passa `app.estagio`.
Uma das duas coisas precisa mudar (no código, o bicho do paywall é o da
pessoa, então talvez seja o ADR).

**6.9 — baixa — Numeração da migration.** O cabeçalho diz "16"
(`20261026120000_baru_crescimento.sql:1`, `supabase_gateway.dart:236,244`,
ADR-024 §6), mas "16/16" já é `20260828100002_baru_daily_quests_sem_escritor.sql`,
citada como "migration 16" em `supabase_gateway.dart:318,620`.
*Correção:* renumerar (é a 18ª; a 17ª é `excluir_minha_conta`).

**6.10 — baixa — Contrato e regressão aceita.** O crescimento é regra de
produto nova (régua, nunca regride, nunca se compra), e o `PRODUCT.md` não
a menciona. O ADR-024 aceita que quem tinha um adulto com poucas sessões o
veja menor depois da atualização. Hoje é um teste fechado; vale reavaliar
antes de qualquer público (piso de "jovem" para contas antigas).

**6.11 — baixa — Borda de reinstalação com remoto sem a coluna.** Com o
banco ainda sem a migration, reinstalar e concluir uma sessão **offline**
antes do primeiro pull cria o mapa `{espécie: 1}`. O pull depois traz
`sessoes_concluidas` alto, mas o mapa já não está vazio e a semente não
roda: o bicho volta a filhote. Só acontece se a migration não for aplicada.
*Correção:* aplicar a migration 16/18 antes de liberar a versão, ou semear
pelo máximo entre o mapa e o total quando o remoto não tem a coluna.

### Capturas da loja

`test/capturas_loja_test.dart` põe 20 sessões em cada espécie, então os
bichos aparecem adultos. A home ganhou a barra de crescimento, que empurra o
conteúdo ~70 dp para baixo, e a barra diz "ADULTO · Faltam 20 sessões para
crescer". As capturas em `play-store/telas/` (fora do git) **não** foram
regeradas pelo commit. Antes e depois, regerado por mim no worktree:
`captura-loja-home-antes-depois.png` (à esquerda, a captura existente na
árvore de trabalho, gerada antes do commit). Aí também se vê o adulto nadando
com a água no queixo, o que já existia antes. Se a loja for usar estas telas,
considerar 40 sessões (pleno, "no auge") ou 20 com o texto revisto.

### O que não verifiquei

- Aplicação da migration no Supabase remoto.
- Som e háptico da cena em aparelho.
- Fonte CJK: o `flutter_tester` não tem fonte chinesa, então não há imagem
  em zh.

---

## Arquivos de evidência

`docs/auditoria/onda-2-itens-5-6/`:

- `grade-9x5-idle.png`, `grade-9x5-swim.png`, `grade-9x5-saudade.png`,
  `grade-9x5-gorro.png`: 9 espécies × 5 estágios (PetView, 2×).
- `app-filhote-na-agua.png`: problema 6.1, em tela inteira.
- `app-home-e-sessao-inicio.png`: problema 6.2 (ovo e ninho na home e na
  sessão).
- `cena-{owl-01,capybara-01,fox-34,penguin-23}-{mov,red}.png`: a cena aos
  200, 900, 1500, 1800, 2400, 2900, 3150, 3300, 3700 e 4700 ms, com e sem
  "reduzir movimento". A tarja escura sob o bicho é um `Text` de fundo do meu
  teste, renderizado na fonte de teste, atrás do véu; não faz parte do app.
- `overlay-quadros-buldogue-tigrado-gorro-filhote.png`: os 7 quadros e o
  bicho da home.
- `overlay-simulacao-3x.png`: a geometria da janela do overlay a 3×.
- `captura-loja-home-antes-depois.png`.

---

## Resposta às ressalvas (commit seguinte)

**Item 6**
- **6.1 (alta) — corrigido.** Nadando, o porte do estágio é aplicado a partir da
  linha d'água, não dos pés. Teste novo em `test/crescimento_test.dart` ("na água
  o filhote não afunda"): a fração do corpo fora d'água do filhote e do jovem fica
  a até 12 pontos da do adulto nas 5 espécies que nadam. Conferido que o teste
  falha sem a correção (capivara filhote: 15% fora d'água contra 47% do adulto).
- **6.2 (média) — corrigido.** `acaoNoEstagio` (pública, em `pet.dart`) é a fonte
  única da ação; a tela da sessão usa a mesma função e diz "está no ovo, quase
  pronto para nascer" / "está dormindo no ninho". A corujinha filhote não voa
  (rótulo "foco de 25 min").
- **6.3 (média) — corrigido.** O pleno ganhou detalhe nas 7 espécies que não
  tinham: flor do lago (lontra), florzinha (tracajá), guelras com brilho
  (axolote), crista dourada (pinguim), borboleta (gata e buldogue), joaninha
  (raposa).
- **6.4 (média) — corrigido.** A alternância de formas na cena virou esmaecer
  suave de 1 a 3 ciclos por segundo (antes: troca seca de até 30 por segundo).
- Baixos corrigidos: sem topete de penugem no tracajá e no axolote; sem dentes no
  buldogue recém-nascido e filhote; "Sigam juntos" → "Continue focando com
  {a}"; zh "少年" → "成长期"; ADR-024 §7 alinhado ao código (o paywall mostra o
  bicho da pessoa); a migration deixou de se chamar "16"; `PRODUCT.md` §4
  documenta a régua.
- Pendentes: bicho pequeno na cena (sem a escala 1,4 do laudo) e ninho/ovo
  boiando no lago — posicionamento do habitat, Onda 3. Capturas da loja não
  regeradas (as atuais seguem válidas como material de lançamento).

**Item 5**
- **5.1 (média) — corrigido.** Cada leva grava em arquivos novos (nome = FNV da
  aparência + instante); o Android só troca as preferências depois de conferir
  que os arquivos existem, num `commit` só, e apaga os da leva anterior. O Dart
  pergunta antes (`quadrosChave`) e não redesenha a aparência que o Android já
  tem; a versão do app entra na conta, então uma atualização redesenha.
- **5.2 (média) — corrigido em parte.** Rasteriza em `hidden`, não em `inactive`.
  Rasterizar no início da sessão (como pede o laudo 05) não foi feito: o
  `WidgetService` documenta que rasterizar com as animações da tela rodando
  derrubava o relógio dos `AnimationController`.
- Baixos sem mudança nesta rodada: tranco na piscada, decodificação na thread
  principal, teste do lado Kotlin.

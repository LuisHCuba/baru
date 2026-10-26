# Fase 4 — Simulador: o app usado tela a tela

Data: 2026-10-26. Testador independente ("simulador"). Não alterei código do
app e não fiz commit.

**O que foi testado.** O build web de release servido em
`http://127.0.0.1:8765` (`main.dart.js` das 18:29, equivalente ao commit
`c07640b`, compilado com `BARU_RELOGIO_RAPIDO=true`: 1 minuto de sessão = 1
segundo). O Supabase estava desligado e tudo ficou local. Depois desse build
entraram `ed32d81` ("Desfazer a compra") e `53d613d` (pulinhos do radiante).
Nada disso está no que vi.

**Como.** Escrevi um script Playwright reutilizável,
`baru_app/tool/simulador/simula.js` com `jornada.js` (instruções no
`README.md` ao lado). Ele percorre o app do zero num celular 412×892 com DPR
2. Rodei também os trechos-chave em 360×640 e 320×640.

- O relógio da página fica **pausado** e só anda quando o script manda. Por
  isso cada quadro de uma tira mostra a animação num instante exato (0, 100,
  200 ms…). Num Chromium headless com WebGL por software a home desenha só
  ~10 quadros/s em DPR 2, então gravar em tempo real enganaria.
- Os elementos são achados pela árvore de semântica do Flutter.

**Evidências.** Ficam em `docs/auditoria/fase-4-simulador/`:

- `412/`, `360/`, `320/`: capturas da jornada, as tiras de quadros em
  `quadros/`, `jornada.log` (cada passo, a rota e os nós da tela, mais os sons
  que o app pediu) e `console.log`.
- `extra-chapeu-e-voltar/`: a compra de uma roupa e o voltar durante a sessão.
- `412-validacao/`: trechos de uma segunda jornada completa com a versão
  final do script, em que todas as etapas passaram. Traz a tira da compra na
  loja e o voltar no resultado.
- `destaques/dNN-*.png`: montagens que provam os defeitos principais.
- `extra-execucoes-anteriores/`: quadros de execuções anteriores do mesmo
  build. Nessas, o relógio ainda não estava pausado, então os instantes das
  tiras são aproximados; o conteúdo dos quadros é o que o app desenhou.
- `sons-espectrogramas.png`: os 26 arquivos de som.

As PNGs foram reduzidas a 256 cores para caber no limite de tamanho. O
pontilhado que aparece nos degradês vem dessa compressão, não do app.

---

## Resumo executivo

O app **funciona de ponta a ponta sem erro**. Não houve nenhuma mensagem de
erro no console em nenhuma das jornadas. O estado sobrevive a recarregar a
página, inclusive no meio de uma sessão, com o relógio certo. As contas de
folhas, XP e missões batem com o extrato. O que pesa é a **experiência**, e
ela confirma quase todas as queixas do dono:

1. **O crescimento do bicho quase não se vê.** Filhote e jovem são o mesmo
   desenho, ~10% maior, na mesma pose e no mesmo lugar. O bicho ocupa cerca
   de ¼ da largura da cena.
2. **A jornada trava no passo 2 da trilha** para quem não deu acesso ao uso.
   Depois de 5 sessões e nível 2, a trilha continua em "Passo 2 de 22" por
   pelo menos mais 3 dias, e "3 sessões de foco" e "nível 3" não andam.
3. **O momento de recompensa tropeça.**
   - O fim da sessão tem um quadro fantasma que entrega o crescimento antes
     da cena.
   - A toca do marco e do nível não diz o que fazer.
   - As +20 folhas do marco não aparecem em lugar nenhum.
   - A cena de crescimento fica por cima do resultado com o fundo
     atravessando.
4. **A home e o relatório inventam tempo de tela.** Sem permissão eles
   mostram "0min" e "4h 30min abaixo da sua meta", o que viola o §8 do
   contrato. A própria tela "Seu tempo de tela" diz que o app "não estima nem
   inventa número".
5. **O bicho muda de uma tela para outra.** A roupa comprada some nos Ajustes,
   na prévia da sobreposição e no relatório. Fora do habitat o bicho
   "nadando" aparece com a linha d'água cortando o corpo sobre um fundo liso.
6. **A arte e o som parecem rascunho.**
   - Itens da loja: a vitória-régia são duas pílulas verdes.
   - A raiz é um traço ou um "parêntese" num quadrado rosa.
   - A toca é uma meia-lua chapada.
   - Os sons são todos sintetizados, na mesma família de três notas, sem voz
     de espécie.
7. **As animações-chave são cortes secos.** A troca de pergunta do quiz, a
   revelação do animal, a entrada na home, a ida da home para a sessão e o
   fecho da cena de crescimento não têm transição.

**Contagem:** 5 altos, 17 médios, 14 baixos (36 no total). A lista está
abaixo.

---

## Jornada percorrida (412×892)

O número entre parênteses é o prefixo do arquivo em `412/`. Para uma tira,
o caminho é `412/quadros/NNN-*.png`.

### 1. Onboarding

**Idioma (001, 002).** Os quatro idiomas aparecem em cartões grandes, e
trocar para English traduz a tela na hora. A primeira barra de progresso
acende.

**Idioma → promessa (tira 003).** A troca de tela é um corte seco.

**Promessa (004).** Mostra a capivara adulta, a frase "Deixe o celular de
lado…" e o botão **"Começar foco"**. O botão não começa foco nenhum: leva ao
quiz.

**Voltar do navegador na promessa (005).** Não faz nada: o onboarding inteiro
fica num endereço só (`#/comecar`), sem histórico.

**Quiz (006–019).** São seis perguntas, uma por tela, e escolher já avança.

- As perguntas não têm "?".
- Na troca de pergunta (tira 008) a opção tocada **não chega a aparecer
  marcada**: o quadro 0 já mostra a pergunta seguinte, sem deslize nem fade.
- "Voltar uma" funciona e mantém a resposta marcada (010).
- **Recarregar na pergunta 4 volta para "1/6"** (012, 013). As respostas
  ficam guardadas e a barra continua meio cheia, mas a pessoa tem de passar
  pelas perguntas de novo.
- O voltar do navegador no quiz não faz nada (017).

**Revelação (tira 021; 022–030).** O texto "Você é uma capivara." e o bicho
adulto aparecem **inteiros já no primeiro quadro**: não há entrada, suspense
nem animação. Depois que a tela termina de entrar, o bicho só respira.

- Ao rolar, o texto passa por baixo da barra de progresso (024).
- Tocar numa espécie bloqueada ("Pinguim") não faz nada nem explica como
  liberar (026).
- Trocar para coruja ou tartaruga muda o título para "Você é uma coruja" e
  troca o nome padrão (027, 028).
- O nome é cortado em 18 caracteres sem aviso: "Pipoca de Milho Do" (029).
- Os seis tons de pelagem são marrons quase iguais.

**Meta (031, 032).** Só oferece 3h, 4h, 5h e 6h. A conta da meta está clara:
"3h 45min / 25% abaixo da sua média".

**Permissões (033–035).** São dois cartões, "Acesso ao uso" e
"Notificações". O "Sem ela:" vem em vermelho, num tom de alerta. Os botões
"Agora não" e "Concluir" são links de texto. Na web o pedido de notificação
é recusado (limite da web) e o botão vira "Pedir de novo".

**Entrada na home (tira 036; 037).** Em 100 ms a home já está inteira, sem
nenhum momento de "bem-vindo" nem apresentação do bicho no habitat. O bicho
que a pessoa acabou de ver adulto agora é um **recém-nascido dormindo num
ninho que boia no lago**. Nenhuma frase explica a troca: só o cartão
"NINHO — Falta 1 sessão de foco para Pipoca abrir os olhos".

### 2. Home

**Primeira tela (037, 038–042).** A frase principal da primeira home é

> "Ainda não houve sessão de foco hoje. E sem o acesso ao uso eu não meço a
> sua tela, então hoje eu leio o dia só pelo foco."

Ao lado vem o chip "Raiz de 0 dias". Logo abaixo, "O relatório de hoje está
pronto", sem nada no dia. O botão **"Começar foco" fica no fim da lista**,
depois de nove blocos: habitat, crescimento, legenda, relatório, 7 dias, uso,
nível, missões e loja. É preciso rolar cerca de 1,5 tela em 412×892 e quase 3
telas em 320×640.

**Toque no bicho (tira 043).** O bicho achata um pouco num único quadro e
solta faíscas pequenas. Em ~200 ms tudo volta ao normal. O pedido de som foi
`toque_*.wav`.

**Carinho (tiras 044, 045).** Arrastei por 1,4 s. Aparecem os olhos fechados
de prazer e corações de ~6 px que sobem. Funciona, mas é miúdo na escala da
cena. O som de "afago completo" (`carinho_*.wav`) não foi pedido com esse
gesto.

**Chips 25/50/90/Livre (046).** Mudam de estado. Com "Livre" não aparece
nenhum seletor de minutos. Não verifiquei qual duração ele usa.

**Telas de detalhe e voltar.**

- **Folhas (047).** Estado vazio claro.
- **Raiz (049).** O desenho é um quadrado rosa com um ponto.
- **Relatório (051).** Mostra "0min tempo de tela hoje" e "4h 30min abaixo
  da sua meta" sem permissão (defeito 1).
- **Tempo (053).** O estado vazio é honesto: "não estima nem inventa número".
- **Missões (055).**
- **Loja (059).**

Em todos esses detalhes o voltar do navegador leva de volta à home.

### 3. Primeira sessão (25 "min" = 25 s)

**Entrada (tira 063).** A home some num corte para a sessão. Logo de cara um
aviso escuro — "Sem 'desenhar sobre outros apps'…" — cobre o botão
"Desistir" (064).

**A sessão (064–066).** Fundo creme liso, o bicho no ninho com quatro
faíscas, o relógio grande e uma barra fina. Não há habitat. O relógio pula de
minuto em minuto por causa do modo rápido, o que é esperado.

**Fim (tira 067 do run final; quadro a quadro em
`destaques/d02-quadro-fantasma-fim-da-sessao.png`).** No último quadro antes
do resultado, a tela da sessão vira:

- "BANHO DE 25 MIN";
- "Pipoca está nadando.";
- o bicho **já filhote, de olhos abertos, dentro d'água**.

Em seguida o resultado mostra o filhote, e só depois vem a cena "Pipoca abriu
os olhos!". Ver o defeito 2.

**Resultado (068, tira 067).** A sequência:

1. "+0 folhas" conta até "+10".
2. Folhas voam até o saldo, que pulsa de 0 a 18, 26, 29 e por fim **30**.
3. A barra de XP enche, e o "+5 da raiz" aparece em outro tom.

Essa parte é boa.

**Cenas.**

- **Raiz (069, tira 070).** O painel sobe de baixo, um ponto vira traço e o
  contador vai de 0 a 1. "Continuar" fica desabilitado por ~150 ms. O
  desenho é um traço marrom num retângulo bege.
- **Crescimento (071, tira 070).** "Continuar" na raiz fecha a cena num
  corte. Por um quadro o resultado reaparece inteiro (100 ms) e só depois o
  véu escurece. A cena fica por cima do resultado com o véu translúcido:
  atrás aparecem o filhote do resultado e os textos (defeito 10). Depois vêm a
  silhueta branca, um flash cinza na tela toda e as folhas
  (`extra-execucoes-anteriores/a-069-…`).
- **Marco (073, tira 074).** Aparecem só "Marco alcançado" e uma meia-lua
  marrom com um furo, **sem instrução e sem botão** (defeito 3). Cavando três
  vezes, abre um círculo com o bicho e "Sua primeira sessão de foco", e ele
  **fecha sozinho em ~2 s**. As **+20 folhas** do marco não aparecem.

**Resultado final (078, tira 077).** "MISSÕES QUE ANDARAM" anima de 0/50
para **25/50** em "Faça um foco de 50 min" (defeito 13) e para 25/60 em
"Some 60 min de foco".

- "Compartilhar o habitat" abre uma folha que diz "Folha de compartilhamento
  nativa. A fase 1 compartilha um screenshot do habitat." (079).
- "Voltar ao habitat" funciona (tira 081).

**Home depois (082).** O bicho filhote nada no lago e a legenda diz "Uma
sessão de foco hoje, 25min no total.".

### 4. Desistência, recarregar e voltar no meio da sessão

**Pedir para desistir (084–086).** O diálogo diz "Pipoca está no meio de um
banho. Sair agora encerra a sessão sem folhas. Nada mais muda." Os botões
são "Ficar com ele" (cheio) e "Sair mesmo assim". "Ficar" volta à sessão.

**Recarregar no meio da sessão (087).** A sessão continua com o relógio
certo: 15:54, depois 6,5 s de relógio, depois 08:53. Confirmei também com
relógio real, fora do script: 22:00, depois 7,6 s, depois 14:38.

**Voltar do navegador na sessão (088; `destaques/d05`).** Leva à home
**sem perguntar**. A sessão segue correndo, invisível, e 25 s depois o app
**pula sozinho** para o resultado. Ver o defeito 7.

**Sair (tira 090; 091, 092).** A tela de desistência mostra o bicho contente
e diz "Pipoca sentiu sua falta. Sem folhas desta vez, e nada foi perdido.
Ela continua aqui." Na home o bicho aparece **de cara triste** no habitat
noturno, com a legenda "Uma sessão de 25min parou no meio hoje". Isso segue
o contrato (§3, ADR-020), mas a sequência "sentiu sua falta" + cara triste
logo depois de desistir lê como cobrança.

### 5. Sessão de 50 min, nível 2, missões e loja

**Sessão de 50 (093–102, tiras 095–100).** Resultado com "+25 folhas" e
"+30 XP".

- A celebração de **Nível 2** é de novo a toca sem dica (096).
- Aberta, ela mostra "Nível 2 / Pipoca está mais em casa." (098).
- As missões viram "Pronta para colher" com o botão "Colher" (101).

**Missões (103–114, tiras 107–110).**

- **"A principal de hoje" é "Descanse 40 minutos seguidos"**, que exige o
  acesso ao uso negado (defeito 12).
- "Colher as 2 de uma vez" abre uma folha com a dica "Tem algo enterrado
  aqui / Toque na terra para cavar". Três toques abrem o buraco, a folha sobe
  com "+42 folhas" e o saldo anima de 55 para 97.
- Depois aparece "Tudo feito por hoje. O próximo passo da trilha te espera."
  com a missão principal ainda em 0/40.
- O cartão de cada missão diz "Resgatar"; o lote e o resultado dizem
  "Colher".

**Loja (115–119; compra de roupa em `extra-chapeu-e-voltar/`).**

- Itens que dá para levar mostram o preço. Os outros mostram só "Faltam N",
  sem o preço.
- **Tocar no cartão já compra**, sem confirmação. A cena "É seu!" é um cartão
  que aparece com fade e escala em ~1 s
  (`extra-chapeu-e-voltar/quadros/003-compra-chapeu`,
  `412-validacao/quadros/116-loja-compra`). Neste build não há "Desfazer";
  ele entrou no commit seguinte.
- A vitória-régia entra no habitat como **duas pílulas verdes no canto
  inferior esquerdo** (122, 130).
- O chapéu de palha aparece no habitat e na sessão, mas **não** nos Ajustes,
  na prévia da sobreposição nem no relatório (`destaques/d09`).

### 6. Crescimento (sessões 4 a 6)

**Sessões 4 e 5 (tiras 121, 124).** Sem cena.

**Sessão 6 (128, tira 129).** A cena é "Pipoca cresceu! / AGORA: JOVEM".

**Na home (130).** A diferença do filhote (102, 122) para o jovem é pequena
(`destaques/d08`).

**Trilha depois de tudo isso (132, 133).** "Passo 2 de 22. Fechar um dia
abaixo da meta, 1/4. Faltam 3 dias seguidos de presença" (defeito 4).

### 7. Abas, ajustes, paywall, idioma

**Abas (131–150).** A troca de aba é um deslize lateral (tiras 131, 139,
144).

- A **Trilha** é um caminho com nós e "VOCÊ ESTÁ AQUI".
- Os **Ajustes** mostram o cartão do bicho com a linha d'água atravessando o
  corpo (145).

**Detalhes dos Ajustes (152–169).**

- **Sobre outros apps** traz uma prévia do balão com o bicho, sem roupa.
- **Sua conta** diz "Você ainda não tem conta neste aparelho" e só oferece
  "Apagar meus dados". Não executei o apagar.
- **Seu animal interior** mostra **lontra (passo 7), tartaruga (passo 8) e
  coruja (passo 17) com cadeado** (158; defeito 11).
- **Meta** usa passos de 15 min.
- **Duração da sessão** lista 25, 50, 90 e **45**, nessa ordem (164).
- **Idioma** e **Política** são folhas que sobem.

**Paywall (170).** Acessado por `#/assinatura`; sem cobrança na loja não há
entrada visível. Mostra anual e mensal, "Começar 7 dias grátis", "Avisamos
24h antes", Restaurar, Termos e Privacidade. **Não tem botão de fechar**: só
o voltar do sistema tira a pessoa de lá.

**Endereços diretos (172–182).** Tempo, sequência, relatório, folhas,
sobreposição e conta abrem certo. O extrato de folhas explica tudo:
sessões +65, marcos +20, missões +42, Vitórias-régias −40.

**Idioma (184–189).** O 中文 sai em quadradinhos nos Ajustes (fonte ausente
no navegador headless, limite do ambiente). O English aparece certo, com
"1-day roots" no chip.

### 8. Telas menores (`360/`, `320/`)

Mesma jornada até a desistência. Em 360 não achei nada quebrado além do que
aparece em 412, mais a pelagem que quebra em 5+1 (360) e 4+2 (320). Em 320:

- **Permissão (033).** O rodapé "Você revê tudo em Ajustes › Sobre outros
  apps" é cortado pelo "Agora não".
- **Home.** "Falta 1 sessão de foco para Pipoca abrir os o…" e "Raiz de 0 …"
  saem truncados.
- **Sessão (068).** O aviso escuro cobre o "Desistir" inteiro.
- **Cena de crescimento (075).** O título atravessa o texto do resultado, e
  o "Compartilhar o habitat" de trás aparece **através** do botão
  "Continuar".
- **Resultado (083).** A segunda missão fica atrás dos botões fixos; o
  "25/60" tem 1 px visível.

---

## Defeitos

Severidade: **alta** quebra o contrato, trava a jornada ou estraga o momento
central; **média** confunde ou fica feio de forma visível; **baixa** é
detalhe. Os passos usam a jornada do script (`jornada.js`); o atalho manual
vem entre parênteses.

### Altos

**1. Tempo de tela inventado sem permissão.** *Home e Relatório.*

- **Reproduzir:** no onboarding, "Agora não" no acesso ao uso, depois
  Concluir. Na home, o cartão "0min de 4h 30min / faltam 4h 30min"; em
  Relatório, "0min tempo de tela hoje" e "4h 30min abaixo da sua meta".
- **Contrato:** o §8 diz "Sem permissão o app não estima nem inventa: mostra
  estado vazio". A tela Tempo cumpre isso; a home e o relatório não.
  - Código: `report_screen.dart` e `home_screen.dart` usam `app.usage` e
    `usageVerdict` sem olhar `usageAccess` (`state.dart:1214-1224`).
- **Evidência:** `destaques/d01-tempo-de-tela-inventado.png`; `412/051`,
  `412/039`, `412/053`.
- **Sugestão:** sem permissão, o cartão da home e o bloco do relatório viram
  o mesmo estado vazio da tela Tempo, com "Permitir" a um toque.

**2. Quadro fantasma no fim da sessão; o crescimento aparece antes da cena.**
*Sessão → Resultado.*

- **Reproduzir:** a primeira sessão de 25 min até o fim. No último quadro da
  sessão, o rótulo "FOCO DE 25 MIN · dormindo no ninho" vira "BANHO DE 25 MIN
  · Pipoca está nadando" e o bicho aparece já filhote, na água.
- O resultado também desenha o bicho já crescido antes de "Pipoca abriu os
  olhos!". A cena de crescimento deixa de ser surpresa.
- **Evidência:**
  - `destaques/d02-quadro-fantasma-fim-da-sessao.png` (quadros de 1750,
    1875 e 2000 ms);
  - a tira inteira em
    `extra-execucoes-anteriores/a-066-tira-fim-da-sessao-e-resultado.png`;
  - `412/068`.
- **Sugestão:**
  - congelar o retrato "antes" (estágio, humor e atividade) na tela da sessão
    durante a saída;
  - no resultado, usar o estágio de antes (`ResumoDaSessao`) até a cena de
    crescimento passar.

**3. A toca da celebração (marco e nível) não diz o que fazer.** *Cena de
conquista.*

- **Reproduzir:** a primeira sessão até o fim. Depois da cena "abriu os
  olhos", aparece "Marco alcançado" sobre uma meia-lua marrom. Não há dica
  nem botão, e tocar fora do monte não faz nada (o véu não fecha, de
  propósito).
- O título é pequeno e cai em cima do "Nível 1 … +12 XP" do resultado, que
  continua visível atrás.
- A mesma toca nas Missões tem "Tem algo enterrado aqui / Toque na terra
  para cavar". Na celebração (`celebracao.dart`, `_aToca`) essa linha não
  existe.
- **Evidência:** `destaques/d03-toca-do-marco-sem-instrucao.png`; `412/073`,
  `412/096`, `412/108`.
- **Sugestão:**
  - reaproveitar a dica e o cabeçalho da toca das missões;
  - escurecer mais o véu ou tirar o resultado de baixo;
  - mostrar o prêmio pelo nome.

**4. A trilha para no passo 2 para quem não deu acesso ao uso.** *Trilha.*

- **Reproduzir:** recusar o acesso ao uso e fazer 5 sessões no dia (nível 2).
  A trilha continua em "Passo 2 de 22 — Fechar um dia abaixo da meta, 1/4,
  Faltam 3 dias seguidos de presença".
- "3 sessões de foco" (passo 4) e "Chegar ao nível 3" seguem com cadeado,
  porque a corrente (ADR-017) só deixa o passo 2 passar com 4 dias seguidos.
- O título promete uma coisa que a pessoa não pode fazer (fechar o dia
  abaixo da meta). Isso explica a "jornada limitada" de que o dono reclamou.
- **Evidência:** `destaques/d07-trilha-parada-sem-permissao.png`;
  `412/130`, `412/132`, `412/133`.
- **Sugestão:**
  - sem permissão, mostrar o critério alternativo como título;
  - ou deixar marcos de sessão e de nível andarem em paralelo ao de
    presença;
  - ou mover o marco de presença para depois de "3 sessões" e "nível 3".

**5. O crescimento do bicho é pouco visível.** *Home, sessão e resultado.*

- **Reproduzir:** comparar a home com 0, 1 e 5 sessões.
  - O ninho é a mesma cabeça adulta, de olhos fechados, num ninho de
    gravetos.
  - Filhote e jovem são o mesmo desenho, na mesma pose, com a mesma linha
    d'água. O jovem é só uns 10% maior.
- O bicho ocupa cerca de ¼ da largura da cena e quase metade dele fica
  debaixo d'água.
- **Evidência:** `destaques/d08-crescimento-pouco-visivel.png`; `412/038`,
  `412/102`, `412/130`.
- **Sugestão:**
  - proporções diferentes por estágio (cabeça grande e corpo curto no
    filhote, corpo alongado no jovem);
  - um traço novo por estágio que se veja a 1 metro;
  - o bicho maior na cena;
  - não pôr o corpo debaixo d'água bem no estágio novo, logo depois da cena
    de crescimento.

### Médios

**6. As +20 folhas do marco ficam escondidas.** O resultado diz "+10 folhas"
e o saldo vai a 30. A celebração aberta mostra só "Sua primeira sessão de
foco" e fecha em ~2 s (`Tempo.celebracao` 900 ms + 1100 ms). Só o extrato
diz "Marcos da trilha +20".

- **Evidência:** `destaques/d04`; `412/078`, `412/176`; tira
  `412/quadros/067` (saldo indo a 30).
- **Sugestão:** o prêmio do marco no rótulo da toca ("+20 folhas"); a
  celebração fica até um toque, ou no mínimo uns 3 s.

**7. O voltar do navegador sai da sessão sem perguntar.**

- **Reproduzir:** começar uma sessão e usar o voltar do navegador. A home
  aparece sem nenhum aviso de sessão rodando; quando o tempo acaba, o app
  pula sozinho para o resultado.
- Na web o voltar chega por `setNewRoutePath`, que não passa pelo pedido de
  confirmação. Não verifiquei se um deep link no Android, como os do widget
  (`baru://…`), faz o mesmo durante uma sessão.
- **Evidência:** `destaques/d05`; `extra-chapeu-e-voltar/010–013`;
  `412/088`.
- **Sugestão:** `abrePorEndereco` com sessão em andamento deve pedir
  confirmação ou ignorar o endereço; e a home deve mostrar uma faixa "sessão
  em andamento".

**8. O voltar no resultado reabre a sessão terminada.** Do resultado, o
voltar do navegador vai para `#/sessao`, que mostra 00:00, "Pipoca está
nadando" e o botão "Desistir" ativo. Com a folha de compartilhar aberta, a
folha fica presa por cima e pode empilhar com a toca do marco.

- **Evidência:** `destaques/d06`;
  `extra-execucoes-anteriores/c-079`, `c-080` e `b-099`.
- Reproduzido de novo na validação: `412-validacao/192–195` (rota
  `/resultado` → `/sessao`).
- **Sugestão:** a rota `/sessao` sem sessão ativa vai para a home; e o voltar
  fecha primeiro as folhas modais também na web.

**9. A roupa some fora do habitat e o bicho nada fora d'água.**

- O chapéu comprado não aparece nos Ajustes, na prévia "Assim que vai
  aparecer" da sobreposição, nem no relatório.
- No código, o `PetView` sem `roupas` aparece também em `paywall_screen`,
  `saida.dart`, `widget_service`, `crescimento.dart:138` e na tela de
  desistência.
- Nos Ajustes e no relatório o bicho usa a atividade "nado", e a linha
  d'água cruza o corpo sobre um fundo liso.
- Esse é o "pet da sobreposição diferente do da pessoa" na parte que dá para
  ver na web. A sobreposição nativa não foi verificada.
- **Evidência:** `destaques/d09`; `extra-chapeu-e-voltar/006–009`;
  `412/145`.
- **Sugestão:** um único "retrato do bicho", com roupa e com uma atividade
  neutra fora do habitat, usado por todas as telas.

**10. A cena de crescimento fica por cima do resultado.** O véu é
translúcido: atrás aparecem o filhote e os textos "25 minutos concluídos",
"Dia feito…". Em 320, o "Compartilhar o habitat" atravessa o botão
"Continuar" (cena 075). No quadro de 900 ms há um flash cinza na tela toda.

- Entre a raiz e o crescimento, o resultado pisca aceso por um quadro
  (tira `412/quadros/070`, 100 ms).
- **Evidência:** `destaques/d10`; tiras `412/quadros/070` e
  `extra-execucoes-anteriores/a-069-…`; `320/075`.
- **Sugestão:** véu opaco ou cena em tela própria; o flash pode existir, mas
  como brilho no bicho, não como véu cinza na tela inteira.

**11. As espécies de origem ficam travadas depois do onboarding.** No
onboarding lontra, tartaruga e coruja são livres. Escolhida a capivara, os
Ajustes mostram lontra "Abre no passo 7", tartaruga "passo 8" e coruja
"passo 17". O §4 do contrato diz que as quatro de origem saem do quiz. Pelo
código, `progressao.dart` entrega lontra e tartaruga como prêmio de marco.

- **Evidência:** `destaques/d11`; `412/027`, `412/158`.
- **Sugestão:** decidir e escrever no contrato. Se ficam travadas, o
  onboarding deve avisar "as outras você conquista na trilha"; se não, abrir
  as quatro nos Ajustes.

**12. "A principal de hoje" é uma missão impossível sem permissão.**
"Descanse 40 minutos seguidos" exige o acesso ao uso negado e fica no topo,
em destaque, com 30 folhas. Depois de colher as outras, o app diz "Tudo
feito por hoje" com ela pendente.

- **Evidência:** `412/103`, `412/111`.
- **Sugestão:** sem permissão, a principal sai do sorteio entre as que
  dependem de foco, e o convite para conceder fica num cartão à parte.

**13. "Faça um foco de 50 min" mostra 25/50 depois de uma sessão de 25.** A
missão pede uma sessão única de 50, mas a barra enche pela maior sessão do
dia e sugere que falta "meia sessão".

- **Evidência:** `412/078`; tira `412/quadros/077`.
- **Sugestão:** progresso binário (0/1) ou "maior sessão hoje: 25 de 50 min",
  dito assim.

**14. A primeira home não recebe ninguém.**

- A primeira frase é técnica e negativa ("Ainda não houve sessão… sem o
  acesso ao uso eu não meço…").
- O chip diz "Raiz de 0 dias" e "O relatório de hoje está pronto" aparece
  vazio.
- "Começar foco" só aparece depois de rolar.
- A troca de bicho adulto para recém-nascido no ninho não é explicada.
- **Evidência:** `destaques/d15`; `412/037–042`; tira `412/quadros/036`.
- **Sugestão:**
  - uma primeira home com uma frase de boas-vindas e "Comece a primeira
    sessão para Pipoca nascer";
  - o CTA fixo acima da barra de abas, ou logo abaixo do habitat;
  - esconder relatório, 7 dias e uso até haver dado.

**15. Cortes secos nas transições centrais.**

- A troca de pergunta do quiz (tira 008) não mostra a opção escolhida.
- A revelação do animal (tira 021) não tem entrada.
- Onboarding → home (036) e home → sessão (063) são cortes.
- As cenas de raiz e de crescimento somem num corte ao tocar "Continuar"
  (tiras `412/quadros/070` e `extra-execucoes-anteriores/a-071-…`).
- O dono reclamou de "animações limitadas"; estes são os pontos onde se
  sente.
- **Sugestão:**
  - marcar a escolha por ~250 ms antes de avançar;
  - entrada do bicho na revelação (subir com um pulinho);
  - transição compartilhada do habitat entre a home e a sessão.

**16. O aviso "Sem 'desenhar sobre outros apps'…" cobre o "Desistir".** Ele
aparece ao começar a sessão e fica sobre o único botão da tela. Em 320 o
cobre inteiro. Na web o texto, que fala de uma permissão do Android, também
não se aplica.

- **Evidência:** `412/064`, `320/068`; tira `412/quadros/063`.
- **Sugestão:** levar o aviso para o topo, ou para um cartão na home antes de
  começar; e não mostrar na web.

**17. Cortes e textos truncados em 320×640.**

- O rodapé da permissão é cortado.
- A segunda missão do resultado fica atrás dos botões fixos.
- "Raiz de 0 …" e "abrir os o…" saem truncados.
- **Evidência:** `destaques/d12-telas-pequenas-320.png`; `320/033`, `320/083`,
  `320/038`.
- **Sugestão:** um respiro inferior igual à altura dos botões fixos e
  textos de duas linhas nesses cartões.

**18. O paywall não tem botão de fechar.** Só se sai dele pelo voltar do
sistema. A loja de apps e o tom "sem culpa" pedem um "Agora não" visível.

- **Evidência:** `destaques/d14`; `412/170`.

**19. Texto de desenvolvedor visível na folha de compartilhar.** "Folha de
compartilhamento nativa. A fase 1 compartilha um screenshot do habitat." é
a chave `shareNote` em `l10n.dart`.

- **Evidência:** `destaques/d14`; `412/079`.
- **Sugestão:** trocar por um texto de produto, ou remover.

**20. A arte parece rascunho em pontos de recompensa.**

- **Itens da loja:** a vitória-régia são duas pílulas verdes; o lampião é
  uma gota laranja. No habitat a vitória-régia fica quase invisível no canto.
- **Raiz:** o cartão "Sua raiz" é um quadrado rosa com um ponto (dia 0) ou um
  ")" (dia 1). A cena é um traço marrom num bloco bege.
- **Toca:** uma meia-lua chapada cortada reta embaixo.
- Isso confirma os "elementos gráficos desconexos e amadores".
- **Evidência:** `destaques/d13`, `destaques/d16`; `412/115`, `412/049`,
  `412/069`.

**21. A resposta ao toque e ao carinho é fraca para o tamanho da cena.**

- O toque é um achatamento de um quadro com faíscas pequenas (tira 043).
- No carinho os corações têm ~6 px (tira 044). Em 1,4 s de arrasto o som de
  afago completo não foi pedido.
- **Sugestão:** reação de corpo inteiro (pulinho, olhar para o dedo), com
  partículas maiores e um som a cada toque.

**22. Os sons têm pouca identidade.**

- São 26 arquivos `.wav`, todos sintetizados (`tool/sons/gera_sons.py`).
- Conquista, crescimento, fim, marco, chegada, carinho e resgate usam as
  mesmas notas (Fá5 698 Hz, Lá5 880 Hz, Dó6 1047 Hz) e se distinguem mais pela
  duração (0,3 a 2,6 s) do que pelo timbre.
- Não há voz de espécie: o próprio `som_service.dart` diz "até a voz de cada
  espécie chegar".
- O app pediu os sons certos nos momentos certos (ver `jornada.log`), mas não
  verifiquei se eles soam, porque o navegador é headless e não tem áudio.
- **Evidência:** `sons-espectrogramas.png`.
- **Sugestão:** timbres distintos por família de evento, e uma voz curta
  gravada por espécie no toque e no crescimento.

### Baixos

23. **Recarregar no quiz volta para "1/6".** As respostas ficam e a barra
    continua meio cheia. Evidência: `412/012–013`.
24. **O voltar do navegador não faz nada no onboarding.** Não há histórico
    por passo (limite de projeto na web). Evidência: `412/005`, `412/017`.
25. **Rótulos de acessibilidade duplicados.** Um leitor de tela ouve "Água,
    Água", "Desistir, Desistir", "Habitat, Habitat" (nós em `jornada.log`).
26. **Textos do onboarding.** As perguntas do quiz não têm "?", e o botão
    "Começar foco" da promessa leva ao quiz. Evidência: `412/004`, `412/006`.
27. **Espécie bloqueada no onboarding.** O toque não explica como liberar.
    Evidência: `412/026`.
28. **Pelagem.** Seis tons quase iguais, que quebram 5+1 em 360 e 4+2 em
    320. Evidência: `360/024`, `320/025`.
29. **Revelação.** Ao rolar, o texto passa por baixo da barra de progresso.
    Evidência: `412/024`.
30. **Nome cortado em silêncio.** O limite de 18 caracteres não mostra
    contador. Evidência: `412/029`.
31. **Meta.** Só há 3h, 4h, 5h e 6h; quem usa menos de 3h ou mais de 6h não
    acha a sua. Evidência: `412/031`.
32. **Duração da sessão nos Ajustes.** Fica fora de ordem (25, 50, 90, 45),
    e os chips da home não têm 45. Evidência: `412/164`.
33. **Dois verbos para a mesma ação.** O cartão diz "Resgatar", o lote e o
    resultado dizem "Colher". Evidência: `412/104`, `412/101`.
34. **"+42 folhas" na toca das missões.** O texto é verde-escuro sobre o
    buraco escuro (baixo contraste) e já aparece, apagado, antes de cavar.
    Evidência: tira `412/quadros/109`.
35. **Textos.**
    - "1-day roots" em inglês (`412/187`).
    - "Bem-vindo de volta" no masculino para quem respondeu "Não dizer"
      (`412/101`).
    - "Crescimento completo" no estágio adulto, quando ainda existe o
      "pleno" (`l10n.dart:778`; só pelo código).
36. **Promessa da assinatura.** O paywall promete "a loja completa do
    habitat", mas nada na loja é restrito — pendência já listada para o dono
    na síntese. Evidência: `412/170`.

---

## O que funciona bem

- **Estabilidade.**
  - Nenhum erro de console em quatro jornadas (412, 360, 320 e a extra).
  - Nenhuma tela em branco no app. A única tela em branco foi quando o voltar
    do navegador saiu da página, o que é normal na web.
  - Nenhum botão sem resposta.
- **Persistência.** Recarregar mantém a tela e o estado: sessão com o
  relógio certo, loja, rota, nome, pelagem e respostas do quiz. Deep link
  por endereço abre a tela certa.
- **As contas batem.** As folhas e o XP do resultado batem com o extrato (+65
  de sessões, +20 de marcos, +42 de missões, −40 da compra), e o extrato
  explica cada número.
- **Resultado.** Bem coreografado na parte de cima: o contador sobe, as
  folhas voam até o saldo, que pulsa a cada chegada, e o XP e o bônus da raiz
  aparecem em tons diferentes. A desistência não pune e diz isso com clareza.
- **Missões.** "Colher as 2 de uma vez" com a toca é o melhor momento de
  recompensa do app: tem dica, três toques, o prêmio sobe e o saldo anima. A
  tela "Seu tempo de tela" sem permissão é honesta.
- **Cena de crescimento.** A silhueta branca e a explosão de folhas são uma
  boa ideia (é o "evoluir" que se espera); o problema é o fundo (defeito 10).
- **Compra.** A roupa aparece na hora no habitat e na sessão, e o extrato
  registra a compra.
- **Consistência.** A paleta e a tipografia (Nunito) são coerentes; a troca
  de idioma é instantânea; a troca de abas desliza.

---

## O que não verifiquei, e por quê

- **Recursos do aparelho** — limites da web e do ambiente:
  - som audível (navegador headless, sem saída de áudio; só vi que o app
    *pediu* os `.wav`);
  - háptico, notificações, a sobreposição nativa (o balão Kotlin com os
    quadros do bicho), o acesso ao uso, o widget da tela inicial;
  - o botão voltar do Android (`popRoute`): na web o voltar é o do navegador
    e passa por outro caminho (`setNewRoutePath`).
- **Fonte chinesa.** O 中文 sai com quadradinhos nos Ajustes; é fonte
  ausente no navegador, não julguei o texto.
- **Conta e assinatura.** Login, criar conta, compra e restauração no
  paywall, e "Apagar meus dados": o Supabase está desligado e não há loja.
- **Desempenho.** O ambiente renderiza por software (~10 quadros/s na home
  em DPR 2, ~32 em DPR 1). As tiras foram feitas com relógio controlado, não
  medem engasgo real. A fluidez num aparelho não foi medida.
- **Progresso que exige vários dias:** raiz de vários dias, congelamento,
  virada do dia, missões semanais, trilha depois do passo 2, estágios
  adulto e pleno, nível 3 em diante, outras espécies crescendo, cena noturna
  versus diurna lado a lado.
  - A cena ficou noturna porque o relógio de verdade do ambiente estava à
    noite.
- **Acessibilidade.** Tamanho de fonte do sistema (`textScaleFactor`) não é
  acessível pelo navegador; testei larguras 360 e 320 no lugar. Também não
  verifiquei "reduzir movimento" nem o leitor de tela de verdade.
- **"Livre".** Qual duração a sessão "Livre" usa.
- **Diálogo de desistir.** O texto "no meio de um banho" com o bicho ainda
  no ninho, porque só capturei o diálogo com o bicho nadando.
- **Build.** Não verifiquei o build mais novo: o que vi é anterior a
  `ed32d81` ("Desfazer a compra") e `53d613d`.

---

## Resumo

**5 altos · 17 médios · 14 baixos** (36 no total).

Altos:

1. Home e relatório inventam "0min / abaixo da meta" sem permissão (§8).
2. Quadro fantasma no fim da sessão revela o crescimento antes da cena.
3. A toca do marco e do nível não tem instrução nem saída.
4. A trilha para no passo 2 sem acesso ao uso (jornada travada por dias).
5. O crescimento filhote → jovem é quase invisível.

Médios:

6. As +20 folhas do marco não aparecem em lugar nenhum.
7. O voltar do navegador sai da sessão sem perguntar e o app pula sozinho
   para o resultado.
8. O voltar no resultado reabre a sessão terminada e prende a folha.
9. A roupa some e o bicho "nada" fora d'água nos Ajustes, na prévia da
   sobreposição e no relatório.
10. A cena de crescimento fica sobre o resultado, translúcida, com flash
    cinza.
11. Lontra, tartaruga e coruja ficam travadas nos Ajustes depois de livres no
    onboarding.
12. "A principal de hoje" é impossível sem permissão.
13. "Foco de 50 min" mostra 25/50.
14. A primeira home é negativa, sem boas-vindas, com o CTA fora da tela.
15. Cortes secos no quiz, na revelação, onboarding → home e home → sessão.
16. O aviso da sobreposição cobre o "Desistir".
17. Cortes e textos truncados em 320.
18. O paywall não tem fechar.
19. Texto de desenvolvedor na folha de compartilhar.
20. Arte rudimentar de itens, raiz e toca.
21. Resposta fraca ao toque e ao carinho.
22. Sons sintetizados da mesma família, sem voz de espécie.

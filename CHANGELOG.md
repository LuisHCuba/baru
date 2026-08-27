# Changelog

Formato: entradas por data, agrupadas em Adicionado / Corrigido / Alterado /
Removido. Datas em AAAA-MM-DD.

## 2026-08-27 — ticker que não para, e um vazamento que nasceu com o botão "Tirar"

O relato foi um assert do Flutter **web** em laço:
`"Trying to render a disposed EngineFlutterView"`. Ele é lançado quando um
quadro é desenhado depois de a view morrer — na prática, em hot restart com
animação em laço rodando. Auditei o que o app mantém vivo e achei dois
problemas de verdade.

### Corrigido

- **Animação em laço não parava com o app fora da tela.** O companheiro
  respira e a cena deriva com `repeat()`, que pede quadro para sempre. Agora
  os dois param em `inactive`, `hidden`, `paused` e `detached`, e voltam em
  `resumed`. É bateria no telefone — e no web é justamente o que segue
  pedindo quadro depois de a view sumir.
- **Vazamento de memória que nasceu com o botão "Tirar".** Cada objeto de cena
  ganha um `AnimationController` de chegada. Antes um item nunca saía do
  habitat, então ninguém reparava; com "Colocar/Tirar", cada retirada deixava
  um controller órfão no mapa, e recolocar criava outro por cima sem descartar
  o primeiro.

### Uma correção minha, no meio do caminho

Eu tinha escrito que o controller órfão "continua pedindo quadro" e por isso
causava o assert do web. **Está errado**: a chegada é um `forward()` que
termina, e controller parado não pede quadro. Descobri isso porque a mutação
não derrubou o teste — o `flutter_test` só acusa ticker **animando**. Refiz o
teste com uma costura que conta os controllers vivos, e aí a mutação cai.

O vazamento é real e vale corrigir; ele só não é a causa do assert. Quem pede
quadro para sempre é `repeat()`, e disso cuida a pausa por ciclo de vida —
essa sim verificada por mutação.

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: 408+ passando
- As duas correções verificadas por mutação, cada uma no seu teste.

## 2026-08-27 — as oito espécies do `baru-pets.html`

### O QUE MUDOU NA TELA

**Quatro espécies novas**, tiradas do arquivo e reproduzidas no painter — o
SVG usava `translate(100 85)`, exatamente a origem do `_PetPainter`, então a
geometria traduziu direto:

- **Lume, o axolote.** Três guelras de cada lado, com ritmo próprio: elas
  abanam mais quando ele está na água.
- **Nino, o pinguim.** Barriga quase branca, nadadeiras dobradas que abrem ao
  respirar, pés laranja com três dedos, bico triangular — o único traço reto
  do elenco.
- **Mel, a gata.** Orelhas triangulares com concha, listras na testa, nariz em
  coração invertido e bigodes longos dos dois lados.
- **Faísca, a raposa.** Orelhas grandes de ponta escura em três camadas, cauda
  em pluma com a ponta clara, focinho longo.

Cada uma com **paleta própria** (rosa-lilás, azul-ardósia, mel-cinza,
laranja-queimado) e nome nos quatro idiomas.

**Todas se desbloqueiam na trilha**, não no quiz: quiz é quem você é, trilha é
o que você conquistou.

| Espécie | Marco |
|---|---|
| Axolote | 20 sessões de foco |
| Pinguim | 15 dias abaixo da meta *(marco novo)* |
| Gata | 30 dias seguidos presente |
| Raposa | 100 sessões de foco |

E as roupas servem nas oito: a peça é desenhada no sistema de coordenadas da
cabeça de cada espécie e escalada por ele.

### Corrigido no caminho

- A nadadeira do pinguim passava do contorno do corpo e sobrava uma fresta do
  fundo entre as duas — lia como risco branco no bicho.
- A cauda da raposa saía estreita e para cima: lia como braço levantado.

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: 400+ passando
- `especies_test.dart` compara os **pixels** das oito duas a duas: duas
  espécies com o mesmo desenho seriam um `case` esquecido caindo no padrão.
- Evidência: `folha-especies.png` (8 × 4 humores), `folha-roupas.png`
  (8 × 5 peças), `especie-*.png`

### Migration 12

`baru_pets.species` tinha `check` com uma lista fechada de quatro. Cada
espécie nova exigiria uma migração, então ele sai — quem tem o catálogo é o
app, e `parseSpecies` já cai na capivara diante de um valor desconhecido.

## 2026-08-27 — "não foi possível sincronizar (pet, loja)": causa e conserto

### Corrigido

**A causa era uma só, e o nome de dois domínios enganava.**
`LocalPetRepository.pushRemote` chama `pushPet` **e** `pushShop`; a falha
estava só na segunda, e derrubava as duas. A falha: o app passou a escrever
`baru_inventory_items.equipped`, coluna inventada no mesmo turno e ainda
ausente no banco remoto (migration 11).

Três consertos:

- **O app degrada em vez de quebrar.** Coluna nova que o banco ainda não tem
  virou `ColunaAusenteNoRemoto` (PostgREST `PGRST204`, Postgres `42703`). O
  inventário sobe; só o "em uso" fica no aparelho até a migração ser
  aplicada. Lembrado por sessão, para não repetir a tentativa que já se sabe
  que falha.
- **`ignoreDuplicates: true` escondia um segundo defeito:** ele preserva o
  `acquired_at` de quem já estava lá, mas também **não atualiza nada** numa
  linha existente — colocar e tirar um item já comprado nunca chegaria ao
  remoto. Agora são duas escritas: uma cria o que é novo, outra manda só
  `equipped` (o upsert só toca nas colunas do corpo, então `acquired_at`
  continua intacto).
- **O aviso do arranque mostrava `{q}` cru.** A leitura falhando usava a
  mensagem da escrita, que ganhou um marcador de domínio que ali não existe.

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: **396 passando, 1 pulado**
- Sonda REST no projeto remoto: migrations 7, 8, 9 e 10 aplicadas; a 11 não.

## 2026-08-27 — a loja virou guarda-roupa, e a trilha voltou a fazer sentido

### Corrigido

**A trilha dizia "VOCÊ ESTÁ AQUI" no último nó com os primeiros apagados.**
Duas coisas somadas, e as duas eram minhas:

- O dado estava corrompido pela perda no arranque (corrigido no commit
  anterior): o XP sobrevivia porque tinha coluna remota, e
  `sessoesConcluidas` não — daí "nível 3 conquistado" com "primeira sessão"
  em aberto.
- E o `proximoMarco` apontava para o **mais perto de fechar**, não para o
  primeiro em aberto. Num caminho isso manda a frente para o fim da trilha.
  Agora `proximoMarco` é o primeiro em aberto — é o que um caminho significa
  — e "o que dá para fechar hoje" virou `marcoMaisPerto`, outra pergunta.

**`ItemSwatch` estourava** (`reduce` em lista vazia) para itens sem peças de
cena, e `t.items[...]` era indexado pela posição em `shopItems`: com dezessete
itens no lugar de oito, `RangeError` na home. Nome de item agora se resolve
por id.

### O QUE MUDOU NA TELA

- **A loja tem três seções e cada uma diz a sua regra.** Objetos do habitat
  (pode ter todos), roupas (uma peça por lugar do corpo) e cenários (um por
  vez, muda o mundo inteiro).
- **Ter deixou de ser o mesmo que usar.** Todo item comprado tem "Colocar" e
  "Tirar". O habitat é seu; você decide o que fica nele.
- **Cinco roupas**: chapéu de palha, coroa de folhas, gorro de lã, cachecol e
  óculos redondos. Desenhadas no sistema de coordenadas da cabeça de cada
  espécie e escaladas por ele — a mesma peça serve na capivara larga e na
  tartaruga pequena, sem código por espécie.
- **Quatro cenários**: entardecer, noite estrelada, chuva mansa e neblina da
  manhã. Cenário comprado ganha da hora do dia — senão comprar "noite
  estrelada" às 14h não mudaria nada.
- Na loja, a miniatura de roupa mostra **o bicho vestindo**. Um quadradinho
  colorido não vende roupa.

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: 390+ passando
- Evidência: `folha-roupas.png` (4 espécies × 5 peças), `tela-loja.png`

### Migration 11

`baru_inventory_items.equipped`, com `default true` — o inventário que já
existe foi comprado quando comprar era o mesmo que colocar, e marcar como
não-equipado esvaziaria o habitat de quem já tinha itens. Também derruba o
`check` de ids fechado: eram oito, agora são dezessete e cada item novo
exigiria uma migração.

## 2026-08-27 — perda de dado no arranque, e o companheiro por cima dos outros apps

### Corrigido — e era perda de dado, não bug de tela

**Missão resgatada voltava a aparecer por resgatar a cada vez que o app
abria.** A causa não era a missão: o arranque montava um `AppSnapshot` das
linhas do remoto e gravava **por cima** do snapshot local. Todo campo sem
coluna remota voltava ao padrão.

Não era só a missão. Iam junto `sessoesConcluidas`, `melhorSequencia` e
`diasAbaixoDaMeta` — **os três contadores que a trilha inteira lê** — mais os
contadores do dia e da semana.

Duas correções, e as duas eram necessárias:

- `AppSnapshot.fundeCom`: o arranque **funde** em vez de sobrescrever.
  Contador que só sobe fica com o maior; conquista vira união; o que é do dia
  fica com o aparelho; o resto é do remoto. Isso protege o dado **mesmo com o
  banco desatualizado**.
- Migration 10: `missoes_resgatadas`, `sessoes_concluidas`,
  `melhor_sequencia` e `dias_abaixo_da_meta` em `baru_progression`, para o
  dado chegar ao segundo aparelho.

### O QUE MUDOU NA TELA

- **O companheiro aparece por cima dos outros apps.** Passou o tempo de tela,
  ele dá um oi no canto com um balão e dois botões: "Fechar o app" e "+5 min".
  É `TYPE_APPLICATION_OVERLAY` de verdade, desenhado em `Canvas` nativo —
  overlay não pode depender do motor do Flutter estar vivo, já que ele aparece
  justamente quando você está noutro app.
- **Não bloqueia e não insiste.** `FLAG_NOT_TOUCH_MODAL`: o toque fora do
  balão continua indo para o app de baixo. Some sozinho em 12 s. No máximo 4
  vezes por dia, com 25 minutos entre uma e outra.
- **Tela nova "Sobre outros apps"** com a **pré-visualização** antes de pedir
  a permissão. `SYSTEM_ALERT_WINDOW` é a mesma permissão que malware usa:
  pedir sem mostrar é o jeito mais rápido de ser negado.

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: 375+ passando
- `AppSnapshot.fundeCom` verificado por mutação: trocado por `=> this`,
  quatro testes de persistência falham.

### Não entregue neste pedido

Widget de tela inicial, widget de tela de bloqueio, ícone do launcher e as
espécies novas do `baru-pets.html`. Cada um é trabalho nativo de um turno.
Ver `docs/BACKLOG.md` — **inclusive por que "widget de tela de bloqueio" não
existe como API no Android entre a 5 e a 14.**

## 2026-08-27 — conta, trilha em caminho, e três defeitos que o usuário viu antes de mim

### Corrigido

- **O seletor de pelagem mostrava seis bolinhas e só quatro respondiam.**
  `setColor` fazia `clamp(0, 3)` — travado na paleta antiga de quatro cores,
  esquecido quando cada espécie ganhou seis tons. Trocar de espécie também
  podia deixar um índice inválido para trás.
- **A trilha dizia "você está no passo 1" para quem já tinha conquistado o
  passo 3.** Duas causas: `proximoMarco` devolvia o primeiro não alcançado na
  ordem da lista, e a fração do marco de **nível** era medida a partir de
  zero — mas o nível começa em 1, então "chegar ao nível 3" nascia com um
  terço da barra cheia numa conta nova. Agora o próximo passo é o **mais perto
  de acontecer**, e a fração respeita o piso de cada tipo.
- **"Não foi possível sincronizar" não dizia o que falhou.** São seis domínios
  e treze tabelas. A mensagem agora nomeia o domínio (pet, loja, ajustes,
  sessões, assinatura, progresso) e o erro cru vai para o log.

### O QUE MUDOU NA TELA

- **A trilha virou um caminho.** Nós grandes que serpenteiam, linha sólida no
  trecho conquistado e tracejada no que falta, ícone por tipo de marco,
  "VOCÊ ESTÁ AQUI" no nó atual com halo pulsando, e o nome e a recompensa ao
  lado de cada um. Tocar num nó abre o detalhe com o progresso exato.
- **Tela nova "Sua conta"**: e-mail com aviso de não confirmado, desde quando
  o companheiro existe, trocar e-mail, trocar senha, recuperar senha, o plano
  e sair. Trocar e-mail avisa o que realmente acontece — o Supabase manda um
  link e o login só muda depois do clique.
- **O voltar na home pergunta antes de fechar**, com o bicho na folha e a
  frase de que nada se perde. Fechar sem avisar é o gesto que uma companhia
  não faz. Insistir no voltar sai; "Ficar mais um pouco" cancela.
- **O botão de debug saiu da tela.**

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: 350+ passando
- Os três defeitos foram verificados por mutação: reintroduzido o
  `clamp(0, 3)` e a fração antiga, os testes correspondentes falham.

## 2026-08-27 — telas novas, cores por espécie, ajustes e transição sem fantasma

### O QUE MUDOU NA TELA

- **As folhas e a sequência agora levam a algum lugar.** Eram os dois únicos
  números do app que mudavam sozinhos e não podiam ser tocados. "Suas folhas"
  mostra de onde cada folha veio (sessões, marcos, missões), onde foi gasta, e
  as últimas que você ganhou com data. "Sua sequência" mostra a atual, a
  melhor, os congelamentos e o próximo marco.
- **A transição entre telas parou de ser fantasma.** As páginas não tinham
  fundo próprio — o `Scaffold` da casca fica atrás do `Navigator` — então dava
  para ver uma tela através da outra durante o cross-fade. Agora cada página é
  opaca e a saída acontece **antes** da entrada, à moda do eixo compartilhado
  do Material.
- **Cada espécie tem a própria paleta.** Havia uma lista de marrons para as
  quatro: a tartaruga era marrom. Agora ela é oliva e musgo, a lontra é
  chocolate escuro, a capivara é castanho-avermelhado e a coruja é ruivo e
  cinza-pardo.
- **A capivara virou capivara.** Cabeça quase retangular, focinho rombudo
  ocupando o terço de baixo da cara, focinheira escura, orelhas pequenas e
  afastadas, olhos altos. Antes era um urso.
- **A tartaruga virou tartaruga.** Casco oliva-amarronzado com duas fileiras de
  escudos de verdade, plastrão, e a listra laranja atrás do olho —
  tartaruga-de-orelha-vermelha. Sem bochecha rosada: réptil não cora.
- **A meta é editável.** Eram quatro chips (90/120/150/180). Agora é passo de
  15 min entre 30 min e 8 h, com os valores comuns como atalho.
- **O relatório da noite tem horário.** Estava escrito `21` no código.
- **O companheiro tem sexo**, e isso muda o pronome: em português e espanhol
  "ele te esperou" e "ela te esperou" são frases diferentes.
- **Ajustes encurtou.** Cada assunto virou uma linha com o valor atual à
  direita; idioma, meta, horário, espécie, pelagem e sexo abrem em folha.

### Corrigido

- O subtítulo do relatório dizia "Todo dia às 21h" fixo — mentira assim que o
  horário virou preferência. Agora acompanha o valor.
- A linha de duração da sessão mostrava `banho de {m} min`: um template do
  catálogo usado como rótulo, com o placeholder cru na tela.

### Adicionado

- `lib/data/carteira.dart`: o extrato de folhas, e **honesto sobre o que o app
  não guardou** — compras e marcos não têm data, e o histórico para nas
  últimas 80 sessões.
- Rotas `/folhas` e `/sequencia`.
- `CabecalhoDeDetalhe` e `LinhaDeValor` em `componentes.dart`: o cabeçalho
  estava privado numa tela só, e com três telas de detalhe copiar era garantir
  que uma ficasse diferente.
- Migration 9 `baru_evening_time_and_sex` — aditiva e idempotente.
- `test/ajustes_test.dart` (12).

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: **337 passando, 1 pulado** (eram 324)
- Evidência visual: `tela-folhas.png`, `tela-sequencia.png`, `tela-ajustes.png`

### Som

- Cinco sons curtos, todos abaixo de 0,6 s: conquista, resgate de missão, fim
  de sessão, toque no bicho e afago completo. Chave própria em Ajustes.
- **Eu não os ouvi.** Foram sintetizados (senoides em escala pentatônica com
  envelope), não gravados, e áudio não se captura em teste de widget. O que
  está provado é o formato (WAV mono 44,1 kHz/16 bits), a duração, a ausência
  de clique no início e no fim, a ausência de clipping — e toda a lógica:
  desligado não toca, dois sons colados viram um, falha de áudio não sobe, e
  áudio que **nunca responde** não deixa future pendente (timeout de 2 s).
- `AudioPlayer` abre um `EventChannel` no construtor e exige o binding do
  Flutter: num teste de unidade puro isso estoura fora do `try`, noutra zona.
  O player só nasce depois que o app arma o serviço.

## 2026-08-27 — navegação, carinho e o elenco refeito

### O QUE MUDOU NA TELA

- **O botão voltar do Android funciona.** Era a queixa: em qualquer tela ele
  fechava o app. Agora tem pilha de verdade: num detalhe volta um passo, numa
  aba que não é a home volta para a home, e só na home ele sai. Durante uma
  sessão de foco ele **pergunta** em vez de descartar o foco em silêncio.
- **As telas entram com transição, não com corte seco.** Irmãos deslizam de
  lado, filho entra em profundidade, modal sobe de baixo — e a barra de
  destinos é fixa: ela sobrevive à troca de tela.
- **Cada tela tem endereço** (`/trilha`, `/missoes`, `/tempo`…): o app tem deep
  link, e na web a barra do navegador mostra onde você está.
- **Dá para acariciar o Baru.** Passe a mão nele: ele acompanha a mão com o
  olhar, encosta a cabeça, aperta os olhinhos de contentamento, o pelo se
  levanta sob o dedo e sobem coraçõezinhos. A mão **ronrona** — um clique curto
  a cada tanto de percurso.
- Afago completo rende **+3 XP** com um rótulo que sobe do bicho, e o
  **Vínculo** aparece na trilha ("Vínculo · 23 afagos").
- **Capivara, lontra e tartaruga foram refeitas.** Eram de perfil: um corpo-ovo
  comprido com uma cabeça-ovo colada na ponta. Agora são personagens de frente,
  na mesma construção da coruja — cabeça grande, cara legível, corpo compacto,
  membros visíveis. A capivara ganhou o focinho rombudo que a define; a lontra,
  bigodes dos dois lados e focinheira escura; a tartaruga virou casco-corpo com
  a cabeça saindo por cima.

### Corrigido

- **"Erro ao sincronizar" a cada gravação.** Causa encontrada e provada por
  sonda REST: `baru_app_categories` **não existe no projeto remoto**, e
  `pushSettings` faz um `delete` nela em toda gravação, mesmo sem nenhuma
  reclassificação. O que dependia deste lado está feito — a migração existe,
  foi validada em banco limpo, e o app parou de chamar isso de falha de rede.
  Aplicar no remoto é do humano: **BL-10**.
- Tabela ausente no remoto agora tem tipo próprio (`TabelaAusenteNoRemoto`) e
  mensagem própria em 4 idiomas, dizendo **qual** tabela falta. Antes o app
  dizia "não foi possível sincronizar" e tentava de novo para sempre — mentira
  em dois níveis: não é falha de rede, e tentar de novo nunca resolve.
- XP, nível celebrado e marcos existiam **só no aparelho**: nenhuma coluna
  remota. Desinstalar zerava a trilha. Agora vão para `baru_progression`.

### Adicionado

- `lib/navegacao.dart`: classificação de rota (destino/detalhe/modal/fluxo),
  `PaginaBaru` com transição derivada do tipo, `BaruRouterDelegate` e
  `BaruRouteParser`. `MaterialApp` virou `MaterialApp.router`.
- Migration 8 `baru_progression` (xp, nível celebrado, marcos, afeto, carinhos
  do dia) com RLS e as 4 políticas.
- `Balanco.carinhosPorDia` (5) e `Balanco.xpPorCarinho` (3).
- `test/navegacao_test.dart` (17) e `test/carinho_test.dart` (11).

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: **324 passando, 1 pulado** (eram 296)
- `supabase db reset` em banco limpo: 8 migrations, 15 tabelas, **0 sem RLS**,
  58 políticas
- RLS de `baru_progression` provada em SQL: A vê 1 linha, `UPDATE 0` e
  `DELETE 0` na linha de B, `anon` vê 0
- Os testes de voltar-do-sistema e de carinho foram verificados por mutação

## 2026-08-27 — arte e reações do companheiro

### O QUE MUDOU NA TELA

- **Cada bicho virou um bicho.** A silhueta é desenhada em camadas de anatomia
  com curvas de Bézier — corpo, barriga, membros, cauda, cabeça, focinho,
  olhos — no lugar dos retângulos arredondados empilhados. A lontra tem
  bigodes e cauda grossa que afina; a tartaruga tem cúpula com escudos,
  plastrão e cabeça pequena; a coruja tem disco facial, tufos de base larga e
  ponta afiada, asas dobradas sobre o corpo e **pés pousados com três dedos**.
- **Ele faz coisas sozinho.** A cada 7 a 15 s ele se espreguiça (com bocejo e
  olhos fechados), sacode a cabeça, ou olha em volta. Só quando está à toa:
  nadando, pastando ou dormindo o corpo já tem o que fazer.
- **Insistir no carinho aparece na tela.** Do terceiro toque em 3 s em diante
  sobem coraçõezinhos. O háptico já ficava mais forte; a tela não mudava.
- Ele **olha para onde você tocou** e a cabeça acompanha o olhar.
- A piscada tem intervalo irregular e às vezes é dupla.

### Corrigido
- **A orelha ficava levantada depois do toque.** `AnimationController.forward`
  termina em 1.0 e fica lá; só o agendador do tremor resetava, até dez
  segundos depois. Na orelha redonda o defeito se escondia (`sin(2π) = 0`),
  mas o tufo da coruja é linear e ficava torto. Teste em
  `pet_vivo_test.dart` captura os pixels no repouso e depois da reação e
  exige que sejam iguais.
- Com "reduzir movimento" o tremor de orelha do toque não acontecia. O §7
  manda reduzir amplitude, não apagar o retorno.
- Os tufos da coruja eram cortados pelo topo do quadro ao se espreguiçar: ela
  nascia com 3 px de folga.
- As asas da coruja chegavam a ±56 num corpo de ±47 e liam como um halo
  escuro atrás dela, não como asas dobradas.
- Os riscos de pena vazavam a silhueta da asa e pareciam arranhões no fundo.
- Os bigodes da lontra saíam do quadro de 200×150.
- O plastrão da tartaruga era um fio branco entre o casco e as patas.

### Adicionado
- `GestoOcioso` e o rig de gesto em `pet.dart`.
- Costuras de teste `PetView.observadorDeGesto` e `PetView.gestoForcado`,
  nulas em produção: o gesto é disparado por `Timer` com sorteio, e sem elas
  não há como afirmar que aconteceu nem capturar um gesto específico.
- Seis PNGs de reação em `docs/evidence/2026-08-27/` (`reacao-1..6`).
- Sete testes novos em `pet_vivo_test.dart`, todos verificados por mutação:
  removida a funcionalidade, o teste falha.

Portões: `flutter analyze` sem issues, `flutter test` **296 passando e 1
pulado**, 13 testes de evidência verdes em três execuções seguidas.

## 2026-08-27 — turno de produto

### O QUE MUDOU NA TELA

- O Baru **respira, pisca e dá uma quicada quando você toca nele**.
- O habitat ganhou céu em gradiente, sol ou lua com halo, colinas que derivam
  e reflexos andando na água.
- **O habitat às 22h não é mais igual ao das 9h**: céu índigo, água escura,
  lanterna acesa.
- Comprar um item o faz **cair na cena com mola**, com sombra por baixo.
- Tela nova **"Seu tempo de tela"**: quanto conta para a meta, quanto foi no
  total, a quebra por categoria em barras coloridas e a lista por aplicativo
  com nome legível. **O Spotify aparece como Áudio, fora da meta.**
- Tocar num app abre a folha de reclassificação, e o número da meta muda na
  hora.
- Aba nova **"Trilha"**: nível, barra de XP, quanto falta, o próximo passo em
  destaque e doze marcos ligados por uma linha.
- **Subir de nível toma a tela** com partículas e háptico.
- Aba nova **"Missões"**: progresso x de y, recompensa exata em folhas e XP,
  prazo, e um botão "Resgatar" que faz **o saldo de folhas subir animado**.
- A **sessão de foco aparece na barra de notificações**, com contagem
  regressiva viva e botão "Desistir".
- A home mostra o **nível de verdade** no lugar de "Habitat nível N", que era o
  número de itens dividido por três.

Portões: `flutter analyze` sem issues, `flutter test` 289 passando e 1 pulado,
integração 7/7 contra Supabase local, 7 migrations aplicando em banco limpo,
33 PNGs de evidência.

### Adicionado
- Design system em código (`lib/design/tokens.dart`) e sistema de movimento
  (`lib/design/motion.dart`).
- Nunito empacotada em `assets/fonts`; `google_fonts` sai das dependências.
- Contabilidade de tempo de tela (`lib/data/tempo_de_tela.dart`): reconstrução
  de intervalos por par de eventos, quatro categorias de produto, exclusões de
  sistema, tabela de 57 apps e reclassificação pelo usuário (ADR-009).
- Progressão (`lib/data/progressao.dart`): XP, curva de nível, doze marcos,
  espécies desbloqueáveis. Todos os números de balanceamento num arquivo só.
- Missões (`lib/data/missoes.dart`): três diárias e duas semanais, sorteio
  determinístico e resgate idempotente (ADR-010).
- Telas: `tempo_screen`, `trilha_screen`, `missoes_screen`.
- Componentes canônicos: `ContadorAnimado`, `BarraAnimada`, `CartaoBaru`,
  `Etiqueta`, `EstadoVazio`, `Esqueleto`, `Celebracao`.
- Notificação viva da sessão com cronômetro do sistema (ADR-011).
- Migration 7: `baru_app_categories` com RLS e CHECK.
- Evidência visual gerada por teste (`test/evidencia_test.dart`).

### Corrigido
- **Spotify tocando no bolso contava como tempo de tela.** Contava também
  launcher, system UI, teclado e o próprio Baru.
- **O companheiro não se movia** — nenhum `AnimationController` no `PetView`.
- **A cena não conhecia a hora do dia.**
- **O toque no bicho não funcionava**: `deferToChild` sobre um `CustomPaint`
  sem filho nunca recebe hit-test.
- Com "reduzir movimento" ligado, o Flutter encurtava o controller para 5% e a
  quicada do toque acabava antes de ser vista.
- **"Habitat nível N" era o número de itens dividido por três.**
- **As quests anunciavam "+10" e "+15" e não creditavam nada.**
- Missão em andamento aparecia rotulada como "concluída".
- O chip de sequência e o cartão de uso truncavam na home.

### Alterado
- A barra de destinos passa a ser **Habitat · Trilha · Missões · Ajustes**.
  Loja e relatório viram telas de detalhe com botão de voltar.
- `LeafBadge` usa contador animado: o saldo sobe em vez de saltar.
- `usage` passa a ser o tempo **contabilizado** (dispersivo + neutro), não a
  soma bruta de foreground.

## 2026-08-26 — turno noturno

Portões ao fim do turno, executados: `flutter analyze` sem issues,
`flutter test` 151 passando e 1 pulado, integração 5/5 contra o stack local,
`supabase db reset` aplicando as 6 migrations num banco limpo.

### Adicionado
- **Bônus de +15 folhas por fechar o dia abaixo da meta** (contrato §5). A
  quest e o relatório anunciavam o bônus e nenhum código creditava. Pago na
  virada do dia (ADR-005).
- **Aviso de 24h antes do fim do trial** (contrato §9). A copy do paywall
  prometia o recado e não havia agendamento.
- **Sessão de foco resiliente**: `sessionStartedAt`/`sessionEndsAt` persistidos,
  retomada ao abrir o app, conclusão de sessão que venceu com o app fechado
  (ADR-008).
- Migration `20260827000000_baru_adopt_rls_auto_enable.sql`: adota no
  repositório a função e o event trigger que só existiam no banco (ADR-002).
- `supabase/config.toml` e `supabase/seed.sql`.
- Suítes novas: `l10n_test`, `mood_test`, `economy_test`, `calendar_test`,
  `session_test`, `sync_test`, `trial_test`, `app_frame_test`,
  `auth_lang_test` e `test/integration/supabase_roundtrip_test`.
- Controle de versão: repositório git, branch `night/2026-08-26`, remote
  `LuisHCuba/baru` (ADR-001), `.gitattributes`.
- Documentação viva: `README.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`,
  `docs/DATA_MODEL.md`, `docs/DECISIONS.md`, `docs/BACKLOG.md`,
  `docs/BLOCKERS.md`, `docs/STATE.md` e este arquivo.

### Corrigido
- **Crash em en/es/zh**: 5 chaves de i18n só existiam em pt e `T.s()` faz cast
  para `String`. `syncFail` é usada com o idioma do usuário, então qualquer
  falha de sincronização derrubava o app dentro do próprio handler de erro.
- **A faixa "esta semana" nunca zerava na virada** de domingo para segunda:
  dias que ainda não aconteceram apareciam como presentes (ADR-006).
- **`todayIndex` desandava** em relação ao calendário depois de ausência longa,
  e o ponto de "hoje" apontava o dia errado (ADR-006).
- **`daysAway`** passa a ser fato de data. O congelamento o zerava, então
  `missing_you` só aparecia no terceiro dia, e o contrato diz dois.
- **Sincronização perdia a intenção** quando um domínio falhava: a máscara era
  zerada antes do push e um erro abortava os quatro domínios seguintes
  (ADR-007).
- **Moldura de desktop aparecia dentro do celular** deitado; a orientação
  passa a ser travada em retrato no mobile.
- **A porta de entrada falava só português** num app de quatro idiomas.
- Mudança efêmera (folha de compartilhamento, humor forçado, flag de debug)
  disparava push das 13 tabelas, e estado de debug vazava para a conta real.
- `_ready` do gateway ficava preso em `true` após expiração de sessão.
- Migration 5 quebrava ao ser reaplicada — as guardas por
  `information_schema` não protegiam nada (ADR-003).
- `SUPABASE_ENABLED` no `.env` era inerte.
- `.gitignore` deixava `android/build/` e `**/.cxx/` entrarem no versionamento.

### Alterado
- Push de sessões em lote (era um round-trip por sessão, até 80) e remoção de
  inventário numa chamada só.
- `acquired_at` do inventário preservado entre pushes.
- Pull remoto do login em paralelo (eram dez consultas em série).
- A folha de desistência não pausa mais o relógio da sessão — decorrência de
  medir pelo relógio de parede, e mais honesta: olhar a folha já é mexer no
  telefone.
- `baru_app/README.md` deixa de ser boilerplate e aponta para os docs.

### Removido
- E-mail pessoal da conta de teste em `supabase/README.md` — o remote é
  público (ADR-004).
- Referências a `seed_test_user.ps1` e `seed_test_user.sql`, que não existiam.

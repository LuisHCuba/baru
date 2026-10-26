# Laudo 06 — Capivara (Baru), lontra (Rio) e tartaruga (Toco)

Pesquisa dedicada a cada pet, com jornada e visuais próprios. Outubro de 2026.

**Legenda usada em todo o laudo**

- **[F]** fato com fonte (link na linha ou na seção "Fontes", ao final);
- **[O]** observação do app (arquivo:linha ou imagem que eu abri);
- **[I]** inferência ou opinião minha, sem fonte que a prove.

**Limites desta pesquisa.** O limite de buscas na web da sessão acabou antes
de eu confirmar dois pontos: o status nacional (ICMBio) da lontra-neotropical
e o do tracajá. Eles ficam marcados como "não verificado". Algumas fontes
(SciELO, Kglmeridian, repositório da UFAM) devolveram 403/503. Quando li só o
resumo pelo indexador, eu digo isso.

---

## 0. Resumo em 12 linhas

1. [O] Os três bichos são **o mesmo boneco** com pelos diferentes: medi a
   sobreposição das silhuetas (alfa > 20) nas artes `pet-*-contente.png`, e
   capivara × lontra dá **IoU 0,83**. É mais parecido que gata × raposa (0,85
   é o único par acima).
2. [O] O humor mora só no rosto. Entre "contente" e "saudade" mudam **2,8%**
   dos pixels na capivara, 3,0% na lontra e 2,3% na tartaruga. O corpo não muda.
3. [O] Há um **defeito** na tristeza: a sobrancelha e a pálpebra caída não são
   espelhadas (`pet.dart:3605-3625`). Um olho fica triste e o outro bravo, e a
   cara de "saudade" sai desconfiada.
4. [O] A lágrima (`_pingo`, `pet.dart:3996-4008`) é desenhada em coordenada
   fixa do widget. Na tartaruga ela flutua no ar, longe do rosto.
5. [O] Os bichos já são desenhados em **proporção de filhote**: a cabeça tem a
   largura do corpo e ocupa 48% a 60% da altura. Não sobra para onde "crescer".
   O estágio adulto vai exigir uma silhueta nova, mais próxima do bicho real.
6. [F+O] A tartaruga do app é uma tartaruga-de-orelha-vermelha
   (`pet.dart:94-96`, `1829-1832`). É uma **espécie exótica com potencial
   invasor no Brasil**. Recomendo trocar pelo **tracajá** (*Podocnemis
   unifilis*), que é amazônico e aquático. As manchas amarelas dele, fortes no
   filhote e mais fracas no adulto, já são um estágio de crescimento visível
   pronto.
7. [F] A "lontra" brasileira é a *Lontra longicaudis*. Os filhotes nascem cegos,
   abrem os olhos com cerca de 44 dias, saem da toca com cerca de 52 e entram na
   água com a mãe com cerca de 74. Boiar de costas segurando pedra no peito é
   comportamento da **lontra-marinha**, não da nossa.
8. [F] A capivara nasce com pelo, de olhos abertos, anda e nada em poucas horas.
   Não existe "ovo de capivara". O estágio 1 dela é o recém-nascido escondido no
   capim.
9. Proposta: **5 estágios** derivados da trilha, que nunca regridem. As viradas
   ficam nos passos 1, 3, 11, 18 e 22, os mesmos em que hoje abre habitat (ou
   que fecham a trilha).
10. Cada espécie ganha **3 a 5 animações próprias** tiradas do comportamento
    real: ave pousada na capivara, malabarismo de seixos da lontra, pescoço
    dobrado de lado do tracajá.
11. Cada espécie ganha **sons próprios**, todos ligados a vocalizações reais de
    contato, nunca de alarme ou dor. Os prompts para o ElevenLabs estão
    descritos.
12. 7 itens por espécie, todos comprados com folhas e nenhum com dinheiro.
    Atenção: o §5 do `PRODUCT.md` ainda fala em "8 itens de posição fixa" e
    precisa de ADR (ver §7).

---

## 1. Achados que valem para os três

### 1.1 O que eu olhei

- As artes `play-store/arte/pet-{capybara,otter,tortoise}-{radiante,contente,sono,saudade}.png`
  (as 12 imagens);
- as homes `play-store/telas/pt/home-capybara.png`, `home-otter-noite.png`,
  `home-tortoise-entardecer.png` e `home-tortoise-noite.png`; a trilha
  `03-trilha.png`; o elenco `docs/evidence/2026-08-28/elenco-nove.png`;
- o código `baru_app/lib/widgets/pet.dart` (as funções `_capivara` 1498-1606,
  `_lontra` 1613-1715 e `_tartaruga` 1725-1854, o olho em 3551-3632, a boca em
  3648-3720, os gestos em 540-570, a lágrima em 3996-4008),
  `lib/widgets/pet_profile.dart`, `lib/data/progressao.dart`,
  `lib/design/tokens.dart:71-98` (pelagens) e `lib/models.dart:257-338` (loja).

### 1.2 Medições objetivas (feitas por mim, reproduzíveis)

Fiz a sobreposição das silhuetas com Python/PIL (alfa > 20, IoU), sempre na
arte "contente", 1200 × 960:

| par | IoU |
|---|---|
| capivara × lontra | **0,83** |
| capivara × coruja | 0,84 |
| lontra × gata | 0,84 |
| tartaruga × qualquer outra | 0,61–0,76 |

E a fração de pixels que muda entre dois humores (diferença RGBA > 60):

| espécie | radiante×contente | contente×sono | contente×saudade |
|---|---|---|---|
| capivara | 1,2% | 3,5% | 2,8% |
| lontra | 2,0% | 3,1% | 3,0% |
| tartaruga | 0,8% | 2,4% | 2,3% |

[I] Em 1,2% dos pixels, "radiante" e "contente" são indistinguíveis no tamanho
real da home, onde o bicho tem uns 280 px de largura numa tela de 1080. O
dono do produto pediu "muito mais qualidade" nas emoções, e é isso que os
números mostram: a emoção não chega ao corpo.

### 1.3 Problemas comuns, com local

| # | Observação [O] | Onde |
|---|---|---|
| C1 | A pálpebra caída de neutro/triste corta os dois olhos **na mesma direção**: sobe para a direita nos dois. No olho direito a borda externa fica alta, o que é o desenho de raiva. | `pet.dart:3605-3616`; visível em `pet-capybara-saudade.png` |
| C2 | A sobrancelha de tristeza vai de (-0,9r, -1,5r) a (0,5r, -1,1r) nos **dois** olhos, sem espelhar. No olho esquerdo a ponta interna fica baixa, que é a sobrancelha brava. | `pet.dart:3618-3624`; `pet-*-saudade.png` |
| C3 | A lágrima fica fixa em (30% da largura, 46% da altura) do widget, sem ligação com o rosto. Na tartaruga, de cabeça menor e mais alta, ela flutua no ar. | `pet.dart:3998`; `pet-tortoise-saudade.png` |
| C4 | A cor da lágrima tem alfa variando. Na capivara ela fica cinza sobre marrom e lê como "suor" ou "gota de chuva". | `pet-capybara-saudade.png` |
| C5 | O repertório ocioso é **o mesmo para as 9 espécies**: espreguiça, sacode, olha em volta, coça, fareja e saltinho. | `pet.dart:555-560` |
| C6 | O habitat é o mesmo lago para todas. A tartaruga e a capivara aparecem com a mesma linha d'água, a mesma pedra e o mesmo deque, na mesma posição. | `home-*.png`; `habitat.dart:82-129` só troca a paleta |
| C7 | O nível de detalhe é o mesmo do bebê ao adulto, porque **não existe** estágio. `RecompensaDeMarco` só conhece folhas, espécie e habitat. | `progressao.dart:121-141` |
| C8 | Os sons são 7 arquivos genéricos (`carinho`, `cavar`, `conquista`, `fim`, `premio`, `resgate`, `toque`), sem voz de espécie. | `assets/sons/` |
| C9 | A folha do sono pousa no mesmo ponto do widget para todos (`cx-26, cy+26`). | `pet.dart:3911` |

### 1.4 Proporção atual = filhote

[O] Medi nas artes "contente" a altura da cabeça (topo → queixo) sobre a
altura total da figura: capivara ≈ 0,60 (cabeça 130→585, pés em 890), lontra
≈ 0,56, tartaruga ≈ 0,48. As cabeças têm 94, 84 e 66 px de largura para
corpos de 92, 82 e 102 px (`pet.dart:1541-1546`, `1668-1673`, `1825`).

[F] O "esquema de bebê" (face larga, testa alta, olhos grandes, nariz e boca
pequenos) aumenta a fofura percebida e a motivação de cuidar (Glocker et al.,
2009, *Ethology* 115:257-263,
[PMC3260535](https://pmc.ncbi.nlm.nih.gov/articles/PMC3260535/)).

[I] Por isso o desenho atual já é fofo, e é também por isso que ele não
cresce. Para que a diferença entre estágios seja **extremamente visível**,
como o dono pediu, a escala tem de ir para os dois lados: o estágio 1 fica
**mais** bebê que o desenho de hoje (cabeça ≈ 0,62 da altura, olhos 1,3×) e o
adulto **menos** (cabeça ≈ 0,38, focinho e corpo da espécie real). O desenho de
hoje vira mais ou menos o estágio 2/3.

### 1.5 Arquitetura dos estágios (comum aos três)

**Regra.** Estágio é posse e nunca regride (contrato §1 e §8B). Ele deriva da
trilha, como o habitat, por meio do mesmo piso de posse `_comPosse`
(`progressao.dart:690-694`). Não depende de humor nem de dias sem abrir.

**Por conta, não por espécie.** O vínculo é da pessoa. Quem troca da
capivara para a lontra no passo 12 vê a lontra no estágio 3, e não um bebê. Se
o estágio fosse por espécie, trocar de bicho pareceria perder progresso, e o
§1 não permite isso [I].

| Estágio | Abre no passo | Marco (id) | Estimativa de dias (`progressao.dart:240-244`) | Coincide com |
|---|---|---|---|---|
| E1 Nascimento | início | — | 0 | onboarding |
| E2 Filhote | 1 | `primeiro_foco` | ~0,7 | 1ª sessão |
| E3 Jovem | 3 | `nivel_3` | ~1,6 | habitat igarapé |
| E4 Adulto | 11 | `semana_inteira` | ~7 | habitat manguezal |
| E5 Sábio | 18 | `trinta_dias` | ~30 | habitat praia |
| (coroa) | 22 | `cem_focos` | ~67 | ilha: um acessório de "sábio pleno", sem novo corpo |

[I] Pus E2 no passo 1 de propósito: o primeiro "nascimento" acontece **na
primeira sessão de foco**. É o melhor momento de recompensa do produto inteiro
(o ovo do tracajá eclode, a lontra sai da toca, a capivara chega ao grupo).
E5 no passo 18 (30 dias) mantém o último corpo novo alcançável; o passo 22
fecha com um detalhe, não com outro corpo.

**Tamanho na cena** (altura do bicho em relação ao adulto E4 = 100%). Os
tamanhos reais são comprimidos para caber num personagem: um tracajá
recém-nascido tem ~4 cm contra ~46 cm do adulto [F, Naturalis], uma escala de
9%, que sumiria na tela.

| | E1 | E2 | E3 | E4 | E5 |
|---|---|---|---|---|---|
| altura na cena | 42% | 58% | 78% | 100% | 100% |
| cabeça / altura total | 0,62 | 0,55 | 0,46 | 0,38 | 0,38 |
| diâmetro do olho (× atual) | 1,30 | 1,15 | 1,0 | 0,85 | 0,85 |

**Como fazer (Flutter)** [I]:

1. `RecompensaDeMarco` ganha `estagioDoBicho` (int?), preenchido nos passos 1,
   3, 11 e 18. `ProgressoDaTrilha` ganha `int get estagioDoBicho`, uma cópia de
   `estagioDoHabitat` (`progressao.dart:716-723`). Os ids não mudam.
2. `PetView` recebe `estagio` (1..5). Cada `_capivara/_lontra/_tartaruga` lê
   uma tabela `_Proporcoes(estagio)` (cabeça, corpo, olho, focinho, cauda) em
   vez de constantes. Os humores continuam funcionando, porque o rosto é o
   mesmo sistema escalado.
3. A transição é uma tela cheia em `celebracao.dart`: 3 a 4 s de cena
   própria (ver cada espécie), depois um *morph* de 600 ms interpolando os
   parâmetros de `_Proporcoes(n)` para `_Proporcoes(n+1)` com
   `TweenAnimationBuilder`. Com "reduzir movimento", troca direta com
   *crossfade* de 200 ms. A informação (corpo novo) não depende da animação.
4. A sobreposição (`OverlayDoBaru.kt`) precisa receber espécie, estágio e
   humor. Senão o item 7 do brief piora, porque o bicho da sobreposição vai
   ficar ainda mais diferente do bicho do app. Ver o laudo da sobreposição.

**Critério de aceite.** Golden tests `test/goldens/pet_<especie>_e<1..5>_<humor>.png`
(3 × 5 × 5 = 75 imagens). Num teste de 5 s com 10 pessoas que nunca viram o
app, ≥ 8 ordenam corretamente as 5 imagens de uma espécie embaralhadas.

---

## 2. Capivara — Baru

### 2.1 Biologia real

**Identidade.** *Hydrochoerus hydrochaeris*, o maior roedor vivo. Ocorre do
Panamá ao nordeste da Argentina, a leste dos Andes, sempre perto d'água [F, SF
Zoo]. O nome guarani dado pelo SF Zoo é "senhor dos capins" [F, SF Zoo].

**Ciclo de vida e estágios**

| Fase | Idade | Tamanho | Aparência / comportamento | Fonte |
|---|---|---|---|---|
| Gestação | ~150 dias | — | Ninhada média de 4,04 filhotes (Embrapa, RS). Picos de parto na primavera (41%) e no outono (27%) | [F] Embrapa Clima Temperado, Comunicado 126 |
| Parto | dia 0 | 1–1,5 kg | A fêmea se afasta do grupo e procura abrigo algumas horas antes do parto | [F] SDZWA; SF Zoo |
| Recém-nascido | 0–3/4 dias | ~1 kg | **Precoce**: nasce com pelo, olhos abertos, anda e nada em poucas horas | [F] Longleat; Houston Zoo; ADW |
| Volta ao grupo | 3–4 dias | — | Os filhotes voltam ao grupo e formam **creches**: mamam em qualquer fêmea que esteja amamentando | [F] SF Zoo; ADW |
| Filhote | 1 sem – 3/4 meses | — | Belisca capim desde ~1 semana e mama até ~16 semanas. Vocaliza "quase constantemente", num **ronronar gutural** | [F] Longleat; ADW; SF Zoo |
| Desmame | ~3–4 meses | ≥ 5 kg no manejo da Embrapa | — | [F] ADW; SF Zoo; Embrapa |
| Jovem | até ~1 ano | — | Fica no grupo dos pais até cerca de 1 ano | [F] ADW |
| Adulto | maturidade 15–18 meses | 35–66 kg (ADW); 27–79 kg (SDZWA) | Corpo de **barril**, sem cauda, patas levemente palmadas. 4 dedos na frente e 3 atrás | [F] ADW; SDZWA; SF Zoo |
| Velhice | — | — | Vive em média 6 anos na natureza (até 10) e até 12 sob cuidado humano | [F] ADW; SDZWA |

**Anatomia que importa para o desenho** [F, SF Zoo; SDZWA]: cabeça grande e
larga, orelhas curtas e arredondadas, **focinho pesado e quadrado com lábio
superior aumentado**. Olhos, orelhas e narinas ficam no **alto da cabeça**, o
que deixa o bicho submerso enquanto vigia. Pelo longo, grosso e ralo,
marrom-avermelhado a acinzentado em cima e marrom-amarelado embaixo. Às vezes
há preto no rosto. O macho adulto tem o *morrillo*, uma glândula nua e alta no
topo do focinho [F, ADW].

**Comportamentos marcantes**

- **Água e lama.** Chafurda em água rasa e lama para se refrescar nos dias
  quentes e pasta no fim da tarde [F, SDZWA]. Passa a parte mais quente do dia
  na água e consegue ficar até 5 min submersa para se esconder [F, ADW].
- **Comer.** Pasta capim e plantas aquáticas, ocasionalmente casca e fruta.
  Pratica coprofagia: reingere de manhã parte do alimento do dia anterior [F,
  ADW]. Os dentes da bochecha crescem a vida toda [F, SF Zoo].
- **Social.** Grupos de ~10 adultos, que chegam a 40 na estação chuvosa [F,
  SDZWA; SF Zoo].
- **Aves.** O gavião-carrapateiro (*Milvago chimachima*), a jaçanã, o
  vira-bosta, o suiriri-cavaleiro e o anu-preto catam carrapatos e insetos nas
  capivaras, ou as usam de poleiro. Capivaras estão entre os "clientes" que
  **adotam posturas de convite** durante a limpeza [F, Sazima & Sazima 2010;
  Sazima 2008; Sazima 2010 "update"]. Os anus foram vistos com as capivaras
  "aparentemente indiferentes" [F, Sazima 2008].
- **Banho morno (cultura, não biologia).** No Izu Shaboten Zoo (Japão), desde
  1982 as capivaras têm banho quente. No inverno a água recebe yuzu (uma
  cítrica), e a prática se espalhou para mais de 20 zoológicos japoneses [F,
  Wikipedia "Izu Shaboten Zoo"; Spoon & Tamago]. É daí que vem a imagem
  popular da "capivara com laranja na cabeça". [I] É meme, não etologia, mas é
  reconhecível no mundo todo e não contradiz a biologia (a capivara gosta de
  água).

**Sons reais**

- Repertório de **7 tipos** de chamada (assobio, choro, ganido, guincho,
  latido, clique e bater de dentes), em 2.069 chamadas de 28 animais em
  cativeiro, agrupadas em **contato, alarme, aflição e agonístico**. Os cliques
  diferem entre grupos sociais (um "sotaque" de grupo). [F, resumo do artigo
  "Vocal repertoire of captive Capybara: structure, context and function",
  visto via [CZAW](https://czaw.org/keyword/capybara). Autoria e ano não
  confirmados na página.]
- Os filhotes produzem um **ronronar gutural constante**. O **latido tossido**
  é dado pelo primeiro que vê o predador, repetido, e o grupo fica alerta ou
  corre para a água [F, SF Zoo].
- O **assobio do filhote funciona como chamada de isolamento**: atrai os
  adultos em experimento de *playback* com 20 adultos [F, resumo via
  indexador, *Brazilian Journal of Biology*; não consegui abrir o texto
  (403)].
- Chamadas com ultrassom só apareceram **sob contenção**, associadas a dor
  [F, resumo via indexador, *Pesquisa Veterinária Brasileira*,
  [SciELO](https://scielo.br/j/pvb/a/QzsDhtrWhYJ3fRTBmT4jprd/abstract/?lang=en)].
  **Não use em app.**

**Linguagem corporal ligada a emoções**

- *Contentamento/relaxamento.* Deitada, sem peso nas quatro patas e com a
  maior parte do corpo no chão (definição de "descanso deitado" do etograma,
  [JZAR](https://www.jzar.org/jzar/article/download/358/266/2541)) [F].
  Indiferente às aves que a catam [F, Sazima 2008].
- *Medo/alerta.* Latido tossido repetido, de pé, alerta, e fuga para a água
  [F, SF Zoo].
- *Agonismo.* Bater de dentes [F, repertório] e perseguições curtas entre
  machos [F, SF Zoo].
- *Carinho/contato.* Ronronar [F, SF Zoo] e cliques de contato [F, repertório].
- *Orelhas.* **Não achei fonte** científica sobre a posição de orelha por
  emoção na capivara. Tudo o que digo sobre orelhas abaixo é [I].

### 2.2 Avaliação do desenho atual

- **Proporção** [O]. A cabeça é um retângulo largo (94 × 74) com focinho baixo
  e largo (`pet.dart:1541-1586`), e as orelhas ficam nos cantos de cima (±40,
  -19). O comentário do próprio código diz "grandes e altas, ela vira urso"
  (`pet.dart:1533-1534`). Mesmo assim, na arte o resultado lê como **urso ou
  hamster**: as orelhas são redondas e grandes demais (16 × 14 numa cabeça de
  94) e o focinho é uma faixa clara curta com nariz-botão. [F] O traço que
  identifica a capivara é o oposto: focinho **pesado, quadrado e alto**, com
  narinas no topo e olhos no alto e na lateral (SF Zoo; SDZWA).
- **Legibilidade** [O]. Sem a etiqueta "Capivara", a silhueta é a da lontra
  sem cauda (IoU 0,83). Na home ela fica parada no meio da água, só com o
  queixo para fora (`home-capybara.png`).
- **Fofura** [I]. Alta, pelo esquema de bebê. Mas é uma fofura genérica, de
  ursinho.
- **Consistência** [O]. É coerente com o elenco: frente, barriga oval, dois pés
  (`elenco-nove.png`). O preço disso é a capivara não ter assinatura própria.
- **Humores** [O]. "Radiante" difere de "contente" pelas faíscas e por 0,1 de
  clareamento do pelo (`pet.dart:1159-1170`). "Saudade" tem o defeito C1/C2 e
  sai com cara brava. "Sono" é o mais claro de todos (olhos fechados, Zzz,
  folha).
- **Pelagens** [O]. Seis tons, de `#7A5133` a `#D9A87C`
  (`tokens.dart:71-78`), coerentes com o "marrom-avermelhado a acinzentado"
  real [F, SF Zoo].

### 2.3 Cinco estágios da capivara

As medidas usam a tabela do §1.5. A vista é sempre de frente, para manter o
elenco, com um quarto de giro de cabeça (≈ 20°) a partir de E3, para mostrar o
comprimento do focinho [I].

**E1 — "Recém-chegada" (escondida no capim)**
- *Biologia.* Nasce longe do grupo, com pelo e olhos abertos, ~1 kg [F].
- *Silhueta.* Uma gota deitada: corpo quase oval, 1,3:1 na horizontal. Cabeça
  0,62 da altura. Pernas curtíssimas, quase escondidas.
- *Cores.* Pelo **um tom mais claro e mais avermelhado** que o adulto da
  paleta (lerp 0,18 para `superficie`), com tufo arrepiado no topo da cabeça
  (3 traços curtos). [I] O pelo arrepiado é licença artística, sem fonte.
- *Cena.* Folhas de capim alto (3 lâminas verdes) na frente, cobrindo a parte
  de baixo. Ela espia por entre o capim.
- *Detalhes que somem depois.* O tufo e o capim na frente.

**Transição E1→E2 (1ª sessão concluída):** o capim se abre, ela dá 3 passinhos
tortos até a beira d'água e o grupo responde com cliques fora de cena. [F] Os
filhotes voltam ao grupo em 3–4 dias. Ao fim, ela entra na água pela primeira
vez e a linha d'água sobe até o peito.

**E2 — "Filhote da creche"**
- *Silhueta.* Barril pequeno; cabeça 0,55; focinho começa a aparecer como um
  retângulo claro **mais alto que largo** (proporção 0,9:1).
- *Detalhes novos.* Narinas no topo do focinho, 2 bigodinhos esparsos e
  orelhas menores (12 × 10).
- *Comportamento na cena.* Às vezes aparece um segundo filhote ao fundo,
  borrado e em tom pastel, para lembrar a creche [F, SF Zoo]. [I] Isso é só
  cenário, não um segundo pet.

**Transição E2→E3 (passo 3, nível 3, igarapé):** ela pasta, levanta a cabeça
e a câmera recua para mostrar que o mundo ficou maior (o igarapé abre junto).

**E3 — "Jovem"**
- *Silhueta.* O corpo alonga (largura 1,15× a altura) e a cabeça vai a 0,46. O
  focinho é um bloco que desce abaixo da linha dos olhos. Os olhos sobem para o
  terço superior da cabeça e se afastam para as bordas.
- *Detalhes novos.* Pelo com 4–6 traços de textura nas costas ("grosso e
  ralo" [F]), e dedos aparentes nas patas (4 na frente).

**Transição E3→E4 (passo 11, uma semana de raiz, manguezal):** banho de lama.
Ela rola, sai com a lama secando em manchas, sacode e aparece no corpo adulto.

**E4 — "Adulta, dona da lagoa"**
- *Silhueta.* **Barril** de verdade: o corpo é um retângulo de cantos muito
  redondos, mais largo que alto. Cabeça 0,38, inclinada 20°, com o perfil
  quadrado do focinho visível de um lado. Lábio superior volumoso. Orelhas
  minúsculas (9 × 8) no alto. Olhos pequenos, altos e laterais, e sem
  pálpebra caída por padrão.
- *Cores.* Mais contraste dorso/ventre: dorso com `sombra` e ventre com
  `claro`, num degradê de duas paradas.
- *Detalhe opcional.* Mancha escura no focinho, que lembra o *morrillo*. [I] Eu
  **não** desenharia o *morrillo*: ele marca macho, o app não tem sexo e a
  mancha lê como sujeira.

**Transição E4→E5 (passo 18, 30 dias, praia):** um suiriri-cavaleiro pousa
nas costas dela e fica. [F] A capivara serve de poleiro (Sazima). O pássaro
passa a ser um morador fixo do E5.

**E5 — "Sábia"**
- *Silhueta.* Igual ao E4, **mais baixa e assentada**: deitada com a barriga no
  chão por padrão, a postura de descanso do etograma [F].
- *Detalhes.* Focinho com pelos grisalhos (5–6 traços `#E8E0D0`) e sobrancelhas
  claras. [I] O grisalho é licença artística, sem fonte. O suiriri pousado vai
  e volta.
- *Passo 22 (coroa):* uma coroa de aguapé florido (lilás) na cabeça, entregue
  pela trilha e não pela loja.

### 2.4 Personalidade, humores e animações

**Traço de personalidade [I, apoiado em F]:** *a anfitriã calma.* Aceita todo
mundo nas costas (aves [F]), divide o leite com os filhotes dos outros (creche
[F]) e resolve o calor parando na água (chafurdar [F]). Combina com a frase
atual do app, "Água morna, companhia fácil" (`l10n.dart:831-834`).

**Os 5 humores na capivara**

| Humor | Olhos | Orelhas | Corpo/postura | Extra |
|---|---|---|---|---|
| Radiante | Abertos, brilho duplo, íris 0,56 (como hoje) | Viradas para a frente, com tremidinha a cada 3 s | **De pé na água até o peito**, nariz alto, corpo balançando de lado | Respingo pequeno de cada lado. Um clique de contato a cada ~8 s |
| Contente | Semicerrados e relaxados (pálpebra a 25%) | Neutras | **Deitada na margem**, barriga no chão, mastigando de lado | Ave pousada (E4–E5) |
| Neutro | Abertos, sem brilho extra | Uma para trás | Sentada sobre as patas traseiras (como cão), olhando o horizonte | Nenhum |
| Sonolento | Fechados (arco para baixo) | Caídas para os lados | Submersa até as narinas: só olhos, orelhas e narinas fora d'água [F: olhos e narinas no alto] | Bolhinhas na respiração no lugar do Zzz. A folha pousa na cabeça, e não no flanco |
| Sentindo falta | Abertos, íris olhando **para a câmera**, sobrancelhas internas erguidas e **espelhadas** (corrigir C1/C2) | Altas e viradas para a frente, procurando | Em pé na beira, pescoço esticado, olhando para fora da cena | Assobio de filhote [F: chamada de isolamento], uma vez ao abrir a tela. A lágrima sai; o assobio diz "cadê você?" sem culpar |

[I] O assobio é a peça central do "sentindo falta". Na biologia ele **atrai
os adultos de volta**, o que é exatamente o tom do contrato: chamar, não
acusar.

**Animações-assinatura (substituem 3 dos 6 gestos genéricos quando a espécie
é capivara)**

1. **"Hóspede"**: um suiriri ou gavião-carrapateiro entra voando, pousa nas
   costas e dá dois bicadinhos. A capivara fecha os olhos e baixa o corpo (a
   postura de convite [F, Sazima & Sazima 2010]). 6 s. A partir de E3.
2. **"Ofurô"**: afunda devagar até o nariz, sopra 3 bolhas, volta. 4 s. Mostra
   a anatomia real dos olhos e narinas no alto [F].
3. **"Lama"**: rola de lado na margem e levanta com manchas de lama que somem
   em 20 s. 5 s. Só fora d'água e só de dia. [F] Chafurda para se refrescar
   (SDZWA).
4. **"Mastigada lateral"**: com a boca cheia de capim, mastiga de lado e um
   fiapo de capim fica para fora e some. 3 s. [I] O movimento lateral é meu; o
   fato é a dieta de capim [F].
5. **"Mexerica"** (só com o item da loja; ver §2.6): a mexerica fica
   equilibrada na cabeça, cai na água, ela olha e a mexerica volta. [F, cultura]
   Referência ao banho de yuzu.

**Como (Flutter)** [I]: `GestoOcioso` ganha valores por espécie (`hospede`,
`ofuro`, `lama`, `mastigadaLateral`), e `_agendaGesto` (`pet.dart:540-570`)
sorteia de `repertorioDe(especie, estagio)`, com 2 gestos genéricos e 3
próprios. A ave é um `CustomPainter` à parte, acima do bicho, com caminho de
Bézier.

### 2.5 Jornada dedicada da capivara

A regra não muda: os 22 critérios, os ids e as folhas continuam os mesmos.
O que muda é a **apresentação** (nome do degrau, ilustração da prévia, fala) e
os **elementos de cena** que a capivara traz para cada habitat. As espécies
continuam abrindo só por marco, nunca por dinheiro.

**Habitat temático por estágio** (camada de props por espécie sobre o
`CenarioDoHabitat` existente) [I]:

| Habitat (passo) | Props da capivara |
|---|---|
| Lagoa (1) | Capim alto na margem, toca de capinzal (E1) |
| Igarapé (3) | Aguapés flutuando, tronco caído |
| Manguezal (11) | Poça de lama com marcas de patas (a lama da transição) |
| Serra (13) | Pedras quentes onde ela deita de manhã |
| Praia (18) | Faixa de areia de rio com pegadas de 4 e 3 dedos; o suiriri passa a morar aqui |
| Ilha (22) | Ofurô natural (poço morno com vapor leve) e o grupo de capivaras ao longe, em silhueta |

**Marcos com nome e fala próprios (amostra; a tabela completa dos 22 está no §5)**

- Passo 1 `primeiro_foco` → "**Primeiros passos fora do capim**". Fala: "Saí
  do capinzal. A água tá morna."
- Passo 3 `nivel_3` → "**Entrou na creche**". Fala: "Tem mais gente pequena
  aqui. Gostei."
- Passo 11 `semana_inteira` → "**Primeiro banho de lama**".
- Passo 18 `trinta_dias` → "**Um passarinho escolheu você**" (o suiriri).
- Passo 22 `cem_focos` → "**Dona da lagoa**" (a coroa de aguapé).

As falas nascem nos 4 idiomas. As versões en/es/zh precisam de revisão
nativa e entram marcadas `TODO-i18n` (contrato §2).

**Voz e sons para gerar no ElevenLabs (Sound Effects)**

Regra [I]: usar **só chamadas de contato** (ronronar, clique, assobio) e
nunca as de alarme (latido), aflição, agonismo (bater de dentes) ou dor
(ultrassom sob contenção) [F, repertório; SF Zoo; PVB]. O app não assusta nem
culpa.

| Uso no app | Base real | Prompt (em inglês, que é como o gerador de efeitos responde melhor [I]) | Duração |
|---|---|---|---|
| Carinho | ronronar gutural do filhote [F] | "soft low guttural purring of a baby capybara, gentle rhythmic chirps, very close microphone, calm, no music, no background" | 1,5–2 s, em laço |
| Contente | clique de contato [F] | "three soft wooden tongue clicks from a large rodent, relaxed, close, dry, no reverb" | 0,6 s |
| Sentindo falta | assobio de isolamento do filhote [F] | "a single short high-pitched whistle from a young capybara calling its group, gentle, slightly rising, outdoors near water, distant birds very faint" | 0,8 s |
| Comer | mastigação de capim | "slow crunchy grass chewing by a large herbivore, side to side, close up" | 1,2 s |
| Ofurô | — | "large animal slowly sinking into warm water, three small bubbles popping, quiet" | 2 s |
| Evolução | — | "water splash then soft chorus of capybara purrs and clicks, warm and celebratory, ends with a single bird chirp" | 3 s |

Antes de usar, compare com gravações de referência abertas, sem copiá-las:
procure "Hydrochoerus hydrochaeris" no Xeno-canto ou no acervo da Fonoteca
Neotropical Jacques Vielliard (Unicamp). [I] Não verifiquei a disponibilidade
dessas gravações.

### 2.6 Itens temáticos da capivara (comprados com folhas; nunca com dinheiro)

| Item (pt-BR) | Categoria | Onde aparece | Preço sugerido |
|---|---|---|---|
| **Mexerica no cocuruto** | roupa / cabeça | Em cima da cabeça. Ativa a animação "Mexerica" | 60 |
| **Ofurô morno** | cena / água | Um poço de pedra com vapor na água da frente (y > 240), à esquerda | 240 |
| **Poça de lama** | cena / margem | Na margem direita. Habilita a animação "Lama" | 110 |
| **Aguapé florido** | cena / água | Flutuando na frente. Ela belisca às vezes, porque come plantas aquáticas [F] | 70 |
| **Poleiro do suiriri** | cena / mata | Um galho seco à direita. O suiriri passa a visitar já no E3 (antes só no E5) | 190 |
| **Chapéu de palha de buriti** | roupa / cabeça | Variante do `chapeu_palha` com aba que deixa as orelhas para fora | 90 |
| **Toalhinha de banho** | roupa / pescoço | Enrolada no pescoço depois do ofurô | 70 |

[I] Os preços seguem a escada 40–400 da loja atual (`models.dart:257-294`).
Quem troca de espécie **não perde** o item: ele fica em "guardados" e volta a
aparecer quando a capivara volta. Os itens de cena (lama, ofurô, aguapé)
podem aparecer para todas as espécies, para nada ficar "morto".

---

## 3. Lontra — Rio

### 3.1 Que lontra?

[F] No Brasil, "lontra" é a **lontra-neotropical** (*Lontra longicaudis*). A
ariranha (*Pteronura brasiliensis*) é outra espécie, maior e social. A
lontra-marinha (*Enhydra lutris*) é do Pacífico Norte e é ela que boia de
costas, usa pedra como bigorna no peito e dorme em grupos flutuantes [F,
Point Lobos/Monterey; fontes secundárias].

[I] **Recomendo a lontra-neotropical** como base biológica do Rio, pelo mesmo
motivo da capivara: é brasileira, vive em rios e lagos (cabe nos habitats
igarapé, manguezal e serra) e tem o ciclo de filhote mais "contável" das três.
Comportamentos de ariranha e de outras lontras podem inspirar, mas com o
aviso dado.

### 3.2 Biologia real (*Lontra longicaudis*)

| Fase | Idade | Aparência / comportamento | Fonte |
|---|---|---|---|
| Gestação | ~56–57 dias (possível implantação tardia) | Reproduz uma vez por ano, na primavera em algumas regiões e o ano todo em outras | [F] ADW |
| Ninhada | dia 0 | 1–5 filhotes, geralmente 2–3. **Nascem cegos e já com pelo** | [F] ADW |
| Olhos | ~44 dias | Abrem os olhos | [F] ADW |
| Saída da toca | ~52 dias | — | [F] ADW |
| Primeira água | ~74 dias | Atividade aquática **com a mãe** | [F] ADW |
| Jovem | até ~1 ano | Fica com a mãe no 1º ano. **Só a fêmea cuida**; o macho fica um dia com ela no cio | [F] ADW; resumo de busca (Unisinos) |
| Adulto | — | 5–15 kg (geralmente < 12). Cabeça+corpo 36–66 cm, **cauda 37–84 cm**, grossa na base e afinando. Pelo curto, denso, cinza-acastanhado lustroso, mais claro na barriga e **sobretudo na garganta**. Lábio superior, mandíbula e ponta do focinho branco-prateados a amarelados. Dedos palmados | [F] ADW |
| Longevidade | — | **Não achei fonte** | — |

**Habitat e alimentação** [F]: rios e lagos permanentes com mata ciliar.
Abriga-se em cavidades entre pedras, **entre raízes de árvores**, em tocas
escavadas e grutas, e usa grutas para criar os filhotes (ADW). Come
principalmente peixe, crustáceos e moluscos, e oportunisticamente insetos,
répteis, aves e pequenos mamíferos. Mergulha **20–30 s**, come a presa pequena
na água e leva a grande para a margem (ADW). Num riacho de Mata Atlântica, peixe
foi 82% da dieta, e ciclídeos 50% ([Journal of Zoology, Cambridge](https://resolve.cambridge.org/core/journals/journal-of-zoology/article/abs/feeding-ecology-of-the-neotropical-river-otter-lontra-longicaudis-in-an-atlantic-forest-stream-southeastern-brazil/C256E2BB6A8E2771813D6C637BB24670),
resumo via busca). No Lago Paranoá (Brasília), tilápia apareceu em 39,6% das
fezes ([UniCEUB](https://publicacoes.uniceub.br/cienciasaude/article/download/513/334),
resumo via busca).

**Comportamento** [F, ADW]: solitária e ativa de dia, mais no meio e no fim da
tarde. Vira noturna onde há perturbação humana. Anda num **galope corcunda,
com cabeça e cauda baixas**. Marca território com fezes em pontos visíveis
(pedras, troncos, bancos de areia). [I] Isso fica fora do app.

**Sons** [F]:
- *L. longicaudis*: **assobios, zumbidos (*hums*) e guinchos**. Na Argentina
  ouviram um "**hahh**" alto, tido como alarme (ADW).
- Ariranha: 22 tipos de chamada em adultos (11 de coesão, como *hum* e
  assobio, incluindo uma **chamada de isolamento** de quem perdeu o grupo; 4 de
  alarme: rosnado, "hah!", bufo, grito trêmulo; 5 de pedir comida). Os
  **recém-nascidos têm ~11 tipos**, com assobios e chamada de mamar, alguns
  precursores das chamadas adultas (Mumm & Knörnschild 2014,
  [PLOS ONE](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0112562)).

**Brincar** [F]:
- *Malabarismo de pedras* (lontra-de-garras-pequenas e lontra-lisa, ambas
  asiáticas): mais frequente **em jovens e em idosos** e **antes de comer**
  (fome ou antecipação). A função continua em aberto (Allison et al. 2020,
  *R. Soc. Open Sci.* 7:200141, [Univ. Exeter](https://news-archive.exeter.ac.uk/2020/may/title_794190_en.html)).
- *Escorregar*: a lontra-norte-americana (*Lontra canadensis*, mesmo gênero da
  nossa) escorrega de barriga na lama e na neve. É locomoção econômica e,
  quando repetida no mesmo barranco, brincadeira (Serfass 2005, via
  [Northern Woodlands](https://northernwoodlands.org/outside_story/article/sliding-shenanigans)).
- Para a *L. longicaudis* em si, o ADW diz que **não há informação** sobre
  brincadeira.

**Linguagem corporal ligada a emoções.** **Não achei fonte** específica de
*L. longicaudis* ligando postura a emoção. O que dá para afirmar: o alarme é
vocal ("hahh") [F]; a coesão é feita de *hum* e assobio (ariranha) [F]; a
brincadeira (malabarismo, escorregar) aparece em contexto relaxado ou de
antecipação de comida [F]. O resto da tabela de humores é [I].

**Status de conservação.** Não verificado por mim (a busca acabou). O resumo
de busca citou "vulnerável/quase ameaçada na Mata Atlântica" a partir de fonte
antiga, não do ICMBio. Confirmar no SALVE/ICMBio antes de usar em texto do app.

### 3.3 Avaliação do desenho atual

- **Proporção** [O]. Cabeça redonda (84 × 74) sobre corpo redondo (82 × 76)
  (`pet.dart:1668-1684`). Isso dá um **ursinho com bigode**. [F] A lontra real
  tem corpo longo e baixo, **cauda quase do tamanho do corpo**, pescoço grosso
  e cabeça achatada e larga (ADW).
- **Cauda** [O]. Desenhada como um espinho fino de dois Bézier
  (`pet.dart:1622-1638`). Na arte aparece um **vão branco** entre os dois
  traços perto da base (`pet-otter-contente.png`, por volta de x 880, y 740), e
  ela sai "de trás" como um rabo de rato. [F] A cauda real é **grossa na base**.
- **Identidade** [O]. Os bigodes (3 traços cinza a 50% de alfa) e a focinheira
  clara são os únicos sinais de lontra, e ambos somem no tamanho da home
  (`home-otter-noite.png`).
- **Pelagem** [O]. A paleta vai do chocolate ao pardo (`tokens.dart:81-88`). [F]
  Falta a **garganta clara** e o **focinho prateado** (ADW), os dois traços que
  mais separam lontra de capivara.
- **Humores** [O]. Iguais aos da capivara (mesmo `_olho` e `_boca`), com o
  mesmo defeito C1/C2.
- **Atividade** [O]. O código diz que "a lontra abre um molusco" ao petiscar
  (`pet.dart:103`). Moluscos estão na dieta [F, ADW], mas o gesto de abrir
  concha no peito é da lontra-marinha. [I] Peixe na margem é mais fiel e mais
  legível.

### 3.4 Cinco estágios da lontra

**E1 — "Filhote de toca"**
- *Biologia.* Nasce cega e com pelo, na toca entre raízes ou pedras [F].
- *Silhueta.* Uma bolinha enrolada, de cauda curta enrolada em volta do corpo.
  Cabeça 0,62, sem pescoço.
- *Olhos.* [I] Para os humores funcionarem, E1 mostra os olhos **recém-abertos**:
  menores (0,8×) e com íris azul-acinzentada, a "névoa" dos olhos novos. É uma
  compressão das primeiras semanas, e o texto do marco diz isso ("abriu os
  olhos") em vez de mostrar um bicho cego.
- *Cena.* Arco de raízes de árvore na frente, como moldura [F: toca entre
  raízes].
- *Cores.* Pelo mais escuro e uniforme, sem a garganta clara (ela surge em E3).
  [I] A diferença filhote/adulto de cor não tem fonte; é escolha de leitura.

**Transição E1→E2 (1ª sessão):** sai da toca de barriga, escorrega pela raiz
até a areia, espirra e olha para a água. [F] Sai da toca por volta de 52 dias.

**E2 — "Filhote de beira"**
- *Silhueta.* Corpo já alongado (1,3:1), cauda em 60% do corpo, patas grandes
  demais para o corpo (fofura) e dedos palmados visíveis.
- *Comportamento.* Na água só até a barriga, com a mãe em silhueta ao fundo
  quando nada [F: primeira água com a mãe, ~74 dias].

**Transição E2→E3 (passo 3, igarapé):** primeiro mergulho de verdade. Some 2 s
e volta com um peixinho pequeno (lambari estilizado), comendo na água [F: presa
pequena come na água].

**E3 — "Jovem"**
- *Silhueta.* Corpo 1,6:1, cabeça 0,46 e achatada no topo, pescoço grosso e
  cauda grossa na base com 80% do comprimento do corpo.
- *Detalhes novos.* **Garganta e queixo claros** (`claro`) e **focinho
  prateado** (lerp para `#E8E4DA`) [F, ADW]. Bigodes mais longos e brancos.

**Transição E3→E4 (passo 11, manguezal):** escorrega 3 vezes num barranco de
lama, cada vez mais rápido, e na última aparece adulta. [F] Escorregar como
brincadeira repetida (Serfass).

**E4 — "Adulta, do rio"**
- *Silhueta.* **Longa e baixa**, deitada de frente sobre a pedra com a cabeça
  erguida, ou de pé "sentada" sobre a cauda (silhueta em S). Cabeça 0,38, larga
  e chata. Orelhas mínimas (6 × 5) quase rente ao contorno. A cauda, grossa e
  cônica, contorna o corpo e aparece dos dois lados.
- *Cores.* Dorso "cinza-acastanhado lustroso" [F], com reflexo (uma faixa
  `luz` a 25% em arco no dorso) para dizer "molhado".

**Transição E4→E5 (passo 18, praia):** sentada na pedra, faz malabarismo com 3
seixos, e um quarto seixo, dourado, entra no laço. [F] Os idosos fazem mais
malabarismo (Allison 2020).

**E5 — "Sábia do rio"**
- *Silhueta.* Igual ao E4, mais robusta no pescoço.
- *Detalhes.* Bigodes brancos longos e caídos, focinho mais prateado e
  sobrancelhas de pelo claro. Um **seixo dourado** fica sempre ao lado. [I] O
  grisalho é licença artística.
- *Passo 22:* uma pedra-guia (seixo dourado) ganha um cordão de capim no
  pescoço.

### 3.5 Personalidade, humores e animações

**Traço [I, apoiado em F]:** *a curiosa independente.* Vive sozinha [F],
explora o rio inteiro e brinca quando espera comida [F, malabarismo antes de
comer]. Combina com "Inquieta e brincalhona; blocos curtos e intensos"
(`l10n.dart:835-838`).

| Humor | Olhos | Orelhas/bigodes | Corpo/cauda | Extra |
|---|---|---|---|---|
| Radiante | Grandes e brilhantes | Bigodes para a frente | **Nadando de costas por 1 s e virando** (rolamento), cauda batendo | Gotas. *Hum* curto |
| Contente | Semicerrados | Bigodes relaxados | Deitada de barriga na pedra quente, cauda enrolada | Mastiga um peixinho na margem |
| Neutro | Abertos | Neutros | De pé sobre as patas traseiras, olhando o rio (silhueta "sentada") | Nenhum |
| Sonolento | Fechados | Caídos | **Enrolada como rosca**, focinho escondido na cauda | Respiração funda no anel |
| Sentindo falta | Abertos, olhando a câmera, sobrancelhas internas erguidas (espelhadas) | Bigodes para a frente, tremendo | Na pedra, pescoço esticado, cabeça girando devagar | **Assobio de isolamento** [F, ariranha; *L. longicaudis* assobia] |

[I] "Nadar de costas" no radiante é licença leve. Lontras de rio rolam ao
nadar, mas não achei fonte para *L. longicaudis*. O que fica proibido é a
cena da lontra-marinha (boiar parada de costas com pedra no peito), para não
tirar a identidade brasileira dela.

**Animações-assinatura**

1. **"Malabares"**: sentada, joga 2–3 seixos de uma pata para a outra. 4 s.
   Mais frequente em E2 e E5 e **antes do "petisco"** [F, Allison 2020].
2. **"Escorrega"**: corre corcunda até o barranco e desce de barriga até a
   água. 3 s [F, galope corcunda (ADW); escorregar (Serfass)].
3. **"Mergulho de pesca"**: some sob a água por 2 s (a escala real de 20–30 s
   comprimida) e volta com peixe, que come na água [F, ADW].
4. **"Secar o pelo"**: rola na areia de lado e sacode. 3 s. [I] Lontras se
   secam e se esfregam, mas não achei fonte para *L. longicaudis*.
5. **"Galope de beira"**: atravessa a cena num galope corcunda de cabeça e
   cauda baixas e volta [F, ADW].

### 3.6 Jornada dedicada da lontra

| Habitat | Props da lontra |
|---|---|
| Lagoa (1) | Toca entre raízes na margem (E1) |
| Igarapé (3) | Pedras lisas no meio d'água e cardume de lambaris passando |
| Manguezal (11) | Barranco de lama com o rastro do escorregador |
| Serra (13) | Cachoeirinha e uma pedra plana para comer |
| Praia (18) | Banco de areia com os 3 seixos do malabarismo |
| Ilha (22) | Seixo dourado e um tronco caído que vira ponte |

Marcos com nome próprio (amostra): passo 1 "**Abriu os olhos e saiu da
toca**"; passo 3 "**Primeiro mergulho**"; passo 7 (o passo que libera a lontra
para quem não começou com ela) "**Um rio novo**"; passo 11 "**Escorregador de
lama**"; passo 18 "**Três seixos no ar**".

Falas (pt; nascem nos 4 idiomas): "Achei uma pedra perfeita. Guarda pra
mim?"; "Mergulhei, mas voltei. Sempre volto."; em "sentindo falta": "Assobiei
pra ver se você ouvia."

**Sons (ElevenLabs)** — só coesão (assobio, *hum*) e nunca alarme ("hahh",
rosnado, bufo, grito) [F, ADW; Mumm & Knörnschild 2014].

| Uso | Base real | Prompt | Duração |
|---|---|---|---|
| Carinho | *hum* de coesão [F] | "soft high nasal humming of a small otter, content, short, close mic, no background" | 1 s |
| Contente | assobio curto [F] | "two quick soft chirpy whistles from a river otter, playful, dry" | 0,5 s |
| Sentindo falta | chamada de isolamento [F, ariranha] | "a single clear rising whistle of a young otter looking for its family, outdoors by a stream, gentle" | 0,8 s |
| Malabares | — | "three small smooth river pebbles clicking together, soft, rhythmic" | 1,5 s |
| Mergulho | — | "small sleek animal diving into a stream, tiny splash, then underwater bubbles" | 1,5 s |
| Evolução | — | "playful otter chirps rising in pitch, water splashes, three pebbles clicking, warm ending" | 3 s |

### 3.7 Itens temáticos da lontra (folhas, nunca dinheiro)

| Item | Categoria | Onde aparece | Preço sugerido |
|---|---|---|---|
| **Seixos de malabarismo** | cena / margem | Três seixos coloridos na margem esquerda. Ativa a animação "Malabares" em todos os estágios | 70 |
| **Escorregador de barranco** | cena / margem | Rampa de argila à direita, descendo para a água | 190 |
| **Toca de raízes** | cena / mata | Arco de raízes ao fundo. Ela dorme lá quando "sonolento" | 240 |
| **Cardume de lambaris** | cena / água | Peixinhos cruzando a água da frente a cada ~15 s | 110 |
| **Óculos de mergulho** | roupa / rosto | No rosto, empurrados para a testa quando fora d'água | 120 |
| **Lenço de nadadora** | roupa / pescoço | Variante do `cachecol` mais curta, com estampa de ondas | 70 |
| **Vitória-régia** | cena / água | Folha grande flutuando. Ela sobe e deita nela (contente) | 150 |

---

## 4. Tartaruga — Toco

### 4.1 Que tartaruga? (decisão necessária)

[O] O código desenha uma **tartaruga-de-orelha-vermelha** (*Trachemys scripta
elegans*): "A listra vermelha atrás do olho — é dela que vem o nome"
(`pet.dart:1829-1832`); "A tartaruga do app é de orelha vermelha [...] que é
aquática" (`pet.dart:94-96`). A chave da espécie é `tortoise`, que em inglês é
**jabuti** (terrestre), e o texto em inglês diz "You're a tortoise"
(`l10n.dart:1345`).

[F] A orelha-vermelha é norte-americana e é tratada como espécie de **alto
potencial invasor** no Brasil: compete com o tigre-d'água nativo (*Trachemys
dorbigni*) e a criação sem autorização é proibida (Portaria SEMA-RS nº
46/2015, [LegisWeb](https://www.legisweb.com.br/legislacao/?id=283376);
[Bem Paraná / Cetas-PUCPR](https://www.bemparana.com.br/publicacao/blogs/papopet/nao-confunda-cagado-com-tartaruga/)).
Não achei a norma federal do Ibama vigente; confirmar antes de citar.

[I] Um app brasileiro com um pet que é espécie invasora, ao lado de uma
capivara e de uma lontra nativas, é um ponto fraco evitável. Duas opções
brasileiras:

| | **Tracajá** (*Podocnemis unifilis*) — **recomendado** | Jabuti-piranga (*Chelonoidis carbonarius*) |
|---|---|---|
| Ambiente | Aquático: rios calmos, lagos, mata alagada [F, Beardsley Zoo] | Terrestre |
| Combina com o lago, o igarapé e o nado do app | Sim (`acaoDoBicho` continua `nado`) | Não: ele brincaria na beira, como a gata (`pet.dart:107-111`) |
| Estágio visível "de graça" | **Manchas amarelas fortes no filhote** e borda amarela no casco [F] | Escamas vermelho-vivas nos membros [F, resumo AZAB] |
| Ovo enterrado | Sim, em praia de rio, 60–69 dias [F] | Sim (desova de agosto a janeiro [F, resumo]) |
| Gesto único | **Dobra o pescoço de lado** (pleurodira) [F] | Recolhe a cabeça para trás |
| Mantém a fábula "devagar e sempre" | Sim, no texto | Sim, e melhor |

**Recomendação:** tracajá. Ele mantém o comportamento aquático que o código já
tem (nado com quatro patas, cabeça alta) e dá a melhor sequência de estágios.
Mudanças: a chave interna `tortoise` **não muda**, porque é persistida e
trocá-la é migração. O nome em pt continua "tartaruga" ou vira "tracajá"; em en
"**river turtle**" (e não "tortoise"); em es "tortuga de río"; em zh
"河龟" (TODO-i18n, revisão nativa). [I] A frase de personalidade continua
valendo.

### 4.2 Biologia real (tracajá)

| Fase | Idade | Tamanho | Aparência / comportamento | Fonte |
|---|---|---|---|---|
| Ninho | — | ovos de 41–53 × 25–37 mm, **casca dura e calcária** | Ninho raso (9,5–23 cm) em areia ou barro de margem e às vezes em tapete de vegetação flutuante. ~80% das posturas à noite, muitas fêmeas juntas. 6–52 ovos (média 19 em mais de 16.000 ninhos), 2+ posturas por estação | [F] Naturalis (Turtles of the World) |
| Incubação | 60–69 dias (média de 73 num estudo); ~2 meses | — | **Sexo pela temperatura**: acima de 32 °C, 90–100% fêmeas; 28–31 °C, ~80% machos | [F] Naturalis; Beardsley Zoo |
| Época | — | — | Desova e incubação na seca; o nascimento coincide com o início da enchente | [F] relatório UFAM via busca; Wikipedia |
| Eclosão | dia 0 | ~40 mm, 9–22 g, "do tamanho de uma moeda" | Forrageia sozinho em poucos dias. Muitos morrem nos poucos metros de areia até a água | [F] Naturalis; Beardsley; resumo de busca |
| Filhote/juvenil | — | — | Cabeça cinza-oliva a marrom com **manchas amarelas** (topo do focinho, laterais até a maxila, do olho ao canto da boca e no tímpano). Carapaça **marrom a cinza-esverdeada com borda amarela estreita**. **Quilha pronunciada** | [F] Naturalis; Beardsley |
| Adulto | — | Fêmea até 46,5 cm de carapaça (~11 kg); macho até 33,5 cm | Carapaça oliva a cinza-escuro ou marrom, levemente abaulada, com quilha reduzida a um calombo baixo nos escudos vertebrais 2–3. Plastrão amarelo, que escurece em manchas com a idade. **Manchas da cabeça somem na fêmea e ficam no macho** | [F] Naturalis; Beardsley; Honolulu Zoo |
| Velhice | > 30 anos em cativeiro (Wikipedia); até 70 anos (Beardsley) | — | As fontes divergem | [F] |

**Alimentação** [F]: onívoro de base vegetal (plantas aquáticas, frutos,
sementes), além de peixe e moluscos. Pratica **neustofagia**: filtra partículas
finas da superfície da água com a boca (Naturalis; Beardsley).

**Comportamento** [F]: diurno, mais ativo no meio da manhã e à tarde. Entra na
mata alagada quando o rio sobe. **Dobra o pescoço de lado** para esconder a
cabeça sob a borda do casco, em vez de puxá-la para trás (Beardsley;
Wikipedia "Podocnemididae"). O corte é cortês: o macho mordisca de leve os pés
e a cauda da fêmea (Beardsley). [I] Tomar sol fora d'água é comum em
*Podocnemis*, mas **não achei fonte** e marco como sem fonte.

**Sons** [F]: na tartaruga-da-amazônia (*Podocnemis expansa*, mesmo gênero),
os filhotes **vocalizam dentro do ovo** (até ~10 dias antes de eclodir), no
ninho aberto e no rio. Os sons parecem sincronizar a eclosão e a escavação em
grupo. Fêmeas adultas respondem aos filhotes no rio, a primeira evidência de
cuidado parental acústico em quelônios. Foram 2.122 sons em 11 tipos (Ferrara
et al. 2012/2014, *Herpetologica* 70(2); [Mongabay](https://news.mongabay.com/2014/07/no-longer-deaf-as-a-stump-researchers-find-turtles-chirp-click-meow-cluck/);
[Cal Academy](https://www.calacademy.org/explore-science/talking-turtles)).
Os sons dos filhotes foram descritos como "**chirps, clicks, meows, and
clucks**" (Vogt, via Mongabay). [I] Para o tracajá não achei estudo
equivalente. Usar o som de *P. expansa* é extrapolação dentro do gênero, e é
assim que o laudo trata.

**Linguagem corporal ligada a emoções (répteis)** [F]: os critérios de
estresse em répteis incluem esconder a cabeça (fuga/evitação), sibilar, inflar
o corpo ou a garganta, respirar de boca aberta, hipo ou hiperatividade
(Warwick et al. 2018, *Front. Vet. Sci.* 5:151,
[PMC6043639](https://pmc.ncbi.nlm.nih.gov/articles/PMC6043639/)). O mesmo
documento diz que **répteis brincam** e precisam de objetos seguros. A
tartaruga-de-casco-mole "Pigface", do National Zoo, empurrava uma bola de
basquete, jogava cabo de guerra com a mangueira e brincava com um bambolê
(Burghardt; primeiro estudo formal de brincadeira em réptil não-ave,
[Scientific American](https://www.scientificamerican.com/blog/not-bad-science/looking-past-the-scales-the-truth-about-reptilian-behavior/)).
[I] Não achei fonte de sinais de **contentamento** específicos do tracajá. O
pescoço esticado e os olhos semicerrados ao sol abaixo são convenção de
desenho.

### 4.3 Avaliação do desenho atual

- **Leitura das "listras"** [O]. A listra vermelha (`pet.dart:1833-1843`) fica
  em ±22–32 px numa cabeça de 66 px de largura, ou seja, na borda, e sai
  cortada pelo contorno. Na arte (`pet-tortoise-*.png`) parecem **dois meios
  discos laranja**, como protetores de ouvido ou bochechas coradas. O
  comentário diz "sem bochecha rosada: réptil não cora" (`pet.dart:1849-1850`),
  e mesmo assim é isso que se vê.
- **Casco** [O]. Visto de frente, o casco translúcido, as linhas de escudo e o
  plastrão oval se sobrepõem (`pet.dart:1758-1806`). Na arte, o plastrão claro
  embaixo e as linhas atravessando a "fileira central" leem como **um babador
  sobre um saco**. A tartaruga é a única espécie cuja forma principal (o casco)
  é ilegível.
- **Pescoço** [O]. É desenhado (`pet.dart:1814-1819`), mas na arte a cabeça
  aparece pousada no casco, com um "pescoço" curto e claro que some.
- **Na água** [O]. Em `home-tortoise-entardecer.png` o casco inteiro fica
  submerso e só a cabeça flutua: lê como uma bola verde boiando.
- **Lágrima** [O]. Flutua no ar (C3).
- **Consistência** [O]. É a única do elenco de "corpo largo" e patas
  espalhadas (IoU 0,61–0,76 com as outras): é a mais diferente, o que é bom.
  Mas a cabeça é a mais "boneca" (uma bola com dois olhos e duas narinas).
- **Humores** [O]. Radiante×contente difere em 0,8% dos pixels, o pior número
  dos três.
- **Paleta** [O]. Oliva e musgo (`tokens.dart:91-98`). Para o tracajá, o
  adulto é oliva-escuro, cinza ou marrom [F], então serve, desde que se
  acrescente o **amarelo das manchas** como cor de acento fixa (`#F2C94C`).

### 4.4 Cinco estágios do tracajá

**E1 — "Ovo"**
- *Biologia.* Ovo elipsoide de casca dura, enterrado na areia de praia de rio,
  ~2 meses [F].
- *Desenho.* Um ovo creme (`#F4EBD8`), elipse 1,55:1, meio enterrado num
  montinho de areia com 3 grãos marcados. **Tem humor**: o ovo inclina,
  balança e mostra uma rachadura cada vez maior conforme a pessoa se aproxima
  da 1ª sessão. Aparecem dois **olhinhos na rachadura** nos humores
  radiante/contente; em "sentindo falta", o ovo dá 3 batidinhas (o som de
  dentro do ovo [F, *P. expansa*]).
- *Por que funciona [I].* É o exemplo que o próprio dono deu ("a coruja começa
  como ovo"), e aqui é biologicamente exato.

**Transição E1→E2 (1ª sessão):** o ovo racha em zigue-zague, sai a cabeça
(manchas amarelas acendendo uma por uma), depois o casquinho. O filhote
**corre pela areia até a água** em 2 s [F: travessia da areia até a água]. Som:
*chirps* e *clicks* [F].

**E2 — "Filhote de moeda"**
- *Silhueta.* Casco quase circular (1,05:1), **quilha central saliente** com 3
  "dentinhos" e borda amarela estreita em volta [F]. Cabeça 0,55, maior que o
  casco é largo.
- *Manchas.* 4 pares bem amarelos e grandes: topo do focinho, laterais do
  focinho, do olho ao canto da boca e tímpano [F]. Elas substituem a "listra
  vermelha".
- *Tamanho na cena.* 58% do adulto. [I] Na escala real seria 9%.

**Transição E2→E3 (passo 3, igarapé):** a enchente sobe [F: nasce no início
da enchente] e ele nada pela primeira vez no igarapé, de cabeça alta.

**E3 — "Juvenil"**
- *Silhueta.* Casco 1,2:1, a quilha diminui e a borda amarela fica mais fina.
  A cabeça vai a 0,46 e aparece o **pescoço longo**, que ele dobra de lado.
- *Cores.* Casco castanho-esverdeado [F]; manchas ainda vivas.

**Transição E3→E4 (passo 11, manguezal):** sobe num tronco, estica o pescoço,
fecha os olhos ao sol e o casco escurece de castanho para oliva. [I] Tomar sol
está sem fonte.

**E4 — "Adulto"**
- *Silhueta.* Casco **largo e baixo** (1,45:1), levemente abaulado, com um
  calombo baixo no meio [F]. Patas com membrana e unhas. Cabeça 0,38, achatada
  e pontuda no focinho.
- *Manchas.* [I] O app não tem sexo. Eu manteria as manchas, mais suaves
  (alfa 0,7), como num macho adulto [F], para não apagar a identidade do
  personagem. Escrever no texto do marco "as manchas ficaram" evita a pergunta.
- *Plastrão.* Amarelo [F]: aparece de leve na borda inferior.

**Transição E4→E5 (passo 18, praia):** volta à praia onde nasceu, e a câmera
mostra a areia. Aparece um anel a mais nos escudos. [I] Anéis de crescimento
nos escudos são comuns em quelônios, mas **não verifiquei** para o tracajá:
usar como ornamento, não como afirmação.

**E5 — "Ancião do rio"**
- *Silhueta.* Igual ao E4.
- *Detalhes.* Escudos com 2–3 anéis concêntricos, um fio de musgo verde-claro
  na borda posterior do casco e manchas do plastrão escurecidas [F: o plastrão
  ganha manchas com a idade]. Olhos com pálpebra pesada e sábia (pálpebra
  superior em 30%).
- *Passo 22:* uma pequena flor de mururé no casco.

### 4.5 Personalidade, humores e animações

**Traço [I, apoiado em F]:** *o paciente que sempre chega.* Nasce sozinho,
atravessa a areia [F] e vive décadas [F]. Mantém a frase do app: "Constância
vence velocidade".

| Humor | Olhos | Cabeça/pescoço | Corpo/patas | Extra |
|---|---|---|---|---|
| Radiante | Abertos, brilho duplo | **Pescoço todo esticado** para cima, cabeça balançando | Nadando com as quatro patas, rápido | Bolhas. *Click* duplo |
| Contente | Semicerrados | Esticado na horizontal, apoiado num tronco | Patas traseiras esticadas para trás, relaxadas | Faz neustofagia: abre a boca na superfície e "aspira" (§4.5, nº 3) |
| Neutro | Abertos | Meio esticado | Parado, boiando, só o topo do casco e a cabeça fora | Nenhum |
| Sonolento | Fechados | **Dobrado de lado** sob a borda do casco [F: pleurodira] | Patas recolhidas | Folha pousada no casco, e não na cabeça |
| Sentindo falta | Abertos, olhando a câmera, sobrancelhas espelhadas | Pescoço esticado para fora da água, olhando a margem | Parado na beira | *Chirp* de filhote [F, *P. expansa*: as fêmeas respondem]. Sem lágrima, porque réptil chorando lê como falso [I] |

[I] Importante: "esconder a cabeça" é sinal de **estresse** em répteis [F,
Warwick 2018]. Por isso a dobra lateral do pescoço só aparece no
**sonolento** (descanso) e num gesto rápido de timidez, **nunca** em "sentindo
falta", onde seria lido como medo.

**Animações-assinatura**

1. **"Pescoço de lado"**: ao ser tocado de surpresa, dobra o pescoço de lado em
   300 ms, espia por baixo da borda do casco e desdobra devagar (1 s). É o
   gesto que nenhuma outra espécie do app tem [F].
2. **"Aspirador de superfície"**: boca aberta rente à água, deslizando, com
   partículas indo para a boca. 3 s [F, neustofagia].
3. **"Bolinha"**: empurra uma bolinha com o focinho pela água e a perde. 4 s
   [F, Pigface/Burghardt; "répteis brincam", Warwick 2018]. Só com o item
   "Bola de buriti".
4. **"Tronco ao sol"**: sobe no tronco, estica as quatro patas e o pescoço e
   fecha os olhos. 5 s. [I] Sem fonte de tomar sol para o tracajá.
5. **"Mergulho de pedra"**: afunda de repente, reto, e sobe com uma folha
   presa na cabeça. 3 s. [I]

### 4.6 Jornada dedicada do tracajá

| Habitat | Props do tracajá |
|---|---|
| Lagoa (1) | Praia de areia com o montinho do ninho e a casca do ovo (fica para sempre) |
| Igarapé (3) | Mata alagada: troncos com marca d'água [F: entra na mata alagada na cheia] |
| Manguezal (11) | Tronco caído para tomar sol |
| Serra (13) | Pedras de rio arredondadas |
| Praia (18) | **A praia onde nasceu**, com outros montinhos de ninho ao longe [F: ninhos gregários] |
| Ilha (22) | Tapete de vegetação flutuante (onde às vezes há ninhos [F]) com a flor de mururé |

Marcos (amostra): passo 1 "**Saiu do ovo**"; passo 3 "**A cheia chegou**";
passo 8 (o passo que libera a tartaruga para quem não começou com ela) "**Um
ovo na areia**"; nesse caso, a cena de chegada **sempre começa pelo ovo**, que
eclode em 3 s e já aparece no estágio atual da conta [I]. Passo 11 "**Primeiro
sol no tronco**"; passo 18 "**De volta à praia**".

Falas (pt): "Fui devagar. Cheguei."; "As manchas ainda brilham, olha."; em
"sentindo falta": "Fiz um barulhinho. Você ouviu?".

**Sons (ElevenLabs)** — base nos sons de filhote de *Podocnemis* [F]. Nunca
sibilo (estresse [F, Warwick 2018]).

| Uso | Base | Prompt | Duração |
|---|---|---|---|
| Ovo (E1) | sons dentro do ovo [F] | "tiny muffled clicks from inside an egg buried in sand, very soft, intimate, close mic" | 1 s |
| Eclosão | *chirps/clicks* de filhote [F] | "small eggshell cracking then a tiny turtle hatchling chirping and clicking, soft sand shuffling" | 2 s |
| Carinho | *cluck* [F] | "a very soft low cluck from a small turtle, content, close, no reverb" | 0,5 s |
| Sentindo falta | *chirp* de filhote [F] | "single faint high chirp of a turtle hatchling near water, gentle" | 0,6 s |
| Nado | — | "slow paddling of a small turtle in calm river water, gentle ripples" | 2 s, em laço |
| Pescoço de lado | — | "quick soft leathery tuck sound, subtle, cartoonish but not comic" | 0,3 s |
| Evolução | — | "gentle river water, chorus of tiny turtle chirps rising, ends with soft splash" | 3 s |

### 4.7 Itens temáticos do tracajá (folhas, nunca dinheiro)

| Item | Categoria | Onde aparece | Preço sugerido |
|---|---|---|---|
| **Tronco de tomar sol** | cena / água | Tronco inclinado saindo da água à direita. Habilita "Tronco ao sol" | 150 |
| **Bola de buriti** | cena / água | Bolinha trançada flutuando. Habilita "Bolinha" | 70 |
| **Tapete de capim flutuante** | cena / água | Ilhazinha verde à esquerda, onde ele descansa | 110 |
| **Flor de mururé no casco** | roupa / cabeça (no casco) | Uma flor lilás presa na borda do casco | 90 |
| **Chapéu de folha de vitória-régia** | roupa / cabeça | Folha redonda de borda virada, como chapéu | 80 |
| **Mochilinha de casco** | roupa / costas | Bolsa de palha amarrada no casco. [I] Precisa de um novo `Vestimenta.costas` | 120 |
| **Ninho de lembrança** | cena / margem | O montinho com a casca do ovo **em todos os habitats** | 40 |

---

## 5. A trilha de 22 passos com a cara de cada espécie

Os critérios, ids, folhas, espécies e habitats ficam **exatamente** como em
`progressao.dart:245-472`. Só muda o **nome exibido** do degrau, que passa a
depender da espécie ativa. Estágios marcados com ★.

| Passo | id | Critério | Capivara | Lontra | Tracajá |
|---|---|---|---|---|---|
| 1 ★E2 | primeiro_foco | 1 sessão | Saiu do capinzal | Saiu da toca | Saiu do ovo |
| 2 | primeiro_dia_abaixo | 1 dia abaixo (ou 4 seguidos) | Primeiro capim | Primeiro peixinho | Primeira folhinha |
| 3 ★E3 | nivel_3 | nível 3 · abre igarapé | Entrou na creche | Primeiro mergulho | A cheia chegou |
| 4 | tres_focos | 3 sessões | Achou a água morna | Bigodes compridos | Manchas acesas |
| 5 | tres_dias | 3 dias seguidos | Três tardes na lagoa | Três tardes no rio | Três dias de correnteza |
| 6 | tres_dias_abaixo | 3 dias abaixo (ou 8 seguidos) | Banho de ofurô | Escondeu um seixo | Aprendeu a dobrar o pescoço |
| 7 | cinco_focos | 5 sessões · libera lontra | Ouviu um assobio novo | Um rio novo | Ouviu um assobio novo |
| 8 | cinco_dias_abaixo | 5 dias abaixo · libera tartaruga | Viu um ovo na areia | Viu um ovo na areia | Um ovo na areia |
| 9 | nivel_5 | nível 5 | Pelo engrossou | Pelo brilhando | Casco ficou firme |
| 10 | dez_focos | 10 sessões | Dez tardes de capim | Dez mergulhos | Dez travessias |
| 11 ★E4 | semana_inteira | 7 seguidos · abre manguezal | Primeiro banho de lama | Escorregador de lama | Primeiro sol no tronco |
| 12 | nivel_6 | nível 6 | Dona do capinzal | Dona do barranco | Dono do tronco |
| 13 | vinte_focos | 20 sessões · abre serra · libera axolote | Pedras quentes | Cachoeirinha | Pedras de rio |
| 14 | duas_semanas | 14 seguidos | Duas semanas de lagoa | Duas semanas de rio | Duas semanas de rio |
| 15 | nivel_8 | nível 8 | Mastigada perfeita | Malabares com dois | Aspirador de superfície |
| 16 | quinze_dias_abaixo | 15 abaixo · libera pinguim | Um pássaro curioso | Seixo favorito | Mata alagada |
| 17 | nivel_10 | nível 10 · libera coruja | Hóspede de toda tarde | Galope de beira | Anel no casco |
| 18 ★E5 | trinta_dias | 30 seguidos · abre praia · libera gata | Um passarinho escolheu você | Três seixos no ar | De volta à praia |
| 19 | trinta_dias_abaixo | 30 abaixo | Sombra de árvore | Toca de raízes | Ninhos ao longe |
| 20 | cinquenta_focos | 50 sessões · libera buldogue | Cinquenta tardes | Cinquenta mergulhos | Cinquenta travessias |
| 21 | nivel_15 | nível 15 | Grisalha e serena | Bigodes de prata | Musgo no casco |
| 22 | cem_focos | 100 sessões · abre ilha · libera raposa | Dona da lagoa (coroa de aguapé) | Seixo dourado | Flor de mururé |

**Como (Flutter)** [I]: em `l10n.dart`, `marcoNome(especieKey, marcoId)` com
*fallback* para o nome atual. São 22 × 3 × 4 = 264 chaves novas, todas nos 4
idiomas e travadas pelo teste de paridade existente (`test/l10n_test.dart`).
Esforço M. Os nomes acima são um rascunho para o redator.

**Itens de trilha (não de loja).** Os passos 11, 18 e 22 podem entregar um
**item próprio de graça** (lama, suiriri, coroa; escorregador, seixos, seixo
dourado; tronco, praia, flor). [I] Isso exige o campo `itemDaEspecie` em
`RecompensaDeMarco`, entregue para as três espécies de uma vez, para que trocar
de bicho depois não "perca" o prêmio.

---

## 6. Consistência entre as três

| | Capivara | Lontra | Tracajá |
|---|---|---|---|
| Silhueta adulta | Barril largo, cabeça quadrada, sem cauda | Longa e baixa, cauda grossa e longa | Disco largo e baixo, pescoço longo |
| Traço de cor exclusivo | Focinho e ventre claros | **Garganta e focinho prateados** | **Manchas amarelas** e borda do casco |
| Gesto que só ela faz | Ave pousada / ofurô até o nariz | Malabares / escorrega | Pescoço de lado / aspirador |
| Som de carinho | Ronronar | *Hum* | *Cluck* |
| Som de "sentindo falta" | Assobio de filhote | Assobio de isolamento | *Chirp* de filhote |
| E1 | Escondida no capim | Na toca entre raízes | Ovo na areia |

**Regras do sistema que valem para as três** [I]: mesma vista de frente; mesmo
traço (sem contorno, preenchimento chapado com uma sombra e uma luz); mesmo
olho (esclera creme, íris escura, dois brilhos); a mesma correção C1/C2/C3
para todas. O que separa as espécies é **a silhueta adulta, o gesto e o som**,
não o rosto.

**Critério de aceite verificável:** no estágio E4, a IoU de silhueta (medida
como no §1.2) fica abaixo de **0,70** entre capivara e lontra e entre lontra e
tracajá. Hoje capivara × lontra dá 0,83.

---

## 7. Mudanças de regra/contrato que estas propostas exigem

1. **§5 do `PRODUCT.md`** diz "Loja: 8 itens de posição fixa no habitat". O
   código já tem 13 (8 de cena e 5 roupas; `models.dart:257-338`). Os 21 itens
   de espécie exigem atualizar o §5 com ADR: itens por espécie, comprados com
   folhas, que nunca somem ao trocar de espécie. **Não** viola "nunca por
   dinheiro" (essa regra é sobre espécies, e as folhas vêm de foco).
2. **§4 do `PRODUCT.md`** fixa os nomes e as chaves das espécies. Trocar a
   orelha-vermelha pelo tracajá **não muda a chave** (`tortoise`) nem o nome
   (Toco); muda o desenho e o nome em en/es/zh. Merece um ADR curto, porque
   "espécie" está no contrato.
3. **§8B** ganha estágios. Eles são derivados da trilha e nunca regridem, como
   o habitat. Isso é coerente com o §1, mas é regra nova e precisa constar no
   contrato.
4. **Vestimenta.costas** (mochilinha do tracajá) é um encaixe novo de roupa.
   Opcional.

---

## 8. As 10 recomendações mais importantes (priorizadas)

**1. Corrigir a tristeza espelhada (C1/C2) e ancorar a lágrima no rosto (C3).**
- *Por quê:* hoje "sentindo falta" lê como bravo ou desconfiado, nas três
  espécies e nas outras seis [O, `pet.dart:3605-3625`, `3996-4008`].
- *Como:* passar `lado` (-1/1) para `_olho` e espelhar os pontos x da
  sobrancelha e da pálpebra. `_pingo` recebe a posição do olho esquerdo
  transformada pelo `canvas` da cabeça (ou é desenhada dentro dela).
- *Esforço:* P. *Impacto:* alto (humor errado é pior que humor fraco).
- *Aceite:* golden de "saudade" com as pontas internas das duas sobrancelhas
  **acima** das externas; lágrima a ≤ 6 px da borda inferior do olho nas 9
  espécies.

**2. Sistema de 5 estágios, derivado da trilha, por conta, sem regressão (§1.5).**
- *Por quê:* é o pedido nº 6 do dono, e hoje não existe estágio [O,
  `progressao.dart:121-141`].
- *Como:* `estagioDoBicho` em `RecompensaDeMarco` (passos 1, 3, 11, 18),
  `ProgressoDaTrilha.estagioDoBicho` e tabela `_Proporcoes` por espécie e
  estágio em `pet.dart`.
- *Esforço:* G. *Impacto:* muito alto.
- *Aceite:* 75 goldens; teste de unidade de que nenhum caminho de contadores
  faz `estagioDoBicho` diminuir; teste com 10 pessoas (≥ 8 ordenam os
  estágios).

**3. Trocar a orelha-vermelha pelo tracajá (§4.1).**
- *Por quê:* espécie com potencial invasor no Brasil [F]; o tracajá entrega o
  ovo, as manchas e o pescoço de lado [F].
- *Como:* redesenhar `_tartaruga` (casco de cima-frente, manchas no lugar da
  listra, pescoço que dobra), mudar en/es/zh e escrever um ADR curto.
- *Esforço:* M. *Impacto:* alto (identidade e coerência).
- *Aceite:* nenhuma listra vermelha; manchas amarelas visíveis a 280 px de
  largura; a revisão de um herpetólogo ou o material do ICMBio/Ibama confirma
  "parece tracajá".

**4. Cenas de nascimento na 1ª sessão (ovo / toca / capinzal).**
- *Por quê:* é o primeiro grande momento do produto, e a biologia dá cenas
  reais e diferentes para cada espécie [F].
- *Como:* `celebracao.dart` ganha `CenaDeNascimento(especie)`, de 3–4 s, com
  sons gerados; com "reduzir movimento", vira quadro estático + texto.
- *Esforço:* M. *Impacto:* muito alto em D1 [I].
- *Aceite:* disparada uma única vez por conta e espécie; ≤ 4 s; pulável com
  um toque.

**5. Silhuetas adultas próprias (capivara barril, lontra longa, tracajá disco).**
- *Por quê:* IoU capivara × lontra de 0,83 [O]; ambas leem como urso [O].
- *Como:* redesenhar E4 seguindo §2.3, §3.4 e §4.4; E2/E3 interpolam.
- *Esforço:* G. *Impacto:* alto.
- *Aceite:* IoU < 0,70 entre os pares (§6).

**6. Humor no corpo, não só no rosto.**
- *Por quê:* contente × saudade muda 2,3–3,0% dos pixels [O].
- *Como:* cada humor ganha uma **pose de corpo** por espécie (tabelas dos §2.4,
  §3.5 e §4.5): de pé, deitada, enrolada, pescoço esticado. Em `_PetPainter`,
  um `PoseDeHumor` com translação, rotação e escala por parte.
- *Esforço:* M. *Impacto:* alto.
- *Aceite:* ≥ 10% de pixels diferentes entre quaisquer dois humores da mesma
  espécie e estágio.

**7. Gestos-assinatura por espécie (3 próprios + 2 genéricos).**
- *Por quê:* o repertório de hoje é igual para os 9 [O, `pet.dart:555-560`].
- *Como:* `repertorioDe(especie, estagio)`; aves, seixos e bola são painters
  auxiliares.
- *Esforço:* M. *Impacto:* médio-alto (faz o bicho parecer vivo e próprio).
- *Aceite:* em 2 min de tela parada, ≥ 2 gestos próprios da espécie aparecem
  (teste com `PetView.gestoForcado` e relógio falso).

**8. Voz por espécie, só com chamadas de contato.**
- *Por quê:* os sons de hoje são genéricos [O, C8]; vocalizações reais de
  contato existem para as três [F].
- *Como:* `som_service.dart` com `SomDoBicho(especie, evento)`; arquivos
  `assets/sons/<especie>/<evento>.wav` gerados com os prompts acima, com
  volume normalizado (−16 LUFS [I]) e ≤ 2 s.
- *Esforço:* M. *Impacto:* médio-alto.
- *Aceite:* nenhum som de alarme, dor ou sibilo; cada espécie tem carinho,
  contente, saudade, comer e evolução.

**9. Nomes de marco e props de habitat por espécie (§5, §2.5, §3.6, §4.6).**
- *Por quê:* a jornada é a mesma para todos [O, C6].
- *Como:* `marcoNome(especie, id)` com *fallback*; props por espécie em
  `habitat.dart` como uma camada desenhada antes do bicho.
- *Esforço:* M. *Impacto:* médio.
- *Aceite:* 264 chaves nos 4 idiomas passam no `l10n_test`; cada habitat
  mostra ≥ 2 props próprios da espécie ativa.

**10. Itens temáticos por espécie (7 cada), que nunca se perdem ao trocar.**
- *Por quê:* dão motivo para gastar folhas e reforçam a identidade; pedido do
  dono.
- *Como:* `ShopItemDef(..., especie: Species.x)`, seção "Da <espécie>" na
  loja, inventário "guardados". Atualizar o §5 com ADR.
- *Esforço:* M. *Impacto:* médio.
- *Aceite:* trocar de espécie e voltar mantém 100% dos itens; nenhum item de
  espécie com preço em dinheiro real.

---

## 9. O que **não** fazer

- **Não** usar latido, bater de dentes, "hahh", rosnado ou sibilo como som do
  app: são alarme, agonismo ou estresse [F]. Nem ultrassom de capivara, que
  está ligado a dor [F].
- **Não** mostrar a tartaruga escondendo a cabeça em "sentindo falta". Esconder
  a cabeça é sinal de estresse em réptil [F]; o recolhimento fica no sono e
  num gesto rápido de timidez.
- **Não** dar à lontra a cena da lontra-marinha (de costas, pedra no peito,
  mãos dadas) como assinatura. Isso apaga a lontra brasileira [F/I].
- **Não** desenhar o *morrillo* da capivara nem as manchas sumindo no tracajá:
  ambos marcam sexo, e o app não tem.
- **Não** fazer o estágio regredir (por dias sem abrir, por "saudade" ou por
  troca de espécie). Fere o §1.
- **Não** vender estágio, aceleração de estágio ou espécie por dinheiro.
- **Não** tornar o ancião frágil (curvado, tremendo, de bengala). Sábio, sim;
  velho no fim da vida, não. O bicho "nunca morre" (§1), e a velhice frágil
  sugere morte [I].
- **Não** usar escala real de tamanho (filhote de tracajá a 9% do adulto). Ele
  some na tela.
- **Não** trocar a chave `tortoise` no armazenamento. Muda só desenho e texto.
- **Não** colocar carrapato visível na cena da ave. A biologia é essa [F], mas
  vira nojo [I]. A ave "pousa e bica de leve".

---

## 10. Riscos e dúvidas em aberto

1. **Status de conservação** da lontra-neotropical e do tracajá no Brasil
   (ICMBio/SALVE): não verifiquei, porque a busca acabou. Não usar em texto do
   app até confirmar.
2. **Norma federal** sobre a orelha-vermelha: só achei a portaria estadual do
   RS e matérias. Confirmar com o Ibama antes de citar no ADR.
3. **Som do tracajá**: a vocalização de filhote está documentada em *P.
   expansa*, não em *P. unifilis*. É extrapolação de gênero, e o laudo diz
   isso.
4. **Autoria do repertório vocal da capivara** e do estudo do assobio de
   isolamento: li os resumos via indexador. Confirmar o artigo antes de citar
   em material público.
5. **Custo de desenho**: 3 espécies × 5 estágios × 5 humores, mais as poses de
   corpo, são muitos estados para o `CustomPainter`. [I] A tabela
   `_Proporcoes` interpolada reduz isso, mas E1 (ovo, toca) e E4 (silhueta
   nova) são desenhos à parte. Se o prazo apertar, faça primeiro E1 → E2 → E4
   e interpole E3/E5.
6. **As outras 6 espécies** vão parecer "sem estágio" enquanto só três tiverem.
   [I] Lançar o sistema para as 9 ao mesmo tempo, ou esconder o indicador de
   estágio nas que ainda não têm.
7. **Sobreposição (Kotlin)**: se ela continuar com desenho próprio, o pet de
   fora do app não acompanha o estágio, o que piora o item 7 do brief.
   Depende do laudo da sobreposição.
8. **ElevenLabs**: efeitos sintéticos podem sair "de desenho animado" ou
   imitar sons de dor por acaso. Ouvir todos com o critério "contato, não
   alarme" antes de aceitar. Gerar custa créditos.
9. **Animal com ave nas costas**: a febre maculosa é transmitida por carrapato,
   e a capivara é hospedeira do carrapato-estrela [I, sem fonte buscada neste
   laudo]. Tratar a cena da ave como amizade, sem carrapato, para não
   associar o pet a doença.

---

## Fontes

**Capivara**
- Embrapa Clima Temperado — Pinheiro, Silva & Rodrigues (2005), *Comunicado Técnico 126*, "Desempenho reprodutivo da capivara em criação semi-intensiva…": https://www.infoteca.cnptia.embrapa.br/infoteca/bitstream/doc/746149/1/comunicado126.pdf
- Animal Diversity Web, *Hydrochoerus hydrochaeris*: https://animaldiversity.org/accounts/Hydrochoerus_hydrochaeris/
- San Diego Zoo Wildlife Alliance, Capybara: https://animals.sandiegozoo.org/animals/capybara
- San Francisco Zoo Docents, fact sheet Capybara (rev. 2008): https://www.sfzoodocents.org/notebook/FactSheets/MAMMALIA/RodentiaLagomorphs/CAPYBARA.pdf
- Houston Zoo, "Don't worry, be capy": https://www.houstonzoo.org/blog/dont-worry-be-capy/
- Longleat, "Capybara pups born at the Park" (2026): https://www.longleat.co.uk/latest-news/2026/capybara-pups-born-at-the-park
- Repertório vocal em cativeiro (resumo): https://czaw.org/keyword/capybara ; artigo na SciELO (403 para mim): https://www.scielo.br/j/bjb/a/BQDG6LSCb7GtZ8XsybVpZjv/abstract/?lang=en
- Ultrassom sob contenção, *Pesquisa Veterinária Brasileira* (resumo): https://scielo.br/j/pvb/a/QzsDhtrWhYJ3fRTBmT4jprd/abstract/?lang=en
- Etograma de capivaras em cativeiro, JZAR (apêndice): https://www.jzar.org/jzar/article/download/358/266/2541
- Sazima & Sazima (2010), "Cleaner birds: an overview for the Neotropics", *Biota Neotropica*: https://www.biotaneotropica.org.br/BN/article/view/735
- Sazima (2008), "Validated cleaner: *Crotophaga ani* picks ticks and pecks at sores of capybaras", *Biota Neotropica*: https://www.biotaneotropica.org.br/BN/article/view/379
- Sazima (2010), "Brazilian cleaner birds: update and brief reappraisal", *Biota Neotropica*: https://www.biotaneotropica.org.br/BN/article/view/624
- Izu Shaboten Zoo (banho quente desde 1982): https://en.wikipedia.org/wiki/Izu_Shaboten_Zoo ; https://spoon-tamago.com/capybara-hot-bath-40-year-anniversary/

**Lontra**
- Animal Diversity Web, *Lontra longicaudis*: https://animaldiversity.org/accounts/Lontra_longicaudis/
- Dieta em riacho de Mata Atlântica, *Journal of Zoology* (resumo): https://resolve.cambridge.org/core/journals/journal-of-zoology/article/abs/feeding-ecology-of-the-neotropical-river-otter-lontra-longicaudis-in-an-atlantic-forest-stream-southeastern-brazil/C256E2BB6A8E2771813D6C637BB24670
- Dieta no Lago Paranoá, UniCEUB (resumo via busca): https://publicacoes.uniceub.br/cienciasaude/article/download/513/334
- Mumm & Knörnschild (2014), "The vocal repertoire of adult and neonate giant otters", *PLOS ONE*: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0112562
- Allison et al. (2020), "The drivers and functions of rock juggling in otters", *R. Soc. Open Sci.* 7:200141 — release da Univ. Exeter: https://news-archive.exeter.ac.uk/2020/may/title_794190_en.html
- Serfass (2005), escorregar em *Lontra canadensis*, via Northern Woodlands: https://northernwoodlands.org/outside_story/article/sliding-shenanigans
- Lontra-marinha, material de Point Lobos com base no Monterey Bay Aquarium: https://pointlobos.org/wp-content/uploads/2022/07/Sea-Otter-2018.pdf

**Tartaruga / tracajá**
- Turtles of the World (Naturalis), *Podocnemis unifilis*: https://turtles.linnaeus.naturalis.nl/linnaeus_ng/app/views/species/taxon.php?id=7921
- Beardsley Zoo, Yellow-spotted Amazon river turtle: https://www.beardsleyzoo.org/yellow-spotted-amazon-river-turtle.html
- Honolulu Zoo, Yellow-spotted Amazon turtle: https://honoluluzoo.org/animals/yellow-spotted-amazon-turtle
- Wikipedia, Yellow-spotted river turtle: https://en.wikipedia.org/wiki/Yellow-spotted_river_turtle ; Podocnemididae: https://en.wikipedia.org/wiki/Podocnemididae
- Ferrara et al. (2014), *Herpetologica* 70(2), sons de *Podocnemis expansa* — Mongabay: https://news.mongabay.com/2014/07/no-longer-deaf-as-a-stump-researchers-find-turtles-chirp-click-meow-cluck/ ; California Academy of Sciences: https://www.calacademy.org/explore-science/talking-turtles
- Warwick et al. (2018), *Front. Vet. Sci.* 5:151 (critérios de estresse em répteis): https://pmc.ncbi.nlm.nih.gov/articles/PMC6043639/
- Burghardt, brincadeira em tartaruga (Pigface) — Scientific American: https://www.scientificamerican.com/blog/not-bad-science/looking-past-the-scales-the-truth-about-reptilian-behavior/
- Orelha-vermelha como invasora — Portaria SEMA-RS 46/2015: https://www.legisweb.com.br/legislacao/?id=283376 ; Bem Paraná (Cetas-PUCPR): https://www.bemparana.com.br/publicacao/blogs/papopet/nao-confunda-cagado-com-tartaruga/

**Transversal**
- Glocker et al. (2009), "Baby schema in infant faces induces cuteness perception and motivation for caretaking in adults", *Ethology* 115:257-263: https://pmc.ncbi.nlm.nih.gov/articles/PMC3260535/

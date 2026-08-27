# Evidência visual — 2026-08-27

PNGs rasterizados a partir da árvore de widgets por
`baru_app/test/evidencia_test.dart`. Não são goldens de comparação nem
descrição de animação: são o que o app desenha.

Para regerar:

```
cd baru_app
flutter test test/evidencia_test.dart
```

## Habitat com hora do dia

| Arquivo | O que mostra |
|---|---|
| `habitat-amanhecer.png` | 6h — céu quente, sol baixo, água clara |
| `habitat-dia.png` | 12h — sol a pino |
| `habitat-entardecer.png` | 18h — luz laranja, sol no horizonte |
| `habitat-noite.png` | 22h — céu índigo, lua com halo, água escura, lanterna acesa |

As quatro são visivelmente diferentes. Antes deste turno as quatro eram
idênticas: a cena não conhecia a hora.

## Habitat por progresso

| Arquivo | O que mostra |
|---|---|
| `habitat-vazio.png` | primeiro dia, sem itens |
| `habitat-cheio.png` | os 8 itens da loja na cena |

## O companheiro

| Arquivo | O que mostra |
|---|---|
| `pet-swim.png` | nadando (radiante) — dentro d'água, com ondas |
| `pet-graze.png` | pastando (contente) — na margem |
| `pet-nap.png` | cochilando (sonolento) — deitado na areia |
| `pet-idle.png` | parado (sentindo falta) |
| `especie-*.png` | capivara, lontra, tartaruga e coruja |

## Telas

| Arquivo | O que mostra |
|---|---|
| `tela-folhas.png` | de onde cada folha veio, onde foi gasta, e as últimas com data |
| `tela-sequencia.png` | sequência atual, melhor, congelamentos, semana e próximo marco |
| `tela-ajustes.png` | cada assunto numa linha com o valor à direita |
| `tela-conta.png` | e-mail, senha, plano — aqui no estado "sem conta neste aparelho" |
| `trilha-inicio.png` | o caminho numa conta nova: o primeiro nó é o atual |
| `trilha-andamento.png` | cinco nós conquistados, linha sólida no trecho feito |
| `folha-de-saida.png` | a pergunta antes de fechar o app |

## Reações ao toque e gestos de ocioso

| Arquivo | O que mostra |
|---|---|
| `reacao-1-repouso.png` | o bicho em repouso, para comparação |
| `reacao-2-um-toque.png` | um toque: a quicada, no pico |
| `reacao-3-carinho.png` | três toques em 3 s: coraçõezinhos subindo |
| `reacao-7-afago.png` | afago: olhos apertados de contentamento, pelo levantado sob a mão e coraçõezinhos subindo |
| `reacao-4-espreguica.png` | gesto de ocioso — espreguiçar, com bocejo e olhos fechados |
| `reacao-5-sacode.png` | gesto de ocioso — sacudir a cabeça |
| `reacao-6-olha-em-volta.png` | gesto de ocioso — olhar de lado |

Os três gestos saem sozinhos, sorteados a cada 7–15 s, e só quando ele está à
toa: nadando, pastando ou dormindo o corpo já tem o que fazer. Nas capturas o
sorteio é fixado por `PetView.gestoForcado` — sem isso a captura do bocejo
dependia do dado cair no lado certo e falhava um terço das vezes.

## Movimento (sequências de quadros)

| Arquivo | O que mostra |
|---|---|
| `respiracao-1..6.png` | seis quadros a 280 ms — o peito enche e esvazia |
| `chegada-0-antes.png` | a cena antes de comprar a ponte |
| `chegada-1..4.png` | a ponte caindo na cena com mola, quadro a quadro |


## Tempo de tela

| Arquivo | O que mostra |
|---|---|
| `tempo-com-dados.png` | o número que conta para a meta, a quebra por categoria e a lista por app |
| `tempo-sem-permissao.png` | sem acesso ao uso: convite de um toque, nenhum número inventado |
| `tempo-vazio.png` | com permissão e sem medição ainda |

Repare no Spotify: aparece como **Áudio**, e a legenda diz que áudio fica fora
da meta. Antes ele era somado ao tempo de tela mesmo tocando no bolso.

## Trilha e nível

| Arquivo | O que mostra |
|---|---|
| `trilha-inicio.png` | conta nova: nível 1, primeiro passo em destaque |
| `trilha-andamento.png` | nível 4, cinco marcos conquistados, próximo passo com progresso |
| `celebracao-nivel.png` | a celebração de nível, com partículas em pleno voo |


## Missões e home

| Arquivo | O que mostra |
|---|---|
| `missoes.png` | três diárias e duas semanais, com progresso x/y, recompensa em folhas e XP, prazo e o botão "Resgatar" |
| `home.png` | a home inteira: saldo, sequência, habitat, humor, semana, uso, nível com XP e o resumo das missões |

## Sobre o "antes"

Não há captura do estado anterior porque o código anterior não tinha as chaves
de captura (`PetView.cenaKey`, `HabitatScene.cenaKey`) que este teste usa. O
"antes" está no histórico do git, no commit `23f1af7`, e era:

- companheiro desenhado por `CustomPainter` **sem nenhum `AnimationController`**
  — sem respiração, sem piscar, sem reação ao toque;
- cena com cor de fundo chapada, sem gradiente, sem camadas, sem paralaxe;
- **a mesma imagem às 9h e às 22h**;
- item comprado aparecendo instantaneamente, sem chegada.

Para ver o antes com os próprios olhos:
`git show 23f1af7:baru_app/lib/widgets/habitat.dart`.

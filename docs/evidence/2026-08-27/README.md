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

## Movimento (sequências de quadros)

| Arquivo | O que mostra |
|---|---|
| `respiracao-1..6.png` | seis quadros a 280 ms — o peito enche e esvazia |
| `chegada-0-antes.png` | a cena antes de comprar a ponte |
| `chegada-1..4.png` | a ponte caindo na cena com mola, quadro a quadro |

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

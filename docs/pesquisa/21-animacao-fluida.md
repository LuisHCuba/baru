# 21 — Animação fluida e orgânica para o bicho procedural

Data: 27/10/2026 · Escopo: como trocar senos de período fixo por movimento
vivo, sem repetição, com transições suaves, num pet desenhado por
`CustomPainter` em Flutter.

Convenções (as mesmas do laudo 05):

- **[Fato]**: afirmação com fonte externa; o link está na própria linha.
- **[App]**: observação do código em `baru_app/`.
- **[Opinião]**: inferência ou valor de partida meu, sem fonte. É hipótese
  para afinar no aparelho.

---

## 0. Resumo

1. **Um seno é um relógio.** O que parece "robótico" é o período fixo: o
   olho percebe a repetição. Três ferramentas resolvem isso. Cada parte do
   corpo **persegue um alvo com mola** (atrasa, passa do ponto e assenta). O
   ocioso usa **ruído suave com oitavas**, que nunca se repete. As decisões
   são **sorteadas com pesos, tempo de espera e inércia**. A ideia não é nova:
   Perlin já animava "marionetes" com ruído rítmico e estocástico em 1995
   ([IEEE TVCG](https://ieeexplore.ieee.org/document/468392),
   [NYU MRL/Improv](https://mrl.cs.nyu.edu/projects/improv/)).
2. **A mola padrão é a "second order dynamics" do t3ssel8r**, com três
   números de leitura intuitiva: `f` (Hz), `zeta` (amortecimento) e `r`
   (resposta inicial). `r > 1` passa do ponto e `r < 0` antecipa. Para
   suavização sem física, use o amortecedor por meia-vida de Daniel Holden.
3. **A arquitetura recomendada é um rig de ~25 números.** Uma camada de
   comportamento escolhe alvos, uma de ruído soma variação, uma de reação
   aplica impulsos e as molas integram tudo. Há **um único `Ticker`**, e o
   pintor redesenha por `CustomPainter(repaint: rig)`, sem build e sem
   layout.
4. **[App] O código já começou isso.** `lib/widgets/vida/dinamica.dart`
   implementa `Mola`, `Mola2` e `Ruido`, e `motor_de_vida.dart` tem um
   "cérebro" com pesos e espera. Mas `lib/widgets/pet.dart` ainda tem 10
   `AnimationController` (respiro, flutua, cauda, ciclo, pisca, orelha,
   toque, gesto, transição, gosto), `Timer`s para piscar, orelha e gesto, e
   um `shouldRepaint` que compara ~20 campos (`pet.dart:388-490`,
   `:5304`). O caminho é migrar esses relógios para o motor, um por um.

---

## 1. Os 12 princípios aplicados a um bicho procedural

[Fato] As definições abaixo vêm de Thomas & Johnston, resumidas em
<https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation>.

| Princípio | Definição | Tradução procedural |
|---|---|---|
| Squash & stretch | dá peso; "o volume não muda" | escala X/Y com `sx·sy = 1` (2D) dirigida por mola subamortecida (§2.6) |
| Antecipação | prepara a ação | mola com `r < 0`, ou um alvo intermediário oposto por 80–150 ms [Opinião] |
| Follow-through / overlapping | partes soltas continuam depois que o corpo para | cadeia de molas com `f` decrescente da base à ponta (§2.3) |
| Slow in / slow out | mais quadros perto dos extremos | uma mola já nasce com ease: nunca use `lerp` linear no tempo |
| Arcos | movimento natural é curvo | rotação em torno de pivô (cabeça gira no pescoço, cauda na base), nunca translação reta |
| Ação secundária | apoia a principal sem competir | orelhas, cauda e pelo reagem às molas do corpo, com amplitude menor |
| Timing | número de quadros = velocidade, peso e humor | `f` por humor: feliz é mais alto, triste e com sono é mais baixo |
| Exagero | a realidade "numa forma mais extrema" | amplitudes de 2 a 3× o real, com moderação |
| Apelo | carisma | assimetria: orelhas com sementes de ruído diferentes, nunca espelhadas (Thomas & Johnston alertam contra "twins") |

Valores concretos com fonte:

- **Overshoot por amortecimento.** [Fato] Para um sistema de segunda ordem
  subamortecido, `PO = 100·exp(−ζπ/√(1−ζ²))`. Isso dá ζ = 0,3 → 37%,
  ζ = 0,5 → 16%, ζ = 0,6 → 9,5%, ζ = 0,7 → 4,6% e ζ = 0,8 → 1,5%
  ([TMU Control Systems](https://pressbooks.library.torontomu.ca/controlsystems/?p=781)).
- **Quando permitir bounce.** [Fato] A Apple recomenda começar com 100% de
  amortecimento (sem overshoot) e "recompensar o momento com um pouco de
  overshoot" só quando o gesto que move o objeto tem momento. No Music,
  tocar usa 100% e arrastar para dispensar usa 80%. A Apple também evita
  descrever comportamento elástico por duração
  ([WWDC 2018, Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803/)).
- **Durações de referência.** [Fato] Transições móveis típicas levam ~300 ms
  (entrada ~225 ms, saída ~195 ms), e acima de 400 ms "pode parecer lento"
  ([Material, duration & easing](https://m1.material.io/motion/duration-easing.html)).
- **Antecipação e responsividade.** [Fato] Em jogos, a antecipação é curta
  no personagem do jogador, para responder rápido ao input, e mais longa em
  NPCs ([gameanim.com](https://www.gameanim.com/?p=115)). [Opinião] No
  Baru, a reação ao toque precisa começar no mesmo quadro (um impulso de
  squash), e a antecipação só cabe em ações que o bicho inicia sozinho: pulo
  e espreguiçar com 120–250 ms de "agachar"; um aceno com 80 ms.
- **Squash proporcional ao impacto.** [Fato] O talk "Juice it or lose it"
  recomenda esticar e espremer objetos em eventos e fazê-los "balançar" no
  quique ([resumo](https://rpgplayground.com/research-making-a-juicy-game/),
  [Game Developer](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-)).
  [Opinião] Valores de partida: squash máximo de 0,82×0,82⁻¹ num pouso
  forte, 0,93 num toque e 1,10 de stretch no ar.

---

## 2. Técnicas procedurais

### 2.1 Mola de segunda ordem (t3ssel8r)

[Fato] O vídeo "Giving Personality to Procedural Animations using Math"
(t3ssel8r, 2022) define o sistema `y + k1·y' + k2·y'' = x + k3·x'`. O
crate `spring_motion`, baseado no vídeo, converte os parâmetros assim
([fonte](https://docs.rs/spring_motion/latest/src/spring_motion/lib.rs.html)):
`k1 = ζ/(πf)`, `k2 = 1/(2πf)²` e `k3 = r·ζ/(2πf)`. Os ports comentados
explicam os parâmetros
([gist Godot](https://gist.github.com/Andicraft/ab605dda924a0321e755abf8f573ebd7)):

- `f` é a frequência em Hz ("as coisas andam mais rápido se for alto");
- `z = 0` vibra para sempre, `0 < z < 1` assenta balançando, `1` é o
  amortecimento crítico e `> 1` chega devagar;
- `r < 1` responde devagar, `r = 1` segue o alvo na hora e `r > 1` passa do
  ponto.

O port Unity expõe `R` de −1 a 1
([gist Unity](https://gist.github.com/ttalexander2/3b8743bf2d38d40a017e807aab43c016)),
e traz a trava de estabilidade "clamp k2 to guarantee stability without
jitter". [Opinião, derivada da equação] Com `r < 0`, o termo `k3·x'` empurra
a aceleração inicial **contra** a direção em que o alvo andou: é antecipação
de graça.

```dart
class SecondOrder {
  SecondOrder({required double f, required double zeta, double r = 0, double x0 = 0})
      : _xp = x0, y = x0 { tune(f, zeta, r); }
  late double _k1, _k2, _k3;
  double _xp, y, yd = 0;

  void tune(double f, double zeta, double r) {
    final w = 2 * pi * f;
    _k1 = zeta / (pi * f);
    _k2 = 1 / (w * w);
    _k3 = r * zeta / w;
  }

  double update(double dt, double x, {double? xd}) {
    if (dt <= 0) return y;
    xd ??= (x - _xp) / dt;               // velocidade estimada do alvo
    _xp = x;
    final k2s = max(_k2, max(dt * dt / 2 + dt * _k1 / 2, dt * _k1)); // estabilidade
    y  += dt * yd;                        // Euler semi-implícito
    yd += dt * (x + _k3 * xd - y - _k1 * yd) / k2s;
    return y;
  }
  void kick(double impulse) => yd += impulse; // toque, pouso
}
```

**Alternativas e quando usar cada uma:**

- [Fato] A forma fechada criticamente amortecida de Ryan Juckett é
  `x(t) = ((v0 + x0ω)t + x0)e^(−ωt)`. Os coeficientes podem ser calculados
  uma vez e reaproveitados
  ([Ryan Juckett, Damped Springs](https://www.ryanjuckett.com/damped-springs/)).
  Use para câmera e UI, onde não pode haver overshoot.
- [Fato] O amortecedor exato por meia-vida de Daniel Holden é
  `x = lerp(x, g, 1 − 2^(−dt/halflife))`. Ele é estável para qualquer `dt`,
  ao contrário de `lerp(x, g, k·dt)`, que diverge com `k·dt > 1`. O mesmo
  artigo traz a **mola dupla**, em que uma mola persegue outra para dar uma
  resposta em "S", e a **inercialização**, em que se guarda o desvio no
  instante da troca de estado e ele decai até zero com mola
  ([The Orange Duck, Spring-It-On](https://theorangeduck.com/page/spring-roll-call)).
  A inercialização é a técnica de transição de Gears of War, e na versão de
  Gears 4 saiu 60% mais barata que blend
  ([GDC 2018, Bollo](https://www.gdcvault.com/play/1025165/Inertialization),
  [SIGGRAPH 2017](https://history.siggraph.org/wp-content/uploads/2022/09/2017-Talks-Bollo_High-Performance-Animation-in-Gears-of-War-4.pdf)).
- [Fato] O Flutter já traz `SpringDescription.withDampingRatio` e
  `withDurationAndBounce`
  ([API](https://api.flutter.dev/flutter/physics/SpringDescription-class.html)).
  Servem para a UI, mas não para o rig, porque são simulações de ida única,
  presas a um `AnimationController`.

**Tabela de partida** [Opinião; ζ conferido com a fórmula de overshoot e
com a regra da Apple]:

| Parâmetro | f (Hz) | ζ | r | Comentário |
|---|---|---|---|---|
| corpo X (passeio) | 0,9 | 0,85 | 0 | massa grande, quase sem overshoot |
| inclinação da cabeça | 1,3–1,8 | 0,45 | 0,3 | ~20% de overshoot dá "curiosidade" |
| squash/stretch | 3–4 | 0,25–0,35 | 0 | 30–40% de overshoot: o pudim |
| orelhas | 3–5 | 0,2–0,3 | 0 | ação secundária viva |
| segmentos da cauda | 2,6 → 1,6 (base→ponta) | 0,3 | 0 | atraso crescente |
| pupila (sacada) | 10–14 | 0,9 | 0 | chega em ~50–80 ms |
| olhar/cabeça seguindo o dedo | 2–2,5 | 0,55 | 0,4 | |
| arrastado pelo dedo | 3–4 | 0,5–0,7 | 0 | atraso de "puxar algo com massa" |
| mistura de humor (pesos) | meia-vida 0,25–0,4 s | — | — | amortecedor de Holden, sem overshoot |

[App] As molas de `motor_de_vida.dart` (`_olhar f 2.4 ζ .55 r .4`,
`_achata f 3.2 ζ .28`, `_cauda f 2.6 ζ .3`, `_x f .9 ζ .85`) já estão dentro
dessas faixas.

### 2.2 Ruído: 1D, 2D e fractal

[Fato] O ruído de valor interpola números aleatórios presos nos inteiros.
Com a curva cúbica `3f² − 2f³` ele é suave, e a melhoria de Perlin troca
essa curva pela quíntica `6f⁵ − 15f⁴ + 10f³`, que achata as pontas. O
simplex tem menos custo e nenhum artefato direcional
([Book of Shaders, cap. 11](https://thebookofshaders.com/11/)). O fBm soma
oitavas, aumentando a frequência por "lacunaridade" e reduzindo a amplitude
por "ganho" ([cap. 13](https://thebookofshaders.com/13/)). A mesma ideia,
ruído em vez de seno, sustenta o screen shake por "trauma" de Squirrel
Eiserloh: "todos os deslocamentos são governados por ruído, o que garante um
tremor suave e contínuo"
([Bevy, exemplo baseado no talk](https://bevy.org/examples/camera/2d-screen-shake/),
[GDC 2016](https://gamedeveloper.com/programming/video-sprucing-up-cameras-with-math)).

```dart
// Hash inteiro -> [-1,1]. Sem tabela: não há período.
double _h1(int i, int seed) {
  var x = (i * 0x27d4eb2d + seed * 0x165667b1) & 0xffffffff;
  x = ((x ^ (x >> 15)) * 0x85ebca6b) & 0xffffffff;
  x = ((x ^ (x >> 13)) * 0xc2b2ae35) & 0xffffffff;
  x ^= x >> 16;
  return x / 0x7fffffff - 1.0;
}
double _fade(double f) => f * f * f * (f * (f * 6 - 15) + 10);

double noise1(double t, int seed) {
  final i = t.floor(); final f = t - i;
  return _lerp(_h1(i, seed), _h1(i + 1, seed), _fade(f));
}

double noise2(double x, double y, int seed) {      // ruído de valor 2D
  final ix = x.floor(), iy = y.floor();
  final fx = _fade(x - ix), fy = _fade(y - iy);
  double c(int a, int b) => _h1(a * 73856093 ^ b * 19349663, seed);
  return _lerp(_lerp(c(ix, iy), c(ix + 1, iy), fx),
               _lerp(c(ix, iy + 1), c(ix + 1, iy + 1), fx), fy);
}

double fbm1(double t, int seed, {int oct = 3, double lac = 2.03, double gain = 0.5}) {
  var sum = 0.0, amp = 1.0, freq = 1.0, norm = 0.0;
  for (var o = 0; o < oct; o++) {
    sum += noise1(t * freq + o * 17.3, seed + o) * amp;
    norm += amp; amp *= gain; freq *= lac;
  }
  return sum / norm;
}
```

Uso [Opinião]:

- **Respiração sem repetição.** A fase avança com velocidade modulada:
  `phase += dt · (1/period) · (1 + 0.25·fbm1(t·0.07, s1))`, e
  `breath = sin(2π·phase) · depth`, com
  `depth = 1 + 0.35·fbm1(t·0.05, s2)`. O seno continua lá, mas o ritmo e a
  fundura derivam. De vez em quando entra um "suspiro" sorteado (1,6× a
  fundura e 1,5× o período). [Fato] O período de base vem da fisiologia:
  cães e gatos em repouso ou dormindo respiram 15–30 vezes por minuto
  ([VCA](https://vcahospitals.com/know-your-pet/home-breathing-rate-evaluation)),
  ou seja, um ciclo de 2–4 s. Dormindo, fique no lento.
- **Balanço ocioso, peso trocando de pé, cauda que ora abana, ora para.**
  Use `fbm1` com uma semente por canal e frequência de 0,1–0,4 Hz. Para
  ligar e desligar o abano, use o ruído como *envelope*:
  `wag = smoothstep(0.1, 0.5, noise1(t·0.08)) · sin(phaseWag)`.
- **2D:** `noise2(t·f, k)` dá campos correlacionados por canal. O pelo do
  dorso pode usar `noise2(posição_ao_longo_do_corpo, t·0,3)` para uma
  "brisa" que corre pelo corpo.
- [App] `Ruido` em `dinamica.dart` usa tabela de 256 valores e período de
  `256/freq` segundos. A 0,07 Hz isso dá ~1 h, o que é aceitável. O hash
  acima elimina o período por completo.

### 2.3 Cadeias: cauda, orelhas e o bicho pendurado

[Fato] O Verlet guarda a posição anterior em vez da velocidade
(`x += x − oldx + a·dt²`). As restrições de distância são satisfeitas por
relaxação: `delta = x2 − x1; diff = (|delta| − rest)/|delta|`, e cada ponto
anda metade da correção. O Hitman usava de 1 a 10 iterações, "o suficiente
para o movimento parecer natural"
([Jakobsen, Advanced Character Physics](https://www.gamedeveloper.com/programming/advanced-character-physics)).
Atenção: a transcrição do Game Developer escreve `x1 −= delta·0,5·diff;
x2 += delta·0,5·diff`. Com esse `diff`, isso afasta os pontos (com x1 = 0,
x2 = 2 e rest = 1, a distância vai a 3). Use `x1 += …; x2 −= …`.

Para um pintor 2D, prefira **cadeia de ângulos com molas** [Opinião]. Ela é
mais barata, sempre estável e mais fácil de afinar:

```dart
// Cauda com N segmentos. Cada um persegue o ângulo do pai + pose de repouso.
// f cai em direção à ponta: a ponta atrasa (overlapping action).
final segs = List.generate(N, (i) =>
    SecondOrder(f: lerpD(2.6, 1.4, i / (N - 1)), zeta: 0.3));

void tailStep(double dt, double rootAngle, double bodyVelX) {
  var parent = rootAngle;
  for (var i = 0; i < N; i++) {
    // Inércia: o corpo andando para a direita deixa a cauda para trás.
    final drag = -bodyVelX * 0.002 * (i + 1);
    final target = parent + restCurl[i] + wag * wagGain[i] + drag;
    parent = segs[i].update(dt, target);   // ângulo absoluto do segmento i
  }
}
```

Use Verlet de verdade só quando o bicho está **pendurado pelo dedo**. Aí o
pivô é o dedo. [Fato] O pêndulo simples segue `θ'' + (g/ℓ)·sen θ = 0`, com
período de `2π√(ℓ/g)` para ângulos pequenos
([Wikipedia](https://en.wikipedia.org/wiki/Pendulum_(mechanics))).
[Opinião, derivação padrão de pivô acelerado] Com o dedo acelerando em
`(ax, ay)`, a equação fica:

```dart
// θ = 0 é pendurado reto para baixo. Ajuste g/ℓ para ~1,3 Hz de balanço.
thetaAcc = -((g + ay) / L) * sin(theta) - (ax / L) * cos(theta) - c * thetaVel;
thetaVel += thetaAcc * dt;  theta += thetaVel * dt;   // semi-implícito
// Pernas e cauda: cadeias de molas presas ao corpo, que já balança.
// Corpo esticado: stretchY = 1 + 0.08 * clamp(|thetaVel| / 6, 0, 1).
```

### 2.4 Olhar: atenção, sacadas e cabeça

Fatos para calibrar:

- **Duração da sacada.** [Fato] Ela cresce com a amplitude, numa média de
  ~24,7 ms + 2,8 ms/° (inclinação individual de 2,22 a 3,37 ms/°), e
  costuma terminar "em dezenas de milissegundos"
  ([Harwood et al., J Neurosci 1999](https://pmc.ncbi.nlm.nih.gov/articles/PMC6782780)).
  Em 60 fps, isso é de 1 a 4 quadros: o olho **salta**, não desliza.
- **Fixação.** [Fato] Na leitura, as fixações duram ~225–250 ms, as
  sacadas 25–60 ms, e o texto difícil alonga as fixações
  ([SAGE, Encyclopedia of the Mind](https://sk.sagepub.com/ency/edvol/embed/encyclopedia-of-the-mind/chpt/eye-movements-during-reading)).
  Outras fontes dão uma faixa de 150–500 ms
  ([UNC](https://users.castle.unc.edu/~jlsmith/ling060/outlines/0201_visual-info.pdf)).
  É um dado de leitura e não vale para toda tarefa. [Opinião] Um pet ocioso
  que "observa" deve fixar mais tempo: de 0,4 a 2,5 s.
- **Sacadas estatísticas.** [Fato] O "Eyes Alive" (SIGGRAPH 2002) modela
  magnitude, direção, duração e intervalo das sacadas a partir de
  eye-tracking. Na comparação com olhos parados e com sacadas aleatórias, as
  sacadas estatísticas foram preferidas
  ([UPenn](https://www.cis.upenn.edu/~badler/papers/EyesAlive.pdf),
  [ACM](https://dcmpx.remotevs.com/org/doi/SL/10.1145/566570.566629)).
  Ele cita que a maioria das sacadas naturais tem 15° ou menos.
- **Olho e cabeça.** [Fato] Olhos e cabeça se movem juntos, na mesma
  direção, mas o olho opera numa escala de tempo diferente da cabeça. A
  contribuição de cada um segue leis simples, levantadas em macacos
  ([Itti et al.](https://ilab.usc.edu/publications/Itti_etal03spienn.html),
  [Andrist et al. 2012](https://www.microsoft.com/en-us/research/?p=557628)).
  Uma integração comercial faz a cabeça "ajudar" quando o alvo passa de
  ~10° do centro do olho; é um padrão de fornecedor, não uma lei
  ([Convai](https://docs.convai.com/api-docs/plugins-and-integrations/convai-unity-sdk/utilities/gaze-and-attention/quick-start)).
- **A lição do Trico.** [Fato] Em The Last Guardian, girar pescoço e depois
  cabeça fez o bicho parecer "uma cobra de brinquedo". A solução foi fixar
  primeiro a posição e a rotação da cabeça e só então o pescoço, como animais
  reais que estabilizam a cabeça enquanto o corpo se move
  ([gameanim, entrevista com Masanobu Tanaka](https://www.gameanim.com/?p=15474)).

```dart
class Gaze {
  final pupil = Spring2(f: 12, zeta: 0.9);    // sacada rápida
  final head  = Spring2(f: 1.8, zeta: 0.5, r: 0.2);
  Offset target = Offset.zero;                 // -1..1, vem da atenção
  double _nextSaccade = 0.6;

  void step(double dt, double t, Attention att, BlinkScheduler blink) {
    final goal = att.currentTarget(t);         // dedo > toque recente > interesse > aleatório
    _nextSaccade -= dt;
    final big = (goal - target).distance > 0.35;
    if (big || _nextSaccade <= 0) {
      // Pequenos desvios (≤ ~15°) são a maioria: sorteie perto do objetivo.
      target = goal + randomInDisk(att.locked ? 0.05 : 0.18);
      _nextSaccade = att.locked ? uniform(0.3, 0.9) : logNormal(median: 1.1, sigma: 0.5);
      if (big && rnd() < 0.4) blink.request(); // piscar junto da troca de olhar
    }
    final micro = Offset(fbm1(t * 1.3, 91), fbm1(t * 1.3, 92)) * 0.015; // tremor fino
    pupil.target = clampDisk(target, 1.0) + micro;
    // A cabeça só acompanha o que o olho não cobre, e atrasada.
    final excess = target - clampDisk(target, 0.35);
    head.target = excess * 0.8 + target * 0.15;
    pupil.update(dt); head.update(dt);
  }
}
```

### 2.5 Piscar

Fatos:

- **Ritmo humano.** [Fato] Em humanos, o ritmo depende da tarefa: ~10,7/min
  lendo e ~31–32/min conversando ou andando, com grande variação individual
  ([medRxiv 2022](https://medrxiv.org/content/10.1101/2022.11.19.22282503.full.pdf)).
  Sentado, a média é de 13,9/min, numa faixa de 6,9–21,8
  ([Dovepress](https://www.dovepress.com/investigation-of-extended-blinks-and-interblink-intervals-in-subjects--peer-reviewed-fulltext-article-OPTH)).
  O intervalo entre piscadas segue distribuição **log-normal**, em "J", que
  fica simétrica em escala logarítmica, com 13,7 ± 7,8 piscadas/min
  ([Arq Bras Oftalmol 2010](https://www.aboonline.org.br/details/1706/en-US)).
- **Ritmo animal.** [Fato] Cães piscam ~6,5/min e gatos ~4,1/min enquanto
  olham o dono
  ([PMC8962689](https://pmc.ncbi.nlm.nih.gov/articles/PMC8962689)).
- **Forma da piscada.** [Fato] Fechar leva ~100 ms e abrir ~200 ms: a
  abertura é a fase mais lenta
  ([arXiv 2211.05541](https://arxiv.org/pdf/2211.05541)).
- **Piscada lenta.** [Fato] Em gatos, a piscada lenta e o estreitar dos
  olhos funcionam como comunicação positiva com humanos
  ([Humphrey et al. 2020](https://researchportal.port.ac.uk/en/publications/the-role-of-cat-eye-narrowing-movements-in-cat-human-communicatio/)).
- **"Considered randomness."** [Fato] No personagem GoodGood, feito em Rive,
  piscar num timer aleatório "pareceu robótico". O time amarrou as piscadas
  a mudanças de olhar, transições de pose e movimentos grandes, e manteve
  também as aleatórias
  ([With Love, Procedural Animation in Rive](https://withloveapp.substack.com/p/procedural-animation-in-rive-how?r=535ifv)).

```dart
class BlinkScheduler {
  double _next = 2.0, _t = -1;   // _t < 0: não está piscando
  bool _double = false, _slow = false;
  // Mediana de partida [Opinião]: 3,5 s acordado (entre o humano e o animal,
  // porque desenho lê melhor com mais piscadas), 6 s concentrado.
  double median = 3.5, sigma = 0.55;

  void request({bool slow = false}) { if (_t < 0) _start(slow: slow); }

  double step(double dt, {required bool asleep}) {   // devolve eyeOpen 0..1
    if (asleep) return 0;
    if (_t < 0) {
      _next -= dt;
      if (_next <= 0) _start();
      return 1;
    }
    _t += dt;
    final close = _slow ? 0.22 : 0.08, hold = _slow ? 0.30 : 0.03, open = _slow ? 0.40 : 0.17;
    double v;
    if (_t < close)              v = 1 - easeIn(_t / close);         // fecha rápido
    else if (_t < close + hold)  v = 0;
    else if (_t < close + hold + open) v = easeOut((_t - close - hold) / open); // abre devagar
    else {
      v = 1; _t = -1;
      if (_double) { _double = false; _next = uniform(0.12, 0.22); }
      else _next = (exp(log(median) + sigma * gaussian())).clamp(1.0, 12.0);
    }
    return v;
  }
  void _start({bool slow = false}) { _t = 0; _slow = slow; _double = !slow && rnd() < 0.12; }
}
// Ganchos: Gaze.request() em sacada grande; request(slow: true) no fim de um afago;
// median *= 0.6 quando assustado; median *= 1.8 quando "focado" (pomodoro).
```

### 2.6 Squash & stretch com conservação de volume

[Fato] Para o volume ficar constante, um eixo encolhe enquanto os outros
crescem ([Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation),
[Autodesk 3ds Max](https://download.autodesk.com/us/3DSmax/2012help/files/GUID-D51970C6-5F52-4C52-8CA8-55FDBEB7A03-289.htm)).
As patentes da Pixar usam um "squamount" de 0 a 1 para conservar o volume
parcialmente ([US7221380](https://patents.google.com/patent/US7221380)).
[Opinião/derivação] Em 2D, conservar a área significa `sx·sy = 1`. Com
conservação parcial `p`, fica `sx = s^(−p)`.

```dart
final squash = SecondOrder(f: 3.4, zeta: 0.3);   // 0 = repouso; >0 achata; <0 estica

void onLand(double impactVy) => squash.kick(clamp(impactVy / 400, 0, 1) * 9);
void onPoke(double strength) => squash.kick(4 * strength);

(double sx, double sy) squashScale(double dt, {double inAirVy = 0, double p = 1.0}) {
  // No ar: estica com a velocidade vertical. No chão, a mola assenta e balança.
  squash.update(dt, inAirVy == 0 ? 0 : -clamp(inAirVy.abs() / 500, 0, 1) * 0.10);
  final s = (1 - squash.y * 0.18).clamp(0.75, 1.25);  // sy
  return (pow(s, -p).toDouble(), s);                  // sx·sy = 1 quando p = 1
}
// No paint: escale em torno do PONTO DE APOIO (pés), não do centro:
// canvas.translate(feet.dx, feet.dy); canvas.scale(sx, sy); canvas.translate(-feet.dx, -feet.dy);
// Para esticar na direção do movimento (arremesso): rotate(+a) · scale(s, 1/s) · rotate(−a).
```

---

## 3. Comportamento: máquina de estados, variedade e camadas

### 3.1 O que Duolingo e Rive fazem

- [Fato] O Duolingo escolheu o Rive pela State Machine, onde se controla
  quais estados tocam e como transitam e se misturam. As bocas (20+ visemas
  por personagem) rodam **em paralelo** aos estados de corpo. Acenos de
  cabeça, piscadas e sobrancelhas são ociosos, e no fim do desafio há uma
  reação de acerto ou erro
  ([Duolingo blog](https://blog.duolingo.com/world-character-visemes)).
- [Fato] A Lily, da videochamada do Duolingo, tem 8 animações de cabeça e 8
  de corpo que se combinam em mais de 64 variações neutras, "o que evitou
  loops ociosos repetitivos". Quando a IA demora, ela parece pensar, e a
  espera vira intenção ([Rive blog](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life)).
  **Lição:** variedade vem de **combinar camadas independentes**, não de
  animar mais clipes.
- [Fato] No Rive, cada camada toca um estado por vez. Várias camadas rodam
  juntas, e quando duas mexem na mesma propriedade, a de baixo vence
  ([Rive docs, Layers](https://rive.app/docs/editor/state-machine/layers)).
  As transições têm duração (0 = corte seco, o padrão), "Allow exit during
  transition" (interrompível) e exit time
  ([Transitions](https://rive.app/docs/editor/state-machine/transitions)).
  O blend aditivo é "não linear" e pode surpreender
  ([States](https://rive.app/community/doc/states/docEwEIEWU1U)).
- [Fato] Uma armadilha conhecida: ligar o *Any State* a vários estados
  sorteados sem condição faz a máquina percorrê-los todos a cada quadro. A
  correção é um estado "idle" central que sorteia a próxima variação
  ([fórum Rive](https://rive.app/community/forums/bugs/fsLjspgTHYcR/randomized-animations-in-parent-groups/ftkc674yHQY8)).
- [Fato] Não encontrei material técnico público sobre como o **Finch**
  anima o pássaro. As matérias falam só do produto
  ([Waltonian](https://waltonian.eastern.edu/ae/the-art-of-finch/)).
  Nenhuma afirmação deste laudo depende do Finch.

### 3.2 Escolha ponderada, baldes, inércia e espera

[Fato] Na teoria de utilidade para jogos, escolher sempre a melhor ação
parece "robótico", e sortear por peso às vezes escolhe algo "totalmente
estúpido". O meio-termo é sortear por peso entre as melhores (o top-N, ou
quem ficou a até 10% do máximo). Os **baldes** (dual utility) servem para a
urgência: com fome, o Sim nem considera diversão. Contra oscilação há
**inércia** (bônus para a ação corrente) e **cooldown**. No Sims Medieval, o
Sim só decide quando a fila de interações esvazia
([Game AI Pro, cap. 9](http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter09_An_Introduction_to_Utility_Theory.pdf)).
Um exemplo mínimo de idle ponderado usa pesos 70/20/10
([python-statemachine](https://python-statemachine.readthedocs.io/en/latest/auto_examples/weighted_idle_machine.html)).

```dart
class IdleAction {
  final String id; final int bucket;           // 0 = urgente (reação), 1 = necessidade, 2 = ócio
  final double baseWeight, cooldown, minDur, maxDur;
  final double Function(PetContext c) context; // multiplicador: humor, hora, energia...
  double lastEnd = -1e9;
}

class IdleScheduler {
  IdleAction? current; double endsAt = 0;
  final rng = Random();

  void step(double t, PetContext c, List<IdleAction> all) {
    if (current != null && t < endsAt && !c.interrupted) return;  // decide só ao terminar
    final byBucket = groupBy(all, (a) => a.bucket);
    for (final b in byBucket.keys.toList()..sort()) {
      final cands = <(IdleAction, double)>[];
      for (final a in byBucket[b]!) {
        final since = t - a.lastEnd;
        if (since < a.cooldown) continue;                         // espera dura
        final fresh = smoothstep(a.cooldown, a.cooldown * 3, since); // volta aos poucos
        final inertia = identical(a, current) ? 0.3 : 1.0;          // evita repetir já
        final w = a.baseWeight * a.context(c) * (0.25 + 0.75 * fresh) * inertia;
        if (w > 0) cands.add((a, w));
      }
      if (cands.isEmpty) continue;                                 // balde vazio → próximo
      cands.sort((x, y) => y.$2.compareTo(x.$2));
      final top = cands.where((e) => e.$2 >= cands.first.$2 * 0.35).toList(); // corta "estúpidas"
      current?.lastEnd = t;
      current = weightedPick(top, rng);
      endsAt = t + lerpD(current!.minDur, current!.maxDur, rng.nextDouble());
      return;
    }
  }
}
// Repertório de partida [Opinião], balde 2: ficar (40, cd 0), observar (25, cd 4 s),
// farejar (12, cd 15 s), coçar orelha (8, cd 25 s), espreguiçar (6, cd 40 s),
// bocejar (4, cd 60 s; ×3 à noite), chamar a pessoa (5, cd 45 s; ×2 após 60 s sem toque).
```

### 3.3 Camadas aditivas e humor contínuo

[Fato] Uma animação aditiva guarda a **diferença** entre duas poses e só
funciona aplicada sobre outra. A respiração é o caso clássico: o delta de
peito e coluna, somado a qualquer estado
([Unreal, Additive](https://docs.unrealengine.com/udk/Three/AdditiveAnimations.html),
[Unity, Animator Layers](https://learn.unity.com/tutorial/3-7-creating-and-configuring-animator-layers)).
[Fato] O Improv de Perlin já "mistura e empilha animações, compondo-as no
tempo", com decisões influenciadas por ruído "em muitos níveis", do piscar à
atitude ([NYU MRL](https://mrl.cs.nyu.edu/projects/improv/)).

Ordem de composição por parâmetro do rig [Opinião]:

```
valor = mola(  pose_do_humor(pesos)          // base: mistura contínua de humores
             + alvo_do_comportamento * wB     // o que ele está fazendo (override suave)
             + reação_transitória )           // impulso de toque, decai por mola
      + ruído_ocioso * ampRuído * (1 - supressão)   // aditivo, fora da mola
      + respiração * ampResp                        // aditivo
```

- O **humor** vira um vetor de pesos, cada um com o amortecedor de Holden
  (meia-vida de ~0,3 s), e a pose resulta de `Σ wᵢ·poseᵢ`. Isso substitui os
  booleanos `feliz/triste/dormindo` e o crossfade do desenho inteiro.
- A **supressão** sobe quando há ação ou toque. O ruído some enquanto ele
  presta atenção, e o bicho "fica quieto para ouvir".
- **Transições** (de ação para ação, ou de humor para humor) são sempre
  interrompíveis: o alvo muda e a mola continua do valor e da velocidade
  atuais. É a inercialização "de graça". [Fato] A Apple trata isso como
  requisito: a animação começa do valor atual e pode ser agarrada e invertida
  a qualquer momento ([WWDC 2018](https://developer.apple.com/videos/play/wwdc2018/803/)).

---

## 4. Reações físicas ao toque

1. **Arrastar com mola.** O corpo persegue o dedo com `Spring2(f: 3.5, ζ:
   0.6)`. A inclinação é proporcional à velocidade horizontal, com
   `tilt = clamp(vx·0,0015, ±0,35)` [Opinião]. Ao soltar, use a ideia de
   **projeção de momento** da Apple: estime onde o gesto "queria" chegar a
   partir de velocidade e desaceleração e leve o objeto até lá
   ([WWDC 2018](https://developer.apple.com/videos/play/wwdc2018/803/)).
   Depois disso, gravidade e squash no pouso proporcional a `vy` (§2.6).
2. **Pegar no colo.** É o pêndulo de pivô acelerado da §2.3, com as pernas e
   a cauda em cadeias de molas de ζ baixo (0,15–0,25). O corpo estica 5–8%.
3. **Gelatina no cutucão.** [Fato] O JellyCar usa massas pontuais e molas
   nas bordas e no interior. Molas sozinhas deixam formas finas "virarem do
   avesso", e por isso o autor acrescentou **shape matching**, uma moldura
   rígida da forma de repouso que puxa cada ponto
   ([Game Developer, JellyCar](https://gamedeveloper.com/programming/deep-dive-the-soft-body-physics-of-jelly-car-explained)).
   [Fato] Em Müller et al. 2005, o ponto anda `α·(gᵢ − xᵢ)` em direção ao
   alvo `gᵢ` por passo. `α ∈ [0, 1]` simula a rigidez, e o esquema é
   incondicionalmente estável
   ([SIGGRAPH 2005](https://cg.informatik.uni-freiburg.de/publications/2005_SIGGRAPH_deformationShapeMatching.pdf)).
   [Opinião] No `CustomPainter`, aplique isso aos **pontos de controle do
   contorno** do corpo (8–16 pontos que já viram `cubicTo`). Cada ponto
   ganha um deslocamento com `Spring2(f: 4–6, ζ: 0.25)` que persegue zero
   (é o shape matching com a pose de repouso). O cutucão empurra os pontos
   num raio, com queda `exp(−d²/2σ²)`, e soma um squash global pequeno.

   ```dart
   void poke(Offset p, double strength) {
     for (var i = 0; i < ctrl.length; i++) {
       final d = (ctrl[i].rest - p).distance;
       final fall = exp(-d * d / (2 * 18 * 18));
       final n = (ctrl[i].rest - center).normalized();   // empurra para dentro
       ctrl[i].offset.kick(-n * strength * 40 * fall);
     }
     squash.kick(3 * strength);
   }
   // paint: ponto_i = rest_i + offset_i.value  → reconstrói o Path com path.reset().
   ```
4. **Afago e resposta do pelo.** [Opinião] A velocidade do dedo inclina os
   tufos sob ele (mola por tufo, ou por faixa do corpo). A cabeça inclina em
   direção à mão com `headTilt.target += 0,15`, as orelhas abaixam e os
   olhos se fecham devagar. No fim do afago vem uma **piscada lenta** (§2.5),
   com respaldo do estudo com gatos.
5. **Elástico nas bordas.** [Fato] Para a Apple, o rubber band "indica
   suavemente os limites" e, sem ele, não se distingue um telefone travado de
   um conteúdo no fim ([WWDC 2018](https://developer.apple.com/videos/play/wwdc2018/803/)).
   A resistência padrão estilo iOS é de 0,55
   ([Bluecadet](https://unity.bluecadet.com/spring/rubberband/)).
   [Opinião] Uma forma usual é `out = d·(1 − 1/(x·c/d + 1))`, com `c =
   0,55`, onde `x` é o excesso e `d` a dimensão. Use ao arrastar o bicho
   para fora do habitat.

---

## 5. Arquitetura recomendada em Flutter

### 5.1 O rig

```dart
class PetRig extends ChangeNotifier {          // o pintor escuta isto
  // corpo
  double bodyX = 0, bodyY = 0, bodyTilt = 0, scaleX = 1, scaleY = 1, breath = 0;
  // cabeça e rosto
  double headTilt = 0, headTurn = 0, eyeOpenL = 1, eyeOpenR = 1, browL = 0, browR = 0;
  Offset pupil = Offset.zero; double mouthCurve = 0, mouthOpen = 0, blush = 0;
  // apêndices
  double earL = 0, earR = 0; final tail = List<double>.filled(5, 0);
  final contour = List<Offset>.filled(12, Offset.zero);   // deslocamentos de gelatina
  void commit() => notifyListeners();          // 1× por quadro
}
```

### 5.2 O laço

```dart
class _PetViewState extends State<PetView> with SingleTickerProviderStateMixin {
  late final rig = PetRig();
  late final brain = PetBrain(rig);            // comportamento + ruído + molas
  late final Ticker _ticker = createTicker(_tick)..start();
  Duration _last = Duration.zero;

  void _tick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6; _last = elapsed;
    dt = dt.clamp(0, 0.1);                     // voltou do fundo: não teleporta
    const maxStep = 1 / 60;                    // subpassos para física com dt grande
    while (dt > 0) { final h = min(dt, maxStep); brain.step(h); dt -= h; }
    rig.commit();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: GestureDetector(
      onPanStart: brain.onGrab, onPanUpdate: brain.onDrag, onPanEnd: brain.onRelease,
      onTapDown: (d) => brain.onPoke(d.localPosition),
      child: CustomPaint(size: size, painter: PetPainter(rig, species, coat, stage)),
    ),
  );
}

class PetPainter extends CustomPainter {
  PetPainter(this.rig, this.species, this.coat, this.stage) : super(repaint: rig);
  final PetRig rig; ...
  @override
  bool shouldRepaint(PetPainter old) =>          // só a configuração ESTÁTICA
      old.species != species || old.coat != coat || old.stage != stage;
}
```

Por que assim:

- **Repintar sem rebuild.** [Fato] Passar um `Listenable` em `repaint:` é
  "a forma mais eficiente de disparar repaint" e evita as fases de build e
  layout ([CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)).
  O `shouldRepaint` deixa de comparar 20 campos de pose, porque a pose chega
  pelo `rig`.
- **Um relógio só.** [Fato] O callback do `Ticker` recebe o tempo decorrido
  desde o início ([TickerCallback](https://api.flutter.dev/flutter/scheduler/TickerCallback.html)),
  e o `TickerProviderStateMixin` silencia o ticker quando o `TickerMode`
  desliga a subárvore ([Ticker](https://api.flutter.dev/flutter/scheduler/Ticker-class.html)).
  Com isso, o bicho fora da tela não gasta CPU. Molas, ruído, piscar e
  cérebro avançam no mesmo `dt`, e os 10 `AnimationController` e os 4
  `Timer` de `pet.dart` somem.
- **Isolar a repintura.** [Fato] O `RepaintBoundary` ajuda quando a
  subárvore repinta em momentos diferentes do resto
  ([RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)).
  O habitat e a interface não repintam a 60 Hz por causa do bicho.
- **Orçamento.** [Fato] Em 60 Hz há 16 ms por quadro (~8 ms de build e ~8
  ms de raster), e em 120 Hz menos de 8 ms no total. `saveLayer`, `Opacity`
  e clip em animação são caros: prefira cor semitransparente
  ([Flutter performance](https://docs.flutter.dev/perf/best-practices)).
  Por isso o crossfade de rosto deve virar alfa na cor de cada traço, não
  `Opacity`.
- **Paths e Paints pré-calculados** [Opinião]:
  - geometria estática por espécie e estágio, montada uma vez;
  - no `paint`, só `canvas.save/translate/rotate/scale/restore` por peça
    (cabeça, orelhas, segmentos da cauda);
  - só o contorno-gelatina e a boca reconstroem `Path` a cada quadro, sempre
    com `path.reset()` num objeto reaproveitado;
  - `Paint` reaproveitados e nenhuma alocação de lista dentro de `paint`.
- **Movimento reduzido.** Multiplique as amplitudes de ruído e de exagero
  por ~0,3, mantendo as reações. [App] O código já faz esse raciocínio
  (`AnimationBehavior.preserve`, `pet.dart:432-437`).
- **Testabilidade.** O motor é puro: recebe `dt` e devolve números.
  Semente fixa e `dt` fixo tornam os testes de ouro determinísticos. [App]
  `MotorDeVida(semente:)` já permite isso.

### 5.3 Ordem de migração sugerida [Opinião]

1. Ligar `CustomPaint(painter: …, repaint: rig)` ao `_quadroDaVida` que já
   existe e reduzir o `shouldRepaint`.
2. Trocar `_pisca` e `_proximoPiscar` (Timer) pelo `BlinkScheduler` dentro
   do motor, com os ganchos de olhar e afago.
3. Trocar `_orelha` e `_toque` por molas com `kick()`: orelhas com f 4 e
   ζ 0,25, e squash com f 3,4 e ζ 0,3.
4. Transformar `_cauda` na cadeia de 4–5 segmentos.
5. Fazer o humor contínuo (pesos amortecidos) e aposentar `_transicao`.
6. Levar os gestos (`_gesto`) para o `IdleScheduler`, com baldes, espera e
   inércia, como alvos para as molas e não como curvas `sin(gestoT·π·k)`.
7. Fazer a gelatina do contorno e o pêndulo no colo.

---

## Fontes

- Thomas & Johnston, 12 princípios: <https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation>
- t3ssel8r (via `spring_motion`): <https://docs.rs/spring_motion/latest/src/spring_motion/lib.rs.html> · gists: <https://gist.github.com/Andicraft/ab605dda924a0321e755abf8f573ebd7>, <https://gist.github.com/ttalexander2/3b8743bf2d38d40a017e807aab43c016>
- Ryan Juckett, Damped Springs: <https://www.ryanjuckett.com/damped-springs/>
- Daniel Holden, Spring-It-On: <https://theorangeduck.com/page/spring-roll-call>
- Bollo, Inertialization (GDC 2018): <https://www.gdcvault.com/play/1025165/Inertialization>
- Overshoot × ζ: <https://pressbooks.library.torontomu.ca/controlsystems/?p=781>
- Apple WWDC 2018, Designing Fluid Interfaces: <https://developer.apple.com/videos/play/wwdc2018/803/>
- Material motion: <https://m1.material.io/motion/duration-easing.html>
- gameanim (antecipação): <https://www.gameanim.com/?p=115> · Trico: <https://www.gameanim.com/?p=15474>
- Juice it or lose it: <https://rpgplayground.com/research-making-a-juicy-game/>
- Perlin 1995: <https://ieeexplore.ieee.org/document/468392> · Improv: <https://mrl.cs.nyu.edu/projects/improv/>
- Book of Shaders, ruído e fBm: <https://thebookofshaders.com/11/>, <https://thebookofshaders.com/13/>
- Screen shake por ruído (Eiserloh): <https://bevy.org/examples/camera/2d-screen-shake/>
- Jakobsen, Advanced Character Physics: <https://www.gamedeveloper.com/programming/advanced-character-physics>
- Pêndulo: <https://en.wikipedia.org/wiki/Pendulum_(mechanics)>
- Sacadas, Harwood 1999: <https://pmc.ncbi.nlm.nih.gov/articles/PMC6782780> · Fixação na leitura: <https://sk.sagepub.com/ency/edvol/embed/encyclopedia-of-the-mind/chpt/eye-movements-during-reading> · Eyes Alive: <https://www.cis.upenn.edu/~badler/papers/EyesAlive.pdf>
- Olho-cabeça: <https://www.microsoft.com/en-us/research/?p=557628>, <https://ilab.usc.edu/publications/Itti_etal03spienn.html>
- Piscar: <https://medrxiv.org/content/10.1101/2022.11.19.22282503.full.pdf>, <https://www.aboonline.org.br/details/1706/en-US>, <https://arxiv.org/pdf/2211.05541>, <https://pmc.ncbi.nlm.nih.gov/articles/PMC8962689>
- Piscada lenta em gatos: <https://researchportal.port.ac.uk/en/publications/the-role-of-cat-eye-narrowing-movements-in-cat-human-communicatio/>
- Respiração de cães e gatos: <https://vcahospitals.com/know-your-pet/home-breathing-rate-evaluation>
- GoodGood em Rive: <https://withloveapp.substack.com/p/procedural-animation-in-rive-how?r=535ifv>
- Duolingo: <https://blog.duolingo.com/world-character-visemes> · Lily: <https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life>
- Rive: <https://rive.app/docs/editor/state-machine/layers>, <https://rive.app/docs/editor/state-machine/transitions>, <https://rive.app/community/forums/bugs/fsLjspgTHYcR/randomized-animations-in-parent-groups/ftkc674yHQY8>
- Utilidade, baldes, inércia: <http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter09_An_Introduction_to_Utility_Theory.pdf>
- Aditivo: <https://docs.unrealengine.com/udk/Three/AdditiveAnimations.html>
- Squash e volume: <https://download.autodesk.com/us/3DSmax/2012help/files/GUID-D51970C6-5F52-4C52-8CA8-55FDBEB7A03-289.htm>, <https://patents.google.com/patent/US7221380>
- Soft body: <https://gamedeveloper.com/programming/deep-dive-the-soft-body-physics-of-jelly-car-explained>, <https://cg.informatik.uni-freiburg.de/publications/2005_SIGGRAPH_deformationShapeMatching.pdf>
- Rubber band: <https://unity.bluecadet.com/spring/rubberband/>
- Flutter: <https://api.flutter.dev/flutter/rendering/CustomPainter-class.html>, <https://docs.flutter.dev/perf/best-practices>, <https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html>, <https://api.flutter.dev/flutter/scheduler/TickerCallback.html>, <https://api.flutter.dev/flutter/physics/SpringDescription-class.html>

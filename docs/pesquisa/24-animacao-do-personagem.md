# 24 — Por que a animação do bicho ainda parece ruim

Pedido: "As animações continuam uma merda, sério, um lixo. Pesquise mais
sobre isso."

## O que a filmagem mostrou (30 quadros por segundo, quadro a quadro)

Filmamos o bicho no mundo da home a 30 qps e olhamos sequências de 1 s.
Os problemas aparecem sem precisar de opinião:

1. **Ele anda como um adesivo arrastado.** O desenho é de frente para a
   câmera, e para ir de um lado a outro ele desliza de lado.
   - As patas oscilavam ±3 unidades na horizontal, num corpo de 120: elas
     deslizavam, em vez de levantar.
   - O corpo subia 3 unidades, sem rolar de um lado para o outro.
   - A cadência era de ~6 passos por segundo: um tremor, não um andar.
2. **Ele andava para um lado olhando para o outro.** Indo para a esquerda,
   o desenho é espelhado, mas o olhar e a virada do rosto vinham do motor
   no sentido da cena e não desfaziam o espelho.
3. **A virada do rosto era pequena demais para ler.** O rosto deslizava 6,5
   unidades dentro de uma cabeça de ~90: não chegava a parecer três quartos.
4. **Parado, quase nada muda em 1 s**, e quando muda é um pulinho vertical.
   Isso está certo em parte (pausa é necessária), mas as poses do repouso
   não têm silhueta clara.

## O que as fontes dizem

- **Duolingo (Rive).**
  - Cabeça e corpo são artboards aninhados que se movem independentes.
  - 8 animações de cabeça × 8 de corpo combinam em mais de 64 variações
    de neutro.
  - A State Machine mistura essas animações em tempo real.
  - Tem contenção ("exaggerated expressions felt off") e economia de
    movimento, citando Chuck Jones.
  - O rosto é feito de camadas (olhos, sobrancelhas, boca) e as expressões
    nascem da combinação.
  - Fontes:
    - <https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life>
    - <https://blog.duolingo.com/world-character-visemes>
- **Rosen, "An Indie Approach to Procedural Animation" (GDC 2014).**
  - Animação fluida e interativa a partir de pouquíssimas poses-chave,
    interpoladas por código. Relatos falam em 13 poses para tudo, e em
    2 poses para a corrida.
  - O ponto do talk: animação e código trabalhando juntos.
  - Fontes:
    - <https://gdcvault.com/play/1020049/Animation-Bootcamp-An-Indie-Approach>
    - <https://discussions.unity.com/t/an-indie-approach-to-procedural-animation-gdc-video-talk/538228>
- **Little Polygon, locomoção procedural.**
  - A partir das poses de Richard Williams: inclinar para começar a cair,
    contato, passagem, repete.
  - O quadril sobe e desce numa senoide e rola a meia frequência.
  - O passo é atado à velocidade real, e não ao comando.
  - Tudo é suavizado com mola: resposta seca parece mecânica.
  - Fonte: <https://blog.littlepolygon.com/posts/loco1/>
- **Rain World (GDC 2016).** As criaturas são várias peças puxadas por
  algoritmos em tempo real, e a animação está ligada à IA de locomoção.
  - Fonte: <https://gamedeveloper.com/art/video-animating-i-rain-world-i-and-its-many-squishy-stretchy-creatures>
- **Klei (Don't Starve).** Animação 2D por símbolos e trocas de desenho,
  sem ossos, pela rapidez e pelo controle.
  - Fonte: <https://gdcvault.com/play/1020165/2D-Animation-at-Klei>
- **O que denuncia o procedural duro** (fontes secundárias, consistentes
  entre si):
  - simetria e tempo uniforme;
  - membros idênticos;
  - falta de peso (o corpo não pende para a direção nem cede no contato);
  - o caminho é misturar poses desenhadas com camadas procedurais por
    cima.

## O que muda (primeira rodada)

- **Caminhada de quem anda de frente: o gingado.**
  - O corpo rola ±5° por cima do pé que está no chão, girando por ele e
    não pelo meio.
  - A pata livre levanta 11 unidades num arco e vai um pouco à frente.
  - O corpo sobe na passagem e cede no contato.
  - Ele pende para onde vai.
  - A cadência caiu para ~2,4 passos por segundo (um ciclo a cada 36
    unidades).
  - O passo entra e sai suave.
- **A cara vai para onde ele vai.**
  - Andando, a virada soma 0,7 no sentido do passo.
  - O rosto desliza 8,5 em vez de 6,5, e o contorno da cabeça 3,2 em vez
    de 2,2.
  - O espelho é desfeito no olhar e na virada.

## O limite honesto

O nível do Duolingo vem de animadores desenhando poses e transições no
Rive. O bicho do Baru é desenhado por código, em Canvas, de frente. Dá para
melhorar muito o movimento: passo, peso, virada, poses de repouso com
silhueta clara. Mas poses desenhadas à mão por um animador numa ferramenta
como o Rive são outro patamar, e esse trabalho não sai de código.

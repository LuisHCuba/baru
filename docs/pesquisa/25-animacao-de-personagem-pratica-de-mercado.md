# 25 — Animação de personagem: o que o mercado faz

Pedido: "Refaz a pesquisa e traz as boas práticas de mercado."

## O que eu fiz, e por que estava errado

Foram três tentativas, todas fora da prática de mercado:

1. **Formas geométricas no código.**
   - O bicho é desenhado por código e "animado" esticando, achatando e trocando medidas.
   - Resultado: deformação, boneco de papel.
2. **Poses de código para em pé e deitado.**
   - Juntava uma cabeça de frente com um corpo em três quartos.
   - O resultado era anatomia incoerente.
3. **Ilustração gerada por IA, vetorizada e trocada inteira de pose em pose.**
   - O recorte automático deixa borda e restos visíveis.
   - O andar tem dois quadros.
   - Nada no corpo se move entre uma pose e outra.

As três sofrem do mesmo problema: o personagem não tem um **rig** (esqueleto e partes separadas). Sem rig não há movimento contínuo, só deformação (1 e 2) ou troca de figura (3).

## Como o mercado faz

### Rig: personagem em partes, com ossos e malha

Para personagem 2D interativo, o padrão é o mesmo nas ferramentas usadas pela indústria (Rive, Spine, Unity 2D Animation):

- A arte é desenhada **em camadas separadas**: cabeça, olhos, boca, orelhas, tronco, cada perna, rabo.
- As camadas são presas a **ossos**.
- Onde precisa curvar (barriga, pescoço, rabo), a imagem vira **malha com pesos**. O osso deforma a malha de forma suave, sem esticar o desenho todo.
  - O Spine liga ossos à malha por "linear blend skinning", que ele chama de *weights* ([Spine, fórum](https://ja.esotericsoftware.com/forum/d/7673-best-practices-for-rigging-mesh-joints)).
  - O Rive prende vértices e alças de curva a ossos, e usa malhas para "deformações naturais e orgânicas" de imagens ([Rive docs, Bone tips](https://rive.app/docs/editor/manipulating-shapes/bone-tips.md); [Rive docs, Manipulating shapes](https://rive.app/docs/editor/manipulating-shapes/manipulating-shapes)).
  - A Unity documenta o mesmo fluxo: *rig*, *skinning*, *weights* ([Unity 2D Animation, Character rigging](https://docs.unity3d.com/Packages/com.unity.2d.animation@4.0/manual/CharacterRig.html)).
- **Boas práticas citadas por animadores:**
  - separar bem as camadas;
  - montar a malha já pensando na deformação;
  - mover vértices por ossos, e não um a um (senão cada vértice vira uma linha do tempo);
  - adensar a malha nas articulações;
  - mudança grande na arte quebra o rig.
  - Fontes: [G5 Games / Medium](https://medium.com/g5careers/spine-animation-optimization-save-your-nerves-and-time-by-avoiding-bugs-2cda96d27c8e), [Unity 2D bone deformation](https://bugnet.io/blog/fix-unity-2d-animation-rig-bone-deformation-twist).

### Máquina de estados: o código só diz o estado

- O app não anima: ele **troca o estado** (parado, andando, comendo, dormindo, feliz) e a máquina de estados do arquivo de animação faz a transição misturada.
- **Duolingo, personagem Lily (no Rive):**
  - cabeça e corpo são *artboards* aninhados que se movem independentes;
  - a máquina de estados comanda boca, expressões, câmera "e todas as outras animações";
  - 8 animações de cabeça × 8 de corpo dão mais de 64 variações de parado;
  - o arquivo final tem menos de 1 MB;
  - animar cada reação à mão "deixaria o arquivo grande demais";
  - os animadores fazem as peças, e criativos-técnicos otimizam o arquivo.
  - Fonte: [Rive, case Duolingo](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life).
- **Duolingo, bocas:** mais de 20 formatos de boca, com estados separados para pose de aula e para boca ([Duolingo blog, visemes](https://blog.duolingo.com/world-character-visemes)).
- **Arquitetura:** a Very Good Ventures descreve o ganho de separar a lógica da animação do código. O designer itera nos estados sem mexer no Flutter ([VGV](https://verygood.ventures/blog/rive-flutter-genui-integration/)).

### Variação de parado

- Bicho parado precisa de micromovimento: "movimento pequeno lê como vivo; nenhum movimento lê como quebrado" ([Wayline, sprite animation](https://www.wayline.io/learn/sprite-animation/2)).
- A variedade vem de:
  - piscar aleatório em camada por cima de qualquer animação ([Spine, fórum de pet virtual](https://esotericsoftware.com/forum/d/8716-updated-virtual-pet-animations));
  - "quebras de parado" ocasionais;
  - combinação de peças, como no caso Lily acima.

### Onde cada ferramenta entra

| Ferramenta | Para quê | Flutter |
|---|---|---|
| **Rive** | Personagem interativo com estados (o caso do Baru) | Runtime oficial `rive`, com entradas de estado booleanas, numéricas e de gatilho ([Rive docs, inputs](https://rive.app/docs/runtimes/flutter/inputs)) |
| **Spine** | Animação esqueletal de jogo, o especialista em 2D | Runtime oficial `spine_flutter` (FFI sobre spine-cpp) ([Esoteric](https://eu.esotericsoftware.com/spine-flutter)) |
| **Lottie** | Animação de tocar uma vez (ícone, celebração) | Fraco para personagem com estados ([comparativos](https://toolradar.com/compare/lottie-vs-rive)) |
| **Quadro a quadro** | Pixel art, ou estúdio com animador desenhando cada quadro (a Klei usa símbolos trocados, feitos à mão, no Flash) | [GDC 2017, Klei](https://gamedeveloper.com/art/video-doing-2d-game-animation-the-klei-way) |

### IA generativa na animação

- Gerar quadros de animação por IA tem um problema conhecido: modelos de imagem "não têm mecanismo para garantir consistência entre saídas sequenciais" ([Sprite Sheet Diffusion, arXiv 2412.03685](https://arxiv.org/html/2412.03685)).
- Os próprios fornecedores dizem que consistência "é a parte difícil" ([Makko](https://blog.makko.ai/ai-game-art-generator/)).
- O uso maduro é **conceito e direção de arte**. A peça final animável sai de um ilustrador e de um animador.
- A minha terceira tentativa usou IA como peça final, e isso explica o recorte ruim e a falta de movimento.

## Custo de mercado (verificado em listagens, out. 2026)

- **Rive:**
  - editor e runtimes gratuitos;
  - exportar para produto comercial exige plano pago, a partir de cerca de US$ 9/mês;
  - não há taxa de runtime.
  - Fonte: [Rive, new pricing](https://rive.app/blog/new-pricing). Confirmar na página de preços.
- **Spine:**
  - Essential US$ 69, Professional US$ 379, pagamento único;
  - o runtime exige licença do editor;
  - vale para empresas com receita abaixo de US$ 500 mil por ano.
  - Fonte: [Esoteric, compra](https://esotericsoftware.com/spine-purchase).
- **Animador freelancer de Rive (personagem com rig e máquina de estados):**
  - US$ 300 (rápido, poucos estados);
  - US$ 1.200 (rig completo, 3 estados, máquina de estados, trecho de integração, 7 a 10 dias);
  - US$ 85/hora, com 15 a 30 horas por avatar de 3 a 4 estados.
  - Fontes: [Dribbble](https://dribbble.com/services/235858-Rive-Animation), [Contra](https://contra.com/s/YvUEsmgk-interactive-rive-characters-and-mascots), [Contra, hourly](https://contra.com/s/oBMELbER-rive-character-and-ai-avatar-rigging).
  - Os preços variam com o número de estados, revisões e se a arte já existe.

## Recomendação

1. **Ferramenta: Rive.**
   - É o padrão para mascote interativo em app (Duolingo).
   - Tem runtime oficial em Flutter, e a máquina de estados dele corresponde ao que o motor de vida do Baru já decide (anda, come, dorme, nada, humor).
   - O app passa a só mandar estados, como no caso Lily.
2. **Produção:** um ilustrador e animador de personagem faz, por bicho:
   - a arte em camadas, no estilo do Baru;
   - o rig com ossos e malha;
   - os estados: parado (com variações e piscar), andar, comer, deitar, dormir, nadar, feliz e triste.
   - Começar por **uma espécie** para validar o padrão antes das outras oito.
3. **O que eu faço do meu lado, sem depender da arte:**
   - o contrato de estados e entradas por espécie (nomes, tipos, quando cada um liga), para o animador montar a máquina de estados igual ao motor de vida;
   - a integração no Flutter com o runtime `rive`, um adaptador do motor de vida para as entradas, e o desenho atual como reserva enquanto o arquivo não existe;
   - o roteiro de teste: filmagem quadro a quadro e as medições de deformação e salto usadas nesta revisão, para aceitar ou recusar cada entrega.
4. **Não usar** IA como peça final de animação nem animar o corpo por deformação no código. As duas coisas já se provaram ruins aqui e não são o que o mercado faz.

## O que entrou no app (a técnica do Duolingo, nos nossos vetores)

Não há como abrir o editor do Rive daqui: ele exige alguém logado no site. O princípio que dá a fluidez, porém, é técnico e vale para qualquer desenho vetorial: **cada vértice do contorno preso a ossos com peso, e o contorno inteiro se curvando quando os ossos se movem.** Os bichos do Baru já são vetoriais, então o app passou a fazer isso com eles (`lib/widgets/vida/deformador.dart`):

- Cada contorno do corpo é amostrado em pontos.
- Cada ponto passa pelo campo de deformação dos "ossos" do quadro:
  - o tronco verga para onde ele vai, ou para onde olha;
  - a cintura incha no pouso e afina no ar;
  - o peito enche ao respirar;
  - o quadril balança no passo;
  - o lado da pata no ar sobe.
- O contorno é refeito por curvas que passam pelos pontos movidos.
- Detalhes pequenos (olho, narina) só acompanham o deslocamento, sem se dobrar: o olho segue redondo.
- Custo medido: cerca de 0,3 ms por quadro.

### Reações do corpo

O mesmo campo de deformação responde ao dedo e às emoções:

- **Toque:** o contorno afunda onde o dedo encosta e volta como borracha (mola com leve passada do ponto).
- **Dois toques seguidos:** susto — o corpo estica de uma vez e assenta, com um pulinho.
- **Afago:** a marca da mão acompanha o dedo enquanto ele passa e solta quando ele sai.
- **Comemoração:** pulos com estica no ar e achata no pouso, e o quadril balançando. Na tela de resultado ela abre a cena e se repete a cada 6,5 s. A festa interrompe o que o bicho estiver fazendo (comendo, pastando) e ele volta depois.
- Testes: `baru_app/test/reacoes_test.dart`.

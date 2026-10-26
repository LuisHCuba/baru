# Laudo 04: elementos sonoros do Baru

Outubro de 2026. Escopo: auditoria dos 7 sons atuais, pesquisa com fontes,
proposta de identidade sonora (incluindo voz por espécie, háptico casado e
ambiente opcional) e plano de produção (ElevenLabs e síntese local).

**Convenção de evidência** (exigida pelo BRIEF):

- **[F]**: fato com fonte, com link na seção 3 ou no próprio parágrafo.
- **[O]**: observação do app, com `arquivo:linha`, medição ou imagem.
- **[I]**: inferência ou opinião minha. Não é fato e precisa de validação.

**Aviso de método.** Medi os arquivos com numpy, scipy e ffmpeg (espectro em
janelas de 30 ms, envelope em 5 ms, loudness EBU R128). **Não ouvi nenhum
som**: este ambiente não tem saída de áudio. O próprio CHANGELOG admite que os
sons atuais também nunca foram ouvidos (`CHANGELOG.md:413`, "Eu não os ouvi").
Os protótipos de síntese da seção 5.3 foram gerados e medidos, mas também não
foram ouvidos. A primeira ação da produção é uma audição humana em aparelho
real (seção 5.6).

**Aviso de pesquisa.** O limite de buscas na web desta rodada acabou no meio da
pesquisa. Busquei **mas não achei**: entrevista ou artigo do Duolingo sobre a
identidade sonora deles, material sobre sons de UI do Finch e documentação da
Nintendo sobre sons de interface. Isso está dito em cada ponto. Nada foi
completado com memória apresentada como fato.

---

## 1. Resumo

O dono do produto disse que os sons são "pobres e sem sentido". As medições
confirmam o diagnóstico e mostram a causa:

1. **[O] Seis dos sete sons são dois senos puros somados**, quase sempre a
   fundamental e a oitava no **mesmo** volume (0 dB de diferença), com decaimento
   exponencial. Não existe timbre: são bipes afinados. O sétimo (`cavar`) é ruído
   branco filtrado com centroide em 6,3 kHz. Soa como chiado, não como terra.
2. **[O] A hierarquia está invertida.** O som do momento central do produto (fim
   da sessão de foco, `fim.wav`) é o 2º mais baixo do catálogo: −19,6 LUFS de
   pico momentâneo. O de nível (`conquista.wav`) está em −15,3 LUFS, e até o
   `cavar` (−18,1) soa mais alto que o fim da sessão.
3. **[O] Um som com três significados.** `conquista` toca no nível, no marco da
   trilha **e** na "saudação da chegada", que dispara todo dia
   (`app.dart:316-350`, `celebracao.dart:84`). O som de herói vira rotina.
4. **[O] Os sons não têm relação com o mundo do app.** O habitat é lago,
   madeira, pedra e folhas (imagem `play-store/telas/pt/01-home.png`; paleta
   "madeira/pedra/verde" em `docs/PRODUCT.md:181-196`). Nenhum som tem madeira,
   água, folha ou bicho. O bicho não tem voz.
5. **[O] Falha técnica séria no áudio.** O app toca tudo com o contexto padrão
   do `audioplayers`: `USAGE_MEDIA` + `AUDIOFOCUS_GAIN`
   (`audioplayers_platform_interface 7.1.1, audio_context.dart:93-98`). Pela
   documentação do Android, um pedido de foco `GAIN` de um app `USAGE_MEDIA`
   **faz o app que está tocando música baixar o volume até parar** (Android 12+).
   **[I]** Na prática, tocar no bicho, resgatar uma missão ou concluir uma sessão
   pode pausar o Spotify ou o podcast da pessoa. Para um app de foco isso é
   grave. O comentário do serviço diz que o contexto é "sonification" e que o
   modo silencioso é respeitado (`som_service.dart:11-13`), mas **nenhum
   contexto de áudio é configurado no código** (grep por `AudioContext` em `lib/`
   não retorna nada). O comentário está errado.

A proposta: uma identidade com **três materiais** (madeira afinada de
marimba/kalimba, água, folhas/terra) numa **única tonalidade** (Fá maior
pentatônica), um **motivo de três notas** que vira família (toque → missão →
sessão → nível), **voz própria para cada uma das 9 espécies** no estilo
Animalese, háptico composto alinhado às notas, e um ambiente opcional por
período do dia. A produção custa ~20 mil créditos de ElevenLabs (estimativa
pela tabela pública) mais a síntese local. A troca no app é M (média), e a
correção do foco de áudio é P e pode sair já.

---

## 2. Auditoria dos sons atuais

### 2.1 Ficha técnica (medida)

Todos os arquivos são WAV PCM 16 bits mono 44,1 kHz e somam 252 KB. Começam e
terminam em zero, sem clique. Sem clipping.

| Arquivo | Dur. | Conteúdo espectral (medido) | Notas | Pico | Máx. momentâneo | Ataque | Onde toca |
|---|---|---|---|---|---|---|---|
| `toque.wav` | 70 ms | 2 senos: 320 + 480 Hz, mesmo nível | ~E4−50 cents + ~A#4+50 cents (**fora de afinação**) | −10,9 dBFS | **−30,3 LUFS** | 5 ms | `pet.dart:591`, todo toque no bicho |
| `carinho.wav` | 300 ms | 2 pares de senos em oitava: 784+1568 → 1046+2093 Hz | G5 → C6 (quarta ascendente) | −10,7 | −20,4 | 85 ms | `state.dart:266`, afago completo |
| `resgate.wav` | 350 ms | 659+1318 → 880+1760 Hz | E5 → A5 (quarta ascendente) | −8,5 | −18,2 | 100 ms | `state.dart:425` e `:769`, missão e descanso resgatados |
| `cavar.wav` | 260 ms | Ruído de banda larga (planura 0,63), centroide 6,3 kHz, 4 grãos | sem altura | **−1,3** | −18,1 | 5 ms | `toca.dart:95`, gestos 1 e 2 da toca |
| `premio.wav` | 620 ms | Arpejo A4-C5-E5-A5 sustentado + varredura aguda no fim | **Lá menor** | −3,9 | −15,9 | 135 ms | `toca.dart:104`, a terra abrindo |
| `conquista.wav` | 560 ms | 524+1046 → 659+1318 → 784+1568 Hz | C5-E5-G5 (Dó maior, arpejo) | −7,5 | −15,3 | 5 ms | `celebracao.dart:84`: nível, marco **e chegada diária** |
| `fim.wav` | 550 ms | 587 + 881 Hz simultâneos, sem movimento | D5 + A5 (quinta vazia, estática) | −9,3 | −19,6 | 30 ms | `state.dart:1907`, sessão concluída |

O máximo momentâneo é o EBU R128 de janela de 400 ms, medido com
`ffmpeg ebur128` e 0,5 s de silêncio de enchimento. O integrado não serve para
sons de menos de 1 s.

O player toca tudo a `volume: 0.55`, ou seja −5,2 dB (`som_service.dart:171`).

### 2.2 Som por som

**`toque`: toque no bicho (o mais frequente).**
- [O] Dois senos de 70 ms a 320 e 480 Hz, meio semitom fora de qualquer nota da
  escala dos outros sons, que são pentatônicos em Dó. É o único som fora da
  afinação do conjunto.
- [O] Está 15 dB abaixo do `conquista` e no limite do audível no alto-falante
  do celular. Abaixo de ~300 Hz o alto-falante de celular perde muita energia
  **[I]**. Com só 70 ms e fundamental em 320 Hz, ele tende a virar um "tic" sem
  corpo.
- [O] É o mesmo som para as 9 espécies. A tartaruga e a lontra respondem igual.
- [O] O háptico dispara em todo toque (`pet.dart:586-590`), mas o som passa
  pelo limitador global de 400 ms (`som_service.dart:93`). Quem toca rápido
  sente vibração sem som em parte dos toques. **[F]** O Android diz que háptico
  fora de sincronia com o som "can be a bit unsettling" ([haptics
  principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)).
- Problema central: **não é o bicho**. Tocar num animal deveria soar como ele
  respondendo.

**`carinho`: afago completo.**
- [O] Duas notas agudas (G5→C6) com a oitava em mesmo nível. Fica um "plim"
  eletrônico de campainha.
- [O] Durante o afago só há `selectionClick` por distância (`pet.dart:647-654`),
  chamado de "ronrom" no código. O ronrom é só tátil: não existe som de
  ronronar, que seria o som mais óbvio e mais querido do evento.

**`resgate`: missão resgatada.**
- [O] E5→A5, quarta ascendente, 350 ms. Correto como direção (sobe = positivo),
  mas é estruturalmente igual ao `carinho` (quarta ascendente, dois senos em
  oitava). Dois eventos diferentes, mesmo gesto.
- [O] Na toca, ele toca 720 ms depois do `premio` (`toca.dart:61-64` e
  `missoes_screen.dart:663`). São dois sons diferentes para um único evento, em
  tonalidades diferentes (Lá menor → Mi-Lá).

**`cavar`: gesto de cavar.**
- [O] Ruído branco quase sem graves (só 10,6% da energia abaixo de 200 Hz e
  13,5% acima de 5 kHz). Terra úmida tem corpo grave e pouco chiado **[I]**. O
  pico de −1,3 dBFS é o mais alto do catálogo: no alto-falante vai soar mais
  áspero que todo o resto.
- [O] O mesmo arquivo toca 2 vezes seguidas, sem variação (`toca.dart:95`).

**`premio`: a terra abre.**
- [O] Arpejo de **Lá menor** (A-C-E-A). Para "achei um prêmio", menor é a
  escolha de cor emocional menos óbvia. **[I]** A convenção é associar menor a
  mistério ou tristeza. Não achei fonte formal para isso nesta rodada, então
  trate como convenção de ofício, não como fato.
- [O] Termina com uma varredura senoidal até ~4 kHz (visível no espectrograma).
  Parece efeito de sintetizador, sem relação com terra abrindo.

**`conquista`: nível, marco e chegada.**
- [O] Arpejo de Dó maior em senos. É o único som "de herói" e é usado para três
  coisas: nível, marco da trilha e "bom te ver" diário (`app.dart:331-337`, sem
  `precisaCavar`, então chama `_explode()` que toca `conquista`).
- [F] O Material diz que hero sounds "occur infrequently" e devem ser aplicados
  de forma consistente ([Material: Applying sound to
  UI](https://m2.material.io/design/sound/applying-sound-to-ui.html)). Tocar o
  som de nível todo dia ao abrir o app gasta o som de herói.
- [O] `anunciaCelebracao()` (`state.dart:219-221`) também toca `conquista` e não
  tem chamadores. É código morto, já apontado como B13 no relatório de agosto.

**`fim`: sessão concluída (o coração do loop).**
- [O] Ré e Lá **ao mesmo tempo**, sem movimento melódico, 550 ms, decaimento
  linear em dB. Uma quinta vazia e parada soa como um "dong" neutro de aviso. Não
  é celebração.
- [O] É 4,3 dB mais baixo que o `conquista` e mais baixo que o `cavar`.
- [O] A sessão também agenda uma notificação "sessão concluída" no canal de
  lembretes (`notification_service.dart:597-600`). Esse canal usa o **som padrão
  do sistema**, porque `canalLembretes` é criado sem `sound`
  (`notification_service.dart:249-255`). **[I]** No primeiro plano tocam dois
  sons sem relação entre si, o "ding" do sistema e o `fim`. Em segundo plano, se
  o isolate Dart ainda estiver vivo, o `fim` toca por cima do app em que a
  pessoa está.

### 2.3 Problemas sistêmicos

| # | Problema | Evidência | Gravidade |
|---|---|---|---|
| S1 | **Foco de áudio rouba a música da pessoa** | [O] Nenhum `AudioContext` em `lib/`. Padrão do plugin: `usageType = media`, `audioFocus = gain` (`audio_context.dart:93-98`). Cada `play` chama `requestAudioFocus` (`WrappedPlayer.kt:211-224`, `FocusManager.kt:36-46`). [F] Com `USAGE_MEDIA`/`USAGE_GAME` + `AUDIOFOCUS_GAIN`, "the system forces the playing app to fade out" ([audio focus](https://developer.android.com/media/optimize/audio-focus)) | **Crítica** ([I] a confirmar em aparelho com Spotify tocando) |
| S2 | **Modo silencioso não é respeitado** | [O] `USAGE_MEDIA` toca no volume de mídia, que o modo silencioso do toque não zera. O comentário de `som_service.dart:11-13` afirma o contrário | Alta |
| S3 | Sem timbre: senos puros | [O] Planura espectral 0,002–0,004 em 6 de 7 arquivos, só 2 parciais | Alta |
| S4 | Hierarquia de volume invertida | [O] Fim −19,6, conquista −15,3, toque −30,3 LUFS-M. [F] O Material pede volume consistente por nível de hierarquia ([choreography](https://m2.material.io/design/sound/sound-choreography.html)) | Alta |
| S5 | Tonalidades soltas | [O] Dó maior (conquista), Lá menor (premio), Ré-Lá (fim), Mi-Lá (resgate), toque fora de afinação. [F] "Don't create earcons with unrelated key signatures" ([choreography](https://m2.material.io/design/sound/sound-choreography.html)) | Média |
| S6 | Zero variação (repetição idêntica) | [O] 1 arquivo por evento, sem variação de altura ou volume. [F] Material e Apple recomendam variar sons repetidos ([choreography](https://m2.material.io/design/sound/sound-choreography.html); [Apple: Playing audio](https://developer.apple.com/design/human-interface-guidelines/playing-audio)) | Média |
| S7 | Um player para tudo e limitador global de 400 ms | [O] `_player ??= AudioPlayer()` único (`som_service.dart:168`). Trocar a fonte do mesmo player interrompe o som anterior (leitura do plugin, `WrappedPlayer.kt:27-44`). O limitador engole sons legítimos. **[I]** Hipótese a testar: em `lowLatency` o SoundPool não emite fim de reprodução e `playing` pode ficar `true`, e um segundo `toque` seguido pode não tocar (`WrappedPlayer.kt:211-215`) | Média |
| S8 | Eventos importantes mudos | [O] Sessão iniciada, desistência, compra, item entrando no habitat, raiz crescendo, congelamento usado, folhas creditadas, contagem de XP, troca de humor, espécie liberada: nenhum tem som (`grep SomDoBaru lib/` só acha 9 chamadas, e todas usam os 7 sons acima) | Alta |
| S9 | Bicho sem voz | [O] Nenhum som por espécie. Os 5 humores (`models.dart:49`) e as falas (`l10n_humor.dart`) são mudos | Alta (é o pedido do dono) |
| S10 | Háptico genérico | [O] 11 chamadas `HapticFeedback.*`. [F] No Android o Flutter traduz `heavyImpact` para `CONTEXT_CLICK`, `mediumImpact` para `KEYBOARD_TAP`, `lightImpact` para `VIRTUAL_KEY` e `selectionClick` para `CLOCK_TICK` ([PlatformPlugin.java](https://github.com/flutter/flutter/blob/master/engine/src/flutter/shell/platform/android/io/flutter/plugin/platform/PlatformPlugin.java)). **[I]** "Heavy" vira um clique de contexto, que não é pesado | Média |
| S11 | Sem chave de vibração, só "Som" | [O] Ajustes tem apenas `setSom` (`l10n.dart:645`). [F] Apple: "Make haptics optional" ([Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)) | Baixa |
| S12 | Notificações com "ding" genérico do sistema | [O] `canalLembretes` sem som próprio (`notification_service.dart:249-255`) | Média |

---

## 3. Pesquisa (fontes)

### 3.1 Material Design: o guia de som mais completo que achei

O Material 2 ainda está publicado e tem uma seção inteira de som. É a base
normativa deste laudo.

- [F] **Três princípios**: o som deve ser *informative*, *honest* ("an authentic
  representation of the product's brand identity") e *reassuring* ("only calling
  for action when needed") ([About
  sound](https://m2.material.io/design/sound/about-sound.html)).
- [F] **Hierarquia** com 5 níveis: 1 brand sounds (mnemônico), 2 hero sounds,
  3 alertas/notificações, 4 sons primários de UX, 5 sons secundários. "Sounds
  that follow or precede one another should have related attributes (like timbre,
  melody, or envelope)" ([Sound
  choreography](https://m2.material.io/design/sound/sound-choreography.html)).
- [F] **Hero sounds** celebram "a significant positive action", recebem o
  usuário e confirmam "a key moment of a product's purpose". Devem ser
  infrequentes e consistentes ([Applying sound to
  UI](https://m2.material.io/design/sound/applying-sound-to-ui.html)).
- [F] **Quando não usar som**: em ações frequentes, em UIs que pedem discrição e
  para quem pediu para não ser interrompido. "Building silence into a UI design
  is just as important as knowing when to apply sound" (mesma página).
- [F] **Fadiga**: "Limit the frequency of decorative sound to reduce user fatigue
  of the sound" (mesma página).
- [F] **Sons primários** (navegação, seleção): "should be suitable for being
  played often (without feeling annoying or redundant)" (mesma página).
- [F] **Tonalidade comum**: "Sounds that are played in close proximity to one
  another should use the same or complementary key signatures" ([Sound
  choreography](https://m2.material.io/design/sound/sound-choreography.html)).
- [F] **Variação**: "These interactions should include minor variations in sound
  timbre, to mimic the variance of sounds in real-world experiences" (mesma
  página).
- [F] **Motivos**: "Upward motion commonly indicates starting, openness,
  positivity, or assurance. Downward motion commonly indicates ending or
  closedness. Repetition commonly indicates thinking, waiting, or lack of
  progress" ([Sound
  attributes](https://m2.material.io/design/sound/sound-attributes.html)).
- [F] **Tonal × atonal**: "Tonal sounds work best to communicate personality,
  emotion, and state changes, whereas atonal sounds better support motion
  transitions and express a sense of haptic feedback" (mesma página).
- [F] **Timbre**: "Use softer, quieter timbres for low-priority sounds". Timbres
  brilhantes "feel more rich and playful" (mesma página).
- [F] **Envelope**: "A softer attack is more ambient. A sharper attack is more
  energetic". "A short decay feels small and fast. A longer decay feels large and
  slow" (mesma página).
- [F] **Loudness**: "Sounds should play at a consistent level of loudness
  depending on their position in the sound hierarchy". Meça a loudness
  percebida, não o pico ([Sound
  choreography](https://m2.material.io/design/sound/sound-choreography.html)).
- [F] **Estados opostos** (liga/desliga) usam o mesmo motivo em direção oposta
  (mesma página).
- [F] **Ambiente**: "should provide atmosphere and not detract the user from
  performing a task". Pode mudar de tom para indicar mudança de estado
  ([Applying sound to
  UI](https://m2.material.io/design/sound/applying-sound-to-ui.html)).

### 3.2 Apple Human Interface Guidelines (áudio e háptico)

- [F] Modo silencioso: as pessoas "also want to silence nonessential sounds, such
  as keyboard clicks, sound effects, game soundtracks" ([Playing
  audio](https://developer.apple.com/design/human-interface-guidelines/playing-audio)).
  Para "sound isn't essential, and it doesn't silence other audio", a Apple
  indica a categoria que "responds to the silence switch. Mixes with other
  sounds". É exatamente o caso do Baru.
- [F] Variação: "Consider varying sounds that people could perceive as
  repetitive over time… the system subtly varies the pitch and volume of the
  virtual keyboard's sounds… randomize a sound file's pitch" (mesma página).
- [F] "Avoid communicating important information using only sound" (mesma
  página).
- [F] Háptico: "Use haptics consistently", "Prefer using haptics to complement
  other feedback… match the intensity and sharpness of a haptic with the
  intensity and sharpness of the animation", "Avoid overusing haptics", "Make
  haptics optional" ([Playing
  haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)).

### 3.3 Android: foco de áudio, atributos e háptico

- [F] **Foco**: peça `AUDIOFOCUS_GAIN` só quando for tocar "for the foreseeable
  future (for example, when playing music)". Use
  `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` para áudio curto e intermitente. No
  Android 12+, um app `USAGE_MEDIA`/`USAGE_GAME` que pede `GAIN` faz o app que
  estava tocando sumir em fade-out ([Manage audio
  focus](https://developer.android.com/media/optimize/audio-focus)).
- [F] O `audioplayers` documenta `assistanceSonification` como "Usage value to
  use when the usage is sonification, such as with user interface sounds", e
  oferece `AndroidAudioFocus.none`
  (`audioplayers_platform_interface-7.1.1/lib/src/api/audio_context.dart:371-376,
  408`). Também oferece `AudioPlayer.global.setAudioContext`
  (`audioplayers-6.7.1/lib/src/global_audio_scope.dart:50`).
- [F] **Háptico, princípios**: "Given the choice of buzzy haptics or no haptics
  for touch feedback, choose no haptics". Evite `createOneShot` e
  `vibrate(long)` para feedback. "If your action is covered by a predefined action
  present in HapticFeedbackConstants, use that constant". "We strongly recommend
  co-design of visual, audio, and haptic effects". Háptico fora de sincronia
  "can be a bit unsettling to the user" ([Haptics design
  principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)).
- [F] **Constantes e nível de API** ([HapticFeedbackConstants](https://developer.android.com/reference/android/view/HapticFeedbackConstants)):
  `CONFIRM` 30, `REJECT` 30, `GESTURE_START`/`GESTURE_END` 30,
  `SEGMENT_TICK`/`SEGMENT_FREQUENT_TICK` 34, `TOGGLE_ON`/`TOGGLE_OFF` 34,
  `DRAG_START` 34, `CLOCK_TICK` 21, `CONTEXT_CLICK` 23, `KEYBOARD_TAP` 8,
  `VIRTUAL_KEY` 5, `LONG_PRESS` 3.
- [F] **Composições** (`VibrationEffect.startComposition().addPrimitive(...)`):
  sequência de primitivas com escala de intensidade e atraso. Confira suporte com
  `vibrator.areAllPrimitivesSupported(...)` e caia num efeito predefinido quando
  não houver ([Custom haptic
  effects](https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects)).
  A página mostra `PRIMITIVE_SLOW_RISE`, `CLICK`, `SPIN`, `THUD` e `LOW_TICK`.
  **[I]** O nível de API de cada primitiva (`LOW_TICK`, `THUD` e `SPIN` são mais
  novas que `CLICK`/`TICK`) precisa ser conferido na referência antes de
  codificar.
- [F] Mapeamento do Flutter no Android: `SUCCESS_NOTIFICATION` → `CONFIRM`,
  `ERROR_NOTIFICATION` → `REJECT`, ambos só no API 30+
  ([PlatformPlugin.java](https://github.com/flutter/flutter/blob/master/engine/src/flutter/shell/platform/android/io/flutter/plugin/platform/PlatformPlugin.java)).

### 3.4 Duolingo: o que achei e o que não achei

- **Não achei** entrevista ou artigo do Duolingo sobre a identidade sonora
  (como os sons de acerto e erro foram desenhados, quem desenhou, princípios).
  Busquei no blog de design e no hub de música do próprio Duolingo
  ([design hub](https://blog.duolingo.com/hub/design/)) e não há texto sobre som.
  Qualquer afirmação sobre "o que o Duolingo pensa do som" seria inventada.
- [F] Cada personagem do Duolingo tem **voz individual**, e a boca é animada em
  sincronia com a fala por *visemes* num state machine do Rive, que roda junto
  dos estados de animação ociosa ([How Duolingo Animates Its World
  Characters](https://blog.duolingo.com/world-character-visemes/)). Lição para o
  Baru: personagem com voz própria, e a animação reage ao som no mesmo instante.
- [F] Análise de terceiros: no erro, o Duolingo toca "a deflated, descending
  tone… the audio equivalent of a gentle head shake" ([Out of
  Scope](https://out-of-scope-product.beehiiv.com/p/duolingo-has-it-venmo-has-it-even-slack-has-it-your-product-doesn-t)).
  **[I]** O Baru não tem "erro". A desistência pode usar o gesto descendente,
  mas **sem o "deflated"**: notas resolvidas, sem detune, sem cair de altura
  (regra 1 do contrato, sem culpa).
- O relatório de agosto (`docs/RELATORIO_UX_DUOLINGO.md:36-42, 223-235`) já
  registrou o fim de lição do Duolingo como uma sequência de telas, "cada uma com
  som". Não repito aqui. A seção 4.6 aplica isso ao som: **cada degrau da
  sequência tem seu earcon**, e todos são da mesma família.

### 3.5 Animal Crossing, Animalese e Nintendo

- [F] O Animalese sintetiza cada letra da fala com o som básico da letra. A
  velocidade acompanha o texto. **O humor muda a altura** (feliz é mais agudo,
  triste ou bravo mais grave). Cada personalidade tem altura própria. Em New
  Horizons, a altura também depende da **espécie, ligada ao tamanho do corpo**:
  rato mais agudo que cabra, elefante mais grave ([Nookipedia:
  Animalese](https://nookipedia.com/wiki/Animalese)). É fonte de fã-wiki. A
  Nintendo não publicou a técnica.
- [F] A série é conhecida pela música que muda de hora em hora e pelo uso do
  relógio do console ([Wikipedia: Animal
  Crossing](https://en.wikipedia.org/wiki/Animal_Crossing)).
- [F] O diretor de som do Animal Crossing original (2001), de Wild World, City
  Folk e New Leaf é Kazumi Totaka ([Wikipedia: Kazumi
  Totaka](https://en.wikipedia.org/wiki/Kazumi_Totaka)). **Não achei** fonte
  primária sobre como os sons de UI foram desenhados.
- [F] Uma receita independente e documentada de "fala de bicho": loop curto de
  uma vogal gravada, **altura por personagem** (faixa de 7 semitons), **nova
  altura a cada palavra** com deslize de ~0,1 s, filtro de formantes dirigido
  pelas letras para dar vogais, e um vibrato leve ([Springbound Devlog 4: Making
  critters talk](https://brycetown.substack.com/p/springbound-devlog-4-making-critters-talk)).
  O autor relata que tocar chamados reais de animal "sounded random and
  inconsistent".
- **Finch: não achei** material público sobre o som do Finch. O site
  (finchcare.com) não devolveu conteúdo legível e a central de ajuda bloqueou o
  acesso.

### 3.6 Earcons, sonic branding, recompensa e fadiga

- [F] *Earcon* é "a brief, distinctive sound that represents a specific event".
  O termo foi cunhado por Sumikawa (1985). Earcons são sons sintetizados. Já
  *auditory icons* são sons gravados do cotidiano com o mesmo papel. O usuário
  precisa **aprender** a associação ([Wikipedia:
  Earcon](https://en.wikipedia.org/wiki/Earcon)).
- [F] Sonic branding: uma "sonic logo" que prepara o usuário. "Use distinct
  sounds for distinct priorities. If everything has the same sound, nothing has
  meaning" ([Out of
  Scope](https://out-of-scope-product.beehiiv.com/p/duolingo-has-it-venmo-has-it-even-slack-has-it-your-product-doesn-t)).
  É newsletter de produto, não pesquisa, e serve como reforço do que o Material
  já diz.
- Recompensa com altura ascendente: a fonte que tenho é o Material ("upward
  motion… positivity"). **Não achei** nesta rodada estudo que meça o efeito de
  acorde maior × menor em UI. Uso "maior = alegre" como convenção de ofício
  **[I]**.
- Fadiga por repetição: Material ("limit the frequency"), Apple ("randomize
  pitch") e Out of Scope ("Do they annoy people after the 10th time?"). Não achei
  número de quantas repetições geram fadiga, e por isso não cito nenhum.

### 3.7 Acessibilidade

- [F] WCAG 1.4.2: áudio automático de mais de 3 s precisa de controle para
  pausar ou ajustar volume, porque atrapalha quem usa leitor de tela ([WCAG
  Understanding 1.4.2](https://www.w3.org/WAI/WCAG22/Understanding/audio-control.html)).
  Isso vale para o ambiente proposto.
- [F] Leitores de tela (TalkBack, VoiceOver) usam earcons próprios para indicar
  tipo de elemento ([Wikipedia:
  Earcon](https://en.wikipedia.org/wiki/Earcon)). **[I]** Os sons do app não
  devem competir com os do TalkBack. Com TalkBack ativo, o Baru deve silenciar os
  sons de interface (nível 4 e 5) e manter só herói e voz.
- [F] Nada importante só por som (Apple, acima). No Baru todo som já acompanha
  um evento visual. A regra é manter assim.

### 3.8 ElevenLabs Sound Effects

- [F] O endpoint aceita `text`, `duration_seconds`, `prompt_influence`
  (0–1, padrão 0,3: "higher… follow the prompt more closely while also making
  generations less variable"), `loop` e `model_id`. O padrão é
  `eleven_text_to_sound_v2` e também existe `eleven_text_to_sound_v3` ([API
  reference](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert)).
- [F] Duração: a referência da API diz **0,5 a 30 s**, e a página de
  capacidades diz **0,1 a 30 s**. Custam **40 créditos por segundo** quando a
  duração é especificada. A saída é MP3, ou **WAV 48 kHz** para efeitos sem loop.
  O loop é desenhado "for seamless repeat playback" ([Sound
  effects](https://elevenlabs.io/docs/capabilities/sound-effects)). **[I]** Pela
  divergência, use ≥ 0,5 s e corte localmente.
- [O] O projeto já usou o ElevenLabs Sound Effects v2 no comercial
  (`play-store/video/audio.py:1-11`): `bicho-a/b.mp3` e `recompensa-a/b.mp3` em
  `play-store/video/assets/sfx/`. Existe precedente e conta.

---

## 4. Proposta: identidade sonora do Baru

### 4.1 Princípios (específicos do Baru)

1. **O mundo soa como ele parece.** Lago, doca de madeira, pedra, folhas e
   bicho (imagem `01-home.png`, paleta em `PRODUCT.md:181-196`). Todo som sai de
   três materiais: **madeira afinada**, **água** e **folha/terra**. Mais a voz do
   bicho.
2. **Uma tonalidade só: Fá maior pentatônica** (F, G, A, C, D). Qualquer
   combinação de notas da pentatônica soa bem junta [I, convenção musical]. Assim
   dois sons sobrepostos nunca brigam ([F] Material: mesma tonalidade).
3. **Um motivo, muitas formas.** O motivo do Baru é **Lá–Dó–Fá (A4–C5–F5)**, um
   arpejo ascendente de Fá maior. Toque usa 1 nota, missão usa 3 rápidas, sessão
   concluída usa o motivo completo com acorde, nível usa o motivo mais uma oitava.
   A pessoa aprende **um** gesto e reconhece a família ([F] earcons são
   aprendidos; Material pede relação entre "peer sounds").
4. **Silêncio é parte do desenho.** Durante a sessão de foco, nenhum som de
   app. Navegação e abas sem som, só háptico ([F] Material: ações frequentes sem
   som).
5. **Sem culpa no som.** Nenhum som descendente "murcho", nenhum gemido de bicho
   triste, nenhum buzzer. Desistência e saudade têm sons **resolvidos** (regra 1
   do `PRODUCT.md`).
6. **Mistura, não interrompe.** O app nunca pausa a música da pessoa
   (`audioFocus: none`) e respeita o modo silencioso.
7. **Nunca o mesmo som duas vezes idêntico.** Cada som tem 3 a 4 variações e
   jitter de altura e volume ([F] Material e Apple).

### 4.2 Paleta de timbres

| Família | Timbre | Por que (relação com o app) | Uso | Fonte de produção |
|---|---|---|---|---|
| **Madeira afinada grave** | Marimba (barra de madeira, parciais 1 : 4 : ~10) | A doca e a madeira (`#A0764C`) do habitat. Calor, chão | Herói, raiz, sessão, desistência | Síntese local |
| **Madeira afinada aguda** | Kalimba (lâmina, ataque "plim", parcial inarmônico curto) | Leve, mágico, "folhinha". Combina com a moeda-folha | Recompensas: folhas, missão, compra, carinho | Síntese local |
| **Madeira seca** | Bloco de madeira/claves (ruído em banda + ressonância) | Gesto tátil sem altura ([F] Material: atonal para háptico e movimento) | Toques de interface, toggles | Síntese local |
| **Água** | Gota/bolha (seno com glissando ascendente rápido), marola | O lago onde todos os bichos estão | Brilho no herói, axolote, ambiente | Síntese local (gota), ElevenLabs (marola) |
| **Folha** | Farfalhar curto de folhas secas | A moeda do app *é* folha | Folhas ganhas, compra, item planta | ElevenLabs |
| **Terra** | Pá de terra úmida, terra abrindo | A toca e a raiz (streak) | Cavar, prêmio, raiz cresceu | ElevenLabs |
| **Voz** | "Animalese" por espécie (sílabas de vocalização fofa, re-afinadas) | O bicho é o produto | Toque no bicho, humor, falas, reação | ElevenLabs (matéria-prima) + motor local |

Excluídos: sinos de metal brilhante, sintetizador tipo arcade, sons de moeda
metálica, "fanfarra" de metais, risadas humanas, buzzer de erro. **[I]** Todos
contradizem o mundo de madeira e lago, e moeda metálica desmente a moeda-folha.

### 4.3 Tonalidade e notas

Fá maior pentatônica, afinação A4 = 440 Hz:

| Nota | F3 | G3 | A3 | C4 | D4 | F4 | G4 | A4 | C5 | D5 | F5 | G5 | A5 | C6 | D6 | F6 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hz | 174,6 | 196,0 | 220,0 | 261,6 | 293,7 | 349,2 | 392,0 | 440,0 | 523,3 | 587,3 | 698,5 | 784,0 | 880,0 | 1046,5 | 1174,7 | 1396,9 |

Abaixo de ~300 Hz, a marimba pede o 2º parcial (4×) presente para o
alto-falante "ouvir" a nota [I]. A receita da seção 5.3 já inclui isso.

### 4.4 Hierarquia e loudness alvo

A referência 0 dB é o som de **sessão concluída**. Os alvos são de **máximo
momentâneo (EBU R128 M, janela 400 ms)**, porque o integrado não funciona para
sons curtos. Pico verdadeiro sempre ≤ −1 dBTP. O player toca a volume 1,0. O
nível vem da masterização, não do código (hoje é 0,55).

| Nível (Material) | Categoria do Baru | dB rel. | Alvo LUFS-M máx. | Frequência esperada |
|---|---|---|---|---|
| 1 mnemônico | Motivo do Baru (abertura do app na 1ª vez, notificação) | 0 | −14 | raro |
| 2 herói | Sessão concluída, nível, marco, espécie liberada | 0 a +1 | −14 a −13 | 1–3×/dia |
| 2b herói menor | Raiz cresceu, missão resgatada, prêmio da toca | −2 | −16 | 1–5×/dia |
| 3 voz | Voz do bicho (toque, humor, reação) | −4 | −18 | várias/dia |
| 4 primário | Folhas ganhas, compra, item no habitat, carinho completo | −5 | −19 | várias/dia |
| 5 secundário | Toggles, indisponível, contagem, cavar | −10 | −24 | frequente |
| — | Navegação/abas | silêncio | — | muito frequente |
| ambiente | Loops por período | −18 | −32 (integrado do loop) | contínuo, opt-in |

**Modo noite [I]:** entre 22 h e 6 h (ou período `noite`, `models.dart:56-66`),
todos os sons caem 4 dB. O herói cai 2 dB.

### 4.5 Quando tocar e quando calar (regras do serviço)

| Situação | Comportamento |
|---|---|
| Ajuste "Sons" = Desligado | Nada toca. O háptico continua, controlado pela chave própria |
| Ajuste "Sons" = Só momentos | Toca só níveis 1, 2 e 2b, mais a voz |
| Ajuste "Voz do bicho" desligado | A voz some, o resto segue |
| Modo de toque do sistema = silencioso **ou vibrar** | Nenhum som. Háptico sim ([F] Apple, por analogia: efeitos sonoros são "nonessential") |
| Sessão de foco em andamento | Nenhum som, nem ambiente (a menos que a pessoa tenha ligado "ambiente durante o foco") |
| App fora do primeiro plano | Nenhum som pelo player. O fim da sessão em segundo plano soa **pela notificação**, com som próprio (seção 4.6, N1) |
| TalkBack ativo | Sem níveis 4 e 5. O ambiente fica desligado mesmo se ligado [I] |
| Dois sons ao mesmo tempo | Permitido (pool de players). Limite **por som** e não global: o mesmo som no máximo 1×/120 ms (voz) ou 1×/300 ms (UI) |

### 4.6 Mapa completo: evento → som → háptico

Legenda. **Dur.** = duração do arquivo. **Var.** = como evitar repetição (N
arquivos e jitter de altura em cents). **Háptico**: ver códigos na seção 4.8.
"Hoje" = o que existe.

#### Interface (níveis 4–5)

| ID | Evento (onde no código) | Hoje | Som proposto | Dur. | Tom | Var. | dB rel. | Háptico |
|---|---|---|---|---|---|---|---|---|
| U1 | Toque em botão primário do loop (iniciar, resgatar, comprar: `componentes.dart:141-170`) | mudo | Bloco de madeira seco, curto | 60–80 ms | ~C6 (ressonância) | 4 arq. + ±40 cents | −12 | H-leve |
| U2 | Navegação/abas, rolagem, abrir cartão | mudo | **Silêncio** | — | — | — | — | H-tique |
| U3 | Toggle liga / desliga (Ajustes) | mudo | 2 toques de madeira **subindo** (C6→F6) / **descendo** (F6→C6) | 120 ms | C6, F6 | ±20 cents | −12 | `TOGGLE_ON`/`OFF` (API 34) ou H-tique |
| U4 | Ação indisponível (folhas insuficientes) | mudo | 2 toques de madeira grave **na mesma nota** (repetição = "ainda não", [F] Material) | 180 ms | A4 A4 | 2 arq. | −12 | H-leve ×2 (nunca `REJECT`) |
| U5 | Contagem de folhas/XP subindo (contadores animados) | mudo | Tiques de kalimba **subindo a pentatônica**, 1 por incremento, máx. 8, o último sempre F6 | 40 ms cada | C5→F6 | sobe a escala | −14 | H-tique por tique |
| U6 | Abrir a loja / trilha | mudo | Silêncio | — | — | — | — | — |

#### Economia e habitat (nível 4)

| ID | Evento | Hoje | Som proposto | Dur. | Tom | Var. | dB rel. | Háptico |
|---|---|---|---|---|---|---|---|---|
| E1 | **Folhas creditadas** (fim de sessão, missão) | mudo | Punhado de folhas (EL) + 2 notas de kalimba C6→F6 | 0,7 s | C6, F6 | 3 farfalhares × 3 pares de notas (C6-F6, D6-F6, A5-C6) | −5 | H-arpejo2 |
| E2 | **Compra** (`state.dart:1732`) | mudo | Embrulho de papel/folha (EL) + kalimba G5→C6 | 0,6 s | G5, C6 | 3 arq. | −5 | `CONFIRM` (30+) / H-leve |
| E3 | **Item entra no habitat** (equipado após compra, `state.dart:1737`) | mudo | Queda suave pelo material: **planta** (lily, bamboo, tree, coroa) = farfalhar + tum, **madeira** (dock, boat) = toc oco, **pedra** (rock, bridge) = clac abafado, **vidro** (lantern) = tim + zumbido quente, **tecido** (roupas) = fofo "fump" + voz feliz do bicho | 0,4–0,6 s | — (atonal) + 1 nota F5 de kalimba no fim | 3 por material, ±60 cents | −6 | H-terra |
| E4 | **Cenário aplicado** (entardecer, noite estrelada, chuva, neblina) | mudo | Crossfade de 2 s para o ambiente do cenário (seção 4.9). Com ambiente desligado, brilho de kalimba F5-A5-C6 | 1,2 s | F maior | — | −6 | H-leve |
| E5 | **Cavar** (gestos 1 e 2, `toca.dart:95`) | `cavar.wav` (chiado) | Pá de terra úmida (EL), **mais grave a cada gesto** (rate 1,0 → 0,94) | 0,3 s | — | 4 arq. round-robin + ±50 cents | −10 | H-terra crescente (0,5 → 0,8) |
| E6 | **Terra abre / prêmio sobe** (`toca.dart:104`) | `premio.wav` (Lá menor) | Terra abrindo (EL) + glissando de kalimba F5-A5-C6-F6 em 160 ms + gota | 0,9 s | F maior | 3 arq. | −2 | H-heroi-curto |

#### Missões, raiz e progressão (níveis 2 e 2b)

| ID | Evento | Hoje | Som proposto | Dur. | Tom | Var. | dB rel. | Háptico |
|---|---|---|---|---|---|---|---|---|
| P1 | **Missão resgatada** (`state.dart:425`, `:769`) | `resgate.wav` | Motivo em kalimba rápido: C5-F5-A5 (90 ms entre notas) com a última sustentando | 1,0 s | F maior | 3 arq. (inversões C5-F5-A5, A4-C5-F5, F5-A5-C6) | −2 | H-arpejo3 (cliques nas notas) |
| P2 | Prêmio da toca **+** missão: sequência | `premio` + `resgate` em tonalidades diferentes | E6 e, 720 ms depois, P1 **na mesma tonalidade**. Os dois são da família e o 2º "responde" o 1º | — | F maior | — | — | — |
| P3 | **Raiz cresceu** (1ª sessão do dia, `state.dart:1909-1912`) | mudo | Marimba grave F3→C4→F4 (a raiz é funda) + madeira rangendo/terra (EL) + 1 brilho F5. Toca **600 ms após** a sessão concluída | 1,5 s | F maior grave | 2 arq. + a nota final sobe 1 grau a cada 7 dias de raiz (F4, G4, A4, C5, D5, volta) | −2 | H-raiz (THUD fraco + SLOW_RISE) |
| P4 | **Congelamento usado** (a falta foi absorvida) | mudo | Geada cristalina suave (EL) + kalimba A5 sustentada. É proteção, não alarme | 1,0 s | A5 | 1 arq. | −5 | H-leve |
| P5 | Raiz **não** cresceu / dia perdido | mudo | **Silêncio, de propósito** (regra 1: nada de som de perda) | — | — | — | — | — |
| P6 | **Subiu de nível** (`app.dart:318-327`) | `cavar` + `premio` + `conquista` | E5 → E6 → **herói de nível**: motivo A4-C5-F5 em marimba + acorde F5-A5-C6 em kalimba + marimba grave F3 + gota. A nota mais aguda sobe a cada nível (C6, D6, F6, ciclo) | 2,0 s | F maior | 3 tops × 2 arq. | +1 | H-heroi |
| P7 | **Marco da trilha** (`app.dart:340-349`) | igual ao nível | Herói de nível **sem** a marimba grave e com 4ª nota D6 (parente, não igual) | 1,8 s | F maior | 2 arq. | 0 | H-heroi |
| P8 | **Espécie liberada** (marco que libera bicho) | igual ao nível | P7 + **a voz "feliz" da espécie nova** 300 ms depois. A pessoa ouve o bicho novo pela primeira vez | 2,3 s | F maior | 9 (uma por espécie) | +1 | H-heroi + H-leve na voz |
| P9 | **Chegada do dia** ("bom te ver", `app.dart:331-337`) | `conquista` (som de herói) | **Não é herói.** Voz do bicho conforme o humor (seção 4.7) + kalimba F5→A5 suave | 0,8 s | F5, A5 | por humor e espécie | −4 | H-leve |

#### Sessão de foco (níveis 1–2)

| ID | Evento | Hoje | Som proposto | Dur. | Tom | Var. | dB rel. | Háptico |
|---|---|---|---|---|---|---|---|---|
| F1 | **Sessão iniciada** (`state.dart:1789`) | mudo | Sopro/brisa ascendente suave (EL) + uma nota de marimba F4 e depois silêncio. É a "respiração antes do foco" | 0,9 s | F4 | 2 arq. | −6 | `GESTURE_START` (30+) ou H-inicio |
| F2 | Durante a sessão | — | **Silêncio** (ou ambiente, se a pessoa ligou) | — | — | — | — | — |
| F3 | **Sessão concluída** em primeiro plano (`state.dart:1907`) | `fim.wav` (quinta parada) | **Herói principal**: motivo A4-C5-F5 em marimba + acorde F5-A5-C6 em kalimba na última nota + gota. Depois de 300 ms, **voz feliz do bicho**. Depois vêm E1 (folhas), P3 (raiz, se houver) e U5 (contagem), em sequência e não juntos | 1,8 s | F maior | 3 arq. + camada extra por duração: 25 min = base, 45–50 min = + marimba grave F3 | 0 | H-heroi |
| F4 | **Sessão concluída em segundo plano** | `fim.wav` toca por cima de outro app + "ding" do sistema | Só **notificação** num canal novo `baru_fim_v1` com som próprio `res/raw/baru_fim.ogg` (versão de 1,2 s do F3). O canal respeita o "Não perturbe" e o silencioso pelo próprio sistema | 1,2 s | F maior | — | 0 | o do canal |
| F5 | **Desistência** (`state.dart:1999`) | mudo | Marimba C5→A4 (descendente, termina na **terça de Fá**, resolvido), suave e sem detune. Depois a voz do bicho em contorno "contente" curto. Diz "tudo bem", não "você falhou" | 0,9 s | C5, A4 | 2 arq. | −10 | H-fim-suave |
| F6 | Sobreposição "volta pro foco" (`OverlayDoBaru.kt`) | mudo | **Silêncio** [I]. A pessoa está em outro app, e som ali é intrusão. Basta o visual | — | — | — | — | nenhum |

#### Bicho (nível 3)

| ID | Evento | Hoje | Som proposto | Dur. | Var. | dB rel. | Háptico |
|---|---|---|---|---|---|---|---|
| B1 | **Toque no bicho** (`pet.dart:574-591`) | `toque.wav` | 1 sílaba da voz da espécie, altura base ± 2 semitons aleatórios dentro da pentatônica | 80–150 ms | banco de 6–8 sílabas, round-robin, ±30 cents | −4 | H-leve |
| B2 | 3º toque seguido (`_toquesSeguidos >= 3`) | igual | "Risadinha": 3 sílabas subindo (contorno radiante) | 0,35 s | idem | −4 | H-leve ×2 |
| B3 | **Afago em curso** (`pet.dart:642-660`) | só `selectionClick` | Loop de **ronrom/contentamento da espécie**: fade-in de 150 ms ao começar, volume segue a velocidade do dedo, fade-out de 300 ms ao soltar | loop 3 s | 2 loops alternados | −8 | H-ronrom alinhado |
| B4 | **Afago completo** (`state.dart:264-266`) | `carinho.wav` | Kalimba F5+A5 (díade) + voz "feliz" da espécie | 0,8 s | 3 díades (F5-A5, A5-C6, C6-F6) | −4 | `CONFIRM` / H-leve |
| B5 | **Humor ao abrir a home** (1× por abertura) | mudo | Frase curta em Animalese com contorno do humor (seção 4.7) | 0,3–0,8 s | contorno + sílabas aleatórias | −4 | nenhum |
| B6 | **Fala do bicho** aparece (balão, `l10n_humor.dart`) | mudo | Animalese: 1 sílaba por palavra (máx. 8), contorno do humor | ≤ 1 s | idem | −6 | nenhum |
| B7 | Gesto ocioso (espreguiçar, sacudir, farejar: `pet.dart`) | mudo | Foley curto por gesto (bocejo, chacoalhão de água, fungada), só se o ambiente estiver ligado | 0,4 s | 2 cada | −12 | nenhum |
| B8 | Bicho troca de roupa (equipar) | mudo | Tecido "fump" + voz feliz | 0,5 s | 3 | −6 | H-leve |

#### Fora do app

| ID | Evento | Hoje | Som proposto |
|---|---|---|---|
| N1 | Lembrete / relatório da noite (`canalLembretes`) | "ding" padrão do sistema | Canal **novo** `baru_lembretes_v2` com `sound: baru_chamado`: motivo A4-C5-F5 em kalimba + 2 sílabas genéricas de bicho, 1,2 s. **[I]** O canal antigo não pode ter o som trocado depois de criado, então é preciso id novo e apagar o antigo |
| N2 | Sessão em andamento (`canalSessao`) | sem som (correto) | Manter sem som |

### 4.7 Vozes por espécie

**Motor (comum às 9).** Cada espécie tem um **banco de 6 a 8 sílabas** de 80 a
150 ms, cortadas de uma geração do ElevenLabs e **re-afinadas localmente** para
a nota base da espécie (seção 5.4). Em tempo de execução, cada sílaba toca com
`playbackRate = 2^((contorno[i] + jitter)/12)`, com jitter de ±0,3 semitom, no
intervalo de sílabas do humor. É o método do Animalese ([F] altura por
personagem, altura pelo humor, velocidade pelo texto) com a variação por
palavra do devlog do Springbound. A fala é **sem palavras**, então vale igual
em pt, en, es e zh, sem tradução (regra 2 do contrato atendida sem custo).

**[F] Altura ligada ao tamanho do corpo** (como em New Horizons, segundo a
Nookipedia):

| Espécie | Nome | Nota base | Hz | Matéria-prima (o que pedir) | Caráter | Ronrom do afago (B3) |
|---|---|---|---|---|---|---|
| tortoise | Toco | F3 | 174,6 | "hum" nasal grave e lento, sopro | calmo, sábio, lento: intervalo de sílaba 1,4× | respiração lenta com zumbido grave |
| frenchie | Bolota | G3 | 196,0 | bufadas, "boof" abafado, grunhidinhos | atrapalhado, carinhoso | fungada contente tipo ronco leve |
| capybara | Baru | A3 | 220,0 | chilreios suaves com cliques de ronrom | tranquilo, acolhedor | ronrom grave com cliques |
| owl | Nina | C4 | 261,6 | "huu" redondo tipo ocarina | sereno, noturno | arrulho baixo contínuo |
| cat | Mel | D4 | 293,7 | trinado "mrrp", chilreio | curiosa, afetuosa | ronronar de gato |
| fox | Faísca | F4 | 349,2 | "kek" suave, ganidinhos curtos (nunca o grito de raposa) | esperta, brincalhona | tagarelar baixinho contente |
| penguin | Nino | G4 | 392,0 | "piu" anasalado de filhote | desajeitado, alegre | piados baixos de contentamento |
| otter | Rio | A4 | 440,0 | chilreios e guinchos rápidos e agudos | brincalhona, rápida: intervalo 0,8× | risadinha tagarela |
| axolotl | Lume | C5 | 523,3 | blips borbulhantes, gorgolejo (sem voz real) | etéreo, aquático | borbulhar suave |

**Contornos por humor** (`Mood { radiant, content, neutral, sleepy,
missingYou }`, `models.dart:49`). Os semitons são relativos à base e ficam
sempre na pentatônica:

| Humor | Contorno (semitons por sílaba) | Sílabas | Intervalo | Extra | Regra |
|---|---|---|---|---|---|
| radiante | 0, +2, +4, +7 (sobe) | 3–5 | 75 ms | sílaba "feliz" no fim | mais agudo e rápido ([F] Animalese: feliz = mais agudo) |
| contente | 0, +2, 0, +2 (ondula) | 2–4 | 95 ms | — | — |
| neutro | 0, 0, −3, 0 | 2–3 | 110 ms | — | — |
| sono | 0, −3, −5 (desce devagar) | 2 | 150 ms | bocejo da espécie | −4 dB. É cansaço gostoso, não tristeza |
| saudade | −3, 0, +4, +7 ("é você? é você!") | 3–4 | 90 ms | sílaba "feliz" no fim | **Nunca** gemido ou choro. Saudade = alegria do reencontro (regra 1: nunca culpa) |

**O que não fazer com a voz:** não usar chamados reais de animal crus ([F] o
Springbound relata que soam "random and inconsistent"). Não usar TTS com
palavras, porque obrigaria a localizar e entraria no "uncanny". Não deixar a
fala longa: máximo de 8 sílabas.

### 4.8 Háptico casado com o som

Implementar via canal nativo `baru/haptico` em `MainActivity.kt`, com
`view.performHapticFeedback(...)` para constantes e `Vibrator.vibrate(composição)`
para padrões. Use fallback se `areAllPrimitivesSupported` for falso ([F] doc
Android). **Disparar no mesmo frame do som** e alinhar cada primitiva à nota
correspondente.

| Código | Android preferido | Fallback (API baixa / sem primitivas) | Usado em |
|---|---|---|---|
| H-tique | `SEGMENT_TICK` (34) | `CLOCK_TICK` = `selectionClick` | U2, U5 |
| H-leve | `VIRTUAL_KEY` | `lightImpact` | U1, U4, B1, B2, E4, P4, P9 |
| H-terra | `PRIMITIVE_THUD` 0,5–0,8 | `mediumImpact` | E3, E5 |
| H-arpejo2 | `CLICK` 0,5 → `CLICK` 0,7 @+80 ms | `lightImpact` | E1 |
| H-arpejo3 | `CLICK` 0,5 → 0,65 @+90 → 0,9 @+90 (nas 3 notas) | `CONFIRM` (30) ou `lightImpact` | P1 |
| H-heroi-curto | `QUICK_RISE` 0,5 → `CLICK` 1,0 | `heavyImpact` | E6 |
| H-heroi | `SLOW_RISE` 0,5 → `CLICK` 1,0 (na 3ª nota) → `TICK` 0,6 @+120 → `TICK` 0,4 @+120 | `CONFIRM` | F3, P6, P7, P8 |
| H-raiz | `THUD` 0,4 → `SLOW_RISE` 0,6 | `mediumImpact` | P3 |
| H-inicio | `GESTURE_START` (30) ou `QUICK_RISE` 0,3 | `lightImpact` | F1 |
| H-fim-suave | `QUICK_FALL` 0,25 | `lightImpact` | F5 |
| H-ronrom | `LOW_TICK` 0,25 a cada ~110 ms enquanto o dedo anda | `selectionClick` por distância (já existe) | B3 |

Regras: chave "Vibração" própria em Ajustes ([F] Apple). Nunca usar `createOneShot`
nem `vibrate(long)` ([F] Android: "buzzy"). Nunca usar `REJECT` em nada do Baru
(não há erro, só "ainda não"). **[I]** Usar `VibrationAttributes.USAGE_TOUCH`
(API 33+) para que a intensidade de "resposta ao toque" do sistema valha, a
conferir na referência.

### 4.9 Ambiente opcional (período do dia e cenário)

[F] O Material admite ambiente "to express an emotional tone and user's location"
desde que não atrapalhe a tarefa. [F] O Animal Crossing é conhecido pela música
por hora. [F] Mais de 3 s automáticos exigem controle (WCAG 1.4.2).

**Desligado por padrão.** Chave "Som ambiente" em Ajustes com volume próprio, e
uma segunda chave "Ambiente durante o foco" (desligada). Toca só com a home
visível, faz crossfade de 2 s na troca de período e para no `paused`.

| Ambiente | Quando | Conteúdo | Formato |
|---|---|---|---|
| A1 amanhecer | `PeriodoDoDia.amanhecer` (5–9 h) | marola na doca, pássaros esparsos e distantes, brisa | loop 30 s |
| A2 dia | `dia` (9–17 h) | marola, insetos leves, folhas ao vento, um pássaro ocasional | loop 30 s |
| A3 entardecer | `entardecer` ou cenário `entardecer` | marola mais lenta, pássaros recolhendo, primeiros grilos | loop 30 s |
| A4 noite | `noite` | grilos, sapos ao longe, água quase parada | loop 30 s |
| A5 chuva | cenário `chuva` (loja) | chuva leve no lago e nas folhas (substitui o período) | loop 30 s |
| A6 neblina | cenário `neblina` | A1 com passa-baixa de 2 kHz, menos pássaros (feito localmente) | derivado |
| A7 noite estrelada | cenário `noite_estrelada` | A4 + cintilar raro de kalimba aleatório na pentatônica (1 a cada 8–15 s, local) | A4 + gerador |

**Camada musical (fora do escopo desta fase) [I]:** uma trilha de kalimba e
marimba por período (ElevenLabs Music) pode vir depois que os efeitos estiverem
validados. Música mal feita cansa mais rápido que ambiente, e a ordem certa é
efeitos → ambiente → música.

---

## 5. Plano de produção

### 5.1 O que vem de onde

| Fonte | O quê | Por quê |
|---|---|---|
| **Síntese local** (Python, numpy/scipy) | Tudo que é **afinado**: marimba, kalimba, madeira, gota, motivo, heróis, contagem, toggles; o cintilar do A7; o filtro do A6; o re-afinamento e o corte das vozes | Precisão de nota e tonalidade (a identidade depende disso), reprodutível, custo zero, versionável |
| **ElevenLabs SFX v2** | Tudo que é **orgânico e difícil de sintetizar bem**: terra, folhas, papel, quedas por material, geada, sopro, ambientes em loop e a matéria-prima das 9 vozes | Foley e vocalização exigem gravação ou modelo |
| **Mistura local** | Sons híbridos (E1, E2, E6, P3, F3) = camada EL + camada sintetizada | Organicidade + afinação |

### 5.2 Gerações no ElevenLabs (prompts exatos)

Configuração comum: `model_id: eleven_text_to_sound_v2`, `output_format`
WAV 48 kHz (sem loop) ou MP3 de maior qualidade para loops (a doc só lista WAV
para não-loop), e `loop: false` salvo indicação. Gerar 3 tomadas por item (o
loop, 2) e escolher na audição. Toda tomada passa pela pós-produção da seção 5.4.

**Efeitos (one-shots)**

| Arquivo-fonte | Prompt (inglês, exato) | `duration_seconds` | `prompt_influence` |
|---|---|---|---|
| `el_terra_cavar` | `Single small hand scoop digging into soft moist garden soil, short earthy crunch with low body, close mic, dry, no reverb, isolated, no music` | 0.5 | 0.6 |
| `el_terra_abre` | `Soft earth crumbling open and a small object popping up out of the ground, gentle and cute, cartoon foley, close mic, dry, isolated, no music` | 1.0 | 0.5 |
| `el_folhas_punhado` | `A small handful of dry leaves rustling briefly, light and crisp, close mic, dry, isolated, no music` | 0.5 | 0.6 |
| `el_compra_embrulho` | `Quick soft rustle of a small paper gift being unwrapped, cozy and gentle, close mic, dry, isolated, no music` | 0.6 | 0.5 |
| `el_cai_planta` | `Small potted plant set down on soft grass, gentle leafy swish followed by a soft thud, close mic, dry, isolated` | 0.5 | 0.55 |
| `el_cai_madeira` | `Small wooden toy dropped onto a wooden dock, single hollow wooden knock with a tiny bounce, close mic, dry, isolated` | 0.5 | 0.6 |
| `el_cai_pedra` | `Small smooth stone placed onto damp ground, soft muffled stone clack, close mic, dry, isolated` | 0.5 | 0.6 |
| `el_cai_vidro` | `Small glass lantern set down gently, soft glass tink with a warm faint hum, close mic, dry, isolated` | 0.5 | 0.55 |
| `el_cai_tecido` | `Soft fabric hat or scarf dropped onto a cushion, gentle fluffy fwump, close mic, dry, isolated` | 0.5 | 0.55 |
| `el_raiz_cresce` | `Plant roots growing underground, soft creaking wood and gently shifting earth, warm and magical, short, close mic, dry, no music` | 1.5 | 0.45 |
| `el_geada` | `Delicate frost crystallizing on a leaf, soft icy shimmer, gentle and calm, close mic, dry, no music` | 1.0 | 0.45 |
| `el_sopro_inicio` | `Calm soft breath-like wind whoosh gently rising, airy and peaceful, close mic, dry, no music` | 0.8 | 0.5 |
| `el_gota_lago` | `Single small water droplet falling into a calm lake, clean plop, close mic, dry, isolated` | 0.5 | 0.6 |

**Ambientes (loop)**

| Arquivo-fonte | Prompt | `duration_seconds` | `prompt_influence` | `loop` |
|---|---|---|---|---|
| `el_amb_amanhecer` | `Gentle lake shore ambience at dawn, soft water lapping against a small wooden dock, sparse distant songbirds, light breeze through leaves, calm and peaceful, no music, no voices, seamless loop` | 30 | 0.35 | true |
| `el_amb_dia` | `Calm lake shore ambience during a warm day, soft water lapping, faint insects, leaves rustling in a light breeze, an occasional distant bird, peaceful, no music, no voices, seamless loop` | 30 | 0.35 | true |
| `el_amb_entardecer` | `Quiet lake shore ambience at sunset, slow gentle water lapping, a few birds settling down, first crickets starting, warm and calm, no music, no voices, seamless loop` | 30 | 0.35 | true |
| `el_amb_noite` | `Peaceful lake shore at night, steady soft crickets, distant frogs, very still water with tiny ripples, calm, no music, no voices, seamless loop` | 30 | 0.35 | true |
| `el_amb_chuva` | `Light gentle rain falling on a calm lake and on leaves, soft and cozy, no thunder, no music, no voices, seamless loop` | 30 | 0.4 | true |

**Vozes: matéria-prima por espécie.** Quatro gerações por espécie, a partir dos
moldes abaixo. Substitua `{SYL}` (sílabas), `{HAPPY}`, `{YAWN}` e `{PURR}` pela
linha da espécie.

| Gera | Molde do prompt | `duration_seconds` | `prompt_influence` | `loop` |
|---|---|---|---|---|
| `el_voz_<esp>_silabas` | `Cute cartoon {SYL}, six short separate syllables with clear short pauses between them, friendly and gentle, close mic, dry, isolated, no background, no music` | 2.0 | 0.5 | false |
| `el_voz_<esp>_feliz` | `One short happy cute {HAPPY} that rises in pitch, friendly, close mic, dry, isolated, no music` | 0.8 | 0.55 | false |
| `el_voz_<esp>_sono` | `Sleepy cute {YAWN}, soft breathy yawn falling in pitch, close mic, dry, isolated, no music` | 1.2 | 0.5 | false |
| `el_voz_<esp>_carinho` | `Continuous soft contented {PURR} of a cute small animal being gently petted, steady and calm, close mic, dry, no music, seamless loop` | 3.0 | 0.5 | true |

| Espécie | `{SYL}` | `{HAPPY}` | `{YAWN}` | `{PURR}` |
|---|---|---|---|---|
| capybara | `capybara chirps, soft squeaky chirps mixed with gentle clicking purrs` | `capybara chirp` | `capybara yawn with a tiny squeak` | `low purring hum with tiny clicks` |
| otter | `otter chirps, quick high-pitched playful squeaks and twitters` | `otter squeak` | `otter yawn with a small squeak` | `chuckling chirps` |
| tortoise | `old tortoise hums, slow mellow low nasal 'hmm' sounds, breathy` | `low 'hmm' hum` | `slow deep tortoise yawn` | `slow breathing with a low hum` |
| owl | `owl hoots, short round mellow 'hoo' sounds like a wooden ocarina at slightly different pitches` | `owl 'hoo'` | `owl yawn with a soft hoot` | `cooing` |
| axolotl | `underwater creature voice, short bubbly blips and soft gurgles` | `bubbly blip` | `bubbly gurgle sinking in pitch` | `bubbling` |
| penguin | `baby penguin peeps, slightly nasal squeaky honks` | `baby penguin peep` | `baby penguin yawn` | `soft content peeping` |
| cat | `cat trills, soft 'mrrp' chirps, no meowing scream` | `cat trill` | `cat yawn with a tiny squeak` | `cat purring` |
| fox | `fox chirps, soft playful 'kek' sounds and tiny gentle yips, never harsh or screaming` | `fox chirp` | `fox yawn with a tiny whine-free squeak` | `soft happy chittering` |
| frenchie | `French bulldog sounds, soft muffled 'boof' woofs, snorts and little grunts` | `snorty 'boof'` | `bulldog yawn with a snort` | `snuffly contented snoring breaths` |

**Custo estimado** ([F] 40 créditos/s com duração especificada):

| Lote | Segundos por tomada | Tomadas | Segundos | Créditos |
|---|---|---|---|---|
| 13 efeitos | 8,9 s | 3 | 26,7 | 1.068 |
| 9 espécies × 4 gerações (2,0 + 0,8 + 1,2 + 3,0) | 63 s | 3 | 189 | 7.560 |
| 5 ambientes | 150 s | 2 | 300 | 12.000 |
| **Total** | | | **515,7 s** | **≈ 20.600** |

**[I]** Esta é a primeira rodada. Reserve +50% para refazer o que reprovar na
audição. Confirme se o plano contratado permite uso comercial dos efeitos (ver
riscos).

### 5.3 Síntese local (receitas)

Protótipo **gerado e medido** (não ouvido) com as funções abaixo. Fica fora do
repositório, em
`/tmp/claude-0/-home-user/d3806615-df93-5613-8e54-399025d4deb2/scratchpad/gera_prototipo.py`.
Resultados medidos:

| Protótipo | Dur. | Picos espectrais medidos | LUFS-M máx. (antes de calibrar) |
|---|---|---|---|
| `missao_resgatada` (kalimba C5-F5-A5) | 1,18 s | 523, 699, 880 Hz | −10,0 |
| `sessao_concluida` (marimba A4-C5-F5 + kalimba A5/C6 + gota) | 1,84 s | 440, 523, 699, 880, 1047 Hz | −12,4 |
| `desistencia` (marimba C5→A4) | 1,16 s | 440, 523 Hz | −11,4 |
| `pet_toque_capivara` (marimba A3 de teste) | 0,35 s | 349 Hz | −17,5 |
| `folhas_ganhas` (ruído de folha sintético + kalimba C6-F6) | 0,73 s | 1047, 1397 Hz + ruído 2,5–9 kHz | −14,0 |
| `ui_toque_1` (bloco de madeira) | 0,08 s | ~880 Hz em banda | −28,6 |

Diferente dos atuais, a planura espectral fica entre 0,006 e 0,4 (há timbre),
com várias parciais por nota.

Núcleo das receitas (48 kHz):

```python
SR = 48000
def t(d): return np.arange(int(SR*d))/SR
def marimba(f, d=0.6, decai=0.22):          # barra: parciais 1 : 4 : ~10, agudos morrem rápido
    x = t(d)
    s = (np.sin(2*np.pi*f*x)*np.exp(-x/decai)
         + 0.35*np.sin(2*np.pi*4*f*x)*np.exp(-x/(decai/4))
         + 0.12*np.sin(2*np.pi*9.9*f*x)*np.exp(-x/(decai/9)))
    golpe = sosfilt(butter(2,[2000,6000],'bandpass',fs=SR,output='sos'),
                    rng.standard_normal(len(x)))*np.exp(-x/0.004)*0.25   # baqueta
    return s + golpe
def kalimba(f, d=0.8, decai=0.35):          # lâmina: "plim" inarmônico ~5,9x muito curto
    x = t(d)
    return (np.sin(2*np.pi*f*x)*np.exp(-x/decai)
            + 0.25*np.sin(2*np.pi*5.93*f*x)*np.exp(-x/0.03)
            + 0.08*np.sin(2*np.pi*2*f*x)*np.exp(-x/(decai/2)))
def madeira(f=900, d=0.08):                  # bloco: ruído em banda estreita + ressonância
    x = t(d); n = rng.standard_normal(len(x))
    return (sosfilt(butter(2,[f*0.8,f*1.25],'bandpass',fs=SR,output='sos'),n)*np.exp(-x/0.012)*4
            + 0.4*np.sin(2*np.pi*f*x)*np.exp(-x/0.02))
def gota(f0=900, f1=1900, d=0.12):           # bolha: seno com glissando ascendente rápido
    x = t(d); fr = f0+(f1-f0)*(1-np.exp(-x/0.02))
    return np.sin(2*np.pi*np.cumsum(fr)/SR)*np.exp(-x/0.03)
```

**[I]** Os coeficientes de parciais e decaimento são ponto de partida de
ofício. O ajuste final é de ouvido, no aparelho.

Receita por som (notas da seção 4.3; `@` = início em segundos; ganho em dB):

| ID | Receita |
|---|---|
| U1 | `madeira(f)` com f ∈ {1000, 1046, 1100, 1175} → 4 arquivos |
| U3 | `madeira(1046)@0 + madeira(1397)@0.06` (liga) e o inverso (desliga) |
| U4 | `marimba(A4,0.25,0.06)@0 + marimba(A4,0.25,0.06)@0.11 −2` |
| U5 | `kalimba(n,0.25,0.06)` para n em C5, D5, F5, G5, A5, C6, D6, F6 → 8 arquivos (o app escolhe por índice) |
| E1 | `el_folhas_punhado −6 @0 + kalimba(C6)@0.05 + kalimba(F6)@0.13 −3`, × 3 pares de notas |
| E2 | `el_compra_embrulho −4 @0 + kalimba(G5)@0.10 + kalimba(C6)@0.19` |
| E3 | `el_cai_<material> @0 + kalimba(F5,0.5,0.15)@0.18 −10` |
| E6 | `el_terra_abre @0 + kalimba F5,A5,C6,F6 @0.25/0.29/0.33/0.37 + gota() @0.4 −10` |
| P1 | `kalimba(C5)@0 + kalimba(F5)@0.09 + kalimba(A5,1.0,0.45)@0.18`, + 2 inversões |
| P3 | `marimba(F3,1.2,0.5)@0 + marimba(C4)@0.12 + marimba(F4,1.2,0.5)@0.24 + el_raiz_cresce −8 @0 + kalimba(F5)@0.5 −8` |
| P6 | `marimba A4,C5,F5 @0/0.12/0.24 + kalimba F5,A5,top @0.24 (−4) + marimba(F3,1.6,0.6)@0.24 −6 + gota@0.05 −14`; top ∈ {C6, D6, F6} |
| P7 | P6 sem `marimba(F3)` e com `kalimba(D6)@0.40 −6` |
| F1 | `el_sopro_inicio −6 @0 + marimba(F4,0.9,0.35)@0.45` |
| F3 | Protótipo `sessao_concluida` (medido acima). Variante longa + `marimba(F3)@0.24 −6`; versão `baru_fim.ogg` de notificação = F3 com corte em 1,2 s e fade de 150 ms |
| F5 | `marimba(C5,0.8,0.3)@0 −2 + marimba(A4,1.0,0.35)@0.16 −4` |
| B4 | `kalimba(F5)+kalimba(A5)` simultâneas (e as outras 2 díades) |
| N1 | `kalimba A4,C5,F5 @0/0.12/0.24` + 2 sílabas da capivara (voz-marca) a −6 |
| A7 | gerador em tempo de execução: `kalimba(nota aleatória F5–F6, 1.5, 0.6)` a −24, a cada 8–15 s |

### 5.4 Pós-produção e formato final

Para cada arquivo, nesta ordem:

1. **Corte** do silêncio no início (ataque em ≤ 5 ms do começo do arquivo).
   Fade-out de 10–30 ms. O silêncio inicial atrasa a resposta e desalinha o
   háptico.
2. **Passa-alta** de 120 Hz (150 Hz em UI) [I]: o alto-falante de celular não
   reproduz isso, e o grave inaudível só come headroom.
3. **Vozes**: cortar cada sílaba em zero-crossing, medir a f0 mediana (por
   exemplo autocorrelação), **re-afinar** para a nota base da espécie com
   `rubberband`/`librosa.effects.pitch_shift` e guardar 6–8 sílabas por espécie.
4. **Loops**: conferir a emenda (crossfade de 50 ms se houver clique) e tocar
   10× seguidas na audição.
5. **Calibração** de loudness pelo máximo momentâneo (seção 4.4), com
   `ffmpeg -af ebur128=framelog=verbose` (como na auditoria) e ganho
   aplicado. Pico verdadeiro ≤ −1 dBTP (`ebur128=peak=true`).
6. **Formato**:
   - One-shots (< 2 s): **WAV PCM 16 bits mono 48 kHz**. Decodificação zero e
     latência mínima no SoundPool. **[I]** 48 kHz é a taxa nativa da maioria dos
     mixers Android e da saída WAV do ElevenLabs, o que evita reamostragem.
   - Bancos de voz: WAV mono 48 kHz (sílabas de ~100 ms, total pequeno).
   - Ambientes e loops de afago: **OGG Vorbis**, q≈5, 48 kHz, **estéreo** nos
     ambientes e mono no afago. OGG emenda loop sem o intervalo de enchimento do
     MP3 [I].
   - Notificações: `android/app/src/main/res/raw/baru_fim.ogg` e
     `baru_chamado.ogg`, em minúsculas e sem hífen (regra de nome de recurso do
     Android).
   - **[I] Orçamento de tamanho:** ~40 one-shots × ~60 KB + 9 × 8 sílabas ×
     ~10 KB + 5 loops × ~400 KB (OGG) ≈ **5 MB**. Se pesar, os ambientes podem ir
     para download opcional depois.
7. **Nomes**: `assets/sons/<familia>/<evento>_<variação>.wav`, por exemplo
   `assets/sons/recompensa/missao_1.wav` e `assets/sons/voz/otter/silaba_3.wav`.

### 5.5 Como trocar no app

Em ordem de entrega. Cada passo é independente e pode ir em PR separado.

**Passo 0: corrigir o foco e o silencioso (P, já).**
Em `app.dart:71`, antes de `arma()`:

```dart
await AudioPlayer.global.setAudioContext(AudioContext(
  android: const AudioContextAndroid(
    usageType: AndroidUsageType.game,          // volume de mídia: as teclas de volume funcionam
    contentType: AndroidContentType.sonification,
    audioFocus: AndroidAudioFocus.none,        // nunca pausa a música da pessoa
  ),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient), // respeita a chave e mistura
));
```

Mais um `MethodChannel('baru/som')` com `getRingerMode()` (`AudioManager`):
`RINGER_MODE_SILENT`/`VIBRATE` → `valeTocar` devolve `false`. E apagar o
comentário falso de `som_service.dart:11-13`. **[I]** Escolhi `game` e não
`assistanceSonification` porque, até onde sei do AOSP, o segundo vai para o
volume de sistema/toque e as teclas de volume do app deixariam de controlar o
som. Valide nos dois sentidos em aparelho.

**Passo 1: catálogo com categorias e variações (M).**
Trocar o `enum SomDoBaru` + `'sons/$name.wav'` (`som_service.dart:24-51`) por
uma definição:

```dart
enum Camada { heroi, recompensa, voz, primario, secundario, ambiente }
class DefSom {
  const DefSom(this.arquivos, this.camada, {this.jitterCents = 0, this.ganhoDb = 0, this.intervaloMin = const Duration(milliseconds: 300), this.haptico});
  final List<String> arquivos;   // round-robin, nunca repete o último
  final Camada camada;
  final double jitterCents;      // 0 para tonais; 30–60 para foley e voz
  final double ganhoDb;          // ajuste fino; o nível vem da masterização
  final Duration intervaloMin;   // por som, não global
  final Haptico? haptico;        // disparado no mesmo frame
}
```

**Passo 2: pool de players (M).** Trocar o player único
(`som_service.dart:168`) por 6 `AudioPlayer` em `PlayerMode.lowLatency`,
pré-carregados com `setSource`, em round-robin. A altura varia com
`setPlaybackRate(pow(2, cents/1200))` **antes** do `play`: o plugin passa o
`rate` ao `SoundPool.play` (`SoundPoolPlayer.kt:179-186`), e no SoundPool rate
muda a altura. Remover o limitador global de 400 ms
(`som_service.dart:93-104`) em favor do `intervaloMin` por som. **[I]** Se a
polifonia ou a latência não bastarem, avaliar `flutter_soloud`. Não verifiquei
esse pacote nesta rodada.

**Passo 3: motor de voz (M).** `VozDoBicho.fala(especie, humor, nSilabas)`
agenda as sílabas com `Timer` usando o contorno da seção 4.7 e expõe um
`ValueNotifier<int>` de "sílaba atual" para o `pet.dart` abrir a boca em
sincronia (o mesmo princípio dos visemes do Duolingo, [F]).

**Passo 4: háptico nativo (P–M).** `MethodChannel('baru/haptico')` em
`MainActivity.kt` com os padrões da seção 4.8 e fallback. Substituir as 11
chamadas `HapticFeedback.*`. Adicionar a chave "Vibração" em Ajustes nos 4
idiomas (regra 2).

**Passo 5: ligar os eventos mudos (P cada).** Os pontos estão na seção 4.6
(`state.dart:1789` início, `:1999` desistência, `:1732` compra, `:1909`
raiz…). A **sequência pós-sessão** (F3 → E1 → P3 → U5) vira uma pequena fila
com atrasos, sincronizada com a tela de resultado (relatório de agosto, R7).

**Passo 6: notificações (P).** Canais novos `baru_fim_v1` e
`baru_lembretes_v2` com `sound: RawResourceAndroidNotificationSound('baru_fim')`
e o equivalente para o chamado. Apagar os canais antigos com
`deleteNotificationChannel`. A conclusão em segundo plano **não** chama o
`SomService` (checar `AppLifecycleState.resumed`).

**Passo 7: ambiente (M).** `AmbienteService` com 2 players `mediaPlayer` em
`ReleaseMode.loop` para o crossfade, volume próprio, ligado ao período
(`models.dart:56-66`) e ao cenário equipado.

**Passo 8: Ajustes (P).** "Sons: Tudo / Só momentos / Desligado", "Voz do
bicho", "Vibração", "Som ambiente" (+ volume) e "Ambiente durante o foco". Tudo
nos 4 idiomas e persistido como a chave `som` atual (`state.dart:497-498`,
migration da `som` em `DECISIONS.md:747`).

**Testes a atualizar:** os testes do `SomService` (limitador e espião) passam a
cobrir: intervalo por som, round-robin sem repetir o último, nada tocando com
ringer silencioso (canal mockado), nada tocando com `running == true` (exceto
F3), nada tocando fora do `resumed`, e o mapa evento → `DefSom` completo
(nenhum evento da tabela 4.6 sem entrada).

### 5.6 Validação (critérios de aceite)

1. **Audição humana** por 3 pessoas, em 2 aparelhos (um de entrada, um médio),
   alto-falante e fone. Cada som é aprovado se ≥ 2 de 3 associarem ao evento
   certo numa lista cega de 8 eventos.
2. **Teste da música:** com Spotify tocando, tocar no bicho 10×, resgatar missão
   e concluir sessão. A música **não pausa** e no máximo abaixa
   momentaneamente. Hoje, pela leitura do código e da doc, ela para [I].
3. **Teste do silencioso:** com o celular em silencioso/vibrar, nenhum som do
   app, e o háptico presente.
4. **Medição:** `ebur128` de todos os arquivos dentro de ±1 LU do alvo da camada
   (seção 4.4), true peak ≤ −1 dBTP, latência toque→som ≤ 50 ms na gravação de
   tela com áudio [I].
5. **Fadiga:** 20 toques seguidos no bicho sem dois sons idênticos consecutivos
   (verificável pelo espião do serviço).

---

## 6. As 10 recomendações principais (priorizadas)

| # | O quê | Por quê (evidência) | Como | Esforço | Impacto | Aceite |
|---|---|---|---|---|---|---|
| 1 | **Parar de pausar a música da pessoa e respeitar o silencioso** | [O] Contexto padrão `media` + `GAIN`, nenhum `AudioContext` em `lib/`. [F] Android: `GAIN` faz o outro app sumir. Comentário falso em `som_service.dart:11-13` | `AudioPlayer.global.setAudioContext(... game, sonification, focus none)` + checagem de `getRingerMode` | P | Alto (bug de confiança) | Critério 5.6-2 e 5.6-3 |
| 2 | **Dar voz própria a cada uma das 9 espécies** (Animalese) | [O] Toque, humor e fala mudos ou genéricos. [F] Animalese: altura por espécie e humor. [F] Duolingo: cada personagem com voz | Banco de sílabas EL re-afinado + motor de contorno (4.7) | M | Alto (o pedido do dono: "sem sentido") | 9 vozes distinguíveis em teste cego (≥ 2/3 acertam a espécie entre 3 opções) |
| 3 | **Refazer o herói da sessão concluída** e pôr a hierarquia em ordem | [O] `fim` é 4,3 dB mais baixo que `conquista`, quinta parada. [F] Material: loudness por hierarquia; hero = momento do propósito | F3 (motivo + acorde + voz feliz), calibração da 4.4 | P | Alto | F3 é o mais alto do catálogo (±1 LU do nível), e 5.6-1 aprovado |
| 4 | **Uma tonalidade e um motivo** (Fá pentatônica, A-C-F) | [O] 5 tonalidades e `toque` desafinado. [F] Material: mesma tonalidade, "peer sounds" relacionados | Re-síntese local de todos os tonais (5.3) | P | Médio-alto | Todos os tonais só com notas da tabela 4.3 (verificável por FFT) |
| 5 | **Trocar senos por madeira, água, folha e terra** | [O] Planura 0,002–0,004 e 2 parciais. [O] Habitat de lago e madeira. [F] Material: "honest to brand" | Paleta 4.2, síntese + EL | M | Alto | Nenhum arquivo final com < 3 parciais por nota tonal |
| 6 | **Ligar os eventos mudos** (início, desistência sem culpa, compra, item, folhas, raiz, congelamento, contagem) | [O] Seção 2.3, S8. Relatório de agosto R7 | Mapa 4.6, passo 5 | M | Alto | Cada linha da 4.6 tem entrada no catálogo e teste |
| 7 | **Variações e fim do limitador global** | [O] 1 arquivo por evento, player único, 400 ms global. [F] Material e Apple: variar altura e timbre | Round-robin + jitter de cents + pool de 6 players | M | Médio | 5.6-5 |
| 8 | **Háptico composto e alinhado às notas** + chave "Vibração" | [F] Android: co-design, evitar buzzy, usar constantes e composições. [O] Flutter `heavyImpact` = `CONTEXT_CLICK` | Canal `baru/haptico` (4.8) | P–M | Médio | Cada som de herói tem padrão com primitivas no tempo das notas, e fallback testado em API < 30 |
| 9 | **Separar "bom te ver" do som de nível** e não usar herói em rotina | [O] `conquista` toca toda chegada diária. [F] Material: hero infrequente | P9 com voz + díade | P | Médio | `conquista`/P6 só toca em nível (espião) |
| 10 | **Fim de sessão em segundo plano e lembretes com som próprio** | [O] Som padrão do sistema + `fim` por cima de outro app | Canais novos com `res/raw`, nenhum `SomService` fora do `resumed` | P | Médio | Em segundo plano só soa a notificação, e na frente só F3 |

Depois das 10: ambiente opcional por período (4.9), contagem tonal (U5) e trilha
musical (fora desta fase).

## 7. O que não fazer

- **Não** tocar som durante a sessão de foco, na sobreposição ou na navegação.
- **Não** usar som de perda: nada para raiz que não cresceu, nada de buzzer,
  "deflated tone" ou gemido. Saudade é alegria do reencontro.
- **Não** usar `AUDIOFOCUS_GAIN` para efeito curto. Nunca pausar a música da
  pessoa.
- **Não** usar moeda metálica, fanfarra, arcade ou sininho brilhante. Destoam do
  mundo de madeira, e moeda metálica desmente a moeda-folha.
- **Não** usar chamados reais de animal crus nem TTS com palavras para a voz.
- **Não** subir o volume no código (`volume: 0.55` → 1,0 com master certo).
  Nível é masterização.
- **Não** ligar ambiente nem música por padrão (WCAG 1.4.2, foco).
- **Não** usar `REJECT`, `createOneShot` ou vibração longa.
- **Não** deixar o mesmo arquivo tocar duas vezes seguidas.
- **Não** publicar nenhum som sem audição humana em aparelho. Os atuais saíram
  sem ninguém ouvir (`CHANGELOG.md:413`).

## 8. Riscos e dúvidas em aberto

1. **Nada aqui foi ouvido.** Medições e protótipos não substituem o ouvido. O
   passo 5.6-1 é obrigatório antes de trocar qualquer arquivo.
2. **S1 (música pausando)** foi deduzido do código do plugin e da documentação
   do Android, não reproduzido em aparelho. A probabilidade é alta, e testar
   leva 2 minutos.
3. **Hipótese do 2º toque mudo** em `lowLatency` (seção 2.3, S7): plausível pela
   leitura de `WrappedPlayer.kt`, não confirmada.
4. **`game` × `assistanceSonification`**: a escolha afeta qual tecla de volume
   controla o som e se o silencioso zera sozinho. Validar nos dois.
5. **Licença ElevenLabs**: uso comercial dos efeitos depende do plano. Não
   verifiquei os termos nesta rodada.
6. **Duração mínima do ElevenLabs**: a doc diverge (0,1 s × 0,5 s). Pedir 0,5 s
   e cortar.
7. **Nível de API das primitivas hápticas**: conferir na referência antes de
   codificar. Muitos aparelhos de entrada não têm primitivas, e o fallback tem
   de ser bom sozinho.
8. **Tamanho do APK**: ~5 MB a mais, principalmente pelos ambientes. Se pesar,
   ambiente vira download sob demanda.
9. **Duolingo, Finch, Nintendo**: não achei fonte primária sobre a identidade
   sonora deles. As decisões aqui se apoiam no Material, na Apple, no Android e
   no Animalese documentado por fã-wiki. Se o dono quiser "como o Duolingo faz",
   é preciso uma pesquisa nova com orçamento de busca, ou engenharia reversa
   (gravar o app e medir como fiz aqui).
10. **Regras do contrato**: nenhuma recomendação exige mudar regra do
    `PRODUCT.md`. A voz sem palavras atende a regra 2 sem tradução. Os sons de
    desistência e saudade foram desenhados para a regra 1. Nenhum som ou voz é
    vendido: as vozes vêm com a espécie, e espécie só pela trilha, nunca por
    dinheiro.

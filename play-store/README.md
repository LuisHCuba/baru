# Material da Google Play

Tudo o que a ficha do Baru na Google Play pede, gerado a partir do app de
verdade: as telas são renderizadas pela árvore de widgets, os bichos e o ícone
saem do mesmo `CustomPainter` que o app usa. Nada aqui é mockup.

```
play-store/
├── ficha.md              textos da ficha (pt-BR, en-US, es-419) + o que o Console pergunta
├── confere_ficha.py      confere os limites de caracteres da ficha
├── loja/                 ⇢ O QUE SOBE NO PLAY CONSOLE
│   ├── icone-512.png         ícone 512 × 512, PNG 32 bits
│   ├── og-1200x630.png       imagem social (a mesma do site)
│   └── <pt|en|es>/
│       ├── captura-1..8.png  capturas do telefone, 1080 × 1920 (9:16), sem alfa
│       └── destaque-1024x500.png  recurso gráfico, sem alfa
├── video/saida/          ⇢ O VÍDEO PROMOCIONAL
│   ├── baru-vertical.mp4     1080 × 1920, para Reels, Shorts, TikTok, Status
│   └── baru-horizontal.mp4   1920 × 1080, para o YouTube da ficha
├── telas/<pt|en|es>/     telas cruas do app, 1080 × 2400, inclusive os 9 bichos em 4 horários
├── arte/                 ícone, os 9 companheiros em 4 humores (1200 × 960, transparentes)
│                         e o habitat nos 4 momentos do dia (1488 × 1184)
├── graficos/             o HTML das peças e o script que as fotografa
└── capturar.sh           regenera telas/ a partir do app
```

## Onde está publicado

- Página: https://lhcx.tech/solucoes/baru/ (mídia em `midia.lhcx.tech/site/baru/`)
- Pacote para a Play: https://midia.lhcx.tech/site/baru/loja/Baru-GooglePlay.zip
- Comercial em qualidade cheia: `midia.lhcx.tech/site/baru/loja/baru-comercial-v1-{horizontal-1920x1080,vertical-1080x1920}.mp4`

## Subir na Play

1. **Ícone:** `loja/icone-512.png`.
2. **Recurso gráfico:** `loja/pt/destaque-1024x500.png` (e as versões `en`/`es`
   nas traduções da ficha).
3. **Capturas do telefone:** `loja/pt/captura-1.png` a `captura-8.png`, nessa
   ordem. A Play aceita até 8 por tipo de aparelho; com 4 ou mais em 1080 px o
   app fica elegível para as áreas de promoção.
4. **Vídeo:** a Play só aceita um link do YouTube. Suba
   `video/saida/baru-horizontal.mp4` como **público ou não listado**, com
   **monetização desligada** e **sem restrição de idade**, e cole a URL do vídeo
   (não de playlist) no campo de vídeo da ficha. Só os primeiros 30 s tocam
   sozinhos na loja; o app aparece já no segundo 3.
5. **Textos:** `ficha.md`.

Tablet (7" e 10") não foi gerado: o app é desenhado para telefone em retrato.

## Regenerar

Telas do app (precisa do Flutter 3.35.2):

```
play-store/capturar.sh pt en es
cd baru_app && CAPTURAS=1 flutter test test/arte_loja_test.dart   # ícone, bichos, habitats
```

O habitat lê a hora do relógio, então `capturar.sh` escolhe o fuso (`TZ`) para
cada momento do dia. Chinês fica de fora: o `flutter_tester` não tem fonte CJK
e a tela sairia em quadradinhos.

Peças da loja (precisa de Node com Playwright/Chromium):

```
cd play-store/graficos && node render.mjs pt en es
```

O texto de cada captura está no topo do `<script>` de `graficos/peca.html`.

Vídeo (Node + Playwright, ffmpeg, Python com numpy):

```
play-store/video/build.sh
```

## O vídeo

37,5 s, 30 fps, as duas proporções saem do mesmo `video/scene.html` (cada
quadro é uma função do tempo; `render.mjs` fotografa e o ffmpeg codifica).

| Trecho | O que aparece |
|---|---|
| 0–3 s | clipe realista: a mão larga o celular cheio de notificações na mesa |
| 3–7 s | a cena se abre num círculo; o Baru pula para dentro e cresce em "cresce" |
| 7–10 s | a sessão de foco; folhas explodem do celular em "folhas" |
| 10–13 s | itens caindo no habitat e o dia passando: 06:00, 12:00, 18:00, 22:00 |
| 13–19 s | tempo de tela por categoria; a barra do áudio é riscada em "não entra" |
| 19–25 s | missões, a trilha contando até 22 e os nove companheiros entrando um a um |
| 25–31 s | a noite cai, o Baru sente falta; em "culpa" amanhece e sobem corações |
| 31–37 s | ícone, marca, "Foco sem culpa", selo "Em breve na Google Play" |

**Áudio**

- **Narração:** ElevenLabs `eleven_v4`, voz *Roberta – Casual Sales* (pt-BR).
  Quatro tomadas em `video/assets/vo/`; a usada é a 2 (`narracao.mp3`). Os
  tempos de cada palavra (`narracao.words.json`) vêm da transcrição da própria
  tomada e conduzem legenda e cena. O transcritor ouve "barulho" onde ela diz
  "Baru" — a legenda é escrita à mão, então isso não aparece no vídeo; vale
  ouvir a pronúncia antes de publicar.
- **Trilha:** ElevenLabs Music v2.5, instrumental de 40 s (`trilha1.mp3`; a
  `trilha2.mp3` é a alternativa). 5 dB abaixo sob a voz e mais 6 dB na parte
  da noite.
- **Efeitos do ElevenLabs:** notificações, celular na mesa, o bicho, recompensa.
- **Efeitos sintetizados** em `audio.py`: whooshes das transições, os nove pops
  em escala, o tique-tique do 22.
- **Master:** −14 LUFS integrado.

**Clipe realista:** Veo 3.1 Fast pelo ElevenLabs, 4 s, 1080 × 1920, sem áudio.
No horizontal ele entra como cartão vertical sobre uma cópia desfocada.

**Créditos do ElevenLabs usados:** narração ≈ 2.212 (4 tomadas), trilha ≈ 1.200
(2 variações), efeitos ≈ 53, clipe ≈ 2.424. Total ≈ 5.900 créditos. Tudo no
fluxo "Baru — comercial Google Play" do ElevenLabs.

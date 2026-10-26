# Simulador

Percorre o build web do Baru como uma pessoa faria — onboarding, home, sessão
de foco, resultado e cenas, desistência, missões, loja, crescimento, abas,
ajustes, paywall, idioma — e guarda capturas, tiras de quadros e o console.

O relógio da página é controlado pelo Playwright (`page.clock`, pausado
depois de cada carga): o tempo do app só anda quando o script manda, então
cada quadro de uma tira mostra a animação num instante exato (ex.: 0, 100,
200 ms…), sem depender da velocidade da máquina. Uma sessão de 25 "min" do
relógio rápido custa 25 s de relógio do app, não de espera real.

A semântica do Flutter é ligada para achar os elementos por rótulo. Com ela
ligada, um clique num nó vira a *ação* de tocar dele (como faria um leitor de
tela); para gestos que dependem do ponto exato (cavar a toca) o script usa
`sim.comDedo(...)`, que deixa o clique passar direto para o desenho.

## Pré-requisitos

- Node com `playwright` e o Chromium dele (não precisa `playwright install`
  se já houver); `python3` com Pillow para montar as tiras.
- O build web servido localmente, de preferência com o relógio rápido
  (1 minuto da sessão = 1 segundo):

```sh
flutter build web --release --dart-define=BARU_RELOGIO_RAPIDO=true
cd build/web && python3 -m http.server 8765 --bind 127.0.0.1
```

## Rodar

```sh
NODE_PATH=$(npm root -g) node tool/simulador/simula.js --saida /tmp/sim-412
# trechos-chave em telas menores (onboarding, home, 1ª sessão, desistência):
SIM_CURTA=1 NODE_PATH=$(npm root -g) node tool/simulador/simula.js --largura 360 --altura 640 --saida /tmp/sim-360
SIM_CURTA=1 NODE_PATH=$(npm root -g) node tool/simulador/simula.js --largura 320 --altura 640 --saida /tmp/sim-320
```

Opções: `--url` (padrão `http://127.0.0.1:8765/index.html`), `--largura`,
`--altura`, `--dpr` (padrão 2), `--etapas onboarding,home,...` (só essas),
`--perfil DIR` (pasta do perfil do navegador; é apagada no início).

A jornada completa leva ~10–15 min de tempo real num Chromium headless com
WebGL por software; a curta, ~4 min.

## O que sai

- `NNN-nome.png`: capturas de tela, na ordem da jornada.
- `quadros/NNN-nome.png`: tira com os quadros de uma animação, com o
  instante de cada um; os quadros soltos ficam em `quadros/NNN-nome/`.
- `jornada.log`: cada passo, a rota (`#/...`) e os nós de semântica visíveis
  em cada captura; também os sons que o app pediu (`som pedido: x.wav`).
- `console.log`: mensagens e erros do console da página.

Limites: o voltar do sistema na web é o voltar do navegador (não é o
`popRoute` do Android); recarregar a página com o relógio pausado preserva o
tempo do app. As etapas estão em `jornada.js`. Se uma falhar, a captura `falha-<etapa>` e
os nós da tela vão para o log e a próxima etapa segue de onde o app ficou.

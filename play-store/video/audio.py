"""Mixagem do comercial: narração + trilha + efeitos, em 48 kHz estéreo.

Fontes:
- assets/vo/narracao.mp3      ElevenLabs (eleven_v4, voz Roberta), tomada 2 de 4
- assets/musica/trilha1.mp3   ElevenLabs Music v2.5, instrumental de 40 s
- assets/sfx/*.mp3            ElevenLabs Sound Effects v2 (notificações, celular
                              na mesa, o bicho, recompensa)
- o resto (whoosh, pops, tique) é sintetizado aqui, para poupar créditos.

Os instantes saem das palavras da narração (assets/vo/narracao.words.json),
os mesmos que a cena usa. Saída: build/mix.wav, já em -14 LUFS.
"""
import json
import pathlib
import subprocess

import numpy as np

AQUI = pathlib.Path(__file__).parent
SR = 48000
DUR = 37.5
OFF = 0.5


def carrega(caminho):
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(caminho), '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-'],
        capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).copy()


def db(x):
    return 10 ** (x / 20)


mix = np.zeros((int(SR * DUR), 2), np.float32)


def poe(som, t, ganho_db=0.0):
    i = int(t * SR)
    if i >= len(mix):
        return
    n = min(len(som), len(mix) - i)
    mix[i:i + n] += som[:n] * db(ganho_db)


words = json.loads((AQUI / 'assets/vo/narracao.words.json').read_text())
W = lambda i: words[i][0] + OFF  # noqa: E731
T = dict(conheca=W(8), baru=W(10), cresce=W(14), cada=W(20), folhas=W(25), itens=W(26), habitat=W(29),
         seu=W(37), honest=W(44), podcast=W(48), naoEntra=W(51), missoes=W(53), trilha=W(56),
         vinte=W(58), nove=W(61), falhar=W(65), culpa=W(78), fim=W(79), selo=W(83))

# ---------- narração ----------
vo = carrega(AQUI / 'assets/vo/narracao.mp3')
poe(vo, OFF, 0)

# ---------- trilha, com ducking sob a voz e respiro na parte da noite ----------
mus = carrega(AQUI / 'assets/musica/trilha1.mp3')[: len(mix)]
env = np.ones(len(mus), np.float32) * db(-13)
voz = np.abs(vo).mean(axis=1)
janela = int(.25 * SR)
voz_suave = np.convolve(voz, np.ones(janela) / janela, mode='same')
ativa = np.zeros(len(mus), np.float32)
ativa[int(OFF * SR):int(OFF * SR) + len(voz_suave)] = (voz_suave > .01)[: max(0, len(mus) - int(OFF * SR))]
ativa = np.convolve(ativa, np.ones(int(.3 * SR)) / int(.3 * SR), mode='same')
env *= db(-5 * ativa)                        # 5 dB a menos enquanto ela fala
t_ax = np.arange(len(mus)) / SR
noite = np.clip((t_ax - (T['falhar'] - .5)) / .6, 0, 1) * np.clip(((T['culpa'] + .3) - t_ax) / .5, 0, 1)
env *= db(-6 * noite)                        # a parte da saudade respira
env *= np.clip((DUR - t_ax) / 1.2, 0, 1)     # sai junto com o último quadro
mix[: len(mus)] += mus * env[:, None]

# ---------- efeitos do ElevenLabs ----------
sfx = lambda n: carrega(AQUI / f'assets/sfx/{n}.mp3')  # noqa: E731
poe(sfx('notificacoes-a'), 0.1, -11)
poe(sfx('mesa-b'), 1.75, -2)
poe(sfx('bicho-a'), T['baru'] + .05, -5)
poe(sfx('recompensa-a'), T['folhas'] - .02, 2)
poe(sfx('recompensa-b'), T['cresce'] + .05, -4)
poe(sfx('recompensa-b'), T['fim'] - .05, -5)
poe(sfx('bicho-b'), T['culpa'] + .1, -7)


# ---------- sintetizados ----------
def whoosh(dur=.45, grave=False):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ruido = np.random.default_rng(7).standard_normal(n).astype(np.float32)
    # passa-banda que varre: filtro de um polo com corte subindo
    corte = np.linspace(.02, .25, n) if not grave else np.linspace(.01, .08, n)
    y = np.zeros(n, np.float32)
    a = 0.0
    for i in range(n):
        a += corte[i] * (ruido[i] - a)
        y[i] = a
    y -= np.convolve(y, np.ones(40) / 40, mode='same')
    env = np.sin(np.pi * t / dur) ** 2
    y = y * env / (np.abs(y).max() + 1e-9)
    return np.stack([y * .9, y], 1)


def pop(f0=520, dur=.12):
    t = np.arange(int(dur * SR)) / SR
    f = f0 * (1 + 1.4 * np.exp(-t * 40))
    fase = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(fase) * np.exp(-t * 28)
    return np.stack([y, y], 1).astype(np.float32)


def tique(f=1800, dur=.03):
    t = np.arange(int(dur * SR)) / SR
    y = np.sin(2 * np.pi * f * t) * np.exp(-t * 160)
    return np.stack([y, y], 1).astype(np.float32)


for t_w in [T['conheca'] - .3, T['cada'] - .3, T['itens'] - .25, T['seu'] - .3, T['missoes'] - .3,
            T['trilha'] - .25, T['nove'] - .35, T['falhar'] - .45]:
    poe(whoosh(), t_w, -16)
poe(whoosh(.9, grave=True), T['fim'] - .35, -12)

# os nove entram um a um
notas = [523, 587, 659, 698, 784, 880, 988, 1047, 1175]
for i, f in enumerate(notas):
    poe(pop(f), T['nove'] - .25 + i * .12 + .08, -15)

# o 22 contando
n_tiques = 12
for i in range(n_tiques):
    k = i / (n_tiques - 1)
    poe(tique(1500 + 900 * k), T['trilha'] + .1 + (1 - (1 - k) ** 3) * (T['vinte'] + .25 - T['trilha'] - .1), -18)

# itens caindo na cena
for i in range(4):
    poe(pop(300 + i * 60, .18), T['itens'] + .15 + i * .22, -12)

# a barra do áudio sendo riscada
poe(whoosh(.3), T['naoEntra'] - .05, -18)
poe(pop(880, .1), T['naoEntra'] + .3, -12)

# ---------- master ----------
tmp = AQUI / 'build' / 'mix_bruto.wav'
tmp.parent.mkdir(exist_ok=True)
pico = np.abs(mix).max()
mix_n = (mix / max(pico, 1e-9) * .9).astype(np.float32)
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '2', '-i', '-', str(tmp)],
               input=mix_n.tobytes(), check=True)
# loudnorm em duas passadas: a primeira mede, a segunda aplica ganho linear
medida = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(tmp), '-af',
                         'loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json', '-f', 'null', '-'],
                        capture_output=True, text=True).stderr
m = json.loads(medida[medida.rindex('{'):medida.rindex('}') + 1])
filtro = ('loudnorm=I=-14:TP=-1.5:LRA=11:linear=true:'
          f"measured_I={m['input_i']}:measured_TP={m['input_tp']}:measured_LRA={m['input_lra']}:"
          f"measured_thresh={m['input_thresh']}:offset={m['target_offset']}")
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(tmp), '-af', filtro, '-ar', str(SR),
                str(AQUI / 'build' / 'mix.wav')], check=True)
print('build/mix.wav', {k: round(v, 2) for k, v in T.items()})

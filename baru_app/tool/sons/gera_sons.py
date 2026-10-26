#!/usr/bin/env python3
"""Gera os sons tonais do Baru por síntese local.

Receitas do laudo 04 (docs/pesquisa/04-som.md, §4 e §5.3): três materiais
(madeira afinada — marimba e kalimba —, madeira seca e água), uma tonalidade
só (Fá maior pentatônica: F G A C D) e um motivo (Lá–Dó–Fá). Reprodutível:
semente fixa, sem rede. Rodar da raiz do app:

    python3 tool/sons/gera_sons.py

Grava WAV PCM 16 bits mono 48 kHz em assets/sons/ e calibra cada arquivo
pelo máximo de loudness momentâneo (EBU R128 M, via ffmpeg) para o alvo da
hierarquia do laudo (§4.4), com pico ≤ −1 dBFS.

Aviso honesto: este ambiente não tem saída de áudio. Os arquivos são
medidos (notas por FFT, loudness por ffmpeg), não ouvidos. A primeira
audição em aparelho é parte do aceite (laudo 04, §5.6).
"""
import os
import re
import subprocess
import sys
import wave

import numpy as np
from scipy.signal import butter, sosfilt

SR = 48000
rng = np.random.default_rng(20261026)

# Fá maior pentatônica, A4 = 440 Hz (laudo 04, §4.3).
N = {
    'F3': 174.61, 'G3': 196.00, 'A3': 220.00, 'C4': 261.63, 'D4': 293.66,
    'F4': 349.23, 'G4': 392.00, 'A4': 440.00, 'C5': 523.25, 'D5': 587.33,
    'F5': 698.46, 'G5': 783.99, 'A5': 880.00, 'C6': 1046.50, 'D6': 1174.66,
    'F6': 1396.91,
}


def t(d):
    return np.arange(int(SR * d)) / SR


def marimba(f, d=0.6, decai=0.22):
    """Barra de madeira: parciais 1 : 4 : ~10, os agudos morrem antes."""
    x = t(d)
    s = (np.sin(2 * np.pi * f * x) * np.exp(-x / decai)
         + 0.35 * np.sin(2 * np.pi * 4 * f * x) * np.exp(-x / (decai / 4))
         + 0.12 * np.sin(2 * np.pi * 9.9 * f * x) * np.exp(-x / (decai / 9)))
    baqueta = sosfilt(butter(2, [2000, 6000], 'bandpass', fs=SR, output='sos'),
                      rng.standard_normal(len(x))) * np.exp(-x / 0.004) * 0.25
    return s + baqueta


def kalimba(f, d=0.8, decai=0.35):
    """Lâmina: o "plim" inarmônico ~5,93× bem curto em cima da nota."""
    x = t(d)
    return (np.sin(2 * np.pi * f * x) * np.exp(-x / decai)
            + 0.25 * np.sin(2 * np.pi * 5.93 * f * x) * np.exp(-x / 0.03)
            + 0.08 * np.sin(2 * np.pi * 2 * f * x) * np.exp(-x / (decai / 2)))


def madeira(f=900, d=0.08):
    """Bloco de madeira seca: ruído em banda estreita + ressonância."""
    x = t(d)
    n = rng.standard_normal(len(x))
    return (sosfilt(butter(2, [f * 0.8, f * 1.25], 'bandpass', fs=SR, output='sos'), n)
            * np.exp(-x / 0.012) * 4
            + 0.4 * np.sin(2 * np.pi * f * x) * np.exp(-x / 0.02))


def gota(f0=900, f1=1900, d=0.12):
    """Bolha d'água: seno com glissando ascendente rápido."""
    x = t(d)
    fr = f0 + (f1 - f0) * (1 - np.exp(-x / 0.02))
    return np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-x / 0.03)


def terra(d=0.25, centro=380, largura=1.6):
    """Terra/folha seca sintética: ruído marrom em banda, ataque curto.

    Ponto de partida até a camada gravada do ElevenLabs (laudo 04, §5.2).
    Grave e abafado de propósito: o `cavar` antigo era chiado a 6,3 kHz.
    """
    x = t(d)
    branco = rng.standard_normal(len(x))
    marrom = np.cumsum(branco)
    marrom -= np.convolve(marrom, np.ones(400) / 400, mode='same')
    banda = sosfilt(butter(2, [centro / largura, centro * largura], 'bandpass',
                           fs=SR, output='sos'), marrom)
    env = (1 - np.exp(-x / 0.004)) * np.exp(-x / (d / 4))
    return banda / (np.max(np.abs(banda)) + 1e-9) * env


def folha(d=0.35):
    """Farfalhar curto de folha: ruído em 2,5–9 kHz com grãos."""
    x = t(d)
    n = sosfilt(butter(2, [2500, 9000], 'bandpass', fs=SR, output='sos'),
                rng.standard_normal(len(x)))
    graos = (rng.random(len(x)) < 0.004).astype(float)
    graos = np.convolve(graos, np.exp(-np.arange(240) / 40), mode='same')
    env = np.exp(-x / (d / 3)) * (0.35 + graos)
    return n * env


def mix(partes, d):
    """Soma camadas (sinal, início em s, ganho em dB) num buffer de d s."""
    out = np.zeros(int(SR * d))
    for sinal, em, db in partes:
        i = int(SR * em)
        fim = min(len(out), i + len(sinal))
        out[i:fim] += sinal[:fim - i] * (10 ** (db / 20))
    return out


def fecha(sinal, passa_alta=120):
    """Pós-produção (§5.4): passa-alta, ataque no começo, fade de 20 ms."""
    sinal = sosfilt(butter(2, passa_alta, 'highpass', fs=SR, output='sos'), sinal)
    limiar = np.max(np.abs(sinal)) * 0.02
    inicio = int(np.argmax(np.abs(sinal) > limiar))
    sinal = sinal[max(0, inicio - int(SR * 0.002)):]
    fade = int(SR * 0.02)
    sinal[-fade:] *= np.linspace(1, 0, fade)
    return sinal


def grava(caminho, sinal):
    pico = np.max(np.abs(sinal)) + 1e-9
    pcm = np.int16(np.clip(sinal / pico * 0.5, -1, 1) * 32767)
    with wave.open(caminho, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def loudness_max_m(caminho):
    """Máximo momentâneo (LUFS-M) medido pelo ffmpeg."""
    r = subprocess.run(
        ['ffmpeg', '-hide_banner', '-nostats', '-i', caminho, '-af',
         'apad=pad_dur=0.5,ebur128', '-f', 'null', '-'],
        capture_output=True, text=True)
    vals = [float(m) for m in re.findall(r' M:\s*(-?[\d.]+)', r.stderr)]
    return max(vals) if vals else -70.0


def calibra(caminho, sinal, alvo):
    """Ajusta o ganho para o alvo LUFS-M, respeitando pico ≤ −1 dBFS."""
    grava(caminho, sinal)
    medido = loudness_max_m(caminho)
    ganho_db = alvo - medido
    with wave.open(caminho, 'rb') as w:
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16) / 32767
    novo = pcm * 10 ** (ganho_db / 20)
    teto = 10 ** (-1 / 20)
    if np.max(np.abs(novo)) > teto:
        novo *= teto / np.max(np.abs(novo))
    with wave.open(caminho, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(np.int16(np.clip(novo, -1, 1) * 32767).tobytes())
    return loudness_max_m(caminho)


# --- o catálogo ----------------------------------------------------------
#
# Alvos de LUFS-M (laudo 04, §4.4): herói −14, herói menor −16, voz −18,
# primário −19, secundário −24. Hoje o volume do player é 1,0: o nível
# vem daqui, não do código.

def sons():
    s = {}

    # F3 — sessão concluída: o motivo em marimba + acorde de kalimba + gota.
    s['fim'] = (mix([
        (marimba(N['A4'], 0.9, 0.28), 0.00, 0),
        (marimba(N['C5'], 0.9, 0.28), 0.12, 0),
        (marimba(N['F5'], 1.3, 0.45), 0.24, 0),
        (kalimba(N['A5'], 1.4, 0.5), 0.24, -4),
        (kalimba(N['C6'], 1.4, 0.5), 0.26, -5),
        (gota(), 0.05, -14),
    ], 1.9), -14)

    # P6 — nível: o motivo + acorde com o topo em F6 + marimba grave.
    s['conquista'] = (mix([
        (marimba(N['A4'], 0.9, 0.28), 0.00, 0),
        (marimba(N['C5'], 0.9, 0.28), 0.12, 0),
        (marimba(N['F5'], 1.4, 0.5), 0.24, 0),
        (kalimba(N['F5'], 1.5, 0.5), 0.24, -4),
        (kalimba(N['A5'], 1.5, 0.5), 0.26, -4),
        (kalimba(N['F6'], 1.5, 0.5), 0.28, -5),
        (marimba(N['F3'], 1.6, 0.6), 0.24, -6),
        (gota(), 0.05, -14),
    ], 2.0), -13)

    # P7 — marco da trilha: parente do nível, sem o grave, com D6 no fim.
    s['marco'] = (mix([
        (marimba(N['A4'], 0.9, 0.28), 0.00, 0),
        (marimba(N['C5'], 0.9, 0.28), 0.12, 0),
        (marimba(N['F5'], 1.3, 0.45), 0.24, 0),
        (kalimba(N['A5'], 1.4, 0.5), 0.24, -4),
        (kalimba(N['C6'], 1.4, 0.5), 0.26, -4),
        (kalimba(N['D6'], 1.2, 0.45), 0.40, -6),
    ], 1.9), -14)

    # P1 — missão resgatada: o motivo rápido em kalimba, 3 inversões.
    for i, (a, b, c) in enumerate([('C5', 'F5', 'A5'), ('A4', 'C5', 'F5'),
                                   ('F5', 'A5', 'C6')], start=1):
        s[f'resgate_{i}'] = (mix([
            (kalimba(N[a], 0.6, 0.25), 0.00, 0),
            (kalimba(N[b], 0.6, 0.25), 0.09, 0),
            (kalimba(N[c], 1.0, 0.45), 0.18, 0),
        ], 1.2), -16)

    # E6 — o prêmio sobe da toca: terra abrindo + glissando + gota.
    s['premio'] = (mix([
        (terra(0.35, 300), 0.00, -6),
        (kalimba(N['F5'], 0.5, 0.2), 0.25, 0),
        (kalimba(N['A5'], 0.5, 0.2), 0.29, 0),
        (kalimba(N['C6'], 0.5, 0.2), 0.33, 0),
        (kalimba(N['F6'], 0.9, 0.4), 0.37, 0),
        (gota(), 0.40, -10),
    ], 1.3), -16)

    # E5 — cavar: terra úmida, grave. Quatro tomadas para a repetição.
    for i, c in enumerate([340, 300, 380, 320], start=1):
        s[f'cavar_{i}'] = (mix([(terra(0.28, c), 0, 0)], 0.3), -24)

    # B1 (provisório até a voz da espécie) — toque: 1 nota de kalimba da
    # pentatônica, 4 tomadas.
    for i, nota in enumerate(['F5', 'A5', 'C6', 'D6'], start=1):
        s[f'toque_{i}'] = (mix([(kalimba(N[nota], 0.4, 0.14), 0, 0)], 0.4), -19)

    # B4 — afago completo: díades de kalimba.
    for i, (a, b) in enumerate([('F5', 'A5'), ('A5', 'C6'), ('C6', 'F6')], start=1):
        s[f'carinho_{i}'] = (mix([
            (kalimba(N[a], 0.9, 0.35), 0.00, 0),
            (kalimba(N[b], 0.9, 0.35), 0.03, -1),
        ], 0.95), -18)

    # P9 — chegada do dia: não é herói. Kalimba F5 → A5 suave.
    s['chegada'] = (mix([
        (kalimba(N['F5'], 0.6, 0.3), 0.00, 0),
        (kalimba(N['A5'], 0.8, 0.35), 0.14, -1),
    ], 0.95), -19)

    # F5 — desistência: resolvida, descendo para a terça de Fá. "Tudo bem."
    s['desistencia'] = (mix([
        (marimba(N['C5'], 0.8, 0.3), 0.00, -2),
        (marimba(N['A4'], 1.0, 0.35), 0.16, -4),
    ], 1.2), -24)

    # F1 — sessão iniciada: respiro + uma nota de marimba, depois silêncio.
    sopro = folha(0.7) * 0.25
    s['inicio'] = (mix([
        (sosfilt(butter(2, [300, 1600], 'bandpass', fs=SR, output='sos'), sopro), 0.0, -6),
        (marimba(N['F4'], 0.9, 0.35), 0.40, 0),
    ], 1.3), -20)

    # E1 — folhas creditadas: farfalhar + C6 → F6.
    s['folhas'] = (mix([
        (folha(0.35), 0.00, -10),
        (kalimba(N['C6'], 0.5, 0.2), 0.05, 0),
        (kalimba(N['F6'], 0.7, 0.3), 0.13, -3),
    ], 0.85), -19)

    # E2 — compra: embrulho (folha mais longa) + G5 → C6.
    s['compra'] = (mix([
        (folha(0.5), 0.00, -9),
        (kalimba(N['G5'], 0.5, 0.2), 0.10, 0),
        (kalimba(N['C6'], 0.8, 0.35), 0.19, 0),
    ], 1.0), -19)

    # P3 + storyboard da raiz (laudo 01, §5): a cena inteira num arquivo,
    # sincronizado com a animação. O arquivo começa no instante em que a gota
    # se forma (400 ms da cena): gota caindo em 0,30 s (700 ms), toc de
    # madeira na ponta em 0,35 (750), três notas de marimba subindo em 0,45 /
    # 0,60 / 0,75 (850 / 1000 / 1150) e o plim do contador em 0,80 (1200).
    # A raiz é funda: F3 → C4 → F4, e um brilho F5 no fim.
    raiz = [
        (gota(700, 1500, 0.14), 0.30, -8),
        (madeira(1046), 0.35, -6),
        (marimba(N['F3'], 1.2, 0.5), 0.45, 0),
        (marimba(N['C4'], 1.0, 0.4), 0.60, 0),
        (marimba(N['F4'], 1.2, 0.5), 0.75, 0),
        (kalimba(N['F5'], 1.0, 0.4), 0.80, -6),
        (terra(0.6, 220, 1.8), 0.40, -16),
    ]
    s['raiz'] = (mix(raiz, 2.0), -16)

    # Variante de marco da raiz: a mesma subida + o galho brotando (+900 ms
    # no storyboard) com o motivo do nível por cima.
    s['raiz_marco'] = (mix(raiz + [
        (marimba(N['A4'], 0.9, 0.28), 1.10, -2),
        (marimba(N['C5'], 0.9, 0.28), 1.22, -2),
        (marimba(N['F5'], 1.3, 0.45), 1.34, -2),
        (kalimba(N['A5'], 1.4, 0.5), 1.34, -5),
        (kalimba(N['F6'], 1.4, 0.5), 1.36, -6),
    ], 2.9), -14)

    # Crescimento do bicho (cena de eclosão e de estágio): o motivo do nível
    # com uma gota d'água no clarão — é vida nova, não pontos.
    s['crescimento'] = (mix([
        (gota(600, 1600, 0.16), 0.00, -6),
        (marimba(N['F4'], 1.0, 0.4), 0.02, -2),
        (marimba(N['A4'], 0.9, 0.3), 0.14, 0),
        (marimba(N['C5'], 0.9, 0.3), 0.26, 0),
        (marimba(N['F5'], 1.4, 0.5), 0.38, 0),
        (kalimba(N['A5'], 1.5, 0.5), 0.38, -4),
        (kalimba(N['C6'], 1.5, 0.5), 0.40, -4),
        (kalimba(N['F6'], 1.5, 0.5), 0.42, -6),
    ], 2.1), -13)

    return s


def main():
    raiz_app = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    pasta = os.path.join(raiz_app, 'assets', 'sons')
    os.makedirs(pasta, exist_ok=True)
    for nome, (sinal, alvo) in sons().items():
        caminho = os.path.join(pasta, f'{nome}.wav')
        medido = calibra(caminho, fecha(sinal), alvo)
        dur = os.path.getsize(caminho) / (SR * 2)
        print(f'{nome:14s} {dur:5.2f}s  alvo {alvo:6.1f}  medido {medido:6.1f} LUFS-M')


if __name__ == '__main__':
    sys.exit(main())

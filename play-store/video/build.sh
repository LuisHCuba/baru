#!/usr/bin/env bash
# Gera os dois cortes do comercial: saida/baru-vertical.mp4 e saida/baru-horizontal.mp4.
# Pré-requisitos: node + playwright (Chromium), ffmpeg, python3 com numpy.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/clip saida
../baixar-midia.sh   # áudio, clipe e arte vêm do R2
[ -f build/clip/096.jpg ] || ffmpeg -v error -y -i assets/clipe/celular-na-mesa.mp4 -vf scale=1080:1920 -q:v 3 build/clip/%03d.jpg
python3 audio.py
node render.mjs full v &
node render.mjs full h &
wait
for f in v h; do
  nome=$([ $f = v ] && echo vertical || echo horizontal)
  ffmpeg -v error -y -i build/video_$f.mp4 -i build/mix.wav -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart saida/baru-$nome.mp4
  echo saida/baru-$nome.mp4
done

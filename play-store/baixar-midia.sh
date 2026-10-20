#!/usr/bin/env bash
# Baixa do R2 a mídia do material da Play que não fica no git: peças da loja,
# telas do app, arte, áudio e clipe do ElevenLabs e os vídeos prontos.
# A lista (tamanho e caminho) está em midia.txt; só baixa o que falta ou
# está com tamanho diferente.
set -euo pipefail
cd "$(dirname "$0")"
R2="https://midia.lhcx.tech/site/baru/play-store"
while read -r tamanho arquivo; do
  if [ -f "$arquivo" ] && [ "$(stat -c %s "$arquivo" 2>/dev/null || stat -f %z "$arquivo")" = "$tamanho" ]; then continue; fi
  mkdir -p "$(dirname "$arquivo")"
  curl -fsS -o "$arquivo" "$R2/$arquivo"
  echo "$arquivo"
done < midia.txt

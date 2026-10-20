#!/usr/bin/env bash
# Renderiza as telas do app (test/capturas_loja_test.dart) em cada idioma e,
# para a home, nos quatro momentos do dia. O habitat lê a hora do relógio, então
# o fuso (TZ) é escolhido para cair no horário pedido.
set -euo pipefail
cd "$(dirname "$0")/../baru_app"
langs="${*:-pt}"
hora_utc=$((10#$(date -u +%H)))
fuso_para() { # hora local desejada -> TZ Etc/GMT±N (sinal invertido no POSIX)
  local d=$(( ($1 - hora_utc + 24) % 24 )); [ $d -gt 12 ] && d=$((d-24))
  if [ $d -ge 0 ]; then echo "Etc/GMT-$d"; else echo "Etc/GMT+$((-d))"; fi
}
for lang in $langs; do
  CAPTURAS=1 CAPTURAS_LANG=$lang TZ=$(fuso_para 12) flutter test test/capturas_loja_test.dart --no-pub
  for par in amanhecer:7 entardecer:18 noite:22; do
    CAPTURAS=1 CAPTURAS_LANG=$lang CAPTURAS_SUFIXO=-${par%%:*} TZ=$(fuso_para ${par##*:}) \
      flutter test test/capturas_loja_test.dart --no-pub --plain-name 'captura home-'
  done
done

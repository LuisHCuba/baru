#!/usr/bin/env bash
# Gera o APK de release recusando o build sem contas.
#
# Com a chave anon do .env ainda no valor de exemplo, o app entra sozinho em
# modo local: sem tela de entrar, sem "Já tenho conta", direto no onboarding.
# Um APK assim chegou a ser entregue para teste. Este script não deixa.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f .env ] || grep -qE "YOUR_PROJECT|your-anon-key" .env \
   || ! grep -qE "^SUPABASE_URL=https://.+" .env \
   || ! grep -qE "^SUPABASE_ANON_KEY=.{20,}" .env; then
  echo "ERRO: .env sem SUPABASE_URL/SUPABASE_ANON_KEY reais — o APK sairia sem contas." >&2
  echo "Preencha o .env (ver .env.example) e rode de novo." >&2
  exit 1
fi
if grep -qiE "^SUPABASE_ENABLED=false" .env; then
  echo "ERRO: SUPABASE_ENABLED=false no .env — o APK sairia sem contas." >&2
  exit 1
fi
flutter build apk --release "$@"

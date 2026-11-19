#!/bin/zsh
# Gera o AppIcon do iPhone a partir de build/icone_ios_1024.png
# (flutter test test/gera_icone_ios_test.dart --tags icone). Sem canal alfa:
# a App Store recusa ícone com alfa.
set -e
cd "$(dirname "$0")/.."
SRC=build/icone_ios_1024.png
DEST=ios/Runner/Assets.xcassets/AppIcon.appiconset
T=$(mktemp -d)
# JPEG não tem alfa; volta para PNG já opaco.
sips -s format jpeg -s formatOptions 100 "$SRC" --out $T/base.jpg >/dev/null
python3 -I - "$DEST/Contents.json" <<'PY' | while read nome px; do
import json, sys
for i in json.load(open(sys.argv[1]))['images']:
    if 'filename' not in i: continue
    lado = float(i['size'].split('x')[0]) * int(i['scale'].rstrip('x'))
    print(i['filename'], int(round(lado)))
PY
  sips -s format png -z $px $px $T/base.jpg --out "$DEST/$nome" >/dev/null
done
rm -rf $T
echo "ícones gerados em $DEST"

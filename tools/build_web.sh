#!/usr/bin/env bash
# Baut die Web-Vorschau mit überprüfbarer Build-Kennung und legt sie in web_preview/ ab.
# Aufruf aus dem Projektordner: tools/build_web.sh
# Hinweis: Die SHA ist die des aktuellen HEAD (Basis-Commit). Der Commit, der die gebauten
# Dateien enthält, ist der nächste – Vercel zeigt ihn zusätzlich im Deployment an.
set -euo pipefail
SHA=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# --pwa-strategy=none: kein Service-Worker-Cache (iPhone-Home-Bildschirm-App zeigt sonst alte
# Versionen); ein bereits installierter alter Worker wird beim nächsten Laden abgeräumt.
# PREVIEW_PRO / PREVIEW_SLICE: nur Staging – Pro-Inhalte offen, Mira + Wiese + Abenteuer vorgewählt.
flutter build web --release --pwa-strategy=none \
  --dart-define=PREVIEW_PRO=true --dart-define=PREVIEW_SLICE=true \
  --dart-define=GIT_SHA="$SHA" --dart-define=GIT_BRANCH="$BRANCH" --dart-define=BUILD_TIME="$TIME"
keep=$(cat web_preview/vercel.json)
rm -rf web_preview/*
cp -r build/web/. web_preview/
rm -rf web_preview/canvaskit   # wird vom Google-CDN geladen
printf '%s\n' "$keep" > web_preview/vercel.json
printf '{"sha":"%s","branch":"%s","built":"%s"}\n' "$SHA" "$BRANCH" "$TIME" > web_preview/build.json
echo "web_preview/ gebaut für $BRANCH @ ${SHA:0:7}"

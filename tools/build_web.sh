#!/usr/bin/env bash
# Baut die Web-Vorschau mit überprüfbarer Build-Kennung und legt sie in web_preview/ ab.
# Aufruf aus dem Projektordner: tools/build_web.sh
# Hinweis: Die SHA ist die des aktuellen HEAD (Basis-Commit). Der Commit, der die gebauten
# Dateien enthält, ist der nächste – Vercel zeigt ihn zusätzlich im Deployment an.
set -euo pipefail
SHA=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
flutter build web --release \
  --dart-define=GIT_SHA="$SHA" --dart-define=GIT_BRANCH="$BRANCH" --dart-define=BUILD_TIME="$TIME"
keep=$(cat web_preview/vercel.json)
rm -rf web_preview/*
cp -r build/web/. web_preview/
rm -rf web_preview/canvaskit   # wird vom Google-CDN geladen
printf '%s\n' "$keep" > web_preview/vercel.json
printf '{"sha":"%s","branch":"%s","built":"%s"}\n' "$SHA" "$BRANCH" "$TIME" > web_preview/build.json
echo "web_preview/ gebaut für $BRANCH @ ${SHA:0:7}"

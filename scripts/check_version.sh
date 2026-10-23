#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
P=$(grep -E '^version:' pubspec.yaml | sed -E 's/version: *([0-9.]+).*/\1/')
D=$(grep -E "appVersion = " lib/app/info.dart | sed -E "s/.*'([0-9.]+)'.*/\1/")
[ "$P" = "$D" ] || { echo "Version mismatch: pubspec=$P info.dart=$D"; exit 1; }
echo "Version konsistent: $P"

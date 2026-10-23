#!/usr/bin/env bash
# Bricht ab, wenn Werbe-/Tracking-/Analytics-SDKs in pubspec.lock auftauchen.
set -euo pipefail
cd "$(dirname "$0")/.."
FORBIDDEN='google_mobile_ads|admob|facebook_app_events|firebase_analytics|firebase_crashlytics|firebase_core|appsflyer|adjust_sdk|amplitude|mixpanel|segment|sentry|onesignal|branch_sdk|unity_ads|applovin|ironsource|flutter_facebook|app_tracking_transparency|advertising_id|google_sign_in|geolocator|location|permission_handler|camera|record'
if grep -E "^  ($FORBIDDEN):" pubspec.lock; then
  echo "VERBOTENE Abhängigkeit gefunden (Kinder-/Privacy-Richtlinie)."; exit 1
fi
echo "Keine Werbe-/Tracking-/Standort-/Kamera-Pakete in pubspec.lock."

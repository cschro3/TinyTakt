# Käufe und Entitlements

Produkt: `tinytakt_pro_lifetime` (nicht verbrauchbar, einmalig; Preis-Vorschlag 4,99 € = **vorläufig, vor Release bestätigen**). iOS: StoreKit 2 (über `in_app_purchase_storekit`, SK2 ist dort Standard), Android: Google Play Billing über `in_app_purchase_android`. iOS- und Android-Käufe sind **getrennt**; es gibt keine plattformübergreifende Freischaltung (und sie wird nirgends versprochen).

## Ablauf (`lib/platform/purchase_service.dart`)
Produktabfrage beim Store → lokalisierter Store-Preis (nie hartcodiert) → `buyNonConsumable` → Stream: `pending` (Hinweis, keine Freischaltung), `canceled` (zurück zu bereit), `error` (Transaktion abschließen, Fehlerhinweis), `purchased/restored` → Verifier → `EntitlementRepository.grant` → `completePurchase`. Doppelte Auslösung blockiert (`purchasing/pending`). Kauf bei vorhandenem Pro blockiert. Fehlgeschlagene Verifikation: **nicht** freischalten, **nicht** abschließen (Google erstattet unbestätigte Käufe nach 3 Tagen).

## Prüfung
* Immer: `StoreEvidenceVerifier` (Produkt-ID, Status, vorhandener Store-Nachweis: Play-Purchase-Token / StoreKit-JWS).
* Optional: `RemoteVerifier` (nur mit `--dart-define=PURCHASE_VERIFY_URL=…`). Sendet ausschließlich Produkt-ID, Plattform, Store-Nachweis. Erwartete Server-Antwort `{"valid":true|false}`. Der Server (nicht Teil dieses Repos) muss Play Developer API (`purchases.products.get`) bzw. App Store Server API/JWS-Signatur prüfen. Offline/Serverfehler → lokale Store-Bestätigung gilt; ausdrückliche Ablehnung blockiert.
* **Ehrliche Einordnung:** Ohne eigenen Server ist die Prüfung nur so stark wie die lokale Store-Bibliothek. Für maximale Manipulationssicherheit Server nachrüsten.

## Offline-Entitlement
Eintrag `{product, platform, txId, grantedAtMs, mac}`; `mac = HMAC-SHA256(Schlüssel, canonical)`; Schlüssel zufällig im Secure Storage (Keychain `first_unlock_this_device` / Android-Keystore-gestützt). Manipulation der Prefs-Datei, kopierte Prefs ohne Schlüssel, andere Plattform und gesetzte Boolean-Flags schalten nichts frei (getestet). **Grenze:** Root/Jailbreak mit Zugriff auf beide Speicher kann umgehen.

## Erstattung/Entzug
Android: bei jedem Start autoritativer Abgleich (`queryPastPurchases`); fehlender Kauf bei erfolgreicher Abfrage → `revoke`. Abfragefehler/offline → Pro bleibt. iOS: Revocation-Erkennung über Transaktionsupdates des Plugins/Wiederherstellen; **nicht auf Gerät verifiziert** und nicht so autoritativ wie Android → TODO bei Sandbox-Test (`Transaction.currentEntitlements`).

## Einrichtung durch den Auftraggeber
1. App Store Connect: IAP „Non-Consumable“, Product ID `tinytakt_pro_lifetime`, Preisstufe, Lokalisierungen DE/EN, Review-Screenshot, Vereinbarungen „Paid Apps“ + Bank/Steuer.
2. Play Console: In-App-Produkt `tinytakt_pro_lifetime` (aktiv), Preise, Lizenztester (E-Mail-Adressen) anlegen; App muss auf einem Test-Track hochgeladen sein, damit Billing-Abfragen funktionieren.
3. Sandbox-/Lizenztest-Käufe auf echten Geräten durchführen (Kaufen, Abbrechen, Wiederherstellen, Erstattung, Pending „langsame Testkarte“). **Nicht durchgeführt** – kein Store-Zugang in dieser Umgebung.

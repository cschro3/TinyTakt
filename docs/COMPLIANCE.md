# Compliance – Vorbereitung und Status

**Wichtig:** Dies ist eine technische Vorbereitung, **keine Rechtsberatung** und **keine abgeschlossene Prüfung**. Richtlinien ändern sich; Stand der Prüfung vor Release (Apple App Review Guidelines inkl. 1.3 Kids Category und 5.1.4, Google Play Families Policy/Target Audience and Content/Data safety) **erneut lesen**. In dieser Umgebung wurden die aktuellen Richtlinientexte **nicht** vollständig gelesen/verifiziert; die Punkte unten stammen aus dem bekannten Stand und sind Prüfpunkte.

## Umgesetzt (technisch nachprüfbar)
* Keine Werbe-/Tracking-/Analytics-SDKs (CI-Prüfung), keine Registrierung, kein Backend, keine Nutzerkommunikation, keine externen Links/Webviews im Kinderbereich.
* Android-Manifest: `AD_ID`, Foto-/Medien-/Kamera-/Mikrofon-/Speicherrechte entfernt; `allowBackup=false` + Extraction-Rules (keine Cloud-Sicherung).
* Käufe und Elternbereich nur hinter Elternsicherung; Kinder sehen keine Preise/Kaufbuttons.
* iOS `PrivacyInfo.xcprivacy`: kein Tracking, keine gesammelten Daten, Required-Reason-APIs (UserDefaults CA92.1, FileTimestamp C617.1 – **Gründe vor Release gegen Plugin-Nutzung prüfen**).
* `ITSAppUsesNonExemptEncryption=false` (nur Standard-/Exemptions-Kryptografie – **vom Anbieter zu bestätigen**).

## Angaben für die Stores (Entwurf)
* **Apple App Privacy:** „Data Not Collected“. Kids Category: Altersband „5 & Under“ oder „6–8“ wählen (Empfehlung: 5 & Under, da 2–8). Keine Drittanbieter-Analyse/Werbung.
* **Google Data safety:** keine Daten erhoben/geteilt; Käufe über Google Play Billing (kein App-seitiger Zahlungsdatenzugriff). Verschlüsselung in Transit: n. a. (keine Übertragung durch die App). Löschanfrage: n. a. (nur lokal).
* **Google Families:** Zielgruppe „bis 5“ und „6–8“ (+ ggf. Eltern); App muss Families-Anforderungen erfüllen (keine AD_ID, werbefrei, geeignete API-Nutzung). **App-Content-Erklärungen vollständig in der Console ausfüllen.**
* **Altersfreigabe-Fragebögen:** beide Stores; erwartetes Ergebnis niedrigste Stufe (keine Gewalt etc.).
* **DSGVO/COPPA:** Es werden keine personenbezogenen Daten an den Anbieter übermittelt (Datenminimierung). In-App-Datenschutzinformation vorhanden (Platzhalter für Verantwortlichen). Datenschutzerklärung als **öffentliche URL** muss vor Einreichung gehostet werden (Platzhalter-Text in `store/`). Elternsicherung ersetzt keine Einwilligung.
* **Verbraucherrecht:** Einmalkauf, kein Abo; Preis aus dem Store; Widerruf/Erstattung über Store-Prozesse. **Händlerangaben (Trader-Status/DSA), Impressum:** vom Anbieter auszufüllen (Platzhalter vorhanden).
* **Google Exact Alarm:** `USE_EXACT_ALARM` Deklaration (Kernfunktion Timer) begründen.

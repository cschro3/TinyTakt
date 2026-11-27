# Produktions-Pipeline für Premium-Figuren (V5)

Ziel: Jede der 81 Figuren erreicht denselben Qualitätsstand wie Mira (echtes, freigestelltes Bild-Asset). Die Technik
dafür steht (Registry, Manifest, Prüfungen, Ausrüstung, Animations-Frames). **Es fehlen die Bilder selbst** – in dieser
Umgebung stand kein Bildgenerator zur Verfügung. Ohne diese Dateien bleibt jede Figur ein dokumentierter Fallback.

## 1. Pro Figur zu liefern
| Datei | Inhalt | Format / Maße |
|---|---|---|
| `design_sheet.png` | Frontal/Seite/Rückseite, Farbpalette (HEX), Proportionen, Mimik-Reihe | ≥ 2048 px, nur zur Abnahme |
| `portrait.webp` | Kopf + Schultern, transparent, für Karten/Avatar | 512×512, ≤ 80 KB |
| `full_phone.webp` | Ganzkörper, transparent, Füße mittig bei y = 0,95 | 514×512, ≤ 100 KB |
| `full_hd.webp` | wie oben, Tablet/Druck | 1097×1093, ≤ 300 KB |
| `states/*.webp` | `idle`, `blink`, `wave`, `walk_a`, `walk_b`, `run_a`, `run_b`, `jump`, `think`, `wonder`, `cheer`, `rest` | je 514×512, gleiche Ankerpunkte |
| `gear/<welt>.webp` (optional) | Ausrüstung als eigene transparente Ebene (Helm, Rucksack …) | 514×512 |
| `manifest.json` | ID, Version, Quelle/Lizenz, Ankerpunkte, Zustände, Palette | siehe `assets/art/manifest.json` |

Ankerpunkte (relativ zum Bild): `feet` (0,5 / 0,95), `head` (Mitte, Radius), `neck`. Die automatische Ausrüstung
(`adventure_gear.dart`) erwartet Kopfmitte ≈ (0,5 / 0,45) und Kopfradius ≈ 0,27 – abweichende Figuren tragen ihre
Ankerpunkte im Manifest ein.

## 2. Bildstil (verbindlich, eigenständig – keine Kopien bekannter Serien)
Hochwertiger 3D-Animationsfilm-Look: große ausdrucksstarke Augen, weiche Rundungen, Material (Fell/Stoff/Metall) mit
weichem Licht von oben links, kühle Schatten, transparenter Hintergrund. Je Gruppe eigene Formensprache und Farbwelt:
Rettungsteam (warmes Orange/Weiß, Funkgerät-Weste) · Feuerwehr (Rot/Gelb, Schlauch-Gürtel) · Spürnasen-Team (Blau,
Lupe/Taschenlampe) · Bau & Technik (Gelb, Werkzeuggürtel) · Sternenreisende (Weiß/Violett, Sternen-Patch) ·
Dino-Abenteurer (Grün/Orange, Fußabdruck-Emblem) · Waldentdecker (Erdtöne, Kompass) · Drachen & Spukfreunde (Violett/
Mint, Funken) · Meeresabenteurer (Türkis, Perlen-Detail) · Roboter (Silber/Cyan, Leuchtaugen) · Fantasiewesen (Pastell,
Glitzer) · Kleine Erfinder (Mintgrün/Gold, Brille/Zahnrad) · Hofhelden (Naturfarben) · Dschungelmutige (Gold/Grün).
Keine Logos, Namen, Kostüme oder Wappen bestehender Marken.

## 3. Einbau (ohne Screens anzufassen)
1. Dateien nach `assets/art/characters/<id>/` legen, `pubspec.yaml` ergänzen.
2. `assets/art/manifest.json` (Abschnitt `characters`) erweitern – `test/asset_manifest_test.dart` prüft Dateien, Maße,
   Transparenz, Budget und Verweise.
3. `VisualRegistry._bitmapCharacters` um die ID erweitern (Stufe wird automatisch `premiumAsset`).
4. `docs/CHARACTER_STATUS.md` neu erzeugen: `flutter test test/tools/character_status_test.dart`.

## 4. Qualitätsprüfung je Figur (Checkliste)
Identität in allen Zuständen gleich · Ankerpunkte stimmen (Kontaktbogen `test/tools/gear_sheet_test.dart`) · Ausrüstung
sitzt in allen 9 Welten · Alpha sauber (kein Rand) · Dateigröße im Budget · lesbar bei 90 px (Auswahlkarte) ·
Animation in `AdventureScene` ohne Sprünge · `?perf=1` ohne Einbruch.

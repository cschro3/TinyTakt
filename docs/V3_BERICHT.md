# TinyTakt 3.0 – Visual Unification (Zwischenstand)

Branch `feature/tinytakt-visual-unification-v3` (abgeleitet von `feature/mira-meadow-slice`, nichts in main).

## Umgesetzt (belegt)
- **VisualRegistry** (`lib/presentation/art/visual/visual_registry.dart`): eine Identität je Figur/Welt, `recipe(Figur, Welt, Stil)` entscheidet Story-Szene/Bildhintergrund. Ersetzt die Sonderbedingung Mira+Wiese+Abenteuer in `home_screen.dart`.
- **Gemeinsame Renderer**: `CharacterVisualPainter` (Mira = echtes Bild/Mesh, sonst Vektor-Fallback), `WorldVisualPainter` (Wiese = echtes Bild, sonst prozedural). Verwendet in Auswahlkarten, Timer-Bühne (alle Stile), Startbildschirm.
- **Story-Szene nicht mehr an Mira gekoppelt**: jede Figur läuft auf dem gemalten Wiesenweg (Abenteuer).
- Mira erscheint in jeder Welt/jedem Stil als dasselbe Bild; die Wiese ist in allen Stilen und in der Weltvorschau dieselbe.
- Welt-Akzentfarbe für Zeitanzeige (Kontrast ≥ 4,5:1), Kartennamen werden skaliert statt abgeschnitten.
- **Asset-Manifest** `assets/art/manifest.json` + `test/asset_manifest_test.dart` (Dateien, Maße, Alpha, Budget, Registry-Verweise, pubspec).
- Inventar: `docs/ASSET_INVENTAR.md` (erzeugt von `test/tools/inventory_test.dart`).
- Tests: 235+ grün, `flutter analyze` sauber (neue Tests: visual_registry, asset_manifest).

## Ehrliche Abdeckung
| | Premium-Asset | Premium-Vektor | Standard-Vektor |
|---|---|---|---|
| Figuren (81) | 1 (Mira) | 10 | 70 |
| Welten (9) | 1 (Wiese) | – | 8 prozedurale Fallbacks |

Nur Mira und Blumenwiese haben echte Illustrationen. Alle anderen Figuren/Welten zeigen weiterhin Vektor-/prozedurale Grafik – das ist Fallback, **keine** Premium-Qualität. Mira hat kein Blinzeln/Laufzyklus (Mesh-Verformung eines Standbilds).

## Performance (nur Headless-Chromium, Software-GL, relativ!)
Szene Mira+Wiese+Abenteuer, 3 Läufe je Version: vorher 25–27 fps, Skript 33–37 ms/Frame; nachher 24–26 fps, 36–38 ms/Frame → kein messbarer Unterschied innerhalb des Rauschens (evtl. ~1 fps). Echte iPhone-Safari-Messung steht aus.

## Offen
- Illustrationen für 80 Figuren und 8 Welten (Spezifikation: `docs/art/ASSET_ANFORDERUNG_RUNDE2.md`); Mira-Zustände/Avatar-Kopf.
- Abenteuer-Wege je Welt (Wald, Strand, Weltraum) – brauchen gemalte Hintergründe; bis dahin klassischer Diorama-Weg.
- UI-Vereinheitlichung der übrigen Screens (Einstellungen, Erfolg, Eltern, Onboarding), Querformat-/Kleingeräte-Screenshots, DE/EN-Textprüfung.
- Erfolgsbildschirm-Konzept, Reduced-Motion-Feinschliff.
- iPhone-Prüfung durch den Auftraggeber.
Bilder: `docs/v3/vorher_nachher_timer.png`, `docs/v3/vorher_nachher_menue.png`.

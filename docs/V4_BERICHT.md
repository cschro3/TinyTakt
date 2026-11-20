# TinyTakt 4.0 – Multi-Adventure Worlds

Branch `feature/tinytakt-visual-unification-v3` (weitergeführt, nichts in main). Staging mit Build-Kennung `/build.json`.

## Neu
- **Adventure-Framework** (`lib/presentation/art/adventure/`): `AdventureWorldSpec` (Weg, Etappen, Ziel, Landschaft, Ambiente, Figurenskalierung, Fortschrittsfarben), `AdvFrame` (Wegpunkte→Bildschirm, Fortschritt→Position), `AdventureScene` (gebackene Landschaft, bewegte Ebene, Figur, Etappen, Feier am Ziel).
- **8 Welten mit eigenem Abenteuer** (eigener Weg, Ziel, Etappenmarken, Ambiente):
  Weltraum (Flugroute, Raumstation, Blasen-Figur, Sternschnuppen) · Abendrot (Laternenpfad, Hütte, Glut) · Sternennacht (Mondpfad, Sternentor, Glühwürmchen) · Zauberwald (Waldweg, leuchtende Pilze, Baumhaus) · Strand (Dünenpfad, Leuchtturm, Wellen, Möwen) · Unterwasser (Korallenpfad, Schatztruhe, Fische, Blasen) · Winter (Schneepfad, Schneemänner, Iglu, Schneefall) · Wolkenhimmel (Wolkenbrücke, Regenbogen-Etappen, Wolkenschloss).
  Blumenwiese bleibt die gemalte Bild-Story.
- **Alle 81 Figuren** laufen in allen Abenteuern (universelles Figurensystem): Mira als Bild-Mesh, alle anderen als Vektor-Figur über gebackene Animations-Frames (`FigureFrames`).
- Weltvorschau-Karten zeigen die jeweilige Abenteuerlandschaft mit Weg und Ziel; die übrigen Timer-Stile nutzen dieselbe Landschaft als Hintergrund (eine Welt = eine Identität).
- Staging-Schalter: `?world=space&char=dog&style=adventure` wählt direkt vor.

## Belegt (Tests, Messung)
- 268 Tests grün, `flutter analyze` sauber. Neu: `test/adventure_test.dart` – Weltabdeckung, Wegegeometrie (kein Springen), Registry für alle Figuren×Welten, Home-Integration je Welt × {Hund, Mira, Löwe} mit Fortschritt, Pause/Fortsetzen ohne Sprung, Abschluss, Neustart, Figur-/Weltwechsel, ruhiger Modus, FigureFrames-Speicherlimit.
- Performance (Headless-Chromium, Software-GL, nur relativ, **kein iPhone**): Vor der Frame-Optimierung 14–21 fps mit Vektor-Figuren (Weltraum/Winter ~14 fps, 68 ms Skript/Bild). Danach 51–53 fps (12–13 ms/Bild). Mira-Szenen unverändert (45–47 fps im selben Lauf).
- Vorher/Nachher: `docs/v4/vorher_nachher_welten.png` (8 Welten mit je anderer Figur; Laufzustand und Abschluss).

## Ehrliche Grenzen
- Alle acht neuen Abenteuer sind **programmatisch gemalte Fallbacks**, keine Illustrationen (Liste fehlender Assets: `docs/ASSET_ANFORDERUNG_ABENTEUER.md`).
- Vektor-Figuren im Abenteuer zeigen nur die Stimmungen Ruhe/Aktiv/Freude/Müde als Schleife (10 Frames/2 s), keine einmaligen Gesten (Begrüßung, Ermutigung); Hüpfen, Weg und Skalierung laufen live.
- Abschlussbild-Konzept: Ziel leuchtet, Feier am Ziel; kein eigener Erfolgsbildschirm je Welt.
- iPhone-Safari-Messung steht aus.

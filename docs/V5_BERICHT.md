# TinyTakt V5 – Charakter-Universum (Zwischenstand, ehrlich)

Branch `feature/tinytakt-character-universe-v5` (auf V4 aufbauend, nichts in main).

## Wichtigste Einschränkung
In dieser Umgebung gab es **keinen Bildgenerator**. Echte 3D-Charakterillustrationen („PAW-Patrol-Niveau“) für 81 Figuren
wurden deshalb **nicht erzeugt**. Es gibt weiterhin genau **1 Figur mit echtem Bild-Asset (Mira)**, 10 aufgewertete
Vektorfiguren und 70 einfache Vektorfiguren (`docs/CHARACTER_STATUS.md`). Die „80 zusätzlichen Figuren“ sind keine neuen
Figuren: Der Bestand umfasst bereits 81 (1 Mira + 80); sie wurden um Profile erweitert, nicht ersetzt.

## Umgesetzt (belegt durch Tests/Screenshots)
- **Charakteruniversum** (`lib/domain/character_profiles.dart`): alle 81 Figuren in 14 Gruppen (die 12 Wunschgruppen +
  Hofhelden + Dschungelmutige) mit Persönlichkeit, Fähigkeit und Kurzgeschichte, Deutsch und Englisch.
  Hinweis: Es gibt keine eigenen Polizei-/Feuerwehr-/Rettungs-*Hunde*-Figuren; Gruppen wurden den vorhandenen Figuren
  sinnvoll zugeordnet (z. B. Feuerwehr = Löschfahrzeug, Elefant, Nilpferd …).
- **Dynamische Abenteuer-Ausrüstung** (`adventure_gear.dart`): ein skalierbares System aus kleinen Teilen je Welt (Raumanzug,
  Entdeckerausrüstung, Taucherausrüstung, Winterkleidung, Expeditionskleidung, Nachtreise-Set, Strandkit, Fliegerkit,
  Blumenschmuck), das automatisch auf alle 57 Figuren mit Kopf passt – ohne Bild pro Kombination. Vehikel/Himmelskörper/
  Pflanzen tragen nichts. Programmatisch gemalt (Fallback), Kontaktbogen: `docs/v5/ausruestung_kontaktbogen.png`.
- **Animation/Timer**: Hüpfer bei erreichter Etappe, lebhafteres Federn kurz vor dem Ziel, Jubel-Sprünge am Ende, leichtes
  Winken bei Begrüßung/Start/Ermutigung, Ausruhen in der Pause, seitliches Ausweichen am Ziel (verdeckt es nicht),
  ruhiger Modus ohne Bewegung (`FigureMotion`, getestet).
- **Galerie**: Favoriten (Stern, eigener Bereich „Meine Favoriten“, lokal gespeichert), Steckbrief-Knopf je Karte,
  **Charakterkarte** mit großem animiertem Porträt (Tippen = Freude), Gruppe, Persönlichkeit, Fähigkeit, Geschichte,
  Ausrüstungsvorschau je Welt, fest verankertem „Figur wählen“-Knopf; gesperrte Figuren öffnen Pro statt gewählt zu werden.
  Screenshots: `docs/v5/galerie_und_steckbrief.png`.
- **Pipeline**: `docs/CHARACTER_PRODUCTION_PIPELINE.md` (Lieferumfang, Stil, Einbau, QA), `docs/CHARACTER_STATUS.md`
  (automatisch), bestehende Manifest-Prüfungen (`test/asset_manifest_test.dart`).

## Nicht umgesetzt / offen
- Illustrationen für 80 Figuren, Mira-Zustände, Porträt-/Ganzkörper-/Ausrüstungs-Bilder (siehe Pipeline-Dokument).
- Rennen/Springen/Nachdenken/Staunen als eigene Posen: nur als Transformationen (Hüpfer, Federn) abgebildet, keine
  Zustandsbilder.
- Kamerabewegung, kurze Bildschirmaufnahmen (keine Videoerfassung möglich), eigene Hintergrundmotive je Figurenkarte.
- Weitere Abenteuerwelten (Baustelle, Vulkan, Rettungsmission) – die Ausrüstung dafür existiert nicht.
- iPhone-Messung steht aus.

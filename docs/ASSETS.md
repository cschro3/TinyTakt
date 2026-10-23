# Assets, Herkunft und Release-Blocker

* **Figuren (46), Welten (9), Timer-Darstellungen (5), Held „Takti“, App-Icon, Splash:** eigene Vektorzeichnungen im Dart-Code (`lib/presentation/painters`), keine Fremd-/Markenfiguren, keine Emojis, keine Platzhalterbilder. Renderblatt: `build/sheets/characters.png` (per `test/tools/character_sheet_test.dart`).
* **Musik (6) und Alarme (6):** synthetisch erzeugt von `tools/generate_audio.py` (eigene Kompositionen, keine Samples/fremden Melodien), AAC, ~1,3 MB gesamt.
* **Schrift:** Nunito (SIL Open Font License 1.1), `assets/fonts/OFL.txt`.

## Release-Blocker (Assets)
1. **Professionelle Illustrations- und Animationsabnahme:** Die Figuren sind konsistent, aber programmatisch gezeichnet (Animationen: Wippen, Blinzeln, Ohren/Schwanz, Hüpfen am Ende). Für „hochwertige Illustration/Motion Design“ empfiehlt sich Abnahme/Überarbeitung durch eine Illustratorin/einen Illustrator. Nicht durch Test belegbar.
2. **Audio nicht abgehört:** Die Klänge wurden synthetisiert und nur technisch geprüft (Pegel, Dauer). Hörabnahme (Qualität, Angenehmheit, Loop-Übergänge, Kindgerechtheit, Lautstärke) durch Menschen steht aus.
3. **Referenz-Screenshots des Auftraggebers** lagen in dieser Sitzung nicht vor; das Design entstand aus der Beschreibung.
4. Store-Screenshots sind Renderings der echten UI aus dem Test-Framework; Geräte-Screenshots nachliefern.

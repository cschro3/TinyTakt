# Asset-Inventar (automatisch aus der VisualRegistry erzeugt)

Einstufung ehrlich: **Premium-Asset** = echte Bilddatei; **Premium-Vektor** = aufgewertete
programmatische Figur (KEINE Illustration); **Standard-Vektor** = alte Grundgrafik.

## Figuren (81)

| Stufe | Anzahl | IDs |
|---|---|---|
| premiumAsset | 1 | nova_mira |
| premiumVector | 10 | dog, cat, bunny, hamster, parrot, cow, pig, sheep, nova_lumi, nova_zeno |
| standardVector | 70 | chicken, horse, lion, elephant, giraffe, monkey, tiger, fish, whale, octopus, turtle, crab, trex, tricera, … |

## Welten (9)

| ID | Name | Stufe | Renderer | Story-Weg | Pro |
|---|---|---|---|---|---|
| meadow | Blumenwiese | premiumAsset | bitmapStory | ja (gemaltes Bild) | nein |
| sky | Wolkenhimmel | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | nein |
| beach | Strand | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | nein |
| forest | Zauberwald | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | nein |
| night | Sternennacht | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | nein |
| space | Weltraum | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | ja |
| underwater | Unterwasserwelt | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | ja |
| winter | Winterland | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | ja |
| sunset | Abendrot | Fallback (prozedural) | procedural | ja (eigene Szene, programmatisch) | ja |

## Kombinationsmatrix Figur × Welt × Timer-Stil

- Kombinationen gesamt: 7290
- mit gemaltem Vollbild-Abenteuer (Story-Szene): 81
- mit Bild-Hintergrund (Wiese): 810
- Figur als Bild-Asset (Mira) in: 90 Kombinationen, Mesh-Renderer in allen Welten und Stilen
- alle übrigen: dokumentierter Fallback (Vektor-Figur / prozedurale Welt)

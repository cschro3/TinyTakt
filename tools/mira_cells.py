#!/usr/bin/env python3
"""Berechnet die Maske der aktiven Netzzellen (24x24) des Mira-Bildes und schreibt sie als Dart-Konstante.
Ein Pixel Rand, Alpha > 0 – dieselbe Regel wie MiraMeshData. Nach jedem Austausch von mira_prototype.webp ausführen:
    python3 tools/mira_cells.py   (Test story_perf_test.dart prüft, dass die Maske zum Bild passt)
"""
import numpy as np
from PIL import Image

COLS = ROWS = 24
a = np.asarray(Image.open('assets/art/mira/mira_prototype.webp').convert('RGBA'))[..., 3]
h, w = a.shape
out = []
for cy in range(ROWS):
    for cx in range(COLS):
        x0, x1 = cx * w // COLS, (cx + 1) * w // COLS
        y0, y1 = cy * h // ROWS, (cy + 1) * h // ROWS
        blk = a[max(y0 - 1, 0):min(y1 + 1, h), max(x0 - 1, 0):min(x1 + 1, w)]
        out.append('1' if (blk > 0).any() else '0')
mask = ''.join(out)
src = f"""// GENERIERT von tools/mira_cells.py – nicht von Hand ändern.
// Aktive Netzzellen (24x24, Zeile für Zeile) des Mira-Bildes: '1' = enthält sichtbare Pixel.
const miraActiveCells =
    '{mask}';
"""
open('lib/presentation/art/story/mira_cells.dart', 'w').write(src)
print('aktiv', mask.count('1'), 'von', len(mask))

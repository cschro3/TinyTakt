#!/usr/bin/env python3
"""Erzeugt alle Audio-Assets von TinyTakt synthetisch (eigene Kompositionen, keine Samples).

Alle Melodien sind eigens für TinyTakt geschrieben; es werden keine fremden
Aufnahmen oder bekannten Melodien verwendet. Lizenz: wie das Projekt (eigenes Werk).
Aufruf: python3 tools/generate_audio.py assets/audio
Benötigt numpy und ffmpeg (AAC-Encoder).
"""
import subprocess
import sys
from pathlib import Path

import numpy as np

SR = 32000
rng = np.random.default_rng(42)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n, a=0.01, d=0.2, s=0.0, r=0.1, sr=SR):
    t = np.arange(n) / sr
    e = np.where(t < a, t / a, np.exp(-(t - a) / max(d, 1e-3)) * (1 - s) + s)
    rel = int(r * sr)
    if rel > 0 and n > rel:
        e[-rel:] *= np.linspace(1, 0, rel)
    return e


def tone(freq, dur, kind="sine", a=0.01, d=0.3, s=0.0, r=0.05, vib=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = freq * (1 + vib * np.sin(2 * np.pi * 5 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == "sine":
        y = np.sin(ph)
    elif kind == "tri":
        y = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == "pluck":  # marimba / music-box artig
        y = np.sin(ph) + 0.35 * np.sin(2 * ph) * np.exp(-t * 8) + 0.15 * np.sin(4 * ph) * np.exp(-t * 14)
    elif kind == "bell":
        y = sum(a_ * np.sin(ph * r_) * np.exp(-t * dc) for a_, r_, dc in [(1, 1, 1.4), (0.6, 2.0, 2.0), (0.45, 2.76, 2.6), (0.3, 5.4, 4.0), (0.2, 8.93, 6.0)])
    elif kind == "piano":  # weicher Klavierklang: Obertöne mit frequenzabhängigem Abklingen
        y = sum((1.0 / n) * np.sin(ph * n * (1 + 0.0004 * n * n)) * np.exp(-t * (1.2 + 1.6 * n)) for n in range(1, 8))
        y = y + 0.02 * np.random.default_rng(int(freq)).standard_normal(n_ := len(t)) * np.exp(-t * 90)
    elif kind == "pizz":  # gezupfte Saite, kurz
        y = np.sin(ph) * np.exp(-t * 9) + 0.5 * np.sin(2 * ph) * np.exp(-t * 16) + 0.25 * np.sin(3 * ph) * np.exp(-t * 22)
    elif kind == "harp":
        y = np.sin(ph) + 0.4 * np.sin(2 * ph) * np.exp(-t * 5) + 0.2 * np.sin(3 * ph) * np.exp(-t * 7)
    else:
        raise ValueError(kind)
    return y * env(n, a, d, s, r)


def place(buf, y, start):
    i = int(start * SR)
    n = len(y)
    L = len(buf)
    # zyklisch (Loop-fähig): Überhang wird an den Anfang gelegt
    idx = (np.arange(n) + i) % L
    np.add.at(buf, idx, y)


def reverb(x, wet=0.25, rt=1.2):
    n = int(rt * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-t * 4.5 / rt)
    ir[0] = 0
    ir /= np.sqrt((ir ** 2).sum())
    L = len(x)
    # zyklische Faltung -> nahtlose Loops
    y = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, L), L)
    return x * (1 - wet) + y * wet


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def norm(x, peak=0.8):
    x = x - x.mean()
    return x / (np.abs(x).max() + 1e-9) * peak


def fade_ends(x, ms=8):
    n = int(ms / 1000 * SR)
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(name, x, out):
    x = np.clip(x, -1, 1)
    pcm = (x * 32767).astype("<i2")
    raw = out / f"{name}.raw"
    raw.write_bytes(pcm.tobytes())
    dst = out / f"{name}.m4a"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", str(raw), "-c:a", "aac", "-b:a", "56k", str(dst)], check=True)
    raw.unlink()
    print(f"{dst.name}: {len(x)/SR:.1f}s, {dst.stat().st_size/1024:.0f} KiB")


# ---------- Musik (Loops) ----------
PENT = [0, 2, 4, 7, 9]  # Dur-Pentatonik


def scale_note(root, degree):
    return root + PENT[degree % 5] + 12 * (degree // 5)


def music_calm(out):  # 56 bpm, 8 Takte à 4 Schläge
    bpm = 56
    beat = 60 / bpm
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    chords = [(48, [0, 4, 7, 11]), (45, [0, 3, 7, 10]), (41, [0, 4, 7, 11]), (43, [0, 4, 7, 10])]
    for b in range(bars):
        root, ch = chords[b % 4]
        for k in ch:
            place(buf, 0.10 * tone(midi(root + k + 12), 4 * beat + 1.2, "tri", a=0.9, d=3, s=0.7, r=1.0), b * 4 * beat)
    mel = [4, 2, 3, 1, 2, 0, 1, 3, 4, 6, 5, 3, 2, 1, 0, 2]
    for i, d in enumerate(mel):
        place(buf, 0.22 * tone(midi(scale_note(72, d)), 2.2, "pluck", d=0.9), i * 2 * beat)
    return reverb(buf, 0.35, 1.6)


def music_happy(out):  # 112 bpm
    bpm = 112
    beat = 60 / bpm
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    bass = [48, 48, 53, 55]
    for b in range(bars):
        r = bass[b % 4]
        for k in range(4):
            place(buf, 0.22 * tone(midi(r - 12 + (7 if k % 2 else 0)), beat * 0.9, "tri", a=0.005, d=0.25), (b * 4 + k) * beat)
    mel = [0, 2, 4, 2, 5, 4, 2, 0, 1, 3, 5, 3, 6, 5, 3, 1, 0, 2, 4, 5, 4, 2, 4, 7, 5, 4, 2, 1, 0, 1, 0, -1]
    for i, d in enumerate(mel):
        place(buf, 0.26 * tone(midi(scale_note(67, d)), beat, "pluck", d=0.35), i * beat)
    for i in range(bars * 8):  # weiche Hi-Hat-Achtel
        n = int(0.05 * SR)
        place(buf, 0.035 * rng.standard_normal(n) * np.exp(-np.arange(n) / (0.012 * SR)), i * beat / 2)
    return reverb(buf, 0.2, 0.9)


def music_nature(out):  # 66 bpm + Wind + Vogel
    bpm = 66
    beat = 60 / bpm
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    for b in range(bars):
        for k in [0, 7, 12, 16]:
            place(buf, 0.09 * tone(midi(50 + k), 4 * beat + 1, "sine", a=1.2, d=3, s=0.6, r=1), b * 4 * beat)
    wind = lowpass(rng.standard_normal(L), 600)
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * np.arange(L) / L * 2)
    buf += 0.35 * wind / (np.abs(wind).max()) * lfo * 0.5
    for t0 in [3.1, 9.4, 15.0, 22.3, 27.7]:
        for j in range(3):
            n = int(0.12 * SR)
            tt = np.arange(n) / SR
            f = 2600 + 700 * np.sin(2 * np.pi * (6 + j) * tt) + 600 * tt / 0.12
            ph = 2 * np.pi * np.cumsum(f) / SR
            place(buf, 0.06 * np.sin(ph) * np.hanning(n), t0 + j * 0.17)
    mel = [2, 4, 3, 1, 2, 0, 1, 2]
    for i, d in enumerate(mel):
        place(buf, 0.16 * tone(midi(scale_note(69, d)), 3.5, "harp", d=1.4), i * 4 * beat)
    return reverb(buf, 0.4, 1.8)


def music_adventure(out):  # 96 bpm, d-dorisch angehaucht
    bpm = 96
    beat = 60 / bpm
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    bass = [50, 50, 55, 53]
    for b in range(bars):
        r = bass[b % 4]
        for k in range(8):
            place(buf, 0.2 * tone(midi(r - 12), beat * 0.45, "tri", a=0.004, d=0.15), (b * 8 + k) * beat / 2)
        for k in range(2):  # sanfte Pauke
            n = int(0.25 * SR)
            tt = np.arange(n) / SR
            f = 90 * np.exp(-tt * 12) + 45
            y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 12)
            place(buf, 0.3 * y, (b * 4 + k * 2) * beat)
    scale = [0, 2, 3, 5, 7, 9, 10]
    mel = [0, 2, 4, 5, 4, 2, 1, 2, 4, 6, 7, 6, 4, 2, 1, 0]
    for i, d in enumerate(mel * 2):
        note = 62 + scale[d % 7] + 12 * (d // 7)
        place(buf, 0.22 * tone(midi(note), beat * 1.9, "tri", a=0.02, d=0.8, s=0.15, r=0.2, vib=0.003), i * 2 * beat)
    return reverb(buf, 0.22, 1.1)


def music_sleep(out):  # 46 bpm Spieluhr-Schlaflied
    bpm = 46
    beat = 60 / bpm
    bars = 8
    L = int(bars * 3 * beat * SR)  # 3/4-Takt
    buf = np.zeros(L)
    mel = [4, 2, 4, 2, 3, 1, 0, 1, 2, 4, 3, 2, 1, 2, 0, -1, 0, 1, 2, 4, 2, 1, 0, -2]
    for i, d in enumerate(mel):
        place(buf, 0.3 * tone(midi(scale_note(72, d)), 3.0, "bell", d=1.5) * 0.5, i * beat)
    for b in range(bars):
        root = [48, 45, 43, 48][b % 4]
        place(buf, 0.12 * tone(midi(root), 3 * beat + 1, "sine", a=0.8, d=3, s=0.6, r=1), b * 3 * beat)
        place(buf, 0.07 * tone(midi(root + 7), 3 * beat + 1, "sine", a=0.8, d=3, s=0.6, r=1), b * 3 * beat)
    return reverb(buf, 0.35, 2.0)


def music_calm2(out):  # Harfen-Arpeggien
    bpm = 72
    beat = 60 / bpm
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    chords = [[48, 55, 60, 64, 67], [45, 52, 57, 60, 64], [41, 48, 53, 57, 60], [43, 50, 55, 59, 62]]
    for b in range(bars):
        ch = chords[b % 4]
        for k in range(8):
            n = ch[k % len(ch)] + (12 if k >= 5 else 0)
            place(buf, 0.2 * tone(midi(n), 3, "harp", d=1.3), (b * 4 + k * 0.5) * beat)
    return reverb(buf, 0.4, 2.0)



# ---------- Neue Musikstücke (weitere Stile) ----------
def music_piano_dream(out):  # 60 bpm, ruhiges Klavier, a-Moll/C-Dur-Gefühl
    beat = 60 / 60
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    prog = [(45, [0, 7, 12, 15, 19]), (41, [0, 7, 12, 16, 19]), (48, [0, 7, 12, 16, 19]), (43, [0, 7, 11, 14, 19])]
    for b in range(bars):
        root, ch = prog[b % 4]
        for k, off in enumerate(ch):  # gebrochener Akkord
            place(buf, 0.20 * tone(midi(root + off), 3.2, "piano"), (b * 4 + k * 0.5) * beat)
        for k, off in enumerate(ch[1:4]):
            place(buf, 0.14 * tone(midi(root + off + 12), 2.5, "piano"), (b * 4 + 2.5 + k * 0.5) * beat)
    mel = [(0, 76), (2, 79), (4, 81), (6, 79), (8, 77), (10, 76), (12, 74), (14, 76), (16, 79), (18, 81), (20, 84), (22, 81), (24, 79), (26, 77), (28, 76), (30, 72)]
    for pos, n in mel:
        place(buf, 0.30 * tone(midi(n), 3.0, "piano"), pos * beat * 1.0)
    return reverb(buf, 0.30, 1.8)


def music_ukulele(out):  # 116 bpm, fröhliches Schrammeln + Pfeif-Melodie
    beat = 60 / 116
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    chords = [[60, 64, 67, 72], [57, 60, 64, 69], [53, 57, 60, 65], [55, 59, 62, 67]]
    pattern = [0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
    for b in range(bars):
        ch = chords[b % 4]
        for i, pos in enumerate(pattern):
            if i in (1, 4, 7):
                continue
            for j, n in enumerate(ch):  # Strum: Saiten leicht versetzt
                place(buf, 0.10 * tone(midi(n), 0.5, "pizz"), (b * 4 + pos) * beat + j * 0.012)
    mel = [0, 2, 4, 5, 4, 2, 4, 0, 5, 4, 2, 1, 2, 4, 2, 0]
    for i, d in enumerate(mel * 2):
        place(buf, 0.20 * tone(midi(scale_note(76, d)), beat * 1.8, "sine", a=0.03, d=0.5, s=0.4, r=0.15, vib=0.004), i * 2 * beat)
    return reverb(buf, 0.15, 0.7)


def music_waltz(out):  # 3/4-Walzer, Spieluhr + Streicherpad
    beat = 60 / 138
    bars = 12
    L = int(bars * 3 * beat * SR)
    buf = np.zeros(L)
    prog = [(48, 0), (53, 5), (55, 7), (48, 0)]
    for b in range(bars):
        r, _ = prog[b % 4]
        place(buf, 0.20 * tone(midi(r - 12), beat * 0.9, "pluck", d=0.3), b * 3 * beat)
        for k in (1, 2):
            for off in (0, 4, 7):
                place(buf, 0.07 * tone(midi(r + off), beat * 0.8, "tri", a=0.02, d=0.3), (b * 3 + k) * beat)
        place(buf, 0.05 * tone(midi(r + 12), 3 * beat + 0.5, "sine", a=0.4, d=3, s=0.8, r=0.5), b * 3 * beat)
    mel = [(0, 76), (1.5, 79), (3, 84), (4.5, 83), (6, 81), (7.5, 79), (9, 77), (10.5, 81), (12, 79), (15, 76), (16.5, 77), (18, 79), (21, 84), (24, 83), (25.5, 81), (27, 79), (30, 77), (33, 76)]
    for pos, n in mel:
        place(buf, 0.26 * tone(midi(n), 1.4, "bell", d=0.8) * 0.6, pos * beat)
    return reverb(buf, 0.25, 1.3)


def music_bossa(out):  # 100 bpm, leichter Bossa-Nova-Groove mit Marimba
    beat = 60 / 100
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    prog = [(48, [0, 4, 7, 11]), (50, [0, 3, 7, 10]), (43, [0, 4, 7, 10]), (48, [0, 4, 7, 9])]
    rhythm = [0, 1.5, 3, 4.5, 6, 7]  # Achtel-Positionen (Bossa-Muster)
    for b in range(bars):
        r, ch = prog[b % 4]
        place(buf, 0.20 * tone(midi(r - 12), beat * 1.4, "tri", a=0.01, d=0.5), b * 4 * beat)
        place(buf, 0.16 * tone(midi(r - 5), beat * 1.4, "tri", a=0.01, d=0.5), (b * 4 + 2) * beat)
        for pos in rhythm:
            for off in ch[1:]:
                place(buf, 0.06 * tone(midi(r + off + 12), 0.5, "pluck", d=0.2), (b * 4 + pos * 0.5) * beat)
        for q in range(8):  # Shaker
            n = int(0.04 * SR)
            place(buf, 0.03 * rng.standard_normal(n) * np.exp(-np.arange(n) / (0.01 * SR)), (b * 4 + q * 0.5) * beat)
    mel = [(0, 79), (1.5, 76), (3, 74), (4, 76), (6, 79), (7.5, 83), (8, 81), (9.5, 79), (11, 76), (12, 74), (14, 72), (15, 74), (16, 76), (17.5, 79), (19, 81), (20, 83), (22, 81), (24, 79), (25.5, 76), (27, 74), (28, 72)]
    for pos, n in mel:
        place(buf, 0.24 * tone(midi(n), 0.9, "pluck", d=0.4), pos * beat)
    return reverb(buf, 0.2, 0.9)


def music_rain(out):  # Regen, weiche Pads, vereinzelte Glöckchen
    L = int(32 * SR)
    buf = np.zeros(L)
    noise = lowpass(rng.standard_normal(L), 3500) - lowpass(rng.standard_normal(L), 400)
    drops = np.zeros(L)
    for _ in range(420):  # einzelne Tropfen
        n = int(0.02 * SR)
        place(drops, 0.5 * rng.standard_normal(n) * np.exp(-np.arange(n) / (0.004 * SR)), rng.uniform(0, 32))
    buf += 0.25 * noise / np.abs(noise).max() + 0.25 * lowpass(drops, 6000)
    for b, root in enumerate([48, 45, 41, 43]):
        for off in (0, 7, 12, 16):
            place(buf, 0.07 * tone(midi(root + off), 8.5, "sine", a=2.0, d=6, s=0.8, r=2.0), b * 8)
    for t0, n in [(2, 84), (6, 88), (10.5, 86), (14, 91), (18.5, 84), (22, 88), (26, 86), (29.5, 91)]:
        place(buf, 0.12 * tone(midi(n), 3.0, "bell", d=1.2), t0)
    return reverb(buf, 0.35, 1.8)


def music_march(out):  # 108 bpm, verspielter Marsch mit Zupfbass
    beat = 60 / 108
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    bass = [48, 48, 53, 55, 48, 48, 55, 48]
    for b in range(bars):
        r = bass[b]
        for k in range(4):
            note = r - 12 if k % 2 == 0 else r - 5
            place(buf, 0.24 * tone(midi(note), beat * 0.6, "pizz"), (b * 4 + k) * beat)
        for k in (1, 3):  # Snare-Schlag leise
            n = int(0.09 * SR)
            place(buf, 0.06 * rng.standard_normal(n) * np.exp(-np.arange(n) / (0.02 * SR)), (b * 4 + k) * beat)
    mel = [(0, 72), (1, 72), (1.5, 74), (2, 76), (3, 79), (4, 77), (5, 77), (5.5, 76), (6, 74), (7, 72), (8, 74), (9, 76), (10, 77), (11, 79), (12, 81), (13, 79), (14, 77), (15, 76), (16, 72), (17, 72), (17.5, 74), (18, 76), (19, 79), (20, 84), (21, 83), (22, 81), (23, 79), (24, 77), (25, 76), (26, 74), (27, 76), (28, 72), (30, 72)]
    for pos, n in mel:
        place(buf, 0.22 * tone(midi(n), beat * 0.9, "tri", a=0.01, d=0.3, s=0.2, r=0.1), pos * beat)
    return reverb(buf, 0.12, 0.6)


def music_lofi(out):  # 78 bpm, warme Akkorde, Rauschen, ruhig
    beat = 60 / 78
    bars = 8
    L = int(bars * 4 * beat * SR)
    buf = np.zeros(L)
    prog = [[50, 57, 60, 64], [55, 59, 62, 65], [48, 55, 59, 64], [57, 60, 64, 67]]
    for b in range(bars):
        ch = prog[b % 4]
        for k, pos in enumerate((0, 1.5, 2, 3.5)):
            for n in ch:
                place(buf, 0.07 * tone(midi(n), 1.6, "piano"), (b * 4 + pos) * beat + (k % 2) * 0.01)
        place(buf, 0.18 * tone(midi(ch[0] - 12), beat * 3.5, "sine", a=0.02, d=1.5, s=0.3, r=0.3), b * 4 * beat)
        n = int(0.08 * SR)  # sanfte Kick
        place(buf, 0.25 * np.sin(2 * np.pi * np.cumsum(60 * np.exp(-np.arange(n) / (0.03 * SR)) + 40) / SR) * np.exp(-np.arange(n) / (0.04 * SR)), b * 4 * beat)
        place(buf, 0.25 * np.sin(2 * np.pi * np.cumsum(60 * np.exp(-np.arange(n) / (0.03 * SR)) + 40) / SR) * np.exp(-np.arange(n) / (0.04 * SR)), (b * 4 + 2.5) * beat)
    hiss = lowpass(rng.standard_normal(L), 5000)
    buf += 0.02 * hiss / np.abs(hiss).max()
    mel = [(0.5, 72), (2.5, 74), (5, 76), (7, 72), (9, 74), (10.5, 79), (13, 76), (15.5, 72), (17, 74), (19, 76), (21, 79), (23, 76), (25, 74), (27, 72), (29, 69), (31, 72)]
    for pos, n in mel:
        place(buf, 0.18 * tone(midi(n), 2.0, "piano"), pos * beat)
    return reverb(buf, 0.25, 1.4)


# ---------- Alarme (kurz, sanft, mit Ausklang) ----------
def alarm_bell(out):
    buf = np.zeros(int(3.2 * SR))
    for i, n in enumerate([84, 79, 84]):
        place(buf, 0.5 * tone(midi(n), 2.5, "bell", d=1.5), i * 0.55)
    return reverb(buf, 0.2, 1.0)


def alarm_chime(out):
    buf = np.zeros(int(3.6 * SR))
    for i, n in enumerate([88, 84, 91, 86, 93, 79]):
        place(buf, 0.3 * tone(midi(n), 2.0, "bell", d=1.2), i * 0.22)
    return reverb(buf, 0.3, 1.4)


def alarm_marimba(out):
    buf = np.zeros(int(3.0 * SR))
    for i, n in enumerate([72, 76, 79, 84, 79, 84]):
        place(buf, 0.45 * tone(midi(n), 0.7, "pluck", d=0.25), i * 0.2)
    return reverb(buf, 0.15, 0.7)


def alarm_harp(out):
    buf = np.zeros(int(3.4 * SR))
    for i, n in enumerate([60, 64, 67, 72, 76, 79, 84]):
        place(buf, 0.3 * tone(midi(n), 2.0, "harp", d=1.0), i * 0.14)
    return reverb(buf, 0.3, 1.2)


def alarm_sparkle(out):
    buf = np.zeros(int(3.0 * SR))
    for i in range(14):
        n = [96, 100, 103, 107, 108][i % 5] - (i // 5) * 3
        place(buf, 0.18 * tone(midi(n), 1.2, "bell", d=0.5), i * 0.07)
    return reverb(buf, 0.3, 1.2)


def alarm_music_box(out):
    buf = np.zeros(int(4.0 * SR))
    for i, d in enumerate([4, 2, 3, 4, 5, 4, 2, 0]):
        place(buf, 0.35 * tone(midi(scale_note(76, d)), 1.6, "bell", d=0.9) * 0.6, i * 0.32)
    return reverb(buf, 0.25, 1.2)


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/audio")
    out.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[2:])
    for name, fn in [(k, v) for k, v in globals().items() if k.startswith(("music_", "alarm_")) and callable(v)]:
        if only and name not in only:
            continue
        x = fn(out)
        x = norm(x, 0.45 if name.startswith("music") else 0.7)
        if only and name.startswith("music"):  # neue Stücke auf ähnliche Lautheit wie die bestehenden bringen
            x = np.tanh(x * (0.09 / (np.sqrt((x ** 2).mean()) + 1e-9)) * 1.0) * 0.8
        if name.startswith("alarm"):
            x = fade_ends(x, 20)
            x[-int(0.3 * SR):] *= np.linspace(1, 0, int(0.3 * SR))
        save(name, x, out)


if __name__ == "__main__":
    main()

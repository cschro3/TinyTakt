#!/usr/bin/env python3
"""Setzt Store-Screenshots aus den gerenderten UI-Bildern (build/shots) zusammen.
Aufruf: flutter test test/tools/store_screenshots_test.dart && python3 tools/compose_store_images.py
Hinweis: Es sind Renderings der echten Flutter-UI aus dem Test-Framework, keine Geräte-Screenshots.
Vor der Einreichung sollten Geräte-Screenshots (Simulator/Emulator) ersetzt/ergänzt werden."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

FONT = Path("assets/fonts/Nunito-900.ttf")
CAP = {
    "de": {"1_timer": "Zeit sehen statt zählen", "2_adventure": "Dein Held wandert zum Ziel", "3_fill": "Das Glas leert sich", "4_space": "Regenbogen & Raketen", "5_characters": "71 Figuren zum Aussuchen", "6_parents": "Ruhe für Eltern", "7_pro": "Einmal kaufen – kein Abo"},
    "en": {"1_timer": "See time, don’t count it", "2_adventure": "Your hero walks to the goal", "3_fill": "The glass slowly empties", "4_space": "Rainbows & rockets", "5_characters": "71 friends to choose from", "6_parents": "Peace of mind for parents", "7_pro": "Buy once – no subscription"},
}
OUT = {"iphone_6_9": (1320, 2868), "ipad_13": (2064, 2752), "android_phone": (1080, 1920)}

def compose(src, size, caption):
    W, H = size
    bg = Image.new("RGB", size)
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(91 - 32 * t), int(79 - 32 * t), int(201 - 114 * t)))
    cap_h = int(H * 0.14)
    font = ImageFont.truetype(str(FONT), int(W * 0.062))
    # Text umbrechen
    words, lines, line = caption.split(), [], ""
    for w in words:
        test = (line + " " + w).strip()
        if d.textlength(test, font=font) < W * 0.88: line = test
        else: lines.append(line); line = w
    lines.append(line)
    y = int(cap_h * 0.5 - len(lines) * font.size * 0.6)
    for l in lines:
        d.text(((W - d.textlength(l, font=font)) / 2, y), l, font=font, fill="white"); y += int(font.size * 1.2)
    shot = Image.open(src).convert("RGB")
    sw = int(W * 0.86); sh = int(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    avail = H - cap_h - int(W * 0.04)
    if sh > avail:
        shot = shot.crop((0, 0, sw, avail))
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width, shot.height + 80], radius=int(W * 0.05), fill=255)
    bg.paste(shot, ((W - sw) // 2, cap_h), mask)
    return bg

for loc in ("de", "en"):
    for dev, size in OUT.items():
        for name, cap in CAP[loc].items():
            src = Path(f"build/shots/{loc}/{dev}/{name}.png")
            if not src.exists(): continue
            out = Path(f"store/screenshots/{loc}/{dev}/{name}.png")
            out.parent.mkdir(parents=True, exist_ok=True)
            compose(src, size, cap).save(out, optimize=True)

# Feature Graphic 1024x500 (Google Play)
for loc, title, sub in (("de", "TinyTakt", "Mein kleiner Zeitheld"), ("en", "TinyTakt", "My little time hero")):
    g = Image.new("RGB", (1024, 500)); d = ImageDraw.Draw(g)
    for x in range(1024):
        t = x / 1024; d.line([(x, 0), (x, 500)], fill=(int(91 - 40 * t), int(79 - 40 * t), int(201 - 100 * t)))
    hero = Image.open("assets/brand/splash_hero.png").convert("RGBA").resize((400, 400))
    g.paste(hero, (80, 60), hero)
    f1 = ImageFont.truetype(str(FONT), 96); f2 = ImageFont.truetype(str(FONT), 40)
    d.text((520, 150), title, font=f1, fill="white"); d.text((524, 270), sub, font=f2, fill=(255, 200, 61))
    out = Path(f"store/feature_graphic_{loc}.png"); out.parent.mkdir(exist_ok=True, parents=True); g.save(out)
print("fertig")

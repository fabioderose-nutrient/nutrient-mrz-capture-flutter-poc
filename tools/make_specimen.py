"""Draws the synthetic passport data page bundled with the app (ICAO 9303 'Utopia' specimen data, no real person).

Usage: python3 tools/make_specimen.py [output.jpg]   (default: assets/samples/specimen_passport.jpg)
Needs Pillow. Fonts: Andale Mono (MRZ) and Arial from macOS (OCR-B is not shipped with macOS);
set SPECIMEN_FONT_DIR to a folder with the same .ttf files on other systems.
"""
import os
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONTS = Path(os.environ.get("SPECIMEN_FONT_DIR", "/System/Library/Fonts/Supplemental"))
MONO = str(FONTS / "Andale Mono.ttf")
SANS = str(FONTS / "Arial.ttf")
SANS_B = str(FONTS / "Arial Bold.ttf")

PX_PER_MM = 12
MRZ = [
    "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
    "L898902C36UTO7408122F1204159ZE184226B<<<<<10",
]


def mm(v):
    return int(v * PX_PER_MM)


def main(out):
    w, h = mm(125), mm(88)
    rnd = random.Random(3)
    img = Image.new("RGB", (w, h), (236, 240, 232))
    d = ImageDraw.Draw(img)
    for _ in range(140):  # faint guilloche-like curves
        x, y, r = rnd.randint(0, w), rnd.randint(0, h), rnd.randint(40, 260)
        d.arc((x - r, y - r, x + r, y + r), rnd.randint(0, 360), rnd.randint(0, 360), fill=(214, 222, 210), width=2)
    label = ImageFont.truetype(SANS, mm(2.0))
    value = ImageFont.truetype(SANS_B, mm(3.0))
    title = ImageFont.truetype(SANS_B, mm(4.0))
    d.text((mm(6), mm(4)), "UTOPIA", font=title, fill=(30, 50, 110))
    d.text((mm(48), mm(4)), "PASSPORT", font=title, fill=(30, 50, 110))
    # Portrait placeholder, no face.
    d.rounded_rectangle((mm(6), mm(18), mm(38), mm(60)), radius=mm(1.5), fill=(190, 196, 205))
    d.ellipse((mm(14), mm(24), mm(30), mm(42)), fill=(150, 156, 168))
    d.rounded_rectangle((mm(10), mm(43), mm(34), mm(60)), radius=mm(6), fill=(150, 156, 168))
    fields = [
        ("Type", "P", 48, 12), ("Code", "UTO", 66, 12), ("Passport No.", "L898902C3", 86, 12),
        ("Surname", "ERIKSSON", 48, 20), ("Given names", "ANNA MARIA", 48, 28),
        ("Nationality", "UTOPIAN", 48, 36), ("Date of birth", "12 AUG 74", 48, 44),
        ("Sex", "F", 100, 44), ("Place of birth", "ZENITH", 48, 52),
        ("Date of issue", "16 APR 07", 48, 60), ("Date of expiry", "15 APR 12", 88, 60),
    ]
    for lab, val, x, y in fields:
        d.text((mm(x), mm(y)), lab, font=label, fill=(80, 80, 90))
        d.text((mm(x), mm(y + 2.4)), val, font=value, fill=(20, 20, 30))
    pitch = 2.54 * PX_PER_MM  # OCR-B character pitch
    mono = ImageFont.truetype(MONO, int(pitch / 0.6))
    for i, line in enumerate(MRZ):
        for j, c in enumerate(line):
            d.text((mm(6) + j * pitch, mm(72) + i * mm(4.6)), c, font=mono, fill=(20, 20, 25))
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    img.save(out, quality=90)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/samples/specimen_passport.jpg")

#!/usr/bin/env python3
"""Generate Forester Lodge and Sapling sprites (Task 8 only — does not overwrite v3 art)."""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

T = (0, 0, 0, 0)
DK = (34, 24, 16, 255)
BR = (92, 58, 30, 255)
BR2 = (120, 76, 42, 255)
BR3 = (68, 42, 22, 255)
G0 = (24, 72, 32, 255)
G1 = (38, 104, 44, 255)
G2 = (58, 138, 58, 255)
G3 = (88, 176, 72, 255)
G4 = (140, 210, 96, 255)
GR = (72, 132, 48, 255)
GR2 = (96, 156, 64, 255)
ST = (136, 134, 146, 255)
SD = (82, 84, 98, 255)
SD2 = (58, 60, 72, 255)
WD = (168, 118, 62, 255)
WL = (210, 162, 88, 255)
WD2 = (130, 84, 44, 255)
YL = (236, 200, 72, 255)
RK = (108, 108, 118, 255)
RK2 = (78, 78, 88, 255)
LG = (118, 168, 88, 255)
LG2 = (156, 210, 118, 255)


def img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), T)


def px(im: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, c) -> None:
    for y in range(y0, y1):
        for x in range(x0, x1):
            px(im, x, y, c)


def ellipse(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / max(rx, 1)
            dy = (y - cy) / max(ry, 1)
            if dx * dx + dy * dy <= 1.0:
                px(im, x, y, c)


def sapling() -> Image.Image:
    """40x52 young tree with thin trunk and small bright canopy."""
    im = img(40, 52)
    ellipse(im, 20, 48, 14, 4, GR)
    ellipse(im, 20, 49, 12, 3, GR2)
    rect(im, 10, 46, 30, 51, G0)
    px(im, 14, 47, G2)
    px(im, 26, 47, G1)
    rect(im, 18, 30, 22, 47, BR3)
    rect(im, 19, 28, 21, 46, BR)
    px(im, 18, 34, WD2)
    px(im, 21, 38, BR3)
    ellipse(im, 20, 20, 11, 9, G0)
    ellipse(im, 18, 18, 8, 7, G1)
    ellipse(im, 22, 17, 7, 6, G2)
    ellipse(im, 20, 12, 6, 5, G2)
    ellipse(im, 20, 10, 4, 3, G4)
    px(im, 17, 14, LG2)
    px(im, 23, 12, LG)
    return im


def forester_lodge() -> Image.Image:
    """64x64 nursery lodge with seedling beds and green roof trim."""
    im = img(64, 64)
    rect(im, 4, 34, 60, 63, SD2)
    rect(im, 5, 35, 59, 62, SD)
    for y in range(18, 36, 3):
        rect(im, 6, y, 58, y + 2, WD2 if (y // 3) % 2 else WD)
        px(im, 6, y, BR3)
        px(im, 57, y, BR3)
    for i in range(12):
        rect(im, 12 + i, 8 + i // 2, 52 - i, 14 + i // 2, BR if i % 2 else BR2)
    rect(im, 18, 4, 46, 10, LG)
    rect(im, 20, 3, 44, 8, LG2)
    rect(im, 46, 6, 50, 16, ST)
    rect(im, 8, 38, 28, 58, (36, 72, 40, 255))
    rect(im, 9, 39, 27, 57, (28, 58, 32, 255))
    for sx, sy in [(12, 44), (18, 46), (24, 44)]:
        rect(im, sx, sy, sx + 2, sy + 5, BR)
        ellipse(im, sx + 1, sy - 1, 2, 2, G3)
    rect(im, 34, 38, 56, 58, (44, 92, 48, 255))
    rect(im, 35, 39, 55, 57, (34, 78, 38, 255))
    for sx, sy in [(40, 44), (48, 46)]:
        rect(im, sx, sy, sx + 2, sy + 5, BR)
        ellipse(im, sx + 1, sy - 1, 2, 2, G2)
    rect(im, 28, 38, 34, 58, DK)
    rect(im, 29, 39, 33, 57, BR3)
    px(im, 32, 48, YL)
    rect(im, 10, 16, 18, 22, (62, 118, 168, 255))
    rect(im, 46, 16, 54, 22, (62, 118, 168, 255))
    rect(im, 22, 12, 42, 16, YL)
    rect(im, 24, 13, 40, 15, (248, 228, 120, 255))
    px(im, 30, 14, G1)
    px(im, 34, 14, G1)
    return im


def main() -> None:
    sapling().save(OUT / "sapling.png")
    forester_lodge().save(OUT / "forester_lodge.png")
    print(f"Wrote Task 8 sprites to {OUT}")


if __name__ == "__main__":
    main()

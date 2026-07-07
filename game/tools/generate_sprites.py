#!/usr/bin/env python3
"""Generate cozy forest pixel art sprites for City Siege."""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

T = (0, 0, 0, 0)
# Forest palette
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
CR = (150, 98, 52, 255)
BL = (62, 118, 168, 255)
BD = (40, 72, 108, 255)
BL2 = (88, 148, 196, 255)
YL = (236, 200, 72, 255)
SK = (244, 194, 148, 255)
SH = (92, 68, 128, 255)
SH2 = (118, 92, 156, 255)
HT = (64, 46, 92, 255)
RK = (108, 108, 118, 255)
RK2 = (78, 78, 88, 255)


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


def mature_tree() -> Image.Image:
    """48x64 tree with layered canopy, gnarled trunk, grass and stones."""
    im = img(48, 64)
    # grass mound
    ellipse(im, 24, 60, 20, 5, GR)
    ellipse(im, 24, 61, 18, 4, GR2)
    rect(im, 8, 58, 40, 63, G0)
    px(im, 12, 59, G2)
    px(im, 18, 60, G3)
    px(im, 30, 59, G2)
    px(im, 35, 60, G1)
    # stones
    rect(im, 14, 60, 17, 63, RK)
    px(im, 14, 60, RK2)
    rect(im, 32, 61, 35, 63, RK2)
    px(im, 34, 61, ST)
    # trunk - gnarled
    rect(im, 20, 38, 28, 59, BR3)
    rect(im, 21, 36, 27, 58, BR)
    rect(im, 22, 35, 26, 57, BR2)
    px(im, 20, 42, BR3)
    px(im, 27, 44, BR3)
    px(im, 21, 50, WD2)
    px(im, 26, 52, WD2)
    # branches
    rect(im, 16, 34, 20, 37, BR)
    rect(im, 28, 33, 32, 36, BR)
    # canopy clumps with highlights
    for cx, cy, rx, ry, base, mid, hi in [
        (24, 22, 14, 12, G0, G1, G3),
        (16, 26, 9, 8, G0, G2, G4),
        (32, 25, 9, 8, G0, G2, G3),
        (24, 14, 10, 8, G1, G2, G4),
        (12, 20, 7, 6, G0, G1, G2),
        (36, 19, 7, 6, G0, G1, G2),
    ]:
        ellipse(im, cx, cy, rx, ry, base)
        ellipse(im, cx - 2, cy - 1, rx - 3, ry - 2, mid)
        ellipse(im, cx - 3, cy - 2, max(2, rx - 5), max(2, ry - 4), hi)
    return im


def lumber_camp() -> Image.Image:
    im = img(48, 48)
    # stone foundation
    rect(im, 2, 28, 46, 47, SD2)
    rect(im, 3, 29, 45, 46, SD)
    # log walls
    for y in range(16, 30, 3):
        rect(im, 4, y, 44, y + 2, WD2 if (y // 3) % 2 else WD)
        px(im, 4, y, BR3)
        px(im, 43, y, BR3)
    # peaked roof
    for i in range(10):
        rect(im, 10 + i, 8 + i // 2, 38 - i, 12 + i // 2, BR if i % 2 else BR2)
    rect(im, 14, 4, 34, 10, BR2)
    rect(im, 16, 3, 32, 6, BR)
    # chimney
    rect(im, 34, 2, 38, 12, SD)
    rect(im, 35, 1, 37, 3, ST)
    px(im, 36, 0, ST)
    # door
    rect(im, 20, 30, 28, 46, DK)
    rect(im, 21, 31, 27, 45, BR3)
    px(im, 26, 38, YL)
    # saw + logs
    rect(im, 6, 32, 12, 38, WL)
    rect(im, 7, 33, 11, 37, WD)
    rect(im, 36, 34, 42, 36, ST)
    px(im, 42, 33, SD)
    return im


def warehouse() -> Image.Image:
    im = img(48, 48)
    rect(im, 2, 10, 46, 47, SD2)
    rect(im, 3, 11, 45, 46, ST)
    rect(im, 2, 6, 46, 12, DK)
    rect(im, 3, 7, 45, 11, SD)
    # roof trim
    rect(im, 4, 6, 44, 8, SD2)
    px(im, 6, 5, ST)
    px(im, 40, 5, ST)
    # large doors
    rect(im, 12, 24, 36, 46, DK)
    rect(im, 13, 25, 23, 45, BR3)
    rect(im, 25, 25, 35, 45, BR3)
    px(im, 18, 34, BR2)
    px(im, 30, 34, BR2)
    # crate stacks
    for ox in (5, 37):
        rect(im, ox, 28, ox + 6, 38, CR)
        rect(im, ox + 1, 29, ox + 5, 37, WD)
        rect(im, ox + 1, 24, ox + 5, 28, WD2)
    # windows
    rect(im, 8, 16, 12, 20, BL2)
    rect(im, 36, 16, 40, 20, BL2)
    return im


def hauler_station() -> Image.Image:
    im = img(48, 48)
    rect(im, 2, 12, 46, 47, BD)
    rect(im, 3, 13, 45, 46, BL)
    rect(im, 2, 8, 46, 14, DK)
    rect(im, 3, 9, 45, 13, BD)
    # bay
    rect(im, 14, 20, 34, 44, (18, 36, 56, 255))
    rect(im, 15, 21, 33, 43, (10, 24, 40, 255))
    # sign
    rect(im, 34, 8, 42, 14, YL)
    rect(im, 35, 9, 41, 13, (248, 228, 120, 255))
    px(im, 37, 10, DK)
    px(im, 39, 10, DK)
    # barrels and cart wheel
    ellipse(im, 10, 40, 4, 4, CR)
    ellipse(im, 38, 40, 4, 4, CR)
    rect(im, 6, 18, 10, 26, BL2)
    rect(im, 38, 18, 42, 26, BL2)
    return im


def wood_log() -> Image.Image:
    im = img(16, 12)
    rect(im, 2, 3, 14, 9, WD2)
    rect(im, 3, 4, 13, 8, WD)
    rect(im, 4, 5, 12, 7, WL)
    px(im, 2, 5, BR3)
    px(im, 13, 6, BR3)
    # rings
    px(im, 8, 5, BR2)
    px(im, 8, 6, BR)
    px(im, 7, 6, WD2)
    return im


def wood_log_pile() -> Image.Image:
    im = img(24, 16)
    for i, (x, y) in enumerate([(4, 8), (10, 6), (16, 8), (7, 11), (13, 11)]):
        log = wood_log()
        im.paste(log, (x, y), log)
    return im


def hauler_frame(step: int) -> Image.Image:
    im = img(24, 24)
    # head
    rect(im, 9, 3, 15, 9, SK)
    rect(im, 9, 2, 15, 5, HT)
    px(im, 11, 6, DK)
    px(im, 13, 6, DK)
    # body
    rect(im, 8, 9, 16, 16, SH)
    rect(im, 9, 10, 15, 15, SH2)
    # arms
    if step % 2 == 0:
        rect(im, 5, 10, 8, 14, SH)
        rect(im, 16, 11, 19, 15, SH2)
    else:
        rect(im, 5, 11, 8, 15, SH2)
        rect(im, 16, 10, 19, 14, SH)
    # legs - 4 phases
    leg_sets = [
        [(8, 16, 11, 21), (13, 16, 16, 20)],
        [(8, 16, 11, 20), (13, 16, 16, 22)],
        [(8, 16, 11, 22), (13, 16, 16, 21)],
        [(8, 16, 11, 21), (13, 16, 16, 20)],
    ]
    for x0, y0, x1, y1 in leg_sets[step % 4]:
        rect(im, x0, y0, x1, y1, DK)
        px(im, x0, y1 - 1, BR3)
    return im


def hauler_walk_sheet() -> Image.Image:
    sheet = img(96, 24)
    for i in range(4):
        sheet.paste(hauler_frame(i), (i * 24, 0))
    return sheet


def main() -> None:
    mature_tree().save(OUT / "mature_tree.png")
    lumber_camp().save(OUT / "lumber_camp.png")
    warehouse().save(OUT / "warehouse.png")
    hauler_station().save(OUT / "hauler_station.png")
    wood_log().save(OUT / "wood_log.png")
    wood_log_pile().save(OUT / "wood_log_pile.png")
    hauler_walk_sheet().save(OUT / "hauler_worker_walk.png")
    hauler_frame(0).save(OUT / "hauler_worker.png")
    print(f"Wrote v2 sprites to {OUT}")


if __name__ == "__main__":
    main()

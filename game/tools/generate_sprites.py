#!/usr/bin/env python3
"""Generate 32x32 pixel art sprites for City Siege art pass."""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

# Palette: cozy forest village
T = (0, 0, 0, 0)  # transparent
DK = (34, 24, 16, 255)
BR = (92, 58, 30, 255)
LG = (48, 118, 52, 255)
MD = (30, 92, 38, 255)
HL = (118, 196, 72, 255)
ST = (120, 118, 128, 255)
SD = (74, 76, 88, 255)
WD = (168, 118, 62, 255)
WL = (206, 158, 82, 255)
CR = (140, 92, 48, 255)
BL = (58, 110, 158, 255)
BD = (36, 68, 102, 255)
YL = (232, 196, 64, 255)
SK = (240, 188, 140, 255)
SH = (84, 62, 120, 255)
HT = (62, 44, 92, 255)
LG2 = (196, 132, 64, 255)


def img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), T)


def px(im: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, c) -> None:
    for y in range(y0, y1):
        for x in range(x0, x1):
            px(im, x, y, c)


def mature_tree() -> Image.Image:
    im = img(32, 32)
    # trunk
    rect(im, 14, 20, 18, 31, BR)
    rect(im, 15, 20, 17, 31, WD)
    px(im, 14, 19, DK)
    # canopy layers
    for y, row in enumerate(
        [
            "...........##...........",
            "..........####..........",
            "........########........",
            ".......##########.......",
            "......###########......",
            ".....#############.....",
            "....#######MM#######....",
            "....####LLLLLL####....",
            ".....###LLHHLL###.....",
            "......##LLLLLL##......",
            ".......########.......",
            "........######........",
        ]
    ):
        for x, ch in enumerate(row):
            if ch == "#":
                px(im, x, 4 + y, MD)
            elif ch == "M":
                px(im, x, 4 + y, LG)
            elif ch == "L":
                px(im, x, 4 + y, LG)
            elif ch == "H":
                px(im, x, 4 + y, HL)
    return im


def lumber_camp() -> Image.Image:
    im = img(32, 32)
    rect(im, 2, 10, 30, 31, WD)
    rect(im, 3, 11, 29, 30, WL)
    rect(im, 1, 8, 31, 12, DK)
    rect(im, 2, 9, 30, 11, BR)
    # roof peak
    for i in range(6):
        rect(im, 8 + i, 6 - i // 2, 24 - i, 9 - i // 2, BR)
    rect(im, 10, 4, 22, 8, WD)
    # door
    rect(im, 13, 18, 19, 30, DK)
    rect(im, 14, 19, 18, 30, BR)
    # saw
    rect(im, 22, 14, 27, 18, ST)
    px(im, 27, 15, SD)
    px(im, 21, 16, ST)
    # chimney smoke hint
    px(im, 6, 3, SD)
    px(im, 7, 2, ST)
    return im


def warehouse() -> Image.Image:
    im = img(32, 32)
    rect(im, 1, 6, 31, 31, SD)
    rect(im, 2, 7, 30, 30, ST)
    rect(im, 1, 4, 31, 8, DK)
    rect(im, 2, 5, 30, 7, SD)
    # big doors
    rect(im, 8, 16, 24, 30, DK)
    rect(im, 9, 17, 15, 29, BR)
    rect(im, 17, 17, 23, 29, BR)
    # crates
    rect(im, 4, 20, 8, 26, CR)
    rect(im, 5, 21, 7, 25, WD)
    rect(im, 24, 20, 28, 26, CR)
    rect(im, 25, 21, 27, 25, WD)
    # roof highlight
    rect(im, 3, 5, 29, 6, ST)
    return im


def hauler_station() -> Image.Image:
    im = img(32, 32)
    rect(im, 2, 8, 30, 31, BD)
    rect(im, 3, 9, 29, 30, BL)
    rect(im, 2, 5, 30, 10, DK)
    rect(im, 3, 6, 29, 9, BD)
    # bay opening
    rect(im, 9, 14, 23, 28, DK)
    rect(im, 10, 15, 22, 27, (24, 44, 68, 255))
    # sign
    rect(im, 23, 6, 29, 10, YL)
    px(im, 25, 7, DK)
    px(im, 27, 7, DK)
    # wheel/barrel
    rect(im, 5, 22, 8, 26, CR)
    rect(im, 24, 22, 27, 26, CR)
    return im


def wood_log() -> Image.Image:
    im = img(8, 8)
    rect(im, 1, 2, 7, 6, WD)
    rect(im, 2, 3, 6, 5, WL)
    px(im, 1, 3, BR)
    px(im, 6, 4, BR)
    return im


def hauler_frame(step: int) -> Image.Image:
    im = img(16, 16)
    # head
    rect(im, 6, 2, 10, 6, SK)
    rect(im, 6, 1, 10, 3, HT)
    # body
    rect(im, 5, 6, 11, 11, SH)
    rect(im, 6, 7, 10, 10, (108, 82, 148, 255))
    # legs alternate
    if step == 0:
        rect(im, 5, 11, 7, 14, DK)
        rect(im, 9, 11, 11, 13, DK)
        px(im, 6, 14, BR)
        px(im, 10, 13, BR)
    else:
        rect(im, 5, 11, 7, 13, DK)
        rect(im, 9, 11, 11, 14, DK)
        px(im, 6, 13, BR)
        px(im, 10, 14, BR)
    # arms
    rect(im, 3, 7, 5, 10, SH)
    rect(im, 11, 7, 13, 10, SH)
    return im


def hauler_walk_sheet() -> Image.Image:
    sheet = img(32, 16)
    for i in range(2):
        frame = hauler_frame(i)
        sheet.paste(frame, (i * 16, 0))
    return sheet


def main() -> None:
    mature_tree().save(OUT / "mature_tree.png")
    lumber_camp().save(OUT / "lumber_camp.png")
    warehouse().save(OUT / "warehouse.png")
    hauler_station().save(OUT / "hauler_station.png")
    wood_log().save(OUT / "wood_log.png")
    hauler_walk_sheet().save(OUT / "hauler_worker_walk.png")
    hauler_frame(0).save(OUT / "hauler_worker.png")
    print(f"Wrote sprites to {OUT}")


if __name__ == "__main__":
    main()

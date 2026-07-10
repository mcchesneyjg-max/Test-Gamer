#!/usr/bin/env python3
"""Generate 32x32 walk sprite sheets for each worker role."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
FRAME_SIZE = 32
WALK_FRAMES = 4

T = (0, 0, 0, 0)
OL = (42, 28, 18, 255)
SK = (244, 194, 148, 255)
DK = (34, 24, 16, 255)
BR = (92, 58, 30, 255)
BR2 = (120, 76, 42, 255)
WD = (168, 118, 62, 255)
WD2 = (130, 84, 44, 255)
G1 = (38, 104, 44, 255)
G2 = (58, 138, 58, 255)
G3 = (88, 176, 72, 255)
OR = (214, 132, 58, 255)
OR2 = (236, 168, 82, 255)
BL = (62, 118, 168, 255)
BL2 = (88, 148, 196, 255)
HT = (64, 46, 92, 255)
SH = (92, 68, 128, 255)
SH2 = (118, 92, 156, 255)
RK = (108, 108, 118, 255)
RK2 = (78, 78, 88, 255)
YL = (236, 200, 72, 255)

LEG_SETS = [
    [(11, 22, 14, 29), (17, 22, 20, 28)],
    [(11, 22, 14, 28), (17, 22, 20, 30)],
    [(11, 22, 14, 30), (17, 22, 20, 29)],
    [(11, 22, 14, 29), (17, 22, 20, 28)],
]

ARM_SETS = [
    ((7, 13, 10, 18), (21, 14, 24, 19)),
    ((7, 14, 10, 19), (21, 13, 24, 18)),
    ((7, 13, 10, 18), (21, 14, 24, 19)),
    ((7, 14, 10, 19), (21, 13, 24, 18)),
]


def img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), T)


def px(im: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, c) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(im, x, y, c)


def outline_rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, fill, edge=OL) -> None:
    rect(im, x0, y0, x1, y1, fill)
    for x in range(x0, x1 + 1):
        px(im, x, y0, edge)
        px(im, x, y1, edge)
    for y in range(y0, y1 + 1):
        px(im, x0, y, edge)
        px(im, x1, y, edge)


def draw_head(im: Image.Image, hair: tuple, hat: tuple | None = None) -> None:
    outline_rect(im, 12, 4, 19, 11, SK)
    rect(im, 13, 5, 18, 10, SK)
    rect(im, 12, 4, 19, 6, hair)
    px(im, 14, 8, DK)
    px(im, 17, 8, DK)
    if hat is not None:
        rect(im, 11, 3, 20, 5, hat)
        px(im, 11, 3, OL)
        px(im, 20, 3, OL)


def draw_body(im: Image.Image, shirt: tuple, shirt_hi: tuple, belt: tuple | None = None) -> None:
    outline_rect(im, 11, 12, 20, 21, shirt)
    rect(im, 12, 13, 19, 20, shirt_hi)
    if belt is not None:
        rect(im, 11, 19, 20, 20, belt)


def draw_limbs(im: Image.Image, step: int, pants: tuple, boot: tuple) -> None:
    left_arm, right_arm = ARM_SETS[step % 4]
    outline_rect(im, *left_arm, pants)
    outline_rect(im, *right_arm, pants)
    for leg in LEG_SETS[step % 4]:
        outline_rect(im, *leg, pants)
        px(im, leg[0], leg[3], boot)
        px(im, leg[2], leg[3], boot)


def draw_lumberjack(step: int) -> Image.Image:
    im = img(FRAME_SIZE, FRAME_SIZE)
    draw_head(im, BR2, BR)
    draw_body(im, OR, OR2, WD2)
    draw_limbs(im, step, BR, DK)
    # plaid hint
    px(im, 13, 14, BR)
    px(im, 15, 16, BR)
    px(im, 17, 18, BR)
    # axe on back
    rect(im, 22, 10, 23, 18, RK2)
    rect(im, 23, 9, 25, 11, RK)
    return im


def draw_forester(step: int) -> Image.Image:
    im = img(FRAME_SIZE, FRAME_SIZE)
    draw_head(im, G2, G1)
    draw_body(im, G2, G3, BR2)
    draw_limbs(im, step, G1, BR)
    # seed satchel
    outline_rect(im, 21, 15, 25, 19, BR2)
    rect(im, 22, 16, 24, 18, WD)
    px(im, 23, 17, G3)
    return im


def draw_hauler(step: int) -> Image.Image:
    im = img(FRAME_SIZE, FRAME_SIZE)
    draw_head(im, HT, SH)
    draw_body(im, SH, SH2, YL)
    draw_limbs(im, step, RK2, DK)
    # shoulder pack
    outline_rect(im, 20, 13, 25, 18, BR2)
    rect(im, 21, 14, 24, 17, WD)
    return im


def draw_player(step: int) -> Image.Image:
    im = img(FRAME_SIZE, FRAME_SIZE)
    draw_head(im, BR, BL)
    draw_body(im, BL, BL2, BR2)
    draw_limbs(im, step, BR, DK)
    # small cape
    rect(im, 9, 13, 10, 20, BL2)
    px(im, 9, 13, OL)
    return im


def save_sheet(name: str, drawer) -> None:
    sheet = img(FRAME_SIZE * WALK_FRAMES, FRAME_SIZE)
    for i in range(WALK_FRAMES):
        frame = drawer(i)
        sheet.paste(frame, (i * FRAME_SIZE, 0), frame)
    sheet.save(OUT / f"{name}.png")
    drawer(0).save(OUT / f"{name.replace('_walk', '')}.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    save_sheet("lumberjack_worker_walk", draw_lumberjack)
    save_sheet("forester_worker_walk", draw_forester)
    save_sheet("hauler_worker_walk", draw_hauler)
    save_sheet("player_walk", draw_player)
    print("Wrote worker walk sheets to", OUT)


if __name__ == "__main__":
    main()

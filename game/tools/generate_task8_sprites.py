#!/usr/bin/env python3
"""Generate Forester Lodge (3 levels) and Sapling sprites.

All lodge levels share a 128x128 canvas (= 4x4 tiles). The building art grows
within that fixed footprint as the lodge is upgraded.
"""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

CANVAS = 128

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
DIRT = (118, 86, 52, 255)
DIRT2 = (92, 66, 38, 255)
PINE = (28, 88, 38, 255)
PINE2 = (42, 118, 48, 255)
PINE3 = (62, 148, 58, 255)
FLAG = (48, 148, 58, 255)
FLAG2 = (72, 188, 78, 255)
SNOW = (228, 236, 244, 255)


def img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), T)


def px(im: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, c) -> None:
    for y in range(y0, y1):
        for x in range(x0, x1):
            px(im, x, y, c)


def hline(im: Image.Image, x0: int, x1: int, y: int, c) -> None:
    rect(im, x0, x1, y, y + 1, c)


def vline(im: Image.Image, x: int, y0: int, y1: int, c) -> None:
    rect(im, x, x + 1, y0, y1, c)


def ellipse(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / max(rx, 1)
            dy = (y - cy) / max(ry, 1)
            if dx * dx + dy * dy <= 1.0:
                px(im, x, y, c)


def draw_shared_ground(im: Image.Image) -> None:
    """Grass + dirt path + fence for every lodge level (fixed 4x4 footprint)."""
    rect(im, 0, 96, CANVAS, CANVAS, G0)
    for x in range(0, CANVAS, 8):
        for y in range(96, CANVAS, 8):
            if (x + y) % 16 == 0:
                rect(im, x, y, x + 4, y + 4, G1)
    rect(im, 52, 108, 76, CANVAS, DIRT)
    rect(im, 54, 110, 74, CANVAS, DIRT2)
    hline(im, 0, CANVAS, 96, GR)
    hline(im, 0, CANVAS, 97, GR2)
    for x in range(8, CANVAS - 8, 16):
        rect(im, x, 98, x + 2, 104, WD2)
        rect(im, x + 1, 98, x + 3, 103, WD)
    rect(im, 0, 98, 8, 104, BR3)
    rect(im, CANVAS - 8, 98, CANVAS, 104, BR3)


def draw_corner_tree(im: Image.Image, cx: int, cy: int) -> None:
    rect(im, cx - 1, cy + 6, cx + 1, cy + 12, BR3)
    ellipse(im, cx, cy + 2, 5, 4, PINE)
    ellipse(im, cx, cy - 1, 4, 3, PINE2)
    ellipse(im, cx, cy - 4, 3, 2, PINE3)


def draw_flag(im: Image.Image, x: int, y: int) -> None:
    vline(im, x, y, y + 18, BR3)
    rect(im, x + 1, y, x + 10, y + 7, FLAG)
    rect(im, x + 2, y + 1, x + 9, y + 6, FLAG2)
    px(im, x + 5, y + 2, G4)
    px(im, x + 4, y + 3, G3)
    px(im, x + 6, y + 4, G2)


def draw_log_stack(im: Image.Image, x: int, y: int, count: int) -> None:
    for i in range(count):
        row = i // 3
        col = i % 3
        lx = x + col * 6
        ly = y - row * 5
        rect(im, lx, ly, lx + 5, ly + 3, WD)
        rect(im, lx, ly, lx + 5, ly + 1, WL)
        px(im, lx, ly + 2, WD2)


def draw_log_lean_to(im: Image.Image, x: int, y: int, w: int, h: int, logs: int) -> None:
    rect(im, x, y - h, x + w, y, BR3)
    for i in range(0, w, 4):
        vline(im, x + i, y - h, y, BR if i % 8 else BR2)
    hline(im, x, x + w, y - h, BR2)
    draw_log_stack(im, x + 4, y - 2, logs)


def draw_window(im: Image.Image, x: int, y: int, w: int, h: int) -> None:
    rect(im, x, y, x + w, y + h, DK)
    rect(im, x + 1, y + 1, x + w - 1, y + h - 1, (62, 118, 168, 255))
    vline(im, x + w // 2, y + 1, y + h - 1, WL)
    hline(im, x + 1, x + w - 1, y + h // 2, WL)


def draw_door(im: Image.Image, x: int, y: int, h: int) -> None:
    """Person-scale door (~22px tall for 32px workers)."""
    rect(im, x, y - h, x + 10, y, BR3)
    rect(im, x + 1, y - h + 1, x + 9, y - 1, WD)
    for dy in range(4, h - 2, 5):
        hline(im, x + 2, x + 8, y - dy, WD2)
    px(im, x + 8, y - h // 2, YL)


def draw_log_wall(im: Image.Image, x0: int, y0: int, x1: int, y1: int) -> None:
    for y in range(y0, y1, 4):
        color = WD if ((y - y0) // 4) % 2 == 0 else WD2
        rect(im, x0, y, x1, min(y + 3, y1), color)
        hline(im, x0, x1, y, BR3)


def draw_roof(im: Image.Image, x0: int, y0: int, x1: int, peak_y: int) -> None:
    width = x1 - x0
    steps = width // 2
    for i in range(steps):
        yy = y0 + i // 2
        rect(im, x0 + i, yy, x1 - i, yy + 4, BR if i % 2 else BR2)
    rect(im, x0 + steps - 4, peak_y, x0 + steps + 4, peak_y + 3, LG)
    rect(im, x0 + steps - 2, peak_y - 2, x0 + steps + 2, peak_y + 1, LG2)


def draw_stone_base(im: Image.Image, x0: int, y0: int, x1: int, y1: int) -> None:
    rect(im, x0, y0, x1, y1, SD2)
    for y in range(y0, y1, 4):
        for x in range(x0, x1, 6):
            rect(im, x, y, min(x + 5, x1), min(y + 3, y1), SD if (x + y) % 12 else ST)


def draw_chimney(im: Image.Image, x: int, y: int, h: int) -> None:
    rect(im, x, y - h, x + 8, y, ST)
    rect(im, x + 1, y - h + 1, x + 7, y - 1, RK)
    rect(im, x, y - h - 3, x + 8, y - h, SD)
    px(im, x + 3, y - h - 4, RK2)


def forester_lodge_l1() -> Image.Image:
    """Level 1 — basic log cabin, small within the 4x4 footprint."""
    im = img(CANVAS, CANVAS)
    draw_shared_ground(im)
    draw_corner_tree(im, 16, 82)
    draw_corner_tree(im, 112, 80)

    bx0, by = 44, 98
    bw, bh = 40, 34
    bx1 = bx0 + bw
    draw_log_wall(im, bx0, by - bh, bx1, by)
    draw_roof(im, bx0 - 4, by - bh - 10, bx1 + 4, by - bh - 12)
    draw_door(im, bx0 + 15, by, 22)
    draw_window(im, bx0 + 4, by - 22, 8, 8)
    draw_window(im, bx1 - 12, by - 22, 8, 8)
    draw_flag(im, bx1 + 6, by - bh - 8)
    draw_log_lean_to(im, bx1 + 2, by, 18, 14, 4)
    return im


def forester_lodge_l2() -> Image.Image:
    """Level 2 — stone foundation, porch, taller roof."""
    im = img(CANVAS, CANVAS)
    draw_shared_ground(im)
    draw_corner_tree(im, 12, 78)
    draw_corner_tree(im, 114, 76)

    bx0, by = 34, 98
    bw, bh = 58, 46
    bx1 = bx0 + bw
    draw_stone_base(im, bx0, by - 10, bx1, by)
    draw_log_wall(im, bx0, by - bh, bx1, by - 10)
    draw_roof(im, bx0 - 6, by - bh - 14, bx1 + 6, by - bh - 18)
    rect(im, bx0 - 12, by - 18, bx0, by, BR3)
    rect(im, bx0 - 11, by - 17, bx0 - 1, by - 1, WD)
    vline(im, bx0 - 8, by - 17, by - 1, BR2)
    vline(im, bx0 - 3, by - 17, by - 1, BR2)
    hline(im, bx0 - 11, bx0 - 1, by - 17, BR)
    draw_door(im, bx0 + 23, by - 10, 24)
    draw_window(im, bx0 + 8, by - 30, 9, 9)
    draw_window(im, bx1 - 17, by - 30, 9, 9)
    draw_chimney(im, bx1 - 10, by - bh, bh - 6)
    draw_flag(im, bx1 + 8, by - bh - 10)
    draw_log_lean_to(im, bx1 + 4, by, 24, 18, 7)
    return im


def forester_lodge_l3() -> Image.Image:
    """Level 3 — master lodge fills most of the fixed footprint."""
    im = img(CANVAS, CANVAS)
    draw_shared_ground(im)
    draw_corner_tree(im, 10, 74)
    draw_corner_tree(im, 116, 72)

    bx0, by = 18, 98
    bw, bh = 88, 62
    bx1 = bx0 + bw
    draw_stone_base(im, bx0, by - 16, bx1, by)
    draw_log_wall(im, bx0, by - bh + 8, bx1, by - 16)
    for y in range(by - bh + 8, by - 16, 8):
        hline(im, bx0, bx1, y, BR3)
    draw_roof(im, bx0 - 8, by - bh - 10, bx1 + 8, by - bh - 16)
    rect(im, bx0 - 18, by - 24, bx0, by, SD2)
    rect(im, bx0 - 17, by - 23, bx0 - 1, by - 1, SD)
    rect(im, bx0 - 18, by - 24, bx0, by - 24 + 6, BR2)
    vline(im, bx0 - 14, by - 23, by - 1, BR3)
    vline(im, bx0 - 4, by - 23, by - 1, BR3)
    hline(im, bx0 - 17, bx0 - 1, by - 23, BR2)
    draw_door(im, bx0 + 38, by - 16, 26)
    draw_window(im, bx0 + 10, by - 38, 10, 10)
    draw_window(im, bx0 + 28, by - 44, 10, 10)
    draw_window(im, bx1 - 28, by - 44, 10, 10)
    draw_window(im, bx1 - 18, by - 38, 10, 10)
    draw_chimney(im, bx1 - 14, by - bh + 4, bh - 2)
    px(im, bx1 - 10, by - bh - 18, RK2)
    draw_flag(im, bx1 + 4, by - bh - 6)
    draw_log_lean_to(im, bx1 - 2, by, 28, 22, 10)
    rect(im, bx0 + 4, by - 16, bx1 - 4, by - 14, BR2)
    return im


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


def main() -> None:
    sapling().save(OUT / "sapling.png")
    forester_lodge_l1().save(OUT / "forester_lodge_l1.png")
    forester_lodge_l2().save(OUT / "forester_lodge_l2.png")
    forester_lodge_l3().save(OUT / "forester_lodge_l3.png")
    forester_lodge_l1().save(OUT / "forester_lodge.png")
    print(f"Wrote Task 8 sprites to {OUT}")


if __name__ == "__main__":
    main()

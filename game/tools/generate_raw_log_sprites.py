#!/usr/bin/env python3
"""Generate raw log sprites — Stardew-style collectible resource (48x24)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

LOG_SIZE = (48, 24)
PILE_SIZE = (72, 48)

T = (0, 0, 0, 0)
OUTLINE = (52, 32, 18, 255)
BARK_DK = (78, 48, 28, 255)
BARK_MD = (112, 70, 38, 255)
BARK_LT = (142, 92, 52, 255)
END_LT = (228, 194, 138, 255)
END_DK = (158, 118, 74, 255)


def img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), T)


def px(im: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def in_ellipse(x: int, y: int, cx: int, cy: int, rx: int, ry: int) -> bool:
    dx = (x - cx) / max(rx, 1)
    dy = (y - cy) / max(ry, 1)
    return dx * dx + dy * dy <= 1.0


def fill_ellipse(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if in_ellipse(x, y, cx, cy, rx, ry):
                px(im, x, y, c)


def ring_ellipse(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / max(rx, 1)
            dy = (y - cy) / max(ry, 1)
            dist = dx * dx + dy * dy
            if 0.80 <= dist <= 1.0:
                px(im, x, y, c)


def add_outline(im: Image.Image, color=OUTLINE) -> None:
    w, h = im.size
    copy = im.copy()
    for y in range(h):
        for x in range(w):
            if copy.getpixel((x, y))[3] == 0:
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if nx < 0 or ny < 0 or nx >= w or ny >= h or copy.getpixel((nx, ny))[3] == 0:
                    px(im, x, y, color)
                    break


def raw_log(width: int = 48, height: int = 24) -> Image.Image:
    im = img(width, height)
    mid_y = height // 2
    end_cx, end_cy = 10, mid_y
    end_rx, end_ry = 9, 10
    body_x0 = 16
    body_x1 = width - 2
    top_y = mid_y - 9
    bot_y = mid_y + 9

    # Cylindrical bark body
    for y in range(top_y, bot_y + 1):
        t = abs(y - mid_y) / 9.0
        row = BARK_LT if t < 0.35 else BARK_MD if t < 0.7 else BARK_DK
        for x in range(body_x0, body_x1):
            px(im, x, y, row)

    # Rough horizontal bark grooves
    for y in range(top_y + 2, bot_y - 1, 2):
        groove = BARK_DK if (y // 2) % 2 == 0 else BARK_MD
        x_start = body_x0 + ((y // 2) % 3)
        for x in range(x_start, body_x1 - 1, 1):
            px(im, x, y, groove)

    # Cut face + clean growth rings
    fill_ellipse(im, end_cx, end_cy, end_rx, end_ry, END_LT)
    for rx, ry in ((7, 8), (5, 6), (3, 4), (1, 2)):
        ring_ellipse(im, end_cx, end_cy, rx, ry, END_DK)

    # Connect cap to body
    for y in range(top_y, bot_y + 1):
        t = abs(y - mid_y) / 9.0
        row = BARK_LT if t < 0.35 else BARK_MD if t < 0.7 else BARK_DK
        for x in range(body_x0 - 4, body_x0):
            if not in_ellipse(x, y, end_cx, end_cy, end_rx - 1, end_ry - 1):
                px(im, x, y, row)

    # Top highlight strip
    for x in range(body_x0, body_x1 - 1):
        px(im, x, top_y + 1, BARK_LT)

    add_outline(im)
    return im


def raw_log_pile() -> Image.Image:
    im = img(PILE_SIZE[0], PILE_SIZE[1])
    placements = [(0, 38, 0.9), (14, 36, 1.0), (30, 38, 0.9), (8, 46, 0.78), (24, 46, 0.78)]
    for x, base_y, scale in placements:
        log = raw_log(*LOG_SIZE)
        new_w = max(1, int(log.width * scale))
        new_h = max(1, int(log.height * scale))
        log = log.resize((new_w, new_h), Image.Resampling.NEAREST)
        im.alpha_composite(log, (x, base_y - new_h))
    return im


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    raw_log(*LOG_SIZE).save(OUT_DIR / "wood_log.png")
    raw_log_pile().save(OUT_DIR / "wood_log_pile.png")
    print(f"Wrote raw log sprites ({LOG_SIZE[0]}x{LOG_SIZE[1]}) to {OUT_DIR}")


if __name__ == "__main__":
    main()

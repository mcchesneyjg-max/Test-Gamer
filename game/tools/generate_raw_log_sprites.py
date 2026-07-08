#!/usr/bin/env python3
"""Generate smooth, generic raw log sprites for harvest/haul/storage."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

LOG_SIZE = (32, 20)
PILE_SIZE = (48, 32)

T = (0, 0, 0, 0)
BARK_DK = (92, 58, 34, 255)
BARK_MD = (128, 82, 48, 255)
BARK_LT = (158, 108, 62, 255)
END_DK = (186, 142, 88, 255)
END_LT = (222, 186, 128, 255)
RING = (150, 108, 68, 255)


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


def ellipse_outline(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            dx = (x - cx) / max(rx, 1)
            dy = (y - cy) / max(ry, 1)
            dist = dx * dx + dy * dy
            if 0.72 <= dist <= 1.0:
                px(im, x, y, c)


def smooth_log(width: int = 32, height: int = 20) -> Image.Image:
    """Simple round log: smooth bark cylinder + soft cut end."""
    im = img(width, height)
    mid_y = height // 2
    body_x0 = 7
    body_x1 = width - 2
    body_half_h = height // 2 - 3

    for y in range(mid_y - body_half_h, mid_y + body_half_h + 1):
        t = abs(y - mid_y) / max(body_half_h, 1)
        row_color = BARK_LT if t < 0.35 else BARK_MD if t < 0.75 else BARK_DK
        rect(im, body_x0, y, body_x1, y + 1, row_color)

    for x in range(body_x0, body_x1):
        px(im, x, mid_y - body_half_h, BARK_DK)
        px(im, x, mid_y + body_half_h, BARK_DK)

    ellipse(im, 6, mid_y, 6, body_half_h, END_DK)
    ellipse(im, 6, mid_y, 4, body_half_h - 2, END_LT)
    ellipse(im, 6, mid_y, 2, body_half_h - 5, END_DK)

    return im


def smooth_log_pile() -> Image.Image:
    im = img(PILE_SIZE[0], PILE_SIZE[1])
    placements = [(2, 14, 0.85), (10, 12, 0.95), (20, 14, 0.85), (8, 20, 0.75), (18, 20, 0.75)]
    for x, y, scale in placements:
        log = smooth_log(LOG_SIZE[0], LOG_SIZE[1])
        new_w = max(1, int(log.width * scale))
        new_h = max(1, int(log.height * scale))
        log = log.resize((new_w, new_h), Image.Resampling.NEAREST)
        im.alpha_composite(log, (x, y - new_h))
    return im


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    smooth_log(*LOG_SIZE).save(OUT_DIR / "wood_log.png")
    smooth_log_pile().save(OUT_DIR / "wood_log_pile.png")
    print(f"Wrote smooth raw log sprites to {OUT_DIR}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate raw log sprites — modern cozy pixel art (48x24 resource icon)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

LOG_W, LOG_H = 48, 24
PILE_W, PILE_H = 72, 48

T = (0, 0, 0, 0)

# 7-shade warm earthy brown palette (dark outline, no black)
OUTLINE = (46, 28, 16, 255)
BARK_DEEP = (62, 38, 22, 255)
BARK_SHADOW = (88, 54, 30, 255)
BARK_MID = (118, 72, 40, 255)
BARK_LIGHT = (148, 96, 56, 255)
BARK_HIGH = (176, 118, 72, 255)
END_PALE = (232, 198, 148, 255)
END_RING = (168, 122, 78, 255)


def img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), T)


def px(im: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def in_ellipse(x: float, y: float, cx: float, cy: float, rx: float, ry: float) -> bool:
    dx = (x - cx) / max(rx, 1e-6)
    dy = (y - cy) / max(ry, 1e-6)
    return dx * dx + dy * dy <= 1.0


def fill_ellipse(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(cy - ry - 1, cy + ry + 2):
        for x in range(cx - rx - 1, cx + rx + 2):
            if in_ellipse(x + 0.5, y + 0.5, cx, cy, rx, ry):
                px(im, x, y, c)


def ring_ellipse(im: Image.Image, cx: int, cy: int, rx: int, ry: int, c, thickness: float = 0.85) -> None:
    inner = thickness * thickness
    for y in range(cy - ry - 1, cy + ry + 2):
        for x in range(cx - rx - 1, cx + rx + 2):
            dx = (x + 0.5 - cx) / max(rx, 1e-6)
            dy = (y + 0.5 - cy) / max(ry, 1e-6)
            dist = dx * dx + dy * dy
            if inner <= dist <= 1.0:
                px(im, x, y, c)


def is_log_body(x: int, y: int) -> bool:
    """Chunky cylinder silhouette with slight 3/4 lift (top edge higher on the right)."""
    top_lift = (x - 14) // 10
    top = 5 - min(top_lift, 2)
    bot = 19 + min(top_lift // 2, 1)
    if y < top or y > bot:
        return False
    if x < 14:
        return in_ellipse(x + 0.5, y + 0.5, 11.5, 13.0, 9.5, 10.5)
    return x <= 45


def body_shade(x: int, y: int) -> tuple[int, int, int, int]:
    """Soft top-left lighting, no pillow shading."""
    top_lift = (x - 14) // 10
    top = 5 - min(top_lift, 2)
    bot = 19 + min(top_lift // 2, 1)
    height = max(bot - top, 1)
    v = (y - top) / height
    if v < 0.22:
        return BARK_HIGH
    if v < 0.48:
        return BARK_LIGHT
    if v < 0.72:
        return BARK_MID
    if v < 0.88:
        return BARK_SHADOW
    return BARK_DEEP


def draw_cut_face(im: Image.Image) -> None:
    cx, cy = 11, 13
    fill_ellipse(im, cx, cy, 10, 11, END_PALE)
    for rx, ry in ((8, 9), (6, 7), (4, 5), (2, 3)):
        ring_ellipse(im, cx, cy, rx, ry, END_RING, 0.82)
    fill_ellipse(im, cx, cy, 1, 1, END_RING)


def draw_bark_body(im: Image.Image) -> None:
    for y in range(LOG_H):
        for x in range(LOG_W):
            if not is_log_body(x, y):
                continue
            if x < 14 and in_ellipse(x + 0.5, y + 0.5, 11.5, 13.0, 8.5, 9.5):
                continue
            px(im, x, y, body_shade(x, y))

    # Visible wood grain — broad horizontal bands, not speckled noise
    for y in range(8, 18, 4):
        tone = BARK_SHADOW if (y // 4) % 2 else BARK_MID
        for x in range(17 + (y % 3), 43, 6):
            px(im, x, y, tone)

    # Soft top highlight strip (3/4 light from upper-left)
    for x in range(15, 44):
        top_lift = (x - 14) // 10
        top = 5 - min(top_lift, 2)
        px(im, x, top + 1, BARK_HIGH)
        if x % 3 == 0:
            px(im, x, top + 2, BARK_LIGHT)


def draw_outline(im: Image.Image) -> None:
    base = im.copy()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if base.getpixel((x, y))[3] == 0:
                continue
            border = False
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if nx < 0 or ny < 0 or nx >= w or ny >= h or base.getpixel((nx, ny))[3] == 0:
                    border = True
                    break
            if border:
                px(im, x, y, OUTLINE)


def raw_log() -> Image.Image:
    im = img(LOG_W, LOG_H)
    draw_bark_body(im)
    draw_cut_face(im)
    draw_outline(im)
    return im


def raw_log_pile() -> Image.Image:
    im = img(PILE_W, PILE_H)
    layout = [(1, 40, 0.88), (15, 38, 1.0), (31, 40, 0.88), (9, 47, 0.76), (25, 47, 0.76)]
    for x, base_y, scale in layout:
        log = raw_log()
        nw = max(1, int(LOG_W * scale))
        nh = max(1, int(LOG_H * scale))
        log = log.resize((nw, nh), Image.Resampling.NEAREST)
        im.alpha_composite(log, (x, base_y - nh))
    return im


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    raw_log().save(OUT_DIR / "wood_log.png")
    raw_log_pile().save(OUT_DIR / "wood_log_pile.png")
    print(f"Wrote raw log sprites ({LOG_W}x{LOG_H}) to {OUT_DIR}")


if __name__ == "__main__":
    main()

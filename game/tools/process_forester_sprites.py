#!/usr/bin/env python3
"""Process forester lodge v3 source art into 128x128 game sprites (4x4 tile footprint)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

SRC_DIR = Path(__file__).resolve().parent.parent / "assets" / "sources"
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"
CANVAS = 128
LEVEL_MAX_WIDTH = {1: 80, 2: 104, 3: 128}


def remove_checkerboard(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            avg = (r + g + b) / 3
            if max(r, g, b) - min(r, g, b) < 24 and avg > 180:
                px[x, y] = (0, 0, 0, 0)
            elif max(r, g, b) - min(r, g, b) < 18 and 120 < avg < 200:
                px[x, y] = (0, 0, 0, 0)
    return im


def crop_content(im: Image.Image) -> Image.Image:
    bbox = im.getbbox()
    if bbox is None:
        return im
    return im.crop(bbox)


def resize_nearest(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    return im.resize(size, Image.Resampling.NEAREST)


def fit_bottom_canvas(im: Image.Image, level: int, canvas: int = CANVAS) -> Image.Image:
    """Bottom-align on fixed canvas; higher levels fill more of the 4x4 footprint."""
    max_w = LEVEL_MAX_WIDTH.get(level, canvas)
    w, h = im.size
    scale = max_w / w
    new_w = max_w
    new_h = max(1, int(h * scale))
    if new_h > canvas:
        scale = canvas / h
        new_h = canvas
        new_w = max(1, int(w * scale))
    resized = resize_nearest(im, (new_w, new_h))
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    x = (canvas - new_w) // 2
    y = canvas - new_h
    out.alpha_composite(resized, (x, y))
    return out


def process_level(level: int) -> None:
    src_path = SRC_DIR / f"forester_lodge_l{level}_v3_src.png"
    if not src_path.exists():
        raise FileNotFoundError(f"Missing source art: {src_path}")
    src = Image.open(src_path)
    out = fit_bottom_canvas(crop_content(remove_checkerboard(src)), level)
    out.save(OUT_DIR / f"forester_lodge_l{level}.png")
    if level == 1:
        out.save(OUT_DIR / "forester_lodge.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for level in (1, 2, 3):
        process_level(level)
    print(f"Wrote forester lodge v3 sprites to {OUT_DIR}")


if __name__ == "__main__":
    main()

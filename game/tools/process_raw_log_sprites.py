#!/usr/bin/env python3
"""Process raw log v4 source art into game-ready sprites."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

SRC_DIR = Path(__file__).resolve().parent.parent / "assets" / "sources"
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

LOG_SIZE = (40, 28)
PILE_SIZE = (64, 44)


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


def fit_size(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    w, h = im.size
    tw, th = size
    scale = min(tw / w, th / h)
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))
    resized = resize_nearest(im, (new_w, new_h))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (tw - new_w) // 2
    y = th - new_h
    out.alpha_composite(resized, (x, y))
    return out


def process_single_log() -> None:
    src = Image.open(SRC_DIR / "raw_log_v4_src.png")
    out = fit_size(crop_content(remove_checkerboard(src)), LOG_SIZE)
    out.save(OUT_DIR / "wood_log.png")


def process_log_pile() -> None:
    src = Image.open(SRC_DIR / "raw_log_pile_v4_src.png")
    out = fit_size(crop_content(remove_checkerboard(src)), PILE_SIZE)
    out.save(OUT_DIR / "wood_log_pile.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    process_single_log()
    process_log_pile()
    print(f"Wrote raw log v4 sprites to {OUT_DIR}")


if __name__ == "__main__":
    main()

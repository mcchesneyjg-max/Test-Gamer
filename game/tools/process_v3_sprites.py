#!/usr/bin/env python3
"""Process AI-generated v3 source art into game-ready pixel sprites."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

SRC_DIR = Path("/opt/cursor/artifacts/assets")
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

TREE_SIZE = (72, 104)
BUILDING_SIZE = (64, 64)
FRAME_SIZE = 32
WALK_FRAMES = 4
LOG_SIZE = (20, 16)
PILE_SIZE = (28, 20)


def remove_checkerboard(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = px[x, y]
            if max(r, g, b) - min(r, g, b) < 18 and (r + g + b) / 3 > 195:
                px[x, y] = (0, 0, 0, 0)
    return im


def crop_content(im: Image.Image) -> Image.Image:
    bbox = im.getbbox()
    if bbox is None:
        return im
    return im.crop(bbox)


def resize_nearest(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    return im.resize(size, Image.Resampling.NEAREST)


def crop_square(im: Image.Image) -> Image.Image:
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = h - side
    return im.crop((left, top, left + side, top + side))


def process_tree() -> None:
    src = Image.open(SRC_DIR / "mature_tree_v3_src.png")
    out = resize_nearest(crop_content(remove_checkerboard(src)), TREE_SIZE)
    out.save(OUT_DIR / "mature_tree.png")


def process_building(name: str, src_name: str) -> None:
    src = Image.open(SRC_DIR / src_name)
    out = resize_nearest(crop_square(crop_content(remove_checkerboard(src))), BUILDING_SIZE)
    out.save(OUT_DIR / f"{name}.png")


def process_walk_sheet() -> None:
    src = Image.open(SRC_DIR / "hauler_worker_walk_v3_src.png")
    row = crop_content(remove_checkerboard(src))
    frame_w = row.width // WALK_FRAMES
    frames: list[Image.Image] = []
    for i in range(WALK_FRAMES):
        frame = row.crop((i * frame_w, 0, (i + 1) * frame_w, row.height))
        frames.append(resize_nearest(frame, (FRAME_SIZE, FRAME_SIZE)))

    sheet = Image.new("RGBA", (FRAME_SIZE * WALK_FRAMES, FRAME_SIZE), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME_SIZE, 0))
    sheet.save(OUT_DIR / "hauler_worker_walk.png")
    frames[0].save(OUT_DIR / "hauler_worker.png")


def process_log() -> None:
    src = Image.open(SRC_DIR / "wood_log_v3_src.png")
    log = resize_nearest(crop_content(remove_checkerboard(src)), LOG_SIZE)
    log.save(OUT_DIR / "wood_log.png")

    pile = Image.new("RGBA", PILE_SIZE, (0, 0, 0, 0))
    offsets = [(2, 8), (8, 4), (14, 9), (6, 12), (12, 14)]
    for ox, oy in offsets:
        pile.alpha_composite(log, (ox, oy))
    pile.save(OUT_DIR / "wood_log_pile.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    process_tree()
    process_building("lumber_camp", "lumber_camp_v3_src.png")
    process_building("warehouse", "warehouse_v3_src.png")
    process_building("hauler_station", "hauler_station_v3_src.png")
    process_walk_sheet()
    process_log()
    print("Wrote v3 sprites to", OUT_DIR)


if __name__ == "__main__":
    main()

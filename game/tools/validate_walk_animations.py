#!/usr/bin/env python3
"""Check that walk animation PNG frames exist for each direction folder."""

from __future__ import annotations

from pathlib import Path

SPRITES_ROOT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
ROOT_CANDIDATES = [
    SPRITES_ROOT / "npc_animations" / "walking_animations",
    SPRITES_ROOT / "walking_animations",
]

DIRECTION_FOLDERS = [
    "walk_north",
    "walk_north_east",
    "walk_north_west",
    "walk_east",
    "walk_south",
    "walk_south_east",
    "walk_south_west",
    "walk_west",
]

ALL_DIRECTION_FOLDERS = [
    "walk_north",
    "walk_north_east",
    "walk_north_west",
    "walk_east",
    "walk_south",
    "walk_south_east",
    "walk_south_west",
    "walk_west",
]

EXPECTED_EXAMPLE = {
    "walk_south": "walk_south_1.png … walk_south_10.png",
    "walk_south_east": "walk_south_east_1.png … walk_south_east_10.png",
    "walk_south_west": "walk_south_west_1.png … walk_south_west_10.png",
}


FOLDER_FILENAME_PREFIXES = {
    "walk_north": ["walk_north"],
    "walk_north_east": ["walk_north_east", "walknortheast"],
    "walk_north_west": ["walk_north_west", "walknorthwest"],
    "walk_east": ["walk_east"],
    "walk_south": ["walk_south"],
    "walk_south_east": ["walk_south_east", "walk_southeast", "walksoutheast"],
    "walk_south_west": ["walk_south_west", "walk_southwest", "walksouthwest"],
    "walk_west": ["walk_west"],
}


def frame_sort_key(path: Path) -> int:
    stem = path.stem
    digits = ""
    for ch in reversed(stem):
        if ch.isdigit():
            digits = ch + digits
        elif digits:
            break
    return int(digits) if digits else 0


def file_matches_folder(basename: str, folder_name: str) -> bool:
    prefixes = FOLDER_FILENAME_PREFIXES.get(folder_name, [folder_name])
    matched_prefix = ""

    for prefix in prefixes:
        if basename.startswith(f"{prefix}_"):
            matched_prefix = prefix
            break

    if not matched_prefix:
        return False

    for other_folder in ALL_DIRECTION_FOLDERS:
        if other_folder == folder_name:
            continue
        if not other_folder.startswith(f"{folder_name}_"):
            continue
        for other_prefix in FOLDER_FILENAME_PREFIXES.get(other_folder, [other_folder]):
            if basename.startswith(f"{other_prefix}_"):
                return False

    return True


def resolve_walk_root() -> Path | None:
    for candidate in ROOT_CANDIDATES:
        if candidate.is_dir():
            return candidate
    return None


def main() -> None:
    root = resolve_walk_root()
    if root is None:
        print("Walk animation check: no folder found.")
        for candidate in ROOT_CANDIDATES:
            print(f"  checked: {candidate}")
        print("\nCreate:")
        print("  game/assets/sprites/npc_animations/walking_animations/")
        raise SystemExit(1)

    print("Walk animation check:", root)
    missing_any = False

    for folder_name in DIRECTION_FOLDERS:
        folder = root / folder_name
        if not folder.exists():
            print(f"  [skip] {folder_name}/ folder not present")
            continue

        pngs = sorted(
            [
                p
                for p in folder.iterdir()
                if p.suffix.lower() == ".png" and file_matches_folder(p.stem, folder_name)
            ],
            key=frame_sort_key,
        )
        if not pngs:
            missing_any = True
            print(f"  [MISSING] {folder_name}/ has no PNG files")
            if folder_name in EXPECTED_EXAMPLE:
                print(f"            expected: {EXPECTED_EXAMPLE[folder_name]}")
            continue

        print(f"  [ok] {folder_name}/ -> {len(pngs)} frames")
        for png in pngs[:3]:
            print(f"       - {png.name}")
        if len(pngs) > 3:
            print(f"       - ... ({len(pngs) - 3} more)")

    if missing_any:
        print("\nAdd your PNG files, then commit them to git:")
        print("  git add game/assets/sprites/npc_animations/walking_animations/")
        print("  git commit -m \"Add walk animation PNG frames\"")
        raise SystemExit(1)

    print("\nAll present folders have PNG frames.")


if __name__ == "__main__":
    main()

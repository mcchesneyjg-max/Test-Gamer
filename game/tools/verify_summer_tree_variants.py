#!/usr/bin/env python3
"""Compare summer tree variant PNGs and detect accidental duplicates."""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

ROOT = (
    Path(__file__).resolve().parent.parent
    / "assets"
    / "sprites"
    / "summer_tree_animation"
)

VARIANTS = ["summer_tree_1", "summer_tree_2", "summer_tree_3"]
ANIMATION_FOLDERS = [
    "axe_strike_animation",
    "fall_animation",
    "fallen_tree_chop_animation",
]


def file_hash(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def list_pngs(folder: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    return sorted(folder.glob("*.png"), key=lambda p: p.name)


def compare_pair(left: str, right: str) -> int:
    issues = 0
    print(f"\n=== {left} vs {right} ===")
    for anim in ANIMATION_FOLDERS:
        left_dir = ROOT / left / anim
        right_dir = ROOT / right / anim
        left_pngs = list_pngs(left_dir)
        right_pngs = list_pngs(right_dir)
        if not left_pngs:
            print(f"  {anim}: MISSING in {left}")
            issues += 1
            continue
        if not right_pngs:
            print(f"  {anim}: MISSING in {right}")
            issues += 1
            continue

        identical = 0
        for lp, rp in zip(left_pngs, right_pngs):
            if file_hash(lp) == file_hash(rp):
                identical += 1

        total = min(len(left_pngs), len(right_pngs))
        print(f"  {anim}: {identical}/{total} frames byte-identical")
        if identical == total and total > 0:
            print(
                f"    WARNING: all {anim} frames match between {left} and {right}."
            )
            print(
                "    This is expected for fall_animation in the current repo,"
            )
            print(
                "    but axe_strike and fallen_chop should usually differ."
            )
            issues += 1
    return issues


def main() -> int:
    if not ROOT.is_dir():
        print(f"ERROR: folder not found: {ROOT}")
        return 1

    print(f"Checking variants under:\n  {ROOT}\n")
    for variant in VARIANTS:
        for anim in ANIMATION_FOLDERS:
            folder = ROOT / variant / anim
            count = len(list_pngs(folder))
            status = f"{count} pngs" if count else "MISSING"
            print(f"  {variant}/{anim}: {status}")

    issues = 0
    issues += compare_pair("summer_tree_1", "summer_tree_3")
    issues += compare_pair("summer_tree_1", "summer_tree_2")

    print("\n=== Tips if summer_tree_1 files keep reverting ===")
    print("1. Commit PNGs BEFORE running git pull or git restore.")
    print("2. Never run 'git restore .' after copying new art.")
    print("3. Use this lowercase path only:")
    print("   game/assets/sprites/summer_tree_animation/summer_tree_1/")
    print("4. On Windows, compare frame 1 with:")
    print(
        "   fc game\\assets\\sprites\\summer_tree_animation\\summer_tree_1"
        "\\axe_strike_animation\\summer_tree_axe_frame_1.png"
        " game\\assets\\sprites\\summer_tree_animation\\summer_tree_3"
        "\\axe_strike_animation\\summer_tree_axe_frame_1.png"
    )
    print("   'FC: no differences' means the files are identical on disk.")

    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())

# summer_tree_1 — complete animation package

This folder must contain all three animation subfolders for the tree to work correctly in-game.

## Required folders

```
summer_tree_1/
  axe_strike_animation/        ← idle + chopping (10 frames typical)
  fall_animation/              ← tree fall (12 frames, ends at frame 12)
  fallen_tree_chop_animation/  ← post-fall chop (14 frames typical)
```

**Use this path only** (lowercase `summer_tree_animation`):

`game/assets/sprites/summer_tree_animation/summer_tree_1/`

Do not create a separate `Summer_tree_animation` folder on Windows — it is the same folder and causes confusion.

## Expected file naming

| Folder | Recognized prefixes | Example |
|--------|---------------------|---------|
| `axe_strike_animation` | `summer_tree_axe_frame`, `axe_strike` | `summer_tree_axe_frame_1.png` |
| `fall_animation` | `summer_tree_fall_frame`, `fall_animation` | `summer_tree_fall_frame_12.png` |
| `fallen_tree_chop_animation` | `fallen_tree_chop_animation`, `fallen_tree_chop` | `fallen_tree_chop_animation_1.png` |

Any numbered `.png` in each folder also works as a fallback.

## Playback sequence

1. **Idle/chop** — `axe_strike_animation` frames while lumberjack chops
2. **Fall** — all `fall_animation` frames play once at the same speed (including frame 12)
3. **Fallen chop** — `fallen_tree_chop_animation` plays once
4. Tree removed, lumberjack carries log to camp

## After replacing this folder

```cmd
git add game\assets\sprites\summer_tree_animation\summer_tree_1\axe_strike_animation\*.png
git add game\assets\sprites\summer_tree_animation\summer_tree_1\fall_animation\*.png
git add game\assets\sprites\summer_tree_animation\summer_tree_1\fallen_tree_chop_animation\*.png
git commit -m "Replace summer_tree_1 animation assets"
git pull --no-edit origin main
git push
```

**Never run `git restore .` after copying new PNGs** — it discards your uncommitted art and restores the old files from git (which may look like `summer_tree_3`).

Then in Godot: **Project → Reload Current Project** → **F5**

## Verify files are really yours (not swapped with tree_3)

On Windows, compare axe frame 1 between variants:

```cmd
fc game\assets\sprites\summer_tree_animation\summer_tree_1\axe_strike_animation\summer_tree_axe_frame_1.png game\assets\sprites\summer_tree_animation\summer_tree_3\axe_strike_animation\summer_tree_axe_frame_1.png
```

- **"FC: no differences"** — the two files are byte-identical on disk (not a path bug).
- **"Files are different sizes"** or **"FC: differences found"** — they are distinct.

Or run the repo checker:

```cmd
python game\tools\verify_summer_tree_variants.py
```

**Note:** In the current repo, `fall_animation` frames for `summer_tree_1` and `summer_tree_3` are intentionally identical (12/12 frames match). Only `axe_strike_animation` and `fallen_tree_chop_animation` should look different between variants.

## Verify in Godot Output panel

When placing trees, look for:

```
MatureTree: axe loaded 10 frames for summer_tree_1 from res://assets/sprites/summer_tree_animation/summer_tree_1/axe_strike_animation (first=res://...summer_tree_1/...)
MatureTree: fall loaded 12 frames for summer_tree_1 from res://assets/sprites/summer_tree_animation/summer_tree_1/fall_animation (first=res://...summer_tree_1/...)
MatureTree: summer_tree_1 ready with axe=10 fall=12 fallen_chop=14
```

The `first=` path must contain `summer_tree_1`, not `summer_tree_3`.

Warnings about missing frames or `borrowed axe art` mean a subfolder is empty or misnamed.

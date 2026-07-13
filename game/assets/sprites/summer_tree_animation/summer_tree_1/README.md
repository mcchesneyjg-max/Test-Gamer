# summer_tree_1 — complete animation package

This folder must contain all three animation subfolders for the tree to work correctly in-game.

## Required folders

```
summer_tree_1/
  axe_strike_animation/        ← idle + chopping (10 frames typical)
  fall_animation/              ← tree fall (12 frames, ends at frame 12)
  fallen_tree_chop_animation/  ← post-fall chop (14 frames typical)
```

Both path casings work on Windows:

- `game/assets/sprites/Summer_tree_animation/summer_tree_1/`
- `game/assets/sprites/summer_tree_animation/summer_tree_1/`

## Expected file naming

| Folder | Recognized prefixes | Example |
|--------|---------------------|---------|
| `axe_strike_animation` | `summer_tree_axe_frame`, `axe_strike` | `summer_tree_axe_frame_1.png` |
| `fall_animation` | `summer_tree_fall_frame`, `fall_animation` | `summer_tree_fall_frame_12.png` |
| `fallen_tree_chop_animation` | `fallen_tree_chop_animation`, `fallen_tree_chop` | `fallen_tree_chop_animation_1.png` |

Any numbered `.png` in each folder also works as a fallback.

## Playback sequence

1. **Idle/chop** — `axe_strike_animation` frames while lumberjack chops
2. **Fall** — all `fall_animation` frames play once
3. **Hold** — final fall frame (`summer_tree_fall_frame_12`) held for **1.5 seconds**
4. **Fallen chop** — `fallen_tree_chop_animation` plays once
5. Tree removed, lumberjack carries log to camp

## After replacing this folder

```cmd
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\axe_strike_animation\*.png
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\fall_animation\*.png
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\fallen_tree_chop_animation\*.png
git commit -m "Replace summer_tree_1 animation assets"
git push
```

Then in Godot: **Project → Reload Current Project** → **F5**

## Verify in Output panel

When placing trees, look for:

```
MatureTree: using variant summer_tree_1 (10 chop frames, ...)
MatureTree: loaded 12 fall frames for summer_tree_1
MatureTree: loaded 14 fallen chop frames for summer_tree_1
MatureTree: summer_tree_1 ready with axe=10 fall=12 fallen_chop=14
```

Warnings about missing frames or `borrowed axe art` mean a subfolder is empty or misnamed.

# Summer tree fall animation (summer_tree_1)

Drop your Aseprite frame exports into this folder.

Supported locations (either works):

- `game/assets/sprites/Summer_tree_animation/summer_tree_1/fall_animation/`
- `game/assets/sprites/summer_tree_animation/summer_tree_1/fall_animation/`

## File naming

Any numbered PNGs work. These prefixes are recognized automatically:

```
summer_tree_fall_frame_1.png
summer_tree_fall_frame_2.png
...
```

Also accepted:

- `fall_animation_1.png`
- `summer_tree_fall_1.png`
- `fall_1.png`
- Any other numbered `.png` in the folder (fallback)

## Playback

Each fall frame anchors by its trunk base so updated art stays grounded through the fall.

1. Lumberjack chops until the tree's final log is gathered.
2. The tree plays through all fall animation frames once (no loop).
3. The final fall frame (`summer_tree_fall_frame_12`) is held for **1.5 seconds**.
4. The `fallen_tree_chop_animation` plays once for this tree variant.
5. The lumberjack keeps waiting through the full sequence.
6. When the fallen-chop animation finishes, the tree is removed and the lumberjack carries the log back to camp.

## Upload your PNGs

```cmd
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\fall_animation\*.png
git commit -m "Update summer_tree_1 fall animation frames"
git push
```

Reload the Godot project after pushing (**Project → Reload Current Project**).

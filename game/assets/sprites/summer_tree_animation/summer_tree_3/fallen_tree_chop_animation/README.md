# Fallen tree chop animation (summer_tree_3)

Drop your Aseprite frame exports into this folder.

## File naming

Any numbered PNGs work. These prefixes are recognized automatically:

```
fallen_tree_chop_1.png
fallen_tree_chop_2.png
...
```

Also accepted:

- `summer_tree_fallen_chop_frame_1.png`
- `fallen_chop_1.png`
- Any other numbered `.png` in the folder (fallback)

## Playback

After the fall animation finishes:

1. The final fall frame (`summer_tree_fall_frame_12`) is held for **1.5 seconds**.
2. This fallen-tree chop animation plays once (no loop).
3. The tree is removed and the lumberjack carries the log back to camp.

The trunk base stays locked to the same world position for every frame.

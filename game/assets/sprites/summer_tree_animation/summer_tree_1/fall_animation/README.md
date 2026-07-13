# Summer tree fall animation

Drop your Aseprite frame exports into this folder.

## File naming

Any numbered PNGs work. These prefixes are recognized automatically:

```
fall_1.png
fall_2.png
...
```

Also accepted:

- `fall_animation_1.png`
- `summer_tree_fall_1.png`
- Any other numbered `.png` in the folder (fallback)

## Playback

The trunk base stays locked to the same world position for every frame in chop, fall, and fallen-chop animations. When fall begins, the code matches the current chop pose so the tree does not jump sideways.

1. Lumberjack chops until the tree's final log is gathered.
2. The tree plays through all fall animation frames once (no loop).
3. The final fall frame is held for **1 second**.
4. The `fallen_tree_chop_animation` plays once for this tree variant.
5. The lumberjack keeps waiting through the full sequence.
6. When the fallen-chop animation finishes, the tree is removed and the lumberjack carries the log back to camp.

## Upload your PNGs

Paste files into this folder first, then:

```cmd
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\fall_animation\*.png
git commit -m "Add summer tree fall animation frames"
git push
```

Reload the Godot project after pushing (**Project → Reload Current Project**).

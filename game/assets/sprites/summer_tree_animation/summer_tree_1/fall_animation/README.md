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

Frames are aligned by the trunk base (bottom-center of the tree art), so the standing tree and fall animation start in the same spot. Each fall frame shifts only as much as your art moves the trunk.

1. Lumberjack chops until the tree's final log is gathered.
2. The tree plays through all fall animation frames once (no loop).
3. The lumberjack keeps swinging through the full fall sequence.
4. When the fall animation finishes, the tree is removed and the lumberjack carries the log back to camp.

## Upload your PNGs

Paste files into this folder first, then:

```cmd
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\fall_animation\*.png
git commit -m "Add summer tree fall animation frames"
git push
```

Reload the Godot project after pushing (**Project → Reload Current Project**).

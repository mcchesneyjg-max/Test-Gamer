# Summer tree fall animation

Drop your Aseprite frame exports into this folder.

## File naming

```
summer_tree_fall_frame_1.png
summer_tree_fall_frame_2.png
...
```

Also accepted:

- `fall_1.png`
- `fall_animation_1.png`
- `summer_tree_fall_1.png`
- Any other numbered `.png` in the folder (fallback)

## Playback

1. Lumberjack chops until the tree's final log is gathered.
2. The tree plays through all fall animation frames once (no loop).
3. The lumberjack keeps swinging through the full fall sequence.
4. When the fall animation finishes, the tree is removed and the lumberjack carries the log back to camp.

## After updating PNGs

```cmd
git add game\assets\sprites\Summer_tree_animation\summer_tree_1\fall_animation\*.png
git commit -m "Update summer tree fall animation frames"
git push
```

Reload the Godot project (**Project → Reload Current Project**), then run **F5**.

Check the Godot Output panel for:

- `CharacterWalk: loaded 13 frames from ... (prefix summer_tree_fall_frame)`
- `MatureTree: started fall animation (13 frames)`

# Log cutting animation

> **Location:** `game/assets/sprites/npc_animations/log_cutting_animation/`

Drop your Aseprite frame exports into that folder for the lumberjack cutting a **fallen** log.

If that folder is empty, the game falls back to `npc_animations/wood_cutting_animation/`.

## File naming

```
log_cutting_1.png
log_cutting_2.png
...
```

Also accepted: `log_cutting_animation_1.png`, etc.

## Playback

Used during the tree's `fallen_tree_chop_animation` phase:

1. Tree finishes falling (all fall frames at equal speed)
2. Lumberjack walks west to the center of the fallen tree
3. Lumberjack plays this log cutting animation (frames 1–N once, then loops from frame 4)
4. Tree plays `fallen_tree_chop_animation` frames at the same time

## Upload your PNGs

```cmd
git add game\assets\sprites\npc_animations\log_cutting_animation\*.png
git commit -m "Add log cutting animation frames"
git push
```

Then reload the Godot project (**Project → Reload Current Project**).

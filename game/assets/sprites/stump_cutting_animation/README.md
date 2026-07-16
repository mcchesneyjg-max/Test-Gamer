# Stump cutting animation

Drop PNGs into:

`game/assets/sprites/stump_cutting_animation/`

## File naming

```
stump_cutting_animation_1.png
stump_cutting_animation_2.png
stump_cutting_animation_3.png
...
```

Also accepted: `stump_cutting_N.png`, or any numbered PNG in the folder.

## Playback

When the forester lodge worker arrives at a depleted `logs_post_tree_fall_5` stump and begins `log_cutting_animation`:

1. The stump sprite plays frames **1–N** from this folder at speed **10** (same as walking/NPC animations)
2. The forester plays log cutting at the same time
3. When the **last stump frame** finishes, the stump disappears

## Upload

```cmd
git add game\assets\sprites\stump_cutting_animation\*.png
git commit -m "Add stump cutting animation frames"
git push
```

Then reload the Godot project (**Project → Reload Current Project**).

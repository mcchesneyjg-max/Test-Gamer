# Summer tree animations

Animated summer tree variants for chopping and other seasonal effects.

## Folder layout

```
summer_tree_animation/
  summer_tree_1/
    axe_strike_animation/   ← tree reacts while lumberjack chops
    (other animation folders)
  summer_tree_2/
  summer_tree_3/
```

## Axe strike animation (`summer_tree_1/axe_strike_animation`)

Drop your Aseprite frame exports into:

`game/assets/sprites/summer_tree_animation/summer_tree_1/axe_strike_animation/`

### File naming

```
axe_strike_1.png
axe_strike_2.png
...
```

Also accepted: `axe_strike_animation_1.png`, etc.

### Playback

1. Lumberjack plays the wood cutting animation (frames 1–11, then loops 4–11)
2. When the lumberjack reaches **frame 7 for the first time** in a chop, the tree starts its axe strike animation
3. The tree loops through all axe strike frames until the log is gathered
4. The tree returns to the static `summer_tree_axe_frame_1.png` when chopping ends

## Upload your PNGs

Paste files into the folder first, then:

```cmd
git add game\assets\sprites\summer_tree_animation\summer_tree_1\axe_strike_animation\*.png
git commit -m "Add summer tree axe strike animation frames"
git push
```

Reload the Godot project after pushing so new textures are picked up.

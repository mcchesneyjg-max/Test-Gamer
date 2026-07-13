# Summer tree animations

Animated summer tree variants for chopping and other seasonal effects.

## Folder layout

Your folder must be named `summer_tree_animation` (lowercase).

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

Any numbered PNGs work. These prefixes are recognized automatically:

```
axe_strike_1.png
axe_strike_2.png
```

Also accepted:

- `axe_strike_animation_1.png`
- `summer_tree_axe_frame_2.png` (and higher numbers)
- Any other numbered `.png` in the folder (fallback)

### Playback

1. The mature tree shows the first axe strike frame from this folder when idle (not being chopped).
2. Lumberjack plays the wood cutting animation (frames 1–11, then loops 4–11).
3. When the lumberjack reaches **wood cutting frame 7 for the first time**, the tree plays through the full axe strike sequence.
4. Both the main tree sprite and the foreground trunk overlay use the same axe strike frames.
5. The tree loops through all axe strike frames until the log is gathered.
6. The tree returns to the first axe strike frame from this folder when chopping ends.

The copy in `game/assets/sprites/summer_tree_axe_frame_1.png` is no longer used.

### Troubleshooting

After adding PNGs, reload the Godot project (**Project → Reload Current Project**).

Check the Godot Output panel for:

- `CharacterWalk: loaded N frames from ...`
- `MatureTree: started axe strike animation (N frames)`

If you see `no axe strike frames found`, the PNG path or filenames do not match.

### After updating PNGs

1. Paste your new files into this folder (replace the old ones).
2. Push them to git:

```cmd
git add game\assets\sprites\summer_tree_animation\summer_tree_1\axe_strike_animation\*.png
git add game\assets\sprites\summer_tree_animation\summer_tree_1\fall_animation\*.png
git add game\assets\sprites\summer_tree_animation\summer_tree_1\fallen_tree_chop_animation\*.png
git commit -m "Replace summer_tree_1 animation assets"
git pull --no-edit origin main
git push
```

**Do not run `git restore .` before committing** — it will undo your new PNGs.

3. Reload the Godot project (**Project → Reload Current Project**).
4. Run the game (**F5**).

The game reloads PNGs directly from this folder each time a tree loads and when chopping starts, so updated art is picked up after a project reload.

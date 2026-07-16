# Stump cutting animation

Drop PNGs into:

`game/assets/sprites/stump_cutting_animation/`

## File naming

```
stump_cutting_animation_1.png
stump_cutting_animation_2.png
stump_cutting_animation_3.png
...
stump_cutting_animation_40.png
```

Also accepted: `stump_cutting_N.png`, or any numbered PNG in the folder.

## Playback

When the forester lodge worker arrives at a depleted `logs_post_tree_fall_5` stump and begins `log_cutting_animation`:

1. The stump sprite plays frames **1–N** from this folder at speed **10** (same as walking/NPC animations)
2. The forester plays log cutting at the same time
3. When the **last stump frame** finishes, the stump disappears

The game uses however many numbered PNGs are in the folder — no fixed frame count in code.

## Re-uploading new art

Replace the PNGs in this folder, then:

```cmd
git pull --no-rebase origin main
git add -A game\assets\sprites\stump_cutting_animation\
git commit -m "Update stump cutting animation frames"
git push
```

Use `git add -A` so removed frames (e.g. dropping from 41 to 40 PNGs) are deleted from GitHub too.

Reload the Godot project (**Project → Reload Current Project**). The game reloads every PNG from disk when stump cutting begins, so new frame counts and artwork are picked up automatically on the next stump chop.

## First upload

```cmd
git add game\assets\sprites\stump_cutting_animation\*.png
git commit -m "Add stump cutting animation frames"
git push
```

Then reload the Godot project (**Project → Reload Current Project**).

## Test in Godot

1. **Project → Reload Current Project**
2. Press **F5**
3. Let a tree become a depleted stump (`logs_post_tree_fall_5`), then send the forester to clear it
4. Check the **Output** panel — you should see:
   ```
   MatureTree: loaded 40 stump cutting frames from res://assets/sprites/stump_cutting_animation
   ```
   (The number matches however many PNGs you have.)

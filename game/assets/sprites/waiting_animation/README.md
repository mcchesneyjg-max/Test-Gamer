# Waiting animation

> **Canonical location:** `game/assets/sprites/npc_animations/waiting_animation/`

This legacy folder keeps documentation only. **Do not add PNGs here** — put frames in `npc_animations/waiting_animation/` instead.

## File naming

```
waiting_animation_1.png
waiting_animation_2.png
...
waiting_animation_12.png
```

## Playback (all characters when stationary)

1. Hold `waiting_animation_1` for **4 seconds**
2. Play `waiting_animation_2` through the last frame in order at walk animation speed (10 fps by default)
3. Hold the **last frame** (e.g. `waiting_animation_12`) until the character moves
4. When movement stops again, restart from step 1

## Upload your PNGs (required — merging the PR is not enough)

From your project folder in Command Prompt:

```cmd
git pull --no-rebase origin main
git add -A game\assets\sprites\npc_animations\waiting_animation\
git commit -m "Update waiting animation frames"
git push
```

Use `git add -A` so deleted old frames (e.g. `_13` to `_15`) are removed from GitHub too.

## Test in Godot

1. **Project → Reload Current Project**
2. Press **F5**
3. Stand still with the player (no WASD) for at least 4 seconds
4. Check the **Output** panel at the bottom — you should see:
   ```
   CharacterWalk: loaded 12 waiting frames
   ```
   If you see a warning about "no waiting frames found", the PNGs are missing or misnamed.

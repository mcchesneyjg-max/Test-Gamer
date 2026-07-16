# Bending down pickup animation

> **Location:** `game/assets/sprites/npc_animations/bending_down_pickup/`

Drop your Aseprite frame exports into this folder.

## File naming

```
bending_down_pickup_1.png
bending_down_pickup_2.png
bending_down_pickup_3.png
...
```

Also accepted: `bending_down_pickup_animation_N.png`, or any numbered PNG in the folder.

## Playback (all characters picking up a log)

Before any log pickup action:

1. The character plays frames **1–N** from this folder once at walk animation speed (**10 fps** by default)
2. When the last frame finishes, the normal pickup continues (log pile harvest, camp cargo pickup, etc.)

Applies to:

- **Lumberjack** — picking up logs from a fallen log pile
- **Hauler** — picking up logs from a lumber camp output pile

## Upload your PNGs (required — merging the PR is not enough)

From your project folder in Command Prompt:

```cmd
git pull --no-rebase origin main
git add game\assets\sprites\npc_animations\bending_down_pickup\*.png
git commit -m "Add bending down pickup animation frames"
git push
```

## Test in Godot

1. **Project → Reload Current Project**
2. Press **F5**
3. Watch a lumberjack or hauler pick up a log
4. Check the **Output** panel — you should see:
   ```
   CharacterWalk: loaded N bending down pickup frames
   ```
   If you see a warning about "no bending down pickup frames found", the PNGs are missing or misnamed.

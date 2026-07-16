# Bending down pickup animation

> **Location:** `game/assets/sprites/npc_animations/bending_down_pickup/`

Drop your Aseprite frame exports into this folder.

## File naming

```
bending_down_pickup_1.png
bending_down_pickup_2.png
bending_down_pickup_3.png
...
bending_down_pickup_10.png
```

Also accepted: `bending_down_pickup_animation_N.png`, or any numbered PNG in the folder.

## Playback (all characters picking up a log)

Before any log pickup action:

1. The character plays frames **1–N** from this folder once at walk animation speed (**10 fps** by default)
2. When the last frame finishes, the normal pickup continues (log pile harvest, camp cargo pickup, etc.)

Applies to:

- **Lumberjack** — picking up logs from a fallen log pile
- **Hauler** — picking up logs from a lumber camp output pile

## Re-uploading new art

Replace the PNGs in this folder, then:

```cmd
git add -A game\assets\sprites\npc_animations\bending_down_pickup\
git commit -m "Update bending down pickup animation frames"
git push
```

Reload the Godot project (**Project → Reload Current Project**). The game reloads every PNG from disk when a character starts bending down to pick up a log, so new frame counts and artwork are picked up automatically on the next pickup.

## First upload

```cmd
git pull --no-rebase origin main
git add game\assets\sprites\npc_animations\bending_down_pickup\*.png
git commit -m "Add bending down pickup animation frames"
git push
```

Then reload the Godot project (**Project → Reload Current Project**).

## Test in Godot

1. **Project → Reload Current Project**
2. Press **F5**
3. Watch a lumberjack or hauler pick up a log
4. Check the **Output** panel — you should see:
   ```
   CharacterWalk: began bending down pickup (10 frames)
   ```
   If pickup skips the bend, the PNGs are missing or misnamed.

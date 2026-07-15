# NPC animations

All lumberjack / forester / hauler / player character animation folders live here.

## Folder layout

```
npc_animations/
  walking_animations/
    walk_north/
    walk_south/
    walk_east/
    walk_west/
    walk_north_east/
    walk_north_west/
    walk_south_east/
    walk_south_west/
  waiting_animation/
  wood_cutting_animation/     ← standing tree chop
  log_cutting_animation/      ← fallen log chop
```

Path in the project:

`game/assets/sprites/npc_animations/`

## Used by

- Player
- Lumberjack worker
- Forester worker
- Hauler worker

All load through `CharacterWalk.apply_shared()`.

## After moving or updating PNGs

```cmd
git add game\assets\sprites\npc_animations\walking_animations\**\*.png
git add game\assets\sprites\npc_animations\waiting_animation\*.png
git add game\assets\sprites\npc_animations\wood_cutting_animation\*.png
git add game\assets\sprites\npc_animations\log_cutting_animation\*.png
git commit -m "Update NPC animation assets"
git push
```

Then in Godot: **Project → Reload Current Project**

## Verify

```cmd
python game\tools\validate_walk_animations.py
```

Check Output for lines like:

```
CharacterWalk: loaded 10 frames for walk_south
CharacterWalk: loaded 12 waiting frames
CharacterWalk: loaded 11 wood cutting frames
CharacterWalk: loaded N log cutting frames
```

The game checks `npc_animations/` first, then falls back to the legacy `assets/sprites/<folder>/` paths if needed.

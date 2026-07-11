# Waiting animation

Drop your Aseprite frame exports into this folder.

## File naming

```
waiting_animation_1.png
waiting_animation_2.png
waiting_animation_3.png
...
```

## Playback (all characters when stationary)

1. Hold `waiting_animation_1` for **4 seconds**
2. Play `waiting_animation_2`, `waiting_animation_3`, … in order at the same speed as walk animations (10 fps by default)
3. Loop back to step 1

Shared by the player, lumberjack, forester, and hauler via `CharacterWalk`.

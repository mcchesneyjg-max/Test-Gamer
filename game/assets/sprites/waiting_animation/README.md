# Waiting animation

Drop your Aseprite frame exports into this folder.

## File naming

```
waiting_animation_1.png
waiting_animation_2.png
waiting_animation_3.png
...
waiting_animation_12.png
```

## Playback (all characters when stationary)

1. Hold `waiting_animation_1` for **4 seconds**
2. Play `waiting_animation_2` through the last frame in order at walk animation speed (10 fps by default)
3. Hold the **last frame** (e.g. `waiting_animation_12`) until the character moves (N, NE, E, SE, S, SW, W, or NW)
4. When movement stops again, restart from step 1

Shared by the player, lumberjack, forester, and hauler via `CharacterWalk`.

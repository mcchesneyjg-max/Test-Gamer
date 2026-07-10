# Walking animations

Drop your Aseprite frame exports into the direction folders below.

## Current setup (North only)

Put your **10 PNG frames** in:

```
walking_animations/walk_north/
```

Example filenames (any names work as long as they sort 1 → 10):

```
01.png
02.png
03.png
...
10.png
```

Or:

```
frame_01.png
frame_02.png
...
frame_10.png
```

Each PNG is one full frame (not a sprite sheet). Use a **transparent background**.

## All direction folders

| Folder | Direction |
|--------|-----------|
| `walk_north` | N |
| `walk_northeast` | NE |
| `walk_east` | E |
| `walk_southeast` | SE |
| `walk_south` | S |
| `walk_southwest` | SW |
| `walk_west` | W |
| `walk_northwest` | NW |

Add other folders when ready — the game loads any folder that exists.

## After adding files

1. Save PNGs in the folder
2. Godot: **Project → Reload Current Project**
3. Press **F5** to test

All characters (player, lumberjack, forester, hauler) use these same animations.

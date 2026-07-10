# Walking animations

Drop your Aseprite frame exports into the direction folders below.

## File naming (use this for every direction)

Each frame is a separate PNG named:

```
walk_north_1.png
walk_north_2.png
walk_north_3.png
...
walk_north_10.png
```

Use the same pattern for other directions:

```
walk_south_1.png … walk_south_10.png
walk_east_1.png … walk_east_10.png
walk_west_1.png … walk_west_10.png
walk_northeast_1.png … etc.
```

## Folder layout

```
walking_animations/
  walk_north/
    walk_north_1.png
    walk_north_2.png
    ...
  walk_south/        (add when ready)
  walk_east/
  ...
```

| Folder | Direction | Filename prefix |
|--------|-----------|-----------------|
| `walk_north` | N | `walk_north_` |
| `walk_northeast` | NE | `walk_northeast_` |
| `walk_east` | E | `walk_east_` |
| `walk_southeast` | SE | `walk_southeast_` |
| `walk_south` | S | `walk_south_` |
| `walk_southwest` | SW | `walk_southwest_` |
| `walk_west` | W | `walk_west_` |
| `walk_northwest` | NW | `walk_northwest_` |

Each PNG is one full frame (not a sprite sheet). Use a **transparent background**.

## After adding files

1. Save PNGs in the matching folder
2. Godot: **Project → Reload Current Project**
3. Press **F5** to test

All characters (player, lumberjack, forester, hauler) use these same animations.

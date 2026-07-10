# Walking animations

Drop your Aseprite frame exports into the direction folders below.

## File naming (use this for every direction)

Each frame is a separate PNG named with the folder name + frame number:

```
walk_north_1.png … walk_north_10.png
walk_north_east_1.png … walk_north_east_10.png
walk_north_west_1.png … walk_north_west_10.png
walk_south_east_1.png … walk_south_east_10.png
walk_south_west_1.png … walk_south_west_10.png
```

## Folder layout

```
walking_animations/
  walk_north/
  walk_north_east/
  walk_north_west/
  walk_south_east/
  walk_south_west/
  walk_south/        (add when ready)
  walk_east/
  walk_west/
```

| Folder | Direction | Filename prefix |
|--------|-----------|-----------------|
| `walk_north` | N | `walk_north_` |
| `walk_north_east` | NE | `walk_north_east_` |
| `walk_north_west` | NW | `walk_north_west_` |
| `walk_east` | E | `walk_east_` |
| `walk_south_east` | SE | `walk_south_east_` |
| `walk_south` | S | `walk_south_` |
| `walk_south_west` | SW | `walk_south_west_` |
| `walk_west` | W | `walk_west_` |

Each PNG is one full frame (not a sprite sheet). Use a **transparent background**.

## After adding files

1. Save PNGs in the matching folder (the `.png` files must be present — `.import` files alone are not enough)
2. Commit the PNGs to git:
   ```cmd
   git add game/assets/sprites/walking_animations/walk_south_east/*.png
   git add game/assets/sprites/walking_animations/walk_south_west/*.png
   git commit -m "Add south east and south west walk frames"
   git push
   ```
3. Godot: **Project → Reload Current Project**
4. Press **F5** to test

Validate locally:

```cmd
python game/tools/validate_walk_animations.py
```

When the game starts, the Godot output log should show lines like:
`CharacterWalk: loaded 10 frames for walk_south_east`

All characters (player, lumberjack, forester, hauler) use these same animations.

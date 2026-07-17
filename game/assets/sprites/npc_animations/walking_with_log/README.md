# Walking with log animations

> **Location:** `game/assets/sprites/npc_animations/walking_with_log/`

Used when an NPC (lumberjack, hauler) is **carrying a log**. Replaces normal walk animations only — idle, chopping, and pickup animations are unchanged.

## Folder layout

One subfolder per direction:

```
walk_log_north/
walk_log_north_east/
walk_log_north_west/
walk_log_east/
walk_log_south/
walk_log_south_east/
walk_log_south_west/
walk_log_west/
```

Number PNGs in frame order inside each folder, e.g.:

```
walk_log_east/walk_log_east_1.png
walk_log_east/walk_log_east_2.png
...
```

Also accepted: any numbered PNGs in the folder (sorted by frame number).

## Direction mapping

| Movement | Normal walk folder | Carrying log folder |
|----------|-------------------|---------------------|
| N | `walk_north` | `walk_log_north` |
| NE | `walk_north_east` | `walk_log_north_east` |
| E | `walk_east` | `walk_log_east` |
| SE | `walk_south_east` | `walk_log_south_east` |
| S | `walk_south` | `walk_log_south` |
| SW | `walk_south_west` | `walk_log_south_west` |
| W | `walk_west` | `walk_log_west` |
| NW | `walk_north_west` | `walk_log_north_west` |

## In-game behavior

- Pick up a log → walk animations switch to `walk_log_*` immediately
- Drop off the log → normal `walk_*` animations return immediately
- If these folders are missing, NPCs keep normal walk + the separate log cargo sprite

## Upload art

```cmd
git add -A game\assets\sprites\npc_animations\walking_with_log\
git commit -m "Add walking with log animation frames"
git push
```

Reload the Godot project after adding or replacing PNGs.

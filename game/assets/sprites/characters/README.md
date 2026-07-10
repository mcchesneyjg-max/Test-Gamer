# Character walk animations (Aseprite upload)

Drop your exported PNGs into the matching character folder. The game loads **8-direction walk animations** automatically.

## Folders

| Character | Folder |
|-----------|--------|
| Player | `player/` |
| Lumberjack | `lumberjack/` |
| Forester | `forester/` |
| Hauler | `hauler/` |

## Required files (per character)

Export **one horizontal strip per direction** from Aseprite:

```
walk_n.png
walk_ne.png
walk_e.png
walk_se.png
walk_s.png
walk_sw.png
walk_w.png
walk_nw.png
```

Optional:

```
idle.png   (single 32×32 frame; if missing, uses the first frame of walk_s)
```

## PNG layout

- **Each frame:** 32×32 pixels (same size as your in-game character)
- **Each file:** frames placed in a **single horizontal row**
- **Example:** 4 walk frames → image size **128×32**
- **Background:** transparent
- **Filter in Godot:** Nearest (no blur)

The game counts frames automatically: `image width ÷ 32`.

## Aseprite export steps

1. Open your character file in Aseprite.
2. Create tags for each direction (e.g. `walk_n`, `walk_ne`, …) or select frames manually.
3. For each direction: **File → Export Sprite Sheet**
   - Layout: **Horizontal Strip**
   - Output file: `walk_n.png` (etc.)
4. Copy all PNGs into the character folder above.
5. In Godot: **Project → Reload Current Project**

## Direction guide (top-down)

```
        walk_n
 walk_nw   walk_ne
walk_w       walk_e
 walk_sw   walk_se
        walk_s
```

- **walk_n** — facing up
- **walk_s** — facing down
- **walk_e** — facing right
- **walk_w** — facing left
- Diagonals use the matching `walk_ne`, `walk_se`, `walk_sw`, `walk_nw` file

## After uploading

No code changes needed. Replace the PNGs, reload Godot, and run the game (F5).

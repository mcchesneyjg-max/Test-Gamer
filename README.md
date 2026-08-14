# City Siege

A Godot 4 pixel strategy game: build a city and supply chains, then defend against siege waves.

See [GAME_DESIGN.md](GAME_DESIGN.md) for the pitch and two-phase gameplay loop.

The playable map is a **250×250 tile grid** with **32×32 pixel tiles** (8000×8000 pixels).

## Open the Godot project

1. Install [Godot 4.7](https://godotengine.org/download) (4.3+ also works).
2. Launch Godot and choose **Import**.
3. Select `game/project.godot` in this repository.
4. Click **Import & Edit**, then press **F5** (or the Play button) to run the main scene.

### Controls (current setup)

- **W/A/S/D** — move the player on an **8-direction grid** (N, NE, E, SE, S, SW, W, NW)
- **Mouse wheel** — zoom in and out (camera follows the player)
- Buildings and planting zones snap to the **cardinal tile grid** (north/south/east/west tiles only)
- **T** — debug: add 1 wood log to log storage
- **Left click** — place the selected building from the build menu (bottom of screen)
- **Build menu** — Tree, Lumber Camp, Haulers, Forester, Log Storage, Cancel
- **Log Storage** — select from menu, then drag on the map (2x2 = 1 pile, up to 2x6 = 5 piles)
- **Left click forester lodge** — open menu → **Draw Planting Zone** or **Upgrade Lodge**
- **Left click log storage area** — view storage stats or redraw the zone
- Forester lodge has **3 exterior levels** (same 4×4 tiles; building art grows larger when upgraded)
- Forester workers only plant inside the zone, with spacing from trees and buildings
- **Tier 1 closed loop:** lodge → saplings → trees → lumber camp → haulers → log storage area
- Haulers spawn from the **log storage area** and auto-haul lumber camp logs there
- Buildings and workers use **cozy forest pixel art v3** (`game/assets/sprites/`, process with `python3 game/tools/process_v3_sprites.py` or regenerate v2 with `python3 game/tools/generate_sprites.py`)
- **Character walk art:** frame PNGs in `game/assets/sprites/walking_animations/` — e.g. `walk_north/walk_north_1.png` … `walk_north_10.png`. See that folder's `README.md`.
- Forester lodge levels use **v3-style detailed art** (`game/assets/sources/`, process with `python3 game/tools/process_forester_sprites.py`)
- Raw logs: **48×24 px** modern cozy pixel art (`python3 game/tools/generate_raw_log_sprites.py`) — soft shading, growth rings, warm browns
- Lumber camps show **output storage** (`Out: X/Y`) and a small log pile beside the building (Task 4)

## Project layout

- `game/` — Godot 4 project (main scene, scripts, tilesets)
- `GAME_DESIGN.md` — design notes
- `legacy/` — archived browser prototype (`index.html`, `game.js`, `style.css`)

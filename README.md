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

- **W/A/S/D** — pan the camera
- **Mouse wheel** — zoom in and out
- **T** — debug: add 1 wood log to the warehouse (Task 1 test)
- **Left click** — place a mature tree on the map (Task 2)
- **Right click** — place a lumber camp on the map (Task 3)
- Lumber camps show **output storage** (`Out: X/Y`) and a small log pile beside the building (Task 4)

## Project layout

- `game/` — Godot 4 project (main scene, scripts, tilesets)
- `GAME_DESIGN.md` — design notes
- `legacy/` — archived browser prototype (`index.html`, `game.js`, `style.css`)

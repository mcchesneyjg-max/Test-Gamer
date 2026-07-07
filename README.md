# City Siege

A Godot 4 pixel strategy game: build a city and supply chains, then defend against siege waves.

See [GAME_DESIGN.md](GAME_DESIGN.md) for the pitch and two-phase gameplay loop.

The playable map is a **250×250 tile grid** with **32×32 pixel tiles** (8000×8000 pixels).

## Open the Godot project

1. Install [Godot 4.3+](https://godotengine.org/download).
2. Launch Godot and choose **Import**.
3. Select `game/project.godot` in this repository.
4. Click **Import & Edit**, then press **F5** (or the Play button) to run the main scene.

### Controls (current setup)

- **W/A/S/D** — pan the camera
- **Mouse wheel** — zoom in and out
- **T** — debug: add 1 wood log to the warehouse (Task 1 test)

## Project layout

- `game/` — Godot 4 project (main scene, scripts, tilesets)
- `GAME_DESIGN.md` — design notes
- `legacy/` — archived browser prototype (`index.html`, `game.js`, `style.css`)

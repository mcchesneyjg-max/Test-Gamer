# Stacked log pile sprites

Place PNG sprites in this folder for the player-drawn log storage area.

## Required files

- `log_pile_1.png` through `log_pile_18.png`

Each frame shows the pile filling up:

- `log_pile_1` — first delivery
- `log_pile_18` — full pile (18 deliveries)

## Layout

Each pile slot uses a fixed **2 tiles tall** zone on the grid:

- 1 pile — 2×2 tiles
- 2 piles — 2×3 tiles
- 3 piles — 2×4 tiles
- 4 piles — 2×5 tiles
- 5 piles — 2×6 tiles

Pile sprites sit on the south edge of the outline, one per 2-wide column (overlapping by 1 tile).
Drag horizontally when placing; the outline snaps to the nearest valid size.

If sprites are missing, the game falls back to `wood_log.png` for pile visuals.

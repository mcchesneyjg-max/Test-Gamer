# Stacked log pile sprites

Place PNG sprites in this folder for the player-drawn log storage area.

## Required files

- `log_pile_1.png` through `log_pile_18.png`

Each frame shows the pile filling up:

- `log_pile_1` — first delivery
- `log_pile_18` — full pile (18 deliveries)

## Layout

Each pile slot uses a fixed zone footprint on the tile grid:

- 1 pile — 4 tiles wide
- 2 piles — 6 tiles wide
- 3 piles — 8 tiles wide
- 4 piles — 10 tiles wide
- 5 piles — 12 tiles wide

Drag horizontally when placing; the outline snaps to the nearest valid width.

If sprites are missing, the game falls back to `wood_log.png` for pile visuals.

# Stacked log pile sprites

Place PNG sprites in this folder for the player-drawn log storage area.

## Required files

- `log_pile_1.png` through `log_pile_18.png`

Each frame shows the pile filling up:

- `log_pile_1` — first delivery
- `log_pile_18` — full pile (18 deliveries)

## Layout

Each pile slot uses a **3×2 tile** footprint on the ground. Storage areas snap horizontally to 1–5 pile slots (18–90 total deliveries).

If sprites are missing, the game falls back to `wood_log.png` for pile visuals.

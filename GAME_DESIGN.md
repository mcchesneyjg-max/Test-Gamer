# Build & Siege (working title)

## One-sentence pitch

Build a pixel city on a **250×250** map, run **Song of Syx–style supply chains**, stockpile goods, then survive **They Are Billions–style siege waves** that test whether your economy and defenses were ready.

## Two phases

### Phase A — Build & supply

- Place buildings on a tile grid
- Workers and production chains move goods (start with **Timber Economy v1.0** — see `SUPPLY_CHAIN.md`)
- **Builder Guild** (built from planks) constructs most buildings — new types unlock through the guild over time
- **Hauler Stations** employ haulers who **roam the map** and auto-haul any ready goods to valid destinations (building input/output storage)
- Stockpile firewood, planks, arrows, walls before siege

### Phase B — Siege

- Player triggers waves (or calendar events)
- Enemies path toward the city
- Towers, walls, and gear consume what Phase A produced
- Damage carries back into Phase A (repair, rebuild, rebalance)

## Current scope

**Only the wood economy** until Tier 1–2 in `SUPPLY_CHAIN.md` feels good. No combat until logs → firewood/planks work.

## Inspirations

- **Song of Syx** — supply chains, logistics, production
- **They Are Billions** — colony prep, wave pressure
- **Original hook** — two explicit phases; economy mistakes hurt you in siege

## Tech

- **Godot 4** in `game/`
- **32×32** pixel tiles, **250×250** grid
- Legacy HTML prototype in `legacy/`

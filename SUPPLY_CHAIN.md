# Timber Economy v1.0

Focus: **wood supply chain only** until this loop is fun. Siege/combat consumes outputs later (arrows, walls, etc.).

## Tile & map

- **250×250** tile grid
- **32×32** pixel tiles

---

## Economy tree

```
                         WOOD LOGS
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
  Forester Lodge      Firewood Cutter         Sawmill
         │                   │                   │
     Saplings             Firewood             Planks
         │                   │                   │
   Mature Trees    ┌──────────┼──────────┐        │
         │         │          │          │        │
   Lumber Camp   Homes    Kitchens    Forge      │
         │                              Winter   │
         │                              Heating  │
         └──────────► WOOD LOGS ◄────────────────┘
                             │
                    (processing consumes logs)

Planks branch:
                         PLANKS
                             │
         ┌───────────────────┼───────────────────────────────┐
         │                   │                               │
  Builder Guild (*)     Fletcher → Arrows → Watch Towers     │
         │               Bowyer → Bows                         │
         │               Shield Maker → Shields              │
         │               Spear Maker → Spears                  │
         │               Furniture Workshop → Happiness        │
         │               Palisade Builder → Walls, Gates       │
         │                                                   │
         └──► BUILDS all other buildings (**)                │

(*) Builder Guild is itself built from planks (wood).
(**) After the guild exists, new buildings cost planks and are placed
    through the guild — not free-placed. More building types added over time.
```

---

## Builder Guild (important)

The **Builder Guild** is not just another plank consumer. It is the **construction hub**:

1. **Built from wood** — player spends **planks** to place the guild on the map.
2. **Builds everything else** — sawmill, fletcher, homes, walls, etc. are **constructed by the guild**, not placed for free.
3. **Plank cost per build** — each new building costs planks (amount TBD per type).
4. **Bootstrap exception** — Tier 1 only (Lumber Camp, Forester Lodge, trees) can be placed **without** a guild so the player can reach logs → planks → guild. After the guild exists, **all new building types** go through it.

Future buildings (mines, farms, towers, etc.) will be added to the guild build menu later.

---

## Haulers & building storage

Goods **do not teleport**. Production buildings use **on-site storage**; **haulers** move stock between them.

### Building storage areas

Each production/service building has:

| Storage | Purpose |
|---------|---------|
| **Input storage** | Raw goods waiting to be processed (e.g. logs at sawmill) |
| **Output storage** | Finished goods waiting to be picked up (e.g. planks at sawmill) |

Limits are per-building (capacity TBD). When output storage is full, production **stops**. When input storage is empty, production **waits**.

### Haulers

- **Separate workers** from lumberjacks, crafters, or builders.
- Each hauler **belongs to a Hauler Station** (its own building type). The station **employs** haulers — they are not a faceless global pool.
- Haulers **roam the full map**. They are not locked to one adjacent building.
- **Automatic jobs**: when any building’s **output storage** has goods ready, and a valid **destination input storage** needs that material, an available hauler from a station picks up the job:
  1. Path to source **output storage**
  2. Pick up goods
  3. Path to destination **input storage** anywhere on the map
  4. Drop off → look for the next ready job
- Multiple **Hauler Stations** = more haulers working the same job queue across the city.
- Optional later: job priority (nearest first, starvation prevention, warehouse vs direct feed).

### Hauler Station (building)

- Built like other buildings (via **Builder Guild** once guild exists; bootstrap rules TBD).
- Provides **N hauler workers** (upgradeable later).
- Haulers **live under** this building — idle haulers wait at or near their station between jobs.

### Typical wood flow (haulers decide routes)

```
Lumber Camp [logs out, ready]  ──►  (hauler from station)  ──►  Warehouse [logs in]
Sawmill [needs logs in]        ◄──  (hauler from station)  ◄──  Warehouse or Camp [logs out]
Sawmill [planks out, ready]    ──►  (hauler from station)  ──►  Builder Guild [planks in]
```

Player does **not** draw routes manually in v1 — haulers fulfill any **ready source → valid destination** pair.

Global UI counters (Wood Logs, Planks, etc.) reflect **warehouse totals** or sum of tracked storage — not magic production.

### Bootstrap

Tier 1: **Warehouse** + **Hauler Station** (bootstrap placement without guild). Camp produces to output storage; station haulers move ready logs anywhere needed (warehouse first).

---

## Build order (one Cloud Agent task per step)

Implement top-to-bottom. Do not skip ahead.

### Tier 1 — Raw logs + logistics (current focus)

| # | Task | Done when |
|---|------|-----------|
| 1 | `WoodLogs` resource + UI counter | Counter shows 0 (warehouse total); debug key optional |
| 2 | Place **Mature Tree** on map (depletable node) | Click/tool places tree tile |
| 3 | **Lumber Camp** building | Camp chops nearby trees → logs into **camp output storage** (not global yet) |
| 4 | **Building storage areas** | Input/output stockpiles per building; visible piles or slot counts |
| 5 | **Warehouse** building | Central storage; global wood counter reads from here |
| 6 | **Hauler Station** building | Employs N haulers (start with 1–2); bootstrap placement without guild |
| 7 | **Hauler AI** | Haulers roam map; auto-pick any ready output → valid input (e.g. camp logs → warehouse) |
| 8 | **Forester Lodge** | Lodge spawns saplings (bootstrap placement, no guild) |
| 9 | Sapling **growth** | Sapling → Mature Tree after N seconds |
| 10 | Closed loop test | Lodge + camp + station haulers keep warehouse supplied on 250×250 map |

### Tier 2 — Split logs (firewood vs planks)

| # | Task | Done when |
|---|------|-----------|
| 11 | **Sawmill** | Pulls logs from **input storage** → planks to **output storage** |
| 12 | Hauler delivery to sawmill | Station haulers auto-deliver logs to sawmill input when sawmill needs them |
| 13 | Plank counter in UI | Planks tracked via warehouse or sawmill output + hauler |
| 14 | **Builder Guild** building | Costs planks (hauled to guild input storage) to complete placement |
| 15 | **Guild build menu** | Select building → planks from storage → guild constructs it |
| 16 | **Firewood Cutter** | Built via guild; logs in → firewood in output storage |
| 17 | Firewood haul jobs | Station haulers auto-deliver firewood output → consumer input storages |

### Tier 3 — Firewood consumers & plank crafts (via guild)

| # | Task | Done when |
|---|------|-----------|
| 18 | **Homes** consume firewood | Built via guild; pull from **input storage** only |
| 19 | **Kitchens**, **Forge** consume firewood | Built via guild; haulers feed input storage |
| 20 | **Winter heating** toggle | Season flag increases firewood demand |
| 21 | **Fletcher** → arrows | Built via guild; planks in storage → arrows in output storage |
| 22 | **Palisade Builder** → walls/gates | Built via guild; planks via haulers |
| 23 | **Furniture Workshop** → happiness | Built via guild; planks → furniture → happiness |

Bowyer, Shield Maker, Spear Maker, Watch Towers: after Tier 3 works. All **built through Builder Guild**; all inputs/outputs use **storage + haulers**.

### Tier 4 — Future (not wood v1.0)

New building types (stone mines, farms, barracks, etc.) added to **guild build menu** as new economies are introduced.

---

## Godot conventions

- Project lives in `game/`
- Resources: `game/resources/` or `game/scripts/resources/`
- Buildings: `game/scripts/buildings/`
- Use simple colored placeholders until art pass
- Every PR: screenshot + which tier/task number completed

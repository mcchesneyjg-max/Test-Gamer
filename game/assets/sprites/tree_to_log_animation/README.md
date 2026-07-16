# Tree to log animation

> **Location:** `game/assets/sprites/tree_to_log_animation/`

PNG sequence showing the log pile left after a tree is felled and chopped. The game uses frames **2 through 5** only.

## Required files

```
logs_post_tree_fall_2.png   # full pile — shown when logs are ready to pick up
logs_post_tree_fall_3.png   # after 1st log is taken
logs_post_tree_fall_4.png   # after 2nd log is taken
logs_post_tree_fall_5.png   # after 3rd (final) log is taken
```

Also accepted: `log_post_tree_fall_N.png`, `tree_to_log_N.png`, or any numbered PNG in this folder.

## In-game behavior

1. Tree **fall animation** finishes, then the full **fallen_tree_chop_animation** plays on the tree (all frames in that folder).
2. When fallen chop completes, the log pile appears as `logs_post_tree_fall_2`.
3. When the lumberjack picks up the **first** log, the image switches to `logs_post_tree_fall_3`.
4. **Second** pickup → `logs_post_tree_fall_4`.
5. **Third** (final) pickup → `logs_post_tree_fall_5`, then the pile is depleted.

Each pickup also plays the bending-down pickup animation on the worker before the frame changes.

## Updating art locally

Replace the PNGs in this folder, then from your repo root:

```cmd
git add -A game\assets\sprites\tree_to_log_animation\
git commit -m "Update tree to log animation frames"
git push
```

Reload the Godot project (**Project → Reload Current Project**). The game reloads every PNG from disk whenever a log pile frame is shown, so new artwork is picked up automatically on the next tree.

## First-time upload (if PNGs are not in git yet)

```cmd
git add game\assets\sprites\tree_to_log_animation\*.png
git commit -m "Add tree to log animation frames"
git push
```

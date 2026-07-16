# Tree to log animation

Drop PNGs into:

`game/assets/sprites/tree_to_log_animation/`

## File naming

```
logs_post_tree_fall_1.png
logs_post_tree_fall_2.png
logs_post_tree_fall_3.png
logs_post_tree_fall_4.png
logs_post_tree_fall_5.png
```

Also accepted: `log_post_tree_fall_N.png`, `tree_to_log_N.png`, or any numbered PNG in the folder.

## Playback sequence

1. After `fallen_tree_chop_animation` finishes, the pile rests on frame **1**
2. When the lumberjack gathers the first log, frames **1–2** play at equal speed
3. Animation **stops on frame 2** — lumberjack carries that log back to camp
4. Frame **3** stays until the lumberjack returns and picks up another log
5. Frame **4** stays until the next pickup
6. Frame **5** stays permanently — no more logs can be gathered from this tree

The lumberjack does **not** carry logs during standing-tree chopping or during tree animations. Logs are only collected after the pile is ready (frame 2) and on return trips to the pile.

## Upload

```cmd
git add game\assets\sprites\tree_to_log_animation\*.png
git commit -m "Add tree to log animation frames"
git push
```

Then reload the Godot project (**Project → Reload Current Project**).

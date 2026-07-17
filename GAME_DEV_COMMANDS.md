# Game dev command reference (Windows)

Keep this file bookmarked. Run commands from your repo root:

```
C:\Users\mcche\block-pickup-game
```

Open Command Prompt, then:

```cmd
cd C:\Users\mcche\block-pickup-game
```

---

## Every time you sit down to work

```cmd
cd C:\Users\mcche\block-pickup-game
git status
git pull --no-rebase origin main
```

**Godot:** Launch Godot → open `game/project.godot` → **F5** to play.

---

## After the Cloud Agent changes code (PR or branch push)

1. **Close Godot first** (avoids file locks on pull).

2. Pull the agent's branch (replace branch name with the one the agent gives you):

```cmd
cd C:\Users\mcche\block-pickup-game
git pull --no-rebase origin cursor/lumberjack-log-pickup-west-a9a8
```

3. Reopen Godot. If art looks stale: **Project → Reload Current Project**.

**You do not need to commit or push** when the agent did the work — only pull to test.

**If there is a PR on GitHub:** merging the PR into `main` is optional for testing; you can pull the branch directly. After merge:

```cmd
git checkout main
git pull --no-rebase origin main
```

---

## Save YOUR Godot tweaks (inspector, scripts) so pull won't overwrite

1. Save in Godot (**Ctrl+S** on scene/script).
2. Commit only the files you changed:

```cmd
cd C:\Users\mcche\block-pickup-game
git status
git add game\scripts\lumberjack_worker.gd
git add game\scenes\lumberjack_worker.tscn
git commit -m "Tune lumberjack log pickup stand offsets"
git push
```

**Rule:** Uncommitted local edits can be lost or conflict on `git pull`. Commit + push = saved in the repo.

---

## Update art (PNG folders)

Replace PNGs in the folder, then add **that folder only** — do **not** use `git add -A` on the whole project.

**Bending down pickup**

```cmd
git add -A game\assets\sprites\npc_animations\bending_down_pickup\
git commit -m "Update bending down pickup animation frames"
git push
```

**Tree to log pile**

```cmd
git add -A game\assets\sprites\tree_to_log_animation\
git commit -m "Update tree to log animation frames"
git push
```

**Fallen tree chop (per variant)**

```cmd
git add -A game\assets\sprites\summer_tree_animation\summer_tree_1\fallen_tree_chop_animation\
git commit -m "Update summer_tree_1 fallen chop frames"
git push
```

**Stump cutting**

```cmd
git add -A game\assets\sprites\stump_cutting_animation\
git commit -m "Update stump cutting animation frames"
git push
```

After push: **Project → Reload Current Project** in Godot. Many animations reload from disk on the next use.

---

## Check what changed

```cmd
git status
git diff
git diff game\scripts\lumberjack_worker.gd
git log --oneline -10
```

---

## Merge conflicts (after pull)

If Git says a file conflicted:

1. Open the file in an editor.
2. Find `<<<<<<<`, `=======`, `>>>>>>>` markers.
3. Keep the version you want (often **your** tuned numbers).
4. Remove the markers, save, then:

```cmd
git add game\scripts\lumberjack_worker.gd
git commit -m "Resolve merge conflict, keep local lumberjack offsets"
git push
```

---

## Switch branches

```cmd
git branch
git checkout main
git checkout cursor/some-branch-name-a9a8
```

---

## Undo local edits (careful — discards uncommitted work)

```cmd
git checkout -- game\scripts\lumberjack_worker.gd
```

---

## Optional: regenerate / process sprites (Python)

From repo root, if you use the art tools:

```cmd
python game\tools\process_v3_sprites.py
python game\tools\generate_raw_log_sprites.py
python game\tools\process_forester_sprites.py
```

---

## What NOT to do

| Avoid | Why |
|-------|-----|
| `git add -A` on whole project | Can accidentally commit/delete art or `.import` noise |
| `git pull` while Godot is open | File locks, failed pulls |
| Editing only during Play mode | Inspector changes lost when you stop |
| Assuming every agent turn creates a PR | Code is still pushed to the branch; pull by branch name |

---

## Quick reference — most common commands

| Goal | Command |
|------|---------|
| See local changes | `git status` |
| Get latest main | `git pull --no-rebase origin main` |
| Test agent branch | `git pull --no-rebase origin cursor/BRANCH-a9a8` |
| Save your tuning | `git add` → `git commit -m "..."` → `git push` |
| Update art folder | `git add -A game\assets\sprites\FOLDER\` then commit + push |
| Refresh Godot | **Project → Reload Current Project** |

---

## Game controls (in play)

See [README.md](README.md) — WASD move, mouse wheel zoom, T debug wood, click/shift/ctrl/alt placements, forester lodge zone drawing.

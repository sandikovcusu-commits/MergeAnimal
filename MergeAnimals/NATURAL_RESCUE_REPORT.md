# V0.9.1-B.3 — NATURAL FREE RESCUE REPORT

Scope: the shipped **free** rescue (one free rescue per Classic session,
`rescue_remaining = 1`) on a naturally reached Game Over. Rewarded rescue was not
touched and is not part of this report.

Automated gameplay. Never presented as human play.

## 1. What is measured

1. A natural Game Over is reached by real input only (see
   `NATURAL_GAMEPLAY_REPORT.md`).
2. The free rescue button is visible, enabled and reads `Rescue: 1 free`.
3. One real pointer press on that button, then the terminal state is re-read.
4. When the rescue is refused, the refusal is reported with the numbers that
   caused it; it is never retried inside the same board and never reported as a
   success.

## 2. Result: the free rescue is refused on deep natural boards

Native, run `46178136922` (three independent natural terminal sessions in
separate `XDG_DATA_HOME` homes, seeds 93023 / 93033 / 93043):

| seed | score | bodies | above Danger Line | rescue_max_remove | plan | outcome |
|------|-------|--------|-------------------|-------------------|------|---------|
| 93023 | 2601 | 59 | 13 | 10 | empty | REFUSED |
| 93033 | 3443 | 74 | 21 | 10 | empty | REFUSED |
| 93043 | 2213 | 68 | 17 | 10 | empty | REFUSED |

Measured facts, identical in every case:

* `rescue_remaining` stays **1** — the budget is not spent on a refusal.
* `game_state` stays **2** (Game Over); the board, score and bodies are unchanged.
* The snapshot is **not empty** and no body is locked or queued, so neither of
  those guards is the cause.
* `mandatory_over_limit = true`: the number of bodies above the Danger Line is
  greater than `rescue_max_remove` (10).

## 3. Root cause (measured, not inferred)

`RescuePlanner.plan()` (`MergeAnimals/scripts/powerups/RescuePlanner.gd`) treats
**every** body above the Danger Line as a mandatory removal:

```gdscript
if float(item.y) - float(item.radius) < danger_y:
    mandatory.append(item)
...
if mandatory.is_empty() or mandatory.size() > max_remove: return {}
```

and `Game._commit_rescue()` (`scripts/gameplay/Game.gd:1262-1300`) passes
`rescue_max_remove` (default 10) into it. A natural Game Over happens when the
Danger Line has been occupied for the grace period, so on a deep board the
mandatory set is routinely larger than 10. The plan is then empty, the commit
fails with `RESCUE_FAILED`, and the player sees
`Rescue failed: no safe clearing within the limit.` while the button keeps
offering a free rescue that can never succeed.

The failure is therefore **not** a save bug, **not** a stale lock, and **not** a
crash: it is the interaction of two shipped rules (danger policy = remove all
bodies above the line; rescue limit = 10 removals).

## 4. Why no fix was made in B.3

The only ways to make the rescue succeed are product/balance decisions that B.3
explicitly forbids:

* raising `rescue_max_remove` (balance / design change),
* changing the danger-removal policy (design change),
* hiding or disabling the button when the plan is empty (UI/design decision,
  and it would still not give the player a working rescue).

B.3 restrictions: no new mechanics, no balance change, no design-freeze change.
The defect is therefore **reported, not patched**, and the acceptance state is
**conditional** (see `REGRESSION_REPORT.md`).

## 5. What is proven working around the refusal

* The button is only enabled when the shipped rules allow a rescue attempt; it is
  correctly disabled while a terminal checkpoint is pending.
* A refusal leaves the checkpoint, the score and the rescue budget intact: it is
  a clean no-op, not a corrupt half-rescue.
* Refresh and restart are unaffected by a refusal (both pass on their own
  natural terminal sessions).

## 6. Still unproven in this phase

* A **successful** natural free rescue (shallow terminal board with 10 or fewer
  bodies above the line). No such natural Game Over has been observed yet; the
  lane-cycle policy produces deep boards by construction. Producing one requires
  a shallower play pattern, which is a policy experiment for B.4, not a
  criterion change in B.3.
* Chromium and Firefox rescue runs: the browser scenario is wired
  (`natural-b3-rescue`) but had not produced a passing run at the time of this
  report; browser evidence is recorded in `BROWSER_PERSISTENCE_REPORT.md` when it
  exists, and is **not** claimed here.

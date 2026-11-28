# V0.9.1-B.3 — NATURAL GAMEPLAY REPORT

Protocol, matrix and per-session numbers for Classic gameplay played only through
normal user input. Automated gameplay; never presented as human play.

## 1. Protocol (identical native and Web)

| item | value |
|------|-------|
| build | Godot 4.7.2 stable (official); Web = production export, no probe, no prepared board |
| start state | clean profile per session (native: own `XDG_DATA_HOME`; Web: fresh persistent profile) |
| seed | explicit per session (native); runtime RNG (Web), recorded with the session id |
| input | native: `InputEventMouseButton`/`InputEventScreenTouch` via `root.push_input(…, true)`; Web: Playwright mouse down/up on the canvas |
| aim | eight-lane cycle 130, 245, 360, 475, 590, 245, 475, 360, rotated per session |
| cadence | 1.25 s between inputs (150 physics ticks at 120 Hz) |
| input guard | 260 (max, not a target); exhaustion prints `NATURAL_NOT_REACHED reason=input_cap` |
| forbidden | debug spawn, direct animal creation, score write, forced Game Over, prepared board, forced merge, forced rescue |
| diagnostics | read-only only: live counters, `_checkpoint_details()`, IndexedDB/save document |

## 2. Per-session matrix (native, run 46176130525)

3 actors × 3 matrix sessions, all reaching a **natural** Game Over.

| seed | inputs | accepted | rejected | merges | cancelled | retries | score | best | highest | max bodies | max combo | danger peak | approaches | sim s | outcome |
|------|--------|----------|----------|--------|-----------|---------|-------|------|---------|-----------|-----------|-------------|------------|-------|---------|
| 93011 | 188 | 187 | 1 | 116 | 471 | 452 | 2428 | 2428 | 8 | 71 | 6 | 1 | 2 | 235.0 | GAME_OVER |
| 93012 | 207 | 205 | 1 | 134 | 330 | 318 | 3016 | 3016 | 8 | 71 | 6 | 2 | 2 | 258.8 | GAME_OVER |
| 93013 | 233 | 225 | 6 | 162 | 1020 | 999 | 3788 | 3788 | 8 | 63 | 9 | 1 | 2 | 291.3 | GAME_OVER |

Full 24-row table (matrix + deep paths, all three actors):
`docs/qa/v091-b3/NATURAL_MATRIX_native.csv`.

Aggregates over 24 sessions: score 158–4194 (median 2850.5); 4544 accepted and
95 rejected inputs; highest animal level 9; largest board 74 bodies; max combo 14;
0 sessions ended on the input cap.

"Rejected" is a drop the game refused (spawn point occupied or cooldown); it is
counted, never retried inside a hidden loop, and it never advanced the queue.

"cancelled" / "retries" are MergeManager's own counters (a cancelled attempt is
a contact that did not produce a merge; a retry is A.4's automatic contact retry).
They are read from production state, not incremented by the suite.

## 3. What this run does NOT prove

* **Balance or skill.** The lane-cycle policy is a fixed pattern; it is not a
  human player. Session lengths and scores measure the shipped physics and rules
  against one reproducible policy, nothing more.
* **Danger cleared by play.** Only 2 clear episodes were observed across the
  matrix; long climb-and-clear cycles were not exercised.
* **Shallow-board behaviour.** Every natural Game Over here is a deep board
  (63–74 bodies), which is exactly why the free rescue was refused (see
  `NATURAL_RESCUE_REPORT.md`).
* **Browser parity.** The Web matrix is reported separately in
  `BROWSER_PERSISTENCE_REPORT.md` and only from runs that exist.

## 4. Reproducibility

```
gh workflow run godot-tests.yml --ref arena/2b071717-mergeanimal \
  -f natural_b3=true -f natural_b3_only=all
```

Each actor: `XDG_DATA_HOME=/tmp/b3-natural-user-<n> godot --headless --fixed-fps 120
--script res://tests/integration/natural_b3.gd -- seed=<93000+n*10> actor=<n>`.

Same seed + same policy reproduces the same session on the same build; session ids
differ per run because they are random per session, which is the shipped behaviour.

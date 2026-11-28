# V0.9.1-B.3 — NATURAL GAMEOVER REPORT (native)

Scope: Danger Line integrity, the terminal contract, and the terminal save on a
**naturally** reached Game Over. Native build: Godot 4.7.2 stable (official),
physics 120 Hz, `--fixed-fps 120`.

Automated gameplay through real input; never presented as human play.

## 1. Method

Each actor runs in its own `XDG_DATA_HOME` (clean profile), with an explicit test
seed for fresh sessions only. Every input is an `InputEventMouseButton` /
`InputEventScreenTouch` pushed through `root.push_input(..., true)`, so it enters
the production `_input` path exactly like a player press. No body, score, state
or rescue is written by the suite.

Input policy: fixed eight-lane cycle `130, 245, 360, 475, 590, 245, 475, 360`,
rotated per session, 1.25 s between inputs (a 150-physics-tick settle per input),
260 input guard. The guard is a maximum: when it is the reason a session did not
end, the log prints `NATURAL_NOT_REACHED` with that reason.

Danger is measured with the production predicate (`DangerMonitor._physics_process`):
above the Danger Line **and** settled (speed ≤ 35 px/s) **and** physically
supported.

## 2. Result: 3 of 3 actors reach a natural Game Over

Run `46176130525`, actors 1–3, 3 matrix sessions each, **24 natural sessions** in
total (9 matrix + 15 diagnostic/deep) — all 24 ended in a real Game Over:

| actor | seeds | Game Over | NOT_REACHED |
|-------|-------|-----------|-------------|
| 1 | 93011, 93012, 93013 | 3 | 0 |
| 2 | 93021, 93022, 93023 | 3 | 0 |
| 3 | 93031, 93032, 93033 | 3 | 0 |

`NATURAL_SUMMARY sessions=3 game_over=3 not_reached=0` on every actor.

Matrix rows (full data in `docs/qa/v091-b3/NATURAL_MATRIX_native.csv`):

| seed | inputs | accepted | rejected | merges | score | best | highest | max bodies | max combo | sim s | wall s |
|------|--------|----------|----------|--------|-------|------|---------|-----------|-----------|-------|--------|
| 93011 | 188 | 187 | 1 | 116 | 2428 | 2428 | 8 | 71 | 6 | 235.0 | 31.4 |
| 93012 | 207 | 205 | 1 | 134 | 3016 | 3016 | 8 | 71 | 6 | 258.8 | 38.8 |
| 93013 | 233 | 225 | 6 | 162 | 3788 | 3788 | 8 | 63 | 9 | 291.3 | 61.6 |

Aggregates over all 24 sessions: score 158 – 4194 (median 2850.5), inputs 45 –
255 (median 206), 4544 accepted and 95 rejected inputs, highest level reached 9,
largest board 74 bodies, every session GAME_OVER.

## 3. Danger Line integrity

* Approaches and clears are counted per input with the production predicate. On
  the matrix sessions the peak concurrent danger count is 1–2 bodies with 2–3
  approach episodes — the pile touches the line, then the session ends within
  the 2.0 s grace period. No session in this run exercised a long climb-and-clear
  cycle, so "danger cleared by play" is only weakly covered here (2 episodes
  across actors).
* A falling body is **not** counted as in danger even though it spawns above the
  line: the predicate requires *supported*, which the first B.3 run got wrong
  (it reported 398 "approaches" in a 400 input session). That was a measurement
  bug in the suite, fixed in `6f52a06`/earlier; it never affected the game.

## 4. Terminal contract (all 9 matrix sessions PASS)

After a natural Game Over, the suite presses six real pointer positions that are
**proven** clear of every visible button (the button rectangles are printed as
evidence, `NATURAL_PROBE ... buttons=[...]`):

| check | result |
|-------|--------|
| still the same live scene (instance id unchanged) | PASS 9/9 |
| refuses new drops (`spawn_count` unchanged) | PASS 9/9 |
| refuses new score | PASS 9/9 |
| body count unchanged | PASS 9/9 |
| no pending reservation, no merge lock | PASS 9/9 |
| immune to a deferred `_commit_pending()` | PASS 9/9 |
| merge counter unchanged by that call | PASS 9/9 |
| repeated input never re-enters a second state | PASS 9/9 |
| overlay visible with text | PASS 9/9 |

The B.1 contract ("`request_merge()` may reserve but must never mutate a terminal
board") therefore still holds after B.3, and no stale lock or callback survives a
natural Game Over.

### Harness note (not a product defect)

The first version of these probes clicked at y = 700, which is inside the result
overlay's **Play Again** row. The "failures" it produced were a legitimate
navigation press being measured as an illegal board input. The probes now use
positions derived from the live button rectangles, and the rectangles are
printed. Recorded in `BUG_TRACKER.csv` as a QA-harness finding.

## 5. Terminal save at the moment of Game Over

`NATURAL_SAVE_TRACE` for all 24 sessions: `doc_status=ok`, `doc_over=true`,
document score equals the live terminal score, `written_revision == current_revision`
and `requested_revision == written_revision` in 24/24 cases; `generation` strictly
increases across checkpoints.

`status` reads `unconfirmed` in all 24 native cases. This is **expected and not a
defect**: the read-back confirmation is a Web-only mechanism
(`SaveDurability` returns early `if not OS.has_feature("web")`), so on native the
checkpoint is written and read back through the ordinary file path, and the
scoped/aggregate read-back strings are simply `native`. Terminal save
**confirmation** is validated on Chromium/Firefox, not here.

## 6. Refresh-equivalent restore (PASS)

Driven from its own freshly played natural terminal session (seed 93021, this run):
the scene is dropped, the Main Menu is instantiated and the **real** Continue
button is pressed. Result:

```
NATURAL_REFRESH seed=93021 revision=79c6b24a… score=4110 best=4110 bodies=73 rescue=1 session_match=true
```

Game Over state, session id, score, best score, terminal body set, rescue budget
and the overlay all survive; the save status and `game_over_pending` are
unchanged. PASS in all three actors.

---

## Reproduction

```
gh workflow run godot-tests.yml --ref arena/2b071717-mergeanimal \
  -f natural_b3=true -f natural_b3_only=all
```

Raw log: `docs/qa/v091-b3/native-46176130525.log`
Matrix: `docs/qa/v091-b3/NATURAL_MATRIX_native.csv`
Save trace: `docs/qa/v091-b3/TERMINAL_SAVE_TRACE_native.csv`

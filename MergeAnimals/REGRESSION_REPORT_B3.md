# V0.9.1-B.3 — REGRESSION REPORT

Baseline: `5410eee` (B.3 start), tested tree: `6f52a06`… plus the B.3 suite
commits on `arena/2b071717-mergeanimal`.

## 1. Product code changed by B.3

**None.** Every commit in this phase is a test, workflow or documentation change:

```
MergeAnimals/tests/integration/natural_b3.gd      new / edited
MergeAnimals/tests/web/natural-b3.mjs             new / edited
.github/workflows/godot-tests.yml                 natural_b3 input + step
.github/workflows/godot-web.yml                   natural-b3-* branch
MergeAnimals/docs/qa/v091-b3/*                    new evidence
MergeAnimals/*REPORT*.md, BUG_TRACKER.csv, …      new documents
```

No file under `MergeAnimals/scripts/` or `MergeAnimals/scenes/` is touched by any
B.3 commit. `git log --stat` for the phase shows zero product-code paths.

Because B.3 changed no product code, the B.1/B.2/A.4 regression suites are
**not re-run** for this phase: re-running them would re-measure the same shipped
build and could be mistaken for new B.3 evidence. The existing results stand as
the regression baseline and are not re-attributed to B.3:

| suite | result | run |
|-------|--------|-----|
| B.1 state machine | `STATE_MACHINE_B1 37/0` | 46139839103 |
| B.1 animal levels | `ANIMAL_LEVELS_B1 157/0` | 46139839103 |
| B.1 drop system | `DROP_SYSTEM_B1 requests=4027 executed=1000 refused=3027 oob=0 dup=0 wrong=0` | 46139839103 |
| B.1 merge integrity | `MERGE_INTEGRITY_B1 43/0` | 46139839103 |
| B.2 impact | `IMPACT_SUMMARY cases=180 max_depth=9.190 escapes=0` | 46139839103 |
| B.2 dense | 600 cases, `overlapped_fixtures=0`, worst 5.821 px | 46139839103 |

If a later B.3 change ever touches product code, the affected suites must be re-run
on that exact commit before acceptance.

## 2. Behaviour re-verified inside B.3 (informal regression)

Although no product code changed, the natural suites exercise these subsystems
end to end and all passed on the tested commit:

| subsystem | how B.3 covers it | result |
|-----------|-------------------|--------|
| drop system | every input is a real drop through `_input`; accepted/rejected counted | 4544 accepted, 95 rejected, no wrong body |
| merge integrity | merge counter, cancelled and retry counters per session | merge counts grew monotonically, 0 anomalies |
| state machine | terminal contract: PLAYING → GAME_OVER, no re-entry | PASS 9/9 |
| danger line | production predicate, grace period ends the session | PASS (2.0 s grace observed) |
| save confirmation (native) | written/requested/current revisions equal | 24/24 |
| refresh / Continue | real Main Menu + real Continue press | PASS 3/3 actors |
| restart isolation | real Restart press, one live board, new session, best kept | PASS 3/3 actors |

## 3. Open defects (not regressions, but they block full acceptance)

| id | priority | subsystem | state |
|----|----------|-----------|-------|
| V091-B3-001 | P1 report-only | free rescue vs Danger Line policy | REFUSED on every observed natural Game Over; not fixed by design restriction |
| V091-B3-002 | P2 investigation | Chromium terminal save confirmation (historical, run 46077100528) | still **unproven**; no cause proven, no fix claimed |
| V091-B3-003 | P3 | QA harness (two cases) | fixed in the harness, documented as harness bugs |

## 4. Acceptance statement

**Conditional.** The natural gameplay, Danger Line, terminal contract, terminal
save write, refresh, restart and Continue paths are validated natively on this
commit. Full acceptance is withheld because:

1. the shipped free rescue cannot complete on any deep natural Game Over
   (V091-B3-001), and fixing it requires a balance/design decision that B.3
   forbids;
2. browser (Chromium/Firefox) validation of the same flows is not complete on
   this commit, so WP1's 3 + 3 + 3 minimum is not met yet;
3. the historical Chromium confirmation incident remains unproven, and it must
   not be shown as fixed.

No criterion was weakened to reach this statement. Commercial status remains
BLOCKED. The pull request stays in DRAFT and nothing is merged to `main`.

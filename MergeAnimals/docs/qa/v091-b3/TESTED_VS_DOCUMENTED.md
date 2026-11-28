# V0.9.1-B.3 — TESTED vs DOCUMENTED COMMIT DIFF

B.3 rule: a result belongs to the exact commit that produced it. A run made on
commit A may never be reported as evidence for commit B.

## 1. Baseline and head

| item | value |
|------|-------|
| B.3 baseline (branch point) | `25fe05a` |
| baseline of the whole phase | `5410eee` |
| branch | `arena/2b071717-mergeanimal` |
| pull request | #1, **DRAFT** (no merge to `main`, no release) |

## 2. What changed in the phase

```
git diff --name-only 25fe05a..HEAD
```

Test and workflow surface:

| path | kind |
|------|------|
| `MergeAnimals/tests/integration/natural_b3.gd` | new native suite |
| `MergeAnimals/tests/web/natural-b3.mjs` | new browser suite |
| `.github/workflows/godot-tests.yml` | `natural_b3`, `natural_b3_only`, native step, failure gate |
| `.github/workflows/godot-web.yml` | `natural-b3-*` branch, `b3_sessions` input |

Documentation and evidence surface:

| path | kind |
|------|------|
| `MergeAnimals/NATURAL_GAMEPLAY_REPORT.md` | new |
| `MergeAnimals/NATURAL_GAMEOVER_REPORT.md` | new |
| `MergeAnimals/NATURAL_RESCUE_REPORT.md` | new |
| `MergeAnimals/REGRESSION_REPORT_B3.md` | new |
| `MergeAnimals/docs/qa/v091-b3/*` | new evidence (raw log, 2 CSVs, README) |
| `MergeAnimals/BUG_TRACKER.csv` | 4 rows added (V091-B3-001…004) |
| `MergeAnimals/KNOWN_ISSUES.md`, `CHANGELOG.md` | B.3 entries |

Product surface: **empty**. `git diff --name-only 25fe05a..HEAD` contains no path
under `MergeAnimals/scripts/` or `MergeAnimals/scenes/`:

```
product-code changes: 0
```

Consequence: the B.1, B.2 and A.4 suite results were produced on the same
product code as this head and therefore remain the regression baseline. They are
**not** re-run and **not** re-attributed to B.3 (§27: no unsolicited repeat), and
they are never presented as B.3 evidence.

## 3. Per-run provenance

| run | workflow | commit | purpose | valid as B.3 evidence |
|-----|----------|--------|---------|-----------------------|
| 46141267945 | godot-tests | 41924e5 | first native attempt | NO — parse error |
| 46145965775 | godot-tests | 6f52a06 | first real session | NO — job hit the 45 min limit |
| 46176130525 | godot-tests | 6f52a06 | native matrix + deep paths | **YES** |
| 46173894723 | godot-tests | (restart focus) | restart attribution | YES (restart only) |
| 46178136922 | godot-tests | (rescue focus) | rescue attribution | YES (rescue only) |
| 46179658792 | godot-tests | push build | non-B.3 regression set only | NO for B.3 |
| 46174734183 | godot-tests | — | reported green with checks=0 | **DISCARDED** (V091-B3-004) |
| web runs 46164412985 / 46169090794 | godot-web | — | browser attempts | NO — harness bugs, documented |

Discarded runs are listed so the record shows what was rejected and why; no
discarded run contributed a number to any report.

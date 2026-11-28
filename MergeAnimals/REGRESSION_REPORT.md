# V0.9.1-A.4 — targeted regression report

**Commit under test: `8103ecb30d0f6ac50178407bd6ea8c58b43fe857`.** Every result
below was executed on this commit after the report commit was created, so no
row is carried over from `7839b8d` or `1c5305b`. Product code is byte-identical
between `7839b8d` and `8103ecb` (`git diff 7839b8d 8103ecb -- MergeAnimals/scripts
MergeAnimals/scenes MergeAnimals/resources MergeAnimals/project.godot
MergeAnimals/export_presets.cfg` is empty), which is why the earlier runs
matched; they are nevertheless listed separately as superseded evidence.

- Base: `e63c38c` (branch point), base of PR: `7e183ab` (`main`)
- Product A.4 commits: `5de6f06` (contact retry), `560a803` + `b58cc61`
  (save observer)
- Test-harness / evidence commits: `1441491`, `cdc3ad3`, `7839b8d`,
  `1c5305b`, `8103ecb`
- Previous production build: `0dedf46` (its CI results are not reused here)
- Commercial status: BLOCKED. Conditional technical acceptance only.

## Native (Godot 4.7.2, CI `46116317592`, evidence blob
`1badfe18970bfea63ff09c892d1180c34c10f317`)

| Suite | Result on 8103ecb |
| --- | --- |
| contact retry A4 (new) | `CONTACT_RETRY_A4 checks=26 failures=0` |
| merge stress A4 (new, 100 seeds x 10/20/40) | `MERGE_STRESS_A4_COMPLETE cases=300 failures=0` |
| placement A3 | `PLACEMENT_A3 checks=19 failures=0` |
| terminal save retry A3 | `SAVE_RETRY_A3 checks=8 failures=0` |
| prior 60-pair synthetic stress | `MERGE_STRESS_COMPLETE cases=300 failures=0` |
| all earlier native suites (integration, physics, bots, real gameplay, 100 drops, stress) | 34 x `exit=0`, no non-zero exit |

Native A4 stress detail: 600 merges, 79 cancellations, 79 automatic retries,
79 successes, 0 duplicates, 0 body loss, pending queue maximum 2, no locks
left at the end. Per-seed rows: `MERGE_STRESS_TEST.csv` (`suite=a4-scheduler`).

## Web — Chromium and Firefox, all on `8103ecb`

| Suite | Chromium | Firefox |
| --- | --- | --- |
| placement 13/13 (30 frozen cases) | `46116256945` ✅ | `46116280447` ✅ |
| save integrity 52/52 | `46116261433` ✅ | `46116285779` ✅ |
| contact retry A4 (new, 8 checks + 30 cases) | `46116265968` ✅ | `46116290564` ✅ |
| observer A4 (new, 27 checks) | `46116270680` ✅ | `46116295210` ✅ |
| observer A3 suite rerun 9/9 | `46116275756` ✅ | `46116299728` ✅ |

## Rescue regression on `8103ecb`

| Suite | Run | Result |
| --- | --- | --- |
| mock rewarded rescue 68/68 | `46116304037` (Chromium), `46116308182` (Firefox) | ✅ both |
| free rescue fixture (24 checks: danger overflow -> persisted Game Over -> pending Game Over survives refresh -> Rescue spends one use and preserves score -> refresh Continue -> full browser close/reopen -> reopened Continue) | `46116312428` (both browsers) | `WEB_POWERUP checks=24 failures=0` |

Mock ad is a mocked SDK response, not a platform ad. Rescue results are
fixture-driven, not natural-device play.

## Failed runs on this branch (disclosed, never reclassified as passes)

| Run | Suite | What failed | Reason / resolution |
| --- | --- | --- | --- |
| 46086881864 | native | `contact_retry_a4` 2 checks; `merge_stress_a4` 300 cases | Harness defects: the game-over scenario built the board BELOW the Danger Line where `DangerMonitor` clears timers, so overflow could not occur; the stress test counted deliberately removed blockers as body loss and sampled before the deferred commit. Fixed in `1441491` (test only). |
| 46086910389 / 46086913145 | observer A4 | power-up record missing; `blockReads` threw | Harness assumption that an ordinary autosave writes the power-up record — `Game.save_session()` passes `powerup=false`, so only terminal/undo/power-up commits do. This also exposed a real product gap (see next row). |
| 46088793695 / 46088795743 | observer A4 | two-file assertion raced; duplicate-track case raced | Periodic autosave superseded the commit under test between commands. Partly fixed with `requires_powerup`; fully isolated in `7839b8d` by suspending the game loop and draining a scheduled autosave. |
| 46089512943 / 46089515540 | observer A4 | same autosave race (`requires_powerup` sampled false) | Fixed in `7839b8d` (QA isolation). |
| 46091791592 / 46091794147 / 46091796686 / 46091799197 | rescue | `unknown mode` | Invalid invocation: `ui_mode` values `rescue-fixture` / `rescue-reward-mock` do not exist; the workflow needs `scenarios=fixture-rescue` and `ui_mode=reward-mock`. Re-run correctly in 46116312428 / 46116304037 / 46116308182. |

None of these were browser gameplay failures, and none are counted as passes.
The real product defect they exposed is recorded as `V091-A4-003` (a required
but untracked file silently satisfied the aggregate) and fixed in `b58cc61`.

## NOT run in A.4 (explicit gaps, handed to V0.9.1-B)

- Natural-input Game Over and natural (non-fixture) rescue on this commit.
- Full natural browser restart / sudden close / eviction durability.
- Cross-file atomicity between the power-up record and the session primary.
- Real Android device, simulated-touch physical device, human visual/audio/play
  review, store rights clearance.
- The six natural Game Over runs from `0dedf46` (Chromium `46083305299` /
  `46083308936` / `46083311713`, Firefox `46083320155` / `46083322794` /
  `46083325420`) remain historical evidence only and are NOT results of
  `8103ecb`.

## Godot import reliability

Editor import aborts on hosted runners were re-examined: archived logs end
after a successful `[DONE] reimport` with glibc heap corruption
(`free(): corrupted unsorted chunks`, `double free or corruption (out)`), i.e.
the editor process dies after import, before the browser or the test binary
starts. QA CSVs/reports are excluded from the PCK (`export_presets.cfg`:
`tests/*`, `*.md`, `*.txt`, `*.csv`, `*.mp4`, `*.py`; `audit_pck.py` rejects QA
paths). On `8103ecb` the PCK audit reports 393 entries and
`forbidden_or_legacy []`. A.4 keeps one clean retry after removing `.godot`;
all 15 runs in this report imported successfully. Root cause still not
established, not classified as a browser gameplay failure (`V091-A4-006`).

---

# V0.9.1-A.2 — verification results (NOT ACCEPTED)

Production code unchanged since `783db74`; CI refs differ only by QA harness/workflows. Exact run links: `https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/<id>`.

| Coverage | Result | Limit |
|---|---|---|
| Old trace reconstruction | native 46077811425 success | Approximate 34-body checkpoint plus two logged cat positions; baseline old code stuck, new candidate 168px |
| Web merge + pending lifecycle | Chromium 46078992480; Firefox 46078995167, 33/33 each | QA fixture; no manual human/device validation |
| 10/20/40 × 10 seeds | same browser runs, 30/30 each | Frozen manually reserved pairs; `../WEB_STRESS_TEST.csv`; not native 300 or natural browser sessions |
| Three-body, two disjoint pair, chain, golden | same browser runs | Physical bodies and collision callbacks, controlled prepared boards; not broad seed coverage |
| Pending pause/resume/restart/menu/undo/remove/save/refresh/game over | same browser runs | Controlled, some direct method calls; menu blocks until safe, resume manually commits; Game Over from simulated danger monitor |
| 587/427 and observer failure | same browser runs | Synthetic scores and injected failure; no actual quota failure |
| Real 225-input Chromium Game Over | 46077100528 FAILED | Checkpoint in IDB score 3499; aggregate observer unconfirmed at 60s; reload not reached |
| Chromium natural Game Over retry | 46078823863 5/5 | Input 210, verified checkpoint 3404; refresh and Continue; does not negate previous failure |
| Firefox 300-input natural attempt | 46078508210 FAILED | No Game Over at sampled points; spawn counter reset mid-run, so a transient state/session transition cannot be ruled out |
| Firefox natural Game Over retry | 46079789253 5/5 | Input 243; verified checkpoint 4296; refresh and Continue |
| Native A.2 | 46077715137 success | Native fixture and 300 synthetic cases, unchanged production |
| Save integrity legacy regression | Chromium 46074758542, Firefox 46074761541, 52/52 | Prior A.1 identical production |
| Challenge, Achievement, Undo, Remove, Rescue and session | A.1 runs in historical table | Prior A.1 identical production |
| Danger-line crossing | both browsers demonstrated 120px committed crossing | Outcome in natural support/timer gameplay not established; safety acceptance blocked |

The following are not certified: no repeated failed reservations under all real contact patterns; natural false rescue or its absence; every browser timing/physics interleaving; actual mobile FPS, Android, human visual/play/audio; cross-file atomicity or sudden-close safety. CI runs that crashed during import are not counted as passes.

---

# Regression report — A.1 PARTIAL

Code under test: `0972f358a2fbf2d1677ef80afedec04b24b19a1f`; `4ac4c3d` changes only stress test and workflow. CI links use `https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/<id>`.

| Scope | Environment / run | Result and limit |
|---|---|---|
| Baseline stuck pair | native 46074106020 | controlled old-code fixture 7/7 reproduces failure |
| Fixed dense / no-space / freed ref | native 46075602196 | 16/16; synthetic fixtures |
| 100-seed reservation × 10/20/40 | native 46075602196 | 300/300 synthetic; timing and scope limits in MERGE_DEADLOCK_REPORT |
| Bot gameplay 100 seeds each | native 46074778285 | CI success 60 and 120 Hz; 90 s cap, not full merge stress coverage |
| Real collision normal/golden; contact chain; combo/pause | native 46074755536 | runtime suite success; logs include 12 pair collisions and chain |
| Undo / Remove / Rescue | native 46074781212 / 46074784283 / 46074787260 | CI success; Rescue includes Game Over pending cancellation fixture |
| Save/Load/Continue/Game Over | native 46074790306 | CI success, fixture/process regression |
| Challenge / Achievement | native 46074793141 / 46074796057 | CI success |
| Deadlock + revision + reload | Chromium 46074749255; Firefox 46074752395 | 15/15 each; frozen QA fixture |
| Save integrity | Chromium 46074758542; Firefox 46074761541 | 52/52 each |
| Rescue and physical overflow | both browsers 46074810587 | 24/24 synthetic fixture |
| Rewarded Rescue | Chromium 46074807905 | 68/68 local SDK mock; not real platform |
| Web Audio | Chromium 46074802203; Firefox 46074805118 | 47/47 each; automated, not human audio review |
| Touch | Chromium 46074799017 | 29/29 simulated, not Android |
| Natural Game Over | Chromium 46074813762; Firefox 46074816508 | FAILED at 120 inputs, Game Over not reached; sampled pending empty; cannot certify natural path |

No full native/Web 3- and 4-way collision stress, continuous long-session status correctness, independent verified pair geometry of the earlier natural hang, real Android/touch, human play/visual/audio, or meaningful real-mobile performance. Automated checks do not certify any of those. Prior physics and rights restrictions remain.

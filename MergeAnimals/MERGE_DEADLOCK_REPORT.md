# V0.9.1-A.1 — pending merge / save report

**Status: PARTIAL / acceptance blocked.** Private testing only; do not merge to main or distribute commercially. Details and unresolved root-cause limitations: `ROOT_CAUSE_ANALYSIS.md`.

## Controlled pre/post evidence

- Baseline production `5285aa0` + test-only `ea6375c`: native 46074106020 **7/7**, including 120 manual commit attempts stuck; drop/save blocked despite a safe far point.
- Production fix `806d5c8`, native 46074441451 **16/16**: one merge/score, 49→48 bodies, no replacement overlap, snapshot/drop resume; a separate intentionally overlapping giant-blocker fixture exercises no-space cancellation with 11 originals retained, score 0, and freed reference cleanup. This fixture is not a natural physical pile.
- Final implementation `0972f35`, Chromium 46074749255 and Firefox 46074752395: QA-only frozen scene **15/15 each**, revision verification, unsaved power-up despite unchanged score, held IndexedDB transaction, pending save refusal, merge, drop, verified checkpoint and reload. The QA autoload is absent from the playable export.
- Natural-input, passive-observer Web: Chromium 46074813762 and Firefox 46074816508 **failed natural Game Over test** at 120 input cap, not a pass. 24 sampled progress points per browser had zero pending pairs and nonempty snapshots; at last sample Chromium 120 drops/97 merges, Firefox 119/80. This suggests improvement for these two seeds but sampling cannot prove no transient or future hang; neither run reached Game Over. The original natural-geometry root cause is not proven.

## Stress and invariants

Native 46075602196 at `4ac4c3d` has 300 synthetic, frozen-board cases, 100 seeds at each of 10, 20 and 40 bodies; `MERGE_STRESS_TEST.csv`. Each requests two disjoint pairs and a conflicting third request; no duplicates, lost bodies, score mismatches, residual locks or rejected snapshot/drop guard failures were observed. Maximum queue 2, locked bodies 4, pending measured 2.052 ms. The three CSV timing columns all record the same wall-clock interval from first request through manual commit; the blocked-drop/save values are **upper bounds**, not separately timed browser write delays. The fixture measures reservation transactions, not real collision callbacks, pause/restart, chain/golden, sustained retries, mobile or cross-browser 100-seed stress.

Native gameplay bots 46074778285 at `0972f35` ran 100 sessions each at 60 and production 120 Hz, up to 90 simulated seconds. At 60 Hz 99 time cap/1 overflow, max wall penetration 16.678 px; at 120 Hz 100 time cap, max 9.190 px; both 0 full-escape frames. These existing bots do not collect all requested pending duration, revision or loss statistics. No claim of complete 100-seed hotfix acceptance follows.

Native runtime includes real contact chain and 12 normal/golden collisions. Separate native integration workflows cover Undo, Remove, Rescue, session, Challenge and Achievement. Existing paused Game Over fixture checks pending cancellation and survivor state. Specific new browser tests for pending pause/resume/restart, all 3/4-body simultaneous collision schedules, wall edge cases and full long-game revision invariants remain incomplete. Natural human/mobile play has not been performed.

Logs: `docs/qa/v091-a1/`, CSV in project root. The two natural Game Over CI failures are retained rather than converted to PASS.

# V0.9.1-A.4 — root-cause findings

## MERGE-CONTACT-RETRY-004 (Phase A) — cause identified and fixed

Baseline `e63c38c`:
- `scripts/managers/MergeManager.gd:48-49` — `observe()` connected only
  `body_entered`. Godot emits that once per new contact pair; it is not a
  continuous "still touching" signal.
- `MergeManager.gd:71-74` — `request_merge()` deliberately suppressed a pair
  that already failed while relevant geometry stayed within the 1 px
  `PLACEMENT_CHANGE` clearance. Correct as a guard, but nothing re-invoked
  `request_merge` when geometry later changed.
- `MergeManager.gd:81-84` — `_physics_process()` only drained `pending`; it
  never re-examined `failed_placements`.
- `MergeManager.gd:121-126` — `_commit_pending()` cancelled the pair when
  `find_merge_position()` returned null and stored the failed geometry.

Consequence: a continuously touching pair whose safe space appears later (a
blocker moves) produced no new contact event, so no new request was made.
Only an explicit request or a genuinely new collision could retry. Resting and
sleeping bodies emit no events, so this was reproducible with frozen bodies.

Fix `5de6f06`: tracked failed pairs (weak refs, pair key, session id, geometry
snapshot, attempt count, cancel reason), `body_exited` connected as a dirty
trigger, and a throttled scheduler (0.25 s, max 4 re-requests per tick) that
re-requests only pairs whose geometry changed while physical contact persists
and no reservation is held. Safety limits are untouched: the retry enters the
normal reserve/commit path, so 132/168 px bounds, radius-derived search and the
Danger Line guard still decide placement. No forced merge path exists.
Verified: native 26/26 and 300/300 stress, Web 8 checks + 30 frozen cases in
both browsers, 79/79 cancellations recovered automatically with 0 duplicates.

## SAVE-AGGREGATE-OBSERVER-005 (Phase B) — cause identified, one real defect
## fixed, original natural event still unproven

Observed failure (`46084133893`, Chromium): session record `verified`,
power-up record `pending` with 0 retries inside its 12 s window, aggregate
`pending`, so `Game._checkpoint_details()` returned `pending`. Firefox
`46084136488` verified both and passed.

Findings:
1. `Game.gd:294-318` (baseline) required the **global** observer aggregate.
   `SaveDurability.status()` (`SaveDurability.gd:94-102`) covers every tracked
   file, so an unrelated pending/unconfirmed record blocked the session
   checkpoint, and the aggregate raised a stale unrelated record to
   session-level status.
2. The terminal commit writes the power-up record first, then the session
   primary. IDBFS sync is per file and not atomic; at the sample instant the
   session entry had verified and the power-up entry had not. The product was
   right to refuse `verified`; the A.3 test asserted too early.
3. New defect found in A.4 while validating (`b58cc61`): an ordinary autosave
   writes only the session primary (`Game.save_session` → `powerup=false`),
   yet the aggregate always included the power-up path, and
   `statusForFiles` dropped missing paths — so a required-but-untracked file
   silently counted as satisfied. Now the aggregate covers exactly the files
   the latest commit wrote, a required path with no record is `unconfirmed`,
   and a commit that included the power-up record verifies only when that
   record, its revision and the primary all verify.

Not proven: why the original natural Chromium terminal event
(`46077100528`) stayed unconfirmed for 60 s. Cross-file atomicity is not
claimed and is not guaranteed. A record that exhausts its bounded read retries
does not revive when a fault clears; only a new commit re-verifies it (open
risk `V091-A4-005`).

## Godot editor import crashes (Phase C, item 14)

Archived logs (`docs/qa/v091-a3/*import-failure.log`) end after
`[DONE] reimport` with glibc heap corruption, before any browser or test
process starts. QA CSVs/reports are excluded from the PCK
(`export_presets.cfg` excludes `tests/*`, `*.md`, `*.txt`, `*.csv`, `*.mp4`,
`*.py`; `audit_pck.py` rejects QA paths). Root cause not established; A.4 adds
one clean retry after removing `.godot`. All A.4 runs imported successfully.
This is not classified as a browser gameplay failure.

---

# V0.9.1-A.3 — root-cause boundaries

Controlled evidence demonstrates old 96px placement search exhaustion and an A.2 120px danger-line crossing. The old natural locked board was not captured exactly; the 168px reconstruction remains approximate. A.3 geometric cancellation addresses those fixtures but no automatic continuous-contact retry is implemented; liveness/gameplay remains open. See MERGE_PLACEMENT_REPORT.md.

Controlled 16s IDB lock in Firefox shows an older pending timer can make a later exact terminal write unconfirmed, but cannot establish why natural Chromium 46077100528 was unconfirmed. Per-request watchdog/read-only retry is mitigation, not proof of original cause. See SAVE_CONFIRMATION_REPORT.md.

---

# V0.9.1-A.2 — trace comparison and limits

Input sequence is known (`130,245,360,475,590,130,360,590`, repeated, 1700 ms interval), but the old run did not record its starting random seed. Its final IndexedDB checkpoint does preserve RNG state and an earlier board. Firefox trace [46071244975](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46071244975) first sampled pending at input 65: rabbit→cat and cat→dog; live and checkpoint score both 552. The two cat positions in checkpoint differ by only 0.562 and 1.032 px from sampled locked-pair positions. Rebuilt the 34-body checkpoint with those two cats moved to their logged positions (`tests/fixtures/v091_trace_firefox_approx.json`). The other bodies were not captured at exactly that moment and may have moved; pair matching by proximity and UID cannot prove exact identity. This is **approximate**, not an exact replay of the original natural collision. Checkpoint RNG state is not the initial seed, and replaying it cannot reconstruct past inputs/physics.

Native [46077811425](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46077811425) runs the same approximation on the current build and separately overlays the exact original `5285aa0` Game.gd and MergeManager.gd. Old: no candidate, 120 commits leave 1 pair locked, 34 bodies, score 0. New: candidate 168 px from midpoint, 1 merge, score 20, 33 bodies. This strengthens the case for 96px search exhaustion but does **not** establish that the old natural run had precisely this geometry or that every original pending pair had this cause. The original A.1 deterministic board old/new evidence remains valid.

The new placement crossing risk and the extended natural Chromium Game Over unconfirmed save are separately documented in `MERGE_PLACEMENT_REPORT.md` and `MERGE_DEADLOCK_REPORT.md`; neither is evidence of actual data loss.

---

# V0.9.1-A.1 — root cause analysis (PARTIAL)

Baseline production code: `5285aa036331a12ebf97f5c78024ceaf2a5f1d0a`; reproduction-only commit `ea6375c` changes only the test and its CI workflow. Godot 4.7.2 native run [46074106020](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46074106020), `MERGE_EXPECT=baseline`, 7/7 checks. A frozen, touching 7×7 mouse lattice reserves a single pair; a non-overlapping position exists at (360,500), but all candidate positions from the old 0–96 px search are blocked. After 120 explicit deferred-commit attempts the reservation and locks remain, score is unchanged, safe save returns busy and drop is blocked. The old source has no cancellation or other exit for `find_merge_position(...) == null`: `_commit_pending()` simply continues, and `_physics_process` schedules it again. This is an empirically demonstrated deadlock mechanism on the controlled board, not merely a timeout theory.

The earlier Chromium/Firefox natural traces establish persistent locked pairs while gameplay time advances, blocked input and empty snapshots (`docs/qa/v091-a/`). They did not capture or reconstruct the exact collision geometry, so **the 96 px exhaustion mechanism has not been established as the cause of those particular natural occurrences**. No measured refresh loss is asserted. Root cause of that natural geometry remains unproven.

Save issue: the old HUD used an aggregate observer which verifies bytes of latest tracked writes, not the current live board. The Firefox baseline showed live 587 vs checkpoint 427 while the aggregate observer was verified. Correct bytes for a previous file do not certify a newer live session.

Mitigation: near-first sampling is retained, extended to bounded 192 px. When no candidate is clear, only the checked failed pair is cancelled, its still-live originals remain and no merge/score is emitted. Invalid, queued-for-deletion or detached pair members cancel safely and only unshared survivors unlock. Successful pairs retain normal deferred commit and exactly-once scoring. A drained queue schedules safe autosave; existing save guards still reject active reservations. Cancellation does not promise immediate retry for continuous contact; distant relocation and the sampling grid require gameplay evaluation. This is not proof that all infinite-pending circumstances have been ruled out.

The HUD now compares a content-hash revision of the complete live snapshot with the locally selected written envelope and the exact observed IndexedDB read-back for that path. Generation and continuously advancing `progression.play_seconds` are excluded; score, bodies/positions, counters and power-ups are included. It shows deferred, unsaved, saving, verified, unconfirmed, failed or unavailable. Requested/written/verified revision and verified score are exposed in QA details; a fresh page cannot call a pre-existing unobserved envelope verified until a tracked write is read back. The observer remains asynchronous, is not a cross-file atomic transaction, and cannot guarantee sudden-close durability.

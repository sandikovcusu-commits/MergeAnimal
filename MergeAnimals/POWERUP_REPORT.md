# V0.6.3.3 DEV — Rescue

Classic has one free Rescue per new session. It is available only on the paused Game Over screen; it is not an ad or a reward. Game Over is pending until Play Again/Main Menu explicitly commits a tombstone. Continue restores a pending Game Over and its board instead of counting a completed game. A successful Rescue resumes the same game; a later final loss counts once. `RewardRequestGateway.RESCUE` remains an unconnected verified-callback boundary; there is no SDK or simulated reward.

The planner requires every animal whose top crosses the danger line to be removed, then minimizes extra spawn blockers across the permitted horizontal spawn interval. It resolves ties by protecting higher levels and preferring the current aim; mandatory danger animals are ordered by highest top, then lower level and stable UID. This is a conservative *geometric safety policy*: it does not predict future physical settling and is not a proof that the globally smallest number of physical removals would suffice. If that set exceeds the `rescue_max_remove` export (default 10), or if the actual physics query finds a remaining collider, Rescue fails without consuming a use. The candidate is validated and the power-up checkpoint committed before the live board or allowance changes. A 0.4-second paused highlight precedes safe detach and the existing soft burst; RESCUED is transient. Reduced effects suppress the burst, not the safety indication.

The checkpoint retains score/best, progression, counts, discovery dates, Golden, current/next and RNG, as well as current Undo/Remove allowances. Rescue resets danger timers, clears any old Undo snapshot, and adds a short spawn cooldown. Pending merge reservations are cancelled without deleting or scoring either animal before the Game Over checkpoint; a deferred merge is unable to commit while paused. The spawn is checked against the live physics space before commit and input remains locked until that query is clear on a subsequent physics tick. There is no automatic recovery if the spawn is later occupied indefinitely by moving bodies; such a board may need a restart.

Actual Godot 4.7.2 tests and fixture screenshots are identified in `QA_REPORT.md`; save and rollback limits in `SAVE_SYSTEM_REPORT.md`. No new sprites, Challenge, Achievement, SDK or physics parameter change was made.

---
# Historical V0.6.3.2 DEV — Undo and power-up integrity

## Undo rules

One free Undo per Classic session. The existing session snapshot is captured immediately before each successful drop, only when there is no pending or scheduled merge and the board is snapshot-safe. A blocked drop does not replace the previous snapshot. It includes stable board-body UIDs and animal IDs/levels, transform and velocities, sleep and eligibility, per-body danger timers, current/next, RNG state, score, combo, cooldown, tutorial and progression. The snapshot is non-recursive and is included in session saves. A safe deferred autosave is requested after a successful drop; unfinished merges can defer saving until the next safe checkpoint.

The Undo button is disabled without a snapshot, after use, during Remove selection, an outstanding drop/merge, pause/game-over or processing. On request, gameplay input and physics pause, pending merges and snapshot validation are rechecked, the candidate state is committed before the live board is touched, and old bodies are locked, disconnected, detached and queued for deletion. A failed checkpoint leaves the board and allowance unchanged. The restored body gets its saved UID but a new engine instance; danger timers are remapped. The current Remove balance is retained and Undo decreases from the *current* balance, never from the old snapshot. A successful Remove invalidates the previous Undo snapshot; the selection prompt states this. A later drop creates a new one.

## Statistics, discovery and score

The rollback restores drop/merge/Golden totals, per-animal creation counts, current score, combo and the best earned after the undone boundary. Play time continues and is not rewound. Unlocks and first discovery dates are permanent: a discovered animal may have creation count zero after rollback. Unlock state uses its discovery date rather than count, so replaying it increments the count once without another discovery notification. Lifetime highest discovered tier is retained. Existing legacy dates/counts migrate without invented discoveries.

Session v3 progression is now authoritative for best score; the separate old `wild_garden.cfg` score is imported only for legacy/missing data and is no longer updated on each merge. Thus an obsolete separate file cannot reintroduce a record undone in v3. Best is persisted with session checkpoints rather than independently at the instant of each merge; a crash before a safe checkpoint can lose recent progress/records. Other pre-existing settings/tutorial config files are unchanged.

## Power-up commit

Remove and Undo use a full, checksummed atomic power-up checkpoint with increasing save generation. It stores the resulting board and both remaining allowances together. The checkpoint is the commit point; the usual primary and backup are mirrored afterwards. When the mirror fails after that commit, gameplay still applies the committed operation, and the newer checkpoint wins over an older valid backup. Restart/game-over tombstones also commit to this checkpoint, preventing resurrection of the previous game. A corrupt existing checkpoint fails closed. Details and limits in `SAVE_SYSTEM_REPORT.md`.

## Evidence and scope

At `a40def8`, [Undo CI 45760082968](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082968) passed 161/161 integration checks including 100 fixture-only allowance resets/Undos, plus 5/5, 7/7 and 3/3 checks in three separate processes. Chain's first merge comes from the actual drop/contact; the fixture then repositions and gives velocities to the resulting and preexisting hamsters, and the second merge is another real physics contact. Golden uses fixture elephants given opposing velocities and a real contact. These are automated fixtures, not human play. Mouse and simulated touch traverse the X11 Godot GUI. Eight full 720×1280 PNGs are in the Actions artifact; reduced copies are in `art_reports/v0632_undo/`. The visual chain fixture directly requests two merge pairs to make the views reproducible; it is not evidence of a natural chain.

[Remove CI 45760082996](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082996) retained 79/79 checks and the separate-process suite. [Gameplay/save regression 45760082958](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082958) passed. No Rescue, Challenge, Achievement, ad SDK, new sprites or physics parameter changes were added. This remains DEV, not commercial release approval.

---

# Historical V0.6.3.1 DEV — Remove power-up

Historical V0.6.3.1 snapshot: subsequent V0.6.3.2 changes above supersede its Undo, commit and backup statements.

## Remove behavior and transaction

- The HUD uses the existing Remove SVG. Select opens the mode, blocks drops and draws yellow rings around eligible live board animals. The same button becomes Cancel; invalid selection and Cancel do not consume a use. Pausing cancels selection. The used button is disabled. Input supports mouse and touch; the X11 fixture also routes simulated GUI mouse and touch through the actual viewport.
- Selection can only target a live, non-queued, non-merge-locked `Animal` directly under `Pieces`. Previews and unrelated nodes are excluded. Position selection chooses the nearest eligible body within its radius. The deferred commit checks eligibility and rejects pending/scheduled merges again. It disconnects the removed body's merge signal, locks it against stale callbacks, clears its danger timer, detaches it and queues it for freeing. Remove does not award score, merges or collection events.
- The free balance starts at one per Classic session; the optional validated `remove_remaining` field is part of the existing v2 session snapshot. V1/v2 snapshots lacking it get one. Selection is transient and Continue starts outside selection. A candidate snapshot excludes the selected body and decrements the allowance together. For persisted games it is validated and atomically written to the primary **before** changing the live board; if the write is rejected or fails, neither body nor allowance changes. The primary is the commit point. On success, a second write refreshes the backup with the same committed state; a failed backup refresh emits a warning but cannot roll back the already committed primary. If that warning occurs and the primary is later damaged before backup repair, the older backup can restore an earlier allowance. This failure combination, power-loss/fsync and concurrent writers are not tested; there is no claim of crash-proof multi-file durability. The game can be retried after normal save errors. Existing V0.6.2 saves remain readable; downgrading to older game builds may discard the additive field and is unsupported.
- `persist_best = false` bypasses disk only in nonpersistent test fixtures. The 50-operation stress fixture resets its balance **only inside the fixture**, alternating 25 frozen and 25 moving rigid bodies. Production does not reset it except on a new game. The prior standalone rewarded-callback boundary remains unconnected; no ad SDK or extra reward exists.

## Executed evidence

Godot 4.7.2 at `a21e09a`: [Remove integration/X11 45757629043](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45757629043) passed 79/79 single-process checks including 50 fixture removals, 25/25 write-process checks and 7/7 read-process checks. The latter actually uses the Main Menu Continue button in a separate Godot process, then verifies a further drop and restart. The save-failure case uses deliberately corrupt primary and backup files; physical disk-full or interrupted writes were not injected. The five PNGs in that Actions artifact are real X11/Xvfb windows at 720×1280, from a seeded scripted fixture, not human play. Reduced JPEG copies are under `art_reports/v0631_remove/`. Regression details and limitations are in `QA_REPORT.md`.

## Audited baseline

Baseline: `f9721c40a9169a2a260fc8d77e0daa9316e28402` (V0.6.2). Classic drop is requested in `_unhandled_input`/`drop_animal` and committed in `_attempt_drop` on a physics tick, after the spawn-space query. The existing `_session_snapshot` stores body transforms, velocities, per-body danger time, provenance, queue, RNG, score/combo and progression. It returns an empty dictionary when any body is locked or queued for deletion. `save_session` additionally rejects pending or scheduled merges and an outstanding drop. This is the snapshot format to extend, not a separate physics representation.

`MergeManager` synchronously locks pairs on contact and queues a deferred `_commit_pending`; pairs without space can remain pending. Restoring over these objects without invalidating deferred work and collision callbacks risks awards or deletion from the old board. Restoring on a physics/contact callback is unsafe. `DangerMonitor` counts only supported, settled animals above the line and tracks time by transient instance UID; restored bodies need new UID timer mapping and peak display refresh. `_spawn_clear` queries the current physics space: a rescue cannot be declared safe merely from the previous frame's state.

Progression and session v2 share the checksummed atomic document, with backup and future-version/corruption refusal. V1/v2 migration must remain conservative. `Progression.record_animal` currently uses the same `count` for unlock and created count: simply retaining counts after Undo inflates replay statistics, while simply restoring the old dictionary causes repeated discoveries. Separate durable first-discovery state from rollback-able counts, with migration and validated, non-recursive snapshot data. Play time needs a policy independent of rewinding board state. `Game._save_best` writes a separate legacy config immediately on merge; a post-drop record cannot safely be undone solely by restoring the session. A complete implementation must prevent the legacy best from resurrecting a rolled-back score, including after crashes or recovery, without losing pre-existing best scores.

On `_on_game_over`, the current code increments completed games and immediately writes an inactive tombstone (twice); it then zeroes combo and pauses. Rescue requires a durable, validated game-over/rescue transition, not simply hiding the panel: otherwise Continue cannot recover the game-over board and completed-games can be double-counted. An interrupted rescue and failed writes must leave a recoverable prior state. The exact minimum-removal and spawn-clear policy needs testable deterministic specification, particularly where multiple removal sets exist and body physics can shift after unpause.

## Adapter implemented, not wired to gameplay

`RewardRequestGateway.gd` is an independent callback boundary for the three named request kinds. It emits a request, never grants inventory, permits only one outstanding request, and ignores mismatched or repeated callbacks. Its `resolve` method is **not a verifier**: a future platform adapter must authenticate/verify the actual platform completion and explicitly invoke it; there is no SDK or callback wired now. No request UI or reward-granting code is included. Pending requests are intentionally in-memory; any future integration must explicitly specify restart/cancellation behavior and protect against callbacks crossing sessions before granting anything.

## Historical V0.6.3 work still required (other than Remove)

- Define and implement a versioned, strictly validated, non-recursive undo snapshot and persistent monotonic use counters, migrating v2 while preserving future-schema safeguards and atomic backup semantics.
- Build safe pre-drop capture, board replacement, pending merge cancellation/invalidation, notification treatment, and explicit rollback policies for stats and separately persisted best score. Cover normal, chain and Golden merges, RNG, timers, pause and Continue.
- Implement real Game Over rescue with deterministic minimum removals, preserve valuable animals, clear danger, verify spawn and guard against immediate failure; safely handle completion and restart.
- Integrate the gateway only with a real verified platform callback; currently no extra power-ups can be obtained.
- Implement HUD and game-over buttons, localized strings, mobile input handling, all requested automated and X11 fixtures, stress and two-process persistence tests. Run all prior regressions.
- Produce the requested versioned reports, source ZIP and checksum only after actual acceptance; update PR #1 honestly and do not merge main.

## Existing risks retained

Commercial rights for the 12 AI-derived sprites are unverified. The prior 120 Hz physics fixture still measured up to 9.190 px penetration; trajectories differ across tick rates. Real mobile performance, battery use, touch behavior and Web export remain unverified.

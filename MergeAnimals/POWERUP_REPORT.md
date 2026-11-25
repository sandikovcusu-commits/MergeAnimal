# V0.6.3 power-up work — INCOMPLETE

This is an audit and a small unintegrated adapter, not a V0.6.3 release. Undo, Remove and Rescue are **not implemented**. No in-game power-up UI, free allowances, persistence, screenshots, stress tests or deliverable ZIP have been produced. Do not use this report as release acceptance.

## Audited baseline

Baseline: `f9721c40a9169a2a260fc8d77e0daa9316e28402` (V0.6.2). Classic drop is requested in `_unhandled_input`/`drop_animal` and committed in `_attempt_drop` on a physics tick, after the spawn-space query. The existing `_session_snapshot` stores body transforms, velocities, per-body danger time, provenance, queue, RNG, score/combo and progression. It returns an empty dictionary when any body is locked or queued for deletion. `save_session` additionally rejects pending or scheduled merges and an outstanding drop. This is the snapshot format to extend, not a separate physics representation.

`MergeManager` synchronously locks pairs on contact and queues a deferred `_commit_pending`; pairs without space can remain pending. Restoring over these objects without invalidating deferred work and collision callbacks risks awards or deletion from the old board. Restoring on a physics/contact callback is unsafe. `DangerMonitor` counts only supported, settled animals above the line and tracks time by transient instance UID; restored bodies need new UID timer mapping and peak display refresh. `_spawn_clear` queries the current physics space: a rescue cannot be declared safe merely from the previous frame's state.

Progression and session v2 share the checksummed atomic document, with backup and future-version/corruption refusal. V1/v2 migration must remain conservative. `Progression.record_animal` currently uses the same `count` for unlock and created count: simply retaining counts after Undo inflates replay statistics, while simply restoring the old dictionary causes repeated discoveries. Separate durable first-discovery state from rollback-able counts, with migration and validated, non-recursive snapshot data. Play time needs a policy independent of rewinding board state. `Game._save_best` writes a separate legacy config immediately on merge; a post-drop record cannot safely be undone solely by restoring the session. A complete implementation must prevent the legacy best from resurrecting a rolled-back score, including after crashes or recovery, without losing pre-existing best scores.

On `_on_game_over`, the current code increments completed games and immediately writes an inactive tombstone (twice); it then zeroes combo and pauses. Rescue requires a durable, validated game-over/rescue transition, not simply hiding the panel: otherwise Continue cannot recover the game-over board and completed-games can be double-counted. An interrupted rescue and failed writes must leave a recoverable prior state. The exact minimum-removal and spawn-clear policy needs testable deterministic specification, particularly where multiple removal sets exist and body physics can shift after unpause.

## Adapter implemented, not wired to gameplay

`RewardRequestGateway.gd` is an independent callback boundary for the three named request kinds. It emits a request, never grants inventory, permits only one outstanding request, and ignores mismatched or repeated callbacks. Its `resolve` method is **not a verifier**: a future platform adapter must authenticate/verify the actual platform completion and explicitly invoke it; there is no SDK or callback wired now. No request UI or reward-granting code is included. Pending requests are intentionally in-memory; any future integration must explicitly specify restart/cancellation behavior and protect against callbacks crossing sessions before granting anything.

## Work still required

- Define and implement a versioned, strictly validated, non-recursive undo snapshot and persistent monotonic use counters, migrating v2 while preserving future-schema safeguards and atomic backup semantics.
- Build safe pre-drop capture, board replacement, pending merge cancellation/invalidation, notification treatment, and explicit rollback policies for stats and separately persisted best score. Cover normal, chain and Golden merges, RNG, timers, pause and Continue.
- Implement Remove selection/input isolation, eligibility, cancel, visible selection and durable one-use transaction.
- Implement real Game Over rescue with deterministic minimum removals, preserve valuable animals, clear danger, verify spawn and guard against immediate failure; safely handle completion and restart.
- Integrate the gateway only with a real verified platform callback; currently no extra power-ups can be obtained.
- Implement HUD and game-over buttons, localized strings, mobile input handling, all requested automated and X11 fixtures, stress and two-process persistence tests. Run all prior regressions.
- Produce the requested versioned reports, source ZIP and checksum only after actual acceptance; update PR #1 honestly and do not merge main.

## Existing risks retained

Commercial rights for the 12 AI-derived sprites are unverified. The prior 120 Hz physics fixture still measured up to 9.190 px penetration; trajectories differ across tick rates. Real mobile performance, battery use, touch behavior and Web export remain unverified.

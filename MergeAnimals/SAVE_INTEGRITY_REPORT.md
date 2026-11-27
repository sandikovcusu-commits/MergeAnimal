# V0.9.0.2 — Save integrity (private test, work in progress)

Code and browser tests: commit `58a04ee`. The new status is observational, not a transactional durability fix. V0.9.0.2 acceptance is **not complete**.

## Existing integrity model

`SaveManager` validates a versioned SHA-256 envelope, writes/flushes and validates a temporary file, copies a valid primary to backup and renames. It fails closed on future/unreadable files. On Web these operations are in MEMFS, and success does **not** confirm IndexedDB. Session v3 contains a generation, session ID, board and motion, score/best/progression, undo state, remove/rescue use, rewarded-rescue flag and RNG; the newest valid session/backup/power-up checkpoint is selected under a single-writer assumption. Earlier formats migrate. Non-session settings/audio/language, theme, challenge and achievements use separate stores; there is no atomic commit across these files.

Irreversible power-up and game-over checkpoints, session/reward callback identifiers and gateway duplicate filtering are pre-existing. Rewarded Rescue's consumed flag is checkpointed, but its commit is only MEMFS success and the in-memory duplicate gate is not a durable transaction ledger. A crash before IndexedDB completion can roll back a reward/use. No server-backed exactly-once guarantee exists. Autosave is deferred at approximately one-second intervals and can be postponed by unsafe physics/merge state; no code here removes that window.

## New checkpoint read-back

On Web only, after a successful `wild_garden_session.json` or `wild_garden_powerup.json` rename, `SaveDurability` uses a **read-only** IndexedDB transaction against the Godot 4.7.2 IDBFS record and compares the entire final envelope to the exact expected bytes. The newest tracked revision for each path replaces earlier observations; a read transaction must complete before `verified`. The Game HUD displays Saving checkpoint / Checkpoint saved / Save not confirmed. Timeouts and access errors are unconfirmed; lack of persistent filesystem is also unconfirmed. The observer does not invoke `FS.syncfs` and does not compete with Godot as a writer.

This verifies only the most recent *written checkpoint*, not changes that have not yet been snapshotted or other stores. The label does not imply the latest action, all game data, OS-level fsync, non-eviction, cross-tab safety, or future retention. There is no flush barrier in reward commit; the game does not wait for read-back before applying rewards. Settings, theme, collection, statistics, challenges and achievements are **not** individually covered by this status. A local write failure continues to use the pre-existing failure UI. Browser restrictions, incompatible future IDBFS internals or timeouts must remain unconfirmed. Multiple tabs, sudden termination and storage clearing/eviction remain unprotected.

## Remaining acceptance

A real end-to-end browser matrix for rapid saves, IndexedDB storage failures, old-version migration, and all separate stores is not complete. Scoped corrupted-primary and local file-failure fixtures passed in both browsers. Native tests do not establish Web persistence. See `WEB_QA_REPORT.md` for actual runs and fixtures. Fixes to asynchronous reward transaction semantics, per-store acknowledgements, retry UX and concurrent writers need separate design and validation; do not present this as a fully durable save system.

# Save integrity — V0.9.1-A.1 PARTIAL

## Current vs checkpoint

A content revision hashes normalized snapshot data excluding storage generation and continuously changing play seconds. The snapshot contains score, board state, power-ups and other session data. Requested revision is assigned at session-write request; written revision is computed from the valid locally selected envelope, with its generation. Verified revision/score are set only when the observer read-back for that exact source path and bytes reports verified. Current revision is separately computed from the live snapshot. Snapshot serialization still refuses locked animals; the HUD's read-only inspection can represent them but reports deferred while a reservation/drop exists.

Status precedence is unavailable/failed, deferred, unsaved, saving, verified, unconfirmed. The exact selected envelope must match current revision and the aggregate tracked writes must be verified before the HUD says Saved. A failed local save is still handled by existing `SaveStatus`; both are displayed independently. Verified means a read-back was observed, not guaranteed durable against all browser or device failures. Hashes are content identifiers, not security/anti-tamper proofs. Revision details are diagnostics rather than a new on-disk schema.

## Executed

- Chromium 46074749255, Firefox 46074752395 (0972f35): 15/15 each, QA-injected frozen board. Checks include prior verified state, score unchanged + power-up change = unsaved, held IndexedDB transaction = saving, pending merge = deferred and safe save refused, resolution and save read-back, subsequent drop and refresh with expected score, spawn count and power-up. Full logs in `docs/qa/v091-a1/merge-{chromium,firefox}.log`.
- Previous 52-check save integrity suite rerun on modified code: Chromium 46074758542 and Firefox 46074761541, **52/52 each**; includes injected browser-storage faults. Injected failure is not proof of actual quota/permission behavior.
- Native dense fixture 46075602196 passed; native session, Undo, Remove, Rescue workflows succeeded on `0972f35`.
- Natural browser gameplay attempted but did not reach Game Over on either browser; no natural Game Over restore/close acceptance claimed. No actual sudden-close loss experiment or cross-file atomicity proof. Browser refresh after verified fixture is not a sudden-close guarantee.

A moving board may correctly return Unsaved changes immediately after a checkpoint because exact positions and velocities continue to change. Polling and reading/hash of complete state every 250 ms has not received reliable real-mobile performance analysis. Observer entries are session-scoped; after reload an older envelope is unconfirmed until newly tracked. These limitations require further testing.

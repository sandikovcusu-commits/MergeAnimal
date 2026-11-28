# V0.9.1-A.4 — aggregate save observer (SAVE-AGGREGATE-OBSERVER-005): PARTIAL

Status: scoped-aggregate fix in `560a803`; CI results pending (see below).
Commercial status: BLOCKED. The original natural Chromium unconfirmed event
(`46077100528`) remains unproven and is kept as an open risk.

## Root cause investigation (baseline `e63c38c`)

Chromium run `46084133893` (isolated observer fault, `cea8215`): session
record verified (5 attempts), power-up record still pending (8 attempts,
0 retries, <12 s deadline), aggregate `pending`, `details.status` `pending`.
Firefox `46084136488` verified both files and passed 9/9.

Findings:

1. **Aggregate scope (product).** `Game._checkpoint_details`
   (`Game.gd:294-318`) required the *global* observer aggregate
   (`SaveDurability.state()`, `SaveDurability.gd:94-102`) to be `verified`.
   The global aggregate covers every tracked file (session, power-up,
   progress, settings, themes, challenges, achievements...), so an unrelated
   pending file blocks the session checkpoint status, and a stale
   `unconfirmed` record for any file blocks it indefinitely.
2. **Required-file timing (not data loss).** The terminal write commits the
   power-up record first, then the session primary (twice). IDBFS sync of the
   two files is not atomic; at the sample instant the session entry had
   synced and verified while the power-up entry had not. The product
   correctly refused to claim `verified` — per specification, session
   verified + power-up pending must stay pending/unconfirmed. The A.3 test
   asserted `verified` at the first session match, i.e. too early.
3. **No evidence of a stuck power-up write.** The power-up record was still
   inside its 12 s pending window polling every 250 ms; retries were 0, so
   no watchdog failure had occurred. Whether it would have verified moments
   later is unproven — the run ended at the assertion.

Conclusion: the failure is an aggregate-scope defect plus a racy test
assertion, not a demonstrated save-data loss. Cross-file atomicity is still
not guaranteed and is not claimed.

## Fix (`560a803`)

- `SaveDurability` gains `statusForFiles(paths)` / `state_for_files(paths)`:
  aggregate over only the requested files (failed > unconfirmed > pending >
  verified; `idle` when none tracked).
- `Game._checkpoint_details` aggregates only the session primary +
  power-up commit record. Unrelated files no longer block the session
  status; a pending power-up record for the current commit still keeps it
  pending. Details now expose `scoped`, `aggregate`, `powerup_status` and
  `powerup_generation` for diagnostics.
- The global HUD indicator still uses the global aggregate (unchanged).
- `confirmation-a3.mjs` now waits for both required files before asserting
  `verified` (strengthened, not weakened).

## Tests

- `confirmation-a4.mjs`: per-file read-fault injection (power-up blocked →
  session verified but aggregate not verified; session blocked → not
  verified), recovery to verified, stale-revision (newest write wins),
  duplicate track of identical bytes, delayed writer lock (pending during
  lock, verified after release). Both browsers.
- Previous 9-test observer suite (`confirmation-a3.mjs`, `confirm-a3-fixed`)
  rerun in both browsers.

## Results (pending CI)

- Observer A4 Chromium: TBD
- Observer A4 Firefox: TBD
- Observer A3 rerun Chromium: TBD
- Observer A3 rerun Firefox: TBD

## Open risks

- Original natural Chromium unconfirmed cause (`46077100528`) unproven.
- IDBFS sync lag between the two commit files remains; aggregate correctly
  reports pending until both verify. Sudden-close durability, eviction and
  cross-file atomicity remain unverified.

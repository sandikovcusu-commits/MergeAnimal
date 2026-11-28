# V0.9.1-A.4 — automatic contact retry (MERGE-CONTACT-RETRY-004): PARTIAL

Status: implementation complete and exercised. Commit `5de6f06` (product) plus
`1441491` (native harness), verified by CI run `46091855431` on `1c5305b`.
Commercial status: BLOCKED. This report does not claim commercial clearance.

## Root cause (baseline `e63c38c`)

- `MergeAnimals/scripts/managers/MergeManager.gd:48-49` (`observe`) connects only
  `body_entered`. `body_exited` is never connected, and Godot fires
  `body_entered` once per new contact, not continuously while contact persists.
- `MergeManager.gd:71-74` (`request_merge`) suppresses a failed pair while
  relevant geometry is unchanged (1 px clearance). The suppression is correct,
  but nothing re-invokes `request_merge` when geometry later changes: the only
  callers are `_on_body_entered` and explicit test/player paths.
- `MergeManager.gd:81-84` (`_physics_process`) only drains `pending`; it never
  scans failed pairs. Sleeping/resting bodies generate no new contact events.
- Result: after a no-safe-placement cancellation (`_commit_pending`,
  `MergeManager.gd:121-126`), a continuously touching pair can never retry
  automatically, even after blockers move. Explicit re-request works because it
  re-evaluates the geometry gate directly.

## Fix (`5de6f06`)

- Cancelled pairs are tracked with pair key, weak body refs, session id,
  geometry snapshot, attempt count, last-attempt time, midpoint and cancel
  reason (`no_safe_placement` only; other cancellations are not retry-eligible).
- `body_exited` is now connected and, together with `body_entered`, sets a
  dirty flag. A throttled scheduler (0.25 s, max 4 re-requests per tick) scans
  only tracked failed pairs — never all bodies — and re-requests a pair only
  when: both bodies live in `pieces`, same session, not locked, same id/level,
  physical contact persists (centre distance ≤ radii sum + 2 px), and relevant
  geometry changed since the failure. Broken contact drops the entry.
- Placement safety is unchanged: the re-request goes through the normal
  reserve/commit path, so `find_merge_position` bounds and the Danger Line
  guard still apply. No forced merge is possible.
- `Game._commit_undo` clears retry state after board replacement; all other
  transitions rely on prune + geometry + session checks.
- Metrics: `retry_state()` exposes failed/pending/cancelled/attempts/
  successes/max delay/contact-broken for stress reporting.

## Tests

- Native `tests/integration/contact_retry_a4.gd`: deterministic cancel → static
  (no retry) → blocker moves → automatic retry, score exactly once, save/drop
  unblocked; contact break, deletion, pause/resume, Game Over gate, golden,
  explicit clear. No explicit re-request in the main scenario.
- Native `tests/integration/merge_stress_a4.gd`: 300 synthetic cases
  (100 seeds × 10/20/40 bodies) with scheduler enabled.
- Web probe ops `contact_retry` / `contact_retry_matrix` + `contact-retry-a4.mjs`:
  frozen dense board in Chromium and Firefox, 30 matrix cases per browser.

## Results (executed)

- Native contact retry `46091855431`: `CONTACT_RETRY_A4 checks=26 failures=0`.
- Native stress A4 `46091855431`: `MERGE_STRESS_A4_COMPLETE cases=300 seeds=100 failures=0`.
- Web contact retry, Chromium `46090588078`: `CONTACT_RETRY_A4 browser=chromium checks=8 failures=0 cases=30`.
- Web contact retry, Firefox `46090590413`: `CONTACT_RETRY_A4 browser=firefox checks=8 failures=0 cases=30`.

### Web deterministic scenario (both browsers, frozen dense board)

1. Pair reserves, no safe placement, cancellation recorded (`cancelled=1`,
   `attempts=0`).
2. Blocker held static: no automatic retry (`attempts=0`, `failed=1`).
3. Blockers removed, pair still in contact: automatic retry without any
   explicit request (`attempts=1`, `successes=1`, `failed=0`).
4. Merge completes once: `merges=1`, `score=4`, `pending=0`, `locks=0`.
5. Save snapshot present (`snapshot_empty=false`), `save_error=0`.
   Retry delay: Chromium 0.466 s, Firefox 0.492 s.

### Native stress matrix (100 seeds x 10/20/40 bodies)

- 300 cases, 0 failures; 79 cancellations, 79 automatic retries, 79
  successes (a cancelled pair that later gained safe space merged
  automatically).
- Duplicate merges 0, duplicate score 0 (`score == 4 x merges` in all cases),
  body loss 0, `pending` queue maximum 2, locks 0 at end.
- Cases with no later safe placement stayed cancelled, as intended: the goal
  is lawful automatic continuation, not forcing every cancellation to merge.

## Open risks

- Retry delay is bounded by the 0.25 s scheduler interval plus commit latency;
  exact delay depends on physics frame rate.
- A pair whose geometry oscillates by ≥1 px can retry at most 4 times per
  scheduler tick; each retry re-validates placement, so no unsafe merge.
- Natural gameplay impact (12/60 synthetic cancellations in A.3) is reduced
  but not eliminated: pairs with no safe placement still cancel correctly.

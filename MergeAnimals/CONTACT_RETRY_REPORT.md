# V0.9.1-A.4 — automatic contact retry (MERGE-CONTACT-RETRY-004): PARTIAL

Status: implementation complete in `5de6f06`; CI results pending (see below).
Commercial status: BLOCKED. This report does not claim acceptance.

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

## Results (pending CI)

- Native contact retry: TBD
- Native stress A4: TBD
- Web contact retry Chromium: TBD
- Web contact retry Firefox: TBD

## Open risks

- Retry delay is bounded by the 0.25 s scheduler interval plus commit latency;
  exact delay depends on physics frame rate.
- A pair whose geometry oscillates by ≥1 px can retry at most 4 times per
  scheduler tick; each retry re-validates placement, so no unsafe merge.
- Natural gameplay impact (12/60 synthetic cancellations in A.3) is reduced
  but not eliminated: pairs with no safe placement still cancel correctly.

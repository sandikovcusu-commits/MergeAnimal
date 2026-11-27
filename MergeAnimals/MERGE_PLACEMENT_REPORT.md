# V0.9.1-A.2 — Merge placement safety

**Verdict: NOT ACCEPTED — Danger Line crossing and displacement need gameplay/physics review.** This session does not alter A.1 production code, physics or game design.

## Method

`MergeVerificationProbe.gd` is injected only into a separate QA WebAssembly export. Existing `Game.find_merge_position` and `MergeManager` execute unchanged. Fixed frozen-board placement tests are not a human visual inspection or natural collision trace. Actual Chromium [46078122992](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46078122992) and Firefox [46078126276](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46078126276) returned identical geometry. Logs: `docs/qa/v091-a2/final-*.log`.

| Setup | Midpoint → result (px) | Displacement | Finding |
|---|---:|---:|---|
| 7×7 dense, high | (378,452) → (510,452) | 132 | Above danger line both before and after |
| 7×7 dense, bottom | (378,908) → (510,908) | 132 | Large lateral jump |
| 4×7 upper touching lattice, target pair in row 1 | (342,380) → (342,500) | 120 | Pair is above danger; committed replacement is below danger |
| Wall/floor, free area | (127,1076) → (127,1071) | 5 | Result radius 23, within wall 91–629 and floor 1094 |
| Approximate old Firefox cat pair | (~482.29,911.57) → (~482.29,743.57) | 168 | Actual current native implementation, approximate reconstruction; see root cause report |

The Danger Line is at y=465. The 4×7 frozen lattice uses 36 px mouse spacing and a mouse radius of 18. The pair top is y=362 (<465); the committed hamster radius is 23 and its top is y=477 (>465). Its score becomes 4 and merge count 1. This proves a search/commit can move a replacement across the threshold, not that a complete natural Game Over was incorrectly prevented: the other fixture bodies remain above the line, support/timers and moving contacts were not reproduced. It nevertheless prevents a safety sign-off on potential artificial rescue and balance/visual teleporting. A near-first 12 px radial grid picks the first sampled clear location, **not the globally nearest continuous free point**; the configured sampled radius is 192 px and boundary clamping may further alter displacement. Human in-game visual judgement, timer/support effects, and balancing have not been tested.

The 30 cases per browser for 10/20/40 frozen bodies check every resulting hamster for walls/floor and overlap with other animals; none failed. Max first-candidate displacement there was 84.00002 px. Those results do not prove all possible geometries, foreign non-animal colliders, upper boundary/danger semantics or real-mobile visuals. No-space synthetic blockers test body preservation, no score, snapshot and retry; it is intentionally overlapping and not a naturally stable pile.

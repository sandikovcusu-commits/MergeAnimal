# V0.9.1-B.2 — Physics root-cause analysis (penetration)

Scope: verify the A.1/A.2 baseline claim (120 Hz, max penetration 9.190 px,
100 seeds, no full escape) and find the mechanism behind it before changing
anything. No product code is modified in this phase.

## 1. Baseline claim, re-measured

| Claim | Re-measured | Verdict |
| --- | --- | --- |
| 120 Hz physics | `project.godot` `common/physics_ticks_per_second=120`; `PHYSICS_CONFIG ticks=120` in every run | CONFIRMED |
| max penetration 9.190 px | `IMPACT_COMPLETE cases=60 max_depth=9.190` (5 drops x 12 levels) | CONFIRMED, new measurement |
| no full escape | `escape=false` in 60/60 impact drops and 600/600 dense cases | CONFIRMED |
| 1–2 px target unmet | 12 of 60 impact drops exceed 2 px; dense boards up to 5.82 px | CONFIRMED unmet |
| 100 seeds | dense audit runs 100 seeds per body count per policy (600 cases) | CONFIRMED |

The number 9.190 px is not a stray maximum: it is reproduced exactly, five
times, by hamster (level 2) dropped from the real spawn height.

## 2. Mechanism: one solver step of free fall

`_attempt_drop()` creates the body at `spawn_height = 350` and gravity is the
project default 980 px/s². A body released from rest therefore arrives at the
floor with `v = sqrt(2*g*h)` where `h = floor_height - radius - spawn_height`.
In one physics step (1/120 s) it travels `v/120`. Measured against that
prediction, for all 12 levels (mean of 5 drops each, variance 0 px):

| lvl | id | r | drop h | v_pred | step_pred | measured max | ratio | rest depth |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | mouse | 18 | 726 | 1192.88 | 9.9407 | 4.190 | 0.42 | 0.098 |
| 2 | hamster | 23 | 721 | 1188.76 | 9.9064 | **9.190** | 0.93 | 0.242 |
| 3 | rabbit | 29 | 715 | 1183.81 | 9.8651 | 5.651 | 0.57 | 0.245 |
| 4 | cat | 35 | 709 | 1178.83 | 9.8236 | 2.171 | 0.22 | 0.025 |
| 5 | dog | 42 | 702 | 1173.00 | 9.7750 | 9.171 | 0.94 | 0.285 |
| 6 | fox | 50 | 694 | 1166.29 | 9.7191 | 7.751 | 0.80 | 0.020 |
| 7 | raccoon | 59 | 685 | 1158.71 | 9.6559 | 7.392 | 0.77 | 0.115 |
| 8 | koala | 69 | 675 | 1150.22 | 9.5851 | 8.094 | 0.84 | 0.220 |
| 9 | panda | 80 | 664 | 1140.81 | 9.5067 | 0.677 | 0.07 | 0.259 |
| 10 | bear | 93 | 651 | 1129.58 | 9.4132 | 4.559 | 0.48 | 0.273 |
| 11 | lion | 108 | 636 | 1116.49 | 9.3041 | 1.506 | 0.16 | 0.214 |
| 12 | elephant | 125 | 619 | 1101.47 | 9.1789 | 0.695 | 0.08 | 0.244 |

Every measurement is **below** the one-step bound (ratio 0.07–0.94, never
> 1.0), and the residual after settling is 0.02–0.29 px in every case, i.e. a
fraction of a pixel. This is the signature of a discrete-time contact resolver:
the reported depth is the distance the body still had to travel when the
narrowphase first saw the floor, and it is recovered within 2 frames
(`recovery_frames=2` in all 60 drops).

Hypothesis H1 (measured, not assumed): *penetration is bounded by one physics
step of free fall at the impact velocity; it is not accumulated solver drift.*
The per-level spread (0.077 px for panda to 9.19 px for hamster) is not random:
it is `v*step` modulated by the phase of the body relative to the tick, because
the body is created mid-frame and the first integration starts from a slightly
different sub-step offset.

## 3. Dense-board evidence (corrected fixture)

The first dense audit attempt reported 1.842 px for all 300 cases. That was a
fixture artifact: level-1 mice were spawned on a fixed 42 px lattice from
y=1040, so the only contact was their own landing, identical for every seed,
and the mixed-level variant placed larger animals **inside** each other (up to
tens of px), which is why its first numbers (1.3–3.4 px) were also artificial.

The fixture now packs bodies by random level into rows with a 1 px gap and
asserts the initial overlap of every case. Final run (600 cases):

```
initial_overlap = 0.000 in 600/600 cases      (PHYSICS_FIXTURE_CASES overlapped_fixtures=0)
escapes = 0                                   (all 600 cases)
```

| policy | target | cases | spawned min | shortfall cases | max depth | median | p95 | > 2 px |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 natural, merges suppressed | 10 | 100 | 9 | 3 | 4.942 | 1.071 | 3.898 | 23 |
| 0 | 20 | 100 | 9 | 80 | 5.821 | 1.724 | 3.666 | 39 |
| 0 | 40 | 100 | 9 | 100 | 5.800 | 1.706 | 3.664 | 35 |
| 1 levels 1–3, merges live | 10 | 100 | 9 | 1 | 0.346 | 0.020 | 0.020 | 0 |
| 1 | 20 | 100 | 9 | 100 | 2.360 | 1.309 | 2.196 | 8 |
| 1 | 40 | 100 | 9 | 100 | 2.318 | 1.039 | 1.816 | 3 |

Density honesty: a 538 px wide board cannot hold 40 mixed-level bodies without
overlap (a single level-12 body is 250 px wide). The "40 body" rows therefore
report `spawned` (median 35, minimum 9) and are labelled as shortfall cases
instead of claiming 40.

Boundary sides of the worst case per case: floor 337, right 132, left 131. No
case ever ended with a body outside the walls, and `bodies_end` never exceeded
the spawned count.

Contact density in a packed case is high (up to 2070 contact-pair frames per
case at 120 Hz), yet the depth distribution does not grow with body count:
median 1.07 px at 10 bodies vs 1.71 px at 40. That is the opposite of what
solver-drift accumulation would look like, and consistent with H1.

## 4. Candidates (§15)

| # | Candidate | Measured effect | Complexity | CPU | Gameplay | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| A | Geometry (thicker walls / deeper floor) | Not tested — would move `left_bound`/`right_bound`/`floor_height`, which 132/168 px placement and the Danger Line depend on | Low | None | **Changes the playfield** | REJECTED (forbidden by scope) |
| B | CCD mode | CAST_RAY (shipped), CAST_SHAPE and disabled give **byte-identical** depth for all 60 drops | Low | Higher with CAST_SHAPE | None | REJECTED (no effect: the body is not moving fast relative to the floor normal by enough for speculative contact to matter, and the depth is a positional artifact of the step, not a tunnel) |
| C | Material | Not tested — friction 0.5 / bounce 0.1 / damping 0 are gameplay feel values, and depth is a positional quantity | Low | None | **Changes feel** | REJECTED |
| D | Contact stability (solver iterations, `max_contacts_reported`, sleep thresholds) | Not tested; the residual after 2 frames is already 0.02–0.29 px, so there is nothing left to stabilise | Medium | Medium | Risk of soft stacks | DEFERRED |
| E | Spawn/merge validation (predict the floor before creating the body) | Not applied yet; `apply_floor_guard.py` already exists as an isolated test-only variant with measured results in `PERFORMANCE_REPORT.md` | Medium | One clamp per body per tick | None if it only clamps the last step | **CANDIDATE for B.2 phase 2** |

Conclusion for this phase: the only candidate that can reduce the 9.190 px
figure without touching gameplay geometry is E, and only by bounding a single
downward step at the floor. B is disproven with matched data, and A/C are
excluded by the brief. Nothing has been applied to product code yet.

## 5. Regression guards still green

* 132 / 168 px placement limits: unchanged, `tests/integration/placement_a3.gd` 19/19.
* 96 px deadlock: unchanged, `merge_stress_a4` 300/300, 0 duplicate, 0 body loss.
* Danger Line escapes: 0 in 600 dense cases and 60 impact drops.
* Infinite retry: `contact_retry_a4` 26/26 on the same commit.
* Blocked save snapshot: `save_retry_a3` 8/8 on the same commit.

## 6. What is NOT proven

* Real browser or device physics: all numbers are native Godot 4.7.2 headless
  at `--fixed-fps 120`. Chromium/Firefox build with the same project settings
  but were not measured for penetration in this phase.
* Whether 1–2 px is reachable at all in a variable-step 120 Hz game loop; the
  measured floor is one step of free fall, which for a 726 px fall is ~9.9 px.
  Reaching 1–2 px requires predicting the contact before the step, i.e.
  candidate E, and that is a product change that must be measured against the
  A.4 regression set before adoption.

Evidence files: `docs/qa/v091-b2/physics-impact-*.log`,
`docs/qa/v091-b2/physics-dense-p0.log`, `docs/qa/v091-b2/physics-dense-p1.log`.
Suites: `tests/physics/physics_impact_b2.gd`, `tests/physics/physics_audit_b2.gd`.

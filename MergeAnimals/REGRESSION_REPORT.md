# V0.9.1-A.2 — verification results (NOT ACCEPTED)

Production code unchanged since `783db74`; CI refs differ only by QA harness/workflows. Exact run links: `https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/<id>`.

| Coverage | Result | Limit |
|---|---|---|
| Old trace reconstruction | native 46077811425 success | Approximate 34-body checkpoint plus two logged cat positions; baseline old code stuck, new candidate 168px |
| Web merge + pending lifecycle | Chromium 46078992480; Firefox 46078995167, 33/33 each | QA fixture; no manual human/device validation |
| 10/20/40 × 10 seeds | same browser runs, 30/30 each | Frozen manually reserved pairs; `../WEB_STRESS_TEST.csv`; not native 300 or natural browser sessions |
| Three-body, two disjoint pair, chain, golden | same browser runs | Physical bodies and collision callbacks, controlled prepared boards; not broad seed coverage |
| Pending pause/resume/restart/menu/undo/remove/save/refresh/game over | same browser runs | Controlled, some direct method calls; menu blocks until safe, resume manually commits; Game Over from simulated danger monitor |
| 587/427 and observer failure | same browser runs | Synthetic scores and injected failure; no actual quota failure |
| Real 225-input Chromium Game Over | 46077100528 FAILED | Checkpoint in IDB score 3499; aggregate observer unconfirmed at 60s; reload not reached |
| Chromium natural Game Over retry | 46078823863 5/5 | Input 210, verified checkpoint 3404; refresh and Continue; does not negate previous failure |
| Firefox 300-input natural attempt | 46078508210 FAILED | No Game Over at sampled points; spawn counter reset mid-run, so a transient state/session transition cannot be ruled out |
| Firefox natural Game Over retry | 46079789253 5/5 | Input 243; verified checkpoint 4296; refresh and Continue |
| Native A.2 | 46077715137 success | Native fixture and 300 synthetic cases, unchanged production |
| Save integrity legacy regression | Chromium 46074758542, Firefox 46074761541, 52/52 | Prior A.1 identical production |
| Challenge, Achievement, Undo, Remove, Rescue and session | A.1 runs in historical table | Prior A.1 identical production |
| Danger-line crossing | both browsers demonstrated 120px committed crossing | Outcome in natural support/timer gameplay not established; safety acceptance blocked |

The following are not certified: no repeated failed reservations under all real contact patterns; natural false rescue or its absence; every browser timing/physics interleaving; actual mobile FPS, Android, human visual/play/audio; cross-file atomicity or sudden-close safety. CI runs that crashed during import are not counted as passes.

---

# Regression report — A.1 PARTIAL

Code under test: `0972f358a2fbf2d1677ef80afedec04b24b19a1f`; `4ac4c3d` changes only stress test and workflow. CI links use `https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/<id>`.

| Scope | Environment / run | Result and limit |
|---|---|---|
| Baseline stuck pair | native 46074106020 | controlled old-code fixture 7/7 reproduces failure |
| Fixed dense / no-space / freed ref | native 46075602196 | 16/16; synthetic fixtures |
| 100-seed reservation × 10/20/40 | native 46075602196 | 300/300 synthetic; timing and scope limits in MERGE_DEADLOCK_REPORT |
| Bot gameplay 100 seeds each | native 46074778285 | CI success 60 and 120 Hz; 90 s cap, not full merge stress coverage |
| Real collision normal/golden; contact chain; combo/pause | native 46074755536 | runtime suite success; logs include 12 pair collisions and chain |
| Undo / Remove / Rescue | native 46074781212 / 46074784283 / 46074787260 | CI success; Rescue includes Game Over pending cancellation fixture |
| Save/Load/Continue/Game Over | native 46074790306 | CI success, fixture/process regression |
| Challenge / Achievement | native 46074793141 / 46074796057 | CI success |
| Deadlock + revision + reload | Chromium 46074749255; Firefox 46074752395 | 15/15 each; frozen QA fixture |
| Save integrity | Chromium 46074758542; Firefox 46074761541 | 52/52 each |
| Rescue and physical overflow | both browsers 46074810587 | 24/24 synthetic fixture |
| Rewarded Rescue | Chromium 46074807905 | 68/68 local SDK mock; not real platform |
| Web Audio | Chromium 46074802203; Firefox 46074805118 | 47/47 each; automated, not human audio review |
| Touch | Chromium 46074799017 | 29/29 simulated, not Android |
| Natural Game Over | Chromium 46074813762; Firefox 46074816508 | FAILED at 120 inputs, Game Over not reached; sampled pending empty; cannot certify natural path |

No full native/Web 3- and 4-way collision stress, continuous long-session status correctness, independent verified pair geometry of the earlier natural hang, real Android/touch, human play/visual/audio, or meaningful real-mobile performance. Automated checks do not certify any of those. Prior physics and rights restrictions remain.

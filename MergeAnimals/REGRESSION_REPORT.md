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

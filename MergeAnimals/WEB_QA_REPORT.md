# V0.9.0.2 — Web QA (private test, incomplete)

Tested code `58a04ee` in Godot 4.7.2 Web export, GitHub Ubuntu runners, headed Playwright with software GL. These are automated desktop browser tests, not physical/mobile devices. Links lead to actual CI runs. Read-only IDB timing test uses standard production export; reward tests use a separate instrumented rewarded export, mocked SDK and deliberately tainted deterministic board fixtures. No real ad, platform or network transaction is tested.

| Required case | Chromium | Firefox | Scope / evidence |
|---|---|---|---|
| Normal save, refresh, browser close/reopen | PASS selected Classic scenarios | PASS selected Classic scenarios | [45973032130](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45973032130), 66 total checks; board/score/power-up limits after deliberate settling. Not every separate store. |
| Immediate close | OBSERVATION, last Undo not reflected | OBSERVATION, Undo state reflected | Same run, no wait after click. Chromium restored pre-Undo score 4, one hamster, Undo available; Firefox showed score 0, one mouse, Undo spent. Not an asserted guarantee, nor proof of the loss mechanism; repeated trials/other close timings needed. |
| Undo / Remove | PASS selected actions, refresh and restart | PASS selected actions, refresh and restart | Same run, real tutorial merge; not all natural boards. |
| Rescue | PASS fixture, refresh and restart | PASS fixture, refresh and restart | Same run, tainted board prepared after real merge, not a natural full playthrough. |
| Rewarded Rescue / duplicate | PASS, 68/68 mock checks | PASS, 68/68 mock checks | [45974059487](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45974059487) Chromium; [45974063629](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45974063629) Firefox. Synthetic board and mocked SDK; refresh tested, not browser restart or real ad. |
| Save failure and retry | PASS scoped fixture | PASS scoped fixture | Same mock runs inject local checkpoint file failure, ensure pending reward and retry; no IndexedDB quota/permission/abort fault injected. |
| Corruption / backup recovery | PASS scoped fixture | PASS scoped fixture | Same mock runs corrupt primary and observe reward checkpoint recovery in the running game, not a separate browser-restart corruption test. |
| Rapid consecutive saves | NOT TESTED as a dedicated correctness scenario | NOT TESTED | Timing runs see ordinary repeated writes but do not prove ordering, back-to-back revision persistence or cross-tab behavior. |
| Old-version migration | NOT TESTED on Web | NOT TESTED on Web | Native save/migration tests exist; cannot substitute for Web migration/restart evidence. |
| Observer exact read-back / missing revision | PASS selected | PASS selected | [45973023812](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45973023812), [45973027650](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45973027650); at least one verified tracked entry, synthetic absent entry stayed pending; not a fault/timeout matrix. |
| Audio, language, themes, collection, achievements, challenges after restart | NOT TESTED as a full persistence matrix | NOT TESTED | Separate files are outside the new indicator. |

All 12 native/commercial workflow jobs on `58a04ee` returned success, including the session, Undo, Remove, Rescue, Challenge, Achievement, Theme, Collection, render, Game Feel and runtime suites. Their workflow conclusions do not assert complete human acceptance or Web durability. CI timing evidence ZIPs and browser logs are kept in `artifacts/v0902/`; they are local test evidence, not public-release artifacts. Browser output and detailed checks are inside the linked runs/evidence.

**Acceptance remains incomplete.** In particular, the immediate-close Chromium trial demonstrates the final Undo can be lost; read-back does not guard unwritten actions. No claim is made for abrupt process/power failure, storage eviction or concurrent tabs.

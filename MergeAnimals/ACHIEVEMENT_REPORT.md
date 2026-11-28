# V0.6.5 Achievement update

Achievement data has four-language names/descriptions and the save checkpoint and retry changes described in `SAVE_SYSTEM_REPORT.md`. Regression CI continues to cover the 15 definitions, real collision events, score isolation, migration, recovery and duplicate notification behavior.

A15 is **not fully proven by a fresh 12-discovery run**. The V0.6.5 attempt got the first five distinct species through real Classic drops with test-selected preview tiers on freshly cleared boards. An attempt to force high-tier previews was rejected by the existing snapshot validator (only the first five can naturally spawn), so those are not valid drops and A15 remains locked. The prior 12th-event test used 11 synthetic historical discoveries and is not natural 12-species proof. No fixture animal was counted as a new eligible discovery in the new attempt. Obtaining all 12 through actual chains remains open.

---

# V0.6.4.3-dev — Achievement system (WIP)

Base `c53bdadab92f999a33299de0a90385bab377938f`; tested implementation `0521c61dd9bbabb0fe123fd46a27b0dda8da205a`. [Achievement CI](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916145), [Challenge/achievement event CI](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916710). Test logs in `tests/logs/v0643-*-0521c61.txt`.

## Implementation and policy

Fifteen independent `resources/achievements/A01.tres` through `A15.tres` define ID, title, description, existing SVG icon, objective type, target, default progress, hidden flag and condition parameter. `AchievementManager` scans resources and evaluates supported objective types; adding a definition with an existing objective type requires no gameplay edit. Runtime state is deliberately stored separately from shared Resources. New objective *types* require manager code.

Eligible Classic merges, creations, score, combo and Golden events reuse `Progression` and `MergeManager`. Eligible Challenge drops/merges/combos/goldens are recorded separately in achievement evidence; starting pieces themselves never fire a discovery event. A14 uses completed **distinct** `ChallengeStore` entries, only after result persistence. Score thresholds use Classic best score only. A15 uses the 12 **Classic Collection** discoveries; a genuine Challenge creation may unlock A02–A05 independently without adding to Classic Collection. Merge Master combines Classic lifetime merges and eligible Challenge merges. Previous Challenge merge counts are not reconstructible and are not invented.

Permanent unlocks follow the Collection discovery policy: a legitimate unlock and its known date remain even if Undo rolls back score, counts, and merge statistics; an unlocked progress bar remains complete, while still-locked progress is recalculated from the rolled-back statistics. Remove and Rescue do not create events. Debug/tainted sessions and ineligible fixture-created bodies do not award Classic achievements. Merge eligibility requires both bodies to be eligible; achievement condition code does not treat level startup as a discovery. Fixture code that deliberately alters valid runtime data/eligibility is not a security boundary and tests using controlled queues are identified below.

State lives at `user://wild_garden_achievements.json` with SaveManager checksum, atomic primary and refreshed backup. On first use, validated Classic statistics and Challenge completions seed supported achievements: no historical date is invented and migration generates no notification. The process retains normal save validation and does not overwrite unknown/future or unreadable Achievement state. Classic and Achievement persistence are separate commits, so they are **not an atomic cross-file transaction**; see Known Issues. No rewards are issued. Notifications reuse the existing DiscoveryNotification queue, are mouse-transparent, animated unless reduced effects is enabled, automatically close, and serialize discoveries with achievements.

## Each achievement: observed result

PASS means the stated test passed, not that a human playtest took place. All real results use physical drops/collision events; deterministic fixtures, pre-existing evidence, seeded access and test-selected spawns are explicitly identified. The separate migration test individually checks all 15 against a synthetic legacy-progress fixture and verifies dates are unknown, as a migration test only.

| ID | Condition | Individual evidence |
|---|---|---|
| A01 First Merge | first merge | PASS: fresh Classic, two test-selected mouse drops and natural physical contact; also live Challenge |
| A02 Cat Lover | first Cat | PASS: actual random Cat drop after deterministic seed search; Challenge access seeded |
| A03 Forest Explorer | first Fox | PASS: actual collision, fixed-dog Classic queue; also configured Challenge |
| A04 Panda Friend | first Panda | PASS: actual collision, fixed-dog Classic queue; also configured Challenge |
| A05 Gentle Giant | first Elephant | PASS: actual Challenge 19 Lion collision; access seeded; starter Lion did not unlock it |
| A06 Golden Legend | first Golden | PASS: actual Challenge 20 configured queue, four drops, two elephants merge; access seeded; starting Bear did not unlock it |
| A07 Beginner | Classic best 100 | PASS: actual Classic collisions, fixed-dog queue |
| A08 Rising Star | Classic best 500 | PASS: actual Classic collisions, fixed-dog queue; Challenge score excluded |
| A09 Score Master | Classic best 1000 | PASS: actual Classic collisions, fixed-dog queue; Challenge score excluded |
| A10 High Score Legend | Classic best 2500 | PASS: actual Classic collisions, fixed-dog queue; Challenge score excluded |
| A11 Combo Starter | x3 | PASS: actual Classic collisions / Challenge events; fixed/level-configured queue |
| A12 Combo Champion | x5 | PASS: actual Classic collisions / configured Challenge 17 |
| A13 Merge Master | 100 | PASS: 124 *new* physical merges across four Challenge 17 replays, 31 each; access seeded; no synthetic counter, score, or board deletion |
| A14 Challenge Explorer | 10 different | PASS: sequential persisted completion suite, duplicate replays do not increase distinct count; 01–05 legacy fixture may reposition/clean bodies, 06–10 tests select drop type. Natural additional runs are logged for 01–05 |
| A15 Animal Collector | 12 Classic discoveries | PASS for transition: 11 validated historical fixture discoveries + actual final mouse drop; migration with all 12 fixture discoveries also passes. **Not** a from-scratch 12-animal human/natural playthrough |

The 45-drop Classic fixed-dog run produced 41 merges, best score 2539 and x5. It is deterministic test-selected spawning, not ordinary random-play difficulty evidence. The separate Cat/Elephant/Golden test uses actual queues and configured starter boards; only Challenge access is seeded. Existing test scripts that reposition bodies, mutate test fixtures, or select types are not human play. Physical events and thresholds, not direct score/merge/unlock calls, drive the live tests.

## Interface and evidence

Main Menu → Achievements opens a scrollable forest-styled list with title, icon, description, current/target progress bar, locked/unlocked status and known unlock date, with total `0/15` on a fresh save. Hidden resources hide title and description until unlocked. English copy currently has no achievement-specific translations.

`art_reports/v0643_achievements/full_resolution/` contains 18 full-resolution JPEGs from actual X11 windows at 360×640, 720×1280 and 1366×768: Main Menu, locked screen, unlocked card, progress bar, completed 15/15, and notification. The UI states use **seeded fixture data**, not human play; original PNGs are the CI artifact `achievement-windows`. Desktop uses portrait letterboxing. Thumbnails are also in the parent folder.

Achievement write/recovery, event provenance, power-up interactions and platform limitations are further qualified in `QA_REPORT.md` and `KNOWN_ISSUES.md`. This is not a commercial release or full device acceptance.

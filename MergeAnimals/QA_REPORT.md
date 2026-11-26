# V0.7.0 QA — executed tests and limits

The new production code at `721cb69` was tested on Godot 4.7.2 in Linux Actions. The subsequent corrected music-instance comparison and all 91 game-feel checks passed at [CI 45838054585](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45838054585), commit `eed588d`. Reports and screenshot packaging do not alter production code.

- [Game Feel CI 45837733394](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733394): 91 assertions and one separate-process settings restore, zero failures. All 12 tiers' drop, landing, merge scaling and blink timing checked while collision radius stays unchanged. 20 sound resources were played through dummy audio; limiter, threshold, cooldown, bus/mute values, audio settings and configured loops passed. Two real Classic mouse drops merged once with one score; real floor impact triggered landing audio. Golden Garden used seeded challenge access but real configured board/queue/physical collisions: Golden sound dispatched, no double score/merge, Reduced Effects camera stayed still. Not all 20 audio integration paths were individually observed, and dummy audio is not human listening.
- [Theme/localization 45837733376](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733376): theme 20 + restore 1; four-language 74; save-integrity 14 + restore 2; forced five-drop A15 17, zero failures.
- [Achievement 45837733524](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733524): 35 base, 13 Classic and 16 restore checks, zero failures; real Classic test uses deterministic dog queue. 100-merge and Golden tests pass using disclosed prepared Challenge access/boards.
- [20 Challenges 45837733873](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733873): base 66, phase 2 34, phase 3 15, phase 4 17, and 16 achievement event checks, zero failures; starting boards and deterministic queues are not human play.
- [Undo 45837733358](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733358) 165 + 5/7/3; [Remove 45837733294](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733294) 80 + 26/7; [Rescue 45837733393](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733393) 61 + 3/3/2; all zero failures. [Runtime 45837733613](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733613), [session 45837733281](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733281), and [Collection 45837733736](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45837733736) passed. Runtime's separate release acceptance deliberately remains unmet because the expression assets and sprite rights are unverified.

Three genuine 720×1280 X11 window captures are in `art_reports/v070_game_feel/`; `scripted_merge.mp4` is a five-second silent 360×640 H.264 capture of deterministic gameplay, not a playtest. Screenshot and video capture are from engine-rendered scripted fixtures, not a person. The audio samples were not heard or rated. No real mobile FPS/touch, Web build, power-loss test, actual eye blink, commercial art clearance or full 12-natural-discovery A15 proof was performed. See `KNOWN_ISSUES.md`, `AUDIO_REPORT.md` and `ASSET_LICENSES.md`.

---

# V0.6.5 QA — actual executions

Tested code commit `a534ffb` using Godot 4.7.2 on Linux Actions. The report/screenshot-only packaging commit is newer. No human mobile playtest or platform durability test was performed.

- [Theme/localization/integrity CI 45832641906](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641906): Theme 20/20 + separate-process restore 1/1; localization 74/74; integrity 14/14 + restore 2/2; A15 five legal forced drops 17/17. Three theme × four locale menus and supplementary screens captured at three actual X11 sizes, 72 images in `art_reports/v0650_themes_locales/`. Seeded fixture state for these screenshots.
- [Achievement CI 45832641612](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641612): 35/35, real-physics Classic 13/13 (45 test-selected dog drops, 41 merges, 2539 score, combo 5), 100-merge fixture, Golden/Elephant/Cat real collision and separate-process 16/16. Some Challenge access/boards were prepared, not natural progression.
- [Challenge CI 45832641623](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641623): 66 base + 34 phase 2 + 15 phase 3 + 17 phase 4 assertions passed; 20 distinct completion and 124 real Challenge merges checked with disclosed seeded/prepared boards. Separate-process reads passed. A14 replays do not inflate distinct count. Physical-solvability tests are not human difficulty acceptance.
- [Undo 45832641629](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641629) 165 checks + 5/7/3 persistence; [Remove 45832641876](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641876) 80 + 26/7; [Rescue 45832641643](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641643) 61 + 3/3/2; all zero failures.
- [Runtime 45832641786](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641786), [session 45832641679](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641679), [Collection 45832641687](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641687), and [software render 45832641519](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45832641519) passed.

**Not passed / not completed:** complete fresh 12-species A15 run; cross-file atomicity or crash-exactly-once; full native-language review, all screens/scroll positions, real touch hit targets, safe areas, human play, actual mobile/Web/Windows and power-loss tests. Sample 360 px screenshots show small ~30 px buttons and reduced legibility; icon contrast was improved after the initial capture and retested. Commercial art rights and missing expressions still block release. See `KNOWN_ISSUES.md`.

---

# V0.6.4.3-dev QA — Achievement system (WIP)

Godot 4.7.2 actual Linux CI on code commit `0521c61dd9bbabb0fe123fd46a27b0dda8da205a`:

| Suite | Result and scope |
|---|---|
| [Achievement](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916145) | 35/35 integration, 11/11 Classic event/queue, 4×31 = 124 new actual Challenge physics merges, Cat/Elephant/Golden isolated actual-event tests, separate-process read 16/16; seeded fixtures disclosed in `ACHIEVEMENT_REPORT.md` |
| [Challenge + events](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916710) | baseline 66/66; stages 32/32, 15/15, 17/17; achievement events 16/16; separate-process Challenge restore |
| [Remove](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916192) | PASS; successful Remove leaves achievement file unchanged, plus existing Remove regressions |
| [Rescue](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825917070) | PASS; successful Rescue leaves achievement file unchanged, plus existing Rescue regressions |
| [Undo](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916313) | PASS; Achievement integration additionally verifies actual merge → Undo rolls back statistic but keeps permanent unlock |
| [Classic runtime](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916252), [Collection](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916076), [session](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45825916435) | PASS for this commit |
| Save and notifications | All 15 historical-evidence migrations (unknown dates), primary-corruption backup recovery, no duplicate notice on recovery and Continue, all 15 read in a second Godot process; Animal → Achievement → Achievement queue order and auto-close checked |
| X11 visuals | 18 seeded windows across 360×640, 720×1280 and 1366×768; real-size JPEG captures included, originals in CI artifact; scripted fixtures are not human/device playtests |

**Coverage boundaries:** A15 is tested with 11 historical fixture discoveries and a genuine twelfth drop, not all 12 gained from a fresh natural session. Classic score run deliberately selects dogs. A13 uses Challenge access fixture but 124 new actual drops/contacts across four fresh boards. A14's first 5 use legacy test fixtures and 06–10 fixed test-selected spawns. Migration counters are fixture inputs, not actual lifetime statistics. Debug taint is tested, but arbitrary test code can mutate live variables and is not an adversarial integrity boundary. These results do not establish every crash/interleaving, human difficulty, device touch, responsiveness, FPS or battery.

Separate Achievement and Classic/Challenge commits are not a single atomic transaction. If achievement persistence fails, a live event may not be retained or notified; if backup refresh also fails and the primary is subsequently lost, the backup may be stale and cannot guarantee duplicate prevention. Filesystem power-loss/fsync, concurrent writers and platform-specific persistence have not been demonstrated. Commercial sprite provenance/rights, 24 missing expression sprites, prior physics overlap risks, and Web/mobile performance limitations remain. The pre-existing Golden Garden human difficulty gap remains open. This is WIP, not release approval.

---
## Previous QA history
# V0.6.4.2-dev QA — WIP

Godot 4.7.2 Linux CI on code commit `9dde09e45073de38fa3f52095235dcb4bb73c61a`; exact log `tests/logs/v0642-challenge-9dde09e.txt` and [Challenge CI](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45806711856). The separate phase runs were actually performed: [Phase 2](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45805038011), [Phase 3](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45805411014), [Phase 4 final](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45805847192). Earlier failed runs and fixes are visible in CI history.

| Check | Actual result / boundary |
|---|---|
| Phase 1 regression | 66/66; natural 01 plus untouched-board 02–05; fixed test-selected spawns; 01 danger disabled |
| Phase 2 / 3 / 4 | 32/32, 15/15, 17/17; 06–10 test-selected spawns, 11–20 level-configured spawns |
| Timer, pause, limit | 60 s expiry; pause timer; 21st drop refused; blocked attempt consumes no drop; failure waits for settle; controlled final drop wins through real contact |
| Combo, golden | real x3 and x5, real Golden event |
| Success/failure conflict | overflow signal injected when 06's real objective reached; success retained. Synthetic signal, not every possible timing/interleaving |
| Result exactly once / retry | obstructed result write, retry commit, attempts checked; no proof against all crash/concurrency conditions |
| Replay / restart / unlock | fresh replay, restart warning/restart, next unlock, failed replay retains previous completion; UI warning captured |
| Restore/migration | v1 5-entry migration 3/3; separate process 01–05 9/9, 01–10 11/11 and 01–20 38/38 including 06–20 best times; backup recovery |
| Classic | known Classic session and power-up checkpoint hashes byte-identical after challenges, score and best reloaded. Collection/statistics bytes preserved, not exhaustive interactive verification of each entry |
| Power-ups | 01–05 actions directly blocked; 06–20 controls hidden (not exhaustive direct action attempts for all 15) |
| X11 | original 5 seeded screenshots plus 11 each 720×1280 and 1280×720. Selection, all four categories, timer, limited, golden, exit warning, success/failure. Success uses real Koala collision; failure screen injects overflow signal. Screenshots in `art_reports/v0642_challenge`; repository images are reduced-size JPEG check-run thumbnails, CI has original PNG artifacts. Desktop is portrait letterboxed |

The collection, runtime, Remove, Undo and Rescue workflows for the tested code succeeded; see CI history. X11, simulated signals and fixed FPS do not establish real touch, screen safe areas, battery, long sessions, all locales or cross-platform compatibility. Release remains blocked by unverified commercial art rights and missing expression assets. Golden challenge difficulty and human balance remain unvalidated. Prior detailed QA remains below as history.

---
## Historical QA
# V0.6.4.1 DEV — Challenge Mode faktiki yoxlama

[Challenge Godot 4.7.2 CI 45764793009](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764793009), `c92e292`: **65/65** integration və başqa Godot prosesində **9/9**, həmçinin real physics gravity/contact ilə toxunulmamış lövhədə 02–05-in 4/4 ssenarisi PASS. Birinci Challenge üçün iki drop-la təbii collision ayrıca PASS. Düşəcək heyvan növbəsi testlərdə deterministik seçilib; tətbiqin normal RNG-si bu testlərdə emal edilən bütün növbəni seçmir. Integration-ın digər ssenarilərində təkrarlanabilir təmas üçün body-lər fixture tərəfindən yerləşdirilir və arada lövhə təmizlənir. Heç bir məqsəd testdən SUCCESS və ya merge funksiyası çağırılaraq tamamlanmayıb. Failed testi overflow siqnalını simulyasiya edir. Tam metod və nəticələr `CHALLENGE_REPORT.md`; faktiki log `tests/logs/v0641-challenge-c92e292.txt`.

Eyni run-da beş faktiki X11 720×1280 scripted pəncərə screenshot-u çəkildi; tam PNG Actions artifact-də, JPEG nüsxələr `art_reports/v0641_challenge/`-dədir. İnsan oyunu və mobil hardware deyil. Save retry, primary corruption backup, ayrı proses, classic save/rekord izolyasiyası, unlock, replay və restart yoxlanıb.

Əlavə olaraq `c92e292` [runtime 45764792995](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764792995), [Undo 45764792986](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764792986), [session 45764792980](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764792980) və [collection 45764793040](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764793040) PASS.

Eyni gameplay kodu ilə `a032c07` [runtime regression 45764021969](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764021969), [Undo 45764021901](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764021901), [Remove 45764021905](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764021905), [session 45764021879](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764021879), [collection 45764021919](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764021919) və [software render 45764021934](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764021934) PASS. Sonrakı commitlər testləri genişləndirib, gameplay kodunu dəyişməyib. Release acceptance əvvəlki kimi ödənmir; hüquqlar, 9.190 px fizika nüfuzu və mobil/Web riskləri qalır.

---

# V0.6.3.3 DEV — Rescue executed evidence

Code/tests at `d0b3f07d10d2c3f31650722512bda71ca339995b`: [Godot 4.7.2 Rescue integration and X11, 45762175148](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175148) PASS: **60/60** assertions, including **30 independent fixture Rescue operations** (not human games); separate write/read/verify Godot processes **3/3, 3/3, 2/2**. The read process restores pending Game Over and performs Rescue; the third process restores the committed rescued board. The tests exercise no-use outside Game Over, pending merge cancellation, actual DangerMonitor overflow signal with fixture-supported body, cap and blocked-spawn failure, checkpoint obstruction, failed ordinary mirror plus corrupt primary, score/progression/queue/RNG and limits, danger reset, tombstone and repeat finalization. The spawn query was checked using the real physics space. `tests/logs/v0633-rescue-d0b3f07.txt` is the actual diagnostic log.

Six real 720×1280 Xvfb/X11 Godot window captures (game over, button, before, highlight, after, used) are Actions artifacts at the same run; reduced JPEG inspection copies are in `art_reports/v0633_rescue/`. Actual viewport GUI input uses synthetic mouse and synthetic touch; it is neither physical-device touch nor a human playtest. The fixture directly positions/freezes animals, and the stress loop creates new nonpersistent fixture games; do not infer production balancing or mobile performance from these tests.

At `d0b3f07`, [runtime regression 45762175172](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175172), [Undo 45762175112](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175112), [Remove 45762175131](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175131), [session 45762175183](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175183), and [collection 45762175118](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175118) passed. The separate [software render run 45762175146](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45762175146) was still in progress when this report was written. Release acceptance remains **NOT MET** (24 missing expression sprites and unresolved commercial rights). Existing 9.190 px 120-Hz physical overlap, sprite halo/Bear silhouette, physical mobile touch/FPS/RAM and Web compatibility risks remain unverified. See `KNOWN_ISSUES.md`.

---
# QA hesabatı — V0.3.0-dev

## Faktiki icra
Baza `ebd434c` [45664927879](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45664927879): rəsmi Godot 4.7.2.stable Linux headless, 49/49, bütün addımlar exit 0. Gün 3 `fbcb4ca` [45665893612](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45665893612): əvvəlki **49/49**, yeni **57/57**; real 11 evolution və iki Elephant Golden collision, 100 seeded bot və physics matrix işlədi. Xam nəticə `tests/logs/v030-runtime-fbcb4ca.txt`.

Köhnə 49 test eyni check-ləri saxlayır; əvvəlki base-score müqayisələri üçün fixture-də `combo_enabled=false` seçilib. Yeni suite default açıq combo-nu ayrıca yoxlayır. 49+57 mənalı assertion minimum 79-u keçir; bu say GUI və cihaz yoxlamaları deyil. Run 45666836718: köhnə 49/49, yeni 61/61; əlavə nonzero high-tier ağırlıq və golden dublikat/resource testləri keçdi. `day3_suite.gd` həm real collision, həm də birbaşa metod/resource yoxlamaları ehtiva edir. Spawn 10000 (seed 13579), Golden duplicate pair lock, combo və timeout yoxlamaları logdadır.

100 bot normal game logic/physics işlədir, lakin proqram strategiyaları real insan davranışı deyil; time-cap, oyun sonu, seed və göstəricilər CSV-dədir. Debug stress və 100-drop digər fixture-ləri merge/danger söndürür və ya test body-lərini təmizləyir; normal oyun onları silmir.

## Əhatə boşluqları
Real telefon touch, Windows BAT, GUI/F5, vizual screenshot, 6 ekran ölçüsündə real render/input, kiçik ekran guide oxunaqlılığı, Web export və mobil FPS/RAM yoxlanmayıb. 512×512 alpha konsept törəmələri var, lakin təmizləmə/qrafik keyfiyyəti və yekun sprite-lar təsdiqlənməyib. Uzunmüddətli insan balansı və riskli çox sıx merge halları təsdiqlənməyib. 60 Hz normal bot oyunlarında 16.678 px, 120 Hz-də 9.190 px-ə qədər floor/boundary overlap, stressdə ayrıca nüfuz qalır; `PHYSICS_REPORT.md`.

## Təhvil statusu
Bu DEV namizədidir, mobil və vizual qəbul yekun deyil. Hər problem və regression xəritəsi `ROOT_CAUSE_REPORT.md`-də, bot metodologiyası `BALANCE_REPORT.md`-dədir.

120 Hz test run 45668965282: köhnə 49/49 və yeni 61/61, 100 bot işləsə də 100-drop fixture 99/99 ilə FAIL idi. Sabit 60 Hz frame fərziyyəsi aradan qaldırılıb; sonrakı [45670121999](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45670121999) run-da 100/100 PASS, köhnə 49 və yeni 61 yoxlama da PASS oldu. Mobil 120 Hz CPU/batareya testi yoxdur.

## V0.4.1 DEV regression
[45681741743](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45681741743), `8eefda7`: Day2 49/0, Day3 61/0, genişləndirilmiş Day4 DEV 64/0 (əvvəlki 56 və Bear/Lion əlavə yoxlamaları), yeni UI 53/0. 20 ikon və 8×4 StyleBox resurs import/varlıq assertion-ları və HUD theme bağlantısı işləyib; test gözlə vizual keyfiyyətə zəmanət deyil. Başqa real collision/input/restart/bot testləri logdadır. Ayrı release acceptance testi missing expression və hüquqlar səbəbindən FAIL gözlənilir. 18 X11 tam pəncərə capture [45682785944](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45682785944); məhdudiyyətlər və vizual nəticə `VISUAL_QA_REPORT.md`-dədir. Yoxlamalar insan/mobile/Web playtest deyil.

Ayrı release acceptance addımı [45682747980](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45682747980) run-da müvəffəqiyyət kimi təqdim edilmir: nəticə gözlənildiyi kimi release-ə hazır olmadığını xəbərdarlıqla göstərir. 24 expression və kommersiya statusu blokludur. DEV regression workflow yaşıl olması release acceptance PASS demək deyil.

## V0.5.0 DEV
V0.4.1 baseline was rerun at [45686946595](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45686946595): 227 DEV checks passed, 25 release items missing/blocked. Initial Day5 regression `bfe85e0` [45690151768](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45690151768) passed previous checks plus 20 state-transition, 6 GUI input, 9 effect and 5 tutorial tests, including natural collision. Later locale-test parse failure at `99410c9` [45690522612](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45690522612) was fixed, but this historical red run is not a PASS. Latest head CI must be checked separately. UI visual evidence, limitations and issue mapping are in `UI_QA_REPORT.md`.

Latest tested code `ee9d33c`: [runtime 45690860555](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45690860555) **227/227** old and **53/53** Day5 checks; separate release acceptance still **25 missing/blocked**. [render 45690860630](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45690860630) captured 36 X11 windows. Raw logs `tests/logs/v050-runtime-ee9d33c.txt` and `v050-render-ee9d33c.txt`.

## V0.6.2 DEV — Collection & Statistics
- Baseline V0.6.1 rerun [45711646672](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45711646672) passed before implementation.
- At `1d31b52`, [runtime 45713935132](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45713935132) passed the 280 DEV checks, 217 save primitive checks, the expanded 60 two-process checks (previously 57), and 52 new collection/statistics checks. The old menu assertion now expects Collection enabled, and the future-session sentinel moved from version 2 to version 3 because version 2 is now current; remaining prior checks are retained. Raw log: `tests/logs/v062-runtime-1d31b52.txt`.
- [Collection X11 CI 45713935279](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45713935279) ran the 52 gameplay checks and captured 21 actual X11 windows across seven scripted fixture screens and three sizes. JPEG inspection copies in `art_reports/v062_ui/`; original PNGs are CI artifacts. Fixture statistics are seeded, not human gameplay. `tests/logs/v062-x11-1d31b52.txt` contains the actual run log.
- [Two-process Continue CI 45713935056](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45713935056) passed with added per-animal/date/stat restoration checks. Existing separate release acceptance remains blocked by missing facial states and licensing. Real mobile, user playthrough, power failure and Windows/Web are not tested.

## V0.6.3.1 DEV — Remove (real Godot 4.7.2)

At `a21e09a`, [Remove run 45757629043](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45757629043) passed 79/79 integration assertions (including 50 test-only allowance resets/removals, 25 of them moving physics bodies), 25/25 in the write process and 7/7 in the separate read process. Assertions cover selection/cancel, invalid/locked/pending/preview/external/queued bodies, unchanged score/merge/collection and notification, corrupt-save rejection, committed snapshot and backup, recovery, legacy v2 Continue/migration, actual menu Continue, further dropping and restart. Selection input is tested with mouse and simulated touch. A synthetic mouse click traverses the actual X11 Godot viewport and GUI without initiating a drop; simulated touch selects through that viewport.

Five actual X11/Xvfb 720×1280 PNG window captures (button, before, selection, after, used) are in the Actions artifact; `art_reports/v0631_remove/` has reduced JPEG copies. Seeded fixture objects and programmatic inputs are not human gameplay. Full mobile device testing, disk-full/power-loss and multi-writer testing remain open.

[Runtime regression 45757629099](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45757629099) and [two-process existing session regression 45757629314](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45757629314) passed at the same code. Separate release acceptance still reports missing states and unverified licensing. Render workflow [45757629058](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45757629058) failed in its thumbnail publishing step on its first attempt; no cause is asserted from unavailable Actions logs. Previous identical gameplay-code render at [45757482167](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45757482167) passed.

## V0.6.3.2 DEV — Undo and integrity

At `a40def8`, [Undo run 45760082968](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082968) passed **161/161** assertions, including **100** test-only reset-and-Undo iterations; process phases were **5/5**, **7/7**, **3/3** in three separate Godot processes. It covers normal/last drop, blocked spawn, actual contact merges (the second chain contact is fixture-positioned/accelerated), actual Golden contact, body IDs/transforms/velocities/danger, RNG/queue/combo/cooldown, tutorial and Golden presentation, counts/discoveries/best, pause/Continue, Remove interaction, primary corruption and checkpoint/mirror write obstructions. The write-obstruction tests are filesystem-path faults, not real disk-full or power-off. The stress fixture resets the limit only in test code.

Eight actual X11/Xvfb captures at 720×1280 and simulated viewport mouse/touch were generated. PNGs: Actions artifact. JPEGs: `art_reports/v0632_undo/`. The visual chain uses explicit manager requests, unlike the physics contact integration test. These fixtures are not human play. Raw diagnostic logs: `tests/logs/v0632-undo-a40def8.txt`, `v0632-remove-a40def8.txt`, `v0632-runtime-a40def8.txt`.

[Remove regression 45760082996](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082996) passed 79/79, plus 25/25 write and 7/7 read assertions. [Runtime 45760082958](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082958) passed prior 280 gameplay/UI, 217 save primitive, 60 session and 52 collection checks, and 10 reward gateway checks. Migration assertions now expect schema 3 and future-schema sentinel 4; corruption test covers all three copies. [Two-process session 45760083010](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760083010) and [collection/X11 45760082966](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45760082966) passed. Separate release acceptance still reports missing facial states and unverified licensing. Physical touch devices, human play, power loss, concurrent writes and mobile performance are not validated.

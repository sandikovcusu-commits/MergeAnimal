# V0.6.4.3-dev — Achievements (WIP)

- Added 15 data resources, AchievementManager, scrollable menu screen, persistent unlock/progress/date storage and queued nonblocking discovery/achievement notices.
- Evaluates validated Classic/Challenge evidence, migrates existing statistics without fabricating historical dates, preserves permanent unlocks through Undo, and keeps score thresholds Classic-only.
- Added live collision, 100-merge, Golden, score, combo, power-up isolation, migration/recovery/Continue and three-resolution X11 fixtures. Scope and limitations are recorded in `ACHIEVEMENT_REPORT.md` and `QA_REPORT.md`.
- No new Challenge, animal, sprite, gameplay mechanics, ad SDK or physics tuning; release remains blocked by existing asset rights and platform risks.

# V0.6.4.2-dev — Challenge expansion (WIP)

- Extended five existing challenges to 20 with difficulty categories, time/drop/combo/golden objectives, configured advanced boards/queues, independent score and time records, v1 save migration, and explicit unsaved-attempt exit/restart warning.
- Added staged real Godot tests, last-drop/conflict/save coverage, separate-process restore, 22 mobile/desktop X11 fixtures and reports. Deterministic/test-selected spawns are disclosed; Golden Garden's requested difficulty and human/device balance remain unverified.
- No new assets, achievement, advertising SDK, physics retuning or active Challenge continue. Commercial release remains blocked.

# V0.6.4.1-dev — Challenge Mode, Phase 1

- Added five resource-defined challenges, selection with sequential unlock, objective/time HUD, success/failure, replay/restart and separate per-challenge result storage. Classic session and best are isolated; Classic power-ups are disabled in Challenge.
- Added actual Godot drop/physics-collision tests, untouched-board gravity fixtures, separate-process persistence/recovery, regression coverage and five real X11 window captures. Queue selection in fixtures is controlled; no human/device playtest is claimed.

# V0.6.3.3-dev — Classic Rescue

- Added recoverable pending Game Over, one Classic Rescue, deterministic conservative selection, spawn preflight, pause/processing/used/failure states, existing procedural effect and transactional checkpoint. Finalization counts a completed game once and commits a tombstone.
- Added Godot Rescue integration, 30 scripted stress cases, three distinct processes, actual X11 window captures and synthetic mouse/touch tests. See QA and save reports for evidence and limits; no SDK or new art.

# V0.6.3.2-dev — Undo and save integrity

- Added one Classic Undo with non-recursive pre-drop snapshots, stable board IDs, safe paused/deferred restore and existing SVG HUD states. Remove invalidates the prior Undo boundary and its usage is never refunded by Undo.
- Rolled-back creation/merge/Golden counts, score/combo and best travel with the snapshot; discovery dates remain permanent to suppress repeat notifications. V3 progression is authoritative over the legacy best-score file.
- Added monotonic generations and a full atomic power-up/tombstone commit checkpoint before ordinary mirrors. Legacy v1/v2 sessions migrate; corrupt journal fails closed. Disk and concurrency limits remain documented.
- Added actual Godot normal, chain/Golden contact, save-failure, three-process, 100-Undo fixture and X11 tests. No Rescue, Challenge, Achievement, new sprites or ad SDK.

# V0.6.3.1-dev — Classic Remove

- Added an existing-SVG Remove button, selection rings, Cancel, one free use per session, disabled state and mouse/touch handling.
- Safely commit the removed body and remaining balance together in the existing validated session snapshot; legacy sessions receive one use. Refuse incomplete merge or save failures; refresh backup after commit.
- Added Godot integration, 50-operation fixture stress, two-process Continue/restart, GUI input and five X11 seeded fixture captures. No Undo, Rescue, Challenge, Achievement or ad SDK added. Commercial art rights and prior physics/device risks remain unresolved.

# V0.5.0-dev — Day 5 WIP, release blocked

- Functional Main Menu → Play, pause/resume/settings/restart/main-menu and game-over navigation; collection/challenge visibly disabled.
- Persistent volume/mute/reduced-effects/language settings and AudioBus scaffolding; basic first-run, skip and replay tutorial with real matching-pair collision test.
- Two-row evolution guide, six procedural effects with reduced-effects option, new-record highlight, subset of icons and keyboard focus styles.
- Real X11 fixtures for gameplay and five implemented UI screens plus effects. 24 expression states, blink, standalone logo, two future-mode screens, complete locale coverage, audio, full motion set and verified commercial rights are still missing. `UI_QA_REPORT.md`.

# V0.4.1-dev — Graphics completion WIP, release bloklu

- Bear/Lion 512² RGBA normal sprite, AnimalData bağlantısı və 12 fərdi collision overlay; kommersiya mənşəyi məlum deyil.
- 20 orijinal kod SVG ikonu, 8 native Theme/StyleBox palitrası; Forest tema HUD düymələrində istifadə edilir.
- 24 expression, blink, effekt və logo hələ yoxdur. Capture testlərində yaşıl status yalnız fayl/ölçü/skript şərtidir; vizual baxış ayrıca tələb olunur.
- Əvvəlki gameplay saxlanılıb, fizika parametrləri dəyişməyib.

# V0.4.0-dev — DAY 4 WIP, RELEASE BLOKLU

- 10 eksperimental, kommersiya mənşəyi təsdiqlənməmiş sprite, üç kodla yazılmış tema, alpha və collision hesabatları, ortaq preview/body inteqrasiyası.
- Bear/Lion, 24 expression, ikon/düymə/effekt/logo və tam hüquq auditi çatışmır. Bu mərhələ tamamlanmayıb və kommersiya buraxılışına hazır deyil.
- Xvfb real viewport fixture və script error nəzarəti əlavə edilib; 49+61 əvvəlki və 56 DEV yoxlama 0227408-də keçib. Tam pəncərə, digər temalar, mobil/Web yoxlanmayıb. `V040_DEV_STATUS.md`-ə baxın.

# Changelog

## 0.3.0-dev — 2026-11-25 (Gün 3)
- 12 editable AnimalData və ID ilə evolution; ilk beş üçün 30/25/20/15/10 çəkili RNG.
- 1 saniyə combo, konfiqurasiya edilən Golden Merge bonusu, alt evolution guide; real collision üzrə 11 keçid və fil cütü üçün headless regression.
- 100 seed-li bot sessiyası və CCD/divar/radius/tick/material matrisi; nüfuz qalır, risk ayrıca sənədləşdirilir.
- Üç AI üslub konsepti: orijinalda opaque damalı fon; 512×512 alpha törəmələr avtomatik təmizlənib, faktiki model ID və kommersiya şərtləri təsdiqlənməyib; yekun sprite deyil.

## 0.2.1-dev — 2026-11-25
- V0.2 blocked-spawn quick-tap input bərpası düzəldildi; red/green Godot runtime regression əlavə edildi.
- 18 V0.1 screenshot ayrıca audit edildi; original JPG-lər paylaşılmadı.
- Headless Godot 4.7.2 Actions, fizika, multitouch və restart fixture-ları, Windows üçün işə salma skriptləri əlavə edildi. Windows və cihazlar yoxlanmayıb.
- Divar testi 700 px/s zərbədə müvəqqəti nüfuz ölçür, limitasiya açıq saxlanır; yekun sprite və mobil ölçülər yoxdur.

## 0.2.0-dev — 2026-11-25 (Gün 2, UNVERIFIED)
- Mənbədə beş heyvan səviyyəsi, `MergeManager`, merge lock/deferred commit, xal və sadə best score əlavə edildi.
- Cari/next preview vizual kodu birləşdirildi; spawn state, overlap sorğusu, cooldown və input ləğvi əlavə edildi.
- Dəstək/sürət/grace əsasında danger monitor, game-over, pause/restart HUD və debug panel üçün kod əlavə edildi.
- Statik testlər və icra edilməmiş Godot integration/stress fixture-ları əlavə edildi. Mühərrik və görüntülər əlçatan deyil; funksional və fizika qəbul meyarları **UNVERIFIED**.

## 0.1.0 — 2026-11-25 (Gün 1, prototip)
- Rəqib səhifələri araşdırması, GDD, art bible və arxitektura planı.
- Godot 4 Compatibility layihəsi, portret əsas səhnə, üç diaqnostik heyvan, fizikalı düşürmə və divarlar üçün mənbə.


## Day 6 work in progress — not V0.6.0 completion
- Exclude historical test logs/CSV from Godot resource importing after an intermittent editor-import crash; cause not conclusively proven.
- Add isolated, experimental versioned JSON/backup save primitive, legacy read seed and CI tests; no gameplay integration or completed migration. Earlier failed test log retained. See `SAVE_SYSTEM_REPORT.md`.
- Requested gameplay progression, challenge system, power-ups and associated acceptance remain outstanding; existing AI art rights blockers remain.

## V0.6.1-dev — Classic Save / Continue
- Added validated, versioned Classic session autosave and menu Continue; physical bodies, score/combo, spawn queue and RNG are restored.
- Refuse incomplete merges, preserve/recover a prior backup, protect future schemas, and invalidate finished sessions. New-game replacement requires confirmation.
- Added two-process real-physics integration and X11 captures; platform and durability limits are documented in `SAVE_SYSTEM_REPORT.md`.

## V0.6.2-dev — Animal Collection & Statistics
- Added 12 local collection cards, scrollable details, progress and queued nonblocking discovery notifications using existing sprites and icons.
- Added actual Classic-game statistics and integrated both systems with session-version-2 transactional snapshots and V0.6.1 migration. Prior unknown counts are not fabricated; debug and unverified legacy body creation are excluded.
- Added Godot gameplay, cross-process, recovery and four-locale layout tests, plus 21 X11 fixture captures. No Challenge, Achievement, Undo, Remove or Rescue implementation.

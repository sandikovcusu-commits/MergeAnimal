# V0.9.0.4 — visual checkpoint (incomplete)

## V0.9.0.4 — davam checkpoint (final deyil)
- Mövcud 12 vektor personaja məhdud növ detalları və adlandırılmış mənbə qrupları; 12 real native əvvəl/sonra fixture.
- Bir pausable kosmetik scheduler və Reduced Effects unregister; terminal golden merge üçün collision-suz texture echo.
- Collection, Statistics, Challenges və Achievements-də ortaq panel/kart tokenləri.
- Eyni-runner 10/20/40 A/B/A testləri; 40-body nəticəsi dəyişkəndir, >5% fərq hələ açıqdır. Kommersiya BLOCKED.

- 12 animal facial-frame dəsti, gözə aid blink, Happy/Surprise və yumşaq action tween; locked Collection art kontrastı.
- Bu tam redesign, full UI/VFX/theme polish və ya final acceptance deyil. Bax: `V0904_CHECKPOINT.md`.

---

# V0.9.0.3 — physics investigation (private, incomplete)

- 100-seed native müqayisə, 12 drop və 10/20/40 pile fixture-ları, test-only CCD/bounds eksperimentləri və Web FPS benchmarkları əlavə edildi.
- 12 statik collision overlay və instrumentli natural click debug görüntüsü əlavə edildi. Production fizika və sprite dəyişməyib; 1–2 px hədəfi ödənmir.

---

# V0.9.0.2.1 — save integrity private test

- Əsas session ilə yanaşı settings/audio/language, theme, challenge və achievement save faylları üçün exact IDB read-back müşahidəsi; lokal xəta və əlçatmaz storage göstəriciləri, Challenge üçün vaxtından əvvəl «Saved» düzəlişi.
- 10/50/100 ardıcıl Web stress, süni xəta/abort/gecikmə sınaqları və əvvəlki layihə tərəfindən yaradılan/captured save-lərin Web bərpası əlavə edildi. Əsl paralel yazı, real quota və bütün data migrasiya halları açıqdır.
- Kommersiya hüquqları BLOCKED; ani bağlanma üçün zəmanət yoxdur.

---

# V0.9.0.2 — save investigation (WIP, private test only)

- Added read-only IndexedDB read-back of exact Classic session and power-up checkpoint bytes with pending/verified/unconfirmed HUD status; no concurrent sync call and no game mechanics or asset changes.
- Added a Web probe for a verified checkpoint and a nonexistent revision; researched Godot 4.7.2 deferred sync and documented outstanding gaps. This does not guarantee last-action or reward durability.
- Commercial rights remain BLOCKED; V0.9.0.2 acceptance is incomplete.

---

# V0.9.0.1.1 — commercial evidence and clean test packages

- Audited public Arena Terms §§1, 3.2–3.5 and 5; ownership language does not remove the unresolved commercial-use restrictions. Added user steps and primary evidence; status remains BLOCKED.
- Byte-regenerated 12 SVG/PNG pairs, 20 icons, 23 audio files and logo; audited runtime SVG links and bundled complete font and Godot logo license notices. No new graphics or gameplay changes.
- Moved historical visual bytes into private research-only archive, preserved Git history, and added historical hash and PCK texture gates for clean test packages.

---

# V0.9.0.1 — commercial asset audit (work in progress)

- Replaced 12 previous image-generated runtime animal PNGs with newly authored editable vector designs and rendered PNGs; kept animal IDs, sizes, collision radii and existing game logic. Legal rights are not yet established.
- Preserved legacy provenance separately; added file-level audit and third-party notices. Reproduced 20 effects and 3 music tracks from mathematical synthesis without external samples.
- Native and selected Web CI against the revised assets passed; further runs, full visual review and rights verification remain pending. No commercial release, merge, gameplay mechanic or ad-type change.

---

# V0.8.3 — Web performance optimization

- Üç kiçik heyvanın importu 256², orijinal PNG-lər dəyişmədən saxlanır; artıq istifadə olunmayan export resursları və benchmark translation artifaktları çıxarılır.
- Spawn-clear shape/query reuse, dəyişməz Undo UI setterlərinin qarşısı və Reduced Effects üçün idle-animation polling əvəzinə settings siqnalı. Fizika tezliyi, radiuslar, gameplay və reklam növləri dəyişdirilməyib.
- 60 s × 3 interval browser benchmarkları, gzip/PCK auditi, CPU/RSS və IndexedDB müşahidələri, 100-seed fizik müqayisəsi və seçilmiş regressiyalar. Cihaz/runner, platforma, vizual və durability məhdudiyyətləri hesabatlarda açıqdır.

---

# V0.8.2.1 — CrazyGames Rewarded Rescue

- Full-launch üçün ayrıca opt-in rewarded preset; standart və Basic konfiqurasiyası reklamsızdır.
- Game Over-da bir könüllü əlavə Rescue, sessiya/transaction callback qorunması, timeout, audio/input/physics pause və save checkpoint/retry; dörd dil.
- Chromium/Firefox official localhost demo, mock callback və audio qrafiki, fallback və seçilmiş reqressiyalar; real platforma BLOCKED. Əlavə Undo/Remove, banner və midgame ads yoxdur.

---

# V0.8.2 WIP — CrazyGames SDK hazırlığı

- Rəsmi MIT Godot SDK, ayrıca opt-in Web preset, sonlu initialization və reklamsız fallback; gameplay start/stop və platform mute inteqrasiyası.
- Rəsmi SDK local demo, skript bloklanması və mute üçün Chromium/Firefox CI smoke.
- Reklam/reward provider-i və mükafatlar hələ yoxdur; bütün reklam düymələri bağlıdır. `SDK_INTEGRATION_REPORT.md` və `MONETIZATION_REPORT.md`-yə baxın.

---

# V0.8.1.3 development — Web audio compatibility

- Use stream playback on Web for the existing bounded SFX pool and singleton music; preserve the existing 20 SFX and three music WAVs.
- Add non-SDK ad suspend/restore hook and cancellation-safe touch handling for audio sliders.
- Add real Chromium/Firefox WASM graph-measured audio CI, including separate uninstrumented production-export smoke; document fixture and real-device limits in `WEB_AUDIO_REPORT.md`. No new gameplay, sprites, physics tuning or SDK.

---

# V0.8.1.2 development — Web touch and partial UI QA

- Prevent Web DOM touchcancel from being treated as a successful gameplay drop in Godot 4.7.2; clear held aim on window resize.
- Add dispatchable release-Web Playwright UI, viewport and Chromium CDP touch probes with screenshots, OCR and logs. Fixes passed the limited simulated-touch regression; broader requested Web/mobile acceptance remains incomplete. See the Web reports and known issues.
- No SDK integration, audio changes, new sprites, mechanics or physics tuning.

---

# V0.7.0 development — animation, audio and game feel

- Add reusable visual-only idle, staggered blink cues, drop/landing and merge squash; no physics-size or impulse changes. Blink is not an actual eye animation.
- Add bounded merge/golden/combo effects, floating score, reduced-effects camera suppression and lightweight UI fades/button feedback.
- Add central bounded audio pool, 20 procedural WAV cues, three synthesized looping WAV themes, audio buses and gesture-gated playback; persist audio settings via SaveManager with legacy settings migration.
- Add generated DejaVu-based original SVG wordmark. Existing AI sprite rights remain unverified; see licensing and reports.
- Add Godot game-feel, Golden collision, settings restart and scripted X11 coverage. Human listening, mobile performance and commercial release acceptance remain outstanding.

---

# V0.6.5 (development)

- Add Forest, Classic-score-unlocked Sunset and ten-distinct-Challenge-unlocked Snow theme selection, persistent selection and live visual application.
- Translate Achievement names/descriptions and remaining gameplay animal labels into English, Azerbaijani, Turkish and Russian; add bundled DejaVu Sans glyph coverage and live language refresh.
- Add monotonic Achievement checkpoint, mirror recovery, ordered retry/pause on failed writes, and tests for failure/reconciliation. Cross-file crash atomicity remains incomplete.
- Add theme/localization/integrity Godot CI and X11 capture fixtures. A fresh A15 12-discovery proof remains incomplete; see reports. No new gameplay mechanics or physics tuning.

---

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

## V0.8.0 — aralıq Web mərhələsi A (natamam)
- Single-threaded Web export preset, export resource listing düzəlişi və əl ilə başladılan Playwright/CI sınağı əlavə edildi.
- Godot 4.7.2 ilə faktiki Web build və məhdud Chromium/Firefox render, iki drop/merge və refresh/reopen müşahidələri: `WEB_QA_REPORT.md`.
- A-nın bütün qəbul sınaqları bitməyib; B SDK və C optimizasiya başlamayıb. Kommersiya və public release təsdiqi yoxdur.

## V0.8.1.1 — Web power-up və save sınaqları
- Faktiki release WASM-da ayrı Chromium/Firefox profil ssenariləri: Undo, Remove, hazırlanmış təhlükə lövhəsi üzərində real Game Over/Rescue, refresh və tam reopen; nəticə və məhdudiyyətlər `WEB_POWERUP_REPORT.md`.
- Test harness cache HTTP 304 və context cleanup işləməsini düzəldir; user:// yazısının Web IndexedDB-də dərhal davamlı olması barədə yanlış kod comment-ləri dəqiqləşdirilib. Qəfil bağlanma riskinə zəmanətli həll tətbiq edilməyib.

## V0.8.1.2.1 — Web UI and touch QA (partial)
- Preserve text resources in Web exports, use a multilingual theme font, constrain localized Restart, and enable touch scroll in menu lists.
- Prevent canceled GUI and Remove selection touches from committing. Preserve the previous drop cancellation/resize safeguards.
- Add browser locale/theme/viewport, challenge outcome, Game Over/Rescue and touch probes. Real device, full visual/translation matrix and tab-switch acceptance remain open; see Web UI and touch reports.

## V0.8.1.2 — Web UI / touch davamı
- Tutorial paneli Undo/Remove və spawn preview üzərindən ayrıldı; uzun tərcümələr sətirə bölünür.
- Faktiki Web Continue, Restart, Pause, Tutorial, touch x-mövqeyi və dörd dildə tutorial viewport sınaqları əlavə edildi. Tam vizual/real-device qəbul hələ açıqdır.

## V0.9.0.4 — final acceptance işi, partial checkpoint
- Settings, Theme Selection, Pause, Game Over/Rescue, Tutorial və Challenge outcome mövcud shared visual tokenlərə uyğunlaşdırıldı (`95bf1d9`).
- Game Over screenshot-da müşahidə olunan mətn/düymə toqquşması üçün dinamik result layout və dörd dil yoxlaması əlavə edildi (`3dadc19`); tam vizual qəbul hələ verilməyib.
- Yalnız CI test fixture-lərində eyni-runner component isolation və mobil Pause OCR ölçüsü üzərində iş başladı (`1a19fa4`, `451210d`). Physics/gameplay balansı dəyişdirilmədi; commercial BLOCKED, freeze NOT FROZEN.
- Settings dil popup və checked-hover label kontrastı screenshot əsasında düzəldildi (`bcd4e2a`, `49a9d6d`); bunların ingiliscə Chromium fixture görüntüləri nəzərdən keçirildi.
- Golden effect source manifest hash uyğunsuzluğu düzəldildi və 176 manifest faylı üçün yeni hash guard əlavə edildi (`e83492f`); hüquq təsdiqi deyil.

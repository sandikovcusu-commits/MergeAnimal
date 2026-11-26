# V0.8.2.1 — açıq risklər

- Real CrazyGames preview, real ad/revenue və Basic Launch/full-launch entitlement **BLOCKED**; rewarded preset yalnız full-launch təsdiqindən sonra seçilməlidir, avtomatik entitlement aşkarlanmır. Script blocking real AdBlock extension testi deyil.
- SDK `muteAudio` polling edir, sənədlərdəki settings-change listener hələ yoxdur; real platforma dəyişiklikləri, mobil lifecycle və fiziki audio dinləməsi yoxlanmayıb. SDK gameplay event-ləri 1 saniyə aralığında throttled ola bilər. Happy Time yoxdur.
- IndexedDB final sync asinxrondur; tab/proses dərhal bağlananda son checkpoint itə bilər. Save retry eyni canlı sessiyada işləyir, offline browser flush zəmanəti deyil.
- Sprite kommersiya hüquqları təsdiqlənməyib. Təbiətdən yaranan overflow, fiziki touch/Android/iOS və tam vizual/tərcümə yoxlaması yoxdu. Əvvəlki açıq risklər aşağıda tarixidir.

---

# Tarixi V0.8.2 WIP — SDK və monetizasiya (V0.8.2.1 ilə qismən aradan qaldırılıb)

- CrazyGames rewarded provider, hər üç reklam mükafatı, transaction/callback/timeout təhlükəsizliyi, UI və reward checkpoint yoxdur; düymələr fail-closed gizlidir. Reklam zamanı pause/audio və reward bütünlüyü yoxlanmayıb.
- SDK `muteAudio` başlanğıc dəyəri local demo-da yoxlanıb; canlı platformada dəyişiklik və fiziki audio cihazları yoxlanmayıb. Happy Time yoxdur. Rəsmi platforma preview və real reklam sınağı yoxdur.
- IndexedDB asinxron son-yazı itkisi, sprite kommersiya hüquqları və əvvəlki açıq risklər qalır. Bu build nə monetizasiya, nə də platformaya çıxış üçün hazırdır.

---

# V0.8.1.3 — audio acceptance gaps

- Real blur/hidden/tab return, OS interruptions, physical devices and speakers, Firefox touch, and sustained memory/performance behavior remain untested. Chromium touch is simulated. Slider touch drag itself needs independent testing.
- Twenty SFX graph checks use fixtures, not full natural end-to-end coverage; Restart/Continue/Game Over audio has not been independently verified. Loop wrap/output was observed, not human-reviewed for seamlessness. Audio recordings have not been listened to or professionally mix-reviewed.
- IndexedDB synchronization is asynchronous; immediate page/process close can lose the final write. The test's 10-second wait is not a production durability fix.
- Future ad hook has no SDK integration or real ad lifecycle testing.

---

# V0.8.1.2 — son yoxlamada açıq qalanlar

- Tutorial paneli artıq power-up düymələrini və spawn preview-ni örtmür, amma təlimat vaxtı oyun sahəsində zolaq tutur; bütün tutorial mərhələləri, dillər, mövzular və sıx oyun vəziyyətlərində vizual təsdiq aparılmayıb. 360 px-də bəzi yazılar çox kiçikdir.
- Bütün ekranlardakı bütün düymələr və bütün lokalizasiya/viewport kombinasiyaları əl ilə tam yoxlanmayıb; real tab dəyişməsi, Firefox touch və real Android/iOS cihazları yoxlanmayıb.
- `user://` IndexedDB sync asinxrondur: tab/proses dərhal bağlanarsa son save və ya power-up istifadəsi itə bilər. Bu risk düzəldilməyib.

---
# V0.8.1.2.1 — open Web UI and touch issues

- Full visual/translation acceptance is not complete: screenshot matrix is not fully manually reviewed, outcome states are English/Forest only, and translations lack native-speaker audit. At 360×640, Collection, Challenge and Restart labels and the evolution guide can be very small; some disabled controls have low contrast.
- Physical Android/iOS, Firefox touch, real tab-switch/OS interruptions and device safe areas/performance remain untested. Headless tab switch was explicitly skipped when no lifecycle event was emitted. Simulated gestures do not prove all touch orderings.
- Rescue/Game Over and Challenge unlocks use isolated fixture state, not natural play progression. Cross-product of gameplay/results in every language and theme remains untested.
- IndexedDB sync remains asynchronous; an immediate tab/process close can lose the last save or power-up use despite a local write. Storage eviction/deletion, cross-file atomicity and sudden power loss are not guaranteed.
- Commercial asset rights and platform testing remain unresolved; no public/commercial release claim. Earlier physics, asset and other risks below are not superseded by this Web UI work.

---
# V0.8.1.2 — current open issues / acceptance gaps

- Web UI/mobile QA is incomplete, not release-ready: full viewport/screen visual review, four locales, applying all themes, Challenge outcomes, scrolling, Rescue/Restart, focus/fullscreen/orientation and Firefox touch remain open. Simulated Chromium touch is not a real Android test; see `WEB_UI_REPORT.md` and `MOBILE_TOUCH_REPORT.md`.
- The Web touchcancel workaround applies to gameplay aim/drop; cancellation safety of every button and selection path is not established. Mouse, keyboard and native regression tests for the resize change still need to be rerun.
- IndexedDB persistence is asynchronous: closing immediately after an action may lose the final write; a GDScript file close does not acknowledge durable IndexedDB commit. Storage eviction/private browsing remain risks. No crash, power loss or concurrent-writer guarantee.
- Asset rights, missing expression sprites, real-device performance, safe areas and human usability remain release blockers; prior physics and save limitations also remain.

---

# V0.7.0 — open issues / release blockers

- Blink is a whole-sprite visual cue, not eye closure; happy/surprise use simple motion because the separate 24 expression sprites are absent. Release acceptance still flags missing states.
- Original procedural sounds and short loops have not been listened to or mix-reviewed by a person; WAV, not OGG. Mobile audio, Web autoplay, loop perception and professional quality are unverified. Not every sound's full user-action path has an independent assertion.
- The 12 existing AI animal sprites remain commercially blocked: backend/provider and applicable terms are unknown. Project-wide asset rights and logo trademark review remain open; see `ASSET_LICENSES.md`.
- A15 twelve natural discoveries remain unproved; saves are not fully cross-file atomic. Existing physical penetration/dense board risks remain.
- Real mobile touch, ≥30 FPS, mobile performance and Web exports are unmeasured; X11 fixtures/video are scripted, not human playtests. 360-pixel controls remain small. No actual iOS/Android/Windows device QA.

---

# V0.6.5 — open issues / acceptance gaps

- Achievement checkpoint strengthens mirror recovery and failed-write retry but it is not atomic with Classic/Challenge saves. A forced kill while the event is in memory, a crash between separate commits, simultaneous writers, rollback of all files, and power-loss durability remain unresolved; see `SAVE_SYSTEM_REPORT.md`. Do not call this exactly-once or fully crash-safe.
- Full A15 12-species organic/eligible chain was attempted but not completed; the first five used forced normal spawn selections. High-tier forced drops were rejected by the existing validator. Previous seeded historical state is not full proof.
- 360×640 controls are about 30 physical px high; touch target, safe-area, native-speaker translation review and exhaustive long-text/contrast checks remain unverified. X11 scripted screenshots are not human/mobile playtests. Desktop is portrait-letterboxed.
- Commercial sprite rights and 24 missing facial expression assets remain release blockers. Mobile FPS/battery/memory, Web exports and Windows hardware are untested. Previously measured physics penetration and dense pending merges remain. Golden Garden difficulty has not been verified by humans.

The following sections are historical and superseded where noted.

---

# V0.6.4.3 DEV — current limitations

- Achievement save and Classic/Challenge snapshots are separate transactions. Failed achievement writes can lose an event or suppress its notification; if backup refresh fails and primary subsequently corrupts, an older backup may lose an unlock and permit later re-notification. No abrupt-power-loss, concurrent writer, cross-file atomicity or all-platform guarantee.
- Animal Collector's twelfth discovery was tested with 11 pre-existing historical fixture discoveries, not a fresh complete 12-animal natural run. Classic score evidence uses a test-selected dog queue; Challenge A14 includes deterministic/repositioned test fixtures. Human play and distribution balance remain open.
- New Achievement strings are English only; 360×640 and desktop captures are seeded X11, not human touch or safe-area tests; desktop is portrait-letterboxed.
- Extra local save/evaluation cost has not been profiled on mobile. Unvalidated commercial art rights and 24 missing expression sprites still block release; earlier physics overlap, mobile performance and Web risks remain.
- Golden Garden difficulty remains unverified as documented for V0.6.4.2.

---
# V0.6.4.2 DEV — current limitations

- Golden Garden is physically solvable in four aligned drops, so requested challenge difficulty is not demonstrated and may not be satisfied. 11, 12, 15, 18, 19 are one-drop starter-board paths. Tune and human-playtest before accepting the difficulty progression.
- 06–10 automated solvability uses a test-selected dog, not ordinary random gameplay; fixed queues and simulated timings do not establish real-player success rate or game balance. See `CHALLENGE_BALANCE_REPORT.md`.
- Limited-drop settlement depends on bodies becoming stable; a persistently moving or pending/blocked merge can delay failure indefinitely. Physics crowding and overlap risks remain.
- X11 captures are simulated windows, desktop portrait-letterboxed. Human touch, safe-area, locale and performance checks remain open; collection/statistics preservation is primarily byte-level.
- 24 expression sprites and verified commercial asset rights still missing; release blocked. No mobile/Web durability, sudden power loss or multiwriter guarantees.

---
# V0.6.3.3 DEV — current limitations

- Rescue's mandatory danger set is conservative: all bodies crossing the danger line are selected even if some would fall below it unaided. The additional spawn-blocker set is minimized for that policy, but globally minimal physical removal is not proved; a dense board can fail the configured cap when another hypothetical strategy might work.
- The pre-commit spawn query can reject static or animal obstacles without spending a use. If moving bodies subsequently occupy the spawn, input waits for it to clear; an indefinitely blocked spawn has no timeout or automatic alternate lane recovery.
- Local backups cannot prevent a use from returning if all save/checkpoint copies are removed, damaged or rolled back together. Abrupt power loss, concurrency and device persistence are not proven. Failed pending writes can leave an older checkpoint as the last recoverable state.
- Release remains blocked: sprite model/vendor and commercial rights are unverified, transparency/halo and Bear silhouette need review, and 24 expression sprites are missing. Previous 120 Hz 9.190 px maximum penetration remains. Real mobile touch, FPS/RAM/battery, human playtests and Web export/compatibility remain unverified. X11 seeded fixtures and simulated touch are not those tests.

---
# Məlum problemlər — V0.3.0-dev

- P1: 60 Hz normal bot gameplay-də 16.678 px, 120 Hz-də eyni seed-lərlə 9.190 px-ə qədər floor/sərhəd overlap ölçüldü; >0.01 px resting kontakt nüfuzu çox uzun qala bilər; sürətli divar təmasında nüfuz da qalır; sıfır overlap və real cihazda görünməzlik təsdiqlənməyib. Dərinlik, müddət, tam escape və ilişmə ayrıca `PHYSICS_REPORT.md`-dədir.
- P1: Sıx sahədə böyük merge nəticəsi üçün boş yer tapılmasa cüt kilidli pending qalır və təkrar yoxlanır; uzunmüddətli sıxlıq/Game Over qarşılıqlı təsiri üçün əlavə test lazımdır.
- P1: Konseptlərin orijinalları 1254×1254 RGB opakdır; `concepts/processed/` 512×512 alpha törəmələr avtomatik təmizlənib, kənar və quyruq bölgəsi əl auditinə ehtiyac duyur. Generasiya aləti model ID-ni bildirməyib; kommersiya hüquqları təsdiqlənməyib; oyun sprite-ı kimi qoşulmayıb.
- P1: Real GUI rendering, alt guide oxunaqlılığı, telefon touch hardware, Windows BAT, Android/iOS, müxtəlif rezolyusiya input koordinatları və Web export hələ yoxlanmayıb. Stretch keep konfiqurasiyası fiziki cihaz nəticəsi deyil.
- P2: 100 bot sessiyası məqsədli 90 simulyasiya saniyəsi ilə məhdudlaşdırılıb; nəticələr uzun insan oyunu, oyun müddəti, filə çatma ehtimalı və mobil performans statistikası deyil.
- P2: Sadə `ConfigFile` yalnız best score saxlayır; lokallaşdırma resursları, audio, tutorial, tam menyu, save, son sprite/effect-lər yoxdur. Debug fixture oyun balansı deyil. 120 Hz fizikanın mobil enerji/CPU xərci ölçülməyib.

## V0.4.1 DEV əlavələri
- 12 normal heyvanın AI mənbə model/vendor və Arena kommersiya şərtləri UNKNOWN — bütün 12 sprite üçün release BLOKLU. 1024² Bear/Lion mənbələri də opak checkerboard idi; avtomatik şəffaflaşdırma üz və kənarlarda əl QA tələb edir.
- 24 happy/surprise vizual state, blink, 6 effekt və logo yoxdur; mövcud enum fallback-u yeni üz effekti deyil.
- 20 SVG ikon və səkkiz StyleBox theme var, icon-lar HUD-a bağlanmayıb, UI/kiçik ölçülü vizual qəbul və bütün state-lərin interaktiv yoxlaması yoxdur.
- 8eefda7-də pəncərə screenshot sınağı səhvən köhnə ölçüdə viewport və qara boşluğu capture edirdi; format/ölçü testi tək başına yetərli deyil. Düzəldilmiş capture `45682074271`-də hər ölçü üçün ayrı X11 pəncərəsi çəkir; screenshot-lara baxış barədə `VISUAL_QA_REPORT.md`.
- İnsan oyun testi, mobil touch, FPS və enerji, Web/Windows export və yüksək pikli floor overlap həll edilməyib.

## V0.5.0 DEV (historical; superseded where noted)
- 24 happy/surprise states and blink are still absent; normal fallback must not be described as 36 distinct states. The separate release acceptance test flags 24 missing plus rights blocker.
- Collection and Challenge screens/progression remain absent and their main-menu buttons are intentionally disabled. No fake Continue/ad, Undo or Remove feature is shown.
- Four-language dictionaries cover new main controls but existing animal names, some HUD/debug text, the logo and other strings remain English; localized clipping was not visually tested.
- 8 of 20 icons are placed, including the two disabled mode entries; other icons, 8 visual themes, and all button states have not received full on-device UX review. Standalone final logo, full motion list, game settings theme selection, new-unlock animation and complete UI polish remain undone.
- 18 gameplay and 18 interface/effect scripted X11 fixtures have been captured for a tested commit; they are not videos or interactive human play. Real mobile touch, safe areas, CPU/FPS and Web export remain untested.
- AI sprite output is from Arena image tool but exact vendor/model and applicable supplemental/provider terms remain unknown. See `ASSET_LICENSES.md`; **commercial/final release remains blocked**.
- Physical overlap and Bear silhouette mismatch are separate unresolved risks; `PHYSICS_REPORT.md`.

## Day 6 WIP (historical; superseded where noted)
- Classic session saving and Continue are connected in V0.6.1; cross-platform durability, interrupted writes, human play and mobile/Web remain unverified. See `SAVE_SYSTEM_REPORT.md`.
- Challenges, Collection, Achievements, unlocks, statistics and requested power-ups remain unimplemented. No V0.6.0 release acceptance, stress matrix or new UI screenshot suite has been completed. See `PROGRESSION_REPORT.md`.
- Intermittent Godot editor import double-free on V0.5 baseline: observed twice in three reruns; excluding non-asset test logs from import is a mitigation with two passing runs, not a confirmed root cause.

## V0.6.2 DEV — historical limitations (Remove superseded in V0.6.3.1)
- AI sprite provider/model and applicable commercial terms remain unverified; final commercial release is blocked. The 24 facial states are still missing.
- Previously measured wall/floor penetration and Bear silhouette mismatch remain unresolved; no physics parameters or sprites were changed for V0.6.2.
- Recovery can roll back to an earlier transaction. Power-loss/fsync, multi-writer, mobile/Web/Windows persistence and real device performance remain untested.
- Legacy v0.6.1 body provenance is unknown and therefore ineligible for collection events; their merges make the current score untrusted for lifetime best/combo. Earlier totals and dates cannot be reconstructed. Debug sessions suppress further progression.
- 21 Godot X11 captures are scripted visual fixtures, not human play; 1366×768 uses portrait letterboxing. Mobile touch, safe areas and human visual acceptance are unverified.
- Challenge, Achievement, Undo, Remove and Rescue remain out of scope/unimplemented.

## V0.6.3.1 DEV limitations (historical; checkpoint issue strengthened in V0.6.3.2)
- A successful Remove commits the primary first, then refreshes the backup. If that second write fails, the primary remains committed but a later corruption may recover an older backup and allowance; this rare combined failure is not tested. Power-loss/fsync, simultaneous writers and downgrade to a build that ignores the new v2 field remain unsupported/untested.
- Selection waits for a fully snapshot-safe board; pending merges can prevent a Remove commit until they settle. Dense locked-pair behavior remains an existing risk.
- X11 captures and touch events are scripted fixtures, not human or physical-device tests. Real Android/iOS touch, mobile FPS, CPU and battery remain unknown. Existing 9.190 px 120 Hz penetration, 12 AI sprite commercial-rights uncertainty, missing expression states and Bear silhouette concerns remain open. Undo, Rescue, Challenge and Achievement are not implemented.

## V0.6.3.2 DEV limitations
- The full power-up journal guards a stale backup when it survives; if it is deleted or an entire older save set is restored, no local-only mechanism guarantees spent balances. A corrupt journal intentionally blocks Continue/writes. Concurrent writers, forced power loss/fsync, actual disk-full, downgrade and mobile/Web/Windows durability are untested.
- Undo is disabled until pending merges finish; an existing dense pair that cannot find room can remain locked, preventing Undo. Recent best score is checkpointed with progression, not separately at each merge; a crash before a safe save can lose recent progress.
- Real mobile touch, FPS/battery, human play and commercial sprite rights remain unverified. The earlier 120 Hz 9.190 px maximum penetration, Bear silhouette mismatch and 24 missing facial states remain unresolved. Rescue, Challenge and Achievement remain unimplemented.

## V0.8 Web aralıq statusu
Web A sınaq matrisi natamamdır; real cihaz, audio dinləmə, power-up istifadə limiti persistensiyası və digər əsas ekranlar hələ yoxlanmayıb. SDK və monetizasiya mövcud deyil. Ətraflı `WEB_QA_REPORT.md`. Browser storage silinərsə progress itə bilər.

## V0.8.1.1 Web saxlama riski
`user://` checkpoint yazısının tamamlanması brauzerin IndexedDB-yə async sync-i təsdiq etdiyi anlamına gəlmir. Dərhal tab/proses bağlanarsa son əməliyyat və istifadə limiti itə bilər; cross-file atomiklik və storage silinməsi/eviction riskləri qalır. Müşahidə və əhatə: `WEB_POWERUP_REPORT.md`.

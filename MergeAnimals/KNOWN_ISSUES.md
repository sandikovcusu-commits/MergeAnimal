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

## V0.6.3.1 DEV limitations
- A successful Remove commits the primary first, then refreshes the backup. If that second write fails, the primary remains committed but a later corruption may recover an older backup and allowance; this rare combined failure is not tested. Power-loss/fsync, simultaneous writers and downgrade to a build that ignores the new v2 field remain unsupported/untested.
- Selection waits for a fully snapshot-safe board; pending merges can prevent a Remove commit until they settle. Dense locked-pair behavior remains an existing risk.
- X11 captures and touch events are scripted fixtures, not human or physical-device tests. Real Android/iOS touch, mobile FPS, CPU and battery remain unknown. Existing 9.190 px 120 Hz penetration, 12 AI sprite commercial-rights uncertainty, missing expression states and Bear silhouette concerns remain open. Undo, Rescue, Challenge and Achievement are not implemented.

> **V0.9.0.1 in progress:** Replacement vector animal assets and rights audit are under review. Commercial release remains blocked; runtime/export verification is pending. See `COMMERCIAL_RIGHTS_REPORT.md`.

> **V0.7.0 development:** Procedural animation, original synthesized audio, central audio settings and SVG logo are included. First input starts audio. Separate eye/expression art and human audio/device acceptance remain incomplete; commercial sprite release is blocked. See `ANIMATION_REPORT.md`, `AUDIO_REPORT.md`, `PERFORMANCE_REPORT.md`, `ASSET_LICENSES.md`, `QA_REPORT.md`, and `KNOWN_ISSUES.md`.

> **V0.6.5 development:** Themes, four-language Achievement text and Achievement save checkpoint/retry are available. Commercial release remains blocked and cross-file atomicity is not guaranteed. See `THEME_REPORT.md`, `LOCALIZATION_REPORT.md`, `SAVE_SYSTEM_REPORT.md`, `QA_REPORT.md`, and `KNOWN_ISSUES.md`.

> **V0.6.4.3 DEV / WIP:** Achievements are available from the main menu. Unlocks are separate from Classic saves and permanent like Collection discovery; score thresholds use Classic best only. See `ACHIEVEMENT_REPORT.md`, `QA_REPORT.md` and `KNOWN_ISSUES.md`.

> **V0.6.4.2 DEV / WIP:** 20 Challenges, separate progress, time/drop/combo/golden goals, and unsaved-attempt warnings are available. Human balance, particularly Golden Garden difficulty, remains unverified. See `CHALLENGE_REPORT.md`, `CHALLENGE_BALANCE_REPORT.md`, `QA_REPORT.md` and `KNOWN_ISSUES.md`.

> **Historical V0.6.4.1 DEV:** Challenges 01–05 are available from the main menu. Results and bests are saved separately; active challenge boards are not resumed after exit. See `CHALLENGE_REPORT.md` and `QA_REPORT.md`.

> **V0.6.3.3 DEV:** Game Over offers one free Classic Rescue per session, with recoverable pending Game Over and a committed checkpoint. Play Again/Main Menu finalize the loss. See `POWERUP_REPORT.md`, `SAVE_SYSTEM_REPORT.md` and `QA_REPORT.md`; release remains blocked.

> **Historical V0.6.3.2 DEV:** Classic Undo restores the last successful drop once per session; Remove clears the previous Undo boundary. Undo and Remove survive Continue through a generation checkpoint. See `POWERUP_REPORT.md` and `SAVE_SYSTEM_REPORT.md`. Rescue remains unavailable.

> **Historical V0.6.3.1 DEV:** Classic Remove is available once per session; select an outlined animal or Cancel. Continue preserves a spent use. Undo and Rescue are not implemented. See `POWERUP_REPORT.md` for save and device limitations.

> **Historical V0.6.2 DEV / release blocked:** Collection, Statistics and local Classic Continue are available; Challenges remain disabled. AI sprite commercial rights are unresolved and 24 expression states remain missing. See `COLLECTION_REPORT.md`, `STATISTICS_REPORT.md` and `ASSET_LICENSES.md`.

# Merge Animals: Wild Garden — V0.7.0-dev

Godot 4.7.2, Compatibility renderer, 120 Hz fizika, redaktə edilə bilən 2D mənbə layihəsi. V0.2.1 üzərindən inkişaf etdirilib. Başsız Linux Actions testləri `QA_REPORT.md`-dədir. **DEV:** X11 proqram renderi yoxlanıb; real mobil touch və Windows yoxlanmayıb; qrafikalar son kommersiya qəbulundan keçməyib.

## Açmaq və oynamaq
Windows: Godot 4.7.2 ayrıca quraşdırın, `RUN_GAME.bat`-ı açın. Testlər üçün `RUN_TESTS.bat` (Windows-da yoxlanmayıb). Başqa sistemlərdə Project Manager-də `project.godot` import edin və F5. Mouse və ya touch ilə yeri seçib buraxın; UI PAUSE/RESTART düymələri var. `user://wild_garden.cfg` best score üçündür.

## Redaktə
`resources/animals/*.tres`: ID, ad, translation key, level, radius, mass, friction, bounce, damping, score, spawn weight, sprite və səslər, sonrakı ID. İlk beş səviyyə çəkili spawn üçün uyğundur, digər səviyyələr təsadüfi düşmür. `Game.tscn` root-da 12 resource, cooldown, combo pəncərəsi və golden config resursu dəyişdirilə bilər. Golden merge iki filin yerini boşaldır; bonus combo ilə vurulmur. Combo 1 s, x2=1.25, x3=1.5, x4=1.75, x5+=2; yeni oyunda sıfırlanır.

Alt Evolution Guide rəngli dairə və adın ilk üç hərfi ilə 12 səviyyəni göstərir; yalnız cari sessiyanın ən yüksək səviyyəsini vurğulayır. Kiçik ekranda oxunaqlılıq **vizual yoxlanmayıb**. Konsept şəkillər `concepts/`-da, oyun sprite-larına qoşulmayıb; 512×512 alpha törəmələri avtomatik hazırlanıb, lakin kənarlar və kommersiya hüquqları yekun təsdiqlənməyib (`ASSET_LICENSES.md`).

## Test və məhdudiyyət
Godot import və skriptləri `.github/workflows/godot-tests.yml` və `RUN_TESTS.bat` göstərir. `tests/logs/` əvvəlki və yeni faktiki loglar, 100 bot sessiyasının CSV-si; hesabatlar `BALANCE_RESEARCH.md`, `BALANCE_REPORT.md`, `PHYSICS_REPORT.md`, `QA_REPORT.md`, `ROOT_CAUSE_REPORT.md`, `KNOWN_ISSUES.md`-dədir. Botlar insan testi deyil; headless stress mobil performans deyil. Web export bu mərhələdə edilməyib.

### Classic Continue (V0.6.1-dev)
Play autosaves locally at safe points. Pause to save before returning to the menu; if a merge is still pending, resume and wait. Continue restores the most recent validated checkpoint. Starting a new game asks before replacing a saved session; game over clears it. Recovery can fall back to an older checkpoint. See `SAVE_SYSTEM_REPORT.md` for testing and limitations.

### Collection and statistics (V0.6.2-dev)
Open Collection or Statistics from the main menu. A normal first-tier drop or merge result records a creation; locked tiers show their discovery condition. Details and statistics use local save data. See `COLLECTION_REPORT.md` and `STATISTICS_REPORT.md` for rules, migration and test limits.

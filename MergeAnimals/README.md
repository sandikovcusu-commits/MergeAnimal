# Merge Animals: Wild Garden — V0.3.0-dev

Godot 4.7.2, Compatibility renderer, 120 Hz fizika, redaktə edilə bilən 2D mənbə layihəsi. V0.2.1 üzərindən inkişaf etdirilib. Başsız Linux Actions testləri `QA_REPORT.md`-dədir. **DEV:** real render, mobil touch və Windows test edilməyib; qrafikalar müvəqqətidir.

## Açmaq və oynamaq
Windows: Godot 4.7.2 ayrıca quraşdırın, `RUN_GAME.bat`-ı açın. Testlər üçün `RUN_TESTS.bat` (Windows-da yoxlanmayıb). Başqa sistemlərdə Project Manager-də `project.godot` import edin və F5. Mouse və ya touch ilə yeri seçib buraxın; UI PAUSE/RESTART düymələri var. `user://wild_garden.cfg` best score üçündür.

## Redaktə
`resources/animals/*.tres`: ID, ad, translation key, level, radius, mass, friction, bounce, damping, score, spawn weight, sprite və səslər, sonrakı ID. İlk beş səviyyə çəkili spawn üçün uyğundur, digər səviyyələr təsadüfi düşmür. `Game.tscn` root-da 12 resource, cooldown, combo pəncərəsi və golden config resursu dəyişdirilə bilər. Golden merge iki filin yerini boşaldır; bonus combo ilə vurulmur. Combo 1 s, x2=1.25, x3=1.5, x4=1.75, x5+=2; yeni oyunda sıfırlanır.

Alt Evolution Guide rəngli dairə və adın ilk üç hərfi ilə 12 səviyyəni göstərir; yalnız cari sessiyanın ən yüksək səviyyəsini vurğulayır. Kiçik ekranda oxunaqlılıq **vizual yoxlanmayıb**. Konsept şəkillər `concepts/`-da, oyun sprite-larına qoşulmayıb; 512×512 alpha törəmələri avtomatik hazırlanıb, lakin kənarlar və kommersiya hüquqları yekun təsdiqlənməyib (`ASSET_LICENSES.md`).

## Test və məhdudiyyət
Godot import və skriptləri `.github/workflows/godot-tests.yml` və `RUN_TESTS.bat` göstərir. `tests/logs/` əvvəlki və yeni faktiki loglar, 100 bot sessiyasının CSV-si; hesabatlar `BALANCE_RESEARCH.md`, `BALANCE_REPORT.md`, `PHYSICS_REPORT.md`, `QA_REPORT.md`, `ROOT_CAUSE_REPORT.md`, `KNOWN_ISSUES.md`-dədir. Botlar insan testi deyil; headless stress mobil performans deyil. Web export bu mərhələdə edilməyib.

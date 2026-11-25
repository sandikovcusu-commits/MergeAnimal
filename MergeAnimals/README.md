# Merge Animals: Wild Garden

**V0.2.1-dev — headless sınaqdan keçən mənbə prototipi, kommersiya buraxılışı deyil.** Godot 4.7.2 rəsmi Linux GitHub Actions runner-də işlədilib; real cihaz, Windows və vizual render yoxlanmayıb. Placeholder qrafika hələ mövcuddur.

## Lokal başlatma
1. Godot **4.7.2.stable** quraşdırın; Project Manager-də bu qovluqdakı `project.godot` faylını import edin.
2. Editor importu tamamladıqdan sonra F5 basın. Sahədə basın/sürüşdürün və buraxın. Məqsəd eyni növləri böyütməkdir. Hazırkı resource ardıcıllığı Mouse → Hamster → Rabbit → Cat → Dog; Dog müvəqqəti maksimumdur və birləşmir. İlkin təsadüfi spawn əvvəlki üç növ arasında bərabərdir.
3. Ekrandakı PAUSE/RESUME və RESTART idarəetmələrini yoxlayın. Cari və növbəti heyvanın preview-si, xal və rekord göstəriciləri mövcuddur. Best `user://wild_garden.cfg`-də saxlanır; bu tam save sistemi deyil.
4. Inspector: `Game.tscn` root-da sərhədlər, spawn hündürlüyü, cooldown, seed və resurslar; `DangerMonitor`-da grace period; `resources/animals/*.tres`-də fizika və görünüş məlumatları dəyişir. Divar shape-ləri və ayrıca bound dəyərləri uyğun qalmalıdır.

## Debug və test
`Game.tscn` root Inspector-da **Debug Enabled** seçin və debug/editor build-də işə salın; paneldə spawn leveli, pair, chain, fill, overflow və təxmini collision outline var. Panel release build-də `OS.is_debug_build()` şərti ilə gizlənir. Debug fixture-larının davranışı normal gameplay balansı deyil.

Lokal başsız testlər (Linux/macOS terminalında Godot icra faylı `godot` adındadırsa):
```sh
python3 tests/unit/check_project.py
python3 tests/unit/test_static_contract.py
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/integration/day2_suite.gd
godot --headless --path . --script res://tests/physics/natural_collision.gd
godot --headless --path . --script res://tests/physics/drop_100.gd
godot --headless --path . --script res://tests/physics/stress.gd
```
Windows-da `RUN_GAME.bat` və `RUN_TESTS.bat` fayllarından istifadə edin; Godot ayrıca quraşdırılmalıdır. Exe-ni layihə qovluğuna qoyun, PATH-ə əlavə edin və ya soruşulduqda tam yolunu daxil edin. Windows skriptləri həmin platformada hələ sınanmayıb; test çıxışları `test-results` qovluğundadır. Editor-un Output panelindəki bütün xətaları və test çıxışlarını saxlayın; xətasız parse real touch, rendering və fiziki keyfiyyət sübutu deyil. 100-drop fixture hər düşürmədən sonra öz obyektini silir, ayrıca 100/150/200-body stress fixture sabit say üçün merge və danger-ı söndürür; bunlar normal oyun testi deyil. Debugger → **Visible Collision Shapes** ilə real shape-ləri vizual yoxlayın; debug panelin OUTLINES düyməsi yalnız təxmini render konturudur.

Manual yoxlayın: təbii fizika kontaktı ilə merge, 3/4 eyni cisim, sıx zəncir, divar/döşəmə yaxınlığı, game-over grace və yanlış sıçrayış, pause zamanı fizikanın dayanması, restart, mouse/touch/emulated mouse, iki barmaq, ləğv, UI basması, mobil portret və landşaft. 18 V0.1 screenshot ayrıca audit edilib, orijinalları məxfilik üçün repoya daxil edilməyib. Ətraflı status: `QA_REPORT.md`, `SCREENSHOT_AUDIT.md`, `KNOWN_ISSUES.md`, `PHYSICS_REPORT.md`.

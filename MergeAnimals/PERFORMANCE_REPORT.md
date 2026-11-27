# V0.8.3 — Web performans hesabatı

Baza `32d50e5`; ilkin əsas ölçmələr runtime dəyişmədən `b8a1905` test harness ilə alındı. Sonrakı daha sərt chain/effect, reward və CPU sınaqlarında köhnə runtime həmin commit-dən ayrıca CI-də export edildi (yəni sonradan təkrar ölçülmüş baseline); son runtime `e439471`-dən etibarən dəyişməyib. Xam hər təkrar, run ID, browser və göstəricilər `docs/performance/BENCHMARK_BEFORE.csv` / `BENCHMARK_AFTER.csv`-dədir; `WEB_OPTIMIZATION_REPORT.md` export və asset auditini göstərir.

## Metod və nəticələrin etibarlılığı

GitHub Actions Ubuntu 24.04, Godot 4.7.2 release WASM, 360×640, Playwright 1.56.1, Xvfb/Mesa; Chromium 141 ANGLE SwiftShader, Firefox 142 llvmpipe, 4 məntiqi CPU bildirən runner. FPS requestAnimationFrame intervallarıdır: orta = 1000/orta ms, 1% low = ən yavaş 1% intervalların orta müddətinin tərsi, median/P95 frame-time ms. Hər xana 60 saniyəlik **ardıcıl** üç intervalın ortalamasıdır; bunlar ayrıca proseslərdə müstəqil təkrar deyil. Godot monitorları saniyədə bir dəfə nümunələnir. Browser və runner-lər ayrı maşınlarda işlədi; Chromium nəticələri çox dəyişkəndir, rəqəmlərin fərqi səbəb-nəticə və ya zəmanətli FPS artımı deyil. Browser VSync Firefox-u təxminən 59 FPS-də məhdudlaşdırır. Heç bir real Android/iOS və ya GPU testi deyil.

`natural`: real UI vasitəsilə hər 3 saniyədə scripted click; insan oyunu deyil və Game Over/board dolduqdan sonra son intervallar boş qala bilər. Digər sətirlər fixture-dir: 10/20/40 daim aktiv, merge-lock-lu body; collision 20 body-yə impuls; `chain` ilkin cütü fixture ilə rezerv edir, sonrakı tier-2 collision fizikidir, tier-3 və 92 toplam merge müşahidə edildi; `golden` təkrarlanan real terminal collision-dur; effects birbaşa merge feedback trigger-idir (cap 40-a çatdı); reduced eyni sintetik yükdür; rewarded rəsmi SDK yox, mock uğurundan sonra bir body ilə gameplay-dir. Fixture-lərdə stabil yük üçün danger və autosave söndürülür, natural ssenaridə isə normaldır. Rewarded və chain nəticələri təbii progression/reklam kimi təqdim edilmir.

Cədvəl hüceyrəsi: **orta FPS / 1% low FPS / median ms / P95 ms**.

| Ssenari | Chromium əvvəl | Chromium sonra | Firefox əvvəl | Firefox sonra |
|---|---:|---:|---:|---:|
| natural | 56.2 / 29.5 / 16.7 / 27.8 | 53.0 / 29.3 / 16.7 / 33.4 | 58.3 / 43.9 / 17.1 / 17.1 | 58.6 / 45.7 / 17.1 / 17.1 |
| 10 | 59.7 / 49.7 / 16.7 / 16.7 | 59.5 / 49.7 / 16.7 / 16.7 | 59.0 / 58.1 / 17.1 / 17.1 | 59.0 / 58.3 / 17.1 / 17.1 |
| 20 | 47.3 / 29.1 / 16.7 / 33.4 | 59.4 / 49.7 / 16.7 / 16.8 | 59.0 / 58.2 / 17.1 / 17.1 | 59.0 / 58.3 / 17.1 / 17.1 |
| 40 | 39.4 / 28.7 / 33.2 / 33.4 | 47.3 / 28.8 / 16.7 / 33.4 | 59.0 / 58.1 / 17.1 / 17.1 | 59.0 / 57.1 / 17.1 / 17.1 |
| collision | 57.4 / 29.5 / 16.7 / 22.3 | 42.8 / 29.7 / 16.7 / 33.4 | 59.0 / 58.1 / 17.1 / 17.1 | 59.0 / 58.1 / 17.1 / 17.1 |
| chain | 59.6 / 49.1 / 16.7 / 16.8 | 59.7 / 49.7 / 16.7 / 16.7 | 59.0 / 58.2 / 17.1 / 17.1 | 59.0 / 58.3 / 17.1 / 17.1 |
| golden | 47.9 / 29.4 / 16.7 / 33.4 | 59.5 / 38.2 / 16.7 / 16.8 | 59.0 / 58.2 / 17.1 / 17.1 | 59.0 / 58.3 / 17.1 / 17.1 |
| effects | 47.5 / 29.9 / 16.7 / 33.4 | 47.3 / 29.9 / 16.7 / 33.4 | 58.9 / 54.3 / 17.1 / 17.1 | 58.9 / 54.3 / 17.1 / 17.1 |
| reduced | 44.0 / 28.3 / 16.7 / 33.4 | 51.6 / 29.9 / 16.7 / 33.4 | 59.0 / 58.2 / 17.1 / 17.1 | 59.0 / 58.1 / 17.1 / 17.1 |
| rewarded | 48.7 / 29.3 / 16.7 / 33.4 | 37.3 / 27.2 / 33.3 / 33.4 | 59.0 / 58.0 / 17.1 / 17.1 | 59.0 / 56.0 / 17.1 / 17.1 |

Eyni sərt effekt ssenarisində orta draw call: Chromium normal 143.4→143.0, reduced 85.6→87.3; Firefox normal 142.0→143.9, reduced 90.0→90.0. Reduced daha az draw call yaradır; FPS fərqini runner qarışıqlığından təkbaşına optimizasiya effekti saymaq olmaz. 4× Chromium CPU throttling + 360×640 sintetik profildə 40-body 41.0→53.6 FPS və köhnə yüngül effekt 49.0→26.0 FPS ölçülüb; nəticələr runner-dən güclü asılıdır, throttling fiziki mobil cihaz deyil. 30 FPS mobil və 60 FPS desktop real hədəfləri təsdiqlənməyib.

Başlanğıc ölçmələri instrumentasiyalı no-ads test exportunda yeni browser context və eyni kontekstdə reload-dur: 9 ssenari üzrə median cold/warm/menu-ready Chromium **1577/1358/1511 → 1505/1351/1443 ms**, Firefox **3005/2294/2477 → 3288/2289/2876 ms**. Bunlar localhost və CI nəticələridir, CDN, real şəbəkə, keşin bütün platformalarda işləməsi və ya müstəqil cihaz təkrarı deyil. İlk after harness exportuna səhvən istifadə olunmayan benchmark CSV translation-ları daxil olmuşdu; son production exportundan çıxarılıb. Bu, after startup/PCK testini son build üçün tam ekvivalent etmir.

CPU/RAM üçün ayrıca 20-body, üç × 60 s /proc sampling: Node + Playwright + browser ağacında bir core=100% kimi Chromium **346.0→345.9%**, Firefox **121.6→86.3%**; toplanmış RSS **1349.6→1336.3 MiB** və **1386.6→1394.4 MiB**. Paylaşılan səhifələr çoxsaylı sayılır, Xvfb ayrıca xaricdir; bu oyun RAM-ı deyil və runner fərqi təsiri ayrılmayıb. Chromium JS heap ayrıca CSV-dədir, Firefox bunu vermir. Godot Web `MEMORY_STATIC` 0 qaytardığı üçün ölçülməmiş sayılıb; GPU yaddaşı ölçülməyib. Physics/process monitor ms və draw call hər interval üçün CSV-dədir; məsələn 20-body CPU-probe physics Chromium 0.34→0.38 ms, Firefox 2.04→1.70 ms. Bunlar nümunələnmiş engine monitorlarıdır, OS CPU profili deyil. `audio_latency_ms` output latency göstəricisidir, **audio processing CPU time deyil**; audio emal müddəti ayrıca ölçülməyib.

## Fizika və saxlama

Fizika 120 Hz-də saxlanılıb. Eyni 100 seed-li 90 simulyasiya saniyəsinə qədər bot matrisi, headless Godot, əvvəl [45914992136](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45914992136), sonra [45916790720](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45916790720): 120 Hz maksimum sərhəd nüfuzu **9.190→9.190 px**, tam escape frame 0→0; 60 Hz **16.678→16.678 px**, escape 0→0. Bütün 200 nəticə sətri eynidir. Bu sıfır nüfuz deyil; wall duration fərqli runner-lərdə 120 Hz 274.432→316.836 s, CPU müqayisəsi deyil. 90 Hz ölçülməyib, heç bir tick/physics materialı dəyişməyib. Chain, Golden, duplicate merge və danger testləri native CI-dədir; tam crowding/cihaz keyfiyyətinə ümumi zəmanət deyil.

IndexedDB transaction observer: Chromium [45916207722](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45916207722) 35 readwrite transaction, median 67.1 ms (22.1–113.9); Firefox [45916211427](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45916211427) 38 transaction, median 1 ms (0–13). Altı click-dən növbəti transaction complete-a 207–819 ms və 88–109 ms müşahidə edilib; əlaqə yalnız zamana əsaslanır, həmin click-in checkpoint-inə zəmanətli aid deyil. Completion disk fsync və ya Godot save API acknowledgment deyil. [Power-up browser test](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45916842766) 66/66, ancaq dərhal bağlama Firefox-da köhnə save bərpa etdi. Checkpoint/reward idempotence qorunur, lakin async son yazı riski həll olunmayıb; V0.9.0 üçün həqiqi sync-completion protokolu və saving status ayrıca işdir. Yeni davamlı save əlavə edilməyib.

---

# Tarixi performans hesabatları

# V0.7.0 performance notes

Compatibility renderer and 120 Hz physics configuration remain unchanged. Visual movement uses one child Node2D per existing animal with one short tween at a time; previews do not run the idle loop. The audio singleton has one music and eight SFX/UI players and refuses extra sounds; collision sound has a speed threshold and global cooldown. Effects are capped at 40 and self-free; floating score labels are capped at 8 and free after 0.7 seconds. Reduced Effects suppresses camera movement and decorative merge effects. No new large animal texture sets were added; three mono WAV loops and the small vector logo are bundled.

These are design bounds, not measured frame-rate or memory claims. No Android/iOS 30 FPS, CPU, memory, battery, thermal, dense-board performance, actual device audio latency or Web export measurement was performed. Per-animal idle `_process` and additional transient effects need profiling on low-end target hardware. Headless CI is not a mobile benchmark. Existing physics overlap/crowding and safe-area/touch concerns remain. CI uses X11 software rendering; a scripted capture is not a human playtest.

---

## Historical performance report (prior versions)

# Performans hesabatı — V0.2.1-dev tarixi ölçülər

Headless Linux Actions runner-də 100/150/200-body təcrid edilmiş stress fixture işlədi (`tests/logs/v021-runtime-green.txt`). Run 45662097242 çıxışı FPS=145, physics_seconds=0.000166/0.000397/0.001272, static_bytes=34025047/35457767/37069767 bildirir; bunlar həmin anda Godot monitor snapshotlarıdır, benchmark, cihaz RAM-ı və ya normal gameplay deyil. Merge və danger deaktiv idi; escaped=0. Mobil cihaz, real gameplay frame-time/FPS/RAM, Web və enerji sərfi ölçülməyib. Dolu sahədə pending merge axtarışı profiler ilə ölçülməlidir; heç bir mobil performans hədəfi təsdiqlənməyib.

V0.3.0-dev 120 Hz: 100 bot işlədilib, amma mobil CPU, FPS, enerji və RAM ölçülməyib. Əvvəlki snapshotlar 60 Hz və başqa versiyaya aiddir, müqayisəli benchmark deyil.

## V0.4.1 DEV: fayl və ölçmə məhdudiyyəti
2026-11-25 yerli fayl cəmləri: 12 PNG 3,608,716 byte, 3 SVG fon 3,318 byte, 20 SVG ikon 5,252 byte, 8 Theme 19,013 byte. 12 × 512 × 512 × 4 = 12,582,912 byte (12 MiB) mipsiz xam RGBA tekstura baza səviyyəsinin nəzəri yuxarı təxmini; faktiki GPU/textura import formatı və mipmap-lar ölçülməyib. Mənbə şəkilləri `.gdignore` altındadır; Web export yoxlanmayıb.

GitHub Actions `8eefda7` headless, 4 eyni seed-li bot ssenarisi, 90 simulyasiya saniyəsi üçün: 60 Hz `BOT_COMPLETE wall_seconds=4.513`, 120 Hz `7.850`. Bu bir runner-də proqramın ölçdüyü toplam wall time-dır, CPU time deyil və fərqli trayektoriyalar var; 120/60 təxminən 1.74×, cihaz, istifadə, təkrar, enerji və statistik nəzarət yoxdur. Software render frame time və physics frame time profillənməyib; bu dəyərlər və real mobil FPS/CPU/enerji naməlumdur. Physics 9.190 px risk qalır.

## V0.5.0 source breakdown / limits
2026-11-25 yerli ilkin ölçüdə `assets/` 3,639,819 B, `art_source/` + `concepts/` 23,994,036 B, `tests/` + `art_reports/` 6,783,631 B, `docs/` 2,074 B, kök Markdown 64,138 B, layihə faylları ümumilikdə 34,614,136 B idi; sənədlər və test görüntüləri son yeniləmə ilə dəyişə bilər. Bunlar faktiki export və ZIP ölçüsü deyil. Xam 12 sprite üçün mipsiz RGBA təxmini 12 MiB-dir; faktiki GPU yaddaşı ölçülməyib.

`art_source`, `concepts`, `art_reports` `.gdignore` ilə importdan kənardadır. `tests` və dokumentasiya üçün faktiki Web export paketi yoxlanmayıb; Godot-un export preset-ində exclude filter / seçilmiş scene və dependency ilə təsdiqləmək lazımdır: https://docs.godotengine.org/en/latest/tutorials/export/exporting_projects.html . Bu mərhələdə Web build edilməyib. Əlavə altı effekt sadə procedural draw-dur, ayrı böyük tekstura yoxdur. Frame time, physics frame time, zəif cihazda 30/60 FPS və mobil enerji ölçülməyib; heç bir real mobil nəticə iddia edilmir. Əvvəlki 60/120 müqayisəsi wall time və fərqli trayektoriyalardır, CPU benchmark deyil.

## V0.8 Web aralıq statusu
C mərhələsinə başlanmayıb. CI sınağı proqram renderidir və performans benchmarkı deyil; FPS, frame-time, yaddaş, mobil cihaz və compressed HTTP transfer ölçülməyib. İlkin Web export fayl ölçüləri və xəbərdarlıqlar `WEB_QA_REPORT.md`-dədir.

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

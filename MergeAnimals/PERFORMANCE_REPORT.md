# Performans hesabatı — V0.2.1-dev tarixi ölçülər

Headless Linux Actions runner-də 100/150/200-body təcrid edilmiş stress fixture işlədi (`tests/logs/v021-runtime-green.txt`). Run 45662097242 çıxışı FPS=145, physics_seconds=0.000166/0.000397/0.001272, static_bytes=34025047/35457767/37069767 bildirir; bunlar həmin anda Godot monitor snapshotlarıdır, benchmark, cihaz RAM-ı və ya normal gameplay deyil. Merge və danger deaktiv idi; escaped=0. Mobil cihaz, real gameplay frame-time/FPS/RAM, Web və enerji sərfi ölçülməyib. Dolu sahədə pending merge axtarışı profiler ilə ölçülməlidir; heç bir mobil performans hədəfi təsdiqlənməyib.

V0.3.0-dev 120 Hz: 100 bot işlədilib, amma mobil CPU, FPS, enerji və RAM ölçülməyib. Əvvəlki snapshotlar 60 Hz və başqa versiyaya aiddir, müqayisəli benchmark deyil.

## V0.4.1 DEV: fayl və ölçmə məhdudiyyəti
2026-11-25 yerli fayl cəmləri: 12 PNG 3,608,716 byte, 3 SVG fon 3,318 byte, 20 SVG ikon 5,252 byte, 8 Theme 19,013 byte. 12 × 512 × 512 × 4 = 12,582,912 byte (12 MiB) mipsiz xam RGBA tekstura baza səviyyəsinin nəzəri yuxarı təxmini; faktiki GPU/textura import formatı və mipmap-lar ölçülməyib. Mənbə şəkilləri `.gdignore` altındadır; Web export yoxlanmayıb.

GitHub Actions `8eefda7` headless, 4 eyni seed-li bot ssenarisi, 90 simulyasiya saniyəsi üçün: 60 Hz `BOT_COMPLETE wall_seconds=4.513`, 120 Hz `7.850`. Bu bir runner-də proqramın ölçdüyü toplam wall time-dır, CPU time deyil və fərqli trayektoriyalar var; 120/60 təxminən 1.74×, cihaz, istifadə, təkrar, enerji və statistik nəzarət yoxdur. Software render frame time və physics frame time profillənməyib; bu dəyərlər və real mobil FPS/CPU/enerji naməlumdur. Physics 9.190 px risk qalır.

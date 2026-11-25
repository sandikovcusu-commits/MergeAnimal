# Performans hesabatı — V0.2.1-dev tarixi ölçülər

Headless Linux Actions runner-də 100/150/200-body təcrid edilmiş stress fixture işlədi (`tests/logs/v021-runtime-green.txt`). Run 45662097242 çıxışı FPS=145, physics_seconds=0.000166/0.000397/0.001272, static_bytes=34025047/35457767/37069767 bildirir; bunlar həmin anda Godot monitor snapshotlarıdır, benchmark, cihaz RAM-ı və ya normal gameplay deyil. Merge və danger deaktiv idi; escaped=0. Mobil cihaz, real gameplay frame-time/FPS/RAM, Web və enerji sərfi ölçülməyib. Dolu sahədə pending merge axtarışı profiler ilə ölçülməlidir; heç bir mobil performans hədəfi təsdiqlənməyib.

V0.3.0-dev 120 Hz: 100 bot işlədilib, amma mobil CPU, FPS, enerji və RAM ölçülməyib. Əvvəlki snapshotlar 60 Hz və başqa versiyaya aiddir, müqayisəli benchmark deyil.

# V0.8.1.1 — Web QA xülasəsi

Əhatə yalnız Undo, Remove, Rescue, Game Over, sessiya saxlama/yükləmə, Continue və istifadə limitləridir. Faktiki Godot 4.7.2 release Web export Chromium və Firefox-da HTTP üzərindən, ayrı persistent test profillərində işlədilib. Tam metod, dəqiq nəticələr, fixture və bağlanma riskləri: [WEB_POWERUP_REPORT.md](WEB_POWERUP_REPORT.md).

- Undo/Remove və istifadə edilmiş limitlərin refresh və tam profil reopen sonrası bərpası: [Web CI 45856491387](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45856491387), 42 check, 0 failure; immediate-close nəticələri assertion deyil.
- Real fizika Game Over və Rescue, pending Game Over-un refresh/Continue bərpası, Rescue sonrası refresh və reopen: [Web CI 45858334711](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45858334711), 24 check, 0 failure. **Game Over lövhəsi hazırlanmış və tainted/ineligible test fixture-idir**, təbii oyun deyil.
- Təbii Game Over sınağı [45847826869](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45847826869) uğursuz: Game Over alınmadı; təbii dolma/Rescue PASS deyil.
- Dərhal səhifə bağlanarkən son əməliyyatın IndexedDB-yə keçməsinə zəmanət yoxdur. Real cihaz, digər browser-lər, storage failure/eviction və müxtəlif tab ssenariləri yoxlanmayıb.

Heç bir SDK, monetizasiya, audio dəyişməsi və ya Web performans işi bu sınağın hissəsi deyil. Mövcud kommersiya hüquqları və digər əvvəlki release riskləri qalır.
- [Birləşmiş Web CI 45858257485](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45858257485): `WEB_POWERUP checks=64 failures=0`, mənbə `b6e69c0`; çatdırılan Web test build-i bu run-dan götürülüb. Sonrakı `76337f7` yalnız test skriptinə Game Over-dan əvvəl refresh ssenarisini əlavə edir; həmin ssenari ayrıca yuxarıdakı 45858334711 run-da keçib.

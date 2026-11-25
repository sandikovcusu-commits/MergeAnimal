# QA / xəta hesabatı — V0.2.0-dev, 25 noyabr 2026

## İcra edilmiş testlər
- **PASS, statik:** `python3 tests/unit/check_project.py`: 19 Godot mətn faylı və `res://` yolları / əsas layihə konfiqurasiyası.
- **PASS, statik:** `python3 tests/unit/test_static_contract.py`: 12 `unittest` (ID/level/radius/mass/material/score, səhnə istinadları, divar konfiqurasiyası, paylaşılan vizual, collision monitor, input setting və düymə mövcudluğu).
- **PASS, sintaksis:** `gdtoolkit` parser GDScript mənbə/test fayllarını qəbul edib; bu Godot-un semantic parseri deyil.
- **PASS:** `git diff --check` icra edilib. Faktiki çıxış `tests/logs/day2-static.txt`.
- **UNVERIFIED:** Godot import/F5, GDScript semantic/runtime, fizika, input, UI, real kontakt, pause, restart, 100 drop, 100/150/200 stress, FPS/RAM və 5 gameplay screenshot. `day2_suite.gd` və physics skriptləri **hazırlanıb, icra edilməyib**. 35 mənalı runtime yoxlamasının icra tələbi ödənməyib. Birinci günün smoke skripti yeni suite-ə yönəldilir; heç bir nəticə iddia edilmir.
- **BLOCKED:** 18 screenshot faylı bu söhbətdə yoxdur; `SCREENSHOT_AUDIT.md` hər biri üçün gözləmə vəziyyətini göstərir.

## Mühit bloklayıcısı
`godot` və `godot4` PATH-da yoxdur. Rəsmi 4.7.2 GitHub yükləməsi `objects.githubusercontent.com` hostuna yönləndirilir və `SSL_ERROR_SYSCALL` ilə alınmır. Bu turn-də saatlarla mühərrik yığılmayıb. Əvvəlki faktiki commit uzaqda `a2692b8`; checkout snapshot-ı həmin commit ilə hash müqayisəsində eyni idi. Bu, layihənin işlədiyinə dəlil deyil.

## Bug protokolu

### BUG-001 — merge yoxdur (P0)
- Screenshot Evidence: 18 şəkil əlçatan deyil; istifadəçinin mətn təsviri müstəqil yoxlanmayıb.
- Reproduction Steps: V0.1-də eyni növ iki cismi yanaşı düşür. Affected: köhnə `Game.gd:70–82`, `Animal.gd:8–18`; köhnə səhnədə merge callback yox idi.
- Root Cause / Evidence: a2692b8-də obyekt yaradılıb, lakin eyni növləri birləşdirən heç bir sistem/signal bağlantısı yox idi.
- Applied Fix: `scripts/managers/MergeManager.gd:14–67` `body_entered`, iki lock, deferred commit, score signal; `scripts/gameplay/Game.gd:199–235` spawn və score; `scenes/game/Game.tscn` beş resource.
- Before: kodda merge yox idi. After: kod yazılıb, **runtime UNVERIFIED**. Regression: `tests/integration/day2_suite.gd` və `tests/physics/natural_collision.gd` hazırlanıb, icra edilməyib. Remaining Risk: sıx kontaktlarda callback, pending, overlap, zəncir və sürət real test tələb edir.

### BUG-002 — preview/spawn üst-üstə görünmə (P1)
- Screenshot Evidence: mövcud deyil. Reproduction Steps: V0.1-də sürətli ardıcıl drop və fərqli radiuslu növbəti preview. Affected: köhnə `Game.gd:70–82,87–97`.
- Root Cause / Evidence: kod fiziki obyekt yaranan kimi yeni preview-ni eyni spawn koordinatında çəkirdi, overlap yoxlaması yox idi. Bunun konkret şəkildəki yeganə səbəb olduğu sübut edilməyib.
- Applied Fix: `scripts/gameplay/Game.gd:85–102,114–120,163–198`, `_physics_process`, `_set_aim`, `drop_animal`, `_spawn_clear`, `_attempt_drop`; ayrıca vizual node və fizika-tick query/cooldown.
- Before: overlap qorunması kodda yox idi. After: **UNVERIFIED**. Regression: `day2_suite.gd` blocked/cooldown checks hazırlanıb, icra edilməyib. Risk: fizik server sinxronluğu, divar marjası və cihaz inputu yoxlanmalıdır.

### BUG-003 — preview üz uyğunsuzluğu (P2)
- Screenshot Evidence: mövcud deyil. Reproduction Steps: V0.1 cari preview-ni fiziki cisimlə müqayisə et. Affected: köhnə `Game.gd:93–97`, `AnimalVisual.gd:4–17`.
- Root Cause / Evidence: preview ayrı sadə dairə, fiziki body isə ayrıca göz və ağız çəkirdi; next yalnız text idi.
- Applied Fix: `scripts/gameplay/AnimalVisual.gd:4–21`, `Animal.gd:11–23`, `Game.gd:299–311`; səhnədə iki visual node.
- Before: kod mənbələri fərqli idi. After: resurs paylaşımı statik yoxlandı, görünüş **UNVERIFIED**. Regression: static contract pass; vizual screenshot yox. Risk: sprite ölçüsü/render sırası Editor-də təsdiqlənməlidir.

### BUG-004 — game over yoxdur (P0)
- Screenshot Evidence: yoxdur; statik şəkil davametmə müddətini sübut edə bilməz. Reproduction Steps: V0.1-də heyvanları xəttin üstündə sabit saxla. Affected: köhnə `Game.gd:92` yalnız xətt çəkirdi.
- Root Cause / Evidence: danger monitor, timer və game-over yox idi.
- Applied Fix: `scripts/managers/DangerMonitor.gd:6–37`, `scripts/gameplay/Animal.gd:26–32`, `scripts/gameplay/Game.gd:259–294`.
- Before: xətt yalnız vizual idi. After: dəstək, sürət və 2 s grace ilə kod yaradılıb, **UNVERIFIED**. Regression: `day2_suite.gd` monitor logic fixture hazırlanıb, icra edilməyib. Risk: normal istiqaməti, sleep və gerçek bounce test edilməyib.

### BUG-005 — həddindən artıq dolma (P1)
- Screenshot Evidence: yoxdur. Reproduction Steps: V0.1-də ardıcıl drop et. Affected: köhnə `Game.gd:70–97` və çatışmayan merge/game-over sistemləri.
- Root Cause / Evidence: merge və game-over olmadığından cismlər mexaniki olaraq yığılırdı; konkret təsvirin səbəbi müstəqil təsdiqlənməyib.
- Applied Fix: BUG-001/002/004 kod dəyişiklikləri; normal oyunda məqsədsiz silmə yoxdur.
- Before: idarə olunan merge/sonlanma yox idi. After: **UNVERIFIED**. Regression: 100 drop və 100/150/200 stress skriptləri icra edilməyib. Risk: CPU, yaddaş və escape məlum deyil.

### BUG-006 — cari və növbəti uyğunluğu (P1)
- Screenshot Evidence: yoxdur. Reproduction Steps: drop/cooldown/blocked spawn zamanı queue izlənməsi. Affected: köhnə `Game.gd:70–85`.
- Root Cause / Evidence: current və next fərqli dəyişən idi, amma next vizualı yox idi, uğursuz overlap drop anlayışı yox idi.
- Applied Fix: `scripts/gameplay/Game.gd:163–198,299–311`; `AnimalVisual.gd:4–21`. Queue yalnız uğurlu creation sonrası dəyişmək üçün kodlaşdırılıb.
- Before: next yalnız ad göstərirdi. After: **UNVERIFIED**. Regression: `day2_suite.gd` fixture mövcuddur, icra edilməyib. Risk: semantic/runtime və mövcud input emulation yolları yoxlanmayıb.

## Növbəti addım
Godot 4.7.2 quraşdırılmış mühitdə README-dəki bütün əmrləri, cihaz testlərini və 35+ mənalı runtime ssenarisini icra edib log/screenshot təqdim edin; uğursuzluqları düzəldib regression testləri təkrarlayın. 18 screenshot-u əlavə edin. Uğurlu faktiki nəticələr olmadan bu mərhələ və release tamamlanmış hesab edilmir.

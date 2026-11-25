# Fizika hesabatı — Gün 2, UNVERIFIED

Godot mühərriki bu sessiyada mövcud deyildi, ona görə heç bir fizika parametri ölçülməyib və dəyişikliklər optimallaşdırma kimi təqdim edilmir. V0.1 baseline runtime ölçüsü yoxdur. `Animal.tscn`: RigidBody2D, `contact_monitor=true`, 8 contact, CCD ray mode, layer/mask 1; `Game.tscn` StaticBody2D divar/döşəmə layer/mask 1. Godot 4.7 default gravity scale/ticks/damping/sleeping saxlanıb; AnimalData-dan mass, friction 0.5 və bounce 0.1. Radius: 18/23/29/35/42.

`MergeManager.gd`: eyni ID və level üçün iki body callback zamanı lock edilir; silinmə/yaradılma deferred, xal bir dəfə `merged` signalı ilə. Orta nöqtə sahəyə clamp edilir; digər dairələrin içində yaranmamaq üçün maksimum 96 px radiusda uyğun mövqe axtarılır, tapılmasa cüt saxlanır. Davranış və performans ölçülməyib.

`Game.gd`: spawn sorğusu fizik tick-də `PhysicsDirectSpaceState2D.intersect_shape` ilə, 2 px divar marjası; cooldown zamanı preview gizlənir. `DangerMonitor.gd`: heyvanın yuxarı kənarı xətti keçdikdə, dəstək normalı, aşağı sürət və 2 saniyə davamlılıq nəzərdə tutulur. Normalın istiqaməti, sleep zamanı davranışı və sərt sıxlıq real physics engine testini tələb edir.

Stress skriptləri `tests/physics/stress.gd` (sabit 100/150/200 obyekt; merge/danger sırf testdə bağlı) və `drop_100.gd` (100 ayrı drop, test fixture təmizlənməsi) hazırlanıb, **icra edilməyib**. FPS, physics frame time, memory, escape sayı, duplicate merge, runtime errors və 5 gameplay screenshot nəticələri yoxdur. Headless FPS/GPU nəticələri mobil cihaz performansına ekvivalent deyil. Normal rejimin Game Over qaydası stress üçün dəyişdirilməyib.

Mənbələr: [RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html), [DirectBodyState2D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectbodystate2d.html), [Physics introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html), [DirectSpaceState2D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html), [Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html).

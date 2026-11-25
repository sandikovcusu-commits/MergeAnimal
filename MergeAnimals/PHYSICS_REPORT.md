# Fizika hesabatı — V0.2.1-dev

Godot 4.7.2.stable official Linux GitHub Actions runner, headless; vizual və mobil nəticə deyil. Ətraflı dəyişməz çıxış `tests/logs/`-da, bütün nəticələr `TEST_RESULTS.txt`-dədir.

- Mouse cütü real collision callback ilə 1 Hamster və 4 xal verdi; üç Mouse real kontakt chain ilə 1 Rabbit, 12 xal, 2 merge, pending 0 verdi. Suite digər səviyyələri və lock qaydalarını manager çağırışları ilə yoxlayır; bütün səviyyələr real kontaktla yoxlanmayıb.
- Real 48-body qalaqda support və 2.017 s grace sonrasında Game Over, əlavə spawn bloklanması; real body üzərində pause və resume keçdi. Düşən/timer reset halları suite ilə yoxlandı, bütün sıçrayış və sleep halları yoxlanmayıb.
- 100 spawn fixture hər spawn sonrası body-ni silir. Stress fixture-də 100/150/200 body, escaped=0; merge, danger söndürülür və lock edilir. Bunlar real dolu gameplay və aktiv merge performansı deyil. CI FPS/physics/memory rəqəmləri yalnız runner və həmin fixture üçündür, mobil FPS/RAM deyil.
- 700 px/s horizontal impact testində 60 Hz ray CCD üzrə sol -0.664, sağ -6.636, döşəmə -0.506 px minimal kənar məsafəsi ölçüldü; mənfi dəyər anlıq radiusun səthə nüfuzudur, bütün cismin escape etməsi deyil. 10 px diaqnostik tolerantlıqla sınaq hazırlanıb; sıfır nüfuz sübut deyil. 120/240 Hz və shape CCD alternativlərinin heç biri ilkin ±2 px kriteriyasını hər yerdə ödəmədi; nəticələr `v021-ccd-ticks.txt`. Vizual/real cihazda və daha geniş sürət diapazonunda ölçmək lazımdır.
- `Game.tscn` divarları StaticBody2D; `Animal.tscn` RigidBody2D; CircleShape2D radiusu AnimalData resource-dan təyin edilir. Fizika materialları balans və mobil yük baxımından ölçülməyib. Normal oyunda qüsuru gizləmək üçün obyekt silinmir; yalnız uğurlu merge iştirakçıları əvəzlənir.

# QA hesabatı — V0.2.1-dev

## Faktiki mühit və nəticə
Rəsmi Godot Engine **4.7.2.stable.official.ed1daf0bf**, Ubuntu GitHub Actions, headless. Run [45662097242](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45662097242), kod commit `ff652c0`: import və bütün skriptlər exit 0. Tam log `tests/logs/v021-runtime-green.txt`. Bu, renderli Editor/F5 və mobil/Windows testi deyil. Lokal sandbox-da rəsmi binary CDN-ə bağlantı alınmadı, Actions runner uğurlu oldu. 18 V0.1 JPG ayrı-ayrı araşdırılıb, audit ayrıca saxlanır.

## Faktiki regression sınaqları
`day2_suite.gd`: **49 yoxlama, 0 failure** — dörd səviyyə üzrə merge və score, fərqli səviyyə, 3/4-body reservation, chain, divar/floor merge mövqeyi, aim clamp, spawn/queue/cooldown/preview, canceled touch, emulated mouse, blocked spawn, danger monitor və pause/resume. Bunların böyük hissəsi birbaşa metod/fixture testidir, avtomatik olaraq hardware və real collision testinə bərabər deyil.

Əlavə Godot testləri: təbii mouse pair → hamster; real üç-body mouse→hamster→rabbit; blocked cooldown sonrası touch/mouse sürətli tap 4 yoxlama; multitouch və kənarda buraxma 4 yoxlama; səhnə restart; real bədən pause/resume; 48-body support overflow və əlavə spawn qadağası; 100 təcrid edilmiş spawn; 100/150/200-body stress; 700 px/s divar/döşəmə diaqnostikası. Run çıxışında PASS və exit statusları ayrıca verilib. 49 yoxlama minimum 35 mənalı test tələbini aşır, lakin hər biri müstəqil cihaz sınağı deyil.

Quick-tap düzəlişi əvvəl red run [45660478538](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45660478538) (dörd gözlənilən FAIL), sonra green [45660780424](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45660780424) (dörd PASS) ilə sübut olunub. `ROOT_CAUSE_REPORT.md` səbəb və sətirləri xəritələyir.

## Məhdudiyyət və risk
- Divar sınağının 10 px tolerantlıqla PASS olması sıfır overlap deyil; 60 Hz-də 6.636 px-ə qədər ani nüfuz ölçülüb. Fizika hesabatına baxın.
- Stressdə merge/danger söndürülüb; 100-drop test fixture hər spawn sonrası body silir. Bu normal oyun davranışı və aktiv merge stressi deyil.
- Windows skriptləri hazırlanıb, Windows-da çalışdırılmayıb. Android/iOS, touch hardware, real mouse GUI, F5/render, vizual screenshot, ekran ölçüləri, focus loss, tam fizika sıçrayışı, real cihaz FPS/RAM və Web yoxlanmayıb. Testlər synthetic input istifadə edir.
- Placeholder qrafika mövcuddur; yeni sprite hazırlanmayıb. Mərhələ DEV olaraq qalır, yekun kommersiya oyunu deyil.

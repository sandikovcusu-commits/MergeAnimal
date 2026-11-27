# V0.9.0.3 — Fizika auditi (private, tamamlanmamış)

Baza `b79dd4d`, Godot 4.7.2; layihənin fizika kodu dəyişdirilməyib. 1–2 px qəbul hədəfi ödənmir. Bu, düzəldilmiş fizika relizi deyil: riskli davranış dəyişikliyi sınaqların nəticəsi və insan feel qiymətləndirməsi olmadan qəbul edilmədi. Native Godot və real WebAssembly ölçmələri ayrı saxlanır.

## Kod, səbəb və qərar

| Yer | Tapıntı / səbəb | Düzəliş / qərar |
|---|---|---|
| `scenes/animals/Animal.tscn:5–12`, `scripts/gameplay/Animal.gd:18–29` | 12 RigidBody2D, hər biri yeni radiuslu CircleShape2D; layer/mask 1; ray CCD, 8 contact. Yüksək sürətli düşmənin diskret addımında səthə 9.190 px daxilolma ölçüldü. CCD bu göstərici üçün təminat deyil. | Shape CCD və iki proqnozlaşdırıcı bound yalnız test nüsxəsində sınandı; 1–2 px ümumi hədəf və feel təsdiqlənmədiyindən tətbiq olunmadı. Daha yaxşı sabit təmas həlli araşdırılmalıdır. |
| `scripts/gameplay/AnimalData.gd:7–13`, `resources/animals/*.tres`, `Animal.gd:23–29` | Radius 18–125, kütlə 0.8–9.8, friction 0.5, bounce 0.1, linear/angular damping 0; xüsusi gravity override yoxdur (engine/project default). Bu parametrlərin ayrı-ayrılıqda kök səbəb olması sübut edilməyib. | Kütlə və materialları özbaşına dəyişmədik; yüksək/kicik qarışıq sıx yığın və cihazlarda ayrıca test lazımdır. |
| `project.godot:31` | 120 physics Hz. Daha az addım bəzən daha böyük penetration yaradır; FPS və CPU ayrıca browser/runner təsirindən asılıdır. | 120 Hz saxlanır; alternativlərin obyektiv üstünlüyü sübut edilməyib. |
| `scenes/game/Game.tscn:27–34,41–55`, `Game.gd:6–10` | Statik 32 px divarlar və döşəmə; daxili kənarlar 91, 629 və 1094 ilə uyğun gəlir. Başlanğıc nüfuzolması, yığınlarda pair overlap və bəzi ekstremal künc halları qalır. | Ölçülən nüfuz hesabatda açıq göstərilir. Tam escape aşkar edilməməsi tunneling-in heç vaxt olmayacağı demək deyil. |
| `MergeManager.gd:26–42,45–85` | Eyni body callback-də sinxron kilidlənir; commit deferred; yer yoxdursa pair pending qalıb retry edir. | Mövcud duplicate qorunur; davamlı sıxlıqda pending-in hədsiz gecikməsi mümkündür, real oyun və edge-case testi lazımdır. |
| `Game.gd:691–738,758–780` | Spawn shape yoxlaması və 0.5 s cooldown; merge replacement radius + 1 px boşluqla məhdud dairəvi axtarılır. | Məkan tapılmayan pair-i silməmək mövcuddur, lakin tam dolu və böyük heyvan oyunu üçün tamamlanmış zəmanət deyil. |
| `Animal.gd:33–42` | Support kontakt normalından alınır; yan divar support sayılmır. Sıx yığında ölçülən overlap cütlər üçün 8.68 px-ə çatdı. | Jitter, sıxılma və uzunmüddətli sabitliyi insan/device sınağı ilə qiymətləndirin. |

## Native müqayisə
100 eyni seed, hər seed ən çox 90 simulyasiya saniyəsi; max/orta boundary overlap, px; ölçülən tam escape frame 0. Shape CCD ayrıca runner, CPU müqayisəsi nəzarətli deyil.

| Hz | ray baseline max / orta | shape CCD max / orta |
|---:|---:|---:|
| 60 | 16.678 / 14.052 | 18.885 / 18.542 |
| 90 | 8.049 / 7.331 | 9.661 / 8.865 |
| 120 | 9.190 / 8.950 | 9.190 / 8.915 |

120 Hz predictive-floor: 7.372 max, 2.926 orta, median 2.7365, 3832 merge; predictive-bounds: 8.359 max, 2.702 orta, median 2.4445, 3948 merge. Baseline 3967, shape 4154 merge. Bunlar fərqli trajetkoriyalardır və həmin müvəqqəti test patch-ləri production deyil. Floor guard 12 tək drop testində maksimum 0.068 px etsə də 40-body pile floor 6.033 və pair 8.322 px; ümumi problemi həll etmir. 120 Hz baseline/shape/floor/bounds CPU user saniyəsi 214.46/328.32/197.65/287.13; fərqli CI runner-ləri olduğundan güclü performans nəticəsi çıxarmaq olmaz. Raw seed CSV və fixture logları `docs/physics/experiments/`.

BEFORE və AFTER CSV-ləri eyni baza ölçməsini daşıyır: production physics dəyişmədiyi üçün AFTER müstəqil yeni ölçmə deyil. Təcrübələr ayrıca etiketlənib. Run [45982547862](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45982547862), floor [45983395327](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45983395327), bounds [45984336631](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45984336631). Sonuncu job parse xətalı əlavə diaqnostika səbəbindən failed; əvvəl tamamlanmış 100-seed nəticəsi saxlanıb. Düzəldilmiş diaqnostika və native CI [45984973896](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45984973896) success; əvvəlki 120-Hz job uğursuzluqları silinməyib.

## Web benchmark
15 s, bir təkrar, software rendering, fixed-count fixture, merge disabled; fiziki cihaz və gameplay FPS-i deyil. Chromium 40 body baseline 60/90/120 Hz 35.46/49.87/51.21 FPS, p95 təxminən 33.4 ms; Firefox 120/40 59 FPS, p95 17.1 ms. Chromium 120/10 və /20: 53.42 və 40.05 FPS. Ayrı eksperimental bounds Chromium 120/40/10/20: 44.15/56.67/50.49 FPS, Firefox 120/40 59.00 FPS; ayrı runner və tək sample, səbəbli performans müqayisəsi deyil. Browser CPU bütün proseslərdə toplamdır, 100%-i keçə bilər. Feel qiymətləndirilməyib.

## Regres və məhdudiyyətlər
Native suite son run-da uğurludur. Əvvəlki baza Web Chromium/Firefox save testləri 52/52; power-up 66/66, reward mock 68/68. Bunlar bu fizika işindən əvvəlki nəticələrdir; real reklam, cihaz toxunuşu, səs dinləmə, bütün 20 challenge və 15 achievement üçün insan yoxlaması deyil. Natural game-over, post-Rescue, böyük/kiçik əzilmə, künclər, chain/golden, çoxlu eyni vaxtlı merge və oyun hissi üçün əhatə tamamlanmış deyil. Ani bağlanma/IDB məhdudiyyətləri əvvəlki hesabatlarda qalır. Commercial status BLOCKED.

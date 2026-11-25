# QA hesabatı — V0.3.0-dev

## Faktiki icra
Baza `ebd434c` [45664927879](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45664927879): rəsmi Godot 4.7.2.stable Linux headless, 49/49, bütün addımlar exit 0. Gün 3 `fbcb4ca` [45665893612](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45665893612): əvvəlki **49/49**, yeni **57/57**; real 11 evolution və iki Elephant Golden collision, 100 seeded bot və physics matrix işlədi. Xam nəticə `tests/logs/v030-runtime-fbcb4ca.txt`.

Köhnə 49 test eyni check-ləri saxlayır; əvvəlki base-score müqayisələri üçün fixture-də `combo_enabled=false` seçilib. Yeni suite default açıq combo-nu ayrıca yoxlayır. 49+57 mənalı assertion minimum 79-u keçir; bu say GUI və cihaz yoxlamaları deyil. Run 45666836718: köhnə 49/49, yeni 61/61; əlavə nonzero high-tier ağırlıq və golden dublikat/resource testləri keçdi. `day3_suite.gd` həm real collision, həm də birbaşa metod/resource yoxlamaları ehtiva edir. Spawn 10000 (seed 13579), Golden duplicate pair lock, combo və timeout yoxlamaları logdadır.

100 bot normal game logic/physics işlədir, lakin proqram strategiyaları real insan davranışı deyil; time-cap, oyun sonu, seed və göstəricilər CSV-dədir. Debug stress və 100-drop digər fixture-ləri merge/danger söndürür və ya test body-lərini təmizləyir; normal oyun onları silmir.

## Əhatə boşluqları
Real telefon touch, Windows BAT, GUI/F5, vizual screenshot, 6 ekran ölçüsündə real render/input, kiçik ekran guide oxunaqlılığı, Web export və mobil FPS/RAM yoxlanmayıb. 512×512 alpha konsept törəmələri var, lakin təmizləmə/qrafik keyfiyyəti və yekun sprite-lar təsdiqlənməyib. Uzunmüddətli insan balansı və riskli çox sıx merge halları təsdiqlənməyib. 60 Hz normal bot oyunlarında 16.678 px, 120 Hz-də 9.190 px-ə qədər floor/boundary overlap, stressdə ayrıca nüfuz qalır; `PHYSICS_REPORT.md`.

## Təhvil statusu
Bu DEV namizədidir, mobil və vizual qəbul yekun deyil. Hər problem və regression xəritəsi `ROOT_CAUSE_REPORT.md`-də, bot metodologiyası `BALANCE_REPORT.md`-dədir.

120 Hz test run 45668965282: köhnə 49/49 və yeni 61/61, 100 bot işləsə də 100-drop fixture 99/99 ilə FAIL idi. Sabit 60 Hz frame fərziyyəsi aradan qaldırılıb; sonrakı [45670121999](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45670121999) run-da 100/100 PASS, köhnə 49 və yeni 61 yoxlama da PASS oldu. Mobil 120 Hz CPU/batareya testi yoxdur.

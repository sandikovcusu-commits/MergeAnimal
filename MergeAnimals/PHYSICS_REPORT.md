# Fizika hesabatı — V0.3.0-dev

## Tarixi və metod
V0.2.1 real runner-də 700 px/s iki fərqli body + gravity ssenarisində sağ radius gap **-6.636 px** (bir anda), sol -0.664, floor -0.506 ölçülmüşdü. Bu bütöv cismin divardan çıxması deyildi; neçə kadr davam etməsi o testdə qeydə alınmamışdı. 10 px tolerantlıq sıfır nüfuz demək deyildi və Gün 3-də overlap PASS kimi istifadə edilmir.

`tests/physics/day3_wall_matrix.gd` sağ divara izolyasiya olunmuş horizontal zərbə: gravity=0, 3 s, ray/shape/disabled CCD, 60/120/240 tick, 32/64 px divar, 120/700 sürət, bounce 0/0.1/0.5, radius 14.4/18/42/125. Dərinlik dairə səthi ilə daxili divar arasındakı maksimum həndəsi fərq, ayrıca 0.01 px-dən böyük overlap frame sayı və ən uzun ardıcıl streak ölçülür. Bu fərqli test quruluşu olduğundan rəqəmlər V0.2.1-lə birbaşa düzəliş effekti kimi müqayisə olunmur. `tests/logs/v030-runtime-fbcb4ca.txt` xam nəticədir.

| Ssenari, 60 Hz / 32 px divar | Maks dərinlik | overlap frame / ardıcıl | Tam escape / stuck |
|---|---:|---:|---|
| Mouse r18, 120 px/s, disabled/ray/shape | 0.081 px hər üçü | 1 / 1 | yox / yox |
| Mouse r18, 700 px/s, disabled/ray/shape | 0.804 / 0.360 / 0.804 px | 1 / 1 | yox / yox |
| Dog r42, ray, 120 / 700 | 0.090 / 2.293 px | 1 / 1 hər biri | yox / yox |
| Elephant r125, ray, 120 / 700 | 0.400 / 5.909 px | 2 / 2 hər biri | yox / yox |
| Mouse r18, ray, 700, bounce 0 | 0.360 px | 158 / 158, son 0.300 px | yox / yox, test kriteriyası üzrə |
| Mouse r18, ray, 700, divar 64 | 0.360 px | 1 / 1 | yox / yox |

Mouse ray 700-də 120 və 240 tick müvafiq 0.911 və 0.964 px; bu fixture daha yüksək tickin ölçülmüş pik nüfuzu azaltmasını göstərmir. r14.4-də 0.288 px; bounce 0.5-də 0.360 px/1 frame. Bütün cisim divar arxasına keçməyib; matrix `stuck` üçün test sonunda >2 px overlap və |vx|<1 px/s şərtini işlədib, bu bütün ilişmə tiplərini əhatə etmir. Bounce 0 ilə kiçik qalıq overlapın 158 frame davam etməsi xüsusilə qeyd edilməlidir.

Merge spawn mövqeyi `Game.gd:247–267` ilə radius üzrə daxili sahəyə clamp və digər cisimlərdən boşluq yoxlaması edir; əvvəlki suite divar/floor placement yoxlamaları və Gün 3 real collision testləri keçib. Bütün dolu sahə/geometriya ssenariləri sübut deyil. Daimi teleport və ya məcburi mövqe dəyişməsi istifadə olunmayıb. İstehsal fizika tezliyi 60-dan 120 Hz-ə qaldırıldı; material və radius dəyişmədi. Bu, seçilmiş bot nümunəsində pik nüfuzu azaltdı, lakin bütün ssenarilərdə azalmanı və sıfır nüfuzu təmin etmir; ikiqat tick-in mobil CPU/batareya təsiri ölçülməyib. Normal renderdə görünən effekt və insan gameplay-i yoxlanmayıb.

## Normal oyun botlarında daha yüksək sürət
Run [45666836718](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45666836718), `71016a8`: 100 botun real normal spawn/merge/danger ssenarilərində maksimum radius-sərhəd overlap **16.678 px**, 0 tam escape-frame. Ən uzun `>0.01 px` eyni body streak **5326 frame** (~88.8 s/60 Hz); bu say bütün kadrların 16.678 px olduğu demək deyil, çox kiçik daimi kontakt nüfuzlarını da sayır. Dərinliyin zaman profili tam saxlanmayıb. Run [45667541539](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45667541539) ilə ilk dörd seed-də maksimum Cat radius 35, y=1075.678, şaquli sürət 1138 px/s və floor=1094 oldu. Bu, əvvəlki 120 px/s izolyasiya sınağının normal sərbəst düşmə sürətini təmsil etmədiyini göstərir. Fiziki nüfuzun GUI-də görünməsi hələ yoxlanmayıb.

Son əlavə matris 60/120/240 Hz-də spawn hündürlüyündən gravity ilə düşməni ayrıca yoxladı (run 45668244551): Mouse 0.360/4.190/1.657 px, Cat 16.678/2.171/4.395 px, Dog 4.712/9.171/1.963 px, Elephant 14.259/0.695/2.787 px; sırayla 60/120/240 Hz. Bu, tək hərəkət trayektoriyalarıdır; bəzi hallarda daha yüksək tick-in də pisi ola bildiyini göstərir. 700 px/s-da Elephant ray 60→120 Hz 5.909→0.264 px, Mouse isə 0.360→0.911 px oldu: effekt ölçüyə və ilkin mövqeyə bağlıdır; bu təkcə bütün normal oyun üçün zəmanət deyil. Floor 700 px/s: Mouse 0.360, Dog 9.958, Elephant 5.283 px; bütün body escape müşahidə edilmədi. 120 px/s floor ölçülərində 0 px. Tam floor/collision nəticələri `v030-runtime-71016a8.txt`-dədir.

## 120 Hz sonrası real bot nəticəsi
Run [45670121999](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45670121999) 100 botda 120 Hz, eyni 30000–30099 seed və 90 s cap ilə maksimum overlap **9.190 px**, 0 tam escape-frame; 60 Hz-də eyni testin piki 16.678 px idi. 120 Hz-də >0.01 px üzrə ən uzun tək body streak 10623 tick ≈88.5 saniyədir (pik boyu deyil, resting contact nüfuzunu da daxil edir); 60 Hz 5326 tick ≈88.8 saniyə idi. 120 Hz bütün rəqəmləri eyni davranışlı trajektoriya kimi qəbul etmək olmaz: fizika dəyişdiyi üçün yığınlar da fərqlənir. Rəqəmlər headless-dir, insan/vizual təsir deyil. 120 Hz daha yüksək CPU yükü ola bilər; mobil cihazda sınanmadan keyfiyyət/performance qəbul edilmiş deyil.

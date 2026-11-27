# V0.9.0.4 — animation checkpoint

`AnimalVisual.gd`: təsadüfi fazalı nəfəsalma qalıb; bütün-sprite blink squash əvəzinə təsadüfi 3–8 s interval və 0.12–0.18 s qapalı göz frame seçimi var. Merge/Happy və Drop/Surprise xüsusi üz kadrını seçir; landing normal üzü istifadə edir. Action tween mövcud miqyasdan 70 ms easing ilə hədəfə keçir və 220 ms-də geri qayıdır. Köhnə tween yenisi başlamazdan öldürülür, node exit-də öldürülür; Reduced Effects tween və blink-i sıfırlayır və process-i dayandırır. Fiziki body/shape scale dəyişmir.

12 heyvanın frame selection, reduced reset, radius/mass invariants testləri [46051133821](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051133821) keçdi. Əvvəl [46050658377](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46050658377) 10 müqayisədə float dəqiqliyi ilə strict mass equality səbəbilə failed; `is_equal_approx` ilə düzəldildi, uğursuzluq gizlədilmir. 12 statik üz nümunəsi [native fixture](docs/visual/v0904/after/native-expression-fixture-thumbnail.jpg).

Bu, tam modul body/eye/pupil/eyelid/mouth/ear rig deyil: bütün expression-lar raster facial-frame variantlarıdır, animator redaktəsi SVG səviyyəsindədir. Continuous eyelid interpolation, ayrı pupil movement, iki heyvanın merge keçidi, xüsusi golden animasiya, insan baxışı və hərəkətli video showcase tamamlanmayıb. Nəfəsalma və bu tween-in bütün edge-case-lərdə hiss keyfiyyəti təsdiqlənməyib.

## Davam: ümumi kosmetik scheduler və golden echo

`97d7b23` 40 ayrıca per-frame kosmetik callback yerinə tək pausable scheduler tətbiq edir; `2595bf6` autoload hələ yaranmamış preload/SceneTree fixture üçün təhlükəsiz fallback əlavə edir. Normal rejimdə fərdi vizuallar qeydiyyata alınır, Reduced Effects və ya silinmə zamanı çıxarılır; pause/davam və 7 lifecycle yoxlaması [46057489877](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46057489877) keçib. Fallback yalnız scheduler mövcud olmayan test kontekstlərində fərdi process istifadə edir. Ölçülmüş sürət üstünlüyü iddia edilmir: bax `PERFORMANCE_REPORT.md`.

`3783810` golden merge zamanı mövcud elephant Happy teksturasını yarımşəffaf, sönən və yuxarı hərəkət edən 0.7 s collision-suz kosmetik echo kimi təkrar istifadə edir. Reduced Effects rejimində echo/shake yoxdur; təcrid olunmuş fiziki iki-elephant collision fixture [46057872423](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46057872423), `docs/visual/v0904/continuation/golden-merge-fixture.png`. İstifadəçinin özü oynamayıb. Ayrı body/eyes/pupils/ears runtime rig və tam motion showcase hələ yoxdur; statik SVG qrupları mövcuddur. Collision shape, mass və production physics tick dəyişməyib.

## Son acceptance işinin sərhədi

Runtime rig mütləq şərt deyil; hazırkı bütün-frame variantları və redaktə olunan SVG-lər saxlanır. Əvvəlki 12/12 frame seçimi və 7/7 scheduler lifecycle hər heyvan üçün bütün hərəkətlərin hərəkətli keyfiyyət yoxlaması, eyni anda uzunmüddətli tween/resource leak testi, ya da merge və score-un bütün kombinasiya testləri demək deyil. Bunlar hələ PARTIAL. Yeni performans izolasiya fixture-i yalnız CI exportuna əlavə olunur; production animasiya kodu və 120 Hz fizika dəyişdirilmir.

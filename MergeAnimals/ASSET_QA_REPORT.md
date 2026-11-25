# Asset QA — V0.4.0-dev / tamamlanmayıb

10/12 normal şəkil: kodla təmizlənmiş 512×512 PNG RGBA; Bear və Lion **MISSING**. Əsl alpha, ölçü və tam kənar yoxlamaları aşağıdadır. 24 happy/surprise şəkli yoxdur; expression seçicisi yalnız infrastruktur səviyyəsindədir. Alpha-ya PASS kommersiya, estetika və collision üçün qəbul demək deyil. Mənbələrdə opak şahmat fonu var idi, 26% fuzz flood-fill ilə çıxarılıb; ağ Rabbit və Panda ağ/qara kompozitdə baxılıb, konturlar və daxili şəffaf boşluqlar üçün peşəkar piksel auditi hələ lazımdır. `art_reports/contact_white_WIP.png`, `contact_black_WIP.png` və `contact_collision_WIP.png` oyun screenshot-u deyil.

| Heyvan | PNG/RGBA/512 | Alpha aralığı | kənar alpha max | bbox | Dairədən kənar alpha>32 (%) | Status |
|---|---|---|---:|---|---:|---|
| mouse | PNG/RGBA/512×512 | [0, 255] | 0 | [6, 11, 506, 502] | 8.95% | WIP; collision və lisenziya BLOCKED |
| hamster | PNG/RGBA/512×512 | [0, 255] | 0 | [32, 6, 481, 506] | 4.40% | WIP; collision və lisenziya BLOCKED |
| rabbit | PNG/RGBA/512×512 | [0, 255] | 0 | [6, 32, 506, 480] | 1.37% | WIP; collision və lisenziya BLOCKED |
| cat | PNG/RGBA/512×512 | [0, 255] | 0 | [8, 6, 505, 506] | 4.36% | WIP; collision və lisenziya BLOCKED |
| dog | PNG/RGBA/512×512 | [0, 255] | 0 | [6, 15, 506, 498] | 6.47% | WIP; collision və lisenziya BLOCKED |
| fox | PNG/RGBA/512×512 | [0, 255] | 0 | [8, 6, 504, 506] | 5.12% | WIP; collision və lisenziya BLOCKED |
| raccoon | PNG/RGBA/512×512 | [0, 255] | 0 | [7, 6, 505, 506] | 7.78% | WIP; collision və lisenziya BLOCKED |
| koala | PNG/RGBA/512×512 | [0, 255] | 0 | [6, 43, 506, 470] | 5.00% | WIP; collision və lisenziya BLOCKED |
| panda | PNG/RGBA/512×512 | [0, 255] | 0 | [20, 6, 492, 506] | 8.26% | WIP; collision və lisenziya BLOCKED |
| bear | MISSING | — | — | — | — | BLOCKED |
| lion | MISSING | — | — | — | — | BLOCKED |
| elephant | PNG/RGBA/512×512 | [0, 255] | 0 | [6, 9, 506, 504] | 1.47% | WIP; collision və lisenziya BLOCKED |

Dairə testi vizual texture düzbucaqlısının mərkəzinə çəkilmiş radius 256 px üzrə alfa>32 olan piksellərin faizidir; bu **Sprite vs CircleShape2D** yaxınlaşmasıdır, real fizika təması testi deyil. Mouse qulaqları, Panda qulaqları və bir neçə quyruq/ayaq dairədən aydın kənara çıxır; cisim divara toxunanda vizual kəsişmə riski var. Koala və başqalarında dairə içində vizual boşluq da görünür. Radiusu və sprite-ı gizlətmək üçün kiçiltmədik. Kəsilməməyə yalnız şəffaf kənarlar və kontakt vərəqində baxış dəstək verir; bütün saç/ətraf orqanlar üzrə incə audit ayrıca tələb olunur.

Üç programmatik vektor fon var; 20 ikon, 8 düymə variantı, 6 effekt və logo hazırlanmayıb. Mövcud `Forest Garden`, `Sunset Safari`, `Snowy Valley` Inspector seçicisi DEV-dir; UI/menyu dizaynı yekun deyil. Mənbə modeli və kommersiya şərti **təsdiqlənməyib** (`ASSET_MANIFEST.json`, `MODEL_AUDIT.md`). Runtime istifadə DEV test məqsədlidir, kommersiya buraxılışı qadağan statusundadır.

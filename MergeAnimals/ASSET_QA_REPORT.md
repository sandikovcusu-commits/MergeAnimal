# Asset QA — V0.4.1 DEV

Aşağıdakı 12 resurs `AnimalData.sprite`-a bağlanıb. 512×512 PNG RGBA, alpha 0–255, bütün kənarların alpha maksimumu 0; ölçülər və bounding box skriptlə yoxlanıb. Kompozitlərə baxış vahid ön görünüş və isti tünd kontur istiqamətini göstərir; kontur qalınlığı və işıq istiqaməti ölçülməyib, yekun art-director təsdiqi deyil. Şahmat fonu opak AI mənbələrdən flood-fill ilə çıxarılıb, halo, incə detallar və daxili deşiklər əl piksel auditi tələb edir. 12-si də kommersiya üçün BLOKLU, Arena model/vendor UNKNOWN.

| Heyvan | Fayl yolu | Bbox | Dairədən kənar alpha>32 | Fərdi vizual audit / risk |
|---|---|---|---:|---|
| mouse | `assets/animals/mouse/normal.png` | [6, 11, 506, 502] | 8.95% | boz, böyük qulaqlar və quyruq; Koaladan burun və bığla seçilir |
| hamster | `assets/animals/hamster/normal.png` | [32, 6, 481, 506] | 4.40% | qızılı, iri açıq yanaqlar; Bear-dən kiçik ağız və rənglə seçilir |
| rabbit | `assets/animals/rabbit/normal.png` | [6, 32, 506, 480] | 1.37% | açıq rəngli, uzun əyik qulaqlar; ağ fonda kənar auditi lazımdır |
| cat | `assets/animals/cat/normal.png` | [8, 6, 505, 506] | 4.36% | narıncı zolaq və bığ; Fox-dan zolaqlı alın və quyruqla seçilir |
| dog | `assets/animals/dog/normal.png` | [6, 15, 506, 498] | 6.47% | açıq qəhvəyi, sallanan qulaq və xəz |
| fox | `assets/animals/fox/normal.png` | [8, 6, 504, 506] | 5.12% | narıncı, iti qulaq və ağ enli yanaq |
| raccoon | `assets/animals/raccoon/normal.png` | [7, 6, 505, 506] | 7.78% | boz, qara göz maskası və zolaqlı quyruq |
| koala | `assets/animals/koala/normal.png` | [6, 43, 506, 470] | 5.00% | boz-mavi, iri qara burun, tüklü qulaq; dairənin içində boşluq |
| panda | `assets/animals/panda/normal.png` | [20, 6, 492, 506] | 8.26% | qara/ağ, göz ətrafı ləkələr və qara ətraflar |
| bear | `assets/animals/bear/normal.png` | [13, 6, 500, 506] | 6.72% | tünd qəhvəyi, açıq dairəvi ağız; qulaqlar dairədən çıxır |
| lion | `assets/animals/lion/normal.png` | [24, 6, 488, 506] | 0.25% | qızılı üz və narıncı yal; kontur bir az daha dekorativ |
| elephant | `assets/animals/elephant/normal.png` | [6, 9, 506, 504] | 1.47% | mavi-boz, xortum və böyük qulaqlar |

Dairə canvas mərkəzində radius 256 olan təxmini collision proyeksiyasıdır. Kənardakı piksellərin bədən və ya aksesuar olması ayrıca vizual nəzərdən keçirilməlidir; bu ölçü divar fizikasının sıfır nüfuzlu olmasını göstərmir. Scale/radius problemi gizlətmək üçün dəyişdirilməyib. 12 fərdi overlay `art_reports/collision_overlays/`, bərabər ölçülü ağ/qara/collision kontaktlar və dizayn radiuslarına uyğun `contact_game_scale_WIP.png` mövcuddur. Eyni heyvanın fərqli context-lərdə istifadəsi və 36 state üçün faktiki inteqrasiya/qəbul ayrıca sınaq tələb edir.

Mənbə, texniki emal və SHA `ASSET_MANIFEST.json`; komersiya şərti `ASSET_LICENSES.md`. 20 SVG və 8 button theme əlavə olunub; son vizual oxunaqlılıq və bütün istifadələr yoxlanmayıb. 24 üz vəziyyəti, blink, 6 effekt, logo hələ hazırlanmayıb.

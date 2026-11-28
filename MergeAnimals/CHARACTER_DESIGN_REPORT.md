# V0.9.0.4 — character checkpoint

12 mövcud ID, normal sprite, ölçü/pivot, radius, mass və digər fizika məlumatları saxlanıb. Hər heyvana üç facial frame əlavə edildi: `blink`, `happy`, `surprise`; editable SVG `art_source/vector_animals/<id>/`, optimallaşdırılmış 256px PNG `assets/animals/<id>/`. Happy/Surprise göz/üz ifadələri dəyişir; elephant üçün xortum qorunur, panda üçün tünd maska üzərində açıq göz qapağı istifadə olunur. IDs: mouse, hamster, rabbit, cat, dog, fox, raccoon, koala, panda, bear, lion, elephant. Yeni normal dizayn, bədən/qulaq modulyasiyası və fərdi premium polish bu checkpoint-də edilməyib.

Faktiki Godot software-render fixture: [ifadələr](docs/visual/v0904/after/native-expression-fixture-thumbnail.jpg), 12 sətir və dörd ayrı vəziyyət. Bu JPEG checks API thumbnail-i və statik test səhnəsidir, playthrough deyil. Əvvəlki normal vektorlar `normal.svg` və PNG-də dəyişmədən saxlanılır; overlay-lər `docs/physics/overlays/`-dədir. Blink yalnız göz bölgəsi piksel fərqinə dair təkrar yaradıla bilən audit [46051321876](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46051321876) keçdi. PNG kadrlar bütöv təsvirlərdir, müstəqil eye/body rig deyil; normal 512px və facial frame 256px olduğu üçün raster sampling fərqi mümkündür.

## V0.9.0.4 davamı — faktiki native müqayisə

`3bd61aa` mövcud 12 dizaynı tamamilə yenidən çəkmədən bütün normal SVG-lərə növə xas üz/cizgi detalları, yumşaq daxili kölgə və əlavə işıq vurğusu əlavə edir. SVG mənbələrində ears, body, markings, muzzle, face details və göz/üz qrupları adlandırılıb; Blink/Happy/Surprise yenidən yaradılıb. Bunlar **ayrı runtime rig deyil**. Raster kadrlar və mövcud fərdi radius/kütlə saxlanır. No external image service; kommersiya BLOCKED. `ASSET_MANIFEST.json` hər mənbənin və PNG-nin hash/provenance qeydidir.

Hər növ üzrə əvvəl (`e034511`) və sonra (`3737255`, xarakter artwork `3bd61aa` ilə eyni) faktiki Godot 4.7.2 Compatibility software-render statik fixture: `docs/visual/v0904/continuation/characters/<id>-before-after.png`. [CI 46057285679](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46057285679). Əvvəlki görüntü repository-nin artıq layihəyə aid PNG-sidir; qadağan edilmiş legacy art deyil. Çəkiliş gameplay və ya insan qiymətləndirməsi deyil. Mənbə/raster yenidən-yaratma [46056366449](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46056366449) keçib; 48 PNG-də diskdən kənar alpha>8 piksel 0 (lokal `tests/commercial/audit_character_bounds.py`), dinamik collision yoxlaması deyil.

| Növ | Görünən forma / ifadə qeydi və açıq məsələ |
|---|---|
| Mouse | Açıq qulaq və bığ əlavə detallarla oxunur; boz-bənövşəyi kölgənin çox kiçik ölçüdə kontrastı hələ insan/cihaz testi istəyir. |
| Hamster | İri açıq yanaqlar əsas fərqləndiricidir; alnın kiçik xəttinin emosiya kimi oxunması nəzərdən keçirilməlidir. |
| Rabbit | Uzun qulaqlar və bığ ayırır; qulaqlar diskə sığdırıldığı üçün şişirdilmiş stil anatomik deyil. |
| Cat | Üç alın zolağı və bığ tanınır; kiçik ölçüdə zolaqlar incədir. |
| Dog | Göz ləkəsi və qulaq forması əsas işarədir; qulaqlar başın arxasında qismən gizlənir. |
| Fox | Narıncı rəng, sivri qulaq və açıq yanaqlar seçilir; yanaq forması sadə vektordur. |
| Raccoon | Tünd göz maskası seçilir; boz tonun koala ilə yığılma səhnəsində ayrılması cihazda qiymətləndirilməyib. |
| Koala | Böyük yumru qulaq və oval burun fərqləndirir; qulaq silueti bədənin arxasında qalır. |
| Panda | Kontrastlı göz maskası və açıq qapalı göz xətləri görünür; açıq kölgələr kiçik ölçüdə zəif ola bilər. |
| Bear | Qəhvəyi palitra və yumru qulaq var; dog ilə siluet fərqi hələ gücləndirilməlidir. |
| Lion | Dairəvi yal və qızılı palitra güclü işarədir; yal həndəsəsi hələ sadədir. |
| Elephant | Xortum və iri qulaqlar qorunur; xortumun kiçik ölçüdə aydınlığı ayrıca yoxlanmalıdır. |

İşıq palitrası və tünd kontur vahiddir, lakin bütün heyvanlar hələ sadə dairəvi vektor estetikasını saxlayır. Bu inkrement **tam premium/AAA redesign kimi qəbul edilmir**; real cihazda bütün ölçülərdə tanınma və insan art review açıqdır.

# Kök səbəb və regression — V0.2.1-dev tarixi + V0.3.0-dev

İlk cədvəlin sətirləri V0.2.1 bazası `ebd434c` və tarixi prefiksli commitlərə aiddir; Gün 3 bölməsi cari mənbəyə aiddir. 18 ayrı V0.1 kadrın müşahidələri və məhdudiyyətləri `SCREENSHOT_AUDIT.md`-dədir; bunlardan zaman, cihaz sürəti və ya ikiqat spawn nəticəsi çıxarmaq olmaz.

| Problem və sübut | Kök səbəb | Dəyişiklik və sınaq statusu |
|---|---|---|
| V0.1 üst-üstə/üzsüz preview, 175292–175301 və başqaları | `a2692b8:scripts/gameplay/Game.gd:70–81,87–97` queue dərhal dəyişir və preview ayrıca dairədir, body üzü `AnimalVisual.gd:4–17`-dədir. | V0.2.0 `Game.gd:85–98,175–200` fizika vaxtında boşluq sorğusu, cooldown və ortaq vizual; suite 32–37, 40–41 PASS. Cihaz renderi UNVERIFIED. |
| Eyni rəngli yığın, 175297–175323 | V0.1-də merge callback/manager yoxdur; kadr təkbaşına kontakt müddətini təsdiqləmir. | `MergeManager.gd:14–36,38–72` eyni növ lock + deferred dəyişmə; `Game.gd:210–230` təhlükəsiz yer axtarışı və `232–237` score. Suite 1–27, təbii iki-body və üç-body chain PASS. Bütün sıx yerləşmə halları təsdiqlənməyib. |
| Danger xəttinin yuxarısında qalaq, 175302 | V0.1 `Game.gd:92` xətti yalnız çəkir, game-over monitor yoxdur; kadr grace müddətini göstərmir. | `Animal.gd:24–30` dəstək normalı, `DangerMonitor.gd:15–33` dəstək/sürət/grace; real 48-body fixture 2.017 saniyədə GAME_OVER və spawn bloklanması PASS. Yanlış sıçrayış və fərqli cihazlar UNVERIFIED. |
| Blocked cooldown sonrası başqa x-də sürətli touch/mouse itir | V0.2.0 `Game.gd` əvvəlki x bağlı olduqda cooldown state-dən çıxmırdı, press qəbul edilmirdi və ya release aim statusunu görmürdü. | V0.2.1 `Game.gd:122–160` `_can_begin_input` vaxtı bitmiş cooldown-da yeni press-i qəbul və AIMING-ə keçirir; real boşluq hələ `_attempt_drop`-da yoxlanır. Red run `45660478538`, commit `5b3e995`, 4 FAIL; green `45660780424`, commit `8e3d079`, 4 PASS. Sintetik inputdur, hardware deyil. |
| Yüksək sürətli divar təmasında vizual radiusun qısamüddətli nüfuzu | `Game.tscn` 32 px divarları, `Animal.tscn` ray CCD, fizika addımı və təmas solveri; konkret solver səbəbi sübut edilməyib. İlkin test ±2 px həddi aşdığına görə bunu səhvən tam escape adlandırırdı. | 700 px/s təcrid olunmuş fixture-də 60 Hz sağ gap -6.636 px, mərtəbə -0.506 px; hər iki cisim yerə düşüb. `tests/physics/wall_collision.gd` ölçünü və 10 px tolerantlığı açıq göstərir; ±2 px tələbi keçməyib. CCD shape/120/240 Hz müqayisəsi köhnə loglarda; heç biri ±2 px-i bütün istiqamətlərdə təmin etmədi. Normal gameplay/render üçün risk açıqdır; fizikanı əsassız dəyişmədik. |

Qeyd: 10 px tolerantlıq test kriteriyasıdır, qüsurun aradan qalxdığı iddiası deyil; istifadəçi vizual qəbul meyarı olmadan seçilmiş diaqnostik sərhəddir. Şəkillərdə divardan çıxma göstərilməyib.

## Gün 3 aşkarlanan və aradan qaldırılan/açıq problemlər

### BUG-D3-01 — level 5-dən sonra evolution dayanırdı (düzəldilib)
- **Fayl/funksiya/sətir:** əvvəlki `MergeManager.gd:22–31`, indi `request_merge:23–37` və `_commit_pending:46–79`; `Game.gd:137–147`.
- **Səbəb:** beş resource və növbəti səviyyə tapılmadıqda merge rəddi. **Sübut/əvvəl:** baza mənbəyində Dog maksimum idi.
- **Düzəliş/yeni:** 12 resource, `next_evolution_id`, terminal flag; 11 real collision və elephant golden testləri run 45665893612 PASS. **Regression:** `day3_suite.gd`; risk: uzun, sıx insan oyunu hələ yoxlanmayıb.

### BUG-D3-02 — çəkili və yalnız beş səviyyə spawn qaydası yox idi (düzəldilib)
- **Fayl/funksiya/sətir:** `Game.gd:_pick_animal:118–135`, `AnimalData.gd`, 12 `.tres`.
- **Səbəb:** əvvəl `randi_range` ilə ilk üç bərabər seçilirdi. Aralıq Gün 3 implementasiyasında yalnız zero-weight-a etibar edilirdi: Inspector-da yanlış high-tier weight verilərsə qadağa pozula bilərdi.
- **Düzəliş/yeni:** çəkili seçim və level <=5 açıq filtri; 10000 nəticə run 45665893612 üzrə 3012/2511/2058/1479/940 və 0 high. **Regression:** `day3_suite.gd` 10000 test və yeni nonzero high-weight testi; sonuncu run 45666836718-də PASS. **Risk:** qeyri-standart bütün çəkilər sıfır olduqda ilk uyğun resource fallback seçilir.

### BUG-D3-03 — combo timeout UI-si köhnə göstəricini saxlaya bilərdi (düzəldilib, məntiq yoxlanıb, vizual yoxlanmayıb)
- **Fayl/funksiya/sətir:** `Game.gd:_physics_process:95–102`, `_update_hud:374–380`.
- **Səbəb:** sayğac reset olsa da score label yalnız yeni event-də yenilənirdi. **Sübut:** kod nəzarət axını; real render müşahidəsi yoxdur.
- **Düzəliş:** timeout label-i sıfırlayır. **Əvvəl/yeni:** kod əsaslı, visual before/after UNVERIFIED. **Regression:** combo timeout suite run 45666836718 PASS; label-in vizual yoxlanması yoxdur.

### BUG-D3-04 — sürətli collision overlap (açıq)
- **Fayl/funksiya/sətir:** `Animal.tscn` CCD, `Game.tscn` wall shape, `Animal.gd:_ready`, `tests/physics/day3_wall_matrix.gd`.
- **Səbəb:** həndəsi nüfuz faktiki ölçülüb; konkret physics solver kök səbəbi və vizual təsir təsdiqlənməyib. **Əvvəl:** 6.636 px başqa fixture-də, müddət məlum deyil. **Yeni:** 125 px fil / 700 px/s / ray 5.909 px, iki frame başqa təcrid fixture-də; birbaşa eyni şərt deyil. **Düzəliş:** physics 120 Hz; teleport və sadəcə tolerantlıqla PASS istifadə olunmur. Eyni 100 bot seed üzrə pik 16.678→9.190 px, lakin bəzi izolyasiya halları daha pis və CPU xərci naməlumdur; tam aradan qaldırma iddia edilmir. **Regression:** matrix bütün escape/stuck kriteriyalarını və overlapı ayrı loglayır. **Risk:** normal renderdə görünmə ehtimalı, digər sürət və shape-lər. Daha yeni bot müşahidəsi: normal Cat düşməsində 1138 px/s, floor overlap 16.678 px; eyni body-də 0.01 px-dən böyük overlap 5326 frame davam etdi (pik dərinlik bütün bu frame-lərdə davam etmir). Fizika solver səbəbi və vizual təsir hələ təsdiqlənməyib.

### BUG-D3-05 — konsept fonu şəffaf deyil (açıq)
- **Fayl:** `concepts/{mouse,cat,elephant}.png`; kod funksiyası yoxdur.
- **Səbəb:** generasiya damalı fonu piksel kimi çəkib; `identify` 1254×1254 RGB opaque. **Əvvəl:** konsept yox idi; **yeni:** şəkillər mövcuddur, 512/alpha tələbinə cavab vermir. **Düzəliş:** ayrıca 512×512 alpha törəmələr flood-fill və resize ilə yaradılıb; orijinallar saxlanıb, aktivə qoşulmayıb. Mouse quyruğunun içi və kontur əllə yoxlanmalıdır. **Regression:** vizual və channel yoxlaması; **risk:** model/lisenziya naməlum, kommersiya istifadəsi təsdiqlənməyib.

### BUG-D3-06 — 120 Hz-ə keçiddə 100-drop fixture regression (testdə düzəliş)
- **Fayl/funksiya/sətir:** `tests/physics/drop_100.gd:run`, cooldown gözləmə dövrü.
- **Səbəb:** test sabit 12 physics frame gözləyirdi; 120 Hz-də 0.1 s sərhədində scheduler və float səbəbi ilə növbəti request hələ hazır deyildi. **Sübut/əvvəl:** 60 Hz-də 100/100; run 45668965282 120 Hz-də 99/99 və FAIL.
- **Düzəliş:** sabit frame sayını artmış tolerantlıqla gizlətmək əvəzinə faktiki `READY/AIMING` və cooldown bitməsini gözləyir, maksimum timeout hesablanır. **Yeni/regression:** run 45670121999-də 100/100 PASS; risk: fixture body-ləri silir və normal dolu oyun stressi deyil.

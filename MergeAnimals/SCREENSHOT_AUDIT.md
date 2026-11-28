# 18 screenshotun fərdi auditi — V0.1 → V0.2.1-dev

**Mənbə:** istifadəçinin 18 ayrı JPG əlavəsi; ZIP faylı verilməyib. Sıra fayl adına görədir. Hər görüntünün başlığında `PHYSICS PLAYGROUND · V0.1` var: bunlar V0.2.0-dev və ya V0.2.1 test nəticəsi deyil. Aşağıdakı müşahidə tək kadrdır; təmasın uzunluğu, sürət, input hadisələrinin sayı, frame rate və ikiqat spawn statik şəkildən təsdiqlənmir. Foto faylları istifadəçi məzmununu avtomatik GitHub-a yükləməmək üçün repoya əlavə edilməyib; `tests/logs/screenshot-sha256.txt` fayl adlarını və hash-ləri qeyd edir.

## Hər bir görüntü

Açarlar: **P** = V0.1 preview və düşən body üst-üstə görünür / ayrı üz renderi; **M** = eyni rəngli cisimlər yığılır, merge kodu V0.1-də yoxdur; **G** = danger xətti V0.1-də yalnız vizualdır. Açarlar müstəqil xəta kodu nəticəsidir; ayrı bir kadr animasiyanın tamamlandığını göstərmir.

| Fayl | Ayrı-ayrı görünənlər və məhdudiyyət | Kodla əlaqə |
|---|---|---|
| 175292.jpg | Solda üzü olmayan sarı preview, eyni x-də aşağıda üzlü sarı cisim; döşəmədə iki kiçik çəhrayı cisim ayrı dayanır. | P; `a2692b8:Game.gd:87–97`, `AnimalVisual.gd:4–17`. |
| 175293.jpg | Yuxarıda iki bənövşəyi dairə əhəmiyyətli dərəcədə üst-üstə, öndə üz görünür; sarı cisim havada, döşəmədə üç cisim. | P; V0.1 `drop_animal:70–81`, `_draw:93–97`. |
| 175294.jpg | Sağ yuxarıda kiçik üzü olmayan çəhrayı dairənin altında üzlü bənövşəyi dairə; sahədə havada bir bənövşəyi və döşəmədə beş cisim var. | P; preview və body ayrıdır. |
| 175295.jpg | Solda narıncı çevrənin içində üzlü çəhrayı dairə kimi görünən üst-üstə görüntü; başqa bənövşəyi cisimlər havada/döşəmədədir. | P; vizual üst-üstə, ikiqat spawn sübutu deyil. |
| 175296.jpg | Sağda böyük bənövşəyi çevrənin içində sarı üzlü cisim; digər kiçik cisimlər yerdə və havadadır. | P; dərhal dəyişən preview ehtimalı kodla uyğun gəlir. |
| 175297.jpg | Solda bənövşəyi iki kontur bir-birinə yaxın örtüşür; döşəmədə eyni rəngli bir neçə cisim görünür. | P, M; merge V0.1-də implementasiya edilməyib. |
| 175298.jpg | Solda preview-də iki bənövşəyi kontur və aşağıda bir-birinə yaxın bənövşəyi cisimlər; digər cisimlər havadadır. | P, M; V0.1 kodu merge etmir. |
| 175299.jpg | Bənövşəyi ikiqat konturlu yuxarı cisim; döşəmədə yaxın/təmasda görünən bənövşəyi dairələr var. | P, M; kadr kontakt müddətini müəyyən etmir. |
| 175300.jpg | Sol kənara yaxın bənövşəyi üst-üstə kontur; döşəmədə eyni rəngli cisimlərdən ibarət kiçik yığın. | P, M; divar keçməsi görünmür və tək kadr bunu sübut etməz. |
| 175301.jpg | Üzü olmayan bənövşəyi preview; daha aşağıda üzlü çəhrayı cisim və döşəmədə çoxlu, bir neçəsi eyni rəngli cisim var. | P, M; fərqli rendering kodları. |
| 175302.jpg | Çox sıx qalaq; bir neçə bənövşəyi cisim qırmızı xəttin üstündədir, overlay Game Over yoxdur; yuxarıda üzü olmayan sarı preview var. | M, G, P; xətt üstündə qalma müddəti naməlumdur. |
| 175317.jpg | Çoxlu cisim və eyni rəngli qonşular; üzü olmayan sarı preview. Sağ sistem səs paneli sahənin bir hissəsini örtür, bu oyun UI-si kimi qəbul edilmir. | M, P; bu kadrdan performans ölçülmür. |
| 175318.jpg | Sıx qalaq, çoxlu eyni rəngli qonşu, üst hissədə üzlü bənövşəyi dairənin arxasında nazik ikinci kontur görünür. | M, P; ardıcıllıq və kontakt müddəti naməlumdur. |
| 175319.jpg | Sıx qalaq, havada bənövşəyi cisim və yuxarıda üzlü sarı cisim. Oyun sahəsi yuxarı xəttədək dolmayıb. | M; görünən üz yuxarı dairənin preview yoxsa yenicə düşən body olduğunu təkbaşına sübut etmir. |
| 175320.jpg | Solda sarı konturun içində üzlü çəhrayı dairə; yığının üstündə sarı cisim; eyni rəngli çoxlu yaxın dairə. | P, M. |
| 175321.jpg | Sarı üzlü cisim yuxarıda, çəhrayı cisim xəttin altında havada; sıx qalaqda bir neçə eyni rəngli qonşu var. | M; yuxarı cismin statusu statik kadrdan dəqiq deyil. |
| 175322.jpg | Yuxarıda çəhrayı üzlü dairə və qalın görünən kontur; solda sıx yığın və çoxlu eyni rəngli cisim. | P/M; ikinci konturun ayrı body olub-olmadığı təsdiqlənmir. |
| 175323.jpg | Sıx qalaq üstündə bənövşəyi böyük dairənin içində kiçik çəhrayı üz; bir çox uyğun rəngli qonşu. | P, M; üst-üstə görüntü fiziki double spawn kimi təqdim edilmir. |

## V0.2.0-dev / V0.2.1 müqayisəsi

- **P:** V0.1 spawn-dan sonra queue dərhal irəliləyirdi (`a2692b8:Game.gd:70–81`), `_draw:93–97` ayrıca üzü olmayan dairə çəkirdi. V0.2 `Game.gd:_attempt_drop`, `_spawn_clear`, `_update_preview`, `AnimalVisual.gd:_draw` ilə ayrıca node və ortaq vizual istifadə edir. Headless queue/cooldown/query testləri keçib; görünüşün cihazda təsdiqi hələ tələb olunur.
- **M:** V0.1-də merge manager və `body_entered` handler yox idi. V0.2 `MergeManager.gd:observe/request_merge/_commit_pending`, `Game.gd:_on_merged` əlavə edib. Rəsmi Godot 4.7.2-də real iki Mouse kontaktı Mouse→Hamster testini keçib. Digər ssenarilərin real/fixture statusu `QA_REPORT.md`-dədir.
- **G:** V0.1 xəttini `Game.gd:92` yalnız çəkirdi. V0.2 `DangerMonitor.gd:_physics_process`, `Animal.gd:_integrate_forces`, `Game.gd:_on_game_over` ilə mövcuddur. Real sabit 48-body qalaqda 2.017 saniyədə Game Over baş verdi; bu, bütün sıçrayış/mobile ssenariləri sübut etmir.
- V0.2-də aşkar edilmiş əlavə quick-tap problemi bu şəkillərdən deyil, mənbə və runtime regression-dan aşkarlanıb; `ROOT_CAUSE_REPORT.md`-yə baxın.

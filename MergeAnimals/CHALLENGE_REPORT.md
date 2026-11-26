# V0.6.4.1 DEV — Challenge Mode, Phase 1

## İstifadə
Əsas menyuda **Challenges** seçin. Əvvəlcə yalnız 01 açıqdır; uğur nəticəsi diskə yazıldıqdan sonra növbəti açılır. Tamamlanmış tapşırıq təkrar oynana bilər. Resume/Restart/Challenges seçimləri pause menyusundadır; nəticə ekranında Play again və açılmış növbəti tapşırıq düymələri var. Şərt təmin edilmədən təhlükə xətti oyunu bitirərsə Failed ekranı göstərilir. Bu mərhələdə vaxt limiti yoxdur: HUD-dakı vaxt aktiv oyun müddətidir və pause zamanı dayandırılır.

| ID | Tapşırıq | Məqsəd |
|---|---|---|
| 01 | First Friend | 1 xomyak yarat |
| 02 | Bunny Garden | 3 dovşan yarat |
| 03 | Cat Party | 2 pişik yarat |
| 04 | Puppy Time | 1 it yarat |
| 05 | Score Hunter | 300 xal topla |

Heyvan yaratmaq dedikdə həmin heyvanın oyunçunun real drop-u **və ya** uyğun heyvanların merge nəticəsi nəzərdə tutulur; yalnız cari cəhddə yarananlar sayılır, eyni heyvanın sonradan yenidən merge olunması əvvəlki sayımı geri almır. Score Hunter cari cəhdin faktiki merge xalını izləyir. Debug/fixture mənşəli, oyunçu drop-undan gəlməyən obyektlərin merge-i məqsəd sayımına daxil edilmir. Mövcud Classic heyvan resursları, rigid-body fizika, MergeManager və DangerMonitor istifadə olunur. Challenge-də Undo, Remove və Rescue gizlədilib və onların çağırışları bloklanır. Classic implementasiyaları dəyişdirilməyib.

## Struktur və yaddaş
Beş `ChallengeData` `.tres` resursu məqsədləri təsvir edir; `ChallengeManager` yaradılma/score hadisələrini və aktiv vaxtı izləyir. ChallengeGame Classic səhnəsini miras alır, amma `persist_best=false` ilə işləyir və nəticə, HUD, pause/restart/naviqasiya davranışını ayrıca idarə edir. Hər tapşırığın ən yaxşı xalı ayrıca saxlanır; Classic score və aktiv sessiya yazılmır və dəyişdirilmir.

Nəticələr `user://wild_garden_challenges.json` və `.bak` faylındadır: checksum-lu SaveManager envelope, schema v1, beş nəticə (`completed`, `best`, `attempts`), ardıcıl unlock validasiyası, atomic temporary-file/rename və backup. Primary xarabdırsa valid backup istifadə edilir; hər ikisi yararsız və ya gələcək schema varsa avtomatik üzərindən yazılmır. Uğur, uğursuzluq və nəticənin save retry-si ayrıca idarə edilir; ilkin save alınmadıqda Next/çıxış bloklanır və Retry save təklif olunur. Restart və ya pause-dan çıxışla yarımçıq cəhd nəticə sayılmır. **Davam edən Challenge lövhəsi və vaxtı saxlanmır**; tətbiq bağlandıqda yalnız əvvəlki tamamlanmış nəticələr qalır. Bu Phase 1 üçün nəzərdə tutulan məhdudiyyətdir, Classic Continue-dan ayrıdır.

Yazılmış nəticə sonrası backup yenilənməsi uğursuz ola bilər; bu halda primary commit edilmiş qalır, lakin həmin primary sonradan korlanarsa köhnə backup bəzi nəticələri geri apara bilər. Bütün lokal faylların silinməsi/geri qaytarılması, elektrik kəsilməsi, paralel yazıçılar və mobil/Web fayl sistemi üçün zəmanət verilmir.

## Faktiki icra və sərhədlər
Godot 4.7.2 [Challenge CI 45764793009](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45764793009), test kodu `c92e2925091c466ba356124e3ddfafca819cdaca`: 65/65 integration, ayrı Godot prosesində 9/9 load/recovery və dörd əlavə toxunulmamış lövhə testi PASS. İlk Challenge-in ayrıca testində iki faktiki drop təbii gravity ilə birləşir; 02–05 üçün heyvan növbəsi testdə deterministik seçilir, lakin lövhədə heyvanlar nə köçürülür, nə də silinir; normal gravity, physics contact, MergeManager və danger işləyir:

| Challenge | Drop | Fiziki merge | Xal |
|---|---:|---:|---:|
| 02 Bunny Garden | 6 | 4 | 39 |
| 03 Cat Party | 4 | 2 | 24 |
| 04 Puppy Time | 2 | 1 | 20 |
| 05 Score Hunter | 8 | 7 | 353 |

Əsas integration ssenarilərində daha sürətli deterministik əhatə üçün düşəcək heyvan növbəsi seçilir, body-lər təmas üçün yenidən yerləşdirilir və növbəti cüt üçün lövhə təmizlənir; merge və məqsəd tamamlanması birbaşa çağırılmır. Failed fixture overflow siqnalını testdən verir; təbii dolu lövhədən Challenge Failed ayrıca təsdiqlənməyib. Restart, replay, növbəti düymə, pause vaxtı, save obstruction/retry, primary corruption/backup, əvvəlki nəticənin ayrı prosesdə yüklənməsi və hər iki Classic save faylının byte-byte dəyişməməsi yoxlanıb. Oyunçu drop-u ilə hamster yaratma ayrıca yoxlanıb.

Beş 720×1280 Xvfb/X11 Godot pəncərəsi — locked/unlocked selection, gameplay, success, failed — eyni Actions run artifact-ində tam PNG-dir; `art_reports/v0641_challenge/` kiçildilmiş JPEG nüsxələrdir. Bunlar scripted fixture-lərdir, insan playtesti və ya fiziki mobil cihaz testi deyil. `QA_REPORT.md` əvvəlki gameplay regression linklərini saxlayır. Release DEV-dir; mövcud art hüquqları, fiziki nüfuz və mobil/Web riskləri ayrıca açıq qalır.

# V0.6.4.2-dev — Challenge expansion (WIP)

Source implementation tested at `9dde09e45073de38fa3f52095235dcb4bb73c61a`; baseline `f0b5cd937ae79fe856dc236fd206a8fa3e0d14f3`. This is a DEV/WIP result, **not release acceptance**. The Golden Garden automated solution takes only four drops; its requested difficulty has not been established. Human balance and real-device acceptance remain open.

20 resource definitions extend the existing ChallengeManager/ChallengeData and preserve 01–05. Selection is sequentially unlocked, scrollable, grouped Beginner 01–05 / Intermediate 06–10 / Advanced 11–15 / Expert 16–20, and shows completed state, score and time. Each result is stored separately from Classic; v1 five-entry results migrate to v2 without inventing old times. Replay and restart start fresh. An active attempt is not saved: leave/restart warns that progress is discarded. Challenge disables Classic Remove, Undo and Rescue. There is no active-board continue.

## Individual completion evidence

Results below use actual Godot bodies, drops, gravity and contact events, with no artificial merge or score addition for the completion. Times are simulated elapsed seconds from fixed-FPS runs, not human times. **01–10 use test-selected animal types**, not proof that the ordinary random queue is equally easy. 11–20 use the configured starter boards and looping spawn sequences. Starter pieces do not themselves count as a creation. For 01 the DangerMonitor is disabled for the untouched-board natural fixture; 02–05 have an independent untouched-board run; the earlier regression fixture also repositions/cleans between pairs and must not be treated as natural balance evidence.

| # | Challenge / target | Result | Drops | Merges | Score | Time s |
|---|---|---|---:|---:|---:|---:|
| 01 | First Friend · 1 hamster | PASS, natural pair; danger monitor disabled | 2 | 1 | not logged | not logged |
| 02 | Bunny Garden · 3 rabbits | PASS | 6 | 4 | 39 | not logged |
| 03 | Cat Party · 2 cats | PASS | 4 | 2 | 24 | not logged |
| 04 | Puppy Time · 1 dog | PASS | 2 | 1 | 20 | not logged |
| 05 | Score Hunter · 300 points | PASS | 8 | 7 | 353 | not logged |
| 06 | Fox Adventure · 1 fox | PASS | 2 | 1 | 32 | 4.85 |
| 07 | Quick Merge · 5 merges / 60 s | PASS | 8 | 5 | 188 | 15.64 |
| 08 | Triple Combo · x3 | PASS | 8 | 7 | 353 | 16.22 |
| 09 | Raccoon Mission · 1 raccoon | PASS | 4 | 3 | 124 | 8.72 |
| 10 | Limited Drops · 150 / 20 drops | PASS | 6 | 4 | 156 | 12.08 |
| 11 | Koala Kingdom · 1 koala | PASS | 1 | 1 | 70 | 2.95 |
| 12 | Panda Rescue · 1 panda | PASS | 1 | 1 | 100 | 2.94 |
| 13 | Score Master · 1000 | PASS | 3 | 2 | 1000 | 6.13 |
| 14 | Double Trouble · 2 foxes | PASS | 4 | 2 | 64 | 8.43 |
| 15 | Bear Mountain · 1 bear | PASS | 1 | 1 | 150 | 2.91 |
| 16 | Fast Thinker · 500 / 90 s | PASS | 14 | 11 | 509 | 26.57 |
| 17 | Combo Champion · x5 | PASS | 32 | 31 | 2062 | 60.42 |
| 18 | Lion King · 1 lion | PASS | 1 | 1 | 220 | 2.87 |
| 19 | Gentle Giant · 1 elephant | PASS | 1 | 1 | 500 | 2.82 |
| 20 | Golden Garden · Golden Merge | PASS, difficulty unverified | 4 | 4 | 2220 | 8.41 |

Detailed limits, setup and the last-drop test: `CHALLENGE_BALANCE_REPORT.md`; executable results: `tests/logs/v0642-challenge-9dde09e.txt`, [CI run 45806711856](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45806711856). Screenshots are downscaled X11 evidence, not physical device photographs, in `art_reports/v0642_challenge/`.

---
## Historical V0.6.4.1 report
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

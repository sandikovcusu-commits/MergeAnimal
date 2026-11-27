# V0.9.0.2.1 — save integrity

**Şəxsi test; qəbulun bütün halları tamamlanmayıb.** Kommersiya hüquqları BLOCKED. Tətbiq kodu `cbf38fd`; test protokolu `ecb0553`. Əvvəlki hesabatlar `docs/archive/` qovluğundadır.

## Dəyişiklik

`SaveManager` Web-də təsdiqləmə müşahidəsini session/power-up ilə yanaşı progress, settings, theme, challenge, achievement primary və achievement checkpoint fayllarına genişləndirir. Ən son yazılmış məzmunun tam eyni bytes-i IDBFS-dən read-only transaction ilə oxunub transaction bitdikdə təsdiqlənir. Ayrı faylların hər biri izlənir, lakin **fayllar arasında atomik transaction yoxdur**. Əvvəlki təsdiq yeni save-ə aid sayılmır. Lokal yazı xətası `failed`, mövcud olmayan filesystem `unavailable`, cavabsız/uyğun gəlməyən IDB oxuması `unconfirmed` olur; yeni cəhd köhnə timeout-u daşımaq əvəzinə yenidən ölçülür. IDB-də faktiki yazı xətasını dəqiq ayırmaq üçün engine callback-i yoxdur; buna görə timeout «uğursuz yazı» yox, «təsdiqlənmədi» kimi göstərilir.

Classic HUD, challenge nəticəsi və başqa ekranlar üçün göstərici AZ/EN/TR/RU mətnləri ilə yenilənib. Challenge-da MEMFS yazısı təkbaşına «Result saved» vermir. Göstərici yalnız izlənən və bu prosesdə yazılmış fayllar üçündür: hələ snapshot-a düşməyən hərəkəti, başqa tabın yazısını, legacy `.cfg` fayllarını və backup-ları tam əhatə etmir. Təsdiqlənən checkpoint son istifadəçi əməliyyatı ilə eyni olmaya bilər. Mövcud save xətası/retry UX-i saxlanılıb; Challenge və reward-un təkrar mükafatın qarşısını almaq üçün bəzi keçidləri bloklayan əvvəlki davranışı qalır.

## Ardıcıl save və ayrı fayllar

Hər brauzerdə instrumentli, ayrıca QA build-də eyni main thread-də 10, 50, 100 ardıcıl `SessionSave.clear_session` çağırışı: generation 1–10, 11–60, 61–160, son hər burst üzrə exact read-back və browser restart sonrası generation 160. Bu, aktiv board gameplay stresi deyil; 160 tombstone fixture-i və eyni prosesdə sinxron ardıcıllıqdır. Əsl parallel multi-tab yazıçı, ayrıca save queue və eyni vaxtda iki writer test edilməyib; bu sistem single-writer-dir. Test fixture-lərində best score, mouse collection count, merge statistics, audio/language settings, challenge, theme və achievement ayrı faylları restart-dan sonra oxunub.

Reward transaction ID-ləri və callback deduplication əvvəlki davranışdır, server-side durable exactly-once ledger deyil. Mock sınaqda duplicate callback, stale session, save failure/retry və refresh yoxlanıb; real reklam və reward commit-in IndexedDB təsdiqindən əvvəl ani bağlanması yoxlanmayıb. Reward istifadəsi rollback ola bilər. Challenge/achievement checkpoint-ləri, theme və settings fərqli fayllardadır; hər biri təsdiqlənsə belə crash iki yazı arasında baş verdikdə vəziyyətlər fərqli nəsillərə aid ola bilər. Mövcud recovery və fail-closed qaydaları cross-file atomiklik yaratmır.

## Köhnə məlumat

V0.6.1 (`ae7d0ec`) və V0.7.0 (`63f2127`) əvvəlki Godot layihələrinin öz write-phase testindən yaradılan real fayllar; V0.8.0 və V0.9.0.2 əvvəlki Web CI-dən götürülmüş capture bytes-ları istifadə edilir. Bunlar istifadəçinin şəxsi save-ləri deyil. Hər brauzerdə exact IDB faylları, browser restart, generation/score/board, Continue və cari schema-ya sonrakı yazı yoxlanıb. 0.6.1 schema 1-dən 3-ə keçdi; digər nümunələr artıq schema 3 idi. 0.6/0.7 canlı board simulyasiyasında əlavə merge olduğuna görə score 152-dən 172-yə artdı; bu, statik bit-bərabər migrasiya testi deyil. Bütün köhnə mağazaların və bütün 0.6.x/0.7.x/0.8.x/0.9.x minor variantlarının məzmunu ayrıca müqayisə edilməyib; yalnız mövcud nümunələri əhatə edir.

## Açıq sərhədlər

Ani bağlanma, cihazın sönməsi, eviction, private mode, cross-tab və ayrı fayllar arasında 100% zəmanət yoxdur. Yeni təsdiqlənməmiş action itə bilər. Fiziki mobil cihaz, real storage quota/permissions və multi-tab konfliktləri yoxlanmayıb. Ətraflı fərdi nəticə və uğursuz təkrarlar `WEB_QA_REPORT.md` və `INDEXEDDB_REPORT.md`-dədir.

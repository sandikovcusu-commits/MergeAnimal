# V0.8.1.1 — Web power-up və sessiya hesabatı

Bu hesabat yalnız tələb edilən sistemlər haqqındadır; platforma releasinin qəbulu deyil. Godot 4.7.2 **release WebAssembly** export-u yerli HTTP-də, Playwright 1.56.1, Xvfb, proqram WebGL2 və 720×1280 masaüstü viewport-da icra edildi. Bunlar avtomatlaşdırılmış brauzer sınaqlarıdır, native Godot testləri və ya insan/real cihaz playtesti deyil. Hər brauzer/ssenari ayrıca, əvvəlcədən boş persistent profil işlədir.

## Nəticələr

| Ssenari | Chromium | Firefox | Sübut |
|---|---|---|---|
| Yeni oyun, iki real tutorial drop və real fiziki merge | PASS | PASS | 2 drop, 1 merge, 4 xal, bir hamster; [CI 45856491387](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45856491387) |
| Undo, refresh/Continue, profili tam bağla/aç/Continue | PASS | PASS | əvvəlki bir siçan və 0 xal bərpa edildi, `undo_remaining=0`; yenidən klik effektsiz |
| Remove, refresh/Continue, profili tam bağla/aç/Continue | PASS | PASS | hamster silindi, 4 xal qaldı, `remove_remaining=0`; yenidən klik effektsiz |
| Game Over → refresh/Continue → Rescue → refresh/Continue → tam bağla/aç/Continue | PASS, **hazırlanmış lövhə** | PASS, **hazırlanmış lövhə** | [CI 45858334711](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45858334711); `rescue_remaining=0`, xal və qalan fil/şir saxlandı |
| Dərhal bağlama sonrası ən son əməliyyatın davamlılığı | **ZƏMANƏTSİZ** | **ZƏMANƏTSİZ** | Hər brauzerdə 1 müşahidə; aşağıya bax |

Bütün üç kömək sistemi ayrıca profil və ayrı oyun ssenarisi ilə sınandı. Script IndexedDB IDBFS qeydlərini **yalnız oxuyaraq** sessiya və power-up checksum-larını, generation, xal, heyvan UID/növü və qalıq limitləri müqayisə edir; Continue-dan sonra daha yeni canlı autosave gözlənilir. Bunlar yoxlanmış ssenarilərin nəticəsidir; bütün mümkün xətalara qarşı zəmanət deyil. Görünən lövhə və UI əlavə screenshot-larda yoxlanıb.

## Rescue fixture açıqlaması

Təbii oyunda real tutorial merge-dən sonra 230 input cəhdi ilə [CI 45847826869](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45847826869) Game Over-a çata bilmədi: bu sınaq **uğursuzdur**, təbii dolma PASS deyil. Növbəti müstəqil sınaqda real merge-dən sonra yalnız test profilinin IndexedDB sessiyasına 4 müxtəlif heyvandan ibarət hazırlanmış lövhə yazıldı; hər biri `eligible=false`, sessiya `tainted=true`, `game_over_pending=false` idi. Xal, kəşf və achievement nəticələri uydurulmadı. Bu lövhə təbii oyun nəticəsi deyil. Oyun özü real fizika/danger timer ilə Game Over yaratdı; oyunçu inputu ilə Rescue işlədi. Ekranda ən böyük fil göstərilməsi fixture lövhəsinə aiddir. İstifadəçilərin yaddaşı və istehsal build-inə test fixture kodu yazılmayıb.

## IndexedDB, qəfil bağlanma və limit riski

Godot `user://` Web-də IDBFS/IndexedDB-yə bağlıdır. `FileAccess.flush()/close()` və oyun içi checkpoint-in `OK` qayıtması IndexedDB transaction-un tamamlandığına dair tətbiqə təsdiq **deyil**. Godot 4.7.2 [OS_Web main loop](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp) növbəti iterasiyada async sync başladır; [JS IDBFS implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/library_godot_os.js) `FS.syncfs` callback-i ilə tamamlayır. Brauzer səhifəni dərhal bağlaya və ya prosesi öldürə bilər; son dəyişiklik, o cümlədən istifadə edilmiş limit itə bilər. Ayrı fayllar arasında tam atomiklik də təmin edilmir. Mövcud GDScript comment-lərində yanlış “durable checkpoint” ifadəsi düzəldildi, **risk kodla aradan qaldırılmayıb**.

Təcrübədə Undo klikindən dərhal sonra konteksti bağlayanda Chromium bir dəfə əvvəlki 4 xallı, istifadəsi qalan snapshot-u; Firefox bir dəfə 0 xallı, istifadəsi bitmiş snapshot-u göstərdi. Klikin commit edilib-edilmədiyi bağlanmadan əvvəl ayrıca təsdiqlənmədiyindən bunu təsdiqlənmiş sonrakı disk yazısı itkisi kimi yox, yarışın reproduksiya olunan nəticəsinə dair **məhdud müşahidə** kimi oxuyun. Qəza, batareya itkisi, storage dolması, private mode və eviction ayrıca sınanmayıb. Gözləmək riski azalda bilər, amma sabit gözləmə müddəti zəmanət deyil. Storage-in silinməsi saxlama məlumatlarını silir.

## Console, WebAssembly və IndexedDB

Yuxarıdakı yekun ssenarilərin `events.json` qeydlərində səhifə JS exception, `console:error`, HTTP ≥400 və failed request yoxdur; checksum-lu IDB qeydləri oxundu. Chromium proqram renderində `ReadPixels` GPU-stall warning, Firefox-da WASM exception-handling `try` deprecation və bəzi reload-larda AudioContext user-gesture warning var. Bunlar performans/səs keyfiyyəti sınağı deyil. Əvvəlki fixture naviqasiyasında Firefox `InvalidStateError: Navigated away from page` səkkiz dəfə qeydə alındı ([CI 45855513340](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45855513340), uğursuz); test harness işləyən səhifəni tərk etmək əvəzinə onu tam bağlayıb ayrıca storage səhifəsi açacaq şəkildə dəyişdirildi və yekun Rescue CI-də həmin error təkrarlanmadı. Bu müşahidə ümumi Web naviqasiyasının təhlükəsizliyini sübut etmir. Firefox-un cache-dən HTTP 304 cavabı əvvəl testdə səhvən failure sayılırdı; harness düzəldildi və startup xətasında context bağlanır.

Sınaq artefaktları: Web evidence ZIP-də PNG, browser log, console/network events və seçilmiş IDB JSON-ları; bunların IDB məzmunu yalnız test profillərinə aiddir. Release build və ayrı sınaq build-ləri eyni mənbədən export olunsa da binary PCK hash-ləri fərqli ola bilər; hər build konkret CI run-u ilə əlaqələndirilməlidir. CrazyGames, audio kodu, sprite, fizika parametrləri və optimizasiya dəyişdirilməyib.

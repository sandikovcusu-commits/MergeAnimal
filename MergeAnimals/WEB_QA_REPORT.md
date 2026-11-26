# V0.8.0 — Web mərhələsi A: aralıq hesabat

**Status: tamamlanmayıb.** Bu hesabat qismən texniki sübutdur; buraxılış və ya CrazyGames uyğunluğu təsdiqi deyil. İstənilən bütün Web yoxlamaları tamamlanmadan B (SDK) və C (optimizasiya) mərhələləri başlanmayıb.

## İcra edilmiş export və müşahidələr

- [CI 45842578448](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45842578448), mənbə `93e4ee2c703becedfe800a663605a28652998a31`: Godot 4.7.2 import və release Web export; HTML-də `GODOT_THREADS_ENABLED = false`, runtime-da Compatibility/WebGL2 və single-threaded. `index.html`, JS, WASM, PCK, ikonlar və audio worklet-lər yaradıldı. Çıxış ZIP-i tam V0.8 buraxılışı deyil.
- Eyni CI-də yerli HTTP server, Xvfb və proqram renderi ilə Playwright Chromium və Firefox masaüstü brauzerləri, 720×1280 pəncərə: menyu və Play görünür; tutorial növbəsində iki real siçan buraxıldı və toqquşma ilə hamster yarandı. Hər iki brauzerin IndexedDB sessiya snapshot-u iki drop, bir merge, 4 xal və hamster göstərir. Bu səhnələr proqramla idarə olunub, insan playtesti deyil; başlanğıc tutorial növbəsi oyunun öz deterministik növbəsidir.
- Refresh/Continue və bütün brauzer proseslərini bağlayıb eyni profili yenidən açdıqdan sonra Continue ekranlarında 4 xal və hamsterin bərpası screenshot-larda görünür. Bu yalnız həmin ssenaridir; ayrıca Collection, Achievement, Challenge və Settings-in yenidən açıldıqdan sonra UI bərpası yoxlanmayıb. Əvvəlki snapshot-da Achievement A01 və kəşflər var; onların yenidən açıldıqdan sonra ayrıca UI-də qalması sübut edilməyib. İstifadə edilmiş power-up limitinin bərpası da yoxlanmayıb.
- İlkin/növbəti eyni səhifədə konsol və failed-request dinləyicilərində JavaScript exception və network failure qeydə alınmayıb. Chromium proqram WebGL ReadPixels stall xəbərdarlığı; Firefox köhnəlmiş WASM exception instruction və reload zamanı jest olmadan AudioContext start xəbərdarlığı verdi. Yenidən açılan kontekstdə ayrıca konsol və network dinləyicisi qurulmayıb. Səsin eşidilməsi yoxlanmayıb.
- CI smoke PASS yalnız HTTP, canvas və izlənən JS/network səhvləri üçündür. Drop/merge/Continue ayrıca görüntü və IndexedDB-nin **manual nəzərdən keçirilməsinə** əsaslanan müşahidədir, həmin funksiyalar üçün avtomatik assertion deyil. Reload və reopen screenshot-ları, JSON və loglar workflow artifact-ində və `artifacts/v080-evidence-93.zip` arxivindədir; ekran görüntüləri CI runner saatını istifadə edir.
- `index.wasm` 39,514,754, `index.pck` 3,719,288 bayt; bu ölçülər sıxılmamış fayllardır, şəbəkə transferi ölçümü deyil. C performans işi aparılmayıb.

## Tamamlanmalı A işləri

Golden, Collection/Statistics/Challenge/Achievement UI, Undo/Remove/Rescue istifadə və limitlərin bərpası, themes, 4 dil, audio dinləmə, Reduced Effects, Game Over, həmçinin çoxsaylı ölçülər, touch, orientation, resize, fullscreen və fokus/scroll ayrıca doğrulanmalıdır. 360×640, 393×873, 720×1280, 1366×768, 1920×1080 viewport matrisindən yalnız 720×1280 bu Web sınağında istifadə edilib. Edge və Android Chrome/real mobil cihaz yoxlanmayıb. Mağaza/SDK platforma testləri keçirilməyib. Tamamlanmamış tapşırıqlar PASS sayılmır.

Brauzer məlumatlarının təmizlənməsi, xüsusi rejim, məhdud storage/iframe siyasəti və ya brauzerin silməsi `user://` məlumatlarını itirə bilər. Müxtəlif origin-lər ayrıca storage-dur. Cross-file atomiklik və əvvəlki A15/sprite hüquqları/mobil performans/fizika riskləri qüvvədədir.

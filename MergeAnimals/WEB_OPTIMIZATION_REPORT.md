# V0.8.3 — Web optimizasiya və audit

## Eyni presetlə faktiki ölçü

Instrumentasiyasız `Web CrazyGames Rewarded (full-launch opt-in)`: əvvəl [45908580684](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45908580684), sonra [45917670694](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45917670694); eyni Godot 4.7.2 release template. ZIP aşağıda eyni compression level 9 ilə, README-siz bütün export fayllarıdır; çatdırılma ZIP-ində əlavə README ölçüsü cüzi fərq yaradır.

| Göstərici, bayt | Əvvəl | Sonra | Fərq |
|---|---:|---:|---:|
| Tam export faylları | 43,577,044 | 43,105,860 | −471,184 (−1.08%) |
| WASM | 39,514,754 | 39,514,754 | 0 |
| PCK | 3,727,516 | 3,256,332 | −471,184 (−12.64%) |
| ZIP, README-siz | 13,693,446 | 13,299,924 | −393,522 (−2.87%) |
| PCK gzip-9 | 3,526,768 | 3,133,247 | −393,521 (−11.16%) |

WASM gzip-9 10,054,758 bayt, dəyişməyib. Ayrı lokal gzip HTTP serveri ilə faktiki browser resource transfer (HTML navigation və uzaq SDK xaric; instrumentasiyalı adi Web export): Chromium median 13,681,337→13,291,525 B, Firefox 13,693,550→13,303,747 B. HTTP headerləri, iconlar və browser resurs sorğuları daxil, real CDN/proxy/şəbəkə deyil; son production PCK-dən fərqli olaraq ilkin after QA exportunda benchmark translation artifaktları var idi. Sıxılmamış export **25 MB-dan kiçik deyil**, ZIP və bu şərti gzip transfer 25 MB-dan kiçikdir. Custom engine template qurulmayıb, WASM ölçüsünün azaldıldığı iddia edilmir.

## Dəyişikliklər və səbəblər

| Fayl / problem | Dəyişiklik, ölçü və keyfiyyət | Reqressiya / risk |
|---|---|---|
| `assets/animals/{mouse,hamster,rabbit}/normal.png.import` — bütün heyvanlar 512² olsa da ilk üçü gameplay-də 36/46/58 logical px diametrdə çəkilir | Yalnız import limit 256²; PNG mənbələri və collision radius dəyişmir. Üç `.ctex` birlikdə 577,884→191,922 B (−385,962 B). 3 × RGBA baza səviyyəsi nəzəri 3 MiB→0.75 MiB; GPU/driver real allocation ölçülməyib. Normal 360 px Web screenshots müqayisə edildi; böyük/yüksək-DPI Collection detalında dəqiqlik azala bilər, tam insan keyfiyyət testi deyil. | 12 sprite/alpha, preview, radius testləri və ayrıca import 256/512 testi keçdi. Original 512 PNG source ZIP-də saxlanır. |
| `export_presets.cfg` — development manifest və istifadə edilməyən beş əlavə UI tema PCK-yə daxil olurdu | `ASSET_MANIFEST.json` (71,174 B), `berry`, `cream`, `earth`, `gold`, `sky` (14,084 B) və təsadüfi benchmark translation-ları exportdan çıxarıldı. Runtime-də istifadə olunan forest/sunset/snow qalır. Source fayllar silinmir. | PCK audit 12 heyvan, 20 challenge, 15 achievement, 3 tema, 20 SFX, 3 loop, 4 dil sayır. No-ads və rewarded preset-ləri ayrıdır. |
| `scripts/gameplay/Game.gd` — hər 120 Hz spawn-clear testində yeni shape/query object, Undo UI-yə eyni dəyərin təkrar təyinatı | Eyni sinxron shape/query reuse və yalnız dəyişəndə label/button setter. Davranış və vizual məntiq dəyişmir. Bütün build fərqini bu sətrlərə və ya bir FPS rəqəminə aid etmək olmaz. | Təmiz/bloklu spawn və dəyişən radius testi, Undo/Rescue/Challenge və 100-seed 60/120 Hz bot müqayisələri keçdi. Digər qarmaqarışıq fizika hallarına zəmanət deyil. |
| `scripts/gameplay/AnimalVisual.gd`, `scripts/audio/AudioManager.gd` — reduced halda hər body hər frame settings poll edirdi | Reduced-effects dəyişiklik siqnalı ilə body animasiya `_process` dayanır, açıldıqda bərpa olunur; aktiv tween ləğv edilir, scale normaldır. Normal animasiya saxlanır. | Toggle/tekrar enable testləri və Web audio/reward sınaqları keçdi. Reduced eyni stressdə draw call-u azaldır, FPS artımı runner təsirindən ayrılmayıb. |
| `docs/performance/.gdignore`, `tests/performance/audit_pck.py` | CSV-lərin Godot translation kimi importunun və production PCK-yə düşməsinin qarşısı alınıb; fresh release PCK-lər avtomatik audit olunur. | Instrumentasiya yalnız `tests/` altındadır və exportdan kənardır. `debug_enabled` release `OS.is_debug_build()` ilə qapalıdır; kod içindəki debug funksiyalarının fayldan tam silindiyi iddia edilmir. |

## 12 tekstura və dekorasiya auditi

`docs/performance/TEXTURE_AUDIT.csv` bütün 12 PNG üçün ölçü, şəffaf bounding box, tam şəffaf piksel faizi və Pillow WebP müqayisəsini saxlayır. PNG cəmi 3,608,716 B; lossless WebP 2,329,508 B; keyfiyyət-90 WebP 403,012 B. Bunlar mənbə fayllarının sınaq çevirmələridir, PCK/network nəticəsi deyil; Godot artıq lossless imported `.ctex` yaradır. Lossy WebP-lər keyfiyyət yoxlaması olmadan istifadə edilməyib. Tam şəffaf piksel 20–39.6%-dir, amma alfa bounding box çox vaxt 6 px-dək kənara çatır; crop draw geometry/siluetini dəyişə biləcəyi üçün tətbiq edilməyib. Digər 9 heyvan 512² qalır: collection/retina və böyük heyvanlarda keyfiyyəti qorumaq üçün. Godot import: lossless mode 0, mipmaps off, alpha-border fix on. 69 asset faylında SHA-256 ilə tam identik dublikat tapılmadı. Üç SVG fon və 20 kiçik SVG ikon yoxlanıb, geniş ölçülü dekorativ rastr yoxdur; istifadə olunan dekorlar silinməyib. Görünən müqayisə tam vizual və ya DPI audit deyil. Kommersiya hüquqları təsdiqlənməyib.

## Audio və effektlər

20 SFX və 3 loop qorunur; pool 8 SFX + bir musiqi player, impact eşiyi 100 və 0.18 s cooldown mövcuddur. Web stream playback dəyişməyib; 47/47 audio qrafik testləri hər iki browserdə, simulyasiya touch 48/48, mock reklam audio susma/bərpası 68/68 keçib. Dinləmə və audio CPU emal müddəti ölçülməyib. Effect node-ları ömür sonunda queue_free olur, cap 40; floating label cap 8 və 0.7 s, notification queue mövcuddur. Tween/notification/Golden kodu yoxlanıb, daha geniş pooling/refactor üçün nəticə yox idi, ona görə dəyişdirilməyib. Hər ayrıca optimizasiya üçün müstəqil A/B profil yoxdur; ölçülən ümumi nəticələri `PERFORMANCE_REPORT.md`-də oxuyun.

## Production təhlükəsizliyi və məhdudiyyətlər

Son rewarded PCK siyahısında QA screenshot/video, test/probe/mock, benchmark, sənəd, manifest və 5 istifadə edilməyən tema yoxdur. Test səviyyəsində release debug panel `OS.is_debug_build()` qapısı ilə gizlidir; JS mühitinə nəzarət edən şəxsə qarşı client-side anti-cheat/ödəmə təhlükəsizliyi iddiası deyil. Basic/normal Web reklamsız; full-launch opt-in preset yalnız entitlement təsdiq ediləndən sonra. Real platforma reklaması BLOCKED. Web test ZIP yerli HTTP vasitəsilə işlədilməlidir; gzip nəticəsi yalnız uyğun serverdə əldə edilir. IndexedDB risk və digər boşluqlar `KNOWN_ISSUES.md`-dədir.

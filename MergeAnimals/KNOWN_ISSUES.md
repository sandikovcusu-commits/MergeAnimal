# Məlum problemlər — V0.3.0-dev

- P1: 60 Hz normal bot gameplay-də 16.678 px, 120 Hz-də eyni seed-lərlə 9.190 px-ə qədər floor/sərhəd overlap ölçüldü; >0.01 px resting kontakt nüfuzu çox uzun qala bilər; sürətli divar təmasında nüfuz da qalır; sıfır overlap və real cihazda görünməzlik təsdiqlənməyib. Dərinlik, müddət, tam escape və ilişmə ayrıca `PHYSICS_REPORT.md`-dədir.
- P1: Sıx sahədə böyük merge nəticəsi üçün boş yer tapılmasa cüt kilidli pending qalır və təkrar yoxlanır; uzunmüddətli sıxlıq/Game Over qarşılıqlı təsiri üçün əlavə test lazımdır.
- P1: Konseptlərin orijinalları 1254×1254 RGB opakdır; `concepts/processed/` 512×512 alpha törəmələr avtomatik təmizlənib, kənar və quyruq bölgəsi əl auditinə ehtiyac duyur. Generasiya aləti model ID-ni bildirməyib; kommersiya hüquqları təsdiqlənməyib; oyun sprite-ı kimi qoşulmayıb.
- P1: Real GUI rendering, alt guide oxunaqlılığı, telefon touch hardware, Windows BAT, Android/iOS, müxtəlif rezolyusiya input koordinatları və Web export hələ yoxlanmayıb. Stretch keep konfiqurasiyası fiziki cihaz nəticəsi deyil.
- P2: 100 bot sessiyası məqsədli 90 simulyasiya saniyəsi ilə məhdudlaşdırılıb; nəticələr uzun insan oyunu, oyun müddəti, filə çatma ehtimalı və mobil performans statistikası deyil.
- P2: Sadə `ConfigFile` yalnız best score saxlayır; lokallaşdırma resursları, audio, tutorial, tam menyu, save, son sprite/effect-lər yoxdur. Debug fixture oyun balansı deyil. 120 Hz fizikanın mobil enerji/CPU xərci ölçülməyib.

## V0.4.1 DEV əlavələri
- 12 normal heyvanın AI mənbə model/vendor və Arena kommersiya şərtləri UNKNOWN — bütün 12 sprite üçün release BLOKLU. 1024² Bear/Lion mənbələri də opak checkerboard idi; avtomatik şəffaflaşdırma üz və kənarlarda əl QA tələb edir.
- 24 happy/surprise vizual state, blink, 6 effekt və logo yoxdur; mövcud enum fallback-u yeni üz effekti deyil.
- 20 SVG ikon və səkkiz StyleBox theme var, icon-lar HUD-a bağlanmayıb, UI/kiçik ölçülü vizual qəbul və bütün state-lərin interaktiv yoxlaması yoxdur.
- 8eefda7-də pəncərə screenshot sınağı səhvən köhnə ölçüdə viewport və qara boşluğu capture edirdi; format/ölçü testi tək başına yetərli deyil. Düzəldilmiş capture `45682074271`-də hər ölçü üçün ayrı X11 pəncərəsi çəkir; screenshot-lara baxış barədə `VISUAL_QA_REPORT.md`.
- İnsan oyun testi, mobil touch, FPS və enerji, Web/Windows export və yüksək pikli floor overlap həll edilməyib.

# V0.9.0.1.1 — kommersiya hüquqlarının yekun yoxlanması: BLOCKED

**Nəticə:** texniki təmiz paket hazırlanması kommersiya hüququnun təsdiqi deyil. Rəsmi Arena Terms 2026-02-23 §5(i) Output-un satışını, yayılmasını, host edilməsini və digər kommersiya istismarını məhdudlaşdırır; §§1, 1.1, 3.4 və 3.5(G) da nəzərə alınmalıdır. Agent Mode-a tətbiq olunan ayrıca müqavilə və bu layihə üçün yazılı icazə görünmür. §3.2 istifadəçi ilə Arena arasındakı mülkiyyəti təsvir edir, amma bu, §5-dən qeyd-şərtsiz istisnanı sübut etmir. **Satış, yayma və reklam gəliri üçün konkret icazə təsdiqlənmədiyinə görə BLOCKED.** Bütün bəndlər, rəsmi keçidlər, nəşr tarixləri və istifadəçinin yazılı təsdiq alma addımları `LICENSE_EVIDENCE.md`-dədir.

## 12 yeni vektor — faktiki provenans

Platforma **Arena.ai Agent Mode**, istifadə edilən xidmət Arena Agent Mode kod yazma/orchestration xidmətidir. Mənbə sübutu: `4e9ac3ab535b644cc6fe0bef89c77bf7a6a92f4d` commit-ində `tools/generate_animal_vectors.py`, `tools/render_animal_vectors.cjs`, `art_source/vector_animals/*/normal.svg` və `assets/animals/*/normal.png`. Agent-generated Python sabit path/geometry/paletlərdən SVG yaradır; Node aləti resvg-js 2.6.2 ilə PNG-yə rasterləşdirir. Bu 12 dizayn üçün şəkil generasiya xidməti və əvvəlki raster faylları input kimi istifadə edilməyib. İstifadə edilən AI backend/model adı/ver­siyası mövcud provenans qeydlərində müəyyən edilmir; **UNKNOWN MODEL ≠ avtomatik hüquq yoxdur**. Hüquq blokunun ayrıca sübutu Arena şərtləri və tətbiq olunan müqavilənin/yazılı icazənin bilinməməsidir.

Əvvəlki hesabat generasiya üçün 2026-11-25 yazır; Git qeydi commit vaxtını `2026-11-27T08:21:54Z` göstərir. Bu, sessiyanın verilmiş 2026-11-25 UTC tarixi ilə ziddiyyət təşkil edir; saat/vaxt mənbəyi yoxlanmadığı üçün dəqiq generasiya tarixi **UNKNOWN**. Commit vaxtı əsərin bütün hissələrinin dəqiq yaradılma vaxtı deyil. Bu ziddiyyətə görə generasiya zamanı qüvvədə olan hesab müqaviləsini də avtomatik müəyyən etmək olmaz.

`tests/commercial/audit_vectors.py` hər 12 SVG-ni və 12 PNG-ni ayrı temp qovluğunda mənbədən byte-byte təkrar yaradır; hər SVG XML elementi yoxlanıb: xarici `href/src`, embedded raster/image, script, xarici URL, `use` və unknown texture elementi aşkarlanmadı. Path, circle, ellipse və gradientlər generatorda görünür. 20 ikon, 23 WAV və loqo da byte-byte reproduksiya edildi; 8 theme generasiyası 3 runtime theme-in font istinadını nəzərə alaraq uyğun gəldi. Mənbə yoxlaması işlədilən alqoritmdə köhnə şəkil girişi və üçüncü tərəf kodu kopyası aşkar etmir; **modelin təlimi, bütün mümkün oxşarlıqlar və real müəlliflik** bu testlə sübut olunmur. Avtomatik copyright-free və ya qeyri-pozuntu iddiası edilmir. İnsan/hüquqşünas tərəfindən personaj və trademark oxşarlığı araşdırması hələ tələb olunur.

## Digər runtime aktivləri

| Qrup | Sübut | Status |
|---|---|---|
| 20 SVG ikon | `tools/generate_ui_icons.py`, byte-byte reproduksiya və SVG giriş yoxlaması; per-fayl SHA manifestdə | **BLOCKED**: Agent/platforma və layihə sahibinin hüquqları təsdiqlənməyib. |
| 3 fon/dekor və procedural VFX | `assets/backgrounds/*.svg`, `scripts/effects/MergeEffects.gd`; SVG-lərdə kənar link/raster aşkarlanmadı. Bu fonlar üçün ayrıca generator və ya müstəqil müəllif sübutu yoxdur. | **BLOCKED**, ayrıca oxşarlıq yoxlanmayıb. |
| Oyun loqosu | `tools/generate_logo.py`, DejaVu Sans glyph outlines, byte-byte reproduksiya | **BLOCKED** for Agent-created composition; **ATTRIBUTION REQUIRED** for DejaVu glyphs. |
| DejaVu Sans fontu | embedded name table version 2.37; yerli SHA və upstream license `LICENSE_EVIDENCE.md` | **ATTRIBUTION REQUIRED**; upstream rəsmi TTF binary ilə hash müqayisəsi aparılmayıb, origin yoxlaması açıqdır. Full Bitstream + Arev notice daxildir. |
| 20 SFX, 3 musiqi loop-u | `tools/generate_audio.py`; 23 WAV byte-byte reproducible; heç bir xarici sample girişi görünmür | **BLOCKED**: Agent-created kod/audio üçün tətbiq olunan müqavilə və output hüququ təsdiqlənməyib. |
| Godot Engine / export logoları | Godot MIT, üçüncü tərəf notices; default splash/icons contain Godot logo | **ATTRIBUTION REQUIRED**, logo © 2017 Andrea Calabró, CC BY 4.0, ölçüləndirilmiş ixrac variantları. |
| CrazyGames Godot addon / CDN | `addons/crazygames/LICENSE` MIT; rəsmi asset v2.0.0; uzaq SDK ayrıca | addon **ATTRIBUTION REQUIRED**; CDN/platform şərtləri və entitlement **UNKNOWN/BLOCKED**. Basic reklamsız, Full Launch opt-in. |
| resvg-js və fontTools | MPL-2.0 / MIT development tools; notices daxildir | Binaries runtime-da yoxdur. Alətlərin öz lisenziyaları Agent output üçün icazə vermir. |

`ASSET_MANIFEST.json` per-fayl SHA-256, mənbə, status və istifadə şərtlərini saxlayır. Proyektin bütün kodu üçün ayrıca mülkiyyətçi seçilmiş blanket lisenziya hələ yoxdur; hər hansı digər insan müəllifin/haqq sahibinin razılığını ayrıca yoxlayın.

## Təmiz paket və qalan risklər

Köhnə 12 source sprite, onların 12 köhnə runtime törəməsi, konseptlər və köhnə vizual QA materialları ayrıca **PRIVATE-RESEARCH** arxivindədir; kommersiya yayımı üçün nəzərdə tutulmayıb. İşlək branch-dən həmin 283 vizual çıxarıldı; Git tarixçəsi dəyişdirilməyib və tarixdə qalır. Xəbərdarlıq: əvvəlki ZIP-lər və Git tarixçəsi yenə köhnə materialları saxlaya bilər, kommersiya üçün istifadə edilməməlidir.

Təmiz Godot source ZIP, Web ZIP və ayrıca release-assets qovluğu 295 məlum köhnə vizualın SHA-256 siyahısı ilə yoxlanılır; Web PCK-də 12 köhnə imported `.ctex` fingerprint-i həmçinin baseline ilə müqayisə edilir. Bu, byte-identical köhnə materialları aşkar edir, bütün mümkün dəyişdirilmiş törəmələrin və ya kənar IP oxşarlıqlarının yoxluğunu riyazi sübut etmir. CI nəticələri və real PCK/hash yoxlama qeydləri `docs/asset_audit/` və çatdırılma hesabatındadır. Oyunun reklam, performans, fiziki cihaz, dinləmə və IndexedDB riskləri `KNOWN_ISSUES.md`-də qalır. Bu, hüquqi rəy deyil.

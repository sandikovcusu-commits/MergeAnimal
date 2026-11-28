# V0.9.0.4 — texniki bazis freeze, məhsul qəbulu deyil

12 mövcud heyvan və frame-ləri, palitra, GardenDesign UI/menyular, hazır animasiya və effektlər, Forest Garden/Sunset Safari/Snowy Valley texniki olaraq bu private QA bazisində dondurulur; bu, kritik regressiya aşkar edilsə düzəlişi qadağan etmir. 120 Hz və shared scheduler saxlanıb. Bu qərar human visual/art/audio/play, accessibility, fiziki cihaz, performans və hüquq qəbulunu əvəz etmir. Tam məhsul/AAA freeze və kommersiya paylanması təsdiqlənmir. Yeni matrix-də sintetik Game Over `Save failed` səbəbi araşdırılmalıdır. V0.9.1: vizual/oxunaqlılıq, touch, save-feedback və full-game manual QA; V0.9.2: real Android/mobil FPS, stress və dayanıqlılıq. Bütün risklər `KNOWN_ISSUES.md`-də açıqdır.

---

## Əvvəlki checkpoint (tarixi; yuxarıdakı yeniləmə üstünlük təşkil edir)

# V0.9.0.4 design freeze — QƏRAR GÖZLƏYİR / NOT FROZEN

Character, UI, palette, animation və üç mövzunun yekun freeze-i elan edilmir. Təklif edilən bazis: layihə daxilindəki 12 mövcud SVG/vector və 48 raster facial frame, GardenDesign tokenləri, üç mövcud mövzu və hazırkı kosmetik scheduler; manifest `ASSET_MANIFEST.json`. Bu bazis qəbul sertifikatı deyil.

Bloklayan yoxlamalar: dörd dil × üç tema × beş tələb olunan ölçü × əsas ekranlar üzrə faktiki Godot və Web vizual yoxlama; bütün uyğun dillərdə/mövzularda nəticə və Settings seçim popup-u, Rescue/Rewarded Rescue və Challenge success/failed state-ləri; 12 heyvanın bütün hərəkətlərinin keyfiyyət və resource-lifecycle yoxlanması; nəticəsiz performans müqayisəsinin izahı; təsdiq edilən kritik regressiyaların aradan qaldırılması. `VISUAL_ACCEPTANCE_REPORT.md` və `REGRESSION_REPORT.md` testlə sübut edilməyənləri göstərir.

Freeze yalnız bu qapılarla əsaslandırılan ayrıca qərardan sonra. V0.9.1: full-game QA və funksional/kritik vizual düzəlişlər; V0.9.2: qalan cihaz, dayanıqlılıq, performans və buraxılış risklərinin planlaşdırılması. Bu təyinat riskin qəbul edildiyi anlamına gəlmir. 9.190 px sərhəd nüfuzu, IndexedDB dərhal bağlanma itki riski, dəyişkən Web performansı, real Android/human/audio testlərinin və kommersiya hüquqlarının olmaması açıq qalır. **Commercial BLOCKED**, public distribution icazəsi verilmir.

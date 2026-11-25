# V0.4.1-dev — Graphics completion WIP, release bloklu

- Bear/Lion 512² RGBA normal sprite, AnimalData bağlantısı və 12 fərdi collision overlay; kommersiya mənşəyi məlum deyil.
- 20 orijinal kod SVG ikonu, 8 native Theme/StyleBox palitrası; Forest tema HUD düymələrində istifadə edilir.
- 24 expression, blink, effekt və logo hələ yoxdur. Capture testlərində yaşıl status yalnız fayl/ölçü/skript şərtidir; vizual baxış ayrıca tələb olunur.
- Əvvəlki gameplay saxlanılıb, fizika parametrləri dəyişməyib.

# V0.4.0-dev — DAY 4 WIP, RELEASE BLOKLU

- 10 eksperimental, kommersiya mənşəyi təsdiqlənməmiş sprite, üç kodla yazılmış tema, alpha və collision hesabatları, ortaq preview/body inteqrasiyası.
- Bear/Lion, 24 expression, ikon/düymə/effekt/logo və tam hüquq auditi çatışmır. Bu mərhələ tamamlanmayıb və kommersiya buraxılışına hazır deyil.
- Xvfb real viewport fixture və script error nəzarəti əlavə edilib; 49+61 əvvəlki və 56 DEV yoxlama 0227408-də keçib. Tam pəncərə, digər temalar, mobil/Web yoxlanmayıb. `V040_DEV_STATUS.md`-ə baxın.

# Changelog

## 0.3.0-dev — 2026-11-25 (Gün 3)
- 12 editable AnimalData və ID ilə evolution; ilk beş üçün 30/25/20/15/10 çəkili RNG.
- 1 saniyə combo, konfiqurasiya edilən Golden Merge bonusu, alt evolution guide; real collision üzrə 11 keçid və fil cütü üçün headless regression.
- 100 seed-li bot sessiyası və CCD/divar/radius/tick/material matrisi; nüfuz qalır, risk ayrıca sənədləşdirilir.
- Üç AI üslub konsepti: orijinalda opaque damalı fon; 512×512 alpha törəmələr avtomatik təmizlənib, faktiki model ID və kommersiya şərtləri təsdiqlənməyib; yekun sprite deyil.

## 0.2.1-dev — 2026-11-25
- V0.2 blocked-spawn quick-tap input bərpası düzəldildi; red/green Godot runtime regression əlavə edildi.
- 18 V0.1 screenshot ayrıca audit edildi; original JPG-lər paylaşılmadı.
- Headless Godot 4.7.2 Actions, fizika, multitouch və restart fixture-ları, Windows üçün işə salma skriptləri əlavə edildi. Windows və cihazlar yoxlanmayıb.
- Divar testi 700 px/s zərbədə müvəqqəti nüfuz ölçür, limitasiya açıq saxlanır; yekun sprite və mobil ölçülər yoxdur.

## 0.2.0-dev — 2026-11-25 (Gün 2, UNVERIFIED)
- Mənbədə beş heyvan səviyyəsi, `MergeManager`, merge lock/deferred commit, xal və sadə best score əlavə edildi.
- Cari/next preview vizual kodu birləşdirildi; spawn state, overlap sorğusu, cooldown və input ləğvi əlavə edildi.
- Dəstək/sürət/grace əsasında danger monitor, game-over, pause/restart HUD və debug panel üçün kod əlavə edildi.
- Statik testlər və icra edilməmiş Godot integration/stress fixture-ları əlavə edildi. Mühərrik və görüntülər əlçatan deyil; funksional və fizika qəbul meyarları **UNVERIFIED**.

## 0.1.0 — 2026-11-25 (Gün 1, prototip)
- Rəqib səhifələri araşdırması, GDD, art bible və arxitektura planı.
- Godot 4 Compatibility layihəsi, portret əsas səhnə, üç diaqnostik heyvan, fizikalı düşürmə və divarlar üçün mənbə.


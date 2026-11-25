# QA hesabatı — Gün 1, 25 noyabr 2026

## Nəticə
Mənbə prototipi yaradılıb, lakin **Gün 1-in işlək Godot Editor/F5 qəbul meyarı bu mühitdə təsdiqlənməyib**. Statik yoxlamalar runtime, rendering və ya fizikanın işlədiyini sübut etmir. Buraxılışa hazır deyil.

| Yoxlama | Real nəticə | Sübut / məhdudiyyət |
|---|---|---|
| Repository və mühit | İcra edildi | Başlanğıc `7e183abd`, Linux x86_64, Python 3.11.2; quraşdırılmış `godot`/`godot4` tapılmadı. |
| Resource yolları və konfiqurasiya | PASS | `python3 tests/unit/check_project.py`: 11 mətn faylı skan edildi, istinadlar və əsas sazlamalar yoxlandı. |
| GDScript sintaktik parse | PASS | `gdtoolkit` parser 4 GDScript faylını qəbul etdi. Bu Godot-un öz semantic parseri deyil. |
| Godot Editor import/F5 | İCRA EDİLMƏYİB | Godot binarı mövcud deyil; rəsmi binar download-un redirect hostu şəbəkə məhdudiyyəti ilə əlçatmazdır. |
| `tests/integration/day1_smoke.gd` | İCRA EDİLMƏYİB | Godot tələb edir. Seed, drop/cooldown, input, gravity və sərhəd testləri hazırlanıb, nəticələri məlum deyil. |
| Ekran görüntüsü / manual mobil input | İCRA EDİLMƏYİB | Qrafik Editor və cihaz testi yoxdur. |
| 100 ssenari, 1000 düşürmə, 30 dəqiqə, Web/profiler | İCRA EDİLMƏYİB | Sonrakı mərhələ qəbul yoxlamalarıdır, heç bir FPS/RAM iddiası yoxdur. |

## Problem / bloklayıcı protokolu
**ENV-001 — Godot runtime yoxlaması bloklanıb.** Addımlar: `command -v godot; command -v godot4`; rəsmi 4.7.2 Linux arxivini GitHub-dan yüklə. Nəticə: binary tapılmadı, GitHub 302 ilə `objects.githubusercontent.com` hostuna yönləndirdi və əlaqə `SSL_ERROR_SYSCALL` ilə kəsildi. Təsir: bütün `.tscn`, `.tres`, `.gd`, xüsusilə `Game.gd` və `Animal.gd`-nin Godot semantic parseri və fiziki icrası yoxlanmayıb. Kök səbəb şəbəkə host məhdudiyyəti və əvvəlcədən quraşdırılmış mühərrikin olmamasıdır; layihə xətası təsdiqlənməyib. Rəsmi 4.7.2 source-u codeload-dan alındı, headless editor build cəhd edildi, lakin uzun kompilyasiya tamamlanmadan dayandırıldı; əldə edilmiş build uğurlu sayılmır. Həll: Godot 4.7.2 quraşdırılmış mühitdə README əmrlərini çalışdır, aşkar edilən hər semantic/runtime xətanı düzəlt və testləri təkrar et. Əvvəl/sonra runtime və regression nəticəsi: mövcud deyil. Risk: açılış, collision və input hələ təsdiqlənməyib.

## Bilinən məhdudiyyətlər
- Yalnız üç bərabər ehtimallı placeholder resource; vizuallar son məhsul deyil. 12 heyvan, final PNG, səs və temalar yoxdur.
- Merge, score, game over, pause, save, localization, reklam, challenge və digər V1 sistemləri implementasiya edilməyib; danger xətti vizualdır.
- Sərhəd dəyərləri və StaticBody2D shape-ləri ayrıca redaktə edilir; hər ikisi birlikdə yenilənməlidir.
- Spam zamanı üst-üstə spawn, tunneling, kənara çıxma və touch/mouse davranışı hələ stress və cihaz testindən keçməyib.

## Növbəti addım
Əvvəl Godot 4.7.2 import və `day1_smoke.gd`-ni işlədib nəticələri və ekran görüntüsünü qeyd et. Gün 1 qəbulunu yalnız bundan sonra təsdiqlə. Ardınca Gün 2-də deferred atomik merge, score, grace-period game over və fizika regression/stress testlərini qur.

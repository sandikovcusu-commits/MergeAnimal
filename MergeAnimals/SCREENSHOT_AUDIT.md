# Screenshot və kod auditi — V0.1 → Gün 2

25 noyabr 2026. Bu söhbətdə 18 görüntü faylı/əlavəsi mövcud deyil. İstifadəçinin təsvirləri görüntülərin özünün müstəqil müşahidəsi deyil. Hər şəkil ayrıca nəzərdən keçirilməsi üçün gözləyir; lütfən 18 faylı əlavə edin. Heç bir şəkildən fakt uydurulmayıb.

| Şəkil | Görünən problem | Ehtimal / mənbə |
|---|---|---|
| 01 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 02 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 03 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 04 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 05 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 06 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 07 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 08 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 09 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 10 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 11 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 12 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 13 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 14 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 15 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 16 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 17 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |
| 18 | Əlçatan deyil — UNVERIFIED | Təqdim olunduqdan sonra fərdi audit ediləcək |

## Kodla təsdiqlənən ilkin audit (commit a2692b8)
- `Game.gd:70–82`: drop instantiate edir, data və koordinat təyin edir, sonra `Pieces`-ə əlavə edir; `_ready()` `Animal.gd:8–18` radius/mass/material qurur. Spawn overlap yoxlanmır. Cooldown yalnız sürətli təkrarı məhdudlaşdırır; preview-nin yeni fiziki obyektlə vizual üst-üstə düşməsi mümkündür, ancaq konkret görüntünün səbəbi məlum deyil.
- `Game.gd:87–97` preview-ni `_draw` daxilində dairə kimi çəkir. `AnimalVisual.gd:4–17` fiziki heyvanın göz/ağzını ayrıca çəkir. Next `Game.gd:84–85` yalnız ad göstərir. Buna görə mənbədə üz uyğunsuzluğu təsdiqlənir; sprite və redraw problemləri haqqında görüntü olmadan əlavə nəticə yoxdur.
- `Game.gd:44–65`: mouse və touch `_unhandled_input` vasitəsilə `drop_animal()`-a gedir. `project.godot` hər iki emulation seçimini söndürür; ləğv olunmuş touch ayrıca idarə edilmir. İkiqat doğulma konkret görüntüdən təsdiqlənmir.
- `Animal.tscn:6–9` contact monitor və CCD açıqdır, lakin `body_entered` bağlantısı və merge manager yoxdur. StaticBody və RigidBody səhnələrində layer/mask təyin edilməyib: Godot default layer 1, mask 1. Eyni növlərin birləşməməsinin kod səbəbi sistemin ümumiyyətlə olmamasıdır.
- `Game.gd:92`: təhlükə xətti yalnız `draw_line`-dır. Vaxtölçən, dəstək yoxlaması və Game Over yoxdur. Statik təsvir təhlükənin davametmə müddətini sübut etməz.
- 3 resource var; merge/score/save/game over olmaması yığılmaya səbəb ola bilər, amma konkret seansın dolma səbəbi şəkillər və runtime testləri olmadan təsdiqlənmir.

İstinadlar: [Godot 4.7 RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html), [physics introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html), [input](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html), [ScreenTouch](https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html), [space queries](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html).

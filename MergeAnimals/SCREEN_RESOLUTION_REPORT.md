# Ekran nisbəti — analitik yoxlama, vizual test deyil

`project.godot`: 720×1280, `canvas_items`, `keep`. İdeal uniform ölçüləmə (`min(width/720,height/1280)`):

| Ekran | Şkala | Oyun sahəsinin ümumi görünən canvas ölçüsü | Təxmini boş kənar |
|---|---:|---:|---:|
| 360×640 | 0.5 | 360×640 | 0 |
| 360×800 | 0.5 | 360×640 | yuxarı/aşağı 80 |
| 720×1280 | 1 | 720×1280 | 0 |
| 1080×1920 | 1.5 | 1080×1920 | 0 |
| 1366×768 | 0.6 | 432×768 | sol/sağ 467 |
| 1920×1080 | 0.84375 | 607.5×1080 | sol/sağ 656.25 |

Bunlar yalnız konfiqurasiyadan çıxarılan nəzəri hesablardır, real render/screenshot və ya OS pəncərə ölçmə nəticəsi deyil. `keep` eyni X/Y miqyasını nəzərdə tutur, lakin ekranlarda sprite/collision nisbəti, guide oxunaqlılığı, kəsilmə və inputun OS/cihaz coordinate transformu test edilməyib. Real telefon, landscape və masaüstü GUI testi tələb olunur.

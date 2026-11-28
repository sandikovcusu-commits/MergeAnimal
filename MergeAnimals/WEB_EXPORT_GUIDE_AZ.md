# Web export — sınaq təlimatı (natamam V0.8)

Godot **4.7.2 standard** və eyni versiyalı export template-ləri tələb olunur. `project.godot` açın, importun bitməsini gözləyin, Export menyusunda **Web (single-threaded)** presetini seçin və `index.html` export edin. Yaradılmış bütün faylları birlikdə saxlayın. Compatibility/WebGL2 və single-thread variantı seçilmişdir; SDK, monetizasiya və platforma təsdiqi yoxdur.

Test arxivini açaraq həmin qovluqda:

```sh
python3 -m http.server 8765
```

Brauzerdə `http://localhost:8765/` açın. `file://` ilə açmayın; istehsalat serverində `.wasm` üçün `application/wasm` MIME və uyğun sıxılma tələb olunur. Səs üçün istifadəçi jesti və WebGL2 dəstəyi lazımdır. Brauzer məlumatlarını silmək IndexedDB `user://` yaddaşını silə bilər; gizli rejim və iframe məhdudiyyətləri fərqli ola bilər. Müxtəlif origin-lər müxtəlif yaddaş istifadə edir. Təcrübə üçün verilmiş build kommersiya nəşri deyil.

`.github/workflows/godot-web.yml` manual `workflow_dispatch` export və məhdud Playwright sınağını icra edir. Müvəqqəti unreferenced Git blob istifadə edərək sınaq sübutunu daşıyır; bu blob Git tarixçəsi deyil və sonradan yığışdırıla bilər. `WEB_QA_REPORT.md` real əhatə dairəsini və açıq sınaqları göstərir.

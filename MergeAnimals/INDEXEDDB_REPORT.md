# V0.9.0.2.1 — IndexedDB sınaq qeydləri

Godot 4.7.2-də `FileAccess` / rename Web MEMFS üzərindədir. [Engine source](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp) növbəti main-loop-da async sync başladır; [JS sync](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/library_godot_os.js) error-u C++ callback-ə ötürmür. [Rəsmi Web sənədləri](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html) storage restrictions və yanlış persistence pozitivləri barədə xəbərdarlıq edir. Yeni kod paralel `syncfs` çağırmır; exact bytes üzrə sonradan read-only IDB transaction tamamlandıqda təsdiq verir. Bu disk `fsync`, eviction əleyhinə zəmanət və ya multi-file atomiklik deyil.

Hər brauzerdə ayrıca QA build ilə test:

| Hal | Metod və müşahidə |
|---|---|
| Lokal yazma xətası | `.tmp` yolunda directory yaradılan **süni fixture**; lokal səhv `failed`, sonra uğurlu təkrar təsdiqləndi. |
| Oxu xətası | Browser API-yə **süni** `SecurityError`; unconfirmed, patch silindikdən sonra yeni yazı təsdiqləndi. |
| Permission | `indexedDB.open` **süni** `SecurityError`; unconfirmed, patch silindikdən sonra yeni yazı təsdiqləndi. Real permission policy və quota deyil. |
| Abort / yazı xətası | Browser-in həqiqi IDB readwrite transaction-u **süni** `abort()` ilə dayandırıldı; təsdiq olmadı; son sınaqlarda patch silinib yenidən yazılınca təsdiq oldu. |
| Gecikmə | Eyni database-də real readwrite transaction **test tərəfindən 5 s açıq saxlandı**; bu müddətdə pending, buraxıldıqdan sonra verified. Bu süni bloklamadır. |
| Korrupt və recovery | Primary faylı **süni** korrupt edildi; eyni işləyən prosesdə power-up checkpoint seçildi. Bu ayrıca restart sonrası disk korrupt testi deyil. |
| Ani bağlanma | Ayrı production-export power-up sınağında input-dan dərhal sonra browser context bağlanıb yenidən açılır; nəticə müşahidədir, 100% test deyil. |

Sınaqlar təkrarlananda tam eyni nəticə zəmanəti yoxdur. Əvvəlki Firefox [45977953486](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45977953486) injected abort sonrası 50 saniyə ərzində sonrakı save-i təsdiqləyə bilmədi; bu, mühüm açıq riskdir. Sonrakı test maksimum üç yeni cəhdlə uğurla tamamlandı, əvvəlki uğursuzluğu ləğv etmir. [45978038241](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45978038241) tarixi 0.7 asset import zamanı Godot crash etdi; sonrakı workflow bir təmiz retry imkanına malikdir. Real cihaz və real browser qəza sınaqları aparılmayıb.

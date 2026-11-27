# V0.9.0.2.1 — faktiki Web və native QA

Godot 4.7.2; Ubuntu GitHub Actions, Playwright Chromium və Firefox, software GL. Fiziki cihaz və real CrazyGames reklamı deyil. Tətbiq kodu `cbf38fd`; save test və fixture arxivləmə protokolu `ecb0553`. Tam nəticələr sətir-sətir CI loglarında və ayrıca log paketindədir.

| Sınaq | Chromium | Firefox | Məhdudiyyət |
|---|---|---|---|
| 10/50/100 save, generation, read-back, restart | [52/52](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45979473262) | [52/52](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45979477664) | QA-probe build, eyni thread-də sinxron tombstone burst; multi-tab/true parallel və aktiv board stress deyil. |
| Ayrı mağazalar: best/collection/statistics, settings/audio/language, theme, challenge, achievement | PASS | PASS | Eyni testdə deterministik fixture və restart; bütün real gameplay kombinasiyaları deyil. |
| 0.6.1, 0.7.0, 0.8.0, 0.9.0.2 fayllarının Web bərpası | PASS | PASS | 0.6/0.7 köhnə layihənin native write-phase-ından, 0.8/0.9 köhnə Web capture-dan; yalnız seçilmiş nümunələr. Continue-dən sonra canlı fizikada score arta bilər; bütün ayrı store-ların köhnə versiya miqrasiyası yoxlanmayıb. |
| Lokal write error, IDB read denial, abort, gecikmə, synthetic permission | PASS | PASS | Test inyeksiyasıdır, real disk/permission/quota xətası deyil. Abort sonrası əvvəlki Firefox təkrarı uğursuz idi; aşağıya baxın. |
| Corrupted primary / backup | PASS | PASS | Eyni işləyən prosesdə power-up checkpoint-ə recovery; restart sonrası korrupt-disk testi deyil. |
| Rewarded Rescue, duplicate və stale callback, lokal failure/retry, refresh | [68/68](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45978046370) | [68/68](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45978050443) | Mock SDK və tainted Game Over fixture, real ad deyil. Ayrı browser restart sonrası reward yoxlanmayıb. |
| Ani bağlanma | OBSERVATION | OBSERVATION | Real production export-da browser context input-dan dərhal sonra bağlanır; son action-ın qorunmasına zəmanət verilmir. Aşağıdakı regressiya run-a baxın. |

Native/asset işləri `cbf38fd`-də 12 workflow nəticəsində success: runtime, session, Undo, Remove, Rescue, Challenge, Achievement, Theme, Collection, render, Game Feel, kommersiya asset auditi. CI success tam acceptance və hüquq təsdiqi deyil. Standart Web export, ayrı instrumentli QA build və capture fixture-ləri bir-birindən ayrılıb.

**Uğursuz təkrarlar:** [45977949360](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45977949360) və [45978042695](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45978042695) 0.6 canlı simulyasiyada əlavə merge olduqda köhnə score ilə bit-bərabərlik tələb edən erkən assert-də failed; sonrakı test score azalmasını rədd edir və artımı loglayır. [45977953486](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45977953486) Firefox-da süni abort-dan sonra növbəti save 50 s ərzində təsdiqlənmədi. Daha sonrakı sınaqda üçə qədər yeni cəhdə icazə verildi və keçdi; bu risk qalır. [45978038241](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45978038241) köhnə 0.7 asset import crash, daha sonra yenidən icra edildi.

Real storage quota, private browsing, actual permission policy, OS crash/power loss, iki tabın paralel yazması, bütün locale/viewport statusunun insan tərəfindən görünüşü və bütün köhnə save-store kombinasiyaları yoxlanmayıb. Son təsdiqlənməmiş action itə bilər. Əvvəlki mərhələ hesabatı `docs/archive/WEB_QA_REPORT_V0.9.0.2.md`-də saxlanılıb.

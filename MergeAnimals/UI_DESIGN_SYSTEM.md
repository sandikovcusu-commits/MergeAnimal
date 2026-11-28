# V0.9.0.4 — UI design system (partial)

`GardenDesign.gd` forest/sunset/snow üçün panel, border, primary, secondary və ink rənglərini, radius və yüngül shadow StyleBox-larını saxlayır. Əsas menyu/HUD əvvəlki checkpoint-dən qorunub. Bu davamda Collection kartları, Back düyməsi, Statistics-in 11 ümumi göstərici və 12 növ sayından ibarət sətirləri, Challenges və Achievements panel/kartları eyni tokenlərə gətirilib. Collection kilid ikonu, muted sprite, level və mətnlə vəziyyəti göstərir; bütün mövcud məlumat və davranış saxlanır.

Əvvəl/sonra faktiki Chromium 720×1280 ekranları: `docs/visual/v0904/continuation/screens/` ([46057215366](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46057215366), əvvəl `01e05aa`). Azərbaycan Collection nümunəsi də var. Virtual scroll altında qalan sətirin kənarda kəsilməsi viewport məzmun sərhədidir; həmin sətirlər scroll ilə açılır. Bu nümunələr bütün 4 dil × 3 mövzu × 7 ölçüdə clipping olmadığına sübut deyil.

Settings, Pause, Game Over/Rescue, challenge success/failure bütün dizayn tokenlərinə migrasiya edilməyib; düymə/sürüşdürmə, klaviatura fokusları, kiçik mobil ekran, uzun mətn və insan review tam qəbuldan əvvəl ayrıca yoxlanmalıdır. Heç bir gameplay düyməsi və ya mövcud məlumat qəsdən silinməyib.

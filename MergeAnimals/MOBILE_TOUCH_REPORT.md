# V0.8.1.2 — əlavə mobil touch nəticələri (delta)

Real cihaz deyil: Linux Chromium + Playwright/CDP ilə 393×873 simulyasiya olunmuş touch. [45887924990](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887924990) 29/29: Play, Tutorial Skip, koordinat x≈260-da bir düşürmə, Pause (əlavə düşürmə yox), Main Menu, Continue (saxlanmış bir heyvan), Restart (köhnə run təmizlənir, düşürmə olmur), x≈470-də bir yeni düşürmə. Tutorial/Pause/Continue-nun hər biri 6 viewportda çəkildi və canvas/DOM ölçüləri ölçüldü. Test `9b2cb4e`-dir; istehsal UI kodu `bad7a03` ilə eynidir.

Son UI kodunda [45887166397](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887166397) touch 12/12, [45887169489](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887169489) Rescue fixture 13/13; əvvəlki resize, touchcancel, multi-touch, Undo/Remove yoxlamaları qorunub. Son layout üçün Tutorial Skip həqiqi touch ilə yoxlanıb. Fokus/fullscreen sınağının ən son təkrarı [45886558456](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45886558456), əvvəlki panel düzəlişində 5/5 və tab-switch hadisəsi olmadığı üçün **SKIP**; yeni panel yalnız yerini dəyişir, real tab dəyişməsi yenə təsdiqlənməyib. Firefox touch və real Android/iOS yoxlanmayıb. Konkret ssenarilərin PASS nəticəsini bütün mümkün touch sıralarına şamil etməyin.

---
# V0.8.1.2.1 — Touch regression delta

**Simulated Chromium touch only, not real Android/iOS.** CDP dispatches touch events into a real Godot 4.7.2 WebAssembly build. The original `touchcancel` interception and active-touch resize invalidation from V0.8.1.2 remain in place. This report supplements the previous report in Git at `f466d78`.

| Check | Result / scope |
|---|---|
| Original eight: Play, one touch/one drop, Pause no drop, multi-touch cancellation, fresh touch after cancel, active-touch resize, Undo use, Remove selection | P in [45879849567](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879849567), `2ce25a1`, 12/12 total assertions including new checks. Counts read from saved game state; not a proof for every gesture. |
| Scroll without drop | P for a Collection swipe and substantial changed content; no gameplay board is active on Collection. Other scroll panels have the same handler but were not individually touch-swiped. |
| Two overlapping fingers | P: exactly one gameplay drop for tested ordering; both-finger cancel produces none. Not exhaustive event ordering. |
| `touchcancel` on gameplay / Play / Remove | P: canceled held gameplay touches do not drop; canceled Play stays in menu; canceled Remove selection does not delete a body or spend use. |
| Rescue and canceled Rescue | P with simulated touch, isolated tainted Game Over fixture; canceled button press does not spend use, subsequent valid Rescue spends one and removes bodies, with saved state checked. [45880619913](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45880619913), `2ce25a1`. Natural Game Over progression is not established by this fixture. |
| Focus loss, fullscreen entry/exit | DOM focus loss while held produces no drop; fullscreen entered and exited and did not drop: [45880610399](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45880610399), `2ce25a1`. Fullscreen is requested by a temporary test-page button. |
| Real tab switch | **SKIPPED**: headless switch emitted neither blur nor hidden; no reliable lifecycle event to exercise. |
| Firefox touch, physical Android/iOS, device rotation/safe area, OS interruptions | **NOT TESTED**. Firefox desktop mouse paths passed elsewhere. |

New fixes: Remove now commits on valid release rather than press; an autoload handles DOM `touchcancel` by notifying the GUI to cancel pending button presses, fixing the observed canceled Rescue/Play activation. Browser-level handling and engine input behavior remain platform-dependent. The above is specific scenario evidence, not a universal guarantee that every possible touch yields at most one operation. Hardware testing is still required.

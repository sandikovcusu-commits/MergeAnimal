# V0.9.0.3 — Collision report

`docs/physics/overlays/` içində 12 statik sprite/circle overlay, `sprite_collision_measurements.csv` içində alpha ölçmələri var. 512×512 normallaşdırılmış mənbələrin hamısında alpha > 8 piksel radius 256 çevrəsindən kənarda deyil; rabbit/bear qulaqları, elephant xortumu və lion yalı da daxil. Bu, statik bounding-art ölçüsüdür: bütün şəffaf dairə sahəsi heyvanla dolu deyil, animasiyalı transformların və oyun hissinin sübutu deyil; sprite dəyişdirilmədi.

`docs/physics/captures/collision-debug-natural-play.png` real Chromium mouse click-ləri ilə instrumentli oyunda debug dairələridir (score 4); eyni run video faylı ayrıca təqdim edilir. Bu qısa playthrough-dur, 12 heyvanın hamısını ekranda göstərmir. Statik overlay-lər in-game debug screenshot ilə eyniləşdirilməməlidir.

120 Hz baza, 5 saniyəlik tək-drop fixture: 12 heyvanda max floor penetration mouse 4.1903, hamster 9.1903, rabbit 5.6505, cat 2.1709, dog 9.1709, fox 7.7515, raccoon 7.3923, koala 8.0935, panda 0.6770, bear 4.5594, lion 1.5058, elephant 0.6946 px. Sonda hamısı yatmışdı, son sürət 0; ilk yüksək sürətli kadrlar yenə hədəfi pozur. 10/20/40 body sabit saylı 6 s pile (merge kilidli, iki kiçik heyvan) max floor 5.327/7.371/6.174 px və pair penetration 6.533/7.881/8.681 px, full-escape frame 0. Bu, böyük və kiçik qarışıq yığının və ya təbii oyun sonunun sübutu deyil. Raw loglar `docs/physics/experiments/`.

Məqsəd 1–2 px **ödənməyib**; 100 seed yalnız sonlu avtomatlaşdırılmış nümunədir və bütün mümkün tunneling, corner, crushing və jitter hallarını istisna etmir. Fiziki cihazda animasiya/toxunuş və hiss yoxlanmayıb. Daha ətraflı metod və CI `PHYSICS_AUDIT_REPORT.md`.

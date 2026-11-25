# Merge Animals: Wild Garden

**V0.1.0 — Gün 1, fizika prototipi; buraxılışa hazır deyil.** Tam redaktə edilə bilən Godot mənbə layihəsidir; EXE və ya HTML prototipi deyil.

## Başlatma
1. Godot **4.7.2.stable** quraşdırın, Project Manager-də bu qovluğun `project.godot` faylını import edin.
2. Editor açıldıqda F5 basın. Mausla sahənin içində basıb buraxın və ya barmaqla toxunub sürüşdürüb buraxın. Rəngli diaqnostik obyektlər düşür və divarlara toxunur; yuxarıdakı yazı növbəti obyekti göstərir.
3. `scenes/game/Game.tscn` daxilində divar shape-ləri və Game Inspector-da spawn hündürlüyü, sahə sərhədləri, cooldown, seed və heyvan siyahısı dəyişir. Divarları dəyişdikdə Game-də `left_bound`, `right_bound`, `floor_height` dəyərlərini də uyğunlaşdırın. `resources/animals/`-da radius, kütlə, material və digər parametrlər var. Sıfır olmayan `test_seed` təkrarlanan ardıcıllıq verir.

## Nə yoxdur
Merge, xal, danger/game over (qırmızı xətt yalnız dekorasiyadır), save, menyu, challenge, audio, tərcümə, SDK və yekun sprite-lar hələ mövcud deyil. Spawn hazırda yalnız üç resource arasında bərabər paylanır; yekun çəkilər Gün 3 üçündür. Placeholder-lar kommersiya aktivləri deyil.

## Yoxlamalar
```
python3 tests/unit/check_project.py
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/integration/day1_smoke.gd
```
Godot testləri üçün əvvəl editor import edilməlidir. `QA_REPORT.md`-də yalnız bu sessiyada faktiki icra edilmiş nəticələr, qalan iş və mühit məhdudiyyətləri göstərilir. `RESEARCH.md`, `GDD.md`, `ART_BIBLE.md`, `docs/ARCHITECTURE.md` mərhələ üçün əsas sənədlərdir.

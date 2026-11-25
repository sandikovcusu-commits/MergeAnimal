# Məlum problemlər və risklər — 0.2.0-dev

- **P0 / UNVERIFIED:** Godot 4.7.2 Editor importu və heç bir runtime/fizika testi icra edilməyib. Mümkün semantic/API səhvləri, faktiki merge və game-over davranışı hələ təsdiqlənməyib.
- **P0 / BLOCKED:** 18 istifadəçi screenshot-u bu sessiyada əlavə edilməyib; fərdi screenshot auditləri mümkün deyil.
- **P1 / UNVERIFIED:** Sıx sahədə yeni böyük dairə üçün 96 px ətrafında boş mövqe tapılmasa, iki heyvan kilidli qalır və merge sonra yenidən sınaqdan keçirilir. Uzun müddətli sıxlıq, performans və game-over qarşılıqlı təsiri real sınaq tələb edir. Heyvanları səbəbsiz silmir.
- **P1 / UNVERIFIED:** Dəstək üçün physics contact normal və speed istifadə edilir; sleep, yüksək sıçrayış, fırlanma, dolu qalaq və zəif cihazlarda yanlış Game Over sınaqdan keçirilməlidir.
- **P1 / UNVERIFIED:** Spawn query və preview-nin fizika ilə sinxronluğu, multitouch, ləğv, emulyasiya və ekrandan kənarda buraxma real brauzer və cihazlarda yoxlanmayıb.
- **P1:** Beşinci səviyyə müvəqqəti maksimumdur; Dog + Dog birləşmir. 12 səviyyə və Golden Merge Gün 3 üçün planlanır.
- **P2:** UI yalnız İngiliscə, müvəqqəti fiqurlar var, mobil responsive screenshot yoxdur. Debug overlay yalnız debug build və Inspector seçimi ilə işləmək üçün nəzərdə tutulub.
- **P2:** Best score üçün yalnız sadə ConfigFile var; backup, sessiya save, reklam, challenge, kolleksiya, audio, tutorial, lokallaşdırma, tam menyu və yekun aktivlər yoxdur.
- **P2:** Başlanğıc spawn çəkiləri hələ 30/25/20/15/10 deyil; əvvəlki kimi üç növ bərabərdir. Fizika materialları ölçülməyib və balanslaşdırılmayıb.

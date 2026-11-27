# V0.9.1 başlanğıc checkpoint

Baza: `481c8885ab3d91b5dfe39838e494f1f016a900fe`, branch `arena/2b071717-mergeanimal`; HEAD bu baza ilə eyni idi, işlək ağac təmiz idi. `KNOWN_ISSUES.md`, `VISUAL_ACCEPTANCE_REPORT.md`, `DESIGN_FREEZE.md`, 192 sətrlik `VISUAL_TEST_MATRIX.csv`, `tests/web` save/quality/reward testləri və `tests/integration` mövcud testlər nəzərdən keçirildi. Native Godot/Xvfb bu mühitdə quraşdırılmayıb: Godot 4.7.2 CI-dən istifadə edilir. Baza son Web build CI [46067101278](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46067101278) və source package mövcuddur; yeni checkpoint üçün təzə build ayrıca yaradılacaq. Başlanğıc baxışı və paket doğrulaması tam V0.9.1 qəbulu deyil.

İlk prioritet sintetik Game Over save xətası, sonra A–E mərhələləri. Tamamlanmamış iş tamamlanmış göstərilməyəcək; kommersiya istifadəsi/paylanması BLOCKED, PR draft.

## İcra vəziyyəti

A hissəsi: fixture səbəbi və düzəliş `SAVE_FAILED_INVESTIGATION.md`; Chromium/Firefox save regression və reward mock tamam, natural Game Over açıq. B hissəsi: 100 seed × 2 tick bot işlədilib, full gameplay/12-animal matrisi açıq. C, D və E tamam deyil. Həqiqi texniki qəbul elan edilmir.

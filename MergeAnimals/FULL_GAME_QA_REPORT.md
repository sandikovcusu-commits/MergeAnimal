# V0.9.1 — real icra checkpoint-i (PARTIAL)

Baza `481c8885ab3d91b5dfe39838e494f1f016a900fe`; ilkin təmiz checkpoint `aa4c45f`. Design freeze qorunur; yeni mexanika, fizika parametri və ya save sisteminin yenidən qurulması yoxdur. Başlanğıcda V0.9.0.4 sənədləri və 192 hüceyrəlik matrisi, testlər yoxlanıb. Faktiki Godot 4.7.2 CI runtime və Web release export yaradılıb. Son checkpoint-lərin dəqiq CI statusu PR və loglarda qeyd olunur.

- **A — PARTIAL:** Game Over mesajının konkret fixture səbəbi müəyyənləşdirilib və fixture düzəldilib; hər iki browserdə old/new ssenari 11/11, save integrity 52/52; reward mock 68/68. `SAVE_FAILED_INVESTIGATION.md`. Tam təbii Game Over əldə olunmayıb; uzun sessiyada yeni P1 pending merge/drop/save liveness xətası aşkar edilib və düzəliş gözləyir.
- **B — PARTIAL:** `762b7a6` 100 seed × 60 Hz və 100 seed × 120 Hz natural physics bot [46068767008](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46068767008), hər biri 90 simulyasiya saniyəsi cap; 120 Hz-də 100/100 cap, Game Over deyil. Ayrıntılar `GAMEPLAY_TEST_REPORT.md`. 12 səviyyənin hər tələb olunan aspekti ayrıca yoxlanmayıb.
- **C — NOT COMPLETED:** 20 Challenge və 15 Achievement üzrə tam V0.9.1 case-by-case matrix və natural completion/A15 hələ icra edilməyib. Köhnə testlərin mövcudluğu bunun əvəzi deyil.
- **D — PARTIAL:** rewarded mock və free Rescue fixture yoxlanıb. 44px real hitbox düzəlişi/auditi, dörd dildə bütün ekranlar və yeni V0.9.1 Web audio regresiyası hələ tamam deyil. Mövcud V0.9.0.4 29/29 touch və audio 47/47 baseline-dır, bu mərhələnin əvəzləyicisi deyil.
- **E — NOT COMPLETED:** tam regression, uzun sessiya diaqnostikası, yeni performance ölçüləri və yekun paketlər tamam deyil. Performance INCONCLUSIVE; real mobil FPS və insan play/audio V0.9.2.

Kritik risklər `KNOWN_ISSUES.md`, xəta statusları `BUG_TRACKER.csv`. Nə AAA, nə V0.9.1 technical acceptance elan edilir. Həqiqi cihaz/insan qəbulu və kommersiya hüquqları yoxlanmayıb; commercial use/distribution **BLOCKED**, PR #1 draft, yalnız private test.

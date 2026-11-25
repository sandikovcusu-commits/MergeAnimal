# Məlum problemlər — V0.2.1-dev

- P1: 700 px/s divar fixture-də 60 Hz-də 6.636 px-ə qədər anlıq radius nüfuzu ölçülüb; sıfır overlap təmin edilmir. Real gameplay/render təsiri və başqa cihazlar yoxlanmayıb. `PHYSICS_REPORT.md`.
- P1: Sıx sahədə merge üçün 96 px radiusda boş yer tapılmasa cüt kilidli pending qalır və təkrar yoxlanır; uzun müddətli sıxlıq/Game Over təsiri yoxlanmayıb.
- P1: Real touch hardware, Windows BAT, vizual render, Android/iOS və müxtəlif ekran ölçüləri, sıçrayış/sleep/focus-loss yoxlanmayıb. Synthetic event real cihaz əvəzi deyil.
- P1: Placeholder proqramla çəkilmiş vizuallar hələ mövcuddur; istifadəçi yeni sprite istəməyib. Yekun kommersiya qrafikası hazır deyil, DEV statusu saxlanır.
- P2: Beşinci səviyyə Dog müvəqqəti maksimumdur; eyni üç başlanğıc növü seçilir. UI ingiliscədir. Tam save, audio, tutorial, lokallaşdırma, menyu və son aktivlər yoxdur.
- P2: Testdə Linux Actions headless ölçüləri mobil performans demək deyil. Rəqib oyunlarının real oynanması və mobil metriklər tədqiq edilməyib (`RESEARCH.md`).

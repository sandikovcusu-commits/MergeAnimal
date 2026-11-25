# Texniki arxitektura

Gün 1: `Game.tscn` Godot main scene-dir; `Game.gd` input/spawn-ı idarə edir, Inspector-da cooldown, seed və animal resource siyahısı, səhnədə divarlar dəyişdirilir. `Animal.tscn` RigidBody2D və CircleShape2D istifadə edir; radius, kütlə, friction və bounce `AnimalData` resource-dan gəlir. Şəkillər yerinə kodla çəkilən diaqnostik fiqurlar var. Compatibility renderer, 720×1280 canvas-items stretch və portrait istifadə edilir.

Gün 2 planı: MergeManager collision siqnalında yalnız cütü təsdiq və lock etsin; deferred commit köhnə cütü deaktiv/silsin, təhlükəsiz orta nöqtəni clamp etsin, yeni heyvanı yaratsın və score-u bir dəfə artırsın. Collision zamanı ağacı dəyişmək olmaz. Müxtəlif səviyyələr birləşməz; üçlü toqquşmada eyni obyekt ikinci dəfə lock edilməz. Chain merge üçün yeni obyekt normal fizika növbəsində işə düşər. Grace period yalnız yerləşmiş və yavaş heyvana tətbiq edilməlidir.

Daha sonra: SaveManager versiyalı atomik save/backup və RNG state, challenge/theme resource-ları; AdService adapter callback-ləri və mükafat idempotentliyi; TranslationServer; audio və UI ayrı məsuliyyətlərlə. Bunlar planlaşdırılır, artıq yaradılmış kimi qəbul edilməməlidir. Editor parametrləri üçün səhnə/resource-lar birbaşa dəyişdirilməlidir. Web-də focus, audio gesture, storage və SDK-lar ayrıca test tələb edir.

# Texniki arxitektura — 0.2.0-dev

`Game.tscn` main scene-dir. `Game.gd` input state machine və physics tick spawn query, queue/HUD və game state saxlayır. `Animal.tscn` RigidBody2D, CircleShape2D və AnimalData-dan fizika parametrləri alır. `AnimalVisual.gd` body və hər iki preview üçün eyni mənbədir. `MergeManager` body_entered-dən cütü kilidləyir, physics callback-dən sonra deferred commit edir; radius-a uyğun boş mövqe yoxdursa pending saxlayır. `DangerMonitor` ayrı per-instance timer və dəstək normalı ilə grace dövrünü izləyir. Game root paused vaxt UI üçün işləyir, Pieces və menecerlər pausable-dir.

Bu implementasiyanın Godot runtime-da düzgünlüyü təsdiqlənməyib; əlaqəli məhdudiyyətlər QA/KNOWN_ISSUES sənədlərindədir. Tam SaveManager, 12 resource, Golden Merge, challenge, reklam, audio, translation və Web sistemləri sonrakı mərhələlərə aiddir. Physics parametrləri balanslı sayılmır. Səhnədəki divar shape-ləri və root Inspector-dakı bounds birlikdə dəyişdirilməlidir.

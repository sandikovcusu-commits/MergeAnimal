# CrazyGames SDK — başlanmayıb

İstifadəçi mərhələ sırasını A → B → C təyin edib. A bütün tələbləri ödəmədiyi üçün SDK/AdManager/rewarded reklam implementasiyası **başlanmayıb** və heç bir SDK, mock, demo və real reklam test edilməyib. Bu layihəni SDK ilə inteqrasiya olunmuş, monetizasiyaya və ya platforma qəbuluna hazır hesab etməyin.

İlkin sənəd araşdırması: [Godot SDK setup](https://docs.crazygames.com/sdk/intro/), [video ads](https://docs.crazygames.com/sdk/video-ads/), [ad requirements](https://docs.crazygames.com/requirements/ads/), [game module](https://docs.crazygames.com/sdk/game/), [official asset page](https://store.godotengine.org/asset/crazygames/crazysdk/) (səhifədə v2.0.0 görünür; paket, versiya və lisenziya hələ yüklənib yoxlanmayıb). Əsl inteqrasiyada SDK muteAudio prioriteti, init/ad uğursuzluğu, callback idempotentliyi, fasilə/səs bərpası və elan yerləşdirmə qaydaları ayrıca sınaq tələb edir.

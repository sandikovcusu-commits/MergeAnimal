# Game Design Document — Wild Garden

## Məqsəd və oyunçu dövrü
Portret fizika merge puzzle: növbəti heyvanı gör, x oxunda hədəflə, burax, eyniləri birləşdir, yeni növlər və xal qazan, təhlükə xəttini idarə et. Oyun hesabı və internet tələb etməməlidir. Hədəf heyvan kolleksiyası, rekord və davamlı sessiyadır; gəlir zəmanəti verilmir.

## Planlaşdırılan qaydalar (Gün 1-də tətbiq olunmayıb)
12 səviyyə Mouse → Hamster → Rabbit → Cat → Dog → Fox → Raccoon → Koala → Panda → Bear → Lion → Elephant; radiuslar 18, 23, 29, 35, 42, 50, 59, 69, 80, 93, 108, 125; merge xalları 2, 4, 8, 12, 20, 32, 48, 70, 100, 150, 220, 500. Score semantikası: göstərilən xal yaradılan səviyyə üçün verilir; iki fil üçün ayrıca balanslanacaq bonus. Spawn ilk beş növə 30/25/20/15/10 çəki ilə məhduddur. Bunlar sınaq balansıdır.

İki eyni səviyyə atomik birləşir; max səviyyəli cüt yox olur, bonus verir və oyun davam edir. 2 saniyə sabit təhlükə halı Game Over; birləşmənin müvəqqəti yerdəyişməsi sayılmır. Combo, kolleksiya, üç nailiyyətlə açılan mövzu, 20 resource əsaslı challenge, məhdud undo/remove/rescue planlaşdırılır. Reklam könüllüdür, əsas oyuna giriş şərti deyil.

## Gün 1 kəsiyi
Açılan əsas səhnə, siçan/touch ilə nişan və buraxma, cooldown, üç müvəqqəti vizual ilə dairəvi rigid body, divarlar, sadə next göstəricisi. Merge, xal, game over, save və menular Gün 1 hədəfi deyil və hazır deyil.

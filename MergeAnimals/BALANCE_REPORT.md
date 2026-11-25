# Balans hesabatı — V0.3.0-dev

## İlkin verilənlər və hesablama
İstifadəçinin verdiyi 12 radius və score saxlanılıb. Sahə daxili eni 538 world px, filin diametri 250 px; iki fil üçün nominal 500 px, qalan 38 px. Təbii collision fixture iki fili birləşdirir, lakin bütün sıx sahə halları sübut olunmur. Spawn 30/25/20/15/10, yalnız level 1–5, score-dan asılı gizli dəyişmə yoxdur. Seed 13579, 10000 nəticə: **3012 / 2511 / 2058 / 1479 / 940**, 6–12 səviyyələrdən **0**; ±2 faiz-bəndi yoxlaması PASS. Nümunə statistikası dəqiq nəzəri faizə bərabərlik deyil.

## Bot simulyasiyası
`tests/physics/bot_sessions.gd`, `tests/logs/v030-bot-sessions.csv`: 100 seed, hər strategiyadan 25 sessiya, real spawn, merge və danger aktiv; maksimum 90 simulyasiya saniyəsi. Random, uyğun heyvana hədəfləmə, ən aşağı stack, ən aşağı uyğun hədəfə merge priority. Hər seed, spawn/merge/xal/ən yüksək səviyyə/combo/səbəb/müddət/escape qeyd edilir. `time_cap` Game Over deyil. Fizika logunun skript xətaları CI səviyyəsində yoxlanır; insan hərəkəti simulyasiya edilmir.

Run 45665893612 üzrə ortalamalar (25 sessiya/hər üsul): random 902.6 xal, 43.8 merge; same-target 1109.6 xal, 54.4 merge; lowest-stack 849.9 xal, 43.2 merge; merge-priority 1143.8 xal, 57.2 merge. Hər qrupun ən böyük səviyyəsi 8, yalnız 1 overflow; qalanları zaman limitinə çatdı. Əhatə qısa və seçmə məhduddur, insan nəticəsi və filə çatma ehtimalı çıxarmaq olmaz. Radius/çəkiləri bu dəlil əsasında əsassız dəyişmədik; daha uzun insan və bot sınaqları lazımdır.

## 120 Hz sonrası müqayisə
Run 45670121999: eyni 100 seed, dörd strategiyanın hər birindən 25, 90 sim-s limit. Orta xal random 938.6, same-target 1201.6, lowest-stack 885.6, merge-priority 1126.9; orta merge müvafiq 45.4/58.0/44.0/57.5; hamısı time-cap, maksimum əldə edilmiş level 8. Əvvəlki 45668965282 run-da 100-drop fixture xətası olmuşdu; düzəlişdən sonrakı bu run-da 100/100 PASS. Bot CSV `v030-bot-120.csv`, ümumi log `v030-runtime-120-green.txt`. 60 Hz və 120 Hz seed-lər eyni olsa da trayektoriyalar fərqlənir. Başqa radius/spawn çəkisini dəyişmək üçün bu qısa bot nümunəsi yetərli deyil.

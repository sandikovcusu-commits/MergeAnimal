# Test planı — V0.2.1-dev

`day2_suite.gd` də bir çoxu birbaşa menecer çağırışlarıdır; onlar real collision callback və real UI/touch sınağını əvəz etmir. `natural_collision.gd`, `drop_100.gd`, `stress.gd` ayrıca fixturedir. Son icra və dəqiq fərqlər üçün `../TEST_RESULTS.txt` və `../QA_REPORT.md`-yə baxın. Aşağıdakı manual hissələr ayrıca icra olunmayıb.

| # | Ssenari | Metod |
|---:|---|---|
| 1 | Mouse + Mouse = Hamster | Suite + natural collision |
| 2 | Hamster + Hamster = Rabbit | Suite, sonra real kontakt |
| 3 | Rabbit + Rabbit = Cat | Suite, sonra real kontakt |
| 4 | Cat + Cat = Dog | Suite, sonra real kontakt |
| 5 | Fərqli səviyyələr birləşmir | Suite |
| 6 | Üç eyni: cisim təkrar istifadə edilmir | Suite, sonra real kontakt |
| 7 | Dörd eyni: iki qanuni merge | Suite, sonra real kontakt |
| 8 | Chain merge | Suite, sonra real kontakt |
| 9 | Duplicate callback / lock | Suite |
| 10 | Sol divar yaxınlığında merge | Suite, sonra real fizika |
| 11 | Döşəmə yaxınlığında merge | Suite, sonra real fizika |
| 12 | Bir dəfə score | Suite |
| 13 | Normal spawn | Suite |
| 14 | Sol sərhəd spawn | Suite clamp + manual real collision |
| 15 | Sağ sərhəd spawn | Suite clamp + manual real collision |
| 16 | Sürətli klik | Suite duplicate request + manual mouse |
| 17 | Touch + emulated mouse duplicate | Suite synthetic event + real touch |
| 18 | Cooldown | Suite |
| 19 | Bloklanmış spawn queue saxlayır | Suite |
| 20 | Preview bir node və cooldown zamanı gizli | Səhnə yoxlaması + suite + manual |
| 21 | Current/next məlumat uyğunluğu | Suite + manual render |
| 22 | Düşən obyekt Game Over yaratmır | Suite monitor logic + real fizika |
| 23 | Müvəqqəti sıçrayış | Manual real fizika |
| 24 | Dəstəklənən sabit təhlükə grace sonrası | Suite monitor logic + real fizika |
| 25 | Danger timer reset | Suite monitor logic + real fizika |
| 26 | Game Over sonra spawn bloklanır | Suite |
| 27 | Restart bütün köhnə obyektləri təmizləyir | Manual main scene |
| 28 | Sol divar collision | Manual physics debug |
| 29 | Sağ divar collision | Manual physics debug |
| 30 | Döşəmə collision | Natural collision + manual physics debug |
| 31 | Pause fizikanı dayandırır | Suite tree pause + manual motion |
| 32 | Resume fizikanı bərpa edir | Suite tree resume + manual motion |
| 33 | 100 avtomatik düşürmə | `drop_100.gd`, təcrid olunmuş boş-spawn fixture |
| 34 | Obyektlər sərhəddən çıxmır | `stress.gd` + normal oyun manual |
| 35 | Main scene import/F5 | Godot editor və headless runtime |

Əlavə manual: iki barmaq, touch cancel, ekran xaricində buraxma, UI düyməsinə toxunma, focus loss, mobil portret/landşaft, preview sprite sərhədi və screenshot; 100/150/200 sabit body stressdə FPS, physics frame, static memory, escape və error log. Stressdə merge söndüyü üçün duplicate merge iddiası ölçülmür. Üç-body natural chain fixture əlavə olunub; digər sıx chain vəziyyətləri hələ tələb olunur.

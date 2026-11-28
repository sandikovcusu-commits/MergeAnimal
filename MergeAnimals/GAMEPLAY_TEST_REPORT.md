# V0.9.1 gameplay və fizika — qismən

[46068767008](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46068767008) `762b7a6`: Godot 4.7.2 headless runtime test run success. `BOT_SESSIONS=100` ilə hər biri 100 deterministik seed, 4 bot siyasəti, real spawn/merge/danger və 90 simulated-second cap; production 120 Hz qorunur, ayrıca 60 Hz müqayisə yalnız testdədir. Hər iki halda `persist_best=false`: save, achievement və browser input coverage deyil. Raw hər seed sətri `docs/qa/v091-a/bot-100-raw.log`.

| Hz | Seed | Nəticə | Tam escape frame | Maksimum sərhəd penetration |
|---|---:|---|---:|---:|
| 60 | 100 | 1 overflow, 99 time cap | 0 | 16.678 px |
| 120 | 100 | 100 time cap | 0 | 9.190 px |

`time_cap` Game Over PASS deyil; sıfır müşahidə olunan escape heç vaxt tunneling olmaması zəmanəti deyil; 1–2 px hədəf qarşılanmayıb. Test zəif səviyyə penetrasiyası, sıx yığın davranışı və nəticələr haqqında məhdud ölçüdür, insan gameplay və uzunmüddətli sızma auditi deyil. 12 heyvanın bütün ID/collision/score/audio/discovery/merge tələbləri ayrıca təsdiqlənməyib. Əvvəlki testlərdə real elephant golden collision var, lakin bu tam V0.9.1 matrisi deyil.

İki standart Web bot cəhdi 120 input limitində Game Over-a çatmadı və fail edildi; Chromium 102, Firefox 32 son müşahidə edilmiş checkpoint spawn sayına çatdı. Bunlar `SAVE_FAILED_INVESTIGATION.md` və `docs/qa/v091-a/natural-*-failed.log` ilə fərqləndirilir; screenshot/observer vəziyyəti fiziki cihaz və insan oyununa bərabər deyil. Səbəb müəyyən edilmədən gameplay freeze və ya məlumat itkisi təsdiqlənmir.

Sonrakı passiv təkrarlarda [46071244975](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46071244975) Firefox və [46071248324](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/46071248324) Chromium-da locked merge cütləri uzun müddət qaldı, `snapshot_empty=true` və yeni drop-lar dayandı. Oyun process vaxtı irəliləyirdi; səbəb ümumi render freeze kimi təqdim edilmir. Bu **açıq P1** liveness issue-dur. Daha əvvəlki Firefox müşahidəsində observer son checkpoint-i verified göstərsə də canlı xal köhnə checkpoint-dən 160 xal irəlidə idi; son vəziyyətin yazıldığı sübut deyil. Bax `SAVE_FAILED_INVESTIGATION.md`.

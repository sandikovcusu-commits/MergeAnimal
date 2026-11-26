# V0.8.2 — Monetizasiya hesabatı: tamamlanmayıb

Bu mərhələdə **reklam sorğusu, reklam gəliri və mükafat verilmir**. Mövcud pulsuz Undo, Remove və Rescue sistemləri saxlanılıb. AdManager `rewarded_available()` həmişə false-dur; CrazyGames rewarded provider-i, istifadəçi razılıq interfeysi və checkpoint-lə atomik sessiya limiti tətbiq edilməyib. Challenge üçün yeni reklam power-up-ları yoxdur. İstifadəçi heç vaxt işləməyən reklam düyməsi görmür.

İstənən extra Undo/Remove/Rescue, ad start/error/finish/cancel/timeout, duplicate və late callback, ad zamanı fizika/input/danger/audio bərpası, refresh/Continue/restart/backup və save failure üzrə rewarded sınaqları **aparılmayıb**. SDK-nın local demo initialization və skript-bloklama smoke testi reklam uğuru və ya real platforma nəticəsi deyil. `SDK_INTEGRATION_REPORT.md` faktiki CI nəticələrini və növbəti işləri göstərir. IndexedDB final async yazı itkisi riski qalır.

Banner və midgame reklamları əlavə edilməyib. Basic Launch reklamları deaktiv etdiyi üçün oyun reklamsız işləməli və rewarded düymələri göstərməməlidir. Platforma qaydalarına uyğun placement, limits və real reklam testləri olmadan gəlir/uyğunluq iddiası yoxdur. Heyvan sprite-larının kommersiya hüquqları hələ təsdiqlənməyib.

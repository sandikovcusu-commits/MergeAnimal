# V0.8.2.1 — CrazyGames Rewarded Rescue

Əvvəlki SDK təməli `cb6e033`; istehsal oyun kodu `8e92540`, test və workflow yenilikləri sonrakı commit-lərdədir. Yalnız ayrıca **`Web CrazyGames Rewarded (full-launch opt-in)`** preset-i `crazygames_rewarded` feature-i ilə reklamı aktiv edir. Adi Web və `Web CrazyGames (experimental)` preset-ləri reklamsız qalır. Basic Launch statusu localhost-dan etibarlı təyin edilmir: həmin opt-in preset yalnız real platformada full launch və reklam hüququ təsdiqləndikdən sonra seçilməlidir. SDK-nın disabled/unavailable/adblock və initialization timeout halları fail-closed-dir. Adblock yoxlaması xətası da blok kimi qəbul edilir. SDK error və ya timeout sonrası həmin prosesdə yeni təklif deaktiv edilir.

Rəsmi [Godot SDK asset v2.0.0](https://store.godotengine.org/asset/crazygames/crazysdk/) MIT, arxiv SHA-256 `b5c5450a8b645966a6368e8c5c99dd7e00729e517e7de25dc7b6cc2245993e95`; lisenziya `addons/crazygames/LICENSE`. Asset, plugin və wrapper-in daxili versiya nömrələri fərqlidir; local testdə uzaq CDN HTML SDK runtime 3.8.0 idi və URL dəqiq versiyaya pinlənməyib.

Godot wrapper-in global ad siqnalları transaction ID daşımadığı və paketdə adError state problemi olduğu üçün [rəsmi HTML SDK `requestAd` callbacks](https://docs.crazygames.com/sdk/video-ads/) eyni SDK üzərindən per-request closure ilə çağırılır. Kripto-random 128-bit session və transaction ID, sahibi və state yoxlanır. Yalnız `adFinished` mükafat verir; duplicate, köhnə sessiya, error və timeout-dan gec callback-lər rədd edilir. Request zamanı touch ləğv edilir, input bloklanır və ağac/physics/danger dayandırılır. Səs yalnız `adStarted`-də mövcud AudioManager vasitəsilə susdurulur və bitmə/error/timeout zamanı əvvəlki vəziyyətə qaytarılır; user/platform mute üstünlüyü qorunur. Mövcud platform mute polling saxlanır; rəsmi sənədlərdə tələb olunan settings-change listener hələ tətbiq edilməyib.

## Brauzer sübutu və sərhədlər

Godot 4.7.2 Web, Linux CI, Playwright Chromium və Firefox, localhost; Game Over lövhəsi test fixture-dir. **Real CrazyGames platforma preview/reklamı BLOCKED**: hesab/upload/yayımlama üçün icazə yoxdur. Local demo real pullu reklam və gəlir sübutu deyil.

| Sınaq | Chromium | Firefox |
|---|---|---|
| Rəsmi SDK localhost demo: request, started, finished, Rescue | [10/10](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45907892368) | [10/10](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45907895218) |
| Mock transaction, tərcümə, audio qrafiki, physics və danger | [68/68](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45909163212) | [68/68](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45909165909) |
| Reklamsız preset (Basic Launch konfiqurasiyası) | [6/6](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45907903673) | [6/6](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45907906302) |
| SDK skripti bloklanıb | [6/6](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45907909204) | [6/6](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45907911657) |
| Instrumentasiyasız rewarded preset: oyun/audio smoke, reklam yox | [6/6](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45908580684) | [6/6](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45908583479) |

Adblock nümunəsi şəbəkə skriptinin bloklanmasıdır, quraşdırılmış AdBlock extension deyil. Əlavə mock sınaqları və nəticələr `WEB_QA_REPORT.md`-dədir. Browser audio RMS virtual sink/qrafik ölçüsüdür, fiziki dinləmə deyil. Rəsmi SDK [reklam qaydaları](https://docs.crazygames.com/requirements/ads/) üçün real platforma uyğunluğu, entitlement, gəlir, mobil cihaz və settings-change listener yoxlanmayıb. İlk demo harness qaçışlarında callback polling yarışı; ilk Chromium backup testində checkpoint yarışı vardı, sonrakı harness düzəlişləri ilə təkrar sınaqlar keçdi. Sınaqlarda sürətli fixture hadisələri SDK-nın 1 saniyəlik gameplay event throttle xəbərdarlığı yarada bilər; onlar təbii oyun sürəti sübutu deyil.

Əlavə mock [Chromium 45908513286](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45908513286) və [Firefox 45908516105](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45908516105) 67/68 idi: yeni fixture çox sürətli gameplayStart throttle xəbərdarlığı yaratdığı üçün console yoxlaması uğursuz oldu; fixture addımları SDK limitinə uyğun aralandı və sonrakı 68/68 nəticələr yuxarıdadır.

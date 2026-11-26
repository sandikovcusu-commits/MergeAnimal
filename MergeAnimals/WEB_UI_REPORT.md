# V0.8.1.2 — bu sessiyada əlavə Web UI yoxlamaları (delta)

Başlanğıc sorğusundakı `f482f0f` bu branch-in əcdadıdır; bu sessiyaya `074108a` üzərindən, əvvəlki işləri qoruyaraq davam edildi. İstehsal UI kodunun son dəyişməsi `bad7a03`, test yeniləmələri `87c5266`-dadır. Aşağıdakı köhnə V0.8.1.2.1 matrisi həmin testlərin tarixçəsidir, yeni kod üzərində bütün kombinasiya yenidən yoxlanıldığı iddiası deyil.

- Real Web görüntüsündə Tutorial paneli Undo/Remove üzərinə düşürdü. Panel oyun sahəsinə köçürüldü; sonra ilk düzəlişin spawn preview-ni örtdüyü aşkar edilərək panel preview və danger xəttindən aşağı yerləşdirildi. Uzun mətn üçün sətirə bölünmə və Skip üçün ölçü verildi. 360×640 AZ Chromium, TR/RU Firefox, 1366×768 EN Chromium nümunələrinə baxıldı: bu görüntülərdə panel düymələri və başlanğıc heyvanını örtmür, AZ hərfləri görünür. Panel təlimat zamanı oyun sahəsinin bir hissəsini örtür; bütün oyun vəziyyətlərində vizual yoxlama aparılmayıb.
- Tutorial ilk mərhələsi 4 dil × 2 brauzer × 6 ölçüdə çəkildi; hər dildə Skip sonrası bir faktiki düşürmə və saxlanmış tutorial mərhələsi yoxlandı: Chromium [EN](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887129347), [AZ](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887132630), [TR](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887136496), [RU](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887140423); Firefox [EN](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887143663), [AZ](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887147162), [TR](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887150198), [RU](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887153386). Hər biri 2/2 funksional assertion; kadrların hamısı vizual təsdiq demək deyil. Yalnız Forest; tutorialın bütün mərhələləri və tərcümə keyfiyyəti tam audit olunmayıb.
- [Chromium](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887917325) və [Firefox](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887920986): hər biri 29/29; Tutorial, Pause və Continue 6 ölçüdə çəkildi, Play, Skip, Pause → Main Menu → Continue, Restart və iki seçilmiş x mövqeyində bir düşürmə yoxlandı. 18 layout assertion yalnız görünən canvas və DOM overflow üçündür; Godot daxilində mətnin kəsilmədiyini avtomatik sübut etmir. Bunlar English/Forest, desktop mouse sınaqlarıdır.
- Yenilənmiş [Chromium ekran sınağı](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887980234), [Firefox ekran sınağı](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45887984228): hərəsi 16/16; açılan alt menyuların Back, Play, Tutorial və Pause yoxlanıldı. Hər ekrandakı hər düymənin bütün vəziyyətləri ayrıca sınaqdan keçirilməyib.
- Qaranlıq paneldə Tesseract mətnini görmədiyi üçün `bad7a03` navigation run-ları yanlış mənfi verdi; ekran görüntüsündə panel vardı. Test indi persisted tutorial stage ilə təsdiqləyir və 3 təkrar keçdi. `45886547992` browser install mərhələsində uğursuz idi; test nəticəsi deyil. Aşağıdakı köhnə sınaq nəticələri ayrıca commit-lərə aiddir.

**Status: qismən.** Bütün düymələr və bütün mətn/sprite kombinasiya və ölçüləri insan tərəfindən təsdiqlənməyib. Aşağıdakı matris və `KNOWN_ISSUES.md` məhdudiyyətlərə baxın. Real Android deyil.

---
# V0.8.1.2.1 — Web UI completion: execution and visual coverage

**Status: partial, not visual acceptance.** Starting snapshot: `f466d7895113e50f344693a5901a8314c88103d4` (V0.8.1.2 partial); the code export tested below is `2ce25a1ad5e6b43ee920816eaf1839f7f149e305` unless otherwise stated. This is an incremental report; the preceding report is available in Git at the starting snapshot. Actual Godot 4.7.2 release WebAssembly was served over HTTP in Linux CI and run in Playwright Chromium and Firefox with software rendering. Resizing a desktop browser is not an Android-device test.

## Changes since V0.8.1.2

- Enabled touch dragging on the scrollable Collection, Statistics, Achievements, Challenge Selection and Theme Selection screens. A Collection swipe is checked against a substantial content-pixel difference, not just button highlighting.
- Bundled DejaVu Sans is selected by all three themes, fixing the missing Azerbaijani Ə glyph observed in Web. Restart's localized label is constrained to prevent overlap with the centered title. Chromium AZ and TR 360×640 screenshots after the change show no overlap; the small label remains a readability concern.
- Disabled **Web-only** text resource/scene binary conversion in `project.godot`. The default Web conversion was observed to lose Challenge resource arrays and inherited scene offsets in these exports: Challenge 11 lacked its configured raccoon sequence and HUD controls overlapped. After disabling conversion, both browsers reached Challenge 11 Success using an actual drop and Challenge 7 timed failure. The prerequisite completions are injected into isolated IndexedDB, not earned naturally. This workaround is not a general claim that every Godot conversion fails.
- Fixed cancelled GUI button presses and Remove selection; retained the prior gameplay `touchcancel` and active-touch resize safeguards. See `MOBILE_TOUCH_REPORT.md`.

## Size / screen matrix

Sizes in every cell: 360×640, 393×873, 540×1170, 720×1280, 1366×768, 1920×1080. C = screenshot captured, not a visual or usability PASS; P = the specific scripted interaction passed. Landscape is portrait content letterboxed. Individual rows of scrollable content beyond the visible viewport are not all visually audited.

| Screen/state | Chromium | Firefox | Scenario and limits |
|---|---|---|---|
| Main Menu, Collection, Statistics, Achievements, Challenge Selection, Theme Selection, Settings | C at six sizes × four languages × three themes | C at six sizes × four languages × three themes | Theme-locale matrix at `a43f8ad`; selecting and persisting all three themes P; test fixture unlocks themes. Screenshots alone do not assert text layout. |
| Gameplay | C at six sizes × four languages, Forest | C at six sizes × four languages, Forest | `2ce25a1`; language persisted and Play created saved session P. Gameplay in Sunset/Snow not covered by the cross-product. |
| Challenge Failed / Success | C at six sizes, English, Forest | C at six sizes, English, Forest | Timed failure and actual-drop success P, unlock fixture: [Chromium](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45880603169), [Firefox](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45880606131); non-English and other themes not tested for these states. |
| Game Over / Rescue | C at six sizes Game Over, English, Forest; Rescue P | C at six sizes Game Over, English, Forest; Rescue P | Tainted injected board triggers actual danger overflow; Rescue changes board and saves. Not natural progression. Rescue is a Game Over button, not a separate six-size screen. |

### Language × theme capture matrix (both browsers, 7 menu screens × 6 sizes per cell)

| Language | Forest Garden | Sunset Safari | Snowy Valley |
|---|---|---|---|
| English | C | C | C |
| Azerbaijani | C | C | C |
| Turkish | C | C | C |
| Russian | C | C | C |

The fixture sets unlock conditions but the theme is selected using the actual UI and its stored value checked. Chromium runs: [EN](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879649476), [AZ](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879652814), [TR](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879656391), [RU](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879660212). Firefox: [EN](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879663690), [AZ](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879667700), [TR](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879672068), [RU](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879675681). Each reports 5/5 *functional* assertions, not hundreds of visual assertions. This precedes only the gameplay Restart-button change.

### Gameplay locale matrix (`2ce25a1`, six captures per cell)

| Language | Chromium | Firefox |
|---|---|---|
| English | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879819973) | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879835127) |
| Azerbaijani | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879824128) | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879838546) |
| Turkish | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879827761) | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879841953) |
| Russian | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879831375) | [P + C](https://github.com/sandikovcusu-commits/MergeAnimal/actions/runs/45879845649) |

## Visual assessment, not inferred from script success

Reviewed representative 360×640 menu, Collection, Statistics, Achievements, Challenges, Settings and Themes captures: Chromium AZ/Sunset and TR/Snow, Firefox RU/Sunset; Chromium AZ/TR gameplay after the Restart adjustment; English Challenge success/failure and Game Over examples, plus earlier settings and theme examples. The displayed Azerbaijani glyphs now render; reviewed sampled controls did not exhibit the previous HUD/title overlap. At 360px Collection card text, Challenge list labels, Restart and parts of the evolution guide are very small; disabled labels have low contrast. Lists intentionally clip at their scroll container edges, but all lower content and touch accessibility have not been reviewed. Language accuracy was not independently reviewed by native speakers; do not infer that all translations are correct. Every screenshot in the matrix has **not** been manually reviewed. In particular no full visual PASS is claimed for all sizes/languages/themes, localized outcomes, or gameplay in non-Forest themes.

The archive includes representative authentic browser PNGs, test logs and a mapping to CI evidence; the full matrix is in linked CI artifacts/evidence blobs. For how fixtures and browser events are generated see `tests/web/ui-responsive.mjs` and `tests/web/powerup-persistence.mjs`. Browser screenshots and OCR are not a substitute for reading every label, checking accessibility, or device testing.

# Art Bible — Wild Garden, v0.1

Bu sənəd qrafika istehsalından əvvəl üslub istiqamətidir; hələ təsdiqlənmiş konsept və ya yekun sprite yoxdur.

- İstiqamət: cozy forest, yumşaq pastel, isti və sakit; oxunaqlılıq dekorasiyadan üstündür.
- Palitra: şam `#304C3B`, yarpaq `#7DA67B`, krem `#F7EBCF`, bal `#E9B86F`, gil `#C67F5B`, kontur `#60483E`; xəbərdarlıq `#D86053`.
- Kontur: 512 px mənbədə təqribən 10–14 px, tünd isti qəhvəyi; vahid qalınlıq, yüksək kontrast.
- İşıq yuxarı soldan, sağ altda yumşaq kölgə; personaj alt kölgəsi yastı oval, ayrıca üzən element yoxdur.
- Personaj: ön görünüş, yumru kompakt gövdə, mərkəzdə; qulaq və ətraflar dairəvi collision-a yaxın, kəsilmə yoxdur. Fizika radiusu render miqyasından müstəqildir.
- Üz: böyük tünd gözlər, sadə ağız, yüngül yanaq; normal, happy, blink/surprise üçün eyni baza. Kiçik ölçüdə növ fərqi siluet və rənglə tanınmalıdır.
- Düymələr: yumru künclü, krem/yaşıl səth, seçilən kontrastlı yazı, geniş toxunma sahəsi, qısa basma animasiyası.
- Fon: mərkəzi oyun sahəsi sakit, meşə təbəqələri kənarlarda, HUD arxasında aşağı kontrast; 720×1280 portret əsasdır.
- Növbəti mərhələdə əvvəl 2–3 konsept hazırlayıb üslub təsdiqlənməli, sonra 12 × 3 şəffaf PNG hazırlanmalıdır. 512 px mənbə və kiçildilmiş runtime ayrılmalıdır. Alpha, kəsilmə, mərkəz və oxunaqlılıq ayrıca yoxlanmalıdır.

Gün 1-də kodla çəkilən rəngli dairələr yalnız fizika diaqnostikası üçün müvəqqəti placeholder-dır, kommersiya sprite-ı deyil.

## Gün 3 ilkin konsepsiya istiqaməti
Mouse, Cat və Elephant üçün vahid orijinal, yumru-kompakt siluet; yuxarı soldan yumşaq işıq, isti krem fon atmosferi, tünd qəhvəyi kontur, sadə üz, doymamış təbii rənglər. Konsept hədəfi şəffaf fonlu 512×512 PNG və dairə collision sərhədinə uyğunluqdur; qulaq/xortum collision xaricinə uzanarsa oyun istifadəsindən öncə ayrıca uyğunlaşdırılmalıdır. Konseptlər yekun sprite deyil; 36 variasiya Gün 4-də hazırlanacaq. Model/şərt şəffaflığı `ASSET_LICENSES.md`-də qeyd olunacaq.

## Gün 4 — Premium Cozy Cartoon / WIP
İstiqamət: ön tərəfdən eyni kamera bucağı, yuxarı-sol işıq, isti qəhvəyi sabit kontur, pastel təbii rəng, yumşaq cel kölgə, yığcam dairə əsas bədəni və kiçik əlavə orqanlar. Mouse boz / yumru qulaq, Cat narıncı / yığcam qulaq-bığ, Elephant mavi-boz / kiçik xortum və qulaq əvvəl müqayisə olunacaq; qalan növlər həmin üsluba uyğunlaşdırılacaq. Fiziki radius dəyişmir. Şəffaf PNG, kənarlardan boşluq və əsl alpha vacibdir; şahmat fonu şəffaflıq sayılmır. Normal/happy/surprise üçün eyni bədən mərkəzi və sabit collision. Bu istiqamət təsdiqlənmiş kommersiya lisenziyası və real render testi deyil; mənşə təsdiqlənmədən final aktiv elan edilmir.

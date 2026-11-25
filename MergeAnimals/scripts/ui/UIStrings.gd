class_name UIStrings
extends RefCounted
# Native TranslationServer resources constructed from project-authored strings.
static var installed := false
static func install() -> void:
	if installed:
		return
	installed = true
	var messages := {
		"en": {"PLAY":"Play", "SETTINGS":"Settings", "COLLECTION":"Collection", "CHALLENGES":"Challenges — coming later", "BEST_SCORE":"Best score", "MASTER_VOLUME":"Master volume", "MUSIC_VOLUME":"Music volume", "SFX_VOLUME":"Effects volume", "MUTE":"Mute", "REDUCED_EFFECTS":"Reduced effects", "LANGUAGE":"Language", "BACK":"Back", "PAUSE":"Pause", "RESUME":"Resume", "RESTART":"Restart", "MAIN_MENU":"Main menu", "GAME_OVER":"Game over", "FINAL_SCORE":"Final score", "BEST":"Best", "SCORE":"SCORE", "NEXT":"NEXT", "GUIDE":"Evolution guide", "LARGEST":"Largest animal", "MERGES":"Total merges", "MAX_COMBO":"Maximum combo", "NEW_RECORD":"New record!", "COMBO":"COMBO"},
		"az": {"PLAY":"Oyna", "SETTINGS":"Tənzimləmələr", "COLLECTION":"Kolleksiya", "CHALLENGES":"Tapşırıqlar — sonra", "BEST_SCORE":"Ən yaxşı nəticə", "MASTER_VOLUME":"Ümumi səs", "MUSIC_VOLUME":"Musiqi səsi", "SFX_VOLUME":"Effekt səsi", "MUTE":"Səsi söndür", "REDUCED_EFFECTS":"Azaldılmış effektlər", "LANGUAGE":"Dil", "BACK":"Geri", "PAUSE":"Fasilə", "RESUME":"Davam et", "RESTART":"Yenidən başla", "MAIN_MENU":"Əsas menyu", "GAME_OVER":"Oyun bitdi", "FINAL_SCORE":"Yekun xal", "BEST":"Rekord", "SCORE":"XAL", "NEXT":"NÖVBƏTİ", "GUIDE":"İnkişaf ardıcıllığı", "LARGEST":"Ən böyük heyvan", "MERGES":"Birləşmələr", "MAX_COMBO":"Ən böyük kombo", "NEW_RECORD":"Yeni rekord!", "COMBO":"KOMBO"},
		"tr": {"PLAY":"Oyna", "SETTINGS":"Ayarlar", "COLLECTION":"Koleksiyon", "CHALLENGES":"Görevler — yakında", "BEST_SCORE":"En iyi skor", "MASTER_VOLUME":"Ana ses", "MUSIC_VOLUME":"Müzik sesi", "SFX_VOLUME":"Efekt sesi", "MUTE":"Sesi kapat", "REDUCED_EFFECTS":"Azaltılmış efektler", "LANGUAGE":"Dil", "BACK":"Geri", "PAUSE":"Duraklat", "RESUME":"Devam et", "RESTART":"Yeniden başla", "MAIN_MENU":"Ana menü", "GAME_OVER":"Oyun bitti", "FINAL_SCORE":"Son skor", "BEST":"Rekor", "SCORE":"SKOR", "NEXT":"SIRADAKİ", "GUIDE":"Gelişim sırası", "LARGEST":"En büyük hayvan", "MERGES":"Birleşmeler", "MAX_COMBO":"En yüksek kombo", "NEW_RECORD":"Yeni rekor!", "COMBO":"KOMBO"},
		"ru": {"PLAY":"Играть", "SETTINGS":"Настройки", "COLLECTION":"Коллекция", "CHALLENGES":"Задания — позже", "BEST_SCORE":"Лучший результат", "MASTER_VOLUME":"Общая громкость", "MUSIC_VOLUME":"Громкость музыки", "SFX_VOLUME":"Громкость эффектов", "MUTE":"Выключить звук", "REDUCED_EFFECTS":"Меньше эффектов", "LANGUAGE":"Язык", "BACK":"Назад", "PAUSE":"Пауза", "RESUME":"Продолжить", "RESTART":"Заново", "MAIN_MENU":"Главное меню", "GAME_OVER":"Игра окончена", "FINAL_SCORE":"Итоговый счёт", "BEST":"Рекорд", "SCORE":"СЧЁТ", "NEXT":"ДАЛЕЕ", "GUIDE":"Эволюция", "LARGEST":"Самое большое животное", "MERGES":"Объединений", "MAX_COMBO":"Максимальное комбо", "NEW_RECORD":"Новый рекорд!", "COMBO":"КОМБО"}
	}
	var save_messages := {
		"en": {"NEW_GAME":"New game", "NEW_GAME_CONFIRM":"Start a new game? The saved session will be replaced.", "SAVE_FAILED":"Save failed", "CONTINUE":"Continue game", "SAVE_WAIT":"Save unavailable. Resume and try again.", "SAVE_UNAVAILABLE":"Saved game unavailable"},
		"az": {"NEW_GAME":"Yeni oyun", "NEW_GAME_CONFIRM":"Yeni oyun başlasın? Saxlanmış oyun əvəz ediləcək.", "SAVE_FAILED":"Saxlama alınmadı", "CONTINUE":"Oyuna davam et", "SAVE_WAIT":"Saxlama mümkün deyil. Davam edib yenidən yoxlayın.", "SAVE_UNAVAILABLE":"Saxlanmış oyun əlçatan deyil"},
		"tr": {"NEW_GAME":"Yeni oyun", "NEW_GAME_CONFIRM":"Yeni oyun başlatılsın mı? Kayıtlı oyun değiştirilecek.", "SAVE_FAILED":"Kayıt başarısız", "CONTINUE":"Oyuna devam et", "SAVE_WAIT":"Kaydedilemedi. Devam edip tekrar deneyin.", "SAVE_UNAVAILABLE":"Kayıtlı oyun kullanılamıyor"},
		"ru": {"NEW_GAME":"Новая игра", "NEW_GAME_CONFIRM":"Начать новую игру? Сохранённая игра будет заменена.", "SAVE_FAILED":"Ошибка сохранения", "CONTINUE":"Продолжить игру", "SAVE_WAIT":"Не удалось сохранить. Продолжите и повторите.", "SAVE_UNAVAILABLE":"Сохранённая игра недоступна"}
	}
	for locale in save_messages:
		messages[locale].merge(save_messages[locale])
	var collection_messages := {
		"en": {"DATA_UNAVAILABLE":"Saved data is unavailable. Your files were not replaced.", "COLLECTION_TITLE":"Animal Collection", "STATISTICS":"Statistics", "ANIMAL_DISCOVERED":"Animal Discovered!", "LEVEL":"Level", "DISCOVERED":"Discovered", "UNLOCKED":"Unlocked", "LOCKED":"Locked", "CREATED":"Created", "UNDISCOVERED":"Not discovered", "UNLOCK_HINT":"Drop it or merge the previous tier", "UNLOCK_DROP_ONLY":"Drop this animal to discover", "UNLOCK_MERGE_ONLY":"Merge the previous tier", "FIRST_FOUND":"First found", "TOTAL_GAMES":"Total games", "COMPLETED_GAMES":"Completed games", "TOTAL_DROPS":"Total drops", "TOTAL_MERGES":"Total merges", "HIGHEST_ANIMAL":"Highest animal", "GOLDEN_MERGES":"Golden merges", "PLAY_TIME":"Active play time", "COMPLETION":"Collection completion", "ANIMAL_COUNTS":"Animal creation counts"},
		"az": {"DATA_UNAVAILABLE":"Saxlanmış məlumat əlçatan deyil. Fayllar dəyişdirilmədi.", "COLLECTION_TITLE":"Heyvan kolleksiyası", "STATISTICS":"Statistika", "ANIMAL_DISCOVERED":"Yeni heyvan kəşf edildi!", "LEVEL":"Səviyyə", "DISCOVERED":"Kəşf edilib", "UNLOCKED":"Açılıb", "LOCKED":"Kilidli", "CREATED":"Yaradılıb", "UNDISCOVERED":"Kəşf edilməyib", "UNLOCK_HINT":"Sal və ya əvvəlki səviyyəni birləşdir", "UNLOCK_DROP_ONLY":"Kəşf etmək üçün bu heyvanı sal", "UNLOCK_MERGE_ONLY":"Əvvəlki səviyyəni birləşdir", "FIRST_FOUND":"İlk kəşf", "TOTAL_GAMES":"Ümumi oyun", "COMPLETED_GAMES":"Bitmiş oyun", "TOTAL_DROPS":"Ümumi düşmə", "TOTAL_MERGES":"Ümumi birləşmə", "HIGHEST_ANIMAL":"Ən yüksək heyvan", "GOLDEN_MERGES":"Qızıl birləşmə", "PLAY_TIME":"Aktiv oyun vaxtı", "COMPLETION":"Kolleksiya tamamlanması", "ANIMAL_COUNTS":"Heyvan yaradılma sayı"},
		"tr": {"DATA_UNAVAILABLE":"Kayıtlı veriler kullanılamıyor. Dosyalar değiştirilmedi.", "COLLECTION_TITLE":"Hayvan koleksiyonu", "STATISTICS":"İstatistikler", "ANIMAL_DISCOVERED":"Hayvan keşfedildi!", "LEVEL":"Seviye", "DISCOVERED":"Keşfedilen", "UNLOCKED":"Açıldı", "LOCKED":"Kilitli", "CREATED":"Oluşturuldu", "UNDISCOVERED":"Keşfedilmedi", "UNLOCK_HINT":"Bırak veya önceki seviyeyi birleştir", "UNLOCK_DROP_ONLY":"Keşfetmek için bu hayvanı bırak", "UNLOCK_MERGE_ONLY":"Önceki seviyeyi birleştir", "FIRST_FOUND":"İlk keşif", "TOTAL_GAMES":"Toplam oyun", "COMPLETED_GAMES":"Biten oyun", "TOTAL_DROPS":"Toplam bırakma", "TOTAL_MERGES":"Toplam birleşme", "HIGHEST_ANIMAL":"En yüksek hayvan", "GOLDEN_MERGES":"Altın birleşme", "PLAY_TIME":"Aktif oyun süresi", "COMPLETION":"Koleksiyon tamamlanma", "ANIMAL_COUNTS":"Hayvan oluşturma sayısı"},
		"ru": {"DATA_UNAVAILABLE":"Сохранённые данные недоступны. Файлы не изменены.", "COLLECTION_TITLE":"Коллекция животных", "STATISTICS":"Статистика", "ANIMAL_DISCOVERED":"Найдено животное!", "LEVEL":"Уровень", "DISCOVERED":"Открыто", "UNLOCKED":"Открыто", "LOCKED":"Закрыто", "CREATED":"Создано", "UNDISCOVERED":"Не найдено", "UNLOCK_HINT":"Бросьте или объедините предыдущий уровень", "UNLOCK_DROP_ONLY":"Бросьте это животное", "UNLOCK_MERGE_ONLY":"Объедините предыдущий уровень", "FIRST_FOUND":"Впервые найдено", "TOTAL_GAMES":"Всего игр", "COMPLETED_GAMES":"Завершено игр", "TOTAL_DROPS":"Всего бросков", "TOTAL_MERGES":"Всего объединений", "HIGHEST_ANIMAL":"Высшее животное", "GOLDEN_MERGES":"Золотых объединений", "PLAY_TIME":"Активное время", "COMPLETION":"Коллекция заполнена", "ANIMAL_COUNTS":"Создано животных"}
	}
	var animal_names := {
		"en": ["Mouse", "Hamster", "Rabbit", "Cat", "Dog", "Fox", "Raccoon", "Koala", "Panda", "Bear", "Lion", "Elephant"],
		"az": ["Siçan", "Xomyak", "Dovşan", "Pişik", "İt", "Tülkü", "Yenot", "Koala", "Panda", "Ayı", "Şir", "Fil"],
		"tr": ["Fare", "Hamster", "Tavşan", "Kedi", "Köpek", "Tilki", "Rakun", "Koala", "Panda", "Ayı", "Aslan", "Fil"],
		"ru": ["Мышь", "Хомяк", "Кролик", "Кошка", "Собака", "Лиса", "Енот", "Коала", "Панда", "Медведь", "Лев", "Слон"]
	}
	var animal_descriptions := {
		"en": ["A curious little garden visitor.", "A tiny friend with full cheeks.", "A gentle, energetic hopper.", "A playful and watchful companion.", "A loyal friend with a happy spirit.", "A clever explorer of the woods.", "A nimble collector with a striped tail.", "A peaceful tree-loving friend.", "A calm bear with a love of leaves.", "A large and gentle forest friend.", "A proud and warm-hearted guardian.", "A mighty friend with a gentle trunk."],
		"az": ["Maraqlı kiçik bağ qonağı.", "Yanaqları dolu balaca dost.", "Şən və zərif hoppanan dost.", "Oynaq və diqqətli yoldaş.", "Şən və sadiq dost.", "Meşənin ağıllı kəşfiyyatçısı.", "Zolaqlı quyruqlu çevik toplayıcı.", "Ağacları sevən sakit dost.", "Yarpaqları sevən sakit ayı.", "İri və mehriban meşə dostu.", "Qürurlu və mehriban gözətçi.", "Xortumlu, güclü və zərif dost."],
		"tr": ["Meraklı küçük bahçe konuğu.", "Yanakları dolu küçük dost.", "Neşeli ve nazik bir zıpzıp.", "Oyuncu ve dikkatli bir arkadaş.", "Neşeli ve sadık bir dost.", "Ormanın zeki kâşifi.", "Çizgili kuyruklu çevik toplayıcı.", "Ağaçları seven sakin dost.", "Yaprakları seven sakin ayı.", "Büyük ve nazik orman dostu.", "Gururlu ve sıcak kalpli bekçi.", "Hortumlu, güçlü ve nazik dost."],
		"ru": ["Любопытный маленький гость сада.", "Маленький друг с полными щёчками.", "Нежный и энергичный прыгун.", "Игривый и внимательный друг.", "Верный и весёлый друг.", "Умный исследователь леса.", "Ловкий собиратель с полосатым хвостом.", "Спокойный любитель деревьев.", "Спокойный медведь, любящий листья.", "Большой и добрый лесной друг.", "Гордый и добросердечный защитник.", "Сильный и нежный друг с хоботом."]
	}
	for locale in collection_messages:
		messages[locale].merge(collection_messages[locale])
		for i in range(12):
			messages[locale]["ANIMAL_" + Progression.IDS[i].to_upper()] = animal_names[locale][i]
			messages[locale]["ANIMAL_DESC_" + Progression.IDS[i].to_upper()] = animal_descriptions[locale][i]
	var tutorial_messages := {
		"en": {"REPLAY_TUTORIAL":"Replay tutorial", "SKIP":"Skip", "DONE":"Done", "TUTORIAL_MOVE":"Drag left or right to aim", "TUTORIAL_DROP":"Release to drop the animal", "TUTORIAL_MATCH":"Drop the matching animal beside it", "TUTORIAL_MERGE":"Matching animals merge into a larger one", "TUTORIAL_DANGER":"Great! Keep animals below the red line"},
		"az": {"REPLAY_TUTORIAL":"Təlimatı təkrarla", "SKIP":"Keç", "DONE":"Bitir", "TUTORIAL_MOVE":"Nişan almaq üçün sağa və ya sola sürüşdür", "TUTORIAL_DROP":"Heyvanı salmaq üçün burax", "TUTORIAL_MATCH":"Eyni heyvanı yanına sal", "TUTORIAL_MERGE":"Eyni heyvanlar daha böyük heyvana çevrilir", "TUTORIAL_DANGER":"Əla! Heyvanları qırmızı xəttdən aşağı saxla"},
		"tr": {"REPLAY_TUTORIAL":"Eğitimi tekrarla", "SKIP":"Geç", "DONE":"Bitti", "TUTORIAL_MOVE":"Nişan almak için sağa veya sola sürükle", "TUTORIAL_DROP":"Hayvanı bırakmak için parmağını kaldır", "TUTORIAL_MATCH":"Aynı hayvanı yanına bırak", "TUTORIAL_MERGE":"Aynı hayvanlar birleşerek büyür", "TUTORIAL_DANGER":"Harika! Hayvanları kırmızı çizginin altında tut"},
		"ru": {"REPLAY_TUTORIAL":"Повторить обучение", "SKIP":"Пропустить", "DONE":"Готово", "TUTORIAL_MOVE":"Двигайте влево или вправо", "TUTORIAL_DROP":"Отпустите, чтобы уронить животное", "TUTORIAL_MATCH":"Бросьте такое же животное рядом", "TUTORIAL_MERGE":"Одинаковые животные объединяются", "TUTORIAL_DANGER":"Отлично! Держите животных ниже красной линии"}
	}
	for locale in tutorial_messages:
		messages[locale].merge(tutorial_messages[locale])
	for locale in messages:
		var translation := Translation.new()
		translation.locale = locale
		for key in messages[locale]:
			translation.add_message(key, messages[locale][key])
		TranslationServer.add_translation(translation)

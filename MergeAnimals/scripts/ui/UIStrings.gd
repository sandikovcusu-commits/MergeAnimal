class_name UIStrings
extends RefCounted
# Native TranslationServer resources constructed from project-authored strings.
static var installed := false
static func install() -> void:
	if installed:
		return
	installed = true
	var messages := {
		"en": {"PLAY":"Play", "SETTINGS":"Settings", "COLLECTION":"Collection — coming later", "CHALLENGES":"Challenges — coming later", "BEST_SCORE":"Best score", "MASTER_VOLUME":"Master volume", "MUSIC_VOLUME":"Music volume", "SFX_VOLUME":"Effects volume", "MUTE":"Mute", "REDUCED_EFFECTS":"Reduced effects", "LANGUAGE":"Language", "BACK":"Back", "PAUSE":"Pause", "RESUME":"Resume", "RESTART":"Restart", "MAIN_MENU":"Main menu", "GAME_OVER":"Game over", "FINAL_SCORE":"Final score", "BEST":"Best", "SCORE":"SCORE", "NEXT":"NEXT", "GUIDE":"Evolution guide", "LARGEST":"Largest animal", "MERGES":"Total merges", "MAX_COMBO":"Maximum combo", "NEW_RECORD":"New record!", "COMBO":"COMBO"},
		"az": {"PLAY":"Oyna", "SETTINGS":"Tənzimləmələr", "COLLECTION":"Kolleksiya — sonra", "CHALLENGES":"Tapşırıqlar — sonra", "BEST_SCORE":"Ən yaxşı nəticə", "MASTER_VOLUME":"Ümumi səs", "MUSIC_VOLUME":"Musiqi səsi", "SFX_VOLUME":"Effekt səsi", "MUTE":"Səsi söndür", "REDUCED_EFFECTS":"Azaldılmış effektlər", "LANGUAGE":"Dil", "BACK":"Geri", "PAUSE":"Fasilə", "RESUME":"Davam et", "RESTART":"Yenidən başla", "MAIN_MENU":"Əsas menyu", "GAME_OVER":"Oyun bitdi", "FINAL_SCORE":"Yekun xal", "BEST":"Rekord", "SCORE":"XAL", "NEXT":"NÖVBƏTİ", "GUIDE":"İnkişaf ardıcıllığı", "LARGEST":"Ən böyük heyvan", "MERGES":"Birləşmələr", "MAX_COMBO":"Ən böyük kombo", "NEW_RECORD":"Yeni rekord!", "COMBO":"KOMBO"},
		"tr": {"PLAY":"Oyna", "SETTINGS":"Ayarlar", "COLLECTION":"Koleksiyon — yakında", "CHALLENGES":"Görevler — yakında", "BEST_SCORE":"En iyi skor", "MASTER_VOLUME":"Ana ses", "MUSIC_VOLUME":"Müzik sesi", "SFX_VOLUME":"Efekt sesi", "MUTE":"Sesi kapat", "REDUCED_EFFECTS":"Azaltılmış efektler", "LANGUAGE":"Dil", "BACK":"Geri", "PAUSE":"Duraklat", "RESUME":"Devam et", "RESTART":"Yeniden başla", "MAIN_MENU":"Ana menü", "GAME_OVER":"Oyun bitti", "FINAL_SCORE":"Son skor", "BEST":"Rekor", "SCORE":"SKOR", "NEXT":"SIRADAKİ", "GUIDE":"Gelişim sırası", "LARGEST":"En büyük hayvan", "MERGES":"Birleşmeler", "MAX_COMBO":"En yüksek kombo", "NEW_RECORD":"Yeni rekor!", "COMBO":"KOMBO"},
		"ru": {"PLAY":"Играть", "SETTINGS":"Настройки", "COLLECTION":"Коллекция — позже", "CHALLENGES":"Задания — позже", "BEST_SCORE":"Лучший результат", "MASTER_VOLUME":"Общая громкость", "MUSIC_VOLUME":"Громкость музыки", "SFX_VOLUME":"Громкость эффектов", "MUTE":"Выключить звук", "REDUCED_EFFECTS":"Меньше эффектов", "LANGUAGE":"Язык", "BACK":"Назад", "PAUSE":"Пауза", "RESUME":"Продолжить", "RESTART":"Заново", "MAIN_MENU":"Главное меню", "GAME_OVER":"Игра окончена", "FINAL_SCORE":"Итоговый счёт", "BEST":"Рекорд", "SCORE":"СЧЁТ", "NEXT":"ДАЛЕЕ", "GUIDE":"Эволюция", "LARGEST":"Самое большое животное", "MERGES":"Объединений", "MAX_COMBO":"Максимальное комбо", "NEW_RECORD":"Новый рекорд!", "COMBO":"КОМБО"}
	}
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

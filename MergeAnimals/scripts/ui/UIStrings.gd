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
	for locale in messages:
		var translation := Translation.new()
		translation.locale = locale
		for key in messages[locale]:
			translation.add_message(key, messages[locale][key])
		TranslationServer.add_translation(translation)

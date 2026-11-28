extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", msg])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func run() -> void:
	UIStrings.install()
	var locales := ["en", "az", "tr", "ru"]
	var required: Array[String] = ["PLAY", "SETTINGS", "NEW_GAME", "CONTINUE", "CHALLENGES", "ACHIEVEMENTS", "COLLECTION", "STATISTICS", "THEMES", "PAUSE", "GAME_OVER", "RESTART", "SAVE_FAILED", "CH_LEAVE_WARNING", "CH_SUCCESS", "CH_FAILED", "UNDO_AVAILABLE", "REMOVE_AVAILABLE", "RESCUE_AVAILABLE", "ANIMAL_DISCOVERED", "ACHIEVEMENT_UNLOCKED", "TUTORIAL_MOVE", "TUTORIAL_DROP", "TUTORIAL_MATCH", "TUTORIAL_MERGE", "TUTORIAL_DANGER", "THEME_FOREST", "THEME_SUNSET", "THEME_SNOW", "THEME_APPLY"]
	for def in ChallengeManager.DEFINITIONS:
		required.append(str(def.title_key)); required.append(str(def.objective_key))
	for id in Progression.IDS:
		required.append("ANIMAL_" + id.to_upper()); required.append("ANIMAL_DESC_" + id.to_upper())
	for def in AchievementManager.definitions():
		required.append("ACH_" + def.id + "_TITLE"); required.append("ACH_" + def.id + "_DESC")
	var english := TranslationServer.get_translation_object("en")
	for key in english.get_message_list():
		if str(key) not in required: required.append(str(key))
	for locale in locales:
		TranslationServer.set_locale(locale)
		var translation := TranslationServer.get_translation_object(locale)
		var missing: Array[String] = []
		if translation == null: missing.append("translation object")
		else:
			for key in required:
				if translation.get_message(key).is_empty(): missing.append(key)
		check(missing.is_empty(), "%s required translation keys present; missing=%s" % [locale, missing])
		for def in AchievementManager.definitions():
			check(not def.localized_title().is_empty() and not def.localized_title().begins_with("ACH_") and not def.localized_description().begins_with("ACH_"), "%s %s achievement text resolved" % [locale, def.id])
	var glyphs := "ƏəİıÖöÜüĞğÇçŞşАяЁё"
	SettingsStore.apply(SettingsStore.load_values())
	var font := ThemeDB.fallback_font
	var absent := ""
	for i in range(glyphs.length()):
		if not font.has_char(glyphs.unicode_at(i)): absent += glyphs.substr(i, 1)
	check(absent.is_empty(), "bundled font Azerbaijani/Cyrillic glyphs available; absent=" + absent)
	change_scene_to_file("res://scenes/ui/MainMenu.tscn"); await frames()
	current_scene._settings(); await frames()
	var panel = current_scene.settings_panel
	for i in range(4):
		panel._on_language(i); await frames()
		check(TranslationServer.get_locale().begins_with(locales[i]) and SettingsStore.load_values().language == locales[i], "%s changes and saves without restart" % locales[i])
		check(current_scene.best_label.text.begins_with(TranslationServer.translate("BEST_SCORE")), "%s current menu updates" % locales[i])
	panel._close(); await frames()
	change_scene_to_file("res://scenes/game/Game.tscn"); await frames()
	var game = current_scene; game._toggle_pause(); game._open_settings(); await frames()
	game.settings_panel._on_language(1); await frames()
	check(game.pause_button.text == TranslationServer.translate("PAUSE") and game.score_label.text.begins_with(TranslationServer.translate("SCORE")), "paused game updates language immediately")
	print("LOCALIZATION checks=%d failures=%d" % [checks, failures]); paused = false; quit(1 if failures else 0)

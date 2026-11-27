extends SceneTree
# Real engine, dummy/headless audio; no claim about listening quality or FPS.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func frames(n: int) -> void:
	for i in range(n): await process_frame
func run() -> void:
	if OS.get_environment("FEEL_PHASE") == "read":
		var values := SettingsStore.load_values()
		check(is_equal_approx(values.master, 0.4) and is_equal_approx(values.music, 0.3) and is_equal_approx(values.sfx, 0.2) and not values.mute and not values.reduced_effects, "audio settings restore in a separate Godot process")
		print("FEEL_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0); return
	var audio = root.get_node_or_null("AudioManager")
	if not audio:
		audio = load("res://scripts/audio/AudioManager.gd").new(); audio.name = "AudioManager"; root.add_child(audio)
	await frames(2)
	check(not audio.unlocked_audio and not audio.music.playing, "no autoplay before gesture")
	check(audio.players.size() == 8 and audio.music != null, "bounded audio pool and single persistent music player")
	var gesture := InputEventMouseButton.new(); gesture.button_index = MOUSE_BUTTON_LEFT; gesture.pressed = true
	audio._input(gesture)
	check(audio.unlocked_audio and audio.music.playing, "first input starts music")
	for id in ["forest", "sunset", "snow"]:
		audio.set_music(id)
		check(audio.music_theme == id and audio.music.playing and audio.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and audio.music.stream.loop_end > 0, "%s has configured looping music" % id)
	var music_instance: int = audio.music.get_instance_id()
	var music_stream: AudioStream = audio.music.stream
	audio.set_music("snow")
	check(audio.music.get_instance_id() == music_instance and audio.music.stream == music_stream, "same theme does not restart or duplicate music")
	for id in audio.EVENTS:
		for player in audio.players: player.stop()
		check(audio.play_event(id) and audio.streams[id] != null, "audio event playable: " + id)
	for player in audio.players: player.stop()
	audio.impact_elapsed = 1.0
	check(not audio.impact(99.0, false) and audio.impact(300.0, false) and not audio.impact(300.0, false), "impact threshold and global cooldown")
	for player in audio.players: player.stop()
	var count := 0
	for i in range(10):
		if audio.play_event("small_merge"): count += 1
	check(count == 8, "simultaneous SFX pool has hard limit")
	for player in audio.players: player.stop()
	var settings := SettingsStore.DEFAULTS.duplicate(); settings.master = 0.4; settings.music = 0.3; settings.sfx = 0.2; settings.mute = true; settings.reduced_effects = true
	check(SettingsStore.save_values(settings) == OK, "settings saved through SaveManager")
	var restored := SettingsStore.load_values()
	SettingsStore.apply(restored)
	check(is_equal_approx(restored.master, 0.4) and is_equal_approx(restored.music, 0.3) and is_equal_approx(restored.sfx, 0.2) and restored.mute and restored.reduced_effects, "audio and reduced settings round-trip")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")), linear_to_db(0.4)) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.3)) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), linear_to_db(0.2)) and AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) and AudioServer.get_bus_send(AudioServer.get_bus_index("UI")) == "SFX", "master/music/SFX/mute and UI buses applied")
	var settings_before_ad := SettingsStore.load_values()
	var music_before_ad: int = audio.music.get_instance_id()
	audio.set_ad_audio_paused(true); audio.set_ad_audio_paused(true)
	check(audio.ad_audio_paused and audio.music.stream_paused and not audio.play_event("button_click"), "ad suspension pauses music and rejects new effects")
	audio.set_music("forest")
	check(audio.music.stream_paused and audio.music_theme == "forest", "theme switch remains suspended during ad")
	audio.set_ad_audio_paused(false); audio.set_ad_audio_paused(false)
	check(not audio.music.stream_paused and audio.music.get_instance_id() == music_before_ad and SettingsStore.load_values() == settings_before_ad and AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "ad resume keeps player and previously muted user settings")
	audio.set_music("snow")
	music_stream = audio.music.stream
	settings.reduced_effects = false; settings.mute = false; SettingsStore.save_values(settings); SettingsStore.apply(settings)
	for path in [SessionSave.PATH, SessionSave.POWERUP_PATH, AchievementManager.PATH, AchievementManager.CHECKPOINT_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var game = load("res://scenes/game/Game.tscn").instantiate(); game.test_seed = 123; root.add_child(game); current_scene = game; await frames(3)
	var intervals := {}
	for tier in range(12):
		var body: Animal = game.create_animal(game.animals[tier], Vector2(100 + tier * 40, 700))
		body.freeze = true
		var radius: float = body.circle.shape.radius
		intervals[snappedf(body.visual.next_blink, 0.001)] = true
		# V0.9.0.4 eases *towards* each pose instead of snapping immediately.
		# Sample during its 70 ms approach; still assert the actual direction and
		# that the rigid body and collision never scale.
		body.visual.animate_action("drop")
		await frames(4)
		check(body.visual.scale.x < 1.0 and body.visual.scale.y > 1.0 and body.circle.shape.radius == radius and body.scale == Vector2.ONE, "tier %d drop motion is visual-only" % (tier + 1))
		body.visual.animate_action("landing")
		await frames(4)
		check(body.visual.scale.x > 1.0 and body.circle.shape.radius == radius and body.scale == Vector2.ONE, "tier %d landing squash is visual-only" % (tier + 1))
		body.visual.animate_action("merge")
		await frames(4)
		check(body.visual.scale.x < 1.0 and body.circle.shape.radius == radius and body.scale == Vector2.ONE, "tier %d merge appearance is visual-only" % (tier + 1))
		body.visual.next_blink = 0; body.visual._process(0.01)
		check(body.visual.blink_left > 0 and body.visual.blink_duration >= 0.12 and body.visual.blink_duration <= 0.18 and body.visual.next_blink >= 3 and body.visual.next_blink <= 8, "tier %d staggered blink timing" % (tier + 1))
		body.queue_free()
	check(intervals.size() >= 10, "initial blink intervals differ")
	await frames(3)
	var reduced_body: Animal = game.create_animal(game.animals[0], Vector2(200, 800)); reduced_body.freeze = true
	audio.reduced_effects = true; reduced_body.visual._process(0.1)
	reduced_body.visual.animate_action("landing")
	check(reduced_body.visual.scale == Vector2.ONE and reduced_body.circle.shape.radius == game.animals[0].radius, "reduced effects disables squash without changing collision")
	reduced_body.queue_free(); audio.reduced_effects = false; await frames(3)
	check(audio.music.playing and audio.music.get_instance_id() == music_instance and audio.music.stream == music_stream, "same music instance and stream continue when game scene changes")
	for player in audio.players: player.stop()
	var old_landings: int = int(audio.accepted_events.get("soft_landing", 0))
	var old_drops: int = int(audio.accepted_events.get("animal_drop", 0))
	var old_merges: int = int(audio.accepted_events.get("small_merge", 0))
	game.current_data = game.animals[0]; game._set_aim(360); game.drop_animal()
	for i in range(260): await physics_frame
	check(int(audio.accepted_events.get("soft_landing", 0)) > old_landings, "real floor impact triggers soft landing sound")
	game.current_data = game.animals[0]; game._set_aim(360); game.drop_animal()
	for i in range(600):
		await physics_frame
		if game.merge_manager.merge_count >= 1: break
	var merge_score: int = game.score
	check(int(audio.accepted_events.get("animal_drop", 0)) > old_drops and int(audio.accepted_events.get("small_merge", 0)) > old_merges, "real drops and merge dispatch audio")
	check(game.merge_manager.merge_count == 1 and merge_score > 0, "real physical merge produces one score")
	for i in range(300): await physics_frame
	check(game.merge_manager.merge_count == 1 and game.score == merge_score, "motion does not repeat merge or score")
	paused = false
	game.queue_free(); current_scene = null; await frames(3)
	# Only challenge access is seeded; Golden comes from actual configured
	# starting board, ordinary queue and physics contacts.
	var access := ChallengeStore.empty()
	for i in range(19): access.entries[i].completed = true
	check(SaveManager.save_progress(access, ChallengeStore.PATH) == OK, "seed access to Golden Garden")
	set_meta("challenge_id", 20)
	game = load("res://scenes/game/ChallengeGame.tscn").instantiate(); game.test_seed = 88
	root.add_child(game); current_scene = game; await frames(3)
	game.reduced_effects = true; audio.reduced_effects = true
	var old_golden: int = int(audio.accepted_events.get("golden_merge", 0))
	for attempt in range(10):
		for i in range(220):
			await physics_frame
			if game.result_finished: break
		if game.result_finished: break
		for player in audio.players: player.stop()
		game._set_aim(360); game.drop_animal()
	for i in range(500):
		await process_frame
		if game.result_finished: break
	check(game.result_success and game.challenge.count == 1 and int(audio.accepted_events.get("golden_merge", 0)) > old_golden, "real Golden collision dispatches special sound")
	check(game.effect_camera.offset == Vector2.ZERO, "reduced effects suppress Golden camera shake")
	var golden_score: int = game.score; var golden_merges: int = game.merge_manager.merge_count
	await frames(90)
	check(game.score == golden_score and game.merge_manager.merge_count == golden_merges, "Golden feedback does not duplicate score or merge")
	paused = false
	game.queue_free(); current_scene = null
	for player in audio.players: player.stop(); player.stream = null
	audio.music.stop(); audio.music.stream = null
	audio.streams.clear(); music_stream = null
	audio.queue_free()
	await frames(3)
	# Allow the dummy audio mixer thread to release stopped playback references.
	OS.delay_msec(400)
	print("FEEL checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)

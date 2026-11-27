extends SceneTree
# Isolated user:// directory. Inject local temp-path blockage, then remove it.
# Overflow uses DangerMonitor; no fake successful write is injected.
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1; print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures += 1
func run() -> void:
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 511; root.add_child(game); current_scene = game
	await process_frame; await process_frame
	game.danger_monitor.set_physics_process(false)
	var animal: Animal = game.create_animal(game.animals[0],Vector2(360,430)); animal.freeze = true; animal.supported = true
	var blocker := ProjectSettings.globalize_path(SessionSave.POWERUP_PATH+".tmp")
	check(DirAccess.make_dir_absolute(blocker)==OK,"create controlled temporary write blocker")
	game.danger_monitor._physics_process(game.danger_monitor.grace_period+0.1)
	await process_frame; await process_frame
	check(game.game_state==game.GameState.GAME_OVER and game.gameover_checkpoint_pending and game.save_status!=OK,"terminal write failure remains visible while retry pending")
	check(game.rescue_button.disabled and not game.rescue_message.text.is_empty(),"rescue disabled and failure message not hidden")
	DirAccess.remove_absolute(blocker)
	await create_timer(1.0,true).timeout
	var doc:=SessionSave.load_document()
	check(not game.gameover_checkpoint_pending and game.save_status==OK and doc.status in ["ok","recovered"] and doc.data.game_over_pending==true and doc.data.bodies.size()==1,"bounded retry writes actual terminal checkpoint after obstruction cleared")
	check(game.rescue_remaining==1 and int(doc.data.rescue_remaining)==1,"free rescue preserved")
	# Fail again, remove the blocker and finalize/restart before delayed retry.
	game.gameover_checkpoint_pending=false
	check(DirAccess.make_dir_absolute(blocker)==OK,"second controlled write blocker created")
	game._checkpoint_game_over()
	check(game.gameover_checkpoint_pending and game.save_status!=OK,"second terminal failure schedules retry")
	DirAccess.remove_absolute(blocker)
	game._restart()
	for i in range(5): await process_frame
	await create_timer(1.1,true).timeout
	var current = current_scene
	var after := SessionSave.load_document()
	check(current!=game and current.scene_file_path=="res://scenes/game/Game.tscn" and current.score==0 and not bool(after.data.get("game_over_pending",false)),"stale retry does not overwrite finalized new session")
	paused=false; print("SAVE_RETRY_A3 checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)

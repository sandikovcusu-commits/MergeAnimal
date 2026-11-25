extends SceneTree

const SAVE := preload("res://scripts/save/SaveManager.gd")
const ROOT := "user://day6_save_test"
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var path := ROOT + "/save.json"
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	check(SAVE.load_progress(path).status == "missing", "empty state")
	for i in range(100):
		var value := {"score": i, "animals": {"mouse": i}, "settings": {"language": "az"}}
		check(SAVE.save_progress(value, path) == OK, "save %d" % i)
		var loaded: Dictionary = SAVE.load_progress(path)
		check(loaded.status == "ok" and int(loaded.data.score) == i and int(loaded.data.animals.mouse) == i, "round trip %d" % i)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	var recovered: Dictionary = SAVE.load_progress(path)
	check(recovered.status == "recovered" and int(recovered.data.score) == 98, "recover previous backup")
	check(SAVE.save_progress({"score": 123}, path) == OK, "write after recovery")
	var after_recovery: Dictionary = SAVE.load_progress(path)
	check(after_recovery.status == "ok" and int(after_recovery.get("data", {}).get("score", -1)) == 123, "recovery write readable")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version":999,"data":{},"checksum":""}')
	file.close()
	check(SAVE.load_progress(path).status == "future", "future version detected")
	check(SAVE.save_progress({"score": 0}, path) != OK, "future version not overwritten")
	check(SAVE.load_progress(path).status == "future", "future version remains intact")
	var corrupt_path := ROOT + "/corrupt.json"
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(corrupt_path + suffix))
	check(SAVE.save_progress({"score": 10}, corrupt_path) == OK, "checksum fixture save")
	check(SAVE.save_progress({"score": 20}, corrupt_path) == OK, "checksum fixture backup")
	file = FileAccess.open(corrupt_path, FileAccess.READ)
	var contents := file.get_as_text()
	file.close()
	file = FileAccess.open(corrupt_path, FileAccess.WRITE)
	file.store_string(contents.replace('20', '21'))
	file.close()
	var checksum_recovered: Dictionary = SAVE.load_progress(corrupt_path)
	check(checksum_recovered.status == "recovered" and int(checksum_recovered.get("data", {}).get("score", -1)) == 10, "checksum mismatch recovers backup")
	file = FileAccess.open(corrupt_path + ".bak", FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(SAVE.load_progress(corrupt_path).status == "corrupt", "both copies corrupt")
	file = FileAccess.open(corrupt_path + ".bak", FileAccess.WRITE)
	file.store_string('{"version":999}')
	file.close()
	check(SAVE.load_progress(corrupt_path).status == "future", "future backup detected")
	check(SAVE.save_progress({}, corrupt_path) != OK, "future backup not overwritten")
	check(SAVE.save_progress({}, "res://forbidden.json") == ERR_INVALID_PARAMETER, "non-user path rejected")
	check(SAVE.save_progress({}, ROOT + "/missing-dir/save.json") != OK, "IO failure reported")
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "best", 501)
	cfg.save(ROOT + "/score.cfg")
	cfg = ConfigFile.new()
	cfg.set_value("settings", "language", "tr")
	cfg.save(ROOT + "/settings.cfg")
	cfg = ConfigFile.new()
	cfg.set_value("tutorial", "completed", true)
	cfg.save(ROOT + "/tutorial.cfg")
	var seed: Dictionary = SAVE.legacy_seed(ROOT + "/settings.cfg", ROOT + "/score.cfg", ROOT + "/tutorial.cfg")
	check(seed.best_score == 501 and seed.settings.language == "tr" and seed.tutorial_completed, "legacy seed")
	check(FileAccess.file_exists(ROOT + "/score.cfg"), "legacy preserved")
	print("Day6 experimental save checks=", checks, " failures=", failures)
	quit(1 if failures else 0)

## Versioned local persistence primitive; gameplay snapshot rules are in SessionSave.
class_name SaveManager
extends RefCounted

const VERSION := 1
const DEFAULT_PATH := "user://wild_garden_progress.json"

static func _read_envelope(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "io_error"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"status": "corrupt"}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"status": "corrupt"}
	if not parsed.has("version") or typeof(parsed.version) not in [TYPE_INT, TYPE_FLOAT] or float(parsed.version) != floorf(float(parsed.version)):
		return {"status": "corrupt"}
	if int(parsed.version) > VERSION:
		return {"status": "future"}
	if int(parsed.version) != VERSION or typeof(parsed.get("payload")) != TYPE_STRING or typeof(parsed.get("checksum")) != TYPE_STRING:
		return {"status": "corrupt"}
	if parsed.payload.sha256_text() != parsed.checksum:
		return {"status": "corrupt"}
	var payload_parser := JSON.new()
	if payload_parser.parse(parsed.payload) != OK or typeof(payload_parser.data) != TYPE_DICTIONARY:
		return {"status": "corrupt"}
	return {"status": "ok", "data": payload_parser.data}

static func load_progress(path: String = DEFAULT_PATH) -> Dictionary:
	var primary := _read_envelope(path)
	if primary.status == "ok" or primary.status == "future" or primary.status == "io_error":
		return primary
	var backup := _read_envelope(path + ".bak")
	if backup.status == "ok":
		return {"status": "recovered", "data": backup.data}
	if backup.status == "future" or backup.status == "io_error":
		return backup
	return {"status": "missing" if primary.status == "missing" and backup.status == "missing" else "corrupt"}

static func save_progress(data: Dictionary, path: String = DEFAULT_PATH, backup_current: bool = true) -> Error:
	# Never overwrite newer saves, unreadable saves, or a newer backup.
	if not path.begins_with("user://"):
		return ERR_INVALID_PARAMETER
	var primary := _read_envelope(path)
	var backup := _read_envelope(path + ".bak")
	if primary.status in ["future", "io_error"] or backup.status in ["future", "io_error"]:
		return ERR_UNAVAILABLE
	var encoded := JSON.stringify(data)
	var envelope := {"version": VERSION, "payload": encoded, "checksum": encoded.sha256_text()}
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return error
	# Verify serialization and write before touching either durable copy.
	if _read_envelope(tmp).status != "ok":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return ERR_FILE_CORRUPT
	var base := ProjectSettings.globalize_path(path)
	if primary.status == "ok" and backup_current:
		var backup_tmp := base + ".bak.tmp"
		error = DirAccess.copy_absolute(base, backup_tmp)
		if error == OK:
			error = DirAccess.rename_absolute(backup_tmp, base + ".bak")
		if error != OK:
			DirAccess.remove_absolute(backup_tmp)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
			return error
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), base)
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	return error

## Read-only migration seed. Legacy files remain authoritative until integration.
static func legacy_seed(settings_path: String = SettingsStore.PATH, score_path: String = "user://wild_garden.cfg", tutorial_path: String = "user://wild_garden_tutorial.cfg") -> Dictionary:
	var cfg := ConfigFile.new()
	var best := 0
	if cfg.load(score_path) == OK:
		var value: Variant = cfg.get_value("scores", "best", 0)
		if typeof(value) == TYPE_INT:
			best = maxi(value, 0)
	var tutorial := ConfigFile.new()
	var completed := false
	if tutorial.load(tutorial_path) == OK:
		var value: Variant = tutorial.get_value("tutorial", "completed", false)
		if typeof(value) == TYPE_BOOL:
			completed = value
	return {"best_score": best, "settings": SettingsStore.load_values(settings_path), "tutorial_completed": completed}

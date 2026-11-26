## Uses evidence from validated Classic progression and saved distinct Challenge results.
## Permanent unlocks are separate from rolling statistics, matching Collection discovery.
class_name AchievementManager
extends RefCounted
const PATH := "user://wild_garden_achievements.json"
const VERSION := 1

static func definitions() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	# Additional data resources are picked up without changing gameplay code.
	var directory := DirAccess.open("res://resources/achievements")
	if directory == null: return result
	var names := directory.get_files(); names.sort()
	for file in names:
		if file.ends_with(".tres"):
			var def := load("res://resources/achievements/" + file) as AchievementData
			if def != null: result.append(def)
	return result

static func _empty() -> Dictionary:
	return {"version": VERSION, "entries": {}}

static func _valid(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY or typeof(value.get("version")) not in [TYPE_INT, TYPE_FLOAT] or float(value.version) != VERSION or typeof(value.get("entries")) != TYPE_DICTIONARY: return false
	for key in value.entries:
		var entry: Variant = value.entries[key]
		if typeof(key) != TYPE_STRING or typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("unlocked")) != TYPE_BOOL or typeof(entry.get("date")) != TYPE_STRING or entry.date.length() > 32: return false
		var n: Variant = entry.get("progress")
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or float(n) < 0 or float(n) > 1000000000 or floorf(float(n)) != float(n): return false
	return true

static func load_state() -> Dictionary:
	var primary := SaveManager._read_envelope(PATH)
	var backup := SaveManager._read_envelope(PATH + ".bak")
	for file in [primary, backup]:
		if file.status in ["future", "io_error"]: return {"status": "unavailable"}
		if file.status == "ok" and typeof(file.data.get("version")) in [TYPE_INT, TYPE_FLOAT] and float(file.data.version) > VERSION: return {"status": "unavailable"}
	if primary.status == "ok" and _valid(primary.data): return {"status": "ok", "data": primary.data}
	if backup.status == "ok" and _valid(backup.data): return {"status": "recovered", "data": backup.data}
	if primary.status == "missing" and backup.status == "missing": return {"status": "missing", "data": _empty()}
	return {"status": "corrupt"}

static func _value(def: AchievementData, progress: Dictionary, challenges: Dictionary) -> int:
	match def.objective_type:
		"total_merges", "golden_merges", "best_score", "max_combo":
			return int(progress.get(def.objective_type, 0)) if Progression.valid(progress) else -1
		"discovery":
			if not Progression.valid(progress) or not progress.animals.has(def.unlock_condition): return -1
			return 1 if not str(progress.animals[def.unlock_condition].date).is_empty() else 0
		"collection": return Progression.discovered(progress) if Progression.valid(progress) else -1
		"challenges":
			if not ChallengeStore.valid(challenges): return -1
			var completed := 0
			for entry in challenges.entries:
				if entry.completed: completed += 1
			return completed
	return -1

# `live` means the caller has just observed a real eligible event. Historical
# migration has no known unlock date and never invents one or sends a toast.
static func synchronize(progress: Dictionary, challenges: Dictionary, live: bool = false) -> Dictionary:
	var loaded := load_state()
	if loaded.status not in ["ok", "recovered", "missing"]: return {"status": loaded.status, "new": []}
	var state: Dictionary = loaded.data.duplicate(true)
	var old := JSON.stringify(state)
	var unlocked: Array[AchievementData] = []
	for def in definitions():
		if def.id.is_empty() or def.target < 1: continue
		var value := _value(def, progress, challenges)
		if value < 0: continue
		var entry: Dictionary = state.entries.get(def.id, {"unlocked": false, "date": "", "progress": 0})
		entry.progress = mini(value, def.target)
		if not entry.unlocked and value >= def.target:
			entry.unlocked = true
			entry.date = Time.get_datetime_string_from_system(false, true) if live else ""
			if live: unlocked.append(def)
		state.entries[def.id] = entry
	if old == JSON.stringify(state): return {"status": "ok", "new": [], "data": state}
	var primary := SaveManager._read_envelope(PATH)
	var err := SaveManager.save_progress(state, PATH, primary.status == "ok" and _valid(primary.data))
	if err != OK: return {"status": "write_failed", "new": []}
	# Refresh validated backup so recovery does not re-announce the last unlock.
	if SaveManager.save_progress(state, PATH, true) != OK: push_warning("Achievement backup refresh failed")
	return {"status": "ok", "new": unlocked, "data": state}

static func saved_inputs() -> Dictionary:
	var doc := SessionSave.load_document()
	var progress := SessionSave.load_progression() if doc.status in ["ok", "recovered", "missing"] else {}
	var saved := ChallengeStore.load_results()
	var challenges: Dictionary = saved.data if saved.status in ["ok", "recovered", "missing"] else {}
	return {"progress": progress, "challenges": challenges}

static func migrate() -> Dictionary:
	var inputs := saved_inputs()
	return synchronize(inputs.progress, inputs.challenges, false)

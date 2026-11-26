## Results are separate from Classic session/progression. Active attempts are not saved.
class_name ChallengeStore
extends RefCounted
const PATH := "user://wild_garden_challenges.json"
const VERSION := 1
static func empty() -> Dictionary:
	var entries := []
	for i in range(5): entries.append({"completed": false, "best": 0, "attempts": 0})
	return {"version": VERSION, "entries": entries}
static func valid(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.get("version") != VERSION or typeof(data.get("entries")) != TYPE_ARRAY or data.entries.size() != 5: return false
	var previous := true
	for item in data.entries:
		if typeof(item) != TYPE_DICTIONARY or typeof(item.get("completed")) != TYPE_BOOL: return false
		for key in ["best", "attempts"]:
			var n: Variant = item.get(key)
			if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or float(n) < 0 or float(n) > 1000000000 or floorf(float(n)) != float(n): return false
		if item.completed and not previous: return false
		previous = item.completed
	return true
static func load_results() -> Dictionary:
	var primary := SaveManager._read_envelope(PATH)
	var backup := SaveManager._read_envelope(PATH + ".bak")
	if primary.status in ["future", "io_error"] or backup.status in ["future", "io_error"]: return {"status": "unavailable"}
	for entry in [primary, backup]:
		if entry.status == "ok" and typeof(entry.data.get("version")) in [TYPE_INT, TYPE_FLOAT] and float(entry.data.version) > VERSION: return {"status": "unavailable"}
	for entry in [[primary, "ok"], [backup, "recovered"]]:
		if entry[0].status == "ok" and valid(entry[0].data): return {"status": entry[1], "data": entry[0].data}
	if primary.status == "missing" and backup.status == "missing": return {"status": "missing", "data": empty()}
	return {"status": "corrupt"}
static func is_unlocked(data: Dictionary, id: int) -> bool:
	return id >= 1 and id <= 5 and valid(data) and (id == 1 or bool(data.entries[id - 2].completed))
static func record_result(id: int, success: bool, score: int) -> Error:
	var loaded := load_results()
	if loaded.status not in ["ok", "recovered", "missing"]: return ERR_UNAVAILABLE
	var data: Dictionary = loaded.data.duplicate(true)
	if not is_unlocked(data, id) or score < 0 or score > 1000000000: return ERR_INVALID_DATA
	var item: Dictionary = data.entries[id - 1]
	item.attempts = int(item.attempts) + 1
	item.best = maxi(int(item.best), score)
	if success: item.completed = true
	if not valid(data): return ERR_INVALID_DATA
	# Never replace a good backup with a corrupt/invalid primary on recovery.
	var primary := SaveManager._read_envelope(PATH)
	var keep_primary: bool = primary.status == "ok" and valid(primary.data)
	var result := SaveManager.save_progress(data, PATH, keep_primary)
	if result != OK: return result
	# Refresh backup after committing primary; mirror failure does not roll back.
	var mirror := SaveManager.save_progress(data, PATH, true)
	if mirror != OK: push_warning("Challenge result committed; backup refresh failed: %s" % mirror)
	return OK

## Classic-session schema and validation. Never partially apply an invalid snapshot.
class_name SessionSave
extends RefCounted

const PATH := "user://wild_garden_session.json"
const IDS := ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]

static func _number(value: Variant, low: float, high: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= low and float(value) <= high

static func _integer(value: Variant, low: int, high: int) -> bool:
	return _number(value, low, high) and floorf(float(value)) == float(value)

static func valid(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not _integer(data.get("session_version"), 1, 1) or data.get("active") != true:
		return false
	for key in ["score", "best_score", "best_at_start", "spawn_count", "merge_count", "combo_count", "combo_events", "max_combo", "highest_level"]:
		if not _integer(data.get(key), 0, 1000000000): return false
	if int(data.highest_level) < 1 or int(data.highest_level) > 12 or int(data.best_score) < int(data.score): return false
	for key in ["combo_left", "cooldown_left"]:
		if not _number(data.get(key), 0, 60): return false
	if not _number(data.get("aim_x"), 0, 720): return false
	if data.get("current") not in IDS.slice(0, 5) or data.get("next") not in IDS.slice(0, 5): return false
	if typeof(data.get("rng_state")) != TYPE_STRING or not data.rng_state.is_valid_int(): return false
	if not _integer(data.get("tutorial_stage"), -1, 4): return false
	if typeof(data.get("bodies")) != TYPE_ARRAY or data.bodies.size() > 500: return false
	var seen := {}
	for body in data.bodies:
		if typeof(body) != TYPE_DICTIONARY or body.get("id") not in IDS: return false
		if not _integer(body.get("uid"), 1, 500) or seen.has(int(body.uid)): return false
		seen[int(body.uid)] = true
		if not _number(body.get("x"), 50, 670) or not _number(body.get("y"), 200, 1140): return false
		if not _number(body.get("rotation"), -1000000, 1000000): return false
		if not _number(body.get("vx"), -10000, 10000) or not _number(body.get("vy"), -10000, 10000) or not _number(body.get("angular_velocity"), -10000, 10000): return false
		if not _number(body.get("danger"), 0, 10) or typeof(body.get("sleeping")) != TYPE_BOOL: return false
	return true

static func _future_schema(envelope: Dictionary) -> bool:
	return envelope.status == "ok" and _integer(envelope.data.get("session_version"), 2, 1000000)

static func can_write() -> bool:
	for path in [PATH, PATH + ".bak"]:
		var envelope := SaveManager._read_envelope(path)
		if envelope.status in ["future", "io_error"] or _future_schema(envelope): return false
	return true

static func load_session() -> Dictionary:
	var first := SaveManager._read_envelope(PATH)
	if first.status in ["future", "io_error"]: return first
	if _future_schema(first): return {"status": "future"}
	if first.status == "ok":
		# Explicitly inactive (game over / new game) suppresses older backups.
		if first.data.get("session_version") == 1 and first.data.get("active") == false: return {"status": "missing"}
		if valid(first.data): return first
	var backup := SaveManager._read_envelope(PATH + ".bak")
	if backup.status in ["future", "io_error"]: return backup
	if _future_schema(backup): return {"status": "future"}
	if backup.status == "ok":
		if backup.data.get("session_version") == 1 and backup.data.get("active") == false: return {"status": "missing"}
		if valid(backup.data): return {"status": "recovered", "data": backup.data}
	return {"status": "missing" if first.status == "missing" and backup.status == "missing" else "corrupt"}

static func clear_session() -> Error:
	if not can_write(): return ERR_UNAVAILABLE
	var primary := SaveManager._read_envelope(PATH)
	var keep_primary: bool = primary.status == "ok" and (valid(primary.data) or (primary.data.get("session_version") == 1 and primary.data.get("active") == false))
	var tombstone := {"session_version": 1, "active": false}
	var result := SaveManager.save_progress(tombstone, PATH, keep_primary)
	if result != OK: return result
	# Replace the backup as well, otherwise corrupting the tombstone could revive
	# a previously finished or deliberately replaced game.
	return SaveManager.save_progress(tombstone, PATH)

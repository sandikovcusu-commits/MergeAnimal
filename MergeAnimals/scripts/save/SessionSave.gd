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
	if int(data.highest_level) < 1 or int(data.highest_level) > 12: return false
	if int(data.best_score) < int(data.score) and data.get("tainted") != true and data.get("score_untrusted") != true: return false
	for key in ["combo_left", "cooldown_left"]:
		if not _number(data.get(key), 0, 60): return false
	if not _number(data.get("aim_x"), 0, 720): return false
	if data.get("current") not in IDS.slice(0, 5) or data.get("next") not in IDS.slice(0, 5): return false
	if typeof(data.get("rng_state")) != TYPE_STRING or not data.rng_state.is_valid_int(): return false
	if not _integer(data.get("tutorial_stage"), -1, 4): return false
	if data.has("progression") and not Progression.valid(data.progression): return false
	if data.has("tainted") and typeof(data.tainted) != TYPE_BOOL: return false
	if data.has("score_untrusted") and typeof(data.score_untrusted) != TYPE_BOOL: return false
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
		if body.has("eligible") and typeof(body.eligible) != TYPE_BOOL: return false
	return true

static func _future_schema(envelope: Dictionary) -> bool:
	return envelope.status == "ok" and (_integer(envelope.data.get("session_version"), 2, 1000000) or (typeof(envelope.data.get("progression")) == TYPE_DICTIONARY and _integer(envelope.data.progression.get("version"), 2, 1000000)))

static func can_write() -> bool:
	for path in [PATH, PATH + ".bak"]:
		var envelope := SaveManager._read_envelope(path)
		if envelope.status in ["future", "io_error"] or _future_schema(envelope): return false
	var doc := load_document()
	return doc.status in ["ok", "recovered", "missing"]

static func _inactive(data: Dictionary) -> bool:
	return data.get("session_version") == 1 and data.get("active") == false and (not data.has("progression") or Progression.valid(data.progression))

static func load_document() -> Dictionary:
	var first := SaveManager._read_envelope(PATH)
	if first.status in ["future", "io_error"]: return first
	if _future_schema(first): return {"status": "future"}
	if first.status == "ok" and (valid(first.data) or _inactive(first.data)): return first
	var backup := SaveManager._read_envelope(PATH + ".bak")
	if backup.status in ["future", "io_error"]: return backup
	if _future_schema(backup): return {"status": "future"}
	if backup.status == "ok" and (valid(backup.data) or _inactive(backup.data)):
		return {"status": "recovered", "data": backup.data}
	return {"status": "missing" if first.status == "missing" and backup.status == "missing" else "corrupt"}

static func load_session() -> Dictionary:
	var document := load_document()
	if document.status in ["ok", "recovered"] and _inactive(document.data): return {"status": "missing"}
	return document

static func load_progression(best: int = 0) -> Dictionary:
	var doc := load_document()
	var legacy_best: int = int(SaveManager.legacy_seed().best_score)
	if doc.status in ["ok", "recovered"] and doc.data.has("progression"):
		var result: Dictionary = doc.data.progression.duplicate(true)
		result.best_score = maxi(int(result.best_score), maxi(best, legacy_best))
		return result
	if doc.status in ["ok", "recovered"] and doc.data.get("active") == true:
		legacy_best = maxi(legacy_best, int(doc.data.get("best_score", 0)))
	var fresh := Progression.empty(maxi(best, legacy_best))
	# A live legacy session is one known game; prior totals and dates are unknown.
	if doc.status in ["ok", "recovered"] and doc.data.get("active") == true:
		fresh.total_games = 1
	return fresh

static func clear_session(progress: Variant = null) -> Error:
	if not can_write(): return ERR_UNAVAILABLE
	var primary := SaveManager._read_envelope(PATH)
	var keep_primary: bool = primary.status == "ok" and (valid(primary.data) or _inactive(primary.data))
	if progress == null: progress = load_progression()
	if not Progression.valid(progress): return ERR_INVALID_DATA
	var tombstone := {"session_version": 1, "active": false, "progression": progress}
	var result := SaveManager.save_progress(tombstone, PATH, keep_primary)
	if result != OK: return result
	# Replace both copies so a damaged tombstone cannot revive an older game.
	return SaveManager.save_progress(tombstone, PATH)

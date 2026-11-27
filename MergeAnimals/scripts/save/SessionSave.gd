## Classic-session schema and validation. Never partially apply an invalid snapshot.
class_name SessionSave
extends RefCounted

const PATH := "user://wild_garden_session.json"
# This checkpoint is the commit record for irreversible power-ups in user://.
# On Web, successful file operations do not acknowledge the asynchronous
# IndexedDB sync; sudden page termination can still lose recent writes.
const POWERUP_PATH := "user://wild_garden_powerup.json"
const IDS := ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]

static func _number(value: Variant, low: float, high: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= low and float(value) <= high

static func _integer(value: Variant, low: int, high: int) -> bool:
	return _number(value, low, high) and floorf(float(value)) == float(value)

static func valid(data: Variant, allow_undo: bool = true) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not _integer(data.get("session_version"), 1, 3) or data.get("active") != true:
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
	if int(data.session_version) >= 2 and not data.has("progression"): return false
	if data.has("progression") and not Progression.valid(data.progression): return false
	if data.has("tainted") and typeof(data.tainted) != TYPE_BOOL: return false
	if data.has("score_untrusted") and typeof(data.score_untrusted) != TYPE_BOOL: return false
	# Optional additive v2 field: old snapshots migrate to one free use.
	if data.has("remove_remaining") and not _integer(data.remove_remaining, 0, 1): return false
	if data.has("rescue_remaining") and not _integer(data.rescue_remaining, 0, 1): return false
	if data.has("ad_rescue_earned") and typeof(data.ad_rescue_earned) != TYPE_BOOL: return false
	if data.has("session_id"):
		if typeof(data.session_id) != TYPE_STRING or data.session_id.length() != 32: return false
		for character in data.session_id:
			if character not in "0123456789abcdef": return false
	if data.has("game_over_pending") and typeof(data.game_over_pending) != TYPE_BOOL: return false
	if int(data.session_version) == 3:
		if not _integer(data.get("generation"), 0, 1000000000): return false
		if not _integer(data.get("undo_remaining"), 0, 1): return false
		if not _integer(data.get("next_body_uid"), 1, 1000000000): return false
		if typeof(data.get("undo_snapshot")) != TYPE_DICTIONARY: return false
		if not data.undo_snapshot.is_empty():
			if not allow_undo or data.undo_snapshot.get("session_version") != 3 or not valid(data.undo_snapshot, false): return false
	if typeof(data.get("bodies")) != TYPE_ARRAY or data.bodies.size() > 500: return false
	var seen := {}
	for body in data.bodies:
		if typeof(body) != TYPE_DICTIONARY or body.get("id") not in IDS: return false
		if not _integer(body.get("uid"), 1, 1000000000) or seen.has(int(body.uid)): return false
		seen[int(body.uid)] = true
		if int(data.session_version) == 3 and int(body.uid) >= int(data.next_body_uid): return false
		if not _number(body.get("x"), 50, 670) or not _number(body.get("y"), 200, 1140): return false
		if not _number(body.get("rotation"), -1000000, 1000000): return false
		if not _number(body.get("vx"), -10000, 10000) or not _number(body.get("vy"), -10000, 10000) or not _number(body.get("angular_velocity"), -10000, 10000): return false
		if not _number(body.get("danger"), 0, 10) or typeof(body.get("sleeping")) != TYPE_BOOL: return false
		if body.has("eligible") and typeof(body.eligible) != TYPE_BOOL: return false
	return true

static func _future_schema(envelope: Dictionary) -> bool:
	return envelope.status == "ok" and (_integer(envelope.data.get("session_version"), 4, 1000000) or (typeof(envelope.data.get("progression")) == TYPE_DICTIONARY and _integer(envelope.data.progression.get("version"), 2, 1000000)))

static func can_write() -> bool:
	for path in [PATH, PATH + ".bak", POWERUP_PATH]:
		var envelope := SaveManager._read_envelope(path)
		if envelope.status in ["future", "io_error"] or _future_schema(envelope): return false
	var doc := load_document()
	return doc.status in ["ok", "recovered", "missing"]

static func _inactive(data: Dictionary) -> bool:
	return _integer(data.get("session_version"), 1, 3) and (int(data.session_version) < 3 or _integer(data.get("generation"), 0, 1000000000)) and data.get("active") == false and (int(data.session_version) == 1 or data.has("progression")) and (not data.has("progression") or Progression.valid(data.progression))

static func load_document() -> Dictionary:
	# A power-up checkpoint is a commit record, not an ordinary stale
	# backup. If it exists but cannot be validated, fail closed instead of
	# accidentally restoring an older free use.
	var powerup := SaveManager._read_envelope(POWERUP_PATH)
	if powerup.status in ["future", "io_error", "corrupt"]: return powerup
	if _future_schema(powerup): return {"status": "future"}
	if powerup.status == "ok" and not (valid(powerup.data) or _inactive(powerup.data)):
		return {"status": "corrupt"}
	var first := SaveManager._read_envelope(PATH)
	if first.status in ["future", "io_error"]: return first
	if _future_schema(first): return {"status": "future"}
	var backup := SaveManager._read_envelope(PATH + ".bak")
	if backup.status in ["future", "io_error"] or _future_schema(backup):
		return {"status": "future"} if _future_schema(backup) else backup
	var best: Dictionary = {}
	var best_generation := -1
	var source := ""
	for entry in [[first, "primary"], [backup, "backup"], [powerup, "powerup"]]:
		var envelope: Dictionary = entry[0]
		if envelope.status != "ok" or not (valid(envelope.data) or _inactive(envelope.data)): continue
		var generation: int = int(envelope.data.get("generation", 0))
		if generation > best_generation:
			best_generation = generation
			best = envelope.data
			source = entry[1]
	if source != "":
		var source_path := PATH if source == "primary" else PATH + ".bak" if source == "backup" else POWERUP_PATH
		return {"status": "ok" if source == "primary" else "recovered", "data": best, "source_path": source_path}
	return {"status": "missing" if first.status == "missing" and backup.status == "missing" and powerup.status == "missing" else "corrupt"}

# Every new checkpoint has a strictly higher local generation. Single writer
# only. A power-up's separate full snapshot is committed first; if mirroring
# the ordinary save fails it remains the authoritative, recoverable commit.
static func write_snapshot(snapshot: Dictionary, powerup: bool = false) -> Error:
	if not can_write(): return ERR_UNAVAILABLE
	var doc := load_document()
	var generation: int = int(doc.data.get("generation", 0)) if doc.status in ["ok", "recovered"] else 0
	var candidate := snapshot.duplicate(true)
	candidate.generation = generation + 1
	if not valid(candidate): return ERR_INVALID_DATA
	if powerup:
		var committed := SaveManager.save_progress(candidate, POWERUP_PATH, false)
		if committed != OK: return committed
	var primary := SaveManager._read_envelope(PATH)
	var keep_primary: bool = primary.status == "ok" and (valid(primary.data) or _inactive(primary.data))
	var result := SaveManager.save_progress(candidate, PATH, keep_primary)
	if powerup:
		if result == OK:
			result = SaveManager.save_progress(candidate, PATH)
		if result != OK: push_warning("Power-up checkpoint committed; ordinary save mirror failed: %s" % result)
		return OK
	return result

static func load_session() -> Dictionary:
	var document := load_document()
	if document.status in ["ok", "recovered"] and _inactive(document.data): return {"status": "missing"}
	return document

static func load_progression(best: int = 0) -> Dictionary:
	var doc := load_document()
	var legacy_best: int = int(SaveManager.legacy_seed().best_score)
	if doc.status in ["ok", "recovered"] and doc.data.has("progression"):
		var result: Dictionary = doc.data.progression.duplicate(true)
		if int(doc.data.get("session_version", 1)) < 3:
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
	var doc := load_document()
	if progress == null:
		progress = load_progression()
		if doc.status in ["ok", "recovered"] and doc.data.get("active") == true and doc.data.get("game_over_pending", false) == true:
			progress.completed_games = int(progress.completed_games) + 1
	if not Progression.valid(progress): return ERR_INVALID_DATA
	var generation: int = int(doc.data.get("generation", 0)) + 1 if doc.status in ["ok", "recovered"] else 1
	var tombstone := {"session_version": 3, "generation": generation, "active": false, "progression": progress}
	# The generation checkpoint is also the commit point for ending/restarting a
	# session. This prevents an older active power-up checkpoint reviving a game
	# if ordinary tombstone mirroring fails and the primary is later corrupted.
	var committed := SaveManager.save_progress(tombstone, POWERUP_PATH, false)
	if committed != OK: return committed
	var result := SaveManager.save_progress(tombstone, PATH, keep_primary)
	if result == OK: result = SaveManager.save_progress(tombstone, PATH)
	if result != OK: push_warning("Session tombstone committed; ordinary mirror failed: %s" % result)
	return OK

## Cosmetics only. Unlocks use validated persisted results, never the active board.
class_name ThemeStore
extends RefCounted
const PATH := "user://wild_garden_themes.json"
const IDS := ["forest", "sunset", "snow"]
const BACKGROUNDS := [preload("res://assets/backgrounds/forest_garden.svg"), preload("res://assets/backgrounds/sunset_safari.svg"), preload("res://assets/backgrounds/snowy_valley.svg")]
const THEMES := [preload("res://assets/ui/themes/forest.tres"), preload("res://assets/ui/themes/sunset.tres"), preload("res://assets/ui/themes/snow.tres")]
static func empty() -> Dictionary: return {"version": 1, "selected": "forest", "unlocked": ["forest"]}
static func valid(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT] or float(data.version) != 1.0: return false
	if typeof(data.get("selected")) != TYPE_STRING or data.selected not in IDS or typeof(data.get("unlocked")) != TYPE_ARRAY: return false
	if "forest" not in data.unlocked or data.selected not in data.unlocked: return false
	var seen := {}
	for id in data.unlocked:
		if id not in IDS or seen.has(id): return false
		seen[id] = true
	return true
static func load_state() -> Dictionary:
	var primary := SaveManager._read_envelope(PATH)
	var backup := SaveManager._read_envelope(PATH + ".bak")
	for item in [primary, backup]:
		if item.status in ["future", "io_error"]: return {"status": "unavailable"}
		if item.status == "ok" and typeof(item.data.get("version")) in [TYPE_INT, TYPE_FLOAT] and float(item.data.version) > 1.0: return {"status": "unavailable"}
	if primary.status == "ok" and valid(primary.data): return {"status": "ok", "data": primary.data}
	if backup.status == "ok" and valid(backup.data): return {"status": "recovered", "data": backup.data}
	if primary.status == "missing" and backup.status == "missing": return {"status": "missing", "data": empty()}
	return {"status": "corrupt"}
static func _save(data: Dictionary) -> Error:
	if not valid(data): return ERR_INVALID_DATA
	var primary := SaveManager._read_envelope(PATH)
	var err := SaveManager.save_progress(data, PATH, primary.status == "ok" and valid(primary.data))
	if err != OK: return err
	if SaveManager.save_progress(data, PATH, true) != OK: push_warning("Theme backup refresh failed")
	return OK
static func refresh() -> Dictionary:
	var state := load_state()
	if state.status not in ["ok", "recovered", "missing"]: return state
	var next: Dictionary = state.data.duplicate(true)
	var doc := SessionSave.load_document()
	if doc.status in ["ok", "recovered", "missing"]:
		var progress := SessionSave.load_progression()
		if Progression.valid(progress) and int(progress.best_score) >= 500 and "sunset" not in next.unlocked: next.unlocked.append("sunset")
	var challenges := ChallengeStore.load_results()
	if challenges.status in ["ok", "recovered", "missing"]:
		var count := 0
		for entry in challenges.data.entries:
			if entry.completed: count += 1
		if count >= 10 and "snow" not in next.unlocked: next.unlocked.append("snow")
	if next != state.data:
		if _save(next) != OK: return {"status": "write_failed", "data": state.data}
		AudioManager.play_event("theme_unlocked")
	return {"status": "ok", "data": next}
static func select(id: String) -> Error:
	var loaded := refresh()
	if loaded.status != "ok": return ERR_UNAVAILABLE
	if id not in loaded.data.unlocked: return ERR_UNAUTHORIZED
	if id == loaded.data.selected: return OK
	var data: Dictionary = loaded.data.duplicate(true); data.selected = id
	return _save(data)
static func current_index() -> int:
	var loaded := load_state()
	if loaded.status not in ["ok", "recovered", "missing"]: return 0
	return maxi(0, IDS.find(loaded.data.selected))
static func background() -> Texture2D: return BACKGROUNDS[current_index()]
static func ui_theme() -> Theme: return THEMES[current_index()]

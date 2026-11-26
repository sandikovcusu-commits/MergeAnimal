## Local lifetime values travel in the same transaction as the Classic snapshot.
class_name Progression
extends RefCounted

const VERSION := 1
const IDS := ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]
const COUNTERS := ["total_games", "completed_games", "total_drops", "total_merges", "best_score", "highest_animal", "max_combo", "golden_merges"]

static func empty(best: int = 0) -> Dictionary:
	var animals := {}
	for id in IDS: animals[id] = {"count": 0, "date": ""}
	return {"version": VERSION, "total_games": 0, "completed_games": 0, "total_drops": 0, "total_merges": 0, "best_score": maxi(0, best), "highest_animal": 0, "max_combo": 0, "golden_merges": 0, "play_seconds": 0.0, "animals": animals}

static func valid(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY or value.get("version") != VERSION: return false
	for key in COUNTERS:
		var n: Variant = value.get(key)
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or float(n) < 0 or float(n) > 1000000000 or floorf(float(n)) != float(n): return false
	if int(value.highest_animal) > 12 or int(value.completed_games) > int(value.total_games): return false
	var seconds: Variant = value.get("play_seconds")
	if typeof(seconds) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(seconds)) or float(seconds) < 0 or float(seconds) > 1000000000: return false
	if typeof(value.get("animals")) != TYPE_DICTIONARY or value.animals.size() != IDS.size(): return false
	for id in IDS:
		var entry: Variant = value.animals.get(id)
		if typeof(entry) != TYPE_DICTIONARY: return false
		var count: Variant = entry.get("count")
		var date: Variant = entry.get("date")
		if typeof(count) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(count)) or float(count) < 0 or float(count) > 1000000000 or floorf(float(count)) != float(count): return false
		if typeof(date) != TYPE_STRING or date.length() > 32 or (int(count) > 0 and date.is_empty()): return false
	return true

static func record_animal(progress: Dictionary, data: AnimalData) -> bool:
	var entry: Dictionary = progress.animals[str(data.id)]
	var first := str(entry.date).is_empty()
	entry.count = int(entry.count) + 1
	if first: entry.date = Time.get_datetime_string_from_system(false, true)
	progress.highest_animal = maxi(int(progress.highest_animal), data.level)
	return first

static func discovered(progress: Dictionary) -> int:
	var count := 0
	for id in IDS:
		if not str(progress.animals[id].date).is_empty(): count += 1
	return count

## Declarative condition. Runtime progress is stored separately, not in this shared Resource.
class_name AchievementData
extends Resource
@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_enum("total_merges", "discovery", "golden_merges", "best_score", "max_combo", "challenges", "collection") var objective_type: String = ""
@export var target: int = 1
@export var progress: int = 0
@export var hidden: bool = false
@export var unlock_condition: String = ""

func localized_title() -> String:
	var key := "ACH_" + id + "_TITLE"
	var translated := TranslationServer.translate(key)
	return title if translated == key else translated
func localized_description() -> String:
	var key := "ACH_" + id + "_DESC"
	var translated := TranslationServer.translate(key)
	return description if translated == key else translated

class_name CollectionNames
extends RefCounted
const NAMES := ["Mouse", "Hamster", "Rabbit", "Cat", "Dog", "Fox", "Raccoon", "Koala", "Panda", "Bear", "Lion", "Elephant"]
static func name_for_level(level: int) -> String:
	return TranslationServer.translate("ANIMAL_" + Progression.IDS[clampi(level - 1, 0, 11)].to_upper())

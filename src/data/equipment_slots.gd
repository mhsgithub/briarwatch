class_name EquipmentSlots
extends RefCounted
## Stable save keys and their accepted item categories. UI and inventory share this schema.
const DEFINITIONS: Array[Dictionary] = [
	{"id": "head", "label": "Head", "category": "head", "icon": 8},
	{"id": "amulet", "label": "Amulet", "category": "amulet", "icon": 13},
	{"id": "shoulders", "label": "Shoulders", "category": "shoulders", "icon": 9},
	{"id": "body", "label": "Armor", "category": "body", "icon": 6},
	{"id": "gloves", "label": "Gloves", "category": "gloves", "icon": 10},
	{"id": "weapon", "label": "Main hand", "category": "weapon", "icon": 0},
	{"id": "shield", "label": "Off hand", "category": "shield", "icon": 1},
	{"id": "belt", "label": "Belt", "category": "belt", "icon": 11},
	{"id": "ring_left", "label": "Ring I", "category": "ring", "icon": 14},
	{"id": "ring_right", "label": "Ring II", "category": "ring", "icon": 14},
	{"id": "boots", "label": "Boots", "category": "boots", "icon": 12},
]

static func empty_equipment() -> Dictionary:
	var result := {}
	for slot in DEFINITIONS:
		result[slot.id] = null
	return result

static func accepts(slot_id: String, category: String) -> bool:
	for slot in DEFINITIONS:
		if slot.id == slot_id:
			return slot.category == category
	return false

static func label_for(slot_id: String) -> String:
	for slot in DEFINITIONS:
		if slot.id == slot_id:
			return slot.label
	return slot_id.capitalize()

class_name LootDrop
extends Node3D
var item: ItemDefinition
var gold: int = 0
var taken: bool = false

func _ready() -> void:
	add_to_group("interactables")
	var color := item.tint if item else Color("dfb669")
	Geometry.cylinder(self, Vector3(0, 0.18, 0), 0.28, 0.3, color, 0.15, 6)
	Geometry.label(self, interaction_name(), Vector3(0, 0.85, 0), color, 24)

func interaction_name() -> String:
	return item.display_name if item else "%d crowns" % gold

func collect(inventory: Inventory) -> bool:
	if taken:
		return false
	if item and not inventory.add(item):
		return false
	taken = true
	inventory.gold += gold
	inventory.changed.emit()
	queue_free()
	return true

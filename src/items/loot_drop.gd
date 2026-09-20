class_name LootDrop
extends Node3D
var item: ItemDefinition
var gold: int = 0
var taken: bool = false
var source_id: String = ""

func _ready() -> void:
	add_to_group("interactables")
	var color := ArtTheme.tier_color(item) if item else Color("dfb669")
	Geometry.cylinder(self, Vector3(0, 0.18, 0), 0.28, 0.3, color, 0.15, 6)
	Geometry.label(self, item.display_name if item else str(gold), Vector3(0, 0.85, 0), color, 24)
	if item == null:
		var coin := Sprite3D.new()
		coin.texture = ArtTheme.icon(15)
		coin.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		coin.pixel_size = 0.0025
		coin.no_depth_test = true
		coin.position = Vector3(-0.50,0.85,0)
		add_child(coin)

func interaction_name() -> String:
	return item.display_name if item else "Gold"

func collect(inventory: Inventory) -> bool:
	if taken:
		return false
	if item and not inventory.add(item):
		return false
	taken = true
	AudioLibrary.play_ui(get_tree().root,"pack" if item else "gold_pickup")
	inventory.gold += gold
	inventory.changed.emit()
	queue_free()
	return true

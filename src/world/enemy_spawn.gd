@tool
class_name EnemySpawn
extends Marker3D

@export var spawn_id: StringName
@export var definition: EnemyDefinition:
	set(value):
		definition = value
		if is_inside_tree():
			call_deferred("_preview")
@export_group("Instance overrides (-1 uses type default)")
@export_range(-1, 10000) var health_override: float = -1
@export_range(-1, 1000) var damage_override: float = -1

func _ready() -> void:
	if Engine.is_editor_hint():
		_preview()

func _preview() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if definition == null or not Engine.is_editor_hint():
		return
	var visual := ActorVisual.new()
	visual.style = definition.behavior
	if definition.commander: visual.style = "commander"
	if definition.brute: visual.style = "brutus"
	if not definition.appearance.is_empty(): visual.style = definition.appearance
	visual.scale = Vector3.ONE * definition.visual_scale
	visual.tint = definition.tint
	add_child(visual)
	Geometry.label(self, "%s\nHP %s | DMG %s" % [definition.display_name, definition.max_health if health_override < 0 else health_override, definition.attack.damage if damage_override < 0 else damage_override], Vector3(0, 2.5, 0), Color("ffe2a3"), 26)

func spawn(parent: Node3D, encounter: StringName) -> Enemy:
	if definition == null:
		return null
	var enemy: Enemy = preload("res://scenes/entities/enemy.tscn").instantiate()
	enemy.definition = definition
	enemy.spawn_id = spawn_id
	enemy.encounter_id = encounter
	enemy.health_override = health_override
	enemy.damage_override = damage_override
	# Set position before _ready captures home; dynamic root shares region transform.
	enemy.position = parent.to_local(global_position)
	parent.add_child(enemy)
	return enemy

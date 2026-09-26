class_name RisenCombat
extends Node
var actor: Enemy
var region: Region
var field: CorruptionField
var spread_left: float = 0.0

func _ready() -> void:
	region = actor.get_parent().get_parent() as Region
	actor.health.damaged.connect(_damaged)
	actor.health.died.connect(_died)

func _physics_process(delta: float) -> void:
	if actor.dormant or actor.health.current <= 0 or not actor.aggro or actor.returning: return
	spread_left -= delta
	if spread_left > 0: return
	var kit := actor.definition.risen
	spread_left = kit.pool_interval
	if not is_instance_valid(field):
		for child in region.actors.get_children():
			if child is CorruptionField and child.owner_id == str(actor.spawn_id): field = child
		if not is_instance_valid(field):
			field = CorruptionField.new()
			field.owner_id = str(actor.spawn_id)
			field.radius = kit.pool_radius
			field.damage = kit.pool_damage
			field.interval = kit.pool_tick
			field.tick_left = kit.pool_tick
			region.actors.add_child(field)
	if field.spread(actor.global_position,kit.pool_spacing):
		AudioLibrary.play_world(actor,actor.global_position,"corruption_spread")

func _damaged(_amount: float) -> void:
	if actor.health.current <= 0 or actor.health.current > actor.health.maximum*actor.definition.risen.reinforcement_threshold: return
	if region.world_state.get("crypt_reinforcement",false): return
	region.world_state["crypt_reinforcement"] = true
	restore_reinforcement()
	AudioLibrary.play_world(actor,actor.global_position,"bone_rise")

func restore_reinforcement() -> void:
	restore_summon(region,actor.definition.risen.reinforcement_marker)

static func restore_summon(region: Region, marker_path: NodePath) -> void:
	if not region.world_state.get("crypt_reinforcement",false): return
	var marker := region.get_node(marker_path) as EnemySpawn
	if str(marker.spawn_id) in region.defeated_ids: return
	for child in region.actors.get_children():
		if child is Enemy and child.spawn_id == marker.spawn_id: return
	var reinforcement := marker.spawn(region.actors,&"crypt_reinforcement")
	reinforcement.aggro = true
	region.register_summon(reinforcement)

func _died() -> void:
	for child in region.actors.get_children():
		if child is CorruptionField and child.owner_id == str(actor.spawn_id): child.clear()

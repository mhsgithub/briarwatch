class_name AttackComponent
extends Node
## Timing and hit resolution shared by player and enemies. Windup locks aim.
signal started(direction: Vector3, duration: float)
signal resolved

var definition: AttackDefinition
var damage_bonus: float = 0.0
var damage_override: float = -1.0
var target_group: StringName
var remaining: float = 0.0
var windup_left: float = 0.0
var pending: bool = false
var direction: Vector3 = Vector3.FORWARD

func request(aim: Vector3) -> bool:
	if definition == null or remaining > 0 or aim.length_squared() < 0.01:
		return false
	direction = aim.normalized()
	direction.y = 0
	remaining = definition.cooldown
	windup_left = definition.windup
	pending = true
	started.emit(direction, windup_left)
	return true

func cancel() -> void:
	pending = false
	remaining = 0

func _physics_process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	if not pending:
		return
	windup_left -= delta
	if windup_left <= 0:
		pending = false
		_resolve()
		resolved.emit()

func _resolve() -> void:
	var actor := get_parent() as Node3D
	var amount := definition.damage if damage_override < 0 else damage_override
	amount += damage_bonus
	if definition.projectile:
		var arrow := preload("res://scenes/entities/projectile.tscn").instantiate()
		arrow.direction = direction
		arrow.speed = definition.projectile_speed
		arrow.packet = DamagePacket.new(amount, actor, definition.damage_type)
		arrow.target_group = target_group
		actor.get_parent().add_child(arrow)
		arrow.global_position = actor.global_position + Vector3.UP * 0.9 + direction * 0.65
		return
	for candidate in get_tree().get_nodes_in_group(target_group):
		if not is_instance_valid(candidate) or not candidate.has_method("receive_damage"):
			continue
		var offset: Vector3 = candidate.global_position - actor.global_position
		offset.y = 0
		if offset.length() > definition.reach:
			continue
		if offset.length() > 0.1 and direction.dot(offset.normalized()) < cos(deg_to_rad(definition.arc_degrees * 0.5)):
			continue
		var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, candidate.global_position + Vector3.UP, 1)
		if actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			candidate.receive_damage(DamagePacket.new(amount, actor, definition.damage_type))

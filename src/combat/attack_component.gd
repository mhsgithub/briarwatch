class_name AttackComponent
extends Node
## Timing and hit resolution shared by player and enemies. Windup locks aim.
signal started(direction: Vector3, duration: float)
signal resolved
signal missed(target: Node3D)

var definition: AttackDefinition
var damage_bonus: float = 0.0
var damage_override: float = -1.0
var cooldown_override: float = -1.0
var target_group: StringName
var remaining: float = 0.0
var windup_left: float = 0.0
var pending: bool = false
var direction: Vector3 = Vector3.FORWARD
var hit_chance: float = 1.0
var minimum_damage: float = 0.0
var rng := RandomNumberGenerator.new()
var swing_multiplier: float = 1.0
var swing_stun: float = 0.0
var knockback: float = 0.0

func _ready() -> void:
	rng.randomize()

func roll_hit() -> bool:
	return hit_chance >= 1.0 or (hit_chance > 0.0 and rng.randf() < hit_chance)

func request(aim: Vector3) -> bool:
	if definition == null or remaining > 0 or aim.length_squared() < 0.01:
		return false
	direction = aim.normalized()
	direction.y = 0
	remaining = definition.cooldown if cooldown_override < 0 else cooldown_override
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
	amount = (amount + damage_bonus) * swing_multiplier
	if definition.projectile:
		var arrow := preload("res://scenes/entities/projectile.tscn").instantiate()
		arrow.direction = direction
		arrow.speed = definition.projectile_speed
		# Projectiles use physical collision alone; there is no accuracy roll.
		arrow.packet = DamagePacket.new(amount, actor, definition.damage_type, minimum_damage)
		arrow.packet.attack_kind = &"ranged"
		arrow.packet.accuracy = 1.0
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
			# Player resolves accuracy together with avoidance once; ordinary targets
			# keep the component's independent accuracy roll.
			if candidate is Player or roll_hit():
				var packet := DamagePacket.new(amount, actor, definition.damage_type, minimum_damage)
				packet.bleed_damage = definition.bleed_damage
				packet.bleed_ticks = definition.bleed_ticks
				packet.knockdown_seconds = definition.knockdown_seconds
				packet.stun_seconds = swing_stun
				packet.knockback = knockback
				packet.accuracy = hit_chance if candidate is Player else -1.0
				candidate.receive_damage(packet)
			else:
				missed.emit(candidate)

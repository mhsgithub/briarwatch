class_name Enemy
extends CharacterBody3D

signal defeated(enemy: Enemy)
@export var definition: EnemyDefinition
var spawn_id: StringName
var encounter_id: StringName
var health_override: float = -1
var damage_override: float = -1
@onready var health: HealthComponent = $Health
@onready var attack: AttackComponent = $Attack
@onready var visual: ActorVisual = $Visual
@onready var navigation: NavigationAgent3D = $Navigation
var home: Vector3
var target: Player
var aggro: bool = false
var returning: bool = false
var repath: float = 0
var orbit_sign: float = 1
var health_label: Label3D

func _ready() -> void:
	add_to_group("enemies")
	home = global_position
	orbit_sign = 1 if hash(spawn_id) % 2 == 0 else -1
	health.configure(definition.max_health if health_override < 0 else health_override, definition.armor)
	attack.definition = definition.attack
	attack.damage_override = damage_override
	attack.target_group = &"player"
	visual.style = definition.behavior
	visual.tint = definition.tint
	visual.rebuild()
	attack.started.connect(visual.attack_started)
	health.died.connect(_die)
	health.damaged.connect(_damaged)
	health_label = Geometry.label(self, definition.display_name, Vector3(0, 2.3, 0), Color("e6c6ac"), 25)
	health_label.visible = false
	target = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if health.current <= 0 or not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if target.dead:
		aggro = false
		returning = true
	elif not aggro and not returning and distance < definition.aggro_radius:
		aggro = _has_sight(target.global_position)
	if global_position.distance_to(home) > definition.leash_radius:
		aggro = false
		returning = true
	health_label.visible = aggro
	health_label.text = "%s  %d / %d" % [definition.display_name, health.current, health.maximum]
	var destination := home
	var wants_move := false
	if returning:
		wants_move = true
		if global_position.distance_to(home) < 1.2:
			returning = false
			health.heal(health.maximum)
	elif aggro:
		_face(offset)
		var sight := _has_sight(target.global_position)
		match definition.behavior:
			"archer":
				if distance < definition.preferred_range - 1.2:
					destination = global_position - offset.normalized() * 4
					wants_move = true
				elif distance > definition.attack.reach or not sight:
					destination = target.global_position
					wants_move = true
				elif not attack.pending:
					attack.request(offset)
			"wolf":
				if distance <= definition.attack.reach:
					attack.request(offset)
					if attack.remaining > 0.5 and not attack.pending:
						destination = global_position - offset.normalized() * 2.5 + Vector3(-offset.z, 0, offset.x).normalized() * orbit_sign * 1.5
						wants_move = true
				else:
					destination = target.global_position
					if distance < 5 and attack.remaining > 0:
						destination += Vector3(-offset.z, 0, offset.x).normalized() * orbit_sign * 2
					wants_move = true
			_:
				if distance <= definition.attack.reach * 0.9 and sight:
					attack.request(offset)
				else:
					destination = target.global_position
					wants_move = true
	velocity = Vector3.ZERO
	repath -= delta
	if wants_move and not attack.pending and NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) > 0:
		if repath <= 0:
			navigation.target_position = destination
			repath = 0.25
		var step := navigation.get_next_path_position() - global_position
		step.y = 0
		velocity = step.normalized() * definition.move_speed
		if step.length() < 0.12:
			velocity = Vector3.ZERO
		if not aggro:
			_face(step)
	velocity.y = -2
	move_and_slide()
	visual.moving = Vector2(velocity.x, velocity.z).length() > 0.2

func _face(direction: Vector3) -> void:
	if direction.length_squared() > 0.01:
		visual.rotation.y = atan2(-direction.x, -direction.z)

func _has_sight(point: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, point + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func receive_damage(packet: DamagePacket) -> void:
	if returning:
		return
	aggro = true
	health.receive(packet)

func _damaged(amount: float) -> void:
	visual.hit()
	var text := Geometry.label(get_parent(), str(int(amount)), global_position + Vector3.UP * 2, Color("f7dba0"), 38)
	text.set_script(preload("res://src/presentation/floating_text.gd"))

func _die() -> void:
	attack.cancel()
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	health_label.visible = false
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(visual, "rotation:z", PI * 0.5, 0.25)
	tween.tween_interval(1.5)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.5)
	tween.tween_callback(queue_free)

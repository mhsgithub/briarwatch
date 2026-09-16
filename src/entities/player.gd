class_name Player
extends CharacterBody3D

signal died
signal interaction_requested(target: Node)
signal feedback(text: String)

@export var move_speed: float = 6.2
@export var base_health: float = 110.0
@export var basic_attack: AttackDefinition
@onready var health: HealthComponent = $Health
@onready var attack: AttackComponent = $Attack
@onready var inventory: Inventory = $Inventory
@onready var visual: ActorVisual = $Visual
@onready var navigation: NavigationAgent3D = $Navigation
var input_enabled: bool = true
var dead: bool = false
var click_moving: bool = false
var attack_target: Node3D
var interact_target: Node3D
var camera: Camera3D
var facing := Vector3.FORWARD
var recovery_time: float = 0

func _ready() -> void:
	add_to_group("player")
	$AudioListener.make_current()
	health.configure(base_health)
	attack.definition = basic_attack
	attack.target_group = &"enemies"
	attack.started.connect(visual.attack_started)
	health.damaged.connect(_damaged)
	health.died.connect(_die)
	inventory.changed.connect(_equipment_changed)

func _equipment_changed() -> void:
	attack.damage_bonus = inventory.bonus("damage_bonus")
	health.armor = inventory.bonus("armor_bonus")

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or dead or camera == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var target := _pick_enemy(event.position)
			if target:
				attack_target = target
				interact_target = null
				click_moving = true
			elif Input.is_key_pressed(KEY_SHIFT):
				click_moving = false
				attack_target = null
				_try_attack(_ground_point(event.position) - global_position)
			else:
				_move_to_mouse(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_move_to_mouse(event.position)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			interact_nearest()
		elif event.physical_keycode == KEY_Q:
			use_potion()

func _move_to_mouse(screen: Vector2) -> void:
	attack_target = null
	interact_target = _pick_interactable(screen)
	var point := interact_target.global_position if is_instance_valid(interact_target) else _ground_point(screen)
	navigation.target_position = point
	click_moving = true

func _pick_enemy(screen: Vector2) -> Node3D:
	var best: Node3D
	var distance := 44.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.health.current <= 0 or camera.is_position_behind(enemy.global_position):
			continue
		var d := camera.unproject_position(enemy.global_position + Vector3.UP * 0.8).distance_to(screen)
		if d < distance:
			distance = d
			best = enemy
	return best

func _pick_interactable(screen: Vector2) -> Node3D:
	var best: Node3D
	var distance := 35.0
	for target in get_tree().get_nodes_in_group("interactables"):
		var d := camera.unproject_position(target.global_position + Vector3.UP * 0.8).distance_to(screen)
		if d < distance:
			distance = d
			best = target
	return best

func _ground_point(screen: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
	return global_position if hit == null else hit

func _physics_process(delta: float) -> void:
	recovery_time = maxf(0, recovery_time - delta)
	health.invulnerable = recovery_time > 0
	if dead or not input_enabled:
		velocity = Vector3.ZERO
		visual.moving = false
		return
	var move := Vector3.ZERO
	var axis := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if axis.length_squared() > 0:
		click_moving = false
		attack_target = null
		interact_target = null
		var right := camera.global_basis.x if camera else Vector3.RIGHT
		var backward := Vector3(-right.z, 0, right.x)
		move = (right * axis.x + backward * axis.y).normalized()
	elif click_moving:
		if is_instance_valid(attack_target) and attack_target.health.current > 0:
			var offset := attack_target.global_position - global_position
			navigation.target_position = attack_target.global_position
			if offset.length() <= basic_attack.reach * 0.88:
				_try_attack(offset)
			else:
				move = _navigation_direction()
		elif is_instance_valid(interact_target) and global_position.distance_to(interact_target.global_position) < 2.8:
			click_moving = false
			interaction_requested.emit(interact_target)
		else:
			attack_target = null
			move = _navigation_direction()
			if navigation.is_navigation_finished():
				click_moving = false
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_key_pressed(KEY_SHIFT):
		_try_attack(_ground_point(get_viewport().get_mouse_position()) - global_position)
	if attack.pending:
		move *= 0.15
	velocity = move * move_speed
	velocity.y = -2.0
	move_and_slide()
	visual.moving = move.length() > 0.1
	if move.length() > 0.1 and not attack.pending:
		_face(move)

func _navigation_direction() -> Vector3:
	if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) == 0:
		return Vector3.ZERO
	var offset := navigation.get_next_path_position() - global_position
	offset.y = 0
	return offset.normalized()

func _face(direction: Vector3) -> void:
	direction.y = 0
	if direction.length() < 0.01:
		return
	facing = direction.normalized()
	visual.rotation.y = atan2(-facing.x, -facing.z)

func _try_attack(direction: Vector3) -> void:
	if attack.request(direction):
		_face(direction)

func receive_damage(packet: DamagePacket) -> void:
	health.receive(packet)

func _damaged(_amount: float) -> void:
	visual.hit()

func _die() -> void:
	dead = true
	attack.cancel()
	click_moving = false
	visual.rotation.z = PI * 0.5
	died.emit()

func respawn(point: Vector3) -> void:
	global_position = point
	dead = false
	visual.rotation.z = 0
	health.revive()
	recovery_time = 3.0
	attack_target = null
	interact_target = null

func interact_nearest() -> void:
	var best: Node3D
	var distance := 3.1
	for target in get_tree().get_nodes_in_group("interactables"):
		var d := global_position.distance_to(target.global_position)
		if d < distance:
			distance = d
			best = target
	if best:
		interaction_requested.emit(best)
	else:
		feedback.emit("Move closer to a person or a dropped item.")

func use_potion() -> void:
	if health.current >= health.maximum:
		feedback.emit("Your health is already full.")
		return
	for i in range(inventory.items.size()):
		if inventory.items[i].heal_amount > 0:
			health.heal(inventory.items[i].heal_amount)
			inventory.items.remove_at(i)
			inventory.changed.emit()
			feedback.emit("Field tonic restored health.")
			return
	feedback.emit("No field tonic. Mara sells supplies in town.")

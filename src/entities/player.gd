class_name Player
extends CharacterBody3D

signal died
signal interaction_requested(target: Node)
signal feedback(text: String)

@export var move_speed: float = 4.96
@export var base_health: float = 100.0
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
var potion_recovery: RecoveryComponent
var actions: ActionLoadout
var combat_state: PlayerCombatState
var progression: CharacterProgression
var statuses: StatusEffects
var abilities: PlayerAbilities
var burn_visual: PlayerBurn

func _ready() -> void:
	add_to_group("player")
	navigation.path_height_offset = NavigationServer3D.map_get_cell_height(navigation.get_navigation_map())
	burn_visual=PlayerBurn.new()
	add_child(burn_visual)
	progression = CharacterProgression.new()
	add_child(progression)
	statuses = StatusEffects.new()
	add_child(statuses)
	add_child(StatusVisual.new())
	abilities = PlayerAbilities.new()
	abilities.player = self
	add_child(abilities)
	progression.changed.connect(_equipment_changed)
	potion_recovery = RecoveryComponent.new()
	potion_recovery.health = health
	add_child(potion_recovery)
	actions = ActionLoadout.new()
	actions.progression = progression
	add_child(actions)
	actions.activated.connect(func(kind: StringName, id: StringName):
		if kind == &"item": use_consumable(id)
		elif kind == &"ability": abilities.activate(str(id)))
	$AudioListener.make_current()
	health.configure(base_health)
	attack.definition = basic_attack
	attack.target_group = &"enemies"
	attack.started.connect(visual.attack_started)
	health.damaged.connect(_damaged)
	health.died.connect(_die)
	inventory.changed.connect(_equipment_changed)
	combat_state = PlayerCombatState.new()
	combat_state.player = self
	add_child(combat_state)

func _equipment_changed() -> void:
	attack.damage_bonus = inventory.bonus("damage_bonus") + strength()
	health.armor = inventory.bonus("armor_bonus")
	health.set_maximum(base_health + inventory.bonus("vitality_bonus") * (1.0 + progression.rank("iron_constitution") * 0.05))
	attack.cooldown_override = swing_seconds()
	visual.set_equipment(inventory.equipment)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or dead or combat_state.knockdown_left > 0 or camera == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var target := _pick_enemy(event.position)
			if Input.is_key_pressed(KEY_SHIFT):
				click_moving = false
				attack_target = null
				interact_target = null
				_try_attack(_ground_point(event.position) - global_position)
			elif target:
				attack_target = target
				interact_target = null
				click_moving = true
			else:
				_move_to_mouse(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_move_to_mouse(event.position)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			interact_nearest()

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
	attack.cooldown_override = swing_seconds()
	if abilities.move_leap(delta): return
	if dead or not input_enabled or combat_state.knockdown_left > 0 or statuses.has("stun"):
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
			# Close enough for contact after windup, even if the target retreats.
			# Keep pursuing during cooldown instead of stopping at the range edge.
			var retreat_speed := maxf(0, attack_target.velocity.dot(offset.normalized()))
			var contact_range := basic_attack.reach - maxf(0.25, retreat_speed * basic_attack.windup)
			if offset.length() <= contact_range and attack.remaining <= 0:
				_try_attack(offset)
			elif offset.length() > 1.2:
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
		if is_instance_valid(attack_target) and not Input.is_key_pressed(KEY_SHIFT):
			move = attack.direction * basic_attack.advance_speed / move_speed
		else:
			move *= 0.15
	velocity = move * move_speed * abilities.movement_multiplier() * statuses.movement_factor()
	velocity += abilities.push_velocity
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
	if abilities.storm_left > 0 or abilities.leap_left > 0 or statuses.has("stun"): return
	if attack.request(direction):
		_face(direction)

func receive_damage(packet: DamagePacket) -> void:
	if dead or health.invulnerable: return
	if not abilities.accept_hit(packet): return
	health.receive(packet)
	if not dead and packet.poison_seconds > 0:
		statuses.apply("poison", packet.poison_seconds, packet.poison_damage)
	if not dead and (packet.bleed_ticks > 0 or packet.knockdown_seconds > 0):
		combat_state.apply(packet)
	if not dead and packet.knockback > 0 and not statuses.control_immune and is_instance_valid(packet.source):
		abilities.push_velocity = (global_position-packet.source.global_position).normalized() * packet.knockback
	if not dead and packet.stun_seconds > 0 and statuses.apply("stun",packet.stun_seconds):
		attack.cancel()

func _damaged(_amount: float) -> void:
	visual.hit()

func receive_ground_fire(packet: DamagePacket) -> void:
	if dead: return
	burn_visual.ignite()
	var before := health.current
	receive_damage(packet)
	if health.current<before:
		AudioLibrary.play_world(self,global_position,"fire_hurt")

func _die() -> void:
	dead = true
	burn_visual.clear()
	combat_state.reset()
	abilities.reset()
	statuses.reset()
	potion_recovery.cancel()
	attack.cancel()
	click_moving = false
	visual.rotation.z = PI * 0.5
	died.emit()

func respawn(point: Vector3) -> void:
	burn_visual.clear()
	global_position = point
	dead = false
	combat_state.reset()
	potion_recovery.cancel()
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

func melee_damage() -> float:
	return basic_attack.damage + inventory.bonus("damage_bonus") + strength()

func strength() -> float:
	return inventory.bonus("strength_bonus")

func crit_rating() -> float:
	return inventory.bonus("crit_rating")

func resolve_critical(packet: DamagePacket) -> void:
	# Resolve once per direct hit, including talent attacks. DOT never crits.
	if packet.critical_resolved: return
	packet.critical_resolved = true
	if packet.damage_type not in [&"physical", &"melee", &"ranged"]: return
	packet.critical = abilities.rng.randf() < clampf(crit_rating() / 100.0, 0.0, 1.0)

func reset_talents() -> bool:
	if dead or inventory.gold < 100 or progression.ranks.is_empty(): return false
	inventory.gold -= 100
	attack.cancel()
	abilities.reset()
	abilities.cooldowns.clear()
	statuses.reset()
	progression.ranks.clear()
	progression.changed.emit()
	for i in range(ActionLoadout.SIZE):
		if actions.slots[i].get("kind", "") == "ability": actions.clear(i)
	inventory.changed.emit()
	return true

func swing_seconds() -> float:
	var weapon_item: ItemDefinition = inventory.equipment.weapon
	var seconds := weapon_item.swing_seconds if weapon_item else 0.8
	return seconds / (1.2 if abilities and abilities.rampage_left > 0 else 1.0)

func use_potion() -> void:
	for item in inventory.items:
		if item.slot == "consumable" and item.heal_amount > 0:
			use_consumable(item.id)
			return
	feedback.emit("No Tonic in your pack.")

func use_consumable(id: StringName) -> void:
	for i in range(inventory.items.size()):
		if inventory.items[i].id == id:
			use_item(i)
			return
	feedback.emit("None left in your pack.")

func use_item(index: int) -> void:
	if dead or index < 0 or index >= inventory.items.size():
		return
	var item := inventory.items[index]
	if item.slot != "consumable":
		if inventory.equip(index): AudioLibrary.play_ui(get_parent(),"equip")
		return
	if potion_recovery.remaining > 0:
		feedback.emit("A Tonic is already restoring vitality.")
		return
	if not potion_recovery.start(item.heal_amount, item.heal_seconds):
		feedback.emit("Your vitality is already full.")
		return
	inventory.items.remove_at(index)
	inventory.changed.emit()
	feedback.emit("%s · Restoring vitality over %.0f seconds." % [item.display_name, item.heal_seconds])
	AudioLibrary.play_ui(get_parent(),"potion")

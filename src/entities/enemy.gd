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
var retreat_left: float = 0.0
var stand_left: float = 0.0
var retreat_destination: Vector3
var commander: CommanderCombat
var statuses: StatusEffects
var brute: BruteCombat
var den_combat: DenBossCombat
var dormant: bool = false
var corpse_consumed: bool = false
var web_attack: WebAttack
var risen_combat: RisenCombat
var charge_combat: ChargeCombat
var damage_gate: Callable

func _ready() -> void:
	add_to_group("enemies")
	statuses = StatusEffects.new()
	add_child(statuses)
	home = global_position
	# Recast places walkable surfaces above the collision floor by a voxel.
	# Compare feet to the adjusted path, keeping the tight corner tolerance.
	navigation.path_height_offset = NavigationServer3D.map_get_cell_height(navigation.get_navigation_map())
	var capsule := CapsuleShape3D.new()
	capsule.radius = definition.collision_radius
	capsule.height = definition.collision_height
	$Collision.shape = capsule
	$Collision.position.y = definition.collision_height * 0.5
	orbit_sign = 1 if hash(spawn_id) % 2 == 0 else -1
	health.configure(definition.max_health if health_override < 0 else health_override, definition.armor)
	attack.definition = definition.attack
	attack.damage_override = damage_override
	attack.target_group = &"player"
	attack.hit_chance = definition.hit_chance
	# All enemy attacks retain a one-damage floor, including future types/arrows.
	attack.minimum_damage = 1.0
	attack.missed.connect(func(victim: Node3D):
		var label := FloatingText.spawn(get_parent(), victim.global_position + Vector3.UP * 2, 0)
		label.text = "Miss"
		label.modulate = Color("b4b6aa"))
	visual.style = definition.behavior
	if definition.commander: visual.style = "commander"
	if definition.brute: visual.style = "brutus"
	if not definition.appearance.is_empty(): visual.style = definition.appearance
	visual.scale = Vector3.ONE * definition.visual_scale
	visual.tint = definition.tint
	visual.rebuild()
	attack.started.connect(visual.attack_started)
	health.died.connect(_die)
	health.damaged.connect(_damaged)
	health_label = Geometry.label(self, definition.display_name, Vector3(0, maxf(2.3,definition.collision_height+0.7), 0), Color("e6c6ac"), 25)
	health_label.visible = false
	target = get_tree().get_first_node_in_group("player") as Player
	if definition.commander:
		commander = CommanderCombat.new()
		commander.actor = self
		add_child(commander)
	if definition.brute:
		brute = BruteCombat.new()
		brute.actor = self
		add_child(brute)
	if definition.den_boss:
		den_combat = DenBossCombat.new()
		den_combat.actor = self
		add_child(den_combat)
	if definition.web_cooldown > 0:
		web_attack = WebAttack.new()
		web_attack.actor = self
		add_child(web_attack)
	if definition.risen:
		risen_combat = RisenCombat.new()
		risen_combat.actor = self
		add_child(risen_combat)
	if definition.charge:
		charge_combat = ChargeCombat.new()
		charge_combat.actor = self
		add_child(charge_combat)

func _physics_process(delta: float) -> void:
	if definition.passive: return
	if dormant or health.current <= 0 or not is_instance_valid(target):
		return
	if statuses.has("stun"):
		if charge_combat: charge_combat.cancel()
		velocity = Vector3.ZERO
		visual.moving = false
		return
	stand_left = maxf(0, stand_left - delta)
	retreat_left = maxf(0, retreat_left - delta)
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
	health_label.visible = aggro and target.attack_target == self
	health_label.text = "%s  %d / %d" % [definition.display_name, health.current, health.maximum]
	if den_combat and den_combat.step(delta):
		return
	if web_attack and web_attack.step(delta):
		velocity = Vector3.ZERO
		visual.moving = false
		return
	if brute and brute.step(delta):
		velocity = Vector3(0,-2,0)
		move_and_slide()
		visual.moving = false
		return
	if commander and commander.step(delta):
		velocity = Vector3(0, -2, 0)
		move_and_slide()
		visual.moving = false
		return
	if charge_combat and charge_combat.step(delta): return
	var destination := home
	var wants_move := false
	if returning:
		retreat_left = 0
		stand_left = 0
		wants_move = true
		if global_position.distance_to(home) < 1.2:
			returning = false
			health.heal(health.maximum)
	elif aggro:
		_face(offset)
		var sight := _has_sight(target.global_position)
		match definition.behavior:
			"archer":
				if distance < definition.preferred_range - 1.2 and retreat_left <= 0 and stand_left <= 0 and not attack.pending:
					retreat_left = definition.retreat_seconds
					stand_left = definition.retreat_seconds + definition.stand_seconds
					retreat_destination = global_position - offset.normalized() * 4
					repath = 0
				if retreat_left > 0:
					destination = retreat_destination
					wants_move = true
				elif stand_left <= 0 and (distance > definition.attack.reach or not sight):
					destination = target.global_position
					wants_move = true
				elif not attack.pending and sight and distance <= definition.attack.reach:
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
		velocity = step.normalized() * definition.move_speed * statuses.movement_factor()
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
	if returning or dormant:
		return
	aggro = true
	if statuses.immune(str(packet.damage_type)): return
	var before := health.current
	if is_instance_valid(packet.source) and packet.source is Player:
		packet.source.resolve_critical(packet)
	if damage_gate.is_valid(): damage_gate.call(packet)
	health.receive(packet)
	var dealt := before - health.current
	if is_instance_valid(packet.source) and packet.source is Player:
		packet.source.abilities.damage_dealt(dealt)
	if health.current > 0 and packet.stun_seconds > 0 and not definition.is_boss:
		statuses.apply("stun",packet.stun_seconds)
		attack.cancel()
		if commander: commander.cancel()

func _damaged(amount: float) -> void:
	visual.hit()
	FloatingText.spawn(get_parent(), global_position + Vector3.UP * 2, amount, health.last_critical)

func _die() -> void:
	if charge_combat: charge_combat.cancel()
	attack.cancel()
	if commander: commander.cancel()
	if brute: brute.cancel()
	if den_combat: den_combat.cancel()
	statuses.reset()
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	health_label.visible = false
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(visual, "rotation:z", PI * 0.5, 0.25)
	if definition.edible_corpse:
		add_to_group("wolf_corpses")
		visual.moving = false
		return
	tween.tween_interval(1.5)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.5)
	tween.tween_callback(queue_free)

func consume_corpse() -> void:
	corpse_consumed = true
	remove_from_group("wolf_corpses")
	var tween := create_tween()
	tween.tween_property(visual,"scale",Vector3.ONE * 0.05,0.6)
	tween.tween_callback(queue_free)

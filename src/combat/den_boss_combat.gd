class_name DenBossCombat
extends Node
var actor: Enemy
var encounter: DenEncounter
var releasing: bool = false
var fire_left: float = 6
var fury_left: float = 0
var fury_cooldown: float = 9
var fury_hit: bool = false
var lunge_cooldown: float = 7
var lunge_left: float = 0
var lunge_direction := Vector3.ZERO
var lunge_hit: bool = false
var feed_left: float = 0
var feed_tick: float = 1
var corpse: Enemy
var howl_count: int = 0
var pending_howls: int = 0
var warning_left: float = 0
var warning_kind: String = ""
var warning: Node3D
var fire_point := Vector3.ZERO
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	rng.randomize()
	actor.health.damaged.connect(_damaged)
func _damaged(_amount: float) -> void:
	if actor.definition.den_boss.role!="bloodfang" or actor.health.current<=0: return
	var thresholds := actor.definition.den_boss.howl_thresholds
	while howl_count < thresholds.size() and actor.health.current <= actor.health.maximum*thresholds[howl_count]:
		howl_count += 1
		pending_howls += 1
func step(delta: float) -> bool:
	var kit := actor.definition.den_boss
	if actor.returning or not actor.aggro or actor.target.dead:
		cancel()
		return false
	if releasing:
		var destination := encounter.cage.global_position+Vector3(0,0,3.7)
		_move_to(destination,kit.sprint_speed)
		if actor.global_position.distance_to(destination) < 1.1:
			releasing = false
			encounter.release()
			actor.attack.remaining = 0.6
		return true
	fire_left -= delta
	fury_cooldown -= delta
	lunge_cooldown -= delta
	if warning_left > 0:
		warning_left = maxf(0,warning_left-delta)
		actor.velocity = Vector3(0,-2,0)
		actor.move_and_slide()
		actor.visual.moving = false
		if warning_left<=0: _resolve_warning()
		return true
	if kit.role=="garrick":
		if fire_left<=0 and not actor.attack.pending:
			_start_fire()
			return true
		return false
	if feed_left > 0:
		var elapsed := minf(delta,feed_left)
		feed_left -= elapsed
		feed_tick -= elapsed
		actor.visual.feeding = true
		actor.visual.moving = false
		actor.velocity = Vector3(0,-2,0)
		actor.move_and_slide()
		while feed_tick <= 0.00001:
			feed_tick += 1
			actor.health.heal(kit.feeding_heal)
			AudioLibrary.play_world(actor,actor.global_position,"bloodfang_feed",0.72)
			_pulse(Color("7aaf72"),1.1)
		if feed_left<=0:
			actor.visual.feeding = false
			if is_instance_valid(corpse): corpse.consume_corpse()
		return true
	# Only consume corpses underfoot; never seek one out or heal through a wall.
	if fury_left<=0 and lunge_left<=0:
		for dead_wolf: Enemy in get_tree().get_nodes_in_group("wolf_corpses"):
			if not dead_wolf.corpse_consumed and actor.global_position.distance_to(dead_wolf.global_position)<1.8 and actor._has_sight(dead_wolf.global_position):
				corpse = dead_wolf
				corpse.corpse_consumed = true
				corpse.remove_from_group("wolf_corpses")
				feed_left = kit.feeding_seconds
				feed_tick = 1
				actor.attack.cancel()
				actor.visual.feeding = true
				return true
	if fury_left > 0:
		fury_left = maxf(0,fury_left-delta)
		actor.visual.raging = true
		actor.visual.attack_started(Vector3.FORWARD,0.1)
		_move_to(actor.target.global_position,actor.definition.move_speed*1.2)
		if not fury_hit and actor.global_position.distance_to(actor.target.global_position)<=kit.fury_radius and actor._has_sight(actor.target.global_position):
			var packet := DamagePacket.new(0,actor,&"bleed")
			packet.bleed_damage = kit.fury_bleed_damage
			packet.bleed_ticks = kit.fury_bleed_ticks
			actor.target.receive_damage(packet)
			fury_hit = true
			AudioLibrary.play_world(actor,actor.global_position,"wolf_bite",0.65)
		if fury_left<=0:
			actor.visual.raging = false
			actor.attack.remaining = 0.8
		return true
	if lunge_left>0:
		lunge_left = maxf(0,lunge_left-delta)
		actor.velocity = lunge_direction*kit.lunge_speed
		actor.velocity.y = -2
		actor.move_and_slide()
		actor.visual.moving = true
		if not lunge_hit and actor.global_position.distance_to(actor.target.global_position)<2.1 and actor._has_sight(actor.target.global_position):
			var packet := DamagePacket.new(actor.definition.attack.damage,actor,&"melee",1)
			packet.accuracy = 1
			packet.knockback = kit.lunge_knockback
			actor.target.receive_damage(packet)
			lunge_hit = true
			AudioLibrary.play_world(actor,actor.global_position,"wolf_bite",0.7)
		if lunge_left<=0: actor.attack.remaining=0.9
		return true
	if pending_howls>0:
		pending_howls -= 1
		_begin_warning("howl",1.1,3.4,Color("c8c5aa"))
		AudioLibrary.play_world(actor,actor.global_position,"bloodfang_howl",0.67)
		return true
	if not actor.attack.pending and fury_cooldown<=0:
		fury_cooldown = kit.fury_cooldown
		fury_hit = false
		_begin_warning("fury",kit.fury_windup,kit.fury_radius,Color("b6382c"))
		AudioLibrary.play_world(actor,actor.global_position,"bloodfang_fury",0.64)
		return true
	var distance := actor.global_position.distance_to(actor.target.global_position)
	if not actor.attack.pending and lunge_cooldown<=0 and distance>3.2 and distance<9 and actor._has_sight(actor.target.global_position):
		lunge_direction = (actor.target.global_position-actor.global_position).normalized()
		lunge_direction.y = 0
		actor._face(lunge_direction)
		_begin_warning("lunge",0.65,1.3,Color("d1ad81"))
		lunge_cooldown = rng.randf_range(kit.lunge_cooldown.x,kit.lunge_cooldown.y)
		AudioLibrary.play_world(actor,actor.global_position,"wolf_growl",0.65)
		return true
	return false
func _move_to(point: Vector3, speed: float) -> void:
	actor.navigation.target_position = point
	var direction := actor.navigation.get_next_path_position()-actor.global_position
	direction.y = 0
	actor._face(direction)
	actor.velocity = direction.normalized()*speed
	actor.velocity.y = -2
	actor.move_and_slide()
	actor.visual.moving = true
func _begin_warning(kind: String, seconds: float, radius: float, color: Color) -> void:
	warning_kind = kind
	warning_left = seconds
	actor.attack.cancel()
	actor.visual.special_started(kind,seconds)
	warning = Geometry.ring(actor,radius,color,0.05)
func _start_fire() -> void:
	var kit := actor.definition.den_boss
	var direction := actor.target.global_position-actor.global_position
	direction.y=0
	if direction.length_squared()<0.01: direction=Vector3.FORWARD
	fire_point = actor.global_position+direction.normalized()*2.8
	fire_point = NavigationServer3D.map_get_closest_point(actor.navigation.get_navigation_map(),fire_point)
	fire_point.y=0
	_begin_warning("fire",0.85,kit.fire_radius,Color("c37639"))
	warning.top_level = true
	warning.global_position = fire_point+Vector3.UP*0.08
	fire_left = rng.randf_range(kit.fire_cooldown.x,kit.fire_cooldown.y)
	AudioLibrary.play_world(actor,actor.global_position,"torch_cast",0.85)
func _resolve_warning() -> void:
	if is_instance_valid(warning): warning.queue_free()
	warning = null
	var kit := actor.definition.den_boss
	match warning_kind:
		"fire":
			var torch := TorchThrow.new()
			torch.kit=kit
			torch.origin=actor.visual.carried_torch.global_position+Vector3.UP*0.7
			torch.destination=fire_point
			encounter.region.actors.add_child(torch)
			torch.global_position=torch.origin
		"howl":
			if encounter: encounter.summon_wave(howl_count-pending_howls,kit.summoned_enemy)
		"fury":
			fury_left = kit.fury_duration
		"lunge":
			lunge_left = kit.lunge_seconds
			lunge_hit = false
	warning_kind = ""
func _pulse(color: Color, radius: float) -> void:
	var ring := Geometry.ring(actor,radius,color,0.06)
	var tween := ring.create_tween()
	tween.tween_property(ring,"scale",Vector3.ONE*1.4,0.45)
	tween.tween_callback(ring.queue_free)
func cancel() -> void:
	warning_left = 0
	fury_left = 0
	lunge_left = 0
	feed_left = 0
	actor.visual.raging = false
	actor.visual.feeding = false
	if is_instance_valid(corpse) and corpse.corpse_consumed: corpse.consume_corpse()
	corpse = null
	if is_instance_valid(warning): warning.queue_free()
	warning = null

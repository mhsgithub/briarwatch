class_name PlayerAbilities
extends Node
## Learned talent execution; ordinary attacks still resolve in AttackComponent.
var player: Player
var cooldowns: Dictionary = {}
var rampage_left: float = 0
var storm_left: float = 0
var storm_tick: float = 0
var impale_left: float = 0
var retaliate_left: float = 0
var block_window: float = 0
var leap_left: float = 0
var leap_direction := Vector3.FORWARD
var push_velocity := Vector3.ZERO
var breath_tick: float = 0
var spin_left: float = 0
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	rng.randomize()
	player.attack.started.connect(_swing)
	player.attack.resolved.connect(func():
		player.attack.swing_multiplier = 1
		player.attack.swing_stun = 0)
func _swing(_direction: Vector3, _duration: float) -> void:
	player.attack.swing_multiplier = (1.0 + player.progression.rank("retaliate") * 0.5) if retaliate_left > 0 else 1.0
	player.attack.swing_stun = 3.0 if impale_left > 0 else 0.0
	retaliate_left = 0
	impale_left = 0
func remaining(id: String) -> float:
	return float(cooldowns.get(id,0))
func ready_reason(id: String) -> String:
	if player.cinematic_locked: return "You cannot act during the encounter."
	if player.dead: return "You cannot act while fallen."
	if player.progression.rank(id) == 0: return "Learn this talent first."
	if player.combat_state and player.combat_state.knockdown_left > 0 or player.statuses.has("stun"): return "You are stunned."
	if player.attack.pending: return "Finish your swing first."
	if leap_left > 0: return "Finish your leap first."
	if id == "leap" and player.statuses.has("root"): return "You are rooted. Use Unshackled first."
	if remaining(id) > 0: return "Recovering: %.1f seconds." % remaining(id)
	if id == "retaliate" and block_window <= 0: return "Block a melee attack first."
	if id in ["leap","whirlwind","bladestorm"] and storm_left > 0: return "Bladestorm is already active."
	return ""
func activate(id: String) -> bool:
	var data := CenturionTalents.find(id)
	if data.is_empty() or not data.active: return false
	var reason := ready_reason(id)
	if not reason.is_empty():
		player.feedback.emit(reason)
		return false
	cooldowns[id] = float(data.cooldown)
	match id:
		"whirlwind":
			area_hit(2.0)
			spin_left = 0.55
			flash(3.0,Color("c2b597"))
			sound("swing",0.78)
		"impale":
			impale_left = 10
			flash(0.85,Color("e3be69"))
			sound("equip")
		"retaliate":
			block_window = 0
			retaliate_left = 10
			flash(0.9,Color("eca66b"))
			sound("equip",0.85)
		"rampage":
			rampage_left = 10
			flash(1.0,Color("b83a29"))
			sound("boss_roar",1.18)
		"bladestorm":
			storm_left = 6
			storm_tick = 1
			player.statuses.control_immune = true
			player.statuses.effects.erase("stun")
			player.statuses.cleanse_movement()
			push_velocity = Vector3.ZERO
			sound("swing",0.7)
		"leap":
			leap_left = 0.5
			leap_direction = player.facing
			player.click_moving = false
			sound("swing",0.85)
		"unshackled":
			player.statuses.cleanse_movement()
			push_velocity = Vector3.ZERO
			flash(0.9,Color("b5d9d0"))
			sound("equip",0.7)
		"elemental_resolve":
			player.statuses.ward(["poison","fire","frost"],player.progression.rank(id)*3.0)
			flash(1.1,Color("87b6d4"))
			sound("potion",0.85)
	player.combat_state.engage()
	return true
func damage_dealt(amount: float) -> void:
	if amount > 0 and not player.dead:
		player.health.heal(amount * player.progression.rank("bloodthirst") * 0.01)
		for item: ItemDefinition in player.inventory.equipment.values():
			if item and item.life_steal_chance > 0 and rng.randf() < item.life_steal_chance:
				player.health.heal(item.life_steal_amount)
				flash(0.55,Color("8974b0"))
				sound("reliquary_siphon",1.0)
func movement_multiplier() -> float:
	var bonus := player.progression.rank("momentum") * 0.03 + player.inventory.bonus("movement_bonus") / 100.0
	if rampage_left > 0: bonus += 0.2
	if player.progression.rank("blood_and_breath") > 0 and player.health.current > player.health.maximum*0.8: bonus += 0.2
	return 1.0+bonus
func block_chance() -> float:
	var shield: ItemDefinition = player.inventory.equipment.get("shield")
	return player.progression.rank("block") * 0.02 * (2 if shield and shield.slot == "shield" else 1)
func accept_hit(packet: DamagePacket) -> bool:
	if player.statuses.immune(str(packet.damage_type)): return false
	if packet.accuracy >= 0:
		var accuracy := clampf(packet.accuracy-player.progression.rank("fleetfooted")*0.03,0,1)
		if rng.randf() >= accuracy:
			floating("Evade" if packet.attack_kind == &"ranged" else "Miss")
			return false
	if packet.damage_type in [&"physical",&"melee"] and packet.attack_kind == &"melee" and rng.randf() < block_chance():
		block_window = 5
		floating("Block")
		flash(0.65,Color("cab786"))
		sound("equip",0.8)
		player.combat_state.engage()
		return false
	packet.taken_multiplier = 1.1 if rampage_left > 0 else 1.0
	return true
func area_hit(multiplier: float) -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.health.current <= 0 or enemy.global_position.distance_to(player.global_position) > 3.0: continue
		var ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,enemy.global_position+Vector3.UP,1)
		if not player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		enemy.receive_damage(DamagePacket.new(player.melee_damage()*multiplier,player))
func move_leap(delta: float) -> bool:
	if leap_left <= 0 or player.dead: return false
	var step := minf(delta,leap_left)
	leap_left = maxf(0,leap_left-delta)
	# Swept CharacterBody collision, never teleport through closed geometry.
	var collision := player.move_and_collide(leap_direction * 20.0 * step)
	if collision: leap_left = 0
	player.visual.position.y = sin((1-leap_left/0.5)*PI)*1.8 if leap_left > 0 else 0.0
	if leap_left <= 0:
		flash(1.0,Color("a79d7a"))
		sound("impact",0.8)
	return true
func _physics_process(delta: float) -> void:
	for id: String in cooldowns: cooldowns[id] = maxf(0,float(cooldowns[id])-delta)
	if player.dead: return
	rampage_left = maxf(0,rampage_left-delta)
	impale_left = maxf(0,impale_left-delta)
	retaliate_left = maxf(0,retaliate_left-delta)
	block_window = maxf(0,block_window-delta)
	push_velocity = push_velocity.move_toward(Vector3.ZERO,delta*24)
	if storm_left > 0:
		var elapsed := minf(delta,storm_left)
		storm_left = maxf(0,storm_left-delta)
		storm_tick -= elapsed
		while storm_tick <= 0.00001:
			storm_tick += 1
			area_hit(1.0)
			flash(3,Color("bfc9bd"))
			sound("swing",0.8)
		spin_left = 0.1
		if storm_left <= 0: player.statuses.control_immune = false
	spin_left = maxf(0,spin_left-delta)
	if is_instance_valid(player.visual.pivot):
		if spin_left > 0: player.visual.pivot.rotation.y += delta*TAU*2.5
		else: player.visual.pivot.rotation.y = 0
	if player.progression.rank("blood_and_breath") > 0 and player.health.current < player.health.maximum*0.2:
		breath_tick += delta
		while breath_tick >= 1:
			breath_tick -= 1
			player.health.heal(player.health.maximum*0.01)
	else: breath_tick = 0
func reset() -> void:
	rampage_left = 0
	storm_left = 0
	impale_left = 0
	retaliate_left = 0
	block_window = 0
	leap_left = 0
	spin_left = 0
	push_velocity = Vector3.ZERO
	player.visual.position.y = 0
	player.attack.swing_multiplier = 1
	player.attack.swing_stun = 0
func sound(cue: String, pitch: float = 1) -> void:
	AudioLibrary.play_world(player,player.global_position,cue,pitch)
func floating(message: String) -> void:
	var label := FloatingText.spawn(player,player.global_position+Vector3.UP*2,0)
	label.top_level = true
	label.text = message
	label.modulate = Color("bacaab")
func flash(radius: float, color: Color) -> void:
	var ring := Geometry.ring(player,radius,color,0.035)
	ring.top_level = true
	ring.global_position = player.global_position+Vector3.UP*0.08
	var tween := ring.create_tween()
	tween.tween_property(ring,"scale",Vector3.ONE*1.15,0.35)
	tween.tween_callback(ring.queue_free)
func serialize() -> Dictionary:
	return cooldowns.duplicate()
func restore(data: Dictionary) -> void:
	cooldowns.clear()
	for id: String in data:
		var talent := CenturionTalents.find(id)
		if not talent.is_empty(): cooldowns[id] = clampf(float(data[id]),0,float(talent.cooldown))

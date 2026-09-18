class_name PlayerCombatState
extends Node
## Transient combat state: discrete resting recovery, bleed and short knockdown.
var player: Player
var combat_left: float = 0.0
var resting_time: float = 0.0
var bleed_left: int = 0
var bleed_tick: float = 0.0
var bleed_damage: float = 0.0
var knockdown_left: float = 0.0
var regeneration_enabled: bool = true

func _ready() -> void:
	player.attack.started.connect(func(_direction: Vector3, _duration: float): engage())
	player.health.damaged.connect(func(_amount: float): engage())

func engage() -> void:
	combat_left = 4.0
	resting_time = 0.0

func apply(packet: DamagePacket) -> void:
	if packet.bleed_ticks > 0:
		bleed_left = packet.bleed_ticks
		bleed_damage = packet.bleed_damage
		bleed_tick = 1.0
	if packet.knockdown_seconds > 0 and not player.statuses.control_immune:
		knockdown_left = maxf(knockdown_left, packet.knockdown_seconds)
		player.attack.cancel()
		player.click_moving = false
		player.attack_target = null
		player.interact_target = null
	engage()

func chased() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.aggro and not enemy.returning and enemy.target == player and enemy.health.current > 0:
			return true
	return false

func _physics_process(delta: float) -> void:
	if player.dead: return
	combat_left = maxf(0, combat_left - delta)
	if knockdown_left > 0:
		knockdown_left = maxf(0, knockdown_left - delta)
		player.visual.rotation.z = -1.2 if knockdown_left > 0 else 0.0
	if bleed_left > 0:
		bleed_tick -= delta
		while bleed_tick <= 0 and bleed_left > 0 and not player.dead:
			bleed_tick += 1.0
			bleed_left -= 1
			player.receive_damage(DamagePacket.new(bleed_damage, null, &"bleed"))
	if player.dead or not regeneration_enabled or combat_left > 0 or bleed_left > 0 or knockdown_left > 0 or chased() or player.health.current >= player.health.maximum:
		resting_time = 0.0
		return
	resting_time += delta
	while resting_time >= 2.0:
		resting_time -= 2.0
		player.health.heal(1.0)

func reset() -> void:
	combat_left = 0
	resting_time = 0
	bleed_left = 0
	knockdown_left = 0

class_name BruteCombat
extends Node
var actor: Enemy
var triggered: bool = false
var rage_left: float = 0
var tick_left: float = 0
var warning: MeshInstance3D
var rage_light: OmniLight3D
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	rng.randomize()
	actor.attack.knockback = actor.definition.brute.knockback_speed
	actor.health.damaged.connect(_damaged)
func _damaged(_amount: float) -> void:
	var kit := actor.definition.brute
	if triggered or actor.health.current <= 0 or actor.health.current > actor.health.maximum*kit.rage_threshold: return
	triggered = true
	rage_left = kit.rage_seconds
	tick_left = kit.rage_interval
	actor.attack.cancel()
	warning = Geometry.ring(actor,kit.rage_radius,Color("c04c2b"),0.07)
	AudioLibrary.play_world(actor,actor.global_position,"boss_roar",0.65)
	actor.visual.raging = true
	rage_light = OmniLight3D.new()
	rage_light.light_color = Color("df5035")
	rage_light.light_energy = 1.3
	rage_light.omni_range = 4.0
	rage_light.position.y = 1.2
	actor.add_child(rage_light)
func step(delta: float) -> bool:
	if actor.returning or not actor.aggro or actor.target.dead:
		cancel()
		if actor.health.current >= actor.health.maximum: triggered = false
		return false
	if rage_left <= 0: return false
	var kit := actor.definition.brute
	var elapsed := minf(delta,rage_left)
	rage_left = maxf(0,rage_left-delta)
	tick_left -= elapsed
	if is_instance_valid(warning):
		warning.scale = Vector3.ONE*(1.0+sin(rage_left*18)*0.025)
	if is_instance_valid(rage_light): rage_light.light_energy=1.2+sin(rage_left*15)*0.25
	while tick_left <= 0.00001:
		tick_left += kit.rage_interval
		actor.visual.attack_started(Vector3.FORWARD,0.12)
		AudioLibrary.play_world(actor,actor.global_position,"brutus_punch",0.8)
		var phase := rng.randf()*TAU
		for i in range(kit.knives_per_volley):
			var angle := phase+i*TAU/kit.knives_per_volley+rng.randf_range(-0.15,0.15)
			var knife := KnifeProjectile.new()
			knife.direction=Vector3(sin(angle),0,cos(angle))
			knife.speed=kit.knife_speed
			knife.packet=DamagePacket.new(kit.knife_damage,actor,&"ranged",1)
			knife.packet.attack_kind=&"ranged"
			knife.packet.accuracy=1
			actor.get_parent().add_child(knife)
			knife.global_position=actor.global_position+Vector3.UP*1.0+knife.direction*0.8
	if rage_left <= 0:
		cancel()
		actor.attack.remaining = 1.0
	return true
func cancel() -> void:
	rage_left = 0
	actor.visual.raging = false
	if is_instance_valid(warning): warning.queue_free()
	warning = null
	if is_instance_valid(rage_light): rage_light.queue_free()
	rage_light = null

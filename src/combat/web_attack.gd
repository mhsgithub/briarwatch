class_name WebAttack
extends Node
## A readable, dodgeable ranged control attack; normal pursuit remains Enemy-owned.
var actor: Enemy
var cooldown: float = 1.0
var windup: float = 0.0
var aim := Vector3.ZERO

func voice_pitch() -> float:
	return actor.definition.voice_pitch * (0.68 if actor.definition.id==&"broodqueen" else 1.0)

func step(delta: float) -> bool:
	cooldown = maxf(0, cooldown-delta)
	if not actor.aggro or actor.returning or actor.target.dead:
		windup = 0
		return false
	if windup > 0:
		windup -= delta
		if windup <= 0:
			var bolt := WebProjectile.new()
			bolt.source = actor
			bolt.root_seconds = actor.definition.web_root_seconds
			var origin := actor.global_position + Vector3.UP * 0.65
			bolt.direction = (aim-origin).normalized()
			actor.get_parent().add_child(bolt)
			bolt.global_position = origin + bolt.direction*0.8
			AudioLibrary.play_world(actor,origin,"spider_web_cast",voice_pitch())
		return true
	var distance := actor.global_position.distance_to(actor.target.global_position)
	if cooldown <= 0 and not actor.attack.pending and distance > 2.5 and distance < actor.definition.web_range and actor._has_sight(actor.target.global_position):
		windup = 0.8
		cooldown = actor.definition.web_cooldown + actor.attack.rng.randf_range(-1.5,1.5)
		aim = actor.target.global_position + Vector3.UP*0.65
		actor.visual.special_started("web",windup)
		AudioLibrary.play_world(actor,actor.global_position,"spider_web",voice_pitch())
		return true
	return false

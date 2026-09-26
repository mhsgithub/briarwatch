class_name ChargeCombat
extends Node
var actor: Enemy
var cooldown: float = 4
var warning: float = 0
var remaining: float = 0
var heading := Vector3.ZERO
var struck: bool = false
func step(delta: float) -> bool:
	var kit := actor.definition.charge
	cooldown = maxf(0,cooldown-delta)
	if not actor.aggro or actor.returning or actor.target.dead:
		cancel()
		return false
	if warning > 0:
		warning -= delta
		actor.visual.pivot.rotation.x = -0.35
		if warning <= 0:
			remaining = kit.duration
			AudioLibrary.play_world(actor,actor.global_position,"brute_charge")
		return true
	if remaining > 0:
		remaining -= delta
		actor.velocity = heading*kit.speed+Vector3.DOWN*2
		actor.move_and_slide()
		actor.visual.moving = true
		var offset := actor.target.global_position-actor.global_position
		if not struck and offset.length()<1.5 and actor._has_sight(actor.target.global_position):
			struck = true
			actor.target.statuses.apply("stun",kit.stun_seconds)
			actor.target.attack.cancel()
			AudioLibrary.play_world(actor,actor.global_position,"brute_charge_impact")
		if actor.is_on_wall() or struck: remaining = 0
		if remaining <= 0: cancel()
		return true
	var offset := actor.target.global_position-actor.global_position
	if cooldown <= 0 and not actor.attack.pending and offset.length()>=kit.minimum_range and offset.length()<=kit.maximum_range and actor._has_sight(actor.target.global_position):
		heading = offset.normalized()
		heading.y = 0
		warning = kit.windup
		actor.visual.special_started("charge",kit.windup)
		struck = false
		cooldown = randf_range(kit.cooldown.x,kit.cooldown.y)
		actor.attack.cancel()
		actor._face(heading)
		AudioLibrary.play_world(actor,actor.global_position,"brute_charge_warning")
		return true
	return false
func cancel() -> void:
	warning = 0
	remaining = 0
	actor.visual.pivot.rotation.x = 0
	actor.visual.special_left = 0
	actor.velocity = Vector3.ZERO

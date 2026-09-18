class_name StatusEffects
extends Node
## One actor-owned status store; elemental wards and movement immunity use the same path.
var effects: Dictionary = {}
var immunities: Dictionary = {}
var control_immune: bool = false
func apply(id: String, seconds: float, power: float = 1.0, element: String = "") -> bool:
	if element.is_empty() and id in ["poison","fire","frost"]: element=id
	if seconds <= 0 or (not element.is_empty() and immune(element)): return false
	if control_immune and id in ["stun","root","slow","knockback"]: return false
	effects[id] = {"remaining":seconds,"power":power,"element":element,"tick":0.0}
	return true
func immune(element: String) -> bool:
	return float(immunities.get(element,0)) > 0
func has(id: String) -> bool:
	return effects.has(id)
func cleanse_movement() -> void:
	for id in ["root","slow","knockback"]: effects.erase(id)
func ward(elements: Array, seconds: float) -> void:
	for element: String in elements: immunities[element] = seconds
	for id: String in effects.keys():
		if effects[id].element in elements: effects.erase(id)
func movement_factor() -> float:
	if has("root"): return 0.0
	return clampf(1.0-float(effects.slow.power),0,1) if has("slow") else 1.0
func reset() -> void:
	effects.clear()
	immunities.clear()
	control_immune = false
func _physics_process(delta: float) -> void:
	for element: String in immunities.keys():
		immunities[element] = maxf(0,float(immunities[element])-delta)
	for id: String in effects.keys():
		if not effects.has(id): continue
		var effect: Dictionary = effects[id]
		var elapsed := minf(delta,float(effect.remaining))
		effect.remaining -= delta
		if id in ["poison","fire","bleed"]:
			effect.tick += elapsed
			while effect.tick >= 1:
				effect.tick -= 1
				var packet := DamagePacket.new(float(effect.power),null,StringName(effect.element if not str(effect.element).is_empty() else id))
				get_parent().receive_damage(packet)
				if not effects.has(id): break
		if float(effect.remaining) <= 0: effects.erase(id)

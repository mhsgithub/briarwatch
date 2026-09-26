class_name RegionTravel
extends Node
## One active region; inactive regions retain only serializable state, never live AI.
signal changed(region: Region)
var scenes: Dictionary = {}
var states: Dictionary = {}
var active: Region
var player: Player
var exploration: Exploration
var catalog: ContentCatalog

func restore(saved: Dictionary) -> void:
	var stored: Variant = saved.get("regions", {})
	states = stored.duplicate(true) if stored is Dictionary else {}
	if not states.has("briar_march"):
		states["briar_march"] = {"defeated": saved.get("defeated", []), "loot": saved.get("loot", []), "exploration": saved.get("exploration", {})}

func state(id: String) -> Dictionary:
	var value: Variant = states.get(id, {})
	return value if value is Dictionary else {}

func world_state(id: String) -> Dictionary:
	var value: Variant = state(id).get("world",{})
	return value.duplicate(true) if value is Dictionary else {}

func snapshot() -> Dictionary:
	states[str(active.region_id)] = {"defeated": active.defeated_ids.duplicate(), "loot": serialize_loot(), "exploration": exploration.serialize(), "world": active.world_state.duplicate(true), "fires": serialize_fires(), "corruption":serialize_corruption()}
	return states.duplicate(true)

func enter(id: StringName, arrival: StringName = &"") -> bool:
	if player.cinematic_locked: return false
	if not scenes.has(str(id)) or active.region_id == id: return false
	var packed := load(scenes[str(id)]) as PackedScene
	if packed == null: return false
	var next := packed.instantiate() as Region
	if next == null: return false
	snapshot()
	player.attack.cancel()
	player.click_moving = false
	player.attack_target = null
	player.interact_target = null
	player.velocity = Vector3.ZERO
	var parent := active.get_parent()
	parent.remove_child(active)
	active.queue_free()
	active = next
	active.world_state = world_state(str(id))
	parent.add_child(active)
	var entry := active.get_node_or_null("Arrivals/" + str(arrival)) as Marker3D if not arrival.is_empty() else null
	player.global_position = entry.global_position if entry else active.player_spawn.global_position
	exploration.configure(active.map_bounds, player)
	exploration.restore(state(str(id)).get("exploration", {}))
	exploration.reveal(Vector2(player.position.x, player.position.z))
	changed.emit(active)
	var defeated: Variant = state(str(id)).get("defeated", [])
	active.initialize(defeated if defeated is Array else [])
	restore_loot(state(str(id)).get("loot", []))
	restore_fires(state(str(id)).get("fires", []))
	restore_corruption(state(str(id)).get("corruption", []))
	return true

func serialize_corruption() -> Array:
	var result: Array = []
	for child in active.actors.get_children():
		if child is CorruptionField and child.active: result.append(child.serialize())
	return result

func restore_corruption(data: Variant) -> void:
	if not data is Array: return
	for record in data:
		if not record is Dictionary or not record.get("points",null) is Array: continue
		var owner_id := str(record.get("owner",""))
		if owner_id in active.defeated_ids: continue
		var owner_actor: Enemy
		for child in active.actors.get_children():
			if child is Enemy and str(child.spawn_id) == owner_id and child.definition.risen: owner_actor = child
		if not owner_actor: continue
		var kit := owner_actor.definition.risen
		var field := CorruptionField.new()
		field.owner_id = owner_id
		field.radius = kit.pool_radius
		field.damage = kit.pool_damage
		field.interval = kit.pool_tick
		field.tick_left = clampf(float(record.get("tick",kit.pool_tick)),0.01,kit.pool_tick)
		active.actors.add_child(field)
		owner_actor.risen_combat.field = field
		for pair in record.points:
			if pair is Array and pair.size() == 2 and (pair[0] is float or pair[0] is int) and (pair[1] is float or pair[1] is int):
				var point := Vector2(float(pair[0]),float(pair[1]))
				if active.map_bounds.has_point(point): field.spread(Vector3(point.x,0,point.y))

func serialize_fires() -> Array:
	var result: Array = []
	for child in active.actors.get_children():
		if child is GroundFire and not child.is_queued_for_deletion():
			result.append({"x":child.position.x,"z":child.position.z,"remaining":child.remaining,"tick":child.tick_left,"radius":child.radius,"damage":child.damage,"interval":child.interval})
	return result

func restore_fires(data: Variant) -> void:
	if not data is Array: return
	for value in data.slice(0,32):
		if not value is Dictionary or float(value.get("remaining",0))<=0: continue
		var fire := GroundFire.new()
		fire.position=Vector3(clampf(float(value.get("x",0)),active.map_bounds.position.x,active.map_bounds.end.x),0,clampf(float(value.get("z",0)),active.map_bounds.position.y,active.map_bounds.end.y))
		fire.remaining=clampf(float(value.remaining),0,40)
		fire.radius=clampf(float(value.get("radius",2.7)),0.1,10)
		fire.damage=clampf(float(value.get("damage",20)),0,100)
		fire.interval=clampf(float(value.get("interval",0.5)),0.1,5)
		fire.tick_left=clampf(float(value.get("tick",fire.interval)),0.01,fire.interval)
		active.actors.add_child(fire)

func serialize_loot() -> Array:
	var result: Array = []
	for child in active.actors.get_children():
		if child is LootDrop and not child.taken:
			result.append({"item": str(child.item.id) if child.item else "", "gold": child.gold, "x": child.position.x, "z": child.position.z, "source":child.source_id})
	return result

func restore_loot(data: Variant) -> void:
	if not data is Array: return
	for entry in data.slice(0, 500):
		if not entry is Dictionary: continue
		var drop := LootDrop.new()
		drop.item = catalog.find_item(str(entry.get("item", "")))
		drop.gold = clampi(int(entry.get("gold", 0)), 0, 1000)
		drop.source_id = str(entry.get("source",""))
		if drop.item == null and drop.gold == 0:
			drop.free()
			continue
		active.actors.add_child(drop)
		drop.position = Vector3(clampf(float(entry.get("x", 0)), active.map_bounds.position.x + 2, active.map_bounds.end.x - 2), 0, clampf(float(entry.get("z", 0)), active.map_bounds.position.y + 2, active.map_bounds.end.y - 2))

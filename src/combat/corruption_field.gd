class_name CorruptionField
extends Node3D
## One ticking field per caster. Overlapping patches never multiply the tick.
var owner_id: String = ""
var points: Array[Vector3] = []
var radius: float = 1.65
var damage: float = 20.0
var interval: float = 0.5
var tick_left: float = 0.5
var active: bool = true
var material: ShaderMaterial

func _ready() -> void:
	add_to_group("corruption_fields")
	material = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/corruption.gdshader")

func spread(point: Vector3, spacing: float = 1.15) -> bool:
	point.y = 0.055
	for existing in points:
		if existing.distance_squared_to(point) < spacing*spacing: return false
	points.append(point)
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE*radius*2.15
	var mesh := MeshInstance3D.new()
	mesh.mesh = plane
	mesh.material_override = material
	mesh.position = point
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return true

func _physics_process(delta: float) -> void:
	if not active: return
	tick_left -= delta
	while tick_left <= 0.00001:
		tick_left += interval
		for player: Player in get_tree().get_nodes_in_group("player"):
			if player.dead or player.cinematic_locked: continue
			for point in points:
				var offset := player.global_position-point
				offset.y = 0
				if offset.length() > radius: continue
				var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP,player.global_position+Vector3.UP,1)
				if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
				var before := player.health.current
				player.receive_damage(DamagePacket.new(damage,null,&"corruption"))
				if player.health.current < before: AudioLibrary.play_world(player,player.global_position,"corruption_hurt")
				break

func clear() -> void:
	active = false
	points.clear()
	remove_from_group("corruption_fields")
	queue_free()

func serialize() -> Dictionary:
	var cells: Array = []
	for point in points: cells.append([point.x,point.z])
	return {"owner":owner_id,"points":cells,"tick":tick_left}

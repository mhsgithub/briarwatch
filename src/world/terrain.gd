@tool
extends Node3D
## Deterministic dressing batched in a MultiMesh; authored collision is unchanged.
@export var seed_value: int = 1847
@export var extent: Vector2 = Vector2(160, 144)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ground := PlaneMesh.new()
	ground.size = extent
	var ground_visual := Geometry.mesh_node(self, ground, Vector3.ZERO, Color.WHITE)
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://assets/shaders/ground.gdshader")
	ground_visual.material_override = ground_material
	ground_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geometry.collider(self, Vector3(0, -0.3, 0), Vector3(extent.x, 0.6, extent.y))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0, 1.05, 2.1]:
		var side := Vector3(cos(angle), 0, sin(angle)) * 0.19
		for vertex in [-side, side, Vector3(0.08, 0.55, 0.04)]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = surface.commit()
	mm.instance_count = int(extent.x * extent.y * 0.70)
	for i in range(mm.instance_count):
		var p := Vector3(rng.randf_range(-extent.x * 0.49, extent.x * 0.49), 0, rng.randf_range(-extent.y * 0.49, extent.y * 0.49))
		var scale_value := rng.randf_range(0.45, 1.25)
		if _on_road(p):
			scale_value = 0.0
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale_value), p))
		mm.set_instance_color(i, Color("3c5942").lerp(Color("8e8860"), rng.randf() * 0.7))
	var cover := MultiMeshInstance3D.new()
	cover.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/foliage.gdshader")
	cover.material_override = mat
	cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cover)
	for side in [-1, 1]:
		Geometry.collider(self, Vector3(side * extent.x * 0.5, 1, 0), Vector3(1, 3, extent.y))
		Geometry.collider(self, Vector3(0, 1, side * extent.y * 0.5), Vector3(extent.x, 3, 1))

func _on_road(point: Vector3) -> bool:
	for sibling in get_parent().get_children():
		if sibling.get_script() != preload("res://src/world/road.gd"):
			continue
		for i in range(sibling.points.size() - 1):
			var a: Vector3 = sibling.position + sibling.points[i]
			var b: Vector3 = sibling.position + sibling.points[i + 1]
			if Geometry3D.get_closest_point_to_segment(point, a, b).distance_to(point) < sibling.width * 0.52:
				return true
	return false

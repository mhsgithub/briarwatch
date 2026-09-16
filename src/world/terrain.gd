@tool
extends Node3D
## Deterministic decorative ground cover. Gameplay placement remains in the scene.
@export var seed_value: int = 1847
@export var extent: Vector2 = Vector2(160, 144)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ground := PlaneMesh.new()
	ground.size = extent
	var ground_visual := Geometry.mesh_node(self, ground, Vector3.ZERO, Color("475746"))
	ground_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geometry.collider(self, Vector3(0, -0.3, 0), Vector3(extent.x, 0.6, extent.y))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	var blade := PrismMesh.new()
	blade.size = Vector3(0.16, 0.22, 0.1)
	multimesh.mesh = blade
	multimesh.instance_count = 6500
	for i in range(multimesh.instance_count):
		var p := Vector3(rng.randf_range(-79, 79), 0.09, rng.randf_range(-71, 71))
		multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p))
		multimesh.set_instance_color(i, Color("708063").lerp(Color("3e5141"), rng.randf()))
	var cover := MultiMeshInstance3D.new()
	cover.multimesh = multimesh
	var mat := Geometry.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	cover.material_override = mat
	add_child(cover)
	# Physical border: wilderness fades to an impassable escarpment.
	for side in [-1, 1]:
		Geometry.collider(self, Vector3(side * 80, 1, 0), Vector3(1, 3, 144))
		Geometry.collider(self, Vector3(0, 1, side * 72), Vector3(160, 3, 1))

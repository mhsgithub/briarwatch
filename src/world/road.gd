@tool
extends MeshInstance3D

@export var points: PackedVector3Array = PackedVector3Array():
	set(value):
		points = value
		if is_inside_tree():
			build()
@export var width: float = 4.0:
	set(value):
		width = value
		if is_inside_tree():
			build()
@export var tint: Color = Color("8a8064")
@export var elevation: float = 0.04

func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	build()

func build() -> void:
	if points.size() < 2:
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var a := points[i] + Vector3.UP * elevation
		var b := points[i + 1] + Vector3.UP * elevation
		var side := (b - a).normalized().cross(Vector3.UP) * width * 0.5
		for vertex in [a - side, a + side, b + side, a - side, b + side, b - side]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	mesh = surface.commit()
	material_override = Geometry.material(tint)
	material_override.cull_mode = BaseMaterial3D.CULL_DISABLED

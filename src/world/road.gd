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
		var vertices := [a - side, a + side, b + side, a - side, b + side, b - side]
		var uvs := [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(1, 0)]
		for index in range(6):
			surface.set_uv(uvs[index])
			surface.add_vertex(vertices[index])
	surface.generate_normals()
	mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/ground.gdshader")
	material.set_shader_parameter("road", true)
	material.set_shader_parameter("paving", width > 10)
	material.set_shader_parameter("base_color", tint.darkened(0.18))
	material_override = material

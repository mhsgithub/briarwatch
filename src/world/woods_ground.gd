@tool
extends Node3D
@export var extent := Vector2(112,164)
func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = extent
	var mesh := Geometry.mesh_node(self,plane,Vector3(0,0,2),Color("263731"))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/ground.gdshader")
	mat.set_shader_parameter("base_color",Color("23322e"))
	mat.set_shader_parameter("terrain_tint",Color(0.65,0.80,0.86))
	mesh.material_override=mat
	Geometry.collider(self,Vector3(0,-0.3,2),Vector3(extent.x,0.6,extent.y))
	for side in [-1,1]:
		Geometry.collider(self,Vector3(side*extent.x*0.5,3,2),Vector3(1,6,extent.y))
		Geometry.collider(self,Vector3(0,3,2+side*extent.y*0.5),Vector3(extent.x,6,1))

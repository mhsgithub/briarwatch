@tool
extends Node3D
@export var extent := Vector2(288,256)
@export var seed_value: int = 72941
func _ready() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = extent
	var ground := Geometry.mesh_node(self,mesh,Vector3.ZERO,Color.WHITE)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/marsh_ground.gdshader")
	ground.material_override = mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ground_cover()
	Geometry.collider(self,Vector3(0,-0.3,0),Vector3(extent.x,0.6,extent.y))
	for side in [-1,1]:
		Geometry.collider(self,Vector3(side*extent.x*0.5,1,0),Vector3(1,3,extent.y))
		Geometry.collider(self,Vector3(0,1,side*extent.y*0.5),Vector3(extent.x,3,1))
	# Ground fog is decoration, never a collision surface or an NPC.
	for i in range(28):
		var plane := PlaneMesh.new()
		plane.size = Vector2(34,25)
		var fog := Geometry.mesh_node(self,plane,Vector3(-125+(i%7)*40,0.65+(i%3)*0.25,-97+(i/7)*59),Color.WHITE)
		var mist := ShaderMaterial.new()
		mist.shader = preload("res://assets/shaders/marsh_mist.gdshader")
		fog.material_override = mist
		fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _ground_cover() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0,1.05,2.1]:
		var side := Vector3(cos(angle),0,sin(angle))*0.14
		for v in [-side,side,Vector3(0.14,0.65,0.02)]: blade.add_vertex(v)
	blade.generate_normals()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade.commit()
	var points: Array[Vector3] = []
	for i in range(24000):
		var p := Vector3(rng.randf_range(-141,141),0,rng.randf_range(-125,125))
		if Rect2(-129,74,47,42).has_point(Vector2(p.x,p.z)): continue
		var clear := true
		for sibling in get_parent().get_children():
			if sibling is MarshWater and Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),sibling.shore):
				clear = false
				break
			if sibling.get_script() == preload("res://src/world/road.gd"):
				for j in range(sibling.points.size()-1):
					if Geometry3D.get_closest_point_to_segment(p,sibling.points[j],sibling.points[j+1]).distance_to(p)<sibling.width*0.55:
						clear = false
						break
		if clear: points.append(p)
	mm.instance_count = points.size()
	for i in range(points.size()):
		var size_value := rng.randf_range(0.35,1.4)
		mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*size_value),points[i]))
		mm.set_instance_color(i,Color("586448").lerp(Color("817658"),rng.randf()*0.55))
	var cover := MultiMeshInstance3D.new()
	cover.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/foliage.gdshader")
	cover.material_override = mat
	cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cover)

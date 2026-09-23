@tool
class_name MarshWater
extends Node3D
## Authored shore polygons. Bridge cutouts carve the same collision used by navigation.
@export var shore: PackedVector2Array
@export var crossings: Array[Rect2] = []
@export var deep: bool = true
func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(shore)
	for i in indices:
		surface.set_uv(shore[i]*0.1)
		surface.add_vertex(Vector3(shore[i].x,0.07,shore[i].y))
	surface.generate_normals()
	var visual := Geometry.mesh_node(self,surface.commit(),Vector3.ZERO,Color.WHITE)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/marsh_water.gdshader")
	visual.material_override = mat
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not deep: return
	var pieces: Array[PackedVector2Array] = [shore]
	for crossing in crossings:
		var cut := PackedVector2Array([crossing.position,Vector2(crossing.end.x,crossing.position.y),crossing.end,Vector2(crossing.position.x,crossing.end.y)])
		var next: Array[PackedVector2Array] = []
		for piece in pieces: next.append_array(Geometry2D.clip_polygons(piece,cut))
		pieces = next
	var body := StaticBody3D.new()
	add_child(body)
	for piece in pieces:
		for polygon in Geometry2D.decompose_polygon_in_convex(piece):
			var vertices := PackedVector3Array()
			for p in polygon:
				vertices.append(Vector3(p.x,-0.4,p.y))
				vertices.append(Vector3(p.x,3.0,p.y))
			var shape := ConvexPolygonShape3D.new()
			shape.points = vertices
			var collision := CollisionShape3D.new()
			collision.shape = shape
			body.add_child(collision)

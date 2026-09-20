@tool
class_name DarkThicket
extends Node3D
## Authored solid tree-wall segments; shared mesh + MultiMesh keeps the maze cheap.
@export var length: float = 10
@export var width: float = 3.6
@export var solid: bool = true
@export var seed_value: int = 1
static var tree_mesh: ArrayMesh
var fade_material: ShaderMaterial
var refresh_left: float = 0
func _ready() -> void:
	if tree_mesh==null: tree_mesh = _tree_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := maxi(1,int(ceil(length/1.7)))
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = tree_mesh
	batch.instance_count = count
	for i in range(count):
		var point := Vector3(-length*0.5+(i+0.5)*length/count,0,rng.randf_range(-width*0.22,width*0.22))
		var scale_value := rng.randf_range(0.78,1.12)
		var basis_value := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(scale_value,scale_value,scale_value))
		batch.set_instance_transform(i,Transform3D(basis_value,point))
	var visual := MultiMeshInstance3D.new()
	visual.multimesh=batch
	fade_material=ShaderMaterial.new()
	fade_material.shader=preload("res://assets/shaders/dark_wood.gdshader")
	visual.material_override=fade_material
	add_child(visual)
	if solid: Geometry.collider(self,Vector3(0,2.4,0),Vector3(length,4.8,width))
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	refresh_left-=delta
	if refresh_left>0: return
	refresh_left=0.1
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player: fade_material.set_shader_parameter("player_position",player.global_position)
static func _tree_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bark := Color("343c3b")
	var root := Vector3.ZERO
	var bend := Vector3(0.2,2.5,0.1)
	var crown := Vector3(-0.3,5.5,0)
	_limb(surface,root,bend,0.43,0.31,bark)
	_limb(surface,bend,crown,0.31,0.09,bark.lightened(0.035))
	for i in range(5):
		var a := i*TAU/5
		_limb(surface,Vector3(cos(a)*1.05,0.07,sin(a)*1.05),Vector3(0,0.65,0),0.09,0.28,bark)
		var start := Vector3(0.1,2.7+i*0.43,0)
		var elbow := start+Vector3(cos(a)*1.35,0.7,sin(a)*1.35)
		var end := elbow+Vector3(cos(a+0.4)*0.9,1.0,sin(a+0.4)*0.9)
		_limb(surface,start,elbow,0.20,0.12,bark)
		_limb(surface,elbow,end,0.12,0.015,bark.lightened(0.07))
		_limb(surface,elbow,elbow+Vector3(cos(a-0.7)*0.8,0.35,sin(a-0.7)*0.8),0.07,0.01,bark)
		var leaves := SphereMesh.new()
		leaves.radius=0.5
		leaves.height=1
		leaves.radial_segments=6
		leaves.rings=2
		_append(surface,leaves,Transform3D(Basis.IDENTITY.scaled(Vector3(1.35,0.5,0.85)),elbow+Vector3.UP*0.3),Color("233e36"))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.roughness=1
	surface.set_material(mat)
	return surface.commit()
static func _limb(surface: SurfaceTool, a: Vector3, b: Vector3, radius: float, top: float, color: Color) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.bottom_radius=radius
	cylinder.top_radius=top
	cylinder.height=a.distance_to(b)
	cylinder.radial_segments=6
	var axis := (b-a).normalized()
	var right := axis.cross(Vector3.FORWARD).normalized()
	if right.length_squared()<0.01: right=Vector3.RIGHT
	_append(surface,cylinder,Transform3D(Basis(right,axis,right.cross(axis).normalized()),(a+b)*0.5),color)
static func _append(surface: SurfaceTool, mesh: PrimitiveMesh, transform_value: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in range(indices.size()):
		var index := indices[i]
		surface.set_color(color)
		surface.set_normal((transform_value.basis*normals[index]).normalized())
		surface.add_vertex(transform_value*vertices[index])

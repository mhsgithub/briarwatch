@tool
class_name Geometry
extends RefCounted
## Small original art vocabulary. Generated visuals never own gameplay state.
static var materials: Dictionary = {}

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key := str(color) + ":" + str(glow)
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	materials[key] = mat
	return mat

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> MeshInstance3D:
	var node := box(parent, (a + b) * 0.5, Vector3(width, a.distance_to(b), width), color)
	var axis := (b - a).normalized()
	var right := axis.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	node.basis = Basis(right, axis, right.cross(axis).normalized())
	return node

static func ring(parent: Node3D, radius: float, color: Color, thickness: float = 0.035) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - thickness
	shape.outer_radius = radius + thickness
	shape.rings = 32
	shape.ring_segments = 6
	var node := mesh_node(parent, shape, Vector3(0, 0.055, 0), color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = pos
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh_node(parent, mesh, pos, color)

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1, sides: int = 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = sides
	return mesh_node(parent, mesh, pos, color)

static func sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var result := mesh_node(parent, mesh, pos, color)
	result.scale = size
	return result

static func collider(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)

static func label(parent: Node3D, text: String, pos: Vector3, color: Color = Color("ebddb9"), font_size: int = 32) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = font_size
	node.pixel_size = 0.012
	node.modulate = color
	node.outline_size = 6
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = true
	parent.add_child(node)
	node.position = pos
	return node

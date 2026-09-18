@tool
extends Node3D
## Native, editor-visible masonry and props. Cutaway walls preserve combat visibility.
const STONE := Color("536169")
const WOOD := Color("554336")

func _ready() -> void:
	var floor_mesh := Geometry.cylinder(self, Vector3(0, -0.25, 0), 13.9, 0.5, STONE, 13.9, 64)
	var floor_material := ShaderMaterial.new()
	floor_material.shader = preload("res://assets/shaders/tower_stone.gdshader")
	floor_mesh.material_override = floor_material
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	floor_body.position.y = -0.25
	var floor_shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 13.9
	cylinder.height = 0.5
	floor_shape.shape = cylinder
	floor_body.add_child(floor_shape)
	for i in range(36):
		var angle := i * TAU / 36
		var point := Vector3(sin(angle), 0, cos(angle)) * 13.35
		var wall := Node3D.new()
		add_child(wall)
		wall.position = point
		wall.rotation.y = angle
		Geometry.collider(wall, Vector3(0, 2.2, 0), Vector3(2.4, 4.4, 0.8))
		var rows := 1 if point.z > 3 or point.x > 9 else 5
		for row in range(rows):
			Geometry.box(wall, Vector3(0, 0.41 + row * 0.81, 0), Vector3(2.27, 0.76, 0.85), STONE.lightened(((i + row) % 4) * 0.018))
		Geometry.box(wall, Vector3(0, rows * 0.81 + 0.08, 0), Vector3(2.39, 0.16, 1.0), Color("77817e"))
		if i % 3 == 0 and rows > 1:
			Geometry.box(wall, Vector3(0, 1.7, -0.60), Vector3(0.48, 3.4, 0.5), Color("657075"))
	# A worn command rug leaves the perimeter free for dodging the axe.
	Geometry.box(self, Vector3(0, 0.026, -1), Vector3(5.1, 0.025, 9.4), Color("542e31"))
	for side in [-1, 1]:
		Geometry.box(self, Vector3(side * 2.34, 0.043, -1), Vector3(0.065, 0.01, 9.05), Color("9e8255"))
	for z in [-5.4, 3.4]:
		Geometry.box(self, Vector3(0, 0.043, z), Vector3(4.72, 0.01, 0.065), Color("9e8255"))
	for i in range(9):
		Geometry.box(self, Vector3(-2.1 + i * 0.52, 0.03, 3.82), Vector3(0.12, 0.02, 0.43 + (i % 3) * 0.11), Color("786344"))
	for p in [Vector3(-8.3, 0, -7.4), Vector3(8.3, 0, -7.4), Vector3(-9.8, 0, 5.4), Vector3(9.8, 0, 5.4)]:
		_brazier(p)
	for x in [-5.4, 0.0, 5.4]:
		_banner(Vector3(x, 3.1, -sqrt(12.7 * 12.7 - x * x)))
	# Arrow slits and cool skylight contrast with the warm braziers.
	for x in [-8.0, 8.0]:
		var slit := Geometry.box(self, Vector3(x, 2.75, -10.45), Vector3(0.30, 1.5, 0.10), Color("213a4b"))
		slit.material_override = Geometry.material(Color("486270"), 0.35)
		Geometry.beam(self, Vector3(x, 2.1, -10.35), Vector3(x, 3.4, -10.35), 0.06, Color("222a2c"))
	# Plunder, supply barrels, a campaign table and an empty command chair.
	for p in [Vector3(-10, 0, -2.2), Vector3(-10.7, 0, -0.7), Vector3(-9.7, 0, 0.9), Vector3(10.0, 0, 0)]:
		_barrel(p)
	var table := Node3D.new()
	add_child(table)
	table.position = Vector3(-5.9, 0, -8.5)
	table.rotation.y = -0.25
	Geometry.box(table, Vector3(0, 1.08, 0), Vector3(3.5, 0.18, 1.65), WOOD)
	for x in [-1.4, 1.4]:
		for z in [-0.55, 0.55]: Geometry.box(table, Vector3(x, 0.52, z), Vector3(0.18, 1.05, 0.18), WOOD.darkened(0.2))
	Geometry.collider(table, Vector3(0, 0.55, 0), Vector3(3.5, 1.1, 1.65))
	Geometry.box(table, Vector3(0.2, 1.19, 0), Vector3(1.9, 0.015, 1.2), Color("b4a47a"))
	for i in range(4): Geometry.box(table, Vector3(-0.5 + i * 0.4, 1.205, 0), Vector3(0.035, 0.01, 0.9), Color("756648"))
	Geometry.cylinder(table, Vector3(-1.23, 1.34, 0.2), 0.14, 0.33, Color("6a7170"))
	Geometry.box(self, Vector3(0, 0.6, -10.4), Vector3(1.4, 0.22, 1.25), WOOD)
	Geometry.box(self, Vector3(0, 1.25, -10.93), Vector3(1.4, 1.6, 0.18), WOOD)
	for x in [-0.58, 0.58]: Geometry.box(self, Vector3(x, 0.3, -10.4), Vector3(0.15, 0.6, 1.05), WOOD)
	Geometry.collider(self, Vector3(0, 0.9, -10.5), Vector3(1.5, 1.8, 1.5))
	for i in range(3):
		var crate := Vector3(6.8 + i * 1.15, 0.5, -8.7 + i * 0.65)
		Geometry.box(self, crate, Vector3(1, 1, 1), WOOD.lightened(i * 0.04))
		Geometry.box(self, crate + Vector3(0, 0, 0.51), Vector3(0.12, 1.02, 0.04), Color("8e7854"))
		Geometry.collider(self, crate, Vector3(1, 1, 1))

func _brazier(point: Vector3) -> void:
	Geometry.cylinder(self, point + Vector3(0, 0.18, 0), 0.62, 0.36, STONE, 0.52, 8)
	Geometry.cylinder(self, point + Vector3(0, 0.7, 0), 0.16, 0.95, Color("303a3b"), 0.19, 6)
	Geometry.cylinder(self, point + Vector3(0, 1.2, 0), 0.30, 0.38, Color("303a3b"), 0.62, 8)
	var fire := FireVisual.new()
	fire.position = point + Vector3(0, 1.36, 0)
	fire.flame_height = 0.85
	fire.light_energy = 1.6
	fire.light_range = 11.0
	add_child(fire)
	Geometry.collider(self, point + Vector3(0, 0.65, 0), Vector3(1, 1.3, 1))

func _barrel(point: Vector3) -> void:
	Geometry.cylinder(self, point + Vector3(0, 0.6, 0), 0.57, 1.2, WOOD, 0.52, 10)
	for y in [0.17, 1.0]: Geometry.cylinder(self, point + Vector3(0, y, 0), 0.58, 0.10, Color("343f40"), 0.58, 10)
	Geometry.collider(self, point + Vector3(0, 0.6, 0), Vector3(1.05, 1.2, 1.05))

func _banner(point: Vector3) -> void:
	Geometry.box(self, point, Vector3(1.5, 2.35, 0.06), Color("582c30"))
	Geometry.beam(self, point + Vector3(-0.93, 1.22, 0), point + Vector3(0.93, 1.22, 0), 0.08, Color("ad9160"))
	# An original angular crow device, cut from flat dark shapes.
	var bird := Geometry.box(self, point + Vector3(0, 0.08, 0.07), Vector3(0.75, 0.43, 0.025), Color("222c30"))
	bird.rotation.z = -0.35
	for side in [-1, 1]:
		var wing := Geometry.box(self, point + Vector3(side * 0.37, 0.35, 0.08), Vector3(0.28, 0.92, 0.025), Color("222c30"))
		wing.rotation.z = side * 0.55

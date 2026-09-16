@tool
class_name WorldProp
extends Node3D
## Native editor placement. Rebuild visual children on Inspector changes.
@export_enum("house", "tower", "tree", "rock", "tent", "fire", "fence", "well", "banner", "crate", "ruin") var kind: String = "tree":
	set(value):
		kind = value
		_refresh()
@export var tint: Color = Color("516347"):
	set(value):
		tint = value
		_refresh()
@export var variation: int = 0:
	set(value):
		variation = value
		_refresh()
@export var solid: bool = true:
	set(value):
		solid = value
		_refresh()
var scheduled: bool = false

func _ready() -> void:
	rebuild()

func _refresh() -> void:
	if is_inside_tree() and not scheduled:
		scheduled = true
		call_deferred("rebuild")

func rebuild() -> void:
	scheduled = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var timber := Color("4a3c2f")
	var stone := Color("787e71")
	match kind:
		"house":
			Geometry.box(self, Vector3(0, 1.5, 0), Vector3(5, 3, 4), Color("b2ab8e"))
			for x in [-2.4, 0, 2.4]:
				Geometry.box(self, Vector3(x, 1.55, -2.02), Vector3(0.2, 3.1, 0.14), timber)
			for y in [0.3, 2.8]:
				Geometry.box(self, Vector3(0, y, -2.08), Vector3(5.1, 0.16, 0.15), timber)
			for side in [-1, 1]:
				var roof := Geometry.box(self, Vector3(0, 3.72, side * 1.25), Vector3(5.8, 0.18, 3), tint)
				roof.rotation_degrees.x = side * 33
			Geometry.box(self, Vector3(1.45, 4.05, 0.9), Vector3(0.7, 2, 0.65), stone)
			Geometry.box(self, Vector3(0, 1, -2.11), Vector3(0.85, 2, 0.12), timber)
			for x in [-1.3, 1.3]:
				Geometry.box(self, Vector3(x, 1.8, -2.12), Vector3(0.6, 0.7, 0.1), Color("d7b56c"))
			if solid:
				Geometry.collider(self, Vector3(0, 1.5, 0), Vector3(5, 3, 4))
		"tower":
			Geometry.cylinder(self, Vector3(0, 3, 0), 2.6, 6, stone, 2.4, 8)
			for i in range(8):
				var a := i * TAU / 8
				Geometry.box(self, Vector3(cos(a) * 2.2, 6.35, sin(a) * 2.2), Vector3(0.95, 1.05, 0.95), stone)
			Geometry.box(self, Vector3(0, 1.3, -2.5), Vector3(1.1, 2.6, 0.2), timber)
			if solid:
				Geometry.collider(self, Vector3(0, 3, 0), Vector3(4.8, 6, 4.8))
		"tree":
			var size := 1.0 + (variation % 4) * 0.14
			Geometry.cylinder(self, Vector3(0, 1.3, 0), 0.27, 2.6, timber, 0.17)
			for i in range(3):
				Geometry.cylinder(self, Vector3(0, 2.5 + i * 0.85, 0), (1.65 - i * 0.35) * size, 2.4 * size, tint.lightened(i * 0.025), 0, 7)
			if solid:
				Geometry.collider(self, Vector3(0, 0.8, 0), Vector3(0.65, 1.6, 0.65))
		"rock":
			var rock := Geometry.sphere(self, Vector3(0, 0.55, 0), Vector3(2.4, 1.7, 1.8), tint)
			rock.rotation.y = variation * 1.7
			if solid:
				Geometry.collider(self, Vector3(0, 0.5, 0), Vector3(1.8, 1, 1.4))
		"tent":
			for side in [-1, 1]:
				var cloth := Geometry.box(self, Vector3(side * 0.85, 1.0, 0), Vector3(0.12, 2.65, 3.2), tint)
				cloth.rotation_degrees.z = side * 41
			Geometry.box(self, Vector3(0, 1.1, -1.55), Vector3(0.1, 2.2, 0.1), timber)
			if solid:
				Geometry.collider(self, Vector3(0, 0.7, 0), Vector3(2.8, 1.4, 3))
		"fire":
			for i in range(8):
				var a := i * TAU / 8
				Geometry.sphere(self, Vector3(cos(a) * 0.72, 0.14, sin(a) * 0.72), Vector3(0.45, 0.3, 0.35), stone)
			Geometry.box(self, Vector3(0, 0.15, 0), Vector3(1, 0.2, 0.2), timber)
			var flame := Geometry.cylinder(self, Vector3(0, 0.45, 0), 0.4, 0.9, Color("f2b35d"), 0, 5)
			flame.material_override = Geometry.material(Color("ffb85b"), 1.6)
			var light := OmniLight3D.new()
			light.light_color = Color("ffc180")
			light.light_energy = 1.1
			light.omni_range = 7
			add_child(light)
			light.position.y = 1.3
		"fence":
			for x in [-1.5, 1.5]:
				Geometry.box(self, Vector3(x, 0.7, 0), Vector3(0.22, 1.4, 0.22), timber)
			for y in [0.5, 1.1]:
				Geometry.box(self, Vector3(0, y, 0), Vector3(3.2, 0.15, 0.13), tint)
			if solid:
				Geometry.collider(self, Vector3(0, 0.6, 0), Vector3(3.2, 1.2, 0.25))
		"well":
			Geometry.cylinder(self, Vector3(0, 0.5, 0), 1.0, 1, stone)
			Geometry.cylinder(self, Vector3(0, 1.01, 0), 0.72, 0.02, Color("233a3a"))
			for x in [-0.9, 0.9]:
				Geometry.box(self, Vector3(x, 1.3, 0), Vector3(0.14, 2.5, 0.14), timber)
			Geometry.box(self, Vector3(0, 2.5, 0), Vector3(2.4, 0.2, 1.5), tint)
			if solid:
				Geometry.collider(self, Vector3(0, 0.6, 0), Vector3(1.8, 1.2, 1.8))
		"banner":
			Geometry.cylinder(self, Vector3(0, 1.6, 0), 0.08, 3.2, timber)
			Geometry.box(self, Vector3(0.5, 2.6, 0), Vector3(1, 1.1, 0.06), tint)
			Geometry.box(self, Vector3(0.5, 2.6, -0.04), Vector3(0.13, 0.7, 0.04), Color("d0b47b"))
		"crate":
			Geometry.box(self, Vector3(0, 0.45, 0), Vector3(1, 0.9, 1), tint)
			for y in [0.12, 0.76]:
				Geometry.box(self, Vector3(0, y, -0.51), Vector3(1.05, 0.1, 0.05), timber)
			if solid:
				Geometry.collider(self, Vector3(0, 0.45, 0), Vector3(1, 0.9, 1))
		"ruin":
			for i in range(4):
				Geometry.box(self, Vector3(i * 0.9 - 1.4, 0.6 + (i % 2) * 0.3, 0), Vector3(0.85, 1.2 + (i % 2) * 0.6, 0.9), stone)
			if solid:
				Geometry.collider(self, Vector3(0, 0.6, 0), Vector3(3.8, 1.2, 1))

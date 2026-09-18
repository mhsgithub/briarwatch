@tool
class_name WorldProp
extends Node3D
## Reusable art vocabulary. Colliders preserve the authored navigation contract.
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
const TIMBER := Color("302d29")
const STONE := Color("5e6a67")
const BRASS := Color("a28b58")

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
	match kind:
		"house": _house()
		"tree": _tree()
		"tower": _tower()
		"fire": _fire()
		"rock":
			var rock := Geometry.sphere(self,Vector3(0,0.53,0),Vector3(2.4,1.7,1.8),STONE)
			rock.rotation=Vector3(0.12,variation*1.7,0.15)
			Geometry.sphere(self,Vector3(0.45,0.20,0.55),Vector3(1.2,0.55,0.8),Color("455649"))
			_collision(Vector3(0,0.5,0),Vector3(1.8,1,1.4))
		"tent":
			for side in [-1,1]:
				var cloth := Geometry.box(self,Vector3(side*0.85,1.0,0),Vector3(0.12,2.65,3.2),Color("70614b") if variation%2==0 else Color("685045"))
				cloth.rotation_degrees.z=side*41
				Geometry.beam(self,Vector3(0,2.1,-1.62),Vector3(side*1.85,0,-1.72),0.075,TIMBER)
				Geometry.beam(self,Vector3(0,2.1,1.62),Vector3(side*1.85,0,1.72),0.075,TIMBER)
			Geometry.beam(self,Vector3(0,2.12,-1.85),Vector3(0,2.12,1.85),0.13,TIMBER)
			_collision(Vector3(0,0.7,0),Vector3(2.8,1.4,3))
		"fence":
			for x in [-1.5,1.5]:
				Geometry.box(self,Vector3(x,0.65,0),Vector3(0.24,1.3,0.24),TIMBER)
				Geometry.cylinder(self,Vector3(x,1.40,0),0.18,0.28,Color("70674c"),0,4)
			for y in [0.43,1.0]:
				Geometry.box(self,Vector3(0,y,0),Vector3(3.2,0.18,0.16),Color("5a5440"))
			_collision(Vector3(0,0.6,0),Vector3(3.2,1.2,0.25))
		"well":
			for row in range(3):
				for i in range(10):
					var a := (i+row*0.5)*TAU/10
					var brick := Geometry.box(self,Vector3(cos(a)*0.86,0.17+row*0.29,sin(a)*0.86),Vector3(0.55,0.27,0.34),STONE.lightened(float(i%3)*0.035))
					brick.rotation.y=-a+PI*0.5
			Geometry.cylinder(self,Vector3(0,0.30,0),0.72,0.04,Color("172a2b"))
			for x in [-0.98,0.98]:
				Geometry.box(self,Vector3(x,1.35,0),Vector3(0.18,2.7,0.18),TIMBER)
			Geometry.beam(self,Vector3(-1.2,2.28,0),Vector3(1.2,2.28,0),0.17,TIMBER)
			Geometry.beam(self,Vector3(0,2.3,0),Vector3(0,0.6,0),0.035,BRASS)
			for side in [-1,1]:
				var roof := Geometry.box(self,Vector3(0,2.73,side*0.45),Vector3(2.6,0.13,1.05),Color("354747"))
				roof.rotation.x=side*0.45
			_collision(Vector3(0,0.6,0),Vector3(1.8,1.2,1.8))
		"banner":
			Geometry.cylinder(self,Vector3(0,1.6,0),0.065,3.2,TIMBER)
			Geometry.cylinder(self,Vector3(0,3.32,0),0.14,0.35,BRASS,0,5)
			Geometry.box(self,Vector3(0.47,2.65,0),Vector3(1.05,0.065,0.09),BRASS)
			Geometry.box(self,Vector3(0.48,2.07,0),Vector3(0.89,1.17,0.06),tint.darkened(0.3))
			Geometry.box(self,Vector3(0.48,2.13,-0.042),Vector3(0.07,0.83,0.015),BRASS)
			Geometry.box(self,Vector3(0.48,2.29,-0.042),Vector3(0.43,0.06,0.015),BRASS)
		"crate":
			Geometry.box(self,Vector3(0,0.45,0),Vector3(1,0.9,1),Color("65513a"))
			for x in [-0.32,0,0.32]:
				Geometry.box(self,Vector3(x,0.45,-0.51),Vector3(0.025,0.86,0.025),TIMBER)
			for y in [0.10,0.78]:
				Geometry.box(self,Vector3(0,y,-0.53),Vector3(1.06,0.09,0.055),Color("363e3b"))
			Geometry.beam(self,Vector3(-0.42,0.14,-0.56),Vector3(0.42,0.74,-0.56),0.11,TIMBER)
			_collision(Vector3(0,0.45,0),Vector3(1,0.9,1))
		"ruin":
			for column in range(4):
				for row in range(2+column%2):
					Geometry.box(self,Vector3(column*0.9-1.4,row*0.49+0.24,0),Vector3(0.85,0.45,0.9),STONE.lightened(row*0.045))
			_collision(Vector3(0,0.6,0),Vector3(3.8,1.2,1))

	if not Engine.is_editor_hint() and kind in ["tree","house","tower","tent","rock","ruin","well"]:
		var fade := ProximityFade.new()
		add_child(fade)

func _collision(point: Vector3, dimensions: Vector3) -> void:
	if solid:
		Geometry.collider(self,point,dimensions)

func _house() -> void:
	Geometry.box(self,Vector3(0,1.5,0),Vector3(5,3,4),Color("817c68"))
	Geometry.box(self,Vector3(0,0.26,0),Vector3(5.16,0.52,4.16),STONE)
	for z in [-2.05,2.05]:
		for x in [-2.42,0,2.42]:
			Geometry.box(self,Vector3(x,1.7,z),Vector3(0.22,2.7,0.20),TIMBER)
		for y in [0.55,2.85]:
			Geometry.box(self,Vector3(0,y,z),Vector3(5.15,0.19,0.2),TIMBER)
		for side in [-1,1]:
			Geometry.beam(self,Vector3(side*0.15,0.7,z),Vector3(side*2.3,2.75,z),0.13,TIMBER)
		# Gable infill and rafters.
		var face := SurfaceTool.new()
		face.begin(Mesh.PRIMITIVE_TRIANGLES)
		for vertex in [Vector3(-2.5,2.9,z),Vector3(2.5,2.9,z),Vector3(0,5.05,z)]:
			face.add_vertex(vertex)
		face.generate_normals()
		var wall := Geometry.mesh_node(self,face.commit(),Vector3.ZERO,Color("817c68"))
		var mat := Geometry.material(Color("817c68")).duplicate() as StandardMaterial3D
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		wall.material_override=mat
		Geometry.beam(self,Vector3(0,2.9,z),Vector3(0,5.03,z),0.17,TIMBER)
		for side in [-1,1]:
			Geometry.beam(self,Vector3(0,5.07,z),Vector3(side*2.9,2.7,z),0.20,TIMBER)
	for side in [-1,1]:
		for z in [-1.8,-0.6,0.6,1.8]:
			Geometry.box(self,Vector3(side*2.53,1.7,z),Vector3(0.12,2.7,0.16),TIMBER)
		for row in range(5):
			for column in range(8):
				var x := 0.30+row*0.56
				var tile := Geometry.box(self,Vector3(side*x,5.15-x*0.82,-2.22+column*0.63),Vector3(0.83,0.105,0.66),Color("344a50").lightened(float((row+column+variation)%4)*0.025))
				tile.rotation.z=-side*0.685
	Geometry.beam(self,Vector3(0,5.19,-2.60),Vector3(0,5.19,2.60),0.18,Color("536361"))
	Geometry.box(self,Vector3(1.35,4.20,0.9),Vector3(0.65,2.1,0.7),STONE)
	for row in range(5):
		Geometry.box(self,Vector3(1.35,3.45+row*0.37,0.535),Vector3(0.7,0.045,0.055),Color("3d4846"))
	Geometry.box(self,Vector3(1.35,5.27,0.9),Vector3(0.88,0.18,0.9),Color("485652"))
	Geometry.box(self,Vector3(0,1.3,-2.13),Vector3(1.1,2.3,0.15),TIMBER)
	for i in range(5):
		Geometry.box(self,Vector3(-0.41+i*0.205,1.27,-2.23),Vector3(0.18,2.12,0.04),Color("504736"))
	for y in [0.65,1.8]:
		Geometry.box(self,Vector3(0,y,-2.27),Vector3(0.94,0.085,0.04),Color("252f30"))
	Geometry.sphere(self,Vector3(0.32,1.18,-2.31),Vector3(0.09,0.09,0.07),BRASS)
	for x in [-1.55,1.55]:
		Geometry.box(self,Vector3(x,1.86,-2.12),Vector3(0.94,1.12,0.17),TIMBER)
		var glass := Geometry.box(self,Vector3(x,1.86,-2.22),Vector3(0.72,0.88,0.055),Color("d6a45d"))
		glass.material_override=Geometry.material(Color("d6a45d"),0.65)
		Geometry.box(self,Vector3(x,1.86,-2.28),Vector3(0.045,0.9,0.055),TIMBER)
		Geometry.box(self,Vector3(x,1.86,-2.28),Vector3(0.74,0.045,0.055),TIMBER)
		Geometry.box(self,Vector3(x,1.25,-2.30),Vector3(1.10,0.13,0.45),TIMBER)
	_lantern(Vector3(0.88,2.45,-2.5))
	_collision(Vector3(0,1.5,0),Vector3(5,3,4))

func _lantern(point: Vector3) -> void:
	Geometry.box(self,point,Vector3(0.22,0.36,0.22),Color("c8944b")).material_override=Geometry.material(Color("e4a34e"),1.0)
	for y in [-0.23,0.23]:
		Geometry.box(self,point+Vector3(0,y,0),Vector3(0.32,0.075,0.32),TIMBER)
	_warm_light(point)

func _warm_light(point: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position=point
	light.light_color=Color("ffb15c")
	light.light_energy=1.4
	light.omni_range=6
	add_child(light)

func _tower() -> void:
	Geometry.cylinder(self,Vector3(0,2.9,0),2.55,5.8,Color("455451"),2.35,10)
	for row in range(9):
		for i in range(10):
			var a := (i+float(row%2)*0.5)*TAU/10
			var brick := Geometry.box(self,Vector3(cos(a)*2.40,0.32+row*0.63,sin(a)*2.40),Vector3(1.42,0.59,0.23),STONE.lightened(float((i+row)%3)*0.035))
			brick.rotation.y=-a+PI*0.5
	for i in range(10):
		var a := i*TAU/10
		Geometry.box(self,Vector3(cos(a)*2.3,6.05,sin(a)*2.3),Vector3(0.82,0.95,0.82),STONE)
	Geometry.cylinder(self,Vector3(0,5.6,0),2.8,0.24,Color("758079"),2.8,10)
	Geometry.box(self,Vector3(0,1.2,-2.54),Vector3(1.05,2.4,0.14),TIMBER)
	_lantern(Vector3(1.15,2.3,-2.42))
	_collision(Vector3(0,3,0),Vector3(4.8,6,4.8))

func _tree() -> void:
	var size_value := 1.0+(variation%4)*0.13
	Geometry.cylinder(self,Vector3(0,1.5,0),0.25,3.0,TIMBER,0.12,6)
	for i in range(3):
		var a := i*TAU/3+variation
		Geometry.beam(self,Vector3(0,0.45,0),Vector3(cos(a)*0.62,0.04,sin(a)*0.62),0.15,TIMBER)
	# Jagged radial boughs form a single colored mesh, rather than stacked cones.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(4):
		var radius := (1.85-layer*0.37)*size_value
		var y := 1.6+layer*0.85
		for i in range(9):
			var a := (i+layer*0.38)*TAU/9
			var b := (i+1+layer*0.38)*TAU/9
			var dip := 0.12 if i%2==0 else -0.12
			surface.set_color(Color("233d35").lerp(Color("52705a"),float((i+layer+variation)%5)/5.0))
			for vertex in [Vector3(cos(a)*radius,y+dip,sin(a)*radius),Vector3(0.12,y+1.75,0),Vector3(cos(b)*radius,y-dip,sin(b)*radius)]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var tree := Geometry.mesh_node(self,surface.commit(),Vector3.ZERO,Color.WHITE)
	var mat := Geometry.material(Color.WHITE).duplicate() as StandardMaterial3D
	mat.vertex_color_use_as_albedo=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	tree.material_override=mat
	_collision(Vector3(0,0.8,0),Vector3(0.65,1.6,0.65))

func _fire() -> void:
	for i in range(9):
		var a := i*TAU/9
		Geometry.sphere(self,Vector3(cos(a)*0.74,0.16,sin(a)*0.74),Vector3(0.42,0.30,0.36),STONE)
	for angle in [0.4,-0.4]:
		var log := Geometry.cylinder(self,Vector3(0,0.20,0),0.13,1.2,TIMBER,0.13,6)
		log.rotation=Vector3(PI*0.5,angle,0)
	var fire := FireVisual.new()
	add_child(fire)

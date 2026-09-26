@tool
class_name CryptChamber
extends Node3D
## Native room geometry: openings define the same walls used by navigation.
@export var extent := Vector2(14,14)
@export var north_opening: float = 0
@export var south_opening: float = 0
@export var west_openings := PackedVector2Array()
@export var east_openings := PackedVector2Array()
@export_enum("hall","tombs","bones","sanctum") var decor: String = "tombs"
@export var lit: bool = true
@export var furnishings: bool = true
const STONE := Color("414c4a")

func _ready() -> void:
	Geometry.box(self,Vector3(0,-0.2,0),Vector3(extent.x,0.4,extent.y),Color("303d3b"))
	Geometry.collider(self,Vector3(0,-0.25,0),Vector3(extent.x,0.5,extent.y))
	for x in range(int(extent.x/2)):
		for z in range(int(extent.y/2)):
			var p := Vector3(-extent.x/2+1+x*2,0.013,-extent.y/2+1+z*2)
			Geometry.box(self,p,Vector3(1.94,0.025,1.94),Color("48524b").darkened(float((x*7+z*3)%5)*0.045))
	_wall(false,-extent.y/2,extent.x,PackedVector2Array([Vector2(0,north_opening)]) if north_opening>0 else PackedVector2Array(),3.7)
	_wall(false,extent.y/2,extent.x,PackedVector2Array([Vector2(0,south_opening)]) if south_opening>0 else PackedVector2Array(),0.95)
	_wall(true,-extent.x/2,extent.y,west_openings,3.2)
	_wall(true,extent.x/2,extent.y,east_openings,1.0)
	if not furnishings: return
	if decor == "hall":
		for z in [24,8,-10,-26]: _sconce(Vector3(-4.3,1.65,z))
		for z in [21,-3,-18]:
			var slab := Geometry.box(self,Vector3(0,0.055,z),Vector3(2.3,0.04,4.0),Color("263c3a"))
			Geometry.box(slab,Vector3(-0.9,0.03,0),Vector3(0.06,0.02,3.9),Color("8c7953"))
	elif decor == "sanctum":
		for x in [-13,13]:
			for z in [-10,4,11]:
				_pillar(Vector3(x,0,z))
				_sconce(Vector3(x,2.2,z))
		Geometry.box(self,Vector3(0,0.42,-11.7),Vector3(5.4,0.85,1.5),Color("485953"))
		Geometry.box(self,Vector3(0,0.94,-11.7),Vector3(5.7,0.2,1.7),Color("747765"))
		Geometry.collider(self,Vector3(0,0.6,-11.7),Vector3(5.7,1.2,1.7))
		for x in [-2,-1,1,2]: _candle(Vector3(x,1.06,-11.7))
		for i in range(6): Geometry.box(self,Vector3(-2.0+i*0.8,1.2,-14.7),Vector3(0.1,2.4,0.14),Color("292d2a"))
	else:
		for z in [-extent.y*0.32,extent.y*0.32]:
			var x := -extent.x*0.28 if decor == "tombs" else extent.x*0.30
			Geometry.box(self,Vector3(x,0.35,z),Vector3(1.8,0.7,2.8),STONE)
			Geometry.box(self,Vector3(x,0.77,z),Vector3(2,0.16,3),Color("686e60"))
			Geometry.collider(self,Vector3(x,0.45,z),Vector3(2,0.9,3))
			Geometry.beam(self,Vector3(x,0.88,z-0.8),Vector3(x,0.88,z+0.8),0.06,Color("92927c"))
			_candle(Vector3(x+0.55,0.9,z-0.7))
		_sconce(Vector3(0,1.7,-extent.y/2+0.5))
		if decor == "bones":
			for i in range(9):
				var p := Vector3(-extent.x*0.3+i%3*0.5,0.18,-extent.y*0.32+i/3*0.5)
				Geometry.sphere(self,p,Vector3(0.32,0.32,0.30),Color("929882"))
				Geometry.box(self,p+Vector3(0,0.01,0.14),Vector3(0.19,0.055,0.02),Color("1e2928"))

func _wall(vertical: bool, edge: float, length: float, openings: PackedVector2Array, height: float) -> void:
	var cuts: Array[Vector2] = []
	for opening in openings: cuts.append(opening)
	cuts.sort_custom(func(a: Vector2,b: Vector2): return a.x < b.x)
	var start := -length/2
	for opening in cuts:
		_segment(vertical,edge,start,opening.x-opening.y/2,height)
		start = opening.x+opening.y/2
		for side in [-1,1]:
			var p := Vector3(edge,0,opening.x+side*(opening.y/2+0.22)) if vertical else Vector3(opening.x+side*(opening.y/2+0.22),0,edge)
			_pillar(p)
	_segment(vertical,edge,start,length/2,height)

func _segment(vertical: bool, edge: float, start: float, end: float, height: float) -> void:
	if end-start < 0.05: return
	var p := Vector3(edge,height/2,(start+end)/2) if vertical else Vector3((start+end)/2,height/2,edge)
	var size_value := Vector3(0.55,height,end-start) if vertical else Vector3(end-start,height,0.55)
	Geometry.box(self,p,size_value,STONE)
	var barrier := size_value
	barrier.y = 4
	Geometry.collider(self,Vector3(p.x,2,p.z),barrier)
	for i in range(int((end-start)/1.7)):
		var along := start+0.8+i*1.7
		for row in range(int(height/0.65)):
			var block := Vector3(edge,row*0.65+0.32,along) if vertical else Vector3(along,row*0.65+0.32,edge)
			Geometry.box(self,block,Vector3(0.61,0.60,1.6) if vertical else Vector3(1.6,0.60,0.61),STONE.lightened(0.02*((i+row)%3)))

func _pillar(p: Vector3) -> void:
	Geometry.box(self,p+Vector3.UP*0.15,Vector3(1.0,0.3,1.0),Color("555e53"))
	Geometry.cylinder(self,p+Vector3.UP*1.65,0.31,3,Color("566258"),0.29,7)
	Geometry.box(self,p+Vector3.UP*3.15,Vector3(0.85,0.28,0.85),Color("686f60"))

func _sconce(p: Vector3) -> void:
	if not lit: return
	Geometry.beam(self,p-Vector3.UP*0.35,p,0.1,Color("726647"))
	var fire := FireVisual.new()
	fire.position = p
	fire.flame_height = 0.65
	fire.light_energy = 1.5
	fire.light_range = 8
	fire.sound_enabled = false
	fire.embers_enabled = false
	add_child(fire)

func _candle(p: Vector3) -> void:
	if not lit: return
	Geometry.cylinder(self,p+Vector3.UP*0.13,0.065,0.27,Color("bbb49a"))
	var glow := Geometry.sphere(self,p+Vector3.UP*0.32,Vector3(0.075,0.18,0.075),Color("e1b978"))
	glow.material_override = Geometry.material(Color("e1b978"),1.5)

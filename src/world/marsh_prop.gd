@tool
class_name MarshProp
extends Node3D
## Editable marsh art vocabulary. Decorative insects have no gameplay identity.
@export_enum("cypress","lamp","bridge","reeds","shrine","ferry","web_nest","grave","palisade","supplies","target","mushrooms") var kind: String = "cypress"
@export var variation: int = 0
@export var length: float = 12.0
@export var width: float = 4.4
var motes: Array[MeshInstance3D] = []
var light: OmniLight3D
var phase: float = 0
const WOOD := Color("3a4035")
const MOSS := Color("425744")
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = variation*173+83
	phase = rng.randf()*TAU
	match kind:
		"supplies":
			for i in range(3):
				Geometry.cylinder(self,Vector3(i*0.8,0.5,0),0.35,1.0,Color("625643"),0.33,10)
				for y in [0.2,0.8]: Geometry.cylinder(self,Vector3(i*0.8,y,0),0.36,0.055,Color("46504a"),0.36,10)
			Geometry.box(self,Vector3(0,0.65,1.1),Vector3(2.3,0.13,0.7),Color("605944"))
			for x in [-0.8,0.8]: Geometry.box(self,Vector3(x,0.3,1.1),Vector3(0.15,0.65,0.5),WOOD)
			for i in range(4): Geometry.sphere(self,Vector3(-0.7+i*0.45,0.79,1.1),Vector3(0.24,0.16,0.24),Color("a39c79"))
		"target":
			Geometry.beam(self,Vector3(-0.5,0,0.2),Vector3(0,1.6,0),0.15,WOOD)
			Geometry.beam(self,Vector3(0.5,0,0.2),Vector3(0,1.6,0),0.15,WOOD)
			var shield := Node3D.new()
			add_child(shield)
			shield.position.y = 1.6
			shield.rotation.x = PI*0.5
			Geometry.cylinder(shield,Vector3.ZERO,0.65,0.15,Color("928768"),0.65,12)
			for radius in [0.20,0.42,0.61]:
				var ring := Geometry.ring(shield,radius,Color("663e2c"),0.035)
				ring.position.y = -0.081
		"mushrooms":
			for i in range(5):
				var p := Vector3(rng.randf_range(-0.7,0.7),0,rng.randf_range(-0.7,0.7))
				var h := rng.randf_range(0.16,0.40)
				Geometry.cylinder(self,p+Vector3.UP*h*0.5,0.04,h,Color("989883"))
				Geometry.sphere(self,p+Vector3.UP*h,Vector3(h,0.12,h),Color("858776"))
		"cypress":
			var height := rng.randf_range(5.3,8.0)
			Geometry.cylinder(self,Vector3(0,height*0.3,0),0.62,height*0.6,WOOD,0.26,7)
			for i in range(5):
				var a := i*TAU/5+rng.randf()*0.3
				var root_end := Vector3(cos(a)*1.8,0.05,sin(a)*1.8)
				Geometry.beam(self,Vector3(0,0.8,0),root_end,0.25,WOOD)
				var branch := Vector3(cos(a)*1.55,height*(0.58+rng.randf()*0.25),sin(a)*1.55)
				Geometry.beam(self,Vector3(0,height*0.48,0),branch,0.20,WOOD)
				Geometry.sphere(self,branch+Vector3.UP*0.3,Vector3(3.3,1.25,2.7),MOSS.darkened(rng.randf()*0.3))
				for j in range(2):
					var hanging := branch+Vector3(rng.randf_range(-0.7,0.7),-0.4,rng.randf_range(-0.7,0.7))
					Geometry.beam(self,hanging,hanging+Vector3(0.2,-rng.randf_range(1.0,2.0),0.1),0.07,Color("66715a"))
			Geometry.collider(self,Vector3(0,1,0),Vector3(1.1,2,1.1))
			if not Engine.is_editor_hint(): add_child(ProximityFade.new())
		"lamp":
			Geometry.cylinder(self,Vector3(0,1.5,0),0.10,3.0,WOOD)
			Geometry.beam(self,Vector3(0,3,0),Vector3(0.7,3,0),0.10,WOOD)
			Geometry.beam(self,Vector3(0.67,3,0),Vector3(0.67,2.6,0),0.035,Color("6c786f"))
			var lamp := Geometry.box(self,Vector3(0.67,2.45,0),Vector3(0.34,0.48,0.34),Color("e6ad5c"))
			lamp.material_override = Geometry.material(Color("f5bd67"),1.8)
			for y in [2.18,2.71]: Geometry.box(self,Vector3(0.67,y,0),Vector3(0.48,0.08,0.48),Color("353b36"))
			for x in [-0.17,0.17]:
				for z in [-0.17,0.17]: Geometry.beam(self,Vector3(0.67+x,2.17,z),Vector3(0.67+x,2.75,z),0.04,Color("353b36"))
			light = OmniLight3D.new()
			light.position = Vector3(0.67,2.6,0)
			light.light_color = Color("ffce83")
			light.light_energy = 3.0
			light.omni_range = 10.0
			add_child(light)
			for i in range(9):
				var mote := Geometry.sphere(self,Vector3.ZERO,Vector3.ONE*0.045,Color("d2dc7c"))
				mote.material_override = Geometry.material(Color("d2dc7c"),2.0)
				mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				motes.append(mote)
		"bridge":
			for i in range(int(length/0.42)):
				var plank := Geometry.box(self,Vector3(0,0.12,-length*0.5+i*0.42),Vector3(width,0.18,0.38),Color("625e48").darkened(rng.randf()*0.18))
				plank.rotation.y = rng.randf_range(-0.015,0.015)
			for side in [-1,1]:
				Geometry.beam(self,Vector3(side*(width*0.5-0.18),0.86,-length*0.5),Vector3(side*(width*0.5-0.18),0.86,length*0.5),0.10,WOOD)
				for z in range(int(length/2.5)+1):
					Geometry.cylinder(self,Vector3(side*(width*0.5-0.18),0.43,-length*0.5+z*2.5),0.13,1.35,WOOD,0.1,6)
				Geometry.collider(self,Vector3(side*width*0.5,0.55,0),Vector3(0.16,1.0,length))
			Geometry.collider(self,Vector3(0,-0.02,0),Vector3(width,0.40,length))
			# A CharacterBody does not automatically step up a vertical deck lip.
			# Both banks have a real sloped collider, shared with the nav bake.
			for side in [-1,1]:
				var ramp_length := 1.8
				var edge: float = side*length*0.5
				var outer: float = edge+side*ramp_length
				var ramp := Geometry.box(self,Vector3(0,0.08,edge+side*ramp_length*0.5),Vector3(width,0.10,ramp_length+0.08),Color("625e48"))
				ramp.rotation.x = side*atan2(0.18,ramp_length)
				var shape := ConvexPolygonShape3D.new()
				shape.points = PackedVector3Array([
					Vector3(-width*0.5,-0.2,edge),Vector3(width*0.5,-0.2,edge),
					Vector3(-width*0.5,-0.2,outer),Vector3(width*0.5,-0.2,outer),
					Vector3(-width*0.5,0.18,edge),Vector3(width*0.5,0.18,edge),
					Vector3(-width*0.5,0,outer),Vector3(width*0.5,0,outer)])
				var body := StaticBody3D.new()
				add_child(body)
				var collision := CollisionShape3D.new()
				collision.shape = shape
				body.add_child(collision)
		"reeds":
			# One batched mesh per clump; seed keeps dressing stable between visits.
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(32):
				var base := Vector3(rng.randf_range(-1.2,1.2),0,rng.randf_range(-1.2,1.2))
				var h := rng.randf_range(0.55,1.5)
				for v in [base-Vector3.RIGHT*0.04,base+Vector3.RIGHT*0.04,base+Vector3(0.25,h,0.08)]: surface.add_vertex(v)
			surface.generate_normals()
			var reeds := Geometry.mesh_node(self,surface.commit(),Vector3.ZERO,Color("6b7750"))
			reeds.material_override = Geometry.material(Color("6b7750")).duplicate()
			reeds.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
			for i in range(5): Geometry.cylinder(self,Vector3(rng.randf_range(-0.7,0.7),1.1,rng.randf_range(-0.7,0.7)),0.065,0.35,Color("544835"),0.065,5)
		"shrine":
			# Surviving voussoirs and a broken nave distinguish the flooded chapel.
			for side in [-1,1]:
				for row in range(5):
					Geometry.box(self,Vector3(side*2.5,0.3+row*0.55,-4.5),Vector3(0.8,0.50,0.85),Color("68786d").darkened(row%2*0.06))
				Geometry.collider(self,Vector3(side*2.5,1.4,-4.5),Vector3(0.8,2.8,0.85))
			for i in range(11):
				if i in [3,4]: continue
				var angle := i*PI/10
				var stone := Geometry.box(self,Vector3(cos(angle)*2.5,2.7+sin(angle)*2.0,-4.5),Vector3(0.72,0.65,0.90),Color("718174"))
				stone.rotation.z = angle-PI*0.5
			for i in range(9):
				Geometry.box(self,Vector3(rng.randf_range(-3,3),0.12,rng.randf_range(-3,4)),Vector3(0.8,0.24,0.5),Color("4b5b4c"))
			for i in range(8):
				var a := i*TAU/8
				var p := Vector3(cos(a)*4.7,1,sin(a)*4.7)
				if i in [2,6]: continue
				Geometry.box(self,p,Vector3(0.85,2+rng.randf(),0.7),Color("63746c"))
				Geometry.collider(self,p,Vector3(0.85,2,0.7))
			Geometry.box(self,Vector3(0,0.65,0),Vector3(2.2,1.3,1.4),Color("55645c"))
			Geometry.box(self,Vector3(0,1.35,0),Vector3(2.6,0.18,1.7),Color("859085"))
			Geometry.box(self,Vector3(0,1.49,-0.25),Vector3(0.48,0.10,0.34),Color("414f42"))
			Geometry.collider(self,Vector3(0,0.65,0),Vector3(2.2,1.3,1.4))
			for i in range(10):
				var a := i*TAU/10
				Geometry.box(self,Vector3(cos(a)*2.1,0.035,sin(a)*2.1),Vector3(0.45,0.055,0.35),Color("606d5d"))
		"ferry":
			for side in [-1,1]:
				Geometry.beam(self,Vector3(side*1.2,0.55,-2.7),Vector3(side*1.2,0.55,2.7),0.25,WOOD)
				Geometry.beam(self,Vector3(side*1.2,0.55,-2.7),Vector3(0,0.55,-3.6),0.22,WOOD)
			for i in range(12): Geometry.box(self,Vector3(0,0.25,-2.5+i*0.45),Vector3(2.4,0.18,0.40),Color("666047"))
			Geometry.beam(self,Vector3(-1,0.4,0),Vector3(1.8,1.0,-3),0.08,Color("807254"))
			Geometry.collider(self,Vector3(0,0.4,0),Vector3(2.4,0.8,5.5))
		"web_nest":
			for i in range(10):
				var a := i*TAU/10
				Geometry.beam(self,Vector3(0,0.08,0),Vector3(cos(a)*3.6,0.10,sin(a)*3.6),0.018,Color("939e92"))
			for r in [0.7,1.3,2.0,2.8,3.5]: Geometry.ring(self,r,Color("7b897e"),0.018)
			for i in range(5): Geometry.sphere(self,Vector3(rng.randf_range(-1.5,1.5),0.35,rng.randf_range(-1.5,1.5)),Vector3(0.55,0.65,0.55),Color("a5a48a"))
		"grave":
			var stone := Geometry.box(self,Vector3(0,0.65,0),Vector3(0.8,1.3,0.32),Color("66766d"))
			stone.rotation.z = rng.randf_range(-0.18,0.18)
			Geometry.box(self,Vector3(0,0.055,0.8),Vector3(0.8,0.08,1.7),Color("41483c"))
			Geometry.collider(self,Vector3(0,0.6,0),Vector3(0.8,1.2,0.32))
		"palisade":
			for i in range(7):
				Geometry.cylinder(self,Vector3(i*0.42-1.3,1.0,0),0.20,2.0,WOOD,0.12,6)
				Geometry.cylinder(self,Vector3(i*0.42-1.3,2.1,0),0.13,0.3,WOOD,0,6)
			Geometry.collider(self,Vector3(0,1,0),Vector3(3.0,2,0.5))
	if kind != "lamp": set_process(false)
func _process(delta: float) -> void:
	phase += delta
	if light: light.light_energy = 3.0+sin(phase*2.7)*0.16
	for i in range(motes.size()):
		var t := phase*0.5+i*2.4
		motes[i].position = Vector3(0.7+sin(t)*(1.0+i*0.14),1.2+sin(t*1.7+i)*0.65,cos(t*0.8)*(0.8+i*0.12))

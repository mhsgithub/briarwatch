@tool
class_name ActorVisual
extends Node3D
## Art-only articulated silhouettes. Gameplay owns timing and health.
@export_enum("warrior", "melee", "archer", "wolf", "npc", "commander", "brutus", "lord", "elite", "garrick", "bloodfang") var style: String = "warrior"
@export var tint: Color = Color("527b7b")
var equipment: Dictionary = {}
var pivot: Node3D
var weapon: Node3D
var legs: Array[Node3D] = []
var phase: float = 0
var moving: bool = false
var swing: float = 0
var windup_duration: float = 0.2
var flash: float = 0
var telegraph: Node3D
var slash: MeshInstance3D
var special_kind: String = ""
var special_left: float = 0.0
var special_duration: float = 1.0
var raging: bool = false
var fists: Array[Node3D] = []
var feeding: bool = false
var beast_head: Node3D
var jaw: Node3D
var rage_light: OmniLight3D
var carried_torch: Node3D

func _ready() -> void:
	rebuild()

func set_equipment(value: Dictionary) -> void:
	if equipment == value:
		return
	equipment = value.duplicate()
	if is_inside_tree():
		rebuild()

func gear(slot: String) -> ItemDefinition:
	return equipment.get(slot) as ItemDefinition

func part(slot: String) -> Node3D:
	var node := Node3D.new()
	node.name = "gear_" + slot
	pivot.add_child(node)
	return node

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	legs.clear()
	fists.clear()
	weapon = null
	beast_head = null
	jaw = null
	rage_light = null
	carried_torch = null
	pivot = Node3D.new()
	add_child(pivot)
	if style in ["crocodile","marsh_widow","broodqueen"]:
		MarshCreature.build(self)
	elif style == "bloodfang":
		_build_bloodfang()
	elif style == "brutus":
		_build_brutus()
	elif style == "lord":
		_build_lord()
	elif style == "wolf":
		_build_wolf()
	else:
		_build_human()
		if style in ["garrick","elite"]: _build_outlaw_armor()
	if style == "warrior":
		Geometry.ring(self, 0.57, Color("b8b886"), 0.018)
	telegraph = Node3D.new()
	add_child(telegraph)
	for i in range(13):
		var angle := deg_to_rad(-55 + i * 9.16)
		var mark := Geometry.box(telegraph, Vector3(sin(angle) * 1.65, 0.075, -cos(angle) * 1.65), Vector3(0.16, 0.025, 0.06), Color("b97143"))
		mark.rotation.y = -angle
	telegraph.visible = false
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var a := deg_to_rad(-70 + i * 9)
		var b := deg_to_rad(-70 + (i + 1) * 9)
		for v in [Vector3(sin(a)*1.1,0,-cos(a)*1.1), Vector3(sin(a)*2.25,0,-cos(a)*2.25), Vector3(sin(b)*2.25,0,-cos(b)*2.25)]:
			surface.add_vertex(v)
	surface.generate_normals()
	slash = Geometry.mesh_node(self, surface.commit(), Vector3(0, 0.8, 0), Color("f6e4b9"))
	var slash_mat := Geometry.material(Color(0.96,0.85,0.60,0.7), 0.7).duplicate() as StandardMaterial3D
	slash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slash_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	slash.material_override = slash_mat
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slash.visible = false

func _build_human() -> void:
	var hero := style == "warrior"
	var two_handed := style == "commander" or (hero and gear("weapon") != null and gear("weapon").two_handed)
	var steel := Color("758c91")
	var edge := Color("c1c6b4")
	var skin := Color("b49776")
	var leather := Color("40332b")
	var cloth := Color("6a6655") if hero else tint.darkened(0.2)
	var brass := Color("ae8c50")
	for side in [-1, 1]:
		var leg := Node3D.new()
		pivot.add_child(leg)
		leg.position = Vector3(side * 0.21, 0.69, 0)
		Geometry.cylinder(leg,Vector3(0,-0.2,0),0.135,0.48,leather,0.16,6)
		Geometry.box(leg,Vector3(0,-0.49,-0.03),Vector3(0.23,0.18,0.33),leather.darkened(0.25))
		if hero and gear("boots"):
			var boot := Node3D.new()
			boot.name = "gear_boots"
			leg.add_child(boot)
			Geometry.box(boot,Vector3(0,-0.40,-0.06),Vector3(0.29,0.34,0.39),leather.lightened(0.09))
			if gear("boots").appearance == "reinforced":
				Geometry.box(boot,Vector3(0,-0.38,-0.25),Vector3(0.25,0.20,0.06),steel)
		legs.append(leg)
	Geometry.cylinder(pivot,Vector3(0,1.17,0),0.30,0.70,cloth,0.40,8)
	Geometry.cylinder(pivot,Vector3(0,0.86,0),0.39,0.30,cloth,0.30,8)
	for side in [-1,1]:
		if two_handed and side == -1:
			Geometry.beam(pivot,Vector3(-0.43,1.37,0),Vector3(0.27,1.06,-0.28),0.20,cloth)
			Geometry.sphere(pivot,Vector3(0.27,1.06,-0.28),Vector3(0.21,0.23,0.24),skin)
		else:
			Geometry.cylinder(pivot,Vector3(side*0.44,1.16,0),0.13,0.47,cloth,0.17,6)
			Geometry.sphere(pivot,Vector3(side*0.47,0.91,-0.04),Vector3(0.21,0.23,0.24),skin)
	Geometry.sphere(pivot,Vector3(0,1.77,0),Vector3(0.43,0.50,0.43),skin)
	Geometry.sphere(pivot,Vector3(0,1.93,0.035),Vector3(0.45,0.23,0.46),Color("342e28"))
	Geometry.box(pivot,Vector3(0,1.79,-0.215),Vector3(0.25,0.035,0.025),Color("342e28"))
	if hero:
		if gear("body"):
			var body := part("body")
			var appearance := gear("body").appearance
			var body_color := leather.lightened(0.10) if appearance == "leather" else tint.darkened(0.10)
			Geometry.cylinder(body,Vector3(0,1.23,0),0.34,0.67,steel if appearance == "mail" else body_color,0.44,8)
			Geometry.cylinder(body,Vector3(0,0.83,0),0.46,0.47,body_color,0.33,8)
			Geometry.box(body,Vector3(0,1.14,-0.36),Vector3(0.28,0.78,0.065),body_color)
			for side in [-1,1]:
				Geometry.sphere(body,Vector3(side*0.43,1.43,0),Vector3(0.39,0.23,0.50),steel if appearance == "mail" else body_color.lightened(0.12))
			_build_cape(body_color)
		if gear("head"):
			var head := part("head")
			if gear("head").appearance == "helmet":
				Geometry.cylinder(head,Vector3(0,1.77,0),0.27,0.47,steel,0.21,8)
				Geometry.sphere(head,Vector3(0,1.98,0),Vector3(0.46,0.30,0.46),edge)
				Geometry.box(head,Vector3(0,1.81,-0.25),Vector3(0.43,0.073,0.055),Color("141c22"))
				Geometry.box(head,Vector3(0,1.72,-0.29),Vector3(0.06,0.36,0.065),brass)
				Geometry.box(head,Vector3(0,2.11,0.03),Vector3(0.10,0.25,0.46),tint.darkened(0.2))
			else:
				Geometry.sphere(head,Vector3(0,1.85,0.04),Vector3(0.58,0.65,0.53),Color("424b46"))
				Geometry.box(head,Vector3(0,1.77,-0.245),Vector3(0.31,0.30,0.06),skin.darkened(0.2))
		if gear("gloves"):
			var gloves := part("gloves")
			for side in [-1,1]:
				Geometry.box(gloves,Vector3(0.27,1.06,-0.28) if two_handed and side == -1 else Vector3(side*0.47,0.95,-0.05),Vector3(0.24,0.31,0.30),steel if gear("gloves").appearance=="reinforced" else leather.lightened(0.1))
		if gear("belt"):
			var belt := part("belt")
			Geometry.box(belt,Vector3(0,0.97,-0.025),Vector3(0.74,0.13,0.63),leather)
			Geometry.box(belt,Vector3(0,0.97,-0.37),Vector3(0.15,0.15,0.06),brass)
		if gear("amulet"):
			var amulet := part("amulet")
			Geometry.beam(amulet,Vector3(-0.14,1.52,-0.29),Vector3(0,1.27,-0.41),0.025,brass)
			Geometry.beam(amulet,Vector3(0.14,1.52,-0.29),Vector3(0,1.27,-0.41),0.025,brass)
			Geometry.sphere(amulet,Vector3(0,1.26,-0.42),Vector3(0.13,0.17,0.08),Color("55a26e"))
		if gear("shoulders"):
			var shoulders := part("shoulders")
			for side in [-1,1]:
				Geometry.sphere(shoulders,Vector3(side*0.47,1.45,0),Vector3(0.47,0.28,0.55),gear("shoulders").tint)
			_build_cape(gear("shoulders").tint)
		for slot in ["ring_left","ring_right"]:
			if gear(slot):
				var ring := part(slot)
				Geometry.sphere(ring,Vector3(-0.49 if slot=="ring_left" else 0.49,0.91,-0.17),Vector3(0.07,0.07,0.035),brass)
	else:
		# Raiders are cloth-and-leather outlaws, not armored watchmen.
		if style in ["melee","archer","commander"]:
			Geometry.cylinder(pivot,Vector3(0,1.20,0),0.32,0.60,leather,0.41,8)
			Geometry.beam(pivot,Vector3(-0.28,1.50,-0.30),Vector3(0.28,0.91,-0.34),0.085,Color("807151"))
			if style == "archer":
				Geometry.sphere(pivot,Vector3(0,1.86,0.03),Vector3(0.54,0.60,0.51),cloth)
				Geometry.box(pivot,Vector3(0,1.77,-0.24),Vector3(0.30,0.26,0.065),skin)
			else:
				Geometry.box(pivot,Vector3(0,1.93,-0.17),Vector3(0.45,0.12,0.15),cloth)
		else:
			_build_cape(cloth)
		if style == "commander":
			_build_cape(Color("4c3435"))
			for side in [-1, 1]:
				Geometry.sphere(pivot, Vector3(side * 0.42, 1.48, 0.05), Vector3(0.55, 0.35, 0.65), Color("554f45"))
			Geometry.box(pivot, Vector3(0, 0.95, -0.03), Vector3(0.78, 0.18, 0.65), leather)
			Geometry.box(pivot, Vector3(0, 0.95, -0.37), Vector3(0.18, 0.18, 0.06), steel)
	var weapon_item := gear("weapon")
	var has_weapon := (hero and weapon_item != null) or style in ["melee","archer","commander","garrick","elite"]
	if has_weapon:
		weapon = part("weapon")
		weapon.position = Vector3(0.55,1.02,-0.08)
		if style == "commander":
			Geometry.beam(weapon, Vector3(0, -0.30, 0.45), Vector3(0, 0.25, -1.65), 0.105, Color("655144"))
			Geometry.box(weapon, Vector3(0, 0.22, -1.53), Vector3(0.20, 0.18, 0.45), steel)
			for side in [-1, 1]:
				var blade := Geometry.box(weapon, Vector3(side * 0.34, 0.24, -1.55), Vector3(0.63, 0.10, 0.67), steel)
				blade.rotation.y = side * -0.22
				var rim := Geometry.box(weapon, Vector3(side * 0.63, 0.24, -1.58), Vector3(0.09, 0.075, 0.76), edge)
				rim.rotation.y = side * -0.22
		elif style == "archer":
			for i in range(8):
				var a := -1.2+i*0.3
				var b := a+0.3
				Geometry.beam(weapon,Vector3(0,sin(a)*0.62,-cos(a)*0.32),Vector3(0,sin(b)*0.62,-cos(b)*0.32),0.07,Color("b19a69"))
			Geometry.beam(weapon,Vector3(0,-0.58,-0.11),Vector3(0,0.58,-0.11),0.015,Color("c2b99a"))
		elif weapon_item and weapon_item.appearance in ["cleaver","greatblade"]:
			var great := weapon_item.appearance == "greatblade"
			Geometry.box(weapon,Vector3(0,0,0.03),Vector3(0.13,0.14,0.65 if great else 0.38),Color("343a30"))
			Geometry.box(weapon,Vector3(0,0,-0.28),Vector3(0.75 if great else 0.48,0.12,0.13),brass)
			Geometry.box(weapon,Vector3(0,0,-1.26 if great else -0.94),Vector3(0.28 if great else 0.39,0.075,1.90 if great else 1.15),Color("929e92"))
			Geometry.box(weapon,Vector3(0,0.045,-1.26 if great else -0.94),Vector3(0.10,0.018,1.7 if great else 0.95),Color("435c48"))
			Geometry.sphere(weapon,Vector3(0,0,0.38 if great else 0.25),Vector3.ONE*0.20,brass)
		elif weapon_item and weapon_item.appearance == "polearm":
			var polearm := Node3D.new()
			weapon.add_child(polearm)
			polearm.rotation.x = 0.85
			polearm.rotation.y = 0.45
			polearm.scale = Vector3.ONE*0.75
			Geometry.beam(polearm,Vector3(0,0,0.85),Vector3(0,0,-1.45),0.09,Color("3f382d"))
			for z in [0.5,0.3,0.1,-0.1,-1.2]:
				Geometry.box(polearm,Vector3(0,0,z),Vector3(0.14,0.14,0.085),brass)
			Geometry.beam(polearm,Vector3(0,0,-1.30),Vector3(-0.09,0,-2.15),0.22,Color("9aa99f"))
			Geometry.beam(polearm,Vector3(-0.09,0,-2.12),Vector3(0.18,0,-2.57),0.12,edge)
			Geometry.beam(polearm,Vector3(0,0,-1.44),Vector3(0.34,0,-1.80),0.13,steel)
			Geometry.beam(polearm,Vector3(0.34,0,-1.80),Vector3(0.30,0,-2.05),0.08,edge)
			Geometry.sphere(polearm,Vector3(0,0.075,-1.35),Vector3(0.16,0.08,0.23),Color("477e55"))
		elif weapon_item and weapon_item.appearance == "pitchfork":
			Geometry.beam(weapon,Vector3(0,-0.5,0.5),Vector3(0,0.65,-0.65),0.085,Color("816446"))
			Geometry.box(weapon,Vector3(0,0.65,-0.65),Vector3(0.65,0.08,0.10),steel)
			for x in [-0.29,0,0.29]:
				Geometry.beam(weapon,Vector3(x,0.65,-0.65),Vector3(x,1.02,-1.02),0.055,edge)
		elif weapon_item and weapon_item.appearance == "bloodclaw":
			Geometry.box(weapon,Vector3(0,0,-0.1),Vector3(0.14,0.14,0.4),Color("251e21"))
			Geometry.beam(weapon,Vector3(-0.32,0,-0.18),Vector3(0.32,0,-0.38),0.10,Color("aea393"))
			Geometry.box(weapon,Vector3(0,0,-0.94),Vector3(0.24,0.065,1.25),Color("a2aeb0"))
			Geometry.box(weapon,Vector3(0,0.042,-0.95),Vector3(0.075,0.015,1.12),Color("941e24"))
			for i in range(3):
				Geometry.beam(weapon,Vector3(0.1,0,-0.65-i*0.3),Vector3(0.24,0,-0.89-i*0.3),0.07,Color("babead"))
			Geometry.beam(weapon,Vector3(0,0,-1.49),Vector3(-0.20,0,-1.75),0.13,Color("681d24"))
		else:
			Geometry.box(weapon,Vector3(0,0,-0.1),Vector3(0.13,0.13,0.4),leather)
			Geometry.box(weapon,Vector3(0,0,-0.29),Vector3(0.52,0.11,0.12),brass)
			Geometry.box(weapon,Vector3(0,0,-0.95),Vector3(0.18,0.055,1.25),edge)
			Geometry.box(weapon,Vector3(0,0.035,-0.95),Vector3(0.055,0.028,1.2),steel)
	if hero and gear("shield"):
		var shield_part := part("shield")
		var shield := Geometry.cylinder(shield_part,Vector3(-0.63,1.06,-0.17),0.43,0.14,brass,0.43,6)
		shield.rotation_degrees.z=90
		shield.scale.z=1.3
		var face := Geometry.cylinder(shield_part,Vector3(-0.72,1.06,-0.17),0.37,0.05,steel if gear("shield").appearance=="iron" else tint,0.37,6)
		face.rotation_degrees.z=90
		face.scale.z=1.3
		Geometry.box(shield_part,Vector3(-0.76,1.06,-0.17),Vector3(0.04,0.6,0.07),brass)

func _build_cape(color: Color) -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := [Vector3(-0.38,1.52,0.22),Vector3(0.38,1.52,0.22),Vector3(0.53,0.51,0.48),Vector3(-0.38,1.52,0.22),Vector3(0.53,0.51,0.48),Vector3(-0.53,0.51,0.48)]
	for v in vertices:
		mesh.add_vertex(v)
	mesh.generate_normals()
	var cape := Geometry.mesh_node(pivot,mesh.commit(),Vector3.ZERO,color.darkened(0.22))
	var mat := Geometry.material(color.darkened(0.22)).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cape.material_override = mat

func _build_outlaw_armor() -> void:
	var elegant := style=="garrick"
	var iron := Color("667477")
	var trim := Color("bfaa77") if elegant else Color("989b89")
	Geometry.cylinder(pivot,Vector3(0,1.2,0),0.33,0.61,Color("262c32"),0.40,8)
	for side in [-1,1]:
		Geometry.sphere(pivot,Vector3(side*0.43,1.43,0),Vector3(0.43,0.25,0.49),iron)
		Geometry.beam(pivot,Vector3(side*0.20,1.5,-0.32),Vector3(side*0.15,0.86,-0.35),0.035,trim)
	Geometry.box(pivot,Vector3(0,0.91,-0.02),Vector3(0.78,0.14,0.66),Color("242323"))
	Geometry.box(pivot,Vector3(0,0.91,-0.38),Vector3(0.17,0.17,0.055),trim)
	if elegant:
		_build_cape(Color("542539"))
		Geometry.box(pivot,Vector3(0,1.60,0.1),Vector3(0.72,0.24,0.32),Color("26202a"))
		Geometry.box(pivot,Vector3(0,1.62,-0.26),Vector3(0.22,0.20,0.06),Color("e0c9a0"))
		Geometry.box(pivot,Vector3(0,1.68,-0.22),Vector3(0.23,0.13,0.07),Color("373231"))
		var torch := Node3D.new()
		carried_torch= torch
		pivot.add_child(torch)
		torch.position=Vector3(-0.5,1.15,-0.24)
		Geometry.beam(torch,Vector3(0,-0.35,0),Vector3(0,0.7,0),0.10,Color("594332"))
		Geometry.cylinder(torch,Vector3(0,0.65,0),0.15,0.26,Color("272c2d"),0.21,6)
		var fire := FireVisual.new()
		fire.position.y=0.77
		fire.flame_height=0.58
		fire.light_range=5
		fire.light_energy=0.8
		torch.add_child(fire)
	else:
		Geometry.cylinder(pivot,Vector3(0,1.9,0),0.25,0.20,iron,0.18,8)
		Geometry.box(pivot,Vector3(0,1.77,-0.23),Vector3(0.39,0.22,0.06),Color("302e29"))

func _build_bloodfang() -> void:
	var fur := Color("3d4241")
	var mane := Color("232c2d")
	var flesh := Color("79625a")
	Geometry.sphere(pivot,Vector3(0,1.55,0.08),Vector3(1.35,1.65,0.95),fur)
	Geometry.sphere(pivot,Vector3(0,2.19,-0.12),Vector3(1.60,1.05,1.18),mane)
	beast_head=Node3D.new()
	pivot.add_child(beast_head)
	beast_head.position=Vector3(0,2.5,-0.4)
	Geometry.sphere(beast_head,Vector3(0,0.16,-0.02),Vector3(0.91,0.95,0.91),fur)
	Geometry.box(beast_head,Vector3(0,-0.04,-0.59),Vector3(0.56,0.25,0.72),flesh)
	Geometry.sphere(beast_head,Vector3(0,0.02,-0.97),Vector3(0.4,0.24,0.2),Color("192324"))
	jaw=Node3D.new()
	beast_head.add_child(jaw)
	jaw.position=Vector3(0,-0.13,-0.35)
	Geometry.box(jaw,Vector3(0,-0.05,-0.32),Vector3(0.50,0.13,0.67),Color("611f26"))
	rage_light=OmniLight3D.new()
	rage_light.light_color=Color("b82323")
	rage_light.omni_range=4.5
	rage_light.position.y=1.7
	rage_light.light_energy=0
	pivot.add_child(rage_light)
	for side in [-1,1]:
		Geometry.cylinder(beast_head,Vector3(side*0.31,0.62,0.1),0.21,0.58,mane,0,5)
		var eye := Geometry.sphere(beast_head,Vector3(side*0.32,0.26,-0.44),Vector3(0.13,0.08,0.09),Color("e86435"))
		eye.material_override=Geometry.material(Color("e86435"),1.2)
		for z in [-1.28,-1.02]:
			var fang := Geometry.cylinder(beast_head,Vector3(side*0.23,-0.20,z+0.4),0.055,0.25,Color("d9ccb0"),0,5)
			fang.rotation.x=PI
		var arm := Node3D.new()
		pivot.add_child(arm)
		arm.position=Vector3(side*0.80,2.16,-0.08)
		Geometry.beam(arm,Vector3.ZERO,Vector3(side*0.22,-0.79,-0.08),0.36,fur)
		Geometry.sphere(arm,Vector3(side*0.24,-0.94,-0.21),Vector3(0.48,0.43,0.56),flesh)
		for i in range(3):
			Geometry.beam(arm,Vector3(side*0.24-0.13+i*0.13,-0.98,-0.39),Vector3(side*0.24-0.13+i*0.13,-1.21,-0.66),0.055,Color("d6c5a5"))
		fists.append(arm)
		var leg := Node3D.new()
		pivot.add_child(leg)
		leg.position=Vector3(side*0.39,0.93,0.04)
		Geometry.beam(leg,Vector3.ZERO,Vector3(0,-0.45,0.24),0.31,fur)
		Geometry.beam(leg,Vector3(0,-0.45,0.24),Vector3(0,-0.79,-0.04),0.19,fur)
		Geometry.box(leg,Vector3(0,-0.84,-0.23),Vector3(0.38,0.22,0.62),flesh)
		for i in range(3):
			Geometry.beam(leg,Vector3(-0.12+i*0.12,-0.84,-0.42),Vector3(-0.12+i*0.12,-0.90,-0.66),0.045,Color("d6c5a5"))
		legs.append(leg)
	for i in range(5):
		var spine := Geometry.cylinder(pivot,Vector3(0,2.36-i*0.19,0.43),0.16,0.50,mane,0,4)
		spine.rotation.x=0.9
	Geometry.box(pivot,Vector3(0,1.07,0),Vector3(0.92,0.27,0.72),Color("3f292b"))

func _build_wolf() -> void:
	var fur := Color("747d77")
	Geometry.sphere(pivot,Vector3(0,0.74,0),Vector3(0.75,0.9,1.65),fur)
	Geometry.sphere(pivot,Vector3(0,1.02,-0.64),Vector3(0.83,1.00,0.9),Color("444f4b"))
	Geometry.sphere(pivot,Vector3(0,1.08,-1.02),Vector3(0.56,0.58,0.71),fur)
	Geometry.box(pivot,Vector3(0,0.94,-1.35),Vector3(0.28,0.24,0.44),Color("363c3b"))
	for side in [-1,1]:
		Geometry.cylinder(pivot,Vector3(side*0.20,1.42,-0.95),0.15,0.45,Color("47534d"),0,5)
		Geometry.sphere(pivot,Vector3(side*0.235,1.14,-1.19),Vector3(0.055,0.065,0.10),Color("e6b362"))
		for z in [-0.49,0.52]:
			var leg := Node3D.new()
			pivot.add_child(leg)
			leg.position=Vector3(side*0.26,0.63,z)
			Geometry.beam(leg,Vector3.ZERO,Vector3(0,-0.5,0.13),0.17,fur)
			Geometry.box(leg,Vector3(0,-0.54,-0.02),Vector3(0.22,0.17,0.34),Color("343e39"))
			legs.append(leg)
	var tail := Geometry.cylinder(pivot,Vector3(0,0.80,1.02),0.18,0.9,Color("3c4842"),0.06,6)
	tail.rotation_degrees.x=60

func attack_started(_direction: Vector3, duration: float) -> void:
	windup_duration=duration
	swing=duration+0.20

func _build_brutus() -> void:
	var skin := Color("ad8264")
	var grubby := Color("5e5540")
	Geometry.sphere(pivot,Vector3(0,1.02,0.02),Vector3(1.48,1.37,1.0),grubby)
	Geometry.sphere(pivot,Vector3(0,1.04,-0.18),Vector3(1.23,0.96,0.94),skin.darkened(0.08))
	Geometry.box(pivot,Vector3(0,0.69,-0.39),Vector3(1.05,0.16,0.16),Color("362a22"))
	Geometry.box(pivot,Vector3(0,0.69,-0.49),Vector3(0.18,0.16,0.04),Color("887449"))
	Geometry.sphere(pivot,Vector3(0,1.9,-0.08),Vector3(0.63,0.65,0.59),skin)
	Geometry.sphere(pivot,Vector3(0,1.65,-0.31),Vector3(0.66,0.52,0.39),Color("302923"))
	for side in [-1,1]:
		Geometry.sphere(pivot,Vector3(side*0.24,2.0,-0.03),Vector3(0.24,0.35,0.48),Color("302923"))
		var brow := Geometry.box(pivot,Vector3(side*0.14,1.99,-0.36),Vector3(0.2,0.065,0.085),Color("352a24"))
		brow.rotation.z = side*0.22
		Geometry.sphere(pivot,Vector3(side*0.14,1.92,-0.38),Vector3(0.055,0.045,0.04),Color("ead4ad"))
		var arm := Node3D.new()
		pivot.add_child(arm)
		arm.position = Vector3(side*0.7,1.49,0)
		Geometry.sphere(arm,Vector3(0,-0.2,-0.09),Vector3(0.45,0.73,0.45),skin)
		Geometry.sphere(arm,Vector3(0,-0.5,-0.32),Vector3(0.43,0.4,0.45),skin.darkened(0.12))
		for i in range(3): Geometry.box(arm,Vector3(-0.13+i*0.13,-0.48,-0.54),Vector3(0.11,0.13,0.06),skin.lightened(0.04))
		fists.append(arm)
		var leg := Node3D.new()
		pivot.add_child(leg)
		leg.position = Vector3(side*0.36,0.58,0)
		Geometry.box(leg,Vector3(0,-0.14,0),Vector3(0.36,0.6,0.38),Color("413c31"))
		Geometry.box(leg,Vector3(0,-0.43,-0.1),Vector3(0.4,0.27,0.61),Color("312b25"))
		legs.append(leg)
	for p in [Vector3(-0.42,1.2,-0.45),Vector3(0.23,0.94,-0.62),Vector3(0.42,1.48,-0.36)]:
		Geometry.sphere(pivot,p,Vector3(0.21,0.15,0.045),Color("62513a"))

func _build_lord() -> void:
	var robe := Color("314d58")
	Geometry.cylinder(pivot,Vector3(0,0.65,0),0.49,1.22,robe,0.3,8)
	Geometry.box(pivot,Vector3(0,1.32,0),Vector3(0.73,0.62,0.42),robe)
	Geometry.box(pivot,Vector3(0,0.85,-0.39),Vector3(0.13,1.37,0.055),Color("a88a55"))
	Geometry.sphere(pivot,Vector3(0,1.91,0),Vector3(0.51,0.59,0.49),Color("b9a083"))
	Geometry.sphere(pivot,Vector3(0,2.05,0.1),Vector3(0.56,0.35,0.45),Color("77756b"))
	Geometry.sphere(pivot,Vector3(0,1.74,-0.2),Vector3(0.35,0.26,0.2),Color("898779"))
	_build_cape(Color("543646"))
	for side in [-1,1]:
		Geometry.beam(pivot,Vector3(side*0.4,1.52,0),Vector3(side*0.53,0.96,-0.08),0.23,robe)
		Geometry.sphere(pivot,Vector3(side*0.54,0.9,-0.09),Vector3(0.16,0.23,0.16),Color("b9a083"))
		Geometry.box(pivot,Vector3(side*0.2,0.11,-0.1),Vector3(0.24,0.19,0.4),Color("392e28"))
	Geometry.sphere(pivot,Vector3(0,1.49,-0.25),Vector3(0.18,0.18,0.06),Color("b99a55"))

func hit() -> void:
	flash=0.15

func special_started(kind: String, duration: float) -> void:
	special_kind = kind
	special_duration = duration
	special_left = duration + 0.3
	if kind == "cleave": attack_started(Vector3.FORWARD, duration)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or pivot == null:
		return
	phase += delta * 10
	pivot.position.y=abs(sin(phase))*0.035 if moving else sin(phase*0.18)*0.012
	for i in range(legs.size()):
		legs[i].rotation.x=sin(phase+float(i%2)*PI)*0.45 if moving else 0.0
		if style in ["marsh_widow","broodqueen"]:
			legs[i].rotation.x *= 0.40
			legs[i].rotation.y = sin(phase+i*PI*0.75)*0.16 if moving else 0.0
	if style == "crocodile":
		pivot.get_node("Snout").rotation.x = -0.35*sin(clampf(swing/(windup_duration+0.2),0,1)*PI)
	swing=maxf(0,swing-delta)
	flash=maxf(0,flash-delta)
	telegraph.visible=swing>0.2 and style!="npc"
	slash.visible=swing>0 and swing<0.16 and style!="archer" and style!="npc"
	if weapon:
		weapon.rotation.y=lerpf(-1.0,0.35,clampf((swing-0.2)/maxf(0.01,windup_duration),0,1)) if swing>0.2 else lerpf(1.3,-1.0,swing/0.2)
		if swing<=0:
			weapon.rotation.y=0
	pivot.rotation.x=-0.12 if flash>0 else 0.0
	for i in range(fists.size()):
		fists[i].rotation.x = (-0.7 + sin(phase*2.4+i*PI)*0.9) if raging else (-1.3*sin(clampf(1.0-swing/(windup_duration+0.2),0,1)*PI) if swing>0 else 0.0)
	if raging:
		pivot.rotation.z = sin(phase*1.5)*0.09
		pivot.rotation.x = 0.2
	elif style in ["brutus","bloodfang"]: pivot.rotation.z = 0
	if feeding:
		pivot.rotation.x=0.75+sin(phase*1.9)*0.10
		pivot.position.y=-0.42
	if beast_head:
		beast_head.rotation.y=sin(phase*2.7)*0.65 if raging else 0.0
		beast_head.rotation.x=0.22 if feeding else 0.0
		jaw.rotation.x=(0.35+sin(phase*3.1)*0.3) if raging or feeding else (0.5 if swing>0 else 0.08)
		rage_light.light_energy=1.3+sin(phase*2)*0.3 if raging else 0.0
	special_left = maxf(0, special_left - delta)
	if weapon: weapon.rotation.x = 0
	if carried_torch: carried_torch.rotation.x=0
	if special_left > 0:
		telegraph.visible = false
		if special_kind == "web":
			pivot.rotation.x = -0.25
			for i in [0,4]:
				if legs.size() > i: legs[i].rotation.x = -0.75
		if special_kind == "cleave" and weapon:
			weapon.rotation.x = 1.15 if special_left > 0.3 else lerpf(-0.55, 1.15, special_left / 0.3)
			if special_left > 0.3: weapon.rotation.y = 0
			pivot.rotation.x = -0.12 if special_left > 0.3 else 0.22
		elif special_kind == "kick" and not legs.is_empty():
			legs[0].rotation.x = 1.3 * sin(PI * clampf(1.0 - special_left / (special_duration + 0.3), 0, 1))
		elif special_kind == "howl":
			pivot.rotation.x=-0.4
			if beast_head: beast_head.rotation.x=-0.5
			for arm in fists: arm.rotation.x=-1.7
		elif special_kind == "lunge":
			pivot.rotation.x=0.5
			pivot.position.y=-0.35
		elif special_kind == "fury":
			pivot.rotation.z=sin(phase*3)*0.13
		elif special_kind == "fire" and weapon:
			if carried_torch: carried_torch.rotation.x=-1.1 if special_left>0.3 else 0.65

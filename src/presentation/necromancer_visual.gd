@tool
class_name NecromancerVisual
extends Node3D
var body: Node3D
var arms: Array[Node3D] = []
var shards: Array[Node3D] = []
var phase: float = 0.0
var channeling: bool = true
var spell: bool = false
var spell_color: Color = Color("b187bf")
var spell_light: OmniLight3D

func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	var black := Color("171720")
	var violet := Color("30273b")
	var bronze := Color("9a876c")
	Geometry.cylinder(body,Vector3(0,1.15,0),0.78,2.15,black,0.30,9)
	for i in range(9):
		var a := i*TAU/9
		var robe := Geometry.beam(body,Vector3(sin(a)*0.33,2.13,cos(a)*0.33),Vector3(sin(a)*0.86,0.11+(i%2)*0.12,cos(a)*0.86),0.12,violet if i%2 else black.lightened(0.03))
		robe.scale.x = 1.6
	Geometry.box(body,Vector3(0,1.48,-0.52),Vector3(0.12,1.47,0.045),bronze)
	Geometry.cylinder(body,Vector3(0,2.03,0),0.47,0.61,black,0.6,7)
	Geometry.sphere(body,Vector3(0,2.75,0),Vector3(0.8,0.93,0.77),violet)
	Geometry.sphere(body,Vector3(0,2.70,-0.33),Vector3(0.48,0.54,0.12),Color("080e14"))
	for side in [-1,1]:
		var eye := Geometry.box(body,Vector3(side*0.12,2.77,-0.397),Vector3(0.10,0.035,0.024),Color("adc4b0"))
		eye.material_override = Geometry.material(Color("87c4ad"),2)
		Geometry.beam(body,Vector3(side*0.24,2.99,0),Vector3(side*0.37,3.54,0.08),0.095,bronze)
		Geometry.beam(body,Vector3(side*0.36,3.5,0.08),Vector3(side*0.13,3.36,0),0.045,bronze)
		Geometry.sphere(body,Vector3(side*0.62,2.19,0),Vector3(0.65,0.30,0.64),Color("3b3b42"))
		for i in range(3): Geometry.beam(body,Vector3(side*(0.48+i*0.11),2.30,0.12),Vector3(side*(0.66+i*0.18),2.72+i*0.10,0.26),0.07,bronze)
		var arm := Node3D.new()
		body.add_child(arm)
		arm.position = Vector3(side*0.59,2.12,0)
		Geometry.beam(arm,Vector3.ZERO,Vector3(side*0.40,-0.40,-0.24),0.27,violet)
		Geometry.beam(arm,Vector3(side*0.40,-0.40,-0.24),Vector3(side*0.52,-0.27,-0.75),0.21,black)
		Geometry.sphere(arm,Vector3(side*0.52,-0.23,-0.84),Vector3(0.19,0.24,0.32),Color("979b8a"))
		for j in range(3): Geometry.beam(arm,Vector3(side*0.5+j*0.05,-0.2,-0.86),Vector3(side*0.5+j*0.05,-0.19,-1.11),0.035,Color("aeb09b"))
		arms.append(arm)
	Geometry.beam(body,Vector3(1.23,0.35,-0.65),Vector3(1.23,3.02,-0.65),0.075,bronze)
	for side in [-1,1]: Geometry.beam(body,Vector3(1.23,2.94,-0.65),Vector3(1.23+side*0.27,3.46,-0.65),0.07,bronze)
	var jewel := Geometry.sphere(body,Vector3(1.23,3.30,-0.65),Vector3(0.31,0.48,0.31),Color("668e88"))
	jewel.material_override = Geometry.material(Color("669d91"),1.5)
	for i in range(7):
		var shard := Geometry.cylinder(self,Vector3.ZERO,0.09,0.48,Color("6b4d82"),0,4)
		shard.material_override = Geometry.material(Color("685281"),0.6)
		shards.append(shard)
	var light := OmniLight3D.new()
	light.position = Vector3(0,2.8,-0.5)
	light.light_color = Color("637aaf")
	light.light_energy = 1.2
	light.omni_range = 7
	add_child(light)
	spell_light=OmniLight3D.new()
	spell_light.position=Vector3(0,2.0,-1)
	spell_light.omni_range=4
	add_child(spell_light)

func _process(delta: float) -> void:
	spell_light.light_color=spell_color
	spell_light.light_energy=1.6 if spell else 0
	phase += delta
	body.position.y = 0.18+sin(phase*1.3)*0.10
	for i in range(arms.size()): arms[i].rotation.x = -0.65+sin(phase*1.5+i)*0.08 if channeling or spell else -0.1
	for i in range(shards.size()):
		var a := i*TAU/shards.size()+phase*0.35
		shards[i].position = Vector3(sin(a)*1.65,1.2+sin(a*2+phase)*0.65,cos(a)*1.65)
		shards[i].rotation = Vector3(0,a,0.45)

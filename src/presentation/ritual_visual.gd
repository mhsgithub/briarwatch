@tool
class_name RitualVisual
extends Node3D
var rings: Array[MeshInstance3D] = []
var motes: Array[MeshInstance3D] = []
var phase: float = 0
var energy: float = 1.0
var light: OmniLight3D
var voice: AudioStreamPlayer3D

func _ready() -> void:
	for i in range(4):
		var ring := Geometry.ring(self,2.0+i*0.85,Color("689686") if i%2 else Color("72588a"),0.045)
		ring.position.y = 0.07+i*0.009
		ring.material_override = Geometry.material(Color("557f74") if i%2 else Color("58406f"),1.2)
		rings.append(ring)
	for i in range(16):
		var a := i*TAU/16
		var p := Vector3(sin(a)*3.25,0.105,cos(a)*3.25)
		var glyph := Node3D.new()
		add_child(glyph)
		glyph.position = p
		glyph.rotation.y = a
		for ends in [[Vector3(-0.18,0,-0.25),Vector3(0.18,0,0.25)],[Vector3(0.18,0,-0.25),Vector3(-0.18,0,0.25)],[Vector3(-0.18,0,0),Vector3(0.18,0,0)]]:
			var stroke := Geometry.beam(glyph,ends[0],ends[1],0.034,Color("8dac8c"))
			stroke.material_override = Geometry.material(Color("729980"),0.8)
	for i in range(36):
		var mote := Geometry.sphere(self,Vector3.ZERO,Vector3(0.08,0.22,0.08),Color("87b79d"))
		mote.material_override = Geometry.material(Color("709d95"),1.5)
		motes.append(mote)
	for i in range(5):
		var arc := Geometry.ring(self,1.2+i*0.28,Color("63517f"),0.025)
		arc.position.y = 0.5+i*0.65
		arc.rotation.x = i*0.28
		arc.material_override = Geometry.material(Color("63517f"),0.8)
		rings.append(arc)
	light = OmniLight3D.new()
	light.position.y = 2.0
	light.light_color = Color("67999e")
	light.omni_range = 13
	add_child(light)
	if not Engine.is_editor_hint():
		voice = AudioStreamPlayer3D.new()
		var stream := AudioLibrary.sample("ritual_loop").duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()/2
		voice.stream = stream
		voice.volume_db = -23
		voice.unit_size = 6
		voice.max_distance = 25
		add_child(voice)
		voice.play()

func _process(delta: float) -> void:
	phase += delta
	visible = energy > 0.01
	light.light_energy = energy*(2.0+sin(phase*3)*0.3)
	if voice: voice.volume_db = -23 if energy > 0.01 else -80
	for i in range(rings.size()):
		rings[i].rotation.y += delta*(0.13 if i%2 else -0.19)*energy
		if i>3: rings[i].scale = Vector3.ONE*(0.94+sin(phase*1.3+i)*0.08)*maxf(0.01,energy)
	for i in range(motes.size()):
		var a := i*2.399+phase*(0.45+i%3*0.08)
		var height := fposmod(phase*0.5+i*0.13,4.5)
		var radius := 2.2-height*0.25
		motes[i].position = Vector3(sin(a)*radius,height+0.2,cos(a)*radius)
		motes[i].scale = Vector3(0.08,0.22,0.08)*energy

func _exit_tree() -> void:
	if is_instance_valid(voice): voice.stop()

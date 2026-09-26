class_name NecroticPatch
extends Node3D
## A stationary, timed magic hazard cast at Malrec's current position.
var duration: float = 5.0
var radius: float = 3.2
var tick_seconds: float = 1.0
var damage: float = 10.0
var source: Enemy
var remaining: float
var tick_left: float
var phase: float = 0.0
var bubbles: Array[MeshInstance3D] = []
var edge: MeshInstance3D
var light: OmniLight3D
var material: ShaderMaterial

func _ready() -> void:
	add_to_group("malrec_hazards")
	remaining=duration
	tick_left=tick_seconds
	var plane:=PlaneMesh.new()
	plane.size=Vector2.ONE*radius*2.15
	var surface:=MeshInstance3D.new()
	surface.mesh=plane
	surface.position.y=0.065
	surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/necrotic_patch.gdshader")
	surface.material_override=material
	add_child(surface)
	edge=Geometry.ring(self,radius,Color("6b437d"),0.055)
	edge.position.y=0.085
	edge.material_override=Geometry.material(Color("5e3a72"),0.7)
	for i in range(16):
		var shade:=Color("45615c") if i%4==0 else Color("443752")
		var mote:=Geometry.sphere(self,Vector3.ZERO,Vector3(0.25,0.15,0.25),shade)
		mote.material_override=Geometry.material(shade,0.35)
		bubbles.append(mote)
	light=OmniLight3D.new()
	light.position.y=0.5
	light.light_color=Color("76518c")
	light.light_energy=0.75
	light.omni_range=radius*1.8
	add_child(light)
	AudioLibrary.play_world(self,global_position,"malrec_dark_patch")

func _process(delta: float) -> void:
	phase+=delta
	var fade:=clampf(remaining/0.45,0,1)
	material.set_shader_parameter("fade",fade)
	edge.scale=Vector3.ONE*(0.97+sin(phase*5.0)*0.025)
	edge.transparency=1.0-fade
	light.light_energy=fade*(0.7+0.18*sin(phase*6.0))
	for i in range(bubbles.size()):
		var angle:=TAU*float(i)/float(bubbles.size())+phase*(0.1 if i%2 else -0.08)
		var distance:=radius*(0.20+0.57*float((i*7)%16)/15.0)
		var rise:=0.11+0.19*pow(maxf(0,sin(phase*3.5+i*1.7)),2)
		bubbles[i].position=Vector3(cos(angle)*distance,rise,sin(angle)*distance)
		bubbles[i].scale=Vector3.ONE*(0.55+0.4*maxf(0,sin(phase*3.5+i*1.7)))
		bubbles[i].transparency=1.0-fade

func _physics_process(delta: float) -> void:
	var active_delta:=minf(delta,remaining)
	remaining-=delta
	tick_left-=active_delta
	while tick_left<=0.00001:
		tick_left+=tick_seconds
		for player: Player in get_tree().get_nodes_in_group("player"):
			if player.dead or player.cinematic_locked: continue
			var distance:=Vector2(player.global_position.x-global_position.x,player.global_position.z-global_position.z).length()
			if distance>radius: continue
			var packet:=DamagePacket.new(damage,source,&"arcane")
			packet.attack_kind=&"magic"
			player.receive_damage(packet)
	if remaining<=0: queue_free()

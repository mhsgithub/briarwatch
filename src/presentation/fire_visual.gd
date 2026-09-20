@tool
class_name FireVisual
extends Node3D
## Reusable stylized fire, independent of camp props or future damage volumes.
@export var flame_height: float = 1.2
@export var light_energy: float = 2.0
@export var light_range: float = 7.0
@export var sound_enabled: bool = true
@export var embers_enabled: bool = true
var elapsed: float = 0
var phase: float = 0
var flames: Array[MeshInstance3D] = []
var light: OmniLight3D

func _ready() -> void:
	if not Engine.is_editor_hint() and sound_enabled: AudioLibrary.attach_fire(self)
	phase = fposmod(global_position.x * 0.71 + global_position.z * 0.43, TAU)
	for i in range(5):
		var flame := Geometry.cylinder(self,Vector3.ZERO,0.25 if i<3 else 0.15,1.0,Color("f08a35"),0,5)
		flame.material_override=Geometry.material(Color("f19a3e") if i<3 else Color("ffe7a1"),1.6)
		flame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flames.append(flame)
	light=OmniLight3D.new()
	light.position=Vector3(0,0.8,0)
	light.light_color=Color("ffb85f")
	light.omni_range=light_range
	add_child(light)
	if not embers_enabled:
		_animate()
		return
	var sparks:=CPUParticles3D.new()
	sparks.amount=20
	sparks.lifetime=2.1
	sparks.preprocess=1.0
	sparks.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius=0.28
	sparks.position=Vector3(0,0.5,0)
	sparks.direction=Vector3.UP
	sparks.spread=22
	sparks.gravity=Vector3(0.1,0.15,0.04)
	sparks.initial_velocity_min=0.65
	sparks.initial_velocity_max=1.45
	sparks.scale_amount_min=0.4
	sparks.scale_amount_max=1.0
	var ember:=SphereMesh.new()
	ember.radius=0.025
	ember.height=0.05
	ember.radial_segments=4
	ember.rings=2
	ember.material=Geometry.material(Color("ffc46b"),1.5)
	sparks.mesh=ember
	add_child(sparks)
	_animate()

func _process(delta: float) -> void:
	elapsed+=delta
	_animate()

func _animate() -> void:
	var time:=elapsed+phase
	for i in range(flames.size()):
		var height:=flame_height*(0.70+0.16*sin(time*4.7+i*1.8)+0.10*sin(time*7.1+i))
		var angle:=float(i)*TAU/5
		flames[i].position=Vector3(cos(angle)*0.23,height*0.5+0.18,sin(angle)*0.23)
		flames[i].scale=Vector3(0.85+0.18*sin(time*5+i),height,0.85)
		flames[i].rotation=Vector3(0.13*sin(time*3+i),angle,0.16*cos(time*4+i))
	if light:
		var pulse:=0.87+0.08*sin(time*5.3)+0.05*sin(time*11.7)
		light.light_energy=light_energy*pulse
		light.light_color=Color("ffad50").lerp(Color("ffd18a"),0.5+0.25*sin(time*3.1))

class_name TorchThrow
extends Node3D
## A thrown burning brand; Vane's carried torch remains in his other-hand pose.
var origin := Vector3.ZERO
var destination := Vector3.ZERO
var duration: float = 0.45
var elapsed: float = 0
var kit: DenBossDefinition
func _ready() -> void:
	Geometry.beam(self,Vector3(0,-0.3,0),Vector3(0,0.3,0),0.085,Color("69503a"))
	var flame := FireVisual.new()
	flame.position.y=0.3
	flame.flame_height=0.38
	flame.light_energy=0.5
	flame.light_range=3
	flame.sound_enabled=false
	flame.embers_enabled=false
	add_child(flame)
func _physics_process(delta: float) -> void:
	if is_queued_for_deletion(): return
	elapsed+=delta
	var t := clampf(elapsed/duration,0,1)
	global_position=origin.lerp(destination,t)+Vector3.UP*sin(t*PI)*1.7
	rotation.z=t*TAU*1.5
	if t<1: return
	var fire := GroundFire.new()
	fire.radius=kit.fire_radius
	fire.remaining=kit.fire_duration
	fire.damage=kit.fire_damage
	fire.interval=kit.fire_interval
	fire.tick_left=kit.fire_interval
	get_parent().add_child(fire)
	fire.global_position=destination
	AudioLibrary.play_world(get_parent(),destination,"fire_impact",0.9)
	queue_free()

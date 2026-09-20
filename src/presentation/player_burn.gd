class_name PlayerBurn
extends Node3D
var remaining: float = 0
func _ready() -> void:
	var flame := FireVisual.new()
	flame.flame_height=0.36
	flame.light_energy=0.16
	flame.light_range=2
	flame.sound_enabled=false
	flame.embers_enabled=false
	flame.scale=Vector3(0.65,0.8,0.65)
	flame.position=Vector3(0,0.22,0)
	add_child(flame)
	visible=false
func ignite() -> void:
	remaining=0.65
	visible=true
func clear() -> void:
	remaining=0
	visible=false
func _process(delta: float) -> void:
	remaining=maxf(0,remaining-delta)
	visible=remaining>0

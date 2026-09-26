class_name PlayerBurn
extends Node3D
var remaining: float = 0
var poison: Node3D
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
	poison=Node3D.new()
	get_parent().add_child.call_deferred(poison)
	for i in range(6):
		var a:=i*TAU/6
		var mote:=Geometry.sphere(poison,Vector3(sin(a)*0.43,0.4+i*0.17,cos(a)*0.43),Vector3(0.07,0.15,0.07),Color("82a852"))
		mote.material_override=Geometry.material(Color("668647"),0.5)
	poison.hide()
	visible=false
func ignite() -> void:
	remaining=0.65
	visible=true
func clear() -> void:
	remaining=0
	visible=false
func _process(delta: float) -> void:
	var player:=get_parent() as Player
	if player and player.statuses:
		if player.statuses.has("fire"): remaining=0.3
		poison.visible=player.statuses.has("poison") and not player.dead
		poison.rotation.y+=delta*1.5
	remaining=maxf(0,remaining-delta)
	visible=remaining>0

class_name StatusVisual
extends Node3D
var actor: Player
var web: Node3D
var poison: Node3D
var phase: float = 0
func _ready() -> void:
	actor = get_parent() as Player
	web = Node3D.new()
	add_child(web)
	for i in range(10):
		var angle := i*TAU/10
		var end := Vector3(cos(angle)*0.85,0.09,sin(angle)*0.85)
		Geometry.beam(web,Vector3(0,0.60,0),end,0.024,Color("bac4b0"))
	for radius in [0.35,0.62,0.84]: Geometry.ring(web,radius,Color("bac4b0"),0.015)
	poison = Node3D.new()
	add_child(poison)
	for i in range(5):
		var mote := Geometry.sphere(poison,Vector3.ZERO,Vector3.ONE*0.08,Color("8db746"))
		mote.material_override = Geometry.material(Color("8db746"),0.7)
func _process(delta: float) -> void:
	if not actor.statuses: return
	phase += delta
	web.visible = actor.statuses.has("root") and not actor.dead
	poison.visible = actor.statuses.has("poison") and not actor.dead
	for i in range(poison.get_child_count()):
		poison.get_child(i).position = Vector3(sin(phase+i)*0.35,fmod(phase*0.65+i*0.3,1.6),cos(phase+i)*0.35)

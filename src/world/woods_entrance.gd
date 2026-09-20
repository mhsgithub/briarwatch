@tool
extends Node3D
## A seeded, irregular forest edge. The approach stays open between dense groves.
@export var seed_value: int = 6173
@export var tree_count: int = 155
@export var forest_width: float = 42
@export var forest_depth: float = 27
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=seed_value
	var placed: Array[Vector3]=[]
	for attempt in range(tree_count*30):
		if placed.size()>=tree_count: break
		var point := Vector3(rng.randf_range(-forest_width*0.5,forest_width*0.5),0,rng.randf_range(-forest_depth+10,10))
		if absf(point.x)<3.8 and point.z>-3: continue
		if point.z>5 and rng.randf()<0.55: continue
		var clear := true
		for other in placed:
			if other.distance_to(point)<1.65:
				clear=false
				break
		if not clear: continue
		placed.append(point)
		var tree := DarkThicket.new()
		tree.length=0.9
		tree.width=0.9
		tree.seed_value=attempt+seed_value
		tree.position=point
		tree.rotation.y=rng.randf()*TAU
		var size_value := rng.randf_range(0.68,1.35)
		tree.scale=Vector3(size_value,rng.randf_range(0.8,1.3),size_value)
		add_child(tree)
	for side in [-1,1]:
		Geometry.sphere(self,Vector3(side*4.3,0.32,4.5),Vector3(1.3,0.9,1.0),Color("566057"))
		var stump := Geometry.cylinder(self,Vector3(side*4.1,0.7,4.5),0.24,1.4,Color("494138"),0.18,7)
		stump.rotation.z=side*0.13
		Geometry.sphere(self,Vector3(side*4.25,1.48,4.5),Vector3(0.34,0.4,0.32),Color("a8aa91"))

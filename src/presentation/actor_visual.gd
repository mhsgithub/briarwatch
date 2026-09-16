@tool
class_name ActorVisual
extends Node3D

@export_enum("warrior", "melee", "archer", "wolf", "npc") var style: String = "warrior"
@export var tint: Color = Color("527b7b")
var pivot: Node3D
var weapon: Node3D
var phase: float = 0
var moving: bool = false
var swing: float = 0
var flash: float = 0
var telegraph: Node3D

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	pivot = Node3D.new()
	add_child(pivot)
	if style == "wolf":
		Geometry.sphere(pivot, Vector3(0, 0.6, 0), Vector3(0.72, 0.7, 1.5), tint)
		Geometry.sphere(pivot, Vector3(0, 0.84, -0.72), Vector3(0.58, 0.56, 0.66), tint.lightened(0.12))
		Geometry.box(pivot, Vector3(0, 0.67, -1.07), Vector3(0.28, 0.25, 0.36), Color("38423f"))
		for x in [-0.22, 0.22]:
			Geometry.cylinder(pivot, Vector3(x, 1.14, -0.62), 0.15, 0.35, tint, 0)
			for z in [-0.43, 0.43]:
				Geometry.box(pivot, Vector3(x, 0.23, z), Vector3(0.15, 0.47, 0.17), tint.darkened(0.25))
		Geometry.box(pivot, Vector3(0, 0.62, 0.85), Vector3(0.18, 0.2, 0.6), tint)
	else:
		var metal := Color("9caeac") if style == "warrior" else Color("6e746b")
		for x in [-0.19, 0.19]:
			Geometry.box(pivot, Vector3(x, 0.34, 0), Vector3(0.25, 0.65, 0.3), Color("333b39"))
			Geometry.box(pivot, Vector3(x, 0.1, -0.11), Vector3(0.28, 0.2, 0.44), Color("292e2b"))
		Geometry.cylinder(pivot, Vector3(0, 0.88, 0), 0.4, 0.7, tint, 0.34, 6)
		Geometry.box(pivot, Vector3(0, 1.17, 0), Vector3(0.78, 0.22, 0.48), metal)
		Geometry.sphere(pivot, Vector3(0, 1.54, 0), Vector3(0.47, 0.49, 0.47), Color("b49c7b"))
		if style != "npc":
			Geometry.sphere(pivot, Vector3(0, 1.65, 0.025), Vector3(0.52, 0.42, 0.51), metal)
			Geometry.box(pivot, Vector3(0, 1.56, -0.245), Vector3(0.42, 0.08, 0.04), Color("273134"))
		Geometry.box(pivot, Vector3(0, 0.65, -0.26), Vector3(0.44, 0.62, 0.09), tint)
		Geometry.box(pivot, Vector3(-0.44, 1.0, 0), Vector3(0.22, 0.54, 0.24), tint)
		weapon = Node3D.new()
		pivot.add_child(weapon)
		weapon.position = Vector3(0.47, 1.0, -0.1)
		if style == "archer":
			var bow := Geometry.cylinder(weapon, Vector3(0, 0, -0.22), 0.42, 0.065, Color("c29962"), 0.4, 12)
			bow.rotation_degrees.x = 90
		elif style != "npc":
			Geometry.box(weapon, Vector3(0, 0, -0.58), Vector3(0.11, 0.09, 1.3), Color("c8d5cc"))
			Geometry.box(weapon, Vector3(0, 0, -0.08), Vector3(0.42, 0.13, 0.1), Color("be9d60"))
			Geometry.box(pivot, Vector3(-0.51, 0.98, -0.21), Vector3(0.13, 0.74, 0.6), metal)
			Geometry.box(pivot, Vector3(-0.59, 0.98, -0.21), Vector3(0.03, 0.5, 0.1), tint)
	telegraph = Node3D.new()
	add_child(telegraph)
	for i in range(9):
		var angle := deg_to_rad(-55 + i * 13.75)
		Geometry.box(telegraph, Vector3(sin(angle) * 1.4, 0.06, -cos(angle) * 1.4), Vector3(0.18, 0.03, 0.22), Color("edac60"))
	telegraph.visible = false

func attack_started(_direction: Vector3, duration: float) -> void:
	swing = duration + 0.2

func hit() -> void:
	flash = 0.15

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or pivot == null:
		return
	phase += delta * 10
	pivot.position.y = abs(sin(phase)) * 0.065 if moving else sin(phase * 0.2) * 0.015
	pivot.rotation.z = sin(phase) * 0.04 if moving else 0.0
	swing = maxf(0, swing - delta)
	flash = maxf(0, flash - delta)
	telegraph.visible = swing > 0.2
	if weapon:
		weapon.rotation.y = -sin(swing * 12) * 1.3 if swing > 0 else 0.0
	pivot.scale = Vector3.ONE * (1.06 if flash > 0 else 1.0)

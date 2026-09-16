class_name DamagePacket
extends RefCounted

var amount: float
var damage_type: StringName
var source: Node3D

func _init(value: float, origin: Node3D = null, kind: StringName = &"physical") -> void:
	amount = value
	source = origin
	damage_type = kind

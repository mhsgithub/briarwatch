class_name DamagePacket
extends RefCounted

var amount: float
var damage_type: StringName
var source: Node3D
var minimum_damage: float = 0.0
var bleed_damage: float = 0.0
var bleed_ticks: int = 0
var knockdown_seconds: float = 0.0
var stun_seconds: float = 0.0
var knockback: float = 0.0
var attack_kind: StringName = &"melee"
var accuracy: float = -1.0
var taken_multiplier: float = 1.0
var critical: bool = false
var critical_resolved: bool = false
var poison_damage: float = 0.0
var poison_seconds: float = 0.0

func _init(value: float, origin: Node3D = null, kind: StringName = &"physical", floor_damage: float = 0.0) -> void:
	amount = value
	source = origin
	damage_type = kind
	minimum_damage = maxf(0, floor_damage)

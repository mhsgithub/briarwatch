class_name HealthComponent
extends Node

signal changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

var maximum: float = 100.0
var current: float = 100.0
var armor: float = 0.0
var invulnerable: bool = false

func configure(hp: float, defense: float = 0.0) -> void:
	maximum = maxf(1, hp)
	armor = maxf(0, defense)
	current = maximum
	changed.emit(current, maximum)

func receive(packet: DamagePacket) -> void:
	if current <= 0 or invulnerable:
		return
	var defense := armor if packet.damage_type in [&"physical", &"melee", &"ranged"] else 0.0
	var dealt := maxf(packet.minimum_damage, (packet.amount - defense) * packet.taken_multiplier)
	if dealt <= 0:
		return
	current = maxf(0, current - dealt)
	damaged.emit(dealt)
	changed.emit(current, maximum)
	if current <= 0:
		died.emit()

func heal(amount: float) -> void:
	if current <= 0:
		return
	current = minf(maximum, current + amount)
	changed.emit(current, maximum)

func revive() -> void:
	current = maximum
	changed.emit(current, maximum)

func set_maximum(value: float) -> void:
	maximum = maxf(1, value)
	current = minf(current, maximum)
	changed.emit(current, maximum)

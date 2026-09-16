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
	var dealt := maxf(1, packet.amount - armor)
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

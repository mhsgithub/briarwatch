class_name AttackDefinition
extends Resource

@export var id: StringName
@export_range(0, 100) var damage: float = 10.0
@export_range(0.1, 20) var reach: float = 2.2
@export_range(0.05, 3) var windup: float = 0.3
@export_range(0.1, 5) var cooldown: float = 1.0
@export_range(10, 180) var arc_degrees: float = 100.0
@export var damage_type: StringName = &"physical"
@export var projectile: bool = false
@export var projectile_speed: float = 17.0
@export var bleed_damage: float = 0.0
@export var bleed_ticks: int = 0
@export_range(0, 1) var bleed_chance: float = 1.0
@export var knockdown_seconds: float = 0.0
## Forward movement during a targeted melee windup; stand attacks never advance.
@export_range(0, 10) var advance_speed: float = 0.0

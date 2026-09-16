class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_enum("melee", "archer", "wolf") var behavior: String = "melee"
@export var max_health: float = 40.0
@export var armor: float = 0.0
@export var move_speed: float = 3.5
@export var aggro_radius: float = 11.0
@export var leash_radius: float = 19.0
@export var preferred_range: float = 7.0
@export var attack: AttackDefinition
@export var gold_min: int = 2
@export var gold_max: int = 5
@export var loot: Array[LootEntry] = []
@export var tint: Color = Color("965848")

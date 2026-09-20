class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_enum("melee", "archer", "wolf") var behavior: String = "melee"
@export var max_health: float = 40.0
@export var armor: float = 0.0
@export var move_speed: float = 2.8
@export_range(0.0, 1.0) var hit_chance: float = 1.0
@export_enum("bandit", "wolf") var audio_profile: String = "bandit"
@export var aggro_radius: float = 11.0
@export var leash_radius: float = 23.0
@export var preferred_range: float = 7.0
@export var retreat_seconds: float = 0.65
@export var stand_seconds: float = 2.4
@export var commander: CommanderDefinition
@export var visual_scale: float = 1.0
@export var attack: AttackDefinition
@export var loot_table: LootTable
@export var tint: Color = Color("965848")
@export var experience: int = 0
@export var is_boss: bool = false
@export var brute: BruteDefinition
@export var appearance: String = ""
@export var den_boss: DenBossDefinition
@export var edible_corpse: bool = false
@export var collision_radius: float = 0.4
@export var collision_height: float = 1.7
@export var voice_pitch: float = 1.0

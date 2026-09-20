class_name DenBossDefinition
extends Resource
## Immutable encounter tuning; actor-owned DenBossCombat holds timers.
@export_enum("garrick", "bloodfang") var role: String = "garrick"
@export var fire_cooldown := Vector2(5,10)
@export var fire_radius: float = 2.7
@export var fire_duration: float = 40
@export var fire_damage: float = 20
@export var fire_interval: float = 0.5
@export var release_threshold: float = 0.25
@export var sprint_speed: float = 7.5
@export var howl_thresholds := PackedFloat32Array([0.66,0.33])
@export var summoned_enemy: EnemyDefinition
@export var fury_cooldown: float = 20
@export var fury_duration: float = 4
@export var fury_windup: float = 1.2
@export_multiline var encounter_dialogue: String = "Kasparov should have died beneath Warwick. Now watch what I bring to his gates."
@export_multiline var release_dialogue: String = "Come, Bloodfang! Let Briar learn to fear the dark!"
@export var fury_radius: float = 2.7
@export var fury_bleed_damage: float = 12
@export var fury_bleed_ticks: int = 5
@export var feeding_heal: float = 15
@export var feeding_seconds: int = 3
@export var lunge_cooldown := Vector2(7,11)
@export var lunge_speed: float = 15
@export var lunge_seconds: float = 0.45
@export var lunge_knockback: float = 4

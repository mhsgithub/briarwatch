class_name MalrecDefinition
extends Resource
@export var bolt_damage: float = 25
@export var bolt_speed: float = 23
@export var cast_seconds: float = 0.55
@export var bolt_cooldown: float = 0.65
@export var affliction_damage: float = 2
@export var affliction_seconds: float = 3
@export var teleport_cooldown: float = 14
@export_range(1, 4, 1) var post_ritual_bolt_count: int = 2
@export_range(0.0, 30.0, 0.5) var post_ritual_cone_degrees: float = 6.0
@export var dark_patch_first_delay: Vector2 = Vector2(5.0, 8.0)
@export var dark_patch_cooldown: Vector2 = Vector2(12.0, 17.0)
@export var dark_patch_duration: float = 5.0
@export var dark_patch_radius: float = 3.2
@export var dark_patch_tick: float = 1.0
@export var dark_patch_damage: float = 10.0
@export var meteor_interval: float = 0.6
@export var meteor_warning: float = 1.15
@export var meteor_damage: float = 40
@export var meteor_radius: float = 1.8
@export var ritual_threshold: float = 0.4
@export var ritual_seconds: float = 60
@export var summon_interval: float = 9
@export var cultist: EnemyDefinition
@export var zombie: EnemyDefinition
@export var spider: EnemyDefinition
@export_multiline var dialogue: String = "Corvin was expected. So were you. Did you think the dead chose those roads? She has already crossed the water. Kill me, and you will only silence the last man who remembers what she was."

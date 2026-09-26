class_name CommanderDefinition
extends Resource
## Optional ability kit; ordinary enemies do not inherit boss moves.
@export var cleave: AttackDefinition
@export var kick: AttackDefinition
@export var cleave_cooldown := Vector2(7, 10)
@export var kick_cooldown := Vector2(9, 13)
@export var warning_color: Color = Color(0.85, 0.25, 0.08, 0.38)
@export var warning_cue: String = "boss_roar"
@export var release_cue: String = "heavy_cleave"
@export var voice_pitch: float = 0.74

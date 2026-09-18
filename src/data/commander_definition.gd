class_name CommanderDefinition
extends Resource
## Optional ability kit; ordinary enemies do not inherit boss moves.
@export var cleave: AttackDefinition
@export var kick: AttackDefinition
@export var cleave_cooldown := Vector2(7, 10)
@export var kick_cooldown := Vector2(9, 13)

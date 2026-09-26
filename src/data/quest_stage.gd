class_name QuestStage
extends Resource
## Ordered investigation objectives. IDs are stable across save migrations.
@export var id: StringName
@export_multiline var objective: String
@export var region: StringName
@export var target_path: NodePath
@export var label: String

class_name QuestDefinition
extends Resource

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var target_encounter: StringName
@export var reward_gold: int = 50
@export var reward_item: ItemDefinition

class_name QuestDefinition
extends Resource

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var target_encounter: StringName
@export var required_item: StringName
@export var target_region: StringName
@export var objective: String
@export var completion_text: String
@export var reward_gold: int = 50
@export var reward_item: ItemDefinition
@export var next_quest: QuestDefinition
@export var handin_region: StringName = &"briar_march"
@export var handin_npc: String = "elric"
@export var return_objective: String = "Bring the cellar key to Warden Elric."
@export var entrance_label: String = "Enter the watchtower"
@export var accept_text: String = "I will find Crowbane's key"
@export_multiline var offer_dialogue: String

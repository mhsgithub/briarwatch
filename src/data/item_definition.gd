class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_enum("weapon", "shield", "body", "consumable") var slot: String = "weapon"
@export var price: int = 10
@export var damage_bonus: float = 0.0
@export var armor_bonus: float = 0.0
@export var heal_amount: float = 0.0
@export var tint: Color = Color("b5c0bd")

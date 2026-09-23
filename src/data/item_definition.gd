class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_enum("weapon", "shield", "body", "head", "shoulders", "gloves", "belt", "boots", "amulet", "ring", "consumable", "quest") var slot: String = "weapon"
@export var icon: Texture2D
@export_range(-1, 31) var icon_index: int = -1
@export var price: int = 10
@export var sell_price: int = 2
@export_enum("white", "green", "blue", "legendary") var tier: String = "white"
@export var vitality_bonus: float = 0.0
@export var strength_bonus: float = 0.0
@export var crit_rating: float = 0.0
## Percentage points, additive with other equipment and movement talents.
@export var movement_bonus: float = 0.0
@export_range(0.1, 5) var swing_seconds: float = 0.8
@export var two_handed: bool = false
## Shared presentation vocabulary, not gameplay behavior.
@export_enum("plain", "quilted", "mail", "leather", "reinforced", "hood", "helmet", "sword", "bloodclaw", "pitchfork", "oak", "iron", "amulet", "cleaver", "greatblade", "polearm") var appearance: String = "plain"
@export_range(0.1, 30) var heal_seconds: float = 5.0
@export var damage_bonus: float = 0.0
@export var armor_bonus: float = 0.0
@export var heal_amount: float = 0.0
@export var tint: Color = Color("b5c0bd")

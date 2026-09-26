class_name NpcDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var title: String
@export_enum("vendor", "healer", "warden", "rescue", "trainer", "companion") var service: String = "vendor"
@export_multiline var greeting: String
@export var stock: Array[ItemDefinition] = []
@export var tint: Color = Color("728985")
@export var appearance: String = "npc"

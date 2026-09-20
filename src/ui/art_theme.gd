class_name ArtTheme
extends RefCounted
const INK := Color("11191a")
const PANEL := Color("172021")
const GOLD := Color("c2a36b")
const PALE := Color("e4d8be")
const MUTED := Color("8f9a91")
static var heading_font: SystemFont
static var atlas: Texture2D = preload("res://assets/ui/equipment_atlas.png")
static var field_atlas: Texture2D = preload("res://assets/ui/field_gear_atlas.png")
static var icon_cache: Dictionary = {}

static func serif() -> Font:
	if heading_font == null:
		heading_font = SystemFont.new()
		heading_font.font_names = PackedStringArray(["Georgia", "Noto Serif", "serif"])
	return heading_font

static func icon(index: int) -> Texture2D:
	if not icon_cache.has(index):
		var texture := AtlasTexture.new()
		texture.atlas = field_atlas if index >= 16 else atlas
		var cell := texture.atlas.get_width() / 4.0
		var local_index := index % 16
		texture.region = Rect2(Vector2(local_index % 4, local_index / 4) * cell, Vector2.ONE * cell)
		texture.filter_clip = true
		icon_cache[index] = texture
	return icon_cache[index]

static func item_icon(item: ItemDefinition) -> Texture2D:
	if item.icon:
		return item.icon
	if item.icon_index >= 0:
		return icon(item.icon_index)
	for slot in EquipmentSlots.DEFINITIONS:
		if slot.category == item.slot:
			return icon(slot.icon)
	return icon(3)

static func label(text: String, size_value: int = 16, color: Color = PALE, heading: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_color_override("font_color",color)
	result.add_theme_font_size_override("font_size",size_value)
	if heading:
		result.add_theme_font_override("font",serif())
	return result

static func box(color: Color = PANEL, border: Color = Color("5d5946"), margin: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1)
	style.content_margin_left=margin
	style.content_margin_right=margin
	style.content_margin_top=margin
	style.content_margin_bottom=margin
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size=16
	result.set_color("font_color","Label",PALE)
	result.set_color("font_color","Button",PALE)
	result.set_color("font_disabled_color","Button",Color("737b74"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var color := Color("25332f") if state=="hover" else Color("192322")
		var border := GOLD if state in ["hover","focus"] else Color("5e5946")
		if state=="pressed":
			color=Color("3b4133")
		if state=="disabled":
			color=Color("131c1d")
		result.set_stylebox(state,"Button",box(color,border,10))
	result.set_stylebox("panel","PanelContainer",box(INK,Color("867048"),40))
	result.set_stylebox("panel","TooltipPanel",box(Color("0e1617"),GOLD,14))
	result.set_color("font_color","TooltipLabel",PALE)
	result.set_font_size("font_size","TooltipLabel",16)
	return result
static func tier_color(item: ItemDefinition) -> Color:
	match item.tier:
		"green": return Color("78c684")
		"blue": return Color("79aff0")
		"legendary": return Color("f39c4e")
	return Color("eeeae1")

static func item_properties(item: ItemDefinition) -> String:
	var lines: Array[String] = []
	if item.slot == "weapon":
		lines.append("+%d melee damage  ·  %.1f s / swing" % [item.damage_bonus,item.swing_seconds])
	if item.armor_bonus > 0: lines.append("+%d armor" % item.armor_bonus)
	if item.vitality_bonus > 0: lines.append("+%d vitality" % item.vitality_bonus)
	if item.strength_bonus > 0: lines.append("+%d strength" % item.strength_bonus)
	if item.heal_amount > 0: lines.append("Restores %d vitality over %.0f seconds" % [item.heal_amount,item.heal_seconds])
	if item.two_handed: lines.append("Two-handed · Main & off hand")
	return "\n".join(lines)

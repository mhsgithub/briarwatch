class_name GoldAmount
extends HBoxContainer
## Consistent currency icon + amount in HUD, pack, trading and rewards.
var amount: int = 0:
	set(value):
		amount = value
		if is_instance_valid(number):
			number.text = str(amount)
var number: Label
var font_size: int = 17

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 5)
	var coin := TextureRect.new()
	coin.texture = ArtTheme.icon(15)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(24, 24)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	number = ArtTheme.label(str(amount), font_size, ArtTheme.GOLD, true)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(number)
	tooltip_text = "Gold"

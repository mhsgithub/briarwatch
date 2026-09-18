class_name OrnatePanel
extends PanelContainer
## Painted border over an opaque enamel interior; visual margins are independent of art resolution.
static var frame_style: StyleBoxTexture

func _ready() -> void:
	if frame_style==null:
		var source: Texture2D=preload("res://assets/ui/panel_frame.png")
		var texture:=ImageTexture.create_from_image(source.get_image())
		texture.set_size_override(Vector2i(source.get_width()/2,source.get_height()/2))
		frame_style=StyleBoxTexture.new()
		frame_style.texture=texture
		frame_style.texture_margin_left=52
		frame_style.texture_margin_right=52
		frame_style.texture_margin_top=42
		frame_style.texture_margin_bottom=42

func _draw() -> void:
	if frame_style:
		draw_style_box(frame_style,Rect2(Vector2.ZERO,size))

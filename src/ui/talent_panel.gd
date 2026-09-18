class_name TalentPanel
extends VBoxContainer
var player: Player
var tree_name: String = "Battle Mastery"
var selected_id: String = "block"
var layout: HBoxContainer
var info: VBoxContainer
var points_label: Label
func _ready() -> void:
	add_theme_constant_override("separation",12)
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for title: String in ["Battle Mastery","Pathfinder"]:
		var button := Button.new()
		button.text = title.to_upper()
		button.custom_minimum_size = Vector2(245,38)
		button.toggle_mode=true
		button.button_pressed=title==tree_name
		button.name=title
		button.pressed.connect(func():
			tree_name = title
			selected_id = "block" if title == "Battle Mastery" else "momentum"
			rebuild())
		tabs.add_child(button)
	points_label = ArtTheme.label("",15,ArtTheme.GOLD)
	add_child(points_label)
	layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation",26)
	add_child(layout)
	player.progression.changed.connect(rebuild)
	rebuild()
func rebuild() -> void:
	for button: Button in get_child(0).get_children():
		button.button_pressed=str(button.name)==tree_name
	for child in layout.get_children():
		layout.remove_child(child)
		child.queue_free()
	points_label.text = "LEVEL %d   /   %d UNSPENT TALENT POINTS" % [player.progression.level,player.progression.points()]
	var tree := TalentTree.new()
	tree.progression = player.progression
	tree.tree_name = tree_name
	tree.selected_id = selected_id
	tree.selected.connect(func(id: String): selected_id=id; rebuild())
	layout.add_child(tree)
	info = VBoxContainer.new()
	info.custom_minimum_size.x = 320
	info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation",9)
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(350,438)
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	scroll.add_child(info)
	details()
func line(value: String, size_value: int = 16, color: Color = ArtTheme.PALE) -> void:
	var label := ArtTheme.label(value,size_value,color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(label)
func details() -> void:
	for child in info.get_children():
		info.remove_child(child)
		child.queue_free()
	var data := CenturionTalents.find(selected_id)
	var icon := TextureRect.new()
	icon.texture = CenturionTalents.icon(int(data.icon))
	icon.custom_minimum_size = Vector2(68,68)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info.add_child(icon)
	line(data.name,25,ArtTheme.GOLD)
	line("%s · Rank %d / %d" % ["ACTIVE" if data.active else "PASSIVE",player.progression.rank(selected_id),int(data.max_rank)],13,ArtTheme.MUTED)
	line(data.description)
	if float(data.cooldown)>0: line("Cooldown: %d seconds" % int(data.cooldown),14,ArtTheme.GOLD)
	var parents: PackedStringArray = []
	for parent: String in data.parents:
		var prerequisite := CenturionTalents.find(parent)
		parents.append("%s %d/%d" % [prerequisite.name,int(prerequisite.max_rank),int(prerequisite.max_rank)])
	line("Requires: "+("nothing" if parents.is_empty() else " + ".join(parents)),13,ArtTheme.MUTED)
	var learn := Button.new()
	learn.text = "Spend 1 point" if player.progression.rank(selected_id)<int(data.max_rank) else "Mastered"
	learn.disabled = not player.progression.available(selected_id)
	learn.pressed.connect(func():
		if player.progression.learn(selected_id): AudioLibrary.play_ui(self,"talent_learn"))
	info.add_child(learn)
	if data.active and player.progression.rank(selected_id)>0:
		line("ASSIGN TO BELT · OR DRAG ICON",11,ArtTheme.GOLD)
		var slots := HBoxContainer.new()
		info.add_child(slots)
		for i in range(6):
			var button := Button.new()
			button.text = str(i+1)
			button.custom_minimum_size.x = 44
			button.pressed.connect(func(): player.actions.assign_ability(i,selected_id))
			slots.add_child(button)

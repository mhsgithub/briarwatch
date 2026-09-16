extends Node
## Composition root and lifecycle coordinator. Mechanics live in child components.
@export var catalog: ContentCatalog
@onready var region: Region = $Region
@onready var player: Player = $Player
@onready var quest: QuestLog = $QuestLog
@onready var hud: GameHUD = $HUD
var testing: bool = false
var initialized: bool = false
var save_pending: bool = false

func _ready() -> void:
	testing = "--test" in OS.get_cmdline_user_args()
	get_tree().auto_accept_quit = false
	quest.definition = catalog.quest
	player.camera = $Camera
	$Camera.target = player
	player.global_position = region.player_spawn.global_position
	hud.bind(player, quest)
	hud.mini_map.bind_region(region)
	hud.large_map.bind_region(region)
	player.interaction_requested.connect(_interact)
	player.feedback.connect(hud.toast)
	player.died.connect(_on_player_died)
	hud.respawn_requested.connect(_respawn)
	hud.service_action.connect(_service)
	hud.save_requested.connect(save_game)
	region.encounter_cleared.connect(quest.encounter_cleared)
	region.enemy_defeated.connect(func(_enemy: Enemy): _schedule_save())
	player.inventory.changed.connect(_schedule_save)
	quest.changed.connect(_schedule_save)
	var saved := {} if testing else SaveStore.read()
	if saved.is_empty():
		player.inventory.gold = 20
		for id in ["old_sword", "oak_shield", "coat"]:
			var item := catalog.find_item(id)
			player.inventory.equipment[item.slot] = item
		for i in range(3):
			player.inventory.add(catalog.find_item("tonic"))
		player.inventory.changed.emit()
	else:
		player.inventory.restore(saved.inventory, catalog)
		quest.restore(saved.quest)
	region.initialize(saved.get("defeated", []))
	_restore_loot(saved.get("loot", []))
	initialized = true
	hud.toast("Welcome to Briarwatch. Speak with Warden Elric.  [E]")

func _interact(target: Node) -> void:
	if target is Npc:
		hud.show_npc(target)
	elif target is LootDrop:
		var name_text: String = target.interaction_name()
		if target.collect(player.inventory):
			hud.toast("Collected " + name_text)
		else:
			hud.toast("Your pack is full. Sell or equip an item first.")

func _service(action: String, index: int) -> void:
	var npc := hud.current_npc
	if not is_instance_valid(npc):
		return
	match action:
		"buy":
			if index >= 0 and index < npc.definition.stock.size():
				if not player.inventory.buy(npc.definition.stock[index]):
					hud.toast("Not enough crowns or pack space.")
		"sell":
			player.inventory.sell(index)
		"heal":
			player.health.heal(player.health.maximum)
			hud.toast("Your wounds are healed.")
		"rest":
			player.health.heal(player.health.maximum)
			region.reset_encounters()
			hud.toast("Dawn breaks. The March stirs again.")
		"accept":
			quest.accept()
		"claim":
			if quest.claim(player.inventory):
				hud.toast("Road secured. +%d crowns and %s." % [quest.definition.reward_gold, quest.definition.reward_item.display_name])
			else:
				hud.toast("Make room in your pack for the reward.")
	hud.show_npc(npc)
	_schedule_save()

func _on_player_died() -> void:
	player.inventory.gold -= int(ceil(player.inventory.gold * 0.1))
	player.inventory.changed.emit()
	hud.show_death()
	_schedule_save()

func _respawn() -> void:
	player.respawn(region.player_spawn.global_position)
	_schedule_save()

func _schedule_save() -> void:
	if not initialized or testing or save_pending:
		return
	save_pending = true
	call_deferred("_autosave")

func _autosave() -> void:
	save_pending = false
	_save(false)

func save_game() -> void:
	_save(true)

func _save(notify: bool) -> void:
	if testing:
		return
	var data := {"inventory": player.inventory.serialize(), "quest": quest.serialize(), "defeated": region.defeated_ids, "loot": _serialize_loot()}
	var error := SaveStore.write(data)
	if error != OK:
		hud.toast("Save failed (%d). Your session is still running." % error)
	elif notify:
		hud.toast("Journey saved.")

func _serialize_loot() -> Array:
	var result: Array = []
	for child in region.actors.get_children():
		if child is LootDrop and not child.taken:
			result.append({"item": str(child.item.id) if child.item else "", "gold": child.gold, "x": child.position.x, "z": child.position.z})
	return result

func _restore_loot(data: Variant) -> void:
	if not data is Array:
		return
	for entry in data.slice(0, 500):
		if not entry is Dictionary:
			continue
		var drop := LootDrop.new()
		drop.item = catalog.find_item(str(entry.get("item", "")))
		drop.gold = clampi(int(entry.get("gold", 0)), 0, 1000)
		if drop.item == null and drop.gold == 0:
			drop.free()
			continue
		region.actors.add_child(drop)
		drop.position = Vector3(clampf(float(entry.get("x", 0)), -78, 78), 0, clampf(float(entry.get("z", 0)), -70, 70))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save(false)
		get_tree().quit()

extends Node

# Debug keys, only in debug builds: F3 rolls a random item and equips it (the replaced item goes
# to the backpack, or the ground if full), F4 clears all gear,
# F5 brings back the three enemies at their starting spots to farm drops.

const GENERATOR := preload("res://items/item_generator.gd")
const LOOT := preload("res://loot.gd")
const DEBUG_ITEM_LEVEL := 30
# Better odds than ordinary drops, so testing sees every rarity.
const DEBUG_WEIGHTS := [20.0, 45.0, 30.0, 5.0]
const ENEMY_SPAWNS := {"skitter": Vector2(560, 250), "scholar": Vector2(800, 250), "sentinel": Vector2(1040, 250)}

var rng := RandomNumberGenerator.new()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_F3:
		roll_and_equip()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F4:
		Inventory.clear()
		_message("Gear cleared", Color.WHITE)
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F5:
		respawn_enemies()
		get_viewport().set_input_as_handled()


func respawn_enemies() -> void:
	for kind: String in ENEMY_SPAWNS:
		var enemy = load("res://enemy.tscn").instantiate()
		enemy.kind = kind
		enemy.position = ENEMY_SPAWNS[kind]
		get_parent().add_child(enemy)
	_message("Enemies respawned", Color.WHITE)


func roll_and_equip():
	var item = GENERATOR.roll(DEBUG_ITEM_LEVEL, rng, -1, DEBUG_WEIGHTS)
	var previous = Inventory.equip(item, Inventory.slot_for(item))
	# The replaced item goes to the backpack, or to the ground when it's full.
	if previous != null and not Inventory.add_item(previous):
		var player = get_tree().get_first_node_in_group("player")
		LOOT.spawn(previous, player.global_position if player != null else Vector2.ZERO, get_parent())
	for line in item.describe():
		print(line[0] if line[0] != "" else "--------")
	_message("Equipped: " + item.display_name(), item.color())
	return item


func _message(text: String, color: Color) -> void:
	var hud = get_parent().get_node_or_null("HUD")
	if hud != null:
		hud.show_message(text, color)

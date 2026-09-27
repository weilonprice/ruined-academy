extends Node

# Debug keys, only in debug builds: F3 rolls a random item and equips it, F4 clears all gear.

const GENERATOR := preload("res://items/item_generator.gd")
const DEBUG_ITEM_LEVEL := 30
# Better odds than ordinary drops, so testing sees every rarity.
const DEBUG_WEIGHTS := [20.0, 45.0, 30.0, 5.0]

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


func roll_and_equip():
	var item = GENERATOR.roll(DEBUG_ITEM_LEVEL, rng, -1, DEBUG_WEIGHTS)
	var previous = Inventory.equip(item, Inventory.slot_for(item))
	if previous != null:
		Inventory.add_item(previous)
	for line in item.describe():
		print(line[0] if line[0] != "" else "--------")
	_message("Equipped: " + item.display_name(), item.color())
	return item


func _message(text: String, color: Color) -> void:
	var hud = get_parent().get_node_or_null("HUD")
	if hud != null:
		hud.show_message(text, color)

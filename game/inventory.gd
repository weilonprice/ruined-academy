extends Node

# The wizard's items: equipped gear and a grid backpack. Survives scene
# reloads (it is an autoload) and saves to disk after every change.

signal changed

const DB := preload("res://items/item_database.gd")
const ITEM := preload("res://items/item.gd")
const COLUMNS := 10
const ROWS := 5
const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://inventory.json"

var save_path := DEFAULT_SAVE_PATH
# Slot name -> item, for occupied slots only.
var equipment := {}
# Each entry is {"item": item, "cell": Vector2i}, the item's top-left cell.
var backpack: Array[Dictionary] = []


func _ready() -> void:
	load_save()


# Points saving and loading at another file and loads it; tests use this to leave the player's save alone.
func use_save_path(path: String) -> void:
	save_path = path
	load_save()


func equipped_items() -> Array:
	return equipment.values()


func equip(item, slot: String):
	assert(item.fits_slot(slot), "%s does not fit %s" % [item.base_id, slot])
	var previous = equipment.get(slot)
	equipment[slot] = item
	_changed()
	return previous


func unequip(slot: String):
	var item = equipment.get(slot)
	equipment.erase(slot)
	if item != null:
		_changed()
	return item


# The first slot an item fits, preferring an empty one (for rings).
func slot_for(item) -> String:
	var fitting := DB.SLOTS.filter(func(slot: String) -> bool: return item.fits_slot(slot))
	for slot: String in fitting:
		if not equipment.has(slot):
			return slot
	return fitting[0] if not fitting.is_empty() else ""


func can_place(item, cell: Vector2i, ignore = null) -> bool:
	var area := Rect2i(cell, item.size())
	if area.position.x < 0 or area.position.y < 0 or area.end.x > COLUMNS or area.end.y > ROWS:
		return false
	for entry in backpack:
		if entry.item != ignore and area.intersects(Rect2i(entry.cell, entry.item.size())):
			return false
	return true


func place(item, cell: Vector2i) -> bool:
	if not can_place(item, cell):
		return false
	backpack.append({"item": item, "cell": cell})
	_changed()
	return true


# Where an item would go: the first free spot scanning each column top to bottom, left to right.
func find_space(item) -> Vector2i:
	for x in range(COLUMNS):
		for y in range(ROWS):
			if can_place(item, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func add_item(item) -> bool:
	var cell := find_space(item)
	return cell.x >= 0 and place(item, cell)


func remove(item) -> bool:
	for index in range(backpack.size()):
		if backpack[index].item == item:
			backpack.remove_at(index)
			_changed()
			return true
	return false


func item_at(cell: Vector2i):
	for entry in backpack:
		if Rect2i(entry.cell, entry.item.size()).has_point(cell):
			return entry.item
	return null


func clear() -> void:
	equipment.clear()
	backpack.clear()
	_changed()


func save() -> void:
	var data := {"version": SAVE_VERSION, "equipment": {}, "backpack": []}
	for slot in equipment:
		data.equipment[slot] = equipment[slot].to_dict()
	for entry in backpack:
		data.backpack.append({"item": entry.item.to_dict(), "cell": [entry.cell.x, entry.cell.y]})
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save inventory to %s" % save_path)
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_save() -> void:
	equipment.clear()
	backpack.clear()
	if FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary and int(data.get("version", 0)) == SAVE_VERSION:
			for slot in data.equipment:
				equipment[slot] = ITEM.from_dict(data.equipment[slot])
			for entry in data.backpack:
				backpack.append({"item": ITEM.from_dict(entry.item), "cell": Vector2i(int(entry.cell[0]), int(entry.cell[1]))})
		else:
			push_warning("Ignoring unreadable inventory save at %s" % save_path)
	changed.emit()


func _changed() -> void:
	save()
	changed.emit()

extends Control

# The inventory screen (I): equipment slots above a 10x5 backpack grid, on the
# right half of the screen. Click to pick up and place; Shift+click to equip or
# unequip. Everything is drawn at whole-number scales so icons stay crisp.

const DB := preload("res://items/item_database.gd")
const STATS := preload("res://stats.gd")
const CELL := 32
const WIDTH := 320
const GRID_ORIGIN := Vector2(0, 232)
const SLOT_RECTS := {
	"weapon": Rect2(16, 24, 64, 128), "offhand": Rect2(240, 24, 64, 128),
	"helmet": Rect2(128, 8, 64, 64), "amulet": Rect2(200, 40, 32, 32),
	"body": Rect2(128, 76, 64, 96), "ring_left": Rect2(88, 120, 32, 32), "ring_right": Rect2(200, 120, 32, 32),
	"gloves": Rect2(16, 160, 64, 64), "boots": Rect2(240, 160, 64, 64), "belt": Rect2(128, 180, 64, 32),
}
const BACKGROUND := Color("15181f")
const SLOT_COLOR := Color("0d0f14")
const LINE_COLOR := Color("2b303b")
const BORDER_COLOR := Color("5a4a33")
const FITS := Color(0.3, 0.8, 0.35, 0.3)
const SWAPS := Color(0.9, 0.7, 0.2, 0.3)
const BLOCKED := Color(0.9, 0.25, 0.2, 0.3)
const ICON_ROOT := "res://assets/icons/%s.png"
# The camera glides this long to keep the wizard in view beside the open screen.
const CAMERA_SHIFT_TIME := 0.15

var icons := {}
var camera_tween: Tween
@onready var tooltip: PanelContainer = get_parent().get_node("Tooltip")


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	Inventory.changed.connect(queue_redraw)
	Inventory.changed.connect(tooltip.hide_tooltip)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory", false, true) or (visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"))):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		show()
		_shift_camera(true)
		queue_redraw()


# Closing puts a carried item back in the backpack; with no room, the screen stays open.
func close() -> bool:
	if not Inventory.stow_held():
		_message("No room to put that away")
		return false
	hide()
	tooltip.hide_tooltip()
	_shift_camera(false)
	return true


# Centres the wizard in the uncovered left part of the screen while the inventory is open, as PoE does.
func _shift_camera(open: bool) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var target := Vector2(WIDTH / 2.0 / camera.zoom.x, 0.0) if open else Vector2.ZERO
	if camera_tween:
		camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.tween_property(camera, "offset", target, CAMERA_SHIFT_TIME)


func _process(_delta: float) -> void:
	if not visible:
		return
	queue_redraw()
	_update_tooltip()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	click(event.position, event.shift_pressed)


# One left click at a panel position; Shift makes it a quick move.
func click(at: Vector2, shift := false) -> void:
	var slot := slot_at(at)
	var cell := cell_at(at)
	if Inventory.held != null:
		if slot != "":
			Inventory.drop_held_in_slot(slot)
		elif cell.x >= 0:
			Inventory.drop_held(drop_cell(at))
		return
	if slot != "":
		if shift:
			if not Inventory.quick_unequip(slot) and Inventory.equipment.has(slot):
				_message("No room in the backpack")
		else:
			Inventory.pick_up_equipped(slot)
	elif cell.x >= 0:
		var item = Inventory.item_at(cell)
		if item != null:
			if shift:
				Inventory.quick_equip(item)
			else:
				Inventory.pick_up(item)


func slot_at(at: Vector2) -> String:
	for slot in SLOT_RECTS:
		if SLOT_RECTS[slot].has_point(at):
			return slot
	return ""


func cell_at(at: Vector2) -> Vector2i:
	var cell := Vector2i(((at - GRID_ORIGIN) / CELL).floor())
	if cell.x < 0 or cell.y < 0 or cell.x >= Inventory.COLUMNS or cell.y >= Inventory.ROWS:
		return Vector2i(-1, -1)
	return cell


# Where the carried item's top-left lands: centred on the cursor, kept inside the grid.
func drop_cell(at: Vector2) -> Vector2i:
	var size: Vector2i = Inventory.held.size()
	var cell := Vector2i(((at - GRID_ORIGIN) / CELL - Vector2(size) / 2.0).round())
	return cell.clamp(Vector2i.ZERO, Vector2i(Inventory.COLUMNS, Inventory.ROWS) - size)


func item_rect(item, cell: Vector2i) -> Rect2:
	return Rect2(GRID_ORIGIN + Vector2(cell) * CELL, Vector2(item.size()) * CELL)


func hovered_item():
	return item_at_position(get_local_mouse_position())


func item_at_position(at: Vector2):
	var slot := slot_at(at)
	if slot != "":
		return Inventory.equipment.get(slot)
	var cell := cell_at(at)
	return Inventory.item_at(cell) if cell.x >= 0 else null


func _draw() -> void:
	draw_rect(Rect2(0, 0, WIDTH, size.y), BACKGROUND)
	draw_line(Vector2(0, 0), Vector2(0, size.y), BORDER_COLOR, 2.0)
	for slot in SLOT_RECTS:
		var area: Rect2 = SLOT_RECTS[slot]
		draw_rect(area, SLOT_COLOR)
		draw_rect(area, LINE_COLOR, false, 1.0)
		var item = Inventory.equipment.get(slot)
		if item != null:
			_draw_item(item, area)
	var grid := Rect2(GRID_ORIGIN, Vector2(Inventory.COLUMNS, Inventory.ROWS) * CELL)
	draw_rect(grid, SLOT_COLOR)
	for entry in Inventory.backpack:
		_draw_item(entry.item, item_rect(entry.item, entry.cell))
	for x in range(Inventory.COLUMNS + 1):
		draw_line(grid.position + Vector2(x * CELL, 0), grid.position + Vector2(x * CELL, grid.size.y), LINE_COLOR)
	for y in range(Inventory.ROWS + 1):
		draw_line(grid.position + Vector2(0, y * CELL), grid.position + Vector2(grid.size.x, y * CELL), LINE_COLOR)
	_draw_placement()
	if Inventory.held != null:
		var held_size := Vector2(Inventory.held.size()) * CELL
		_draw_item(Inventory.held, Rect2(get_local_mouse_position() - held_size / 2.0, held_size))


# Shows where a carried item would land: green fits, amber swaps, red blocked.
func _draw_placement() -> void:
	if Inventory.held == null:
		return
	var at := get_local_mouse_position()
	var slot := slot_at(at)
	if slot != "":
		draw_rect(SLOT_RECTS[slot], FITS if Inventory.held.fits_slot(slot) else BLOCKED)
	elif cell_at(at).x >= 0:
		var cell := drop_cell(at)
		var area := Rect2i(cell, Inventory.held.size())
		var under := Inventory.backpack.filter(func(entry: Dictionary) -> bool: return area.intersects(Rect2i(entry.cell, entry.item.size())))
		var tint := FITS if under.is_empty() else (SWAPS if under.size() == 1 else BLOCKED)
		draw_rect(item_rect(Inventory.held, cell), tint)


# An item's rarity-tinted backing and its icon at the largest whole scale that fits.
func _draw_item(item, area: Rect2) -> void:
	var tint: Color = item.color()
	tint.a = 0.14
	draw_rect(area.grow(-1), tint)
	var icon := _icon(item)
	if icon == null:
		return
	var scale := maxi(1, int(minf(area.size.x, area.size.y) / icon.get_width()))
	var icon_size := Vector2(icon.get_size()) * scale
	draw_texture_rect(icon, Rect2((area.position + (area.size - icon_size) / 2.0).floor(), icon_size), false)


func _icon(item) -> Texture2D:
	var key: String = item.base().icon
	if not icons.has(key):
		var path := ICON_ROOT % key
		icons[key] = load(path) if ResourceLoader.exists(path) else null
	return icons[key]


func _update_tooltip() -> void:
	var item = hovered_item() if Inventory.held == null else null
	if item == null:
		tooltip.hide_tooltip()
		return
	tooltip.show_item(item, comparison(item))
	tooltip.place_near(get_global_mouse_position(), get_viewport_rect().size)


# For a backpack item: how equipping it would change each stat, as [text, color] lines.
func comparison(item) -> Array:
	if Inventory.equipment.values().has(item):
		return []
	var slot := Inventory.slot_for(item)
	var current := Inventory.equipment.duplicate()
	var before := STATS.compute(current.values())
	current[slot] = item
	var after := STATS.compute(current.values())
	var lines := []
	for stat in STAT_LABELS:
		var change: float = after[stat] - before[stat]
		if absf(change) >= 0.05:
			var shown := ("%+.1f" if absf(change) < 10.0 and not is_equal_approx(change, roundf(change)) else "%+d") % change
			lines.append([STAT_LABELS[stat] % shown, Color("7fd67f") if change > 0.0 else Color("e06a5a")])
	return lines


const STAT_LABELS := {
	"max_life": "%s maximum Life", "life_regen": "%s Life per second", "armour": "%s Armour",
	"max_mana": "%s maximum Mana", "mana_regen": "%s Mana per second",
	"spell_damage": "%s%% Spell Damage", "cast_speed": "%s%% Cast Speed", "projectile_speed": "%s%% Projectile Speed",
	"crit_chance": "%s%% Critical Strike Chance",
	"fire_res": "%s%% Fire Resistance", "cold_res": "%s%% Cold Resistance", "lightning_res": "%s%% Lightning Resistance",
}


func _message(text: String) -> void:
	var hud = get_parent()
	if hud.has_method("show_message"):
		hud.show_message(text, Color("e06a5a"))

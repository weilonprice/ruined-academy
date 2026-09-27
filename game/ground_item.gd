extends Node2D

# An item lying on the ground: its icon, a label in its rarity colour, and a
# light beam for rares and uniques. Click the label or the item to pick it up;
# the wizard walks over first if it is out of reach. Normal items only show
# their label while Alt is held or the cursor is over them.

const DB := preload("res://items/item_database.gd")
const ICON_ROOT := "res://assets/icons/%s.png"
const POP_TIME := 0.4
const POP_HEIGHT := 18.0
# World units; at the camera's zoom this reads like the HUD's text.
const FONT_SIZE := 16
const LABEL_GAP := 20.0
const BEAM_HEIGHT := 70.0

var item
var origin := Vector2.ZERO
var landing := Vector2.ZERO
var lift := 0.0
var landed := false
var hovered := false
var label: Label
var hitbox: Control
var icon: Sprite2D

# Labels placed so far this frame, in world space, so nearby labels stack instead of overlapping.
static var _placed_frame := -1
static var _placed: Array[Rect2] = []


func _ready() -> void:
	add_to_group("ground_items")
	global_position = origin
	icon = Sprite2D.new()
	var path := ICON_ROOT % item.base().icon
	icon.texture = load(path) if ResourceLoader.exists(path) else null
	add_child(icon)
	hitbox = Control.new()
	hitbox.position = Vector2(-16, -16)
	hitbox.size = Vector2(32, 32)
	add_child(hitbox)
	label = Label.new()
	label.text = item.display_name()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", item.color())
	add_child(label)
	for target: Control in [hitbox, label]:
		target.mouse_filter = Control.MOUSE_FILTER_STOP
		target.gui_input.connect(_on_gui_input)
		target.mouse_entered.connect(_set_hovered.bind(true))
		target.mouse_exited.connect(_set_hovered.bind(false))
	# Labels read above characters and props, as in PoE.
	label.z_index = 10
	_style_label()
	label.hide()
	hitbox.hide()
	# Pop out of where the enemy fell in a short arc, then settle.
	var pop := create_tween()
	pop.tween_property(self, "global_position", landing, POP_TIME)
	pop.parallel().tween_method(func(t: float) -> void:
		lift = sin(t * PI) * POP_HEIGHT
		icon.position.y = -lift, 0.0, 1.0, POP_TIME)
	pop.tween_callback(_land)


func _land() -> void:
	landed = true
	lift = 0.0
	icon.position.y = 0.0
	hitbox.show()
	_update_label()
	queue_redraw()


func _process(_delta: float) -> void:
	if landed:
		_update_label()


func _update_label() -> void:
	label.visible = item.rarity != DB.RARITY_NORMAL or hovered or Input.is_action_pressed("show_labels")
	if not label.visible:
		return
	label.reset_size()
	if _placed_frame != Engine.get_process_frames():
		_placed_frame = Engine.get_process_frames()
		_placed.clear()
	var area := Rect2(global_position + Vector2(-label.size.x / 2.0, -LABEL_GAP - label.size.y), label.size).abs()
	# Move up past any label already placed here this frame.
	var moved := true
	while moved:
		moved = false
		for other in _placed:
			if area.intersects(other):
				area.position.y = other.position.y - area.size.y - 1.0
				moved = true
	_placed.append(area)
	label.position = (area.position - global_position).round()


func _style_label() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.95 if hovered else 0.8)
	style.border_color = item.color() if hovered or item.rarity >= DB.RARITY_RARE else Color(item.color(), 0.4)
	style.set_border_width_all(1)
	style.content_margin_left = 3
	style.content_margin_right = 3
	label.add_theme_stylebox_override("normal", style)


func _set_hovered(on: bool) -> void:
	hovered = on
	_style_label()
	var tooltip = _tooltip()
	if tooltip == null:
		return
	if on:
		tooltip.show_item(item)
		tooltip.place_near(get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)
	elif tooltip.shown_item == item:
		tooltip.hide_tooltip()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var player = get_tree().get_first_node_in_group("player")
		if player != null:
			player.walk_to_pick_up(self)


# Moves the item into the backpack. With no room it stays on the ground.
func pick_up() -> bool:
	# Looked up by path: this script is also preloaded before autoloads exist.
	if not get_node("/root/Inventory").add_item(item):
		var hud = _hud()
		if hud != null:
			hud.show_message("Inventory full", Color("e06a5a"))
		return false
	if hovered:
		_set_hovered(false)
	queue_free()
	return true


func _draw() -> void:
	if item.rarity >= DB.RARITY_RARE and landed:
		# A soft pillar of light in the item's colour marks the good drops.
		for step in range(8):
			var beam: Color = item.color()
			beam.a = 0.22 * (1.0 - step / 8.0)
			draw_rect(Rect2(-1, -step * BEAM_HEIGHT / 8.0 - BEAM_HEIGHT / 8.0, 2, BEAM_HEIGHT / 8.0), beam)
	# A soft shadow under the item; the icon is a child sprite drawn on top.
	draw_circle(Vector2(0, 10), 8.0, Color(0, 0, 0, 0.3))


func _hud() -> Node:
	return get_parent().get_node_or_null("HUD")


func _tooltip() -> Node:
	var hud := _hud()
	return hud.get_node_or_null("Tooltip") if hud != null else null

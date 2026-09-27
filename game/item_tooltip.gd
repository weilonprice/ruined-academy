extends PanelContainer

# A PoE-style item tooltip: the name in its rarity colour over a coloured
# header, then properties, mods, and an optional "if equipped" comparison.

const FONT_SIZE := 8
const DIVIDER := Color("3a3f4b")
const COMPARE_HEADER := Color("a0a0a0")

var shown_item = null
@onready var lines: VBoxContainer = $Lines


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_item(item, comparison := []) -> void:
	if item == shown_item and visible:
		return
	shown_item = item
	for child in lines.get_children():
		lines.remove_child(child)
		child.queue_free()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.94)
	style.border_color = item.color()
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	add_theme_stylebox_override("panel", style)
	var entries: Array = item.describe()
	if not comparison.is_empty():
		entries.append(["", DIVIDER])
		entries.append(["If equipped:", COMPARE_HEADER])
		entries.append_array(comparison)
	for entry in entries:
		if entry[0] == "":
			var rule := ColorRect.new()
			rule.color = DIVIDER
			rule.custom_minimum_size = Vector2(0, 1)
			lines.add_child(rule)
			continue
		var label := Label.new()
		label.text = entry[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", entry[1])
		lines.add_child(label)
	reset_size()
	show()


# Beside the cursor, flipped left or up when it would run off the screen.
func place_near(point: Vector2, screen: Vector2) -> void:
	var box := get_combined_minimum_size()
	var spot := point + Vector2(12, 12)
	if spot.x + box.x > screen.x:
		spot.x = point.x - box.x - 12
	if spot.y + box.y > screen.y:
		spot.y = screen.y - box.y
	position = spot.clamp(Vector2.ZERO, (screen - box).max(Vector2.ZERO))


func hide_tooltip() -> void:
	shown_item = null
	hide()

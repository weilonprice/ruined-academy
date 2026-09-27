extends Control

# The skill bar: the bolt on the left mouse button, Frost Nova on the right.
# A skill dims while there isn't enough mana to cast it.

const SLOT := 24.0
const GAP := 6.0
const FRAME := Color("5a4a33")
const BACK := Color("0d0f14")
const DIM := Color(0, 0, 0, 0.6)
const KEY_COLOR := Color("d8d8d8")

var player
@onready var font := get_theme_default_font()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	queue_redraw()


# [key label, mana cost, icon drawer] for each slot, left to right.
func skills() -> Array:
	return [["LMB", player.BOLT_MANA_COST, _draw_bolt_icon], ["RMB", player.NOVA_MANA_COST, _draw_nova_icon]]


func usable(cost: float) -> bool:
	return player != null and not player.dead and player.mana >= cost


func _draw() -> void:
	if player == null:
		return
	var list := skills()
	var width := list.size() * SLOT + (list.size() - 1) * GAP
	for index in range(list.size()):
		var slot := Rect2(Vector2((size.x - width) / 2.0 + index * (SLOT + GAP), 0.0), Vector2(SLOT, SLOT))
		draw_rect(slot, BACK)
		list[index][2].call(slot.get_center())
		if not usable(list[index][1]):
			draw_rect(slot, DIM)
		draw_rect(slot, FRAME, false, 1.0)
		draw_string(font, Vector2(slot.position.x, slot.end.y + 8.0), list[index][0], HORIZONTAL_ALIGNMENT_CENTER, SLOT, 8, KEY_COLOR)


func _draw_bolt_icon(center: Vector2) -> void:
	var points := PackedVector2Array([Vector2(-7, 4), Vector2(3, -6), Vector2(7, -7), Vector2(6, -3), Vector2(-4, 7)])
	for index in range(points.size()):
		points[index] += center
	draw_colored_polygon(points, Color("e78a3b"))
	draw_line(center + Vector2(-4, 4), center + Vector2(4, -4), Color("fff0ae"), 2.0)


func _draw_nova_icon(center: Vector2) -> void:
	draw_arc(center, 8.0, 0.0, TAU, 24, Color("9fe8ff"), 2.0)
	draw_arc(center, 4.0, 0.0, TAU, 16, Color("e8fbff"), 1.0)
	for index in range(8):
		var out := Vector2.from_angle(TAU * index / 8.0)
		draw_line(center + out * 9.0, center + out * 11.0, Color("e8fbff"), 1.0)

extends Control

# The skill bar: the bolt on the left mouse button, Frost Nova on the right.
# A skill dims while there isn't enough mana to cast it.

const SLOT := 32.0
const BOLT_ICON := preload("res://assets/ui/skill_firebolt.png")
const NOVA_ICON := preload("res://assets/ui/skill_frost_nova.png")
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


# [key label, mana cost, icon] for each slot, left to right.
func skills() -> Array:
	return [["LMB", player.BOLT_MANA_COST, BOLT_ICON], ["RMB", player.NOVA_MANA_COST, NOVA_ICON]]


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
		draw_texture(list[index][2], slot.position)
		if not usable(list[index][1]):
			draw_rect(slot, DIM)
		draw_rect(slot, FRAME, false, 1.0)
		draw_string(font, Vector2(slot.position.x, slot.end.y + 8.0), list[index][0], HORIZONTAL_ALIGNMENT_CENTER, SLOT, 8, KEY_COLOR)


extends Control

# The skill bar: Wind Slash on the left mouse button, the bolt on the right,
# Frost Nova on 1, Wind Wave on 2 with 3 and 4 free for later skills, and the dash on Space.
# A spell dims while there isn't enough mana to cast it; the dash is shaded from
# the top while it recharges, the shade shrinking as it does.

const SLOT := 32.0
const BOLT_ICON := preload("res://assets/ui/skill_firebolt.png")
const NOVA_ICON := preload("res://assets/ui/skill_frost_nova.png")
const DASH_ICON := preload("res://assets/ui/skill_dash.png")
const SLASH_ICON := preload("res://assets/ui/skill_wind_slash.png")
const WAVE_ICON := preload("res://assets/ui/skill_wind_wave.png")
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


# [key label, icon or null for an empty slot, how much of the slot is dimmed from 0 to 1]
# for each slot, left to right.
func skills() -> Array:
	return [["LMB", SLASH_ICON, 0.0 if usable(0.0) else 1.0],
		["RMB", BOLT_ICON, 0.0 if usable(player.BOLT_MANA_COST) else 1.0],
		["1", NOVA_ICON, 0.0 if usable(player.NOVA_MANA_COST) else 1.0],
		["2", WAVE_ICON, 0.0 if usable(player.WAVE_MANA_COST) else 1.0],
		["3", null, 0.0], ["4", null, 0.0],
		["SPACE", DASH_ICON, dash_recharge()]]


func usable(cost: float) -> bool:
	return player != null and not player.dead and player.mana >= cost


# The share of the dash's full cooldown still to wait; 1 while the wizard is down.
func dash_recharge() -> float:
	if player == null or player.dead:
		return 1.0
	return clampf(player.dodge_cooldown_left / (player.DODGE_TIME + player.DODGE_COOLDOWN), 0.0, 1.0)


func _draw() -> void:
	if player == null:
		return
	var list := skills()
	var width := list.size() * SLOT + (list.size() - 1) * GAP
	for index in range(list.size()):
		var slot := Rect2(Vector2((size.x - width) / 2.0 + index * (SLOT + GAP), 0.0), Vector2(SLOT, SLOT))
		draw_rect(slot, BACK)
		if list[index][1] != null:
			draw_texture(list[index][1], slot.position)
		var dim: float = list[index][2]
		if dim > 0.0:
			draw_rect(Rect2(slot.position, Vector2(SLOT, roundf(SLOT * dim))), DIM)
		draw_rect(slot, FRAME, false, 1.0)
		draw_string(font, Vector2(slot.position.x, slot.end.y + 8.0), list[index][0], HORIZONTAL_ALIGNMENT_CENTER, SLOT, 8, KEY_COLOR)


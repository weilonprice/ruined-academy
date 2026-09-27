extends Control

# Flask vials beside the skill bar: fill shows charges, a bright rim shows a
# flask recovering, and a vial dims when it lacks the charges for a drink.

const VIAL := Vector2(14, 24)
const GAP := 6.0
const COLORS := [Color("d66765"), Color("5b7fd6")]
const GLASS := Color("0d0f14")
const RIM := Color("5a4a33")
const ACTIVE_RIM := Color("fff0ae")
const DIM := Color(0, 0, 0, 0.55)
const KEY_COLOR := Color("d8d8d8")

var player
@onready var font := get_theme_default_font()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var count: int = player.FLASKS.size()
	var width := count * VIAL.x + (count - 1) * GAP
	for index in range(count):
		var flask: Dictionary = player.FLASKS[index]
		var vial := Rect2(Vector2((size.x - width) / 2.0 + index * (VIAL.x + GAP), 0.0), VIAL)
		draw_rect(vial, GLASS)
		var fill: float = float(player.flask_charges[index]) / flask.max_charges
		var inner := vial.grow(-2)
		var level := Rect2(inner.position + Vector2(0, inner.size.y * (1.0 - fill)), Vector2(inner.size.x, inner.size.y * fill))
		draw_rect(level, COLORS[index])
		# A notch for each drink's worth of charges.
		var drinks: int = flask.max_charges / flask.per_use
		for step in range(1, drinks):
			var y := inner.end.y - inner.size.y * step / drinks
			draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), GLASS)
		if player.flask_charges[index] < flask.per_use or player.dead:
			draw_rect(vial, DIM)
		var running: bool = player.flask_time_left[index] > 0.0
		draw_rect(vial, ACTIVE_RIM if running else RIM, false, 1.0)
		draw_string(font, Vector2(vial.position.x, vial.end.y + 8.0), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, VIAL.x, 8, KEY_COLOR)

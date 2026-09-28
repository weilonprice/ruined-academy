extends Control

# Flasks beside the skill bar: the liquid level shows charges, a pip under each
# flask marks each drink it holds, a running flask glows, and a flask dims when
# it lacks the charges for a drink.

const TEXTURES := [preload("res://assets/ui/life_flask.png"), preload("res://assets/ui/mana_flask.png")]
# First row of liquid in the flask art; the level rises from the bottom row to here.
const LIQUID_TOP := 9
const GAP := 6.0
const EMPTY := Color(0.3, 0.3, 0.36)
const FULL := Color.WHITE
const RUNNING := Color(1.35, 1.3, 1.15)
const UNUSABLE := Color(0.55, 0.55, 0.6)
const PIP_ON := Color("f2c14e")
const PIP_OFF := Color("2b303b")
const KEY_COLOR := Color("d8d8d8")
# The key that drinks each flask.
const KEYS := ["Q", "E"]

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
	var width := 0.0
	for texture: Texture2D in TEXTURES:
		width += texture.get_width()
	width += (count - 1) * GAP
	var x := (size.x - width) / 2.0
	for index in range(count):
		var flask: Dictionary = player.FLASKS[index]
		var texture: Texture2D = TEXTURES[index]
		var at := Vector2(roundf(x), 0.0)
		x += texture.get_width() + GAP
		# The whole flask drawn dark is the empty glass; the lit part is the liquid left.
		draw_texture(texture, at, EMPTY)
		var fill: float = float(player.flask_charges[index]) / flask.max_charges
		var liquid := texture.get_height() - LIQUID_TOP
		var top := texture.get_height() - roundi(liquid * fill)
		var tint := FULL
		if player.flask_time_left[index] > 0.0:
			tint = RUNNING
		elif player.flask_charges[index] < flask.per_use or player.dead:
			tint = UNUSABLE
		if top < texture.get_height():
			var region := Rect2(0, top, texture.get_width(), texture.get_height() - top)
			draw_texture_rect_region(texture, Rect2(at + region.position, region.size), region, tint)
		# One pip per drink the flask can hold, lit for each drink it has now.
		var drinks: int = flask.max_charges / flask.per_use
		var pips_left := at.x + (texture.get_width() - drinks * 3 + 1) / 2.0
		for drink in range(drinks):
			var lit: bool = player.flask_charges[index] >= (drink + 1) * flask.per_use
			draw_rect(Rect2(roundf(pips_left + drink * 3), texture.get_height() + 1, 2, 2), PIP_ON if lit else PIP_OFF)
		draw_string(font, Vector2(at.x, texture.get_height() + 11.0), KEYS[index], HORIZONTAL_ALIGNMENT_CENTER, texture.get_width(), 8, KEY_COLOR)

extends CanvasLayer

# Wizard life and mana bars, short messages, and the prompt shown when the wizard falls.
const LIFE_BAR := Rect2(8, 8, 104, 10)
const MANA_BAR := Rect2(8, 20, 104, 6)
const LIFE_COLOR := Color("d66765")
const MANA_COLOR := Color("5b7fd6")
const FRAME_COLOR := Color("181c24")
# A notch every this many points keeps the bars readable at a glance.
const NOTCH := 10.0
const MESSAGE_TIME := 2.5

var health := 1.0
var max_health := 1.0
var mana := 1.0
var max_mana := 1.0
var message_tween: Tween
@onready var bar: Control = $Bar
@onready var fallen: Label = $Fallen
@onready var message: Label = $Message


func _ready() -> void:
	bar.draw.connect(_draw_bars)
	fallen.hide()
	message.hide()
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.mana_changed.connect(_on_mana_changed)
		player.died.connect(fallen.show)
		_on_health_changed(player.health, player.max_health)
		_on_mana_changed(player.mana, player.max_mana)


# Shows a line of text under the bars for a moment.
func show_message(text: String, color := Color.WHITE) -> void:
	message.text = text
	message.add_theme_color_override("font_color", color)
	message.modulate.a = 1.0
	message.show()
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(MESSAGE_TIME)
	message_tween.tween_property(message, "modulate:a", 0.0, 0.5)


func _on_health_changed(new_health: float, new_max: float) -> void:
	health = new_health
	max_health = new_max
	bar.queue_redraw()


func _on_mana_changed(new_mana: float, new_max: float) -> void:
	mana = new_mana
	max_mana = new_max
	bar.queue_redraw()


func _draw_bars() -> void:
	_draw_bar(LIFE_BAR, health, max_health, LIFE_COLOR)
	_draw_bar(MANA_BAR, mana, max_mana, MANA_COLOR)


func _draw_bar(frame: Rect2, value: float, maximum: float, color: Color) -> void:
	bar.draw_rect(frame, FRAME_COLOR)
	var inner := frame.grow(-2)
	bar.draw_rect(Rect2(inner.position, Vector2(inner.size.x * clampf(value / maximum, 0.0, 1.0), inner.size.y)), color)
	var notch := NOTCH
	while notch < maximum:
		var x := inner.position.x + inner.size.x * notch / maximum
		bar.draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), FRAME_COLOR)
		notch += NOTCH

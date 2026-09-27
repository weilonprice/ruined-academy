extends Node2D

# A gold ring rising and widening around the wizard on a new level.

const GOLD := Color("f2c14e")
const TIME := 1.0
const RISE := 24.0

var progress := 0.0


func _ready() -> void:
	z_index = 1
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Stays bright most of the way, then fades out.
	var fade := 1.0 - progress * progress
	for ring in range(3):
		var color := GOLD
		color.a = fade * (0.9 - ring * 0.25)
		var center := Vector2(0, 16 - progress * RISE - ring * 6.0)
		var radius := 12.0 + progress * 26.0 - ring * 4.0
		# Flattened circles read as rings lying on the ground.
		draw_set_transform(center, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 3.0)
		draw_set_transform(Vector2.ZERO)
	for index in range(8):
		var mote := Vector2.from_angle(TAU * index / 8.0 + progress) * (8.0 + progress * 20.0)
		var color := GOLD
		color.a = fade
		draw_rect(Rect2((Vector2(mote.x, mote.y * 0.5 - progress * RISE * 1.4)).round(), Vector2(2, 2)), color)

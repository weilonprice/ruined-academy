extends Control

# A gold bar in a slim gold frame showing progress toward the next level.

const FILL := Color("f2c14e")
const FRAME_TEXTURE := preload("res://assets/ui/exp_frame.png")
# The frame art's border widths (left, top, right, bottom); the middle stretches.
const FRAME_BORDER := [8, 4, 8, 3]

var frame_style := StyleBoxTexture.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_style.texture = FRAME_TEXTURE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame_style.set_texture_margin(side, FRAME_BORDER[side])
	Character.changed.connect(queue_redraw)


func _draw() -> void:
	draw_style_box(frame_style, Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(FRAME_BORDER[0], FRAME_BORDER[1]),
		size - Vector2(FRAME_BORDER[0] + FRAME_BORDER[2], FRAME_BORDER[1] + FRAME_BORDER[3]))
	var fill := Rect2(inner.position, Vector2(roundf(inner.size.x * Character.progress()), inner.size.y))
	draw_rect(fill, FILL)
	# A lighter top row gives the fill some depth.
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 1)), FILL.lightened(0.4))

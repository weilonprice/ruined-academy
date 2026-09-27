extends Control

# A thin gold bar showing progress toward the next level.

const FILL := Color("f2c14e")
const BACK := Color("181c24")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Character.changed.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * Character.progress(), size.y)), FILL)

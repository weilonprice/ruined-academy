extends Node2D

# A piece of map scenery: res://assets/<folder>/<kind>.png, scaled up by a
# whole number and drawn with its base SORT_LIFT below this node, so it
# y-sorts against the wizard, whose node sits at the middle of his sprite.
# A footprint makes the area just above the base block the wizard's feet.
# Flat pieces (floor plans, garden plots) draw under everything that walks.

const ROOT := "res://assets/%s/%s.png"
const SORT_LIFT := 28.0

# The art folder under res://assets: "village" or "ruins".
@export var folder := "village"
@export var kind := "pine_tree"
@export var pixel_scale := 2
# Width and height of the blocking area, centred on the base; zero blocks nothing.
@export var footprint := Vector2.ZERO
@export var flat := false
@export var flip := false


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(ROOT % [folder, kind])
	sprite.centered = false
	sprite.flip_h = flip
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * pixel_scale
	var size := sprite.texture.get_size() * pixel_scale
	sprite.position = Vector2(-size.x / 2.0, SORT_LIFT - size.y).round()
	add_child(sprite)
	if flat:
		z_index = -1
	if footprint != Vector2.ZERO:
		add_to_group("obstacles")


# The blocked area in world coordinates.
func footprint_rect() -> Rect2:
	var base := global_position + Vector2(0, SORT_LIFT)
	return Rect2(base - Vector2(footprint.x / 2.0, footprint.y), footprint)

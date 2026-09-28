extends Node2D

# Village ground: grass crossed by dirt roads and yards, drawn from the
# generated corner tileset at twice its size. Each corner point of the grid is
# grass or dirt; each cell shows the tile whose corners match its four points.
# A map sets its own dirt areas, tint and saturation (the ruins use the same
# tiles, drained of colour and tinted dusty).

const WORLD := preload("res://world.gd")
const TILESET := preload("res://assets/village/terrain_grass_dirt.png")
const SOURCE_TILE := 32
const CELL := 64
const COLUMNS := 25
const ROWS := 15
# The village's dirt areas in corner-point coordinates (0..COLUMNS, 0..ROWS), end exclusive.
const DIRT: Array[Rect2i] = [
	Rect2i(12, 0, 2, 16),   # the main road, north to the ruins and south
	Rect2i(0, 7, 24, 2),    # the cross road, west out to the academy
	Rect2i(3, 11, 6, 3),    # the sawmill yard
	Rect2i(16, 10, 7, 4),   # the training yard
	Rect2i(8, 5, 4, 2),     # in front of the forge
	Rect2i(14, 6, 5, 1),    # in front of the tavern
]

# Blends each pixel toward grey by 1 - saturation, then multiplies it by tint.
const SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation = 1.0;
void fragment() {
	vec4 colour = texture(TEXTURE, UV);
	float grey = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(grey), colour.rgb, saturation) * tint.rgb, colour.a);
}
"""

@export var dirt: Array[Rect2i] = DIRT
@export var tint := Color.WHITE
@export_range(0.0, 1.0) var saturation := 1.0


func _ready() -> void:
	z_index = -10
	if tint != Color.WHITE or saturation < 1.0:
		var shader := Shader.new()
		shader.code = SHADER
		material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("tint", tint)
		material.set_shader_parameter("saturation", saturation)


# Whether a corner point is dirt.
static func is_dirt(point: Vector2i, areas: Array[Rect2i] = DIRT) -> bool:
	return areas.any(func(area: Rect2i) -> bool: return area.has_point(point))


# The tileset tile for a cell: its index is NW*8 + NE*4 + SW*2 + SE, with grass 1 and dirt 0.
static func tile_for(cell: Vector2i, areas: Array[Rect2i] = DIRT) -> int:
	var index := 0
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		index = index * 2 + (0 if is_dirt(cell + corner, areas) else 1)
	return index


func _draw() -> void:
	for row in range(ROWS):
		for column in range(COLUMNS):
			var index := tile_for(Vector2i(column, row), dirt)
			var source := Rect2(Vector2(index % 4, index / 4) * SOURCE_TILE, Vector2.ONE * SOURCE_TILE)
			draw_texture_rect_region(TILESET, Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL), source)

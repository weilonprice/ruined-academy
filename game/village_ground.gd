extends Node2D

# The village ground: grass crossed by dirt roads and yards, drawn from the
# generated corner tileset at twice its size. Each corner point of the grid is
# grass or dirt; each cell shows the tile whose corners match its four points.

const WORLD := preload("res://world.gd")
const TILESET := preload("res://assets/village/terrain_grass_dirt.png")
const SOURCE_TILE := 32
const CELL := 64
const COLUMNS := 25
const ROWS := 15
# Dirt areas in corner-point coordinates (0..COLUMNS, 0..ROWS), end exclusive.
const DIRT := [
	Rect2i(12, 0, 2, 16),   # the main road, north to south, out to the academy
	Rect2i(2, 7, 22, 2),    # the cross road
	Rect2i(3, 11, 6, 3),    # the sawmill yard
	Rect2i(16, 10, 7, 4),   # the training yard
	Rect2i(8, 5, 4, 2),     # in front of the forge
	Rect2i(14, 6, 5, 1),    # in front of the tavern
]


func _ready() -> void:
	z_index = -10


# Whether a corner point is dirt.
static func is_dirt(point: Vector2i) -> bool:
	return DIRT.any(func(area: Rect2i) -> bool: return area.has_point(point))


# The tileset tile for a cell: its index is NW*8 + NE*4 + SW*2 + SE, with grass 1 and dirt 0.
static func tile_for(cell: Vector2i) -> int:
	var index := 0
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		index = index * 2 + (0 if is_dirt(cell + corner) else 1)
	return index


func _draw() -> void:
	for row in range(ROWS):
		for column in range(COLUMNS):
			var index := tile_for(Vector2i(column, row))
			var source := Rect2(Vector2(index % 4, index / 4) * SOURCE_TILE, Vector2.ONE * SOURCE_TILE)
			draw_texture_rect_region(TILESET, Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL), source)

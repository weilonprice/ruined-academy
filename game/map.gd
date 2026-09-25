extends Node2D

const WORLD := preload("res://world.gd")
const TILE_SIZE := 32
const COURTYARD := Rect2(512, 320, 576, 320)
const GRASS := [Color("334b3c"), Color("384f3f"), Color("3d5542"), Color("405642")]
const EARTH := [Color("6b5b48"), Color("72604b"), Color("77654e")]
const STONE := [Color("535f69"), Color("586470"), Color("5e6973"), Color("54646c")]


func _draw() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 173
	draw_rect(WORLD.MAP_RECT, Color("293e34"))
	for row in range(30):
		for column in range(50):
			var tile := Rect2(column * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var center := tile.get_center()
			var stone := COURTYARD.has_point(center)
			var path := absf(center.y - (480.0 + sin(center.x / 170.0) * 45.0)) < 48.0
			path = path or absf(center.x - (800.0 + sin(center.y / 140.0) * 36.0)) < 40.0
			if stone:
				draw_rect(tile, Color("424f56"))
				draw_rect(Rect2(tile.position + Vector2.ONE, Vector2(30, 30)), STONE[random.randi_range(0, STONE.size() - 1)])
				if random.randf() < 0.3:
					var crack := tile.position + Vector2(random.randi_range(8, 20), random.randi_range(5, 23))
					draw_line(crack, crack + Vector2(6, 0), Color("46545e"))
					draw_line(crack + Vector2(6, 0), crack + Vector2(6, 3), Color("46545e"))
			elif path:
				draw_rect(tile, EARTH[random.randi_range(0, EARTH.size() - 1)])
				for speck in range(3):
					var point := tile.position + Vector2(random.randi_range(3, 27), random.randi_range(3, 27))
					draw_rect(Rect2(point, Vector2(2, 1)), Color("918066"))
			else:
				draw_rect(tile, GRASS[random.randi_range(0, GRASS.size() - 1)])
				for blade in range(4):
					var point := tile.position + Vector2(random.randi_range(3, 27), random.randi_range(3, 27))
					draw_rect(Rect2(point, Vector2(1, 3)), Color("546949"))
	# A thin stone rim keeps the central courtyard distinct from the grass.
	draw_rect(COURTYARD, Color("81816b"), false, 2.0)
	draw_rect(WORLD.MAP_RECT.grow(-4), Color("20372f"), false, 8.0)

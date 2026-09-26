extends Node2D

# A caster's bolt. It flies straight and hurts the wizard on contact; dodge out of its path.
const SPEED := 170.0
const HIT_RADIUS := 14.0
const WORLD := preload("res://world.gd")

var direction := Vector2.RIGHT
var damage := 1
var lifetime := 3.0


func _ready() -> void:
	add_to_group("hostile_projectiles")
	rotation = direction.angle()
	z_index = 1


func _physics_process(delta: float) -> void:
	rotation = direction.angle()
	var start := global_position
	var next_position := start + direction * SPEED * delta
	var player = get_tree().get_first_node_in_group("player")
	# Check the whole step against the wizard so a fast frame cannot skip past.
	if player != null and not player.dead:
		var closest := Geometry2D.get_closest_point_to_segment(player.global_position, start, next_position)
		if closest.distance_to(player.global_position) <= HIT_RADIUS:
			player.take_damage(damage)
			queue_free()
			return
	global_position = next_position
	lifetime -= delta
	if lifetime <= 0.0 or not WORLD.MAP_RECT.has_point(global_position):
		queue_free()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -3), Vector2(1, -3), Vector2(5, 0), Vector2(1, 3), Vector2(-9, 3)]), Color("8a4fd1"))
	draw_rect(Rect2(-3, -1, 6, 2), Color("eed8ff"))

extends Node2D

const SPEED := 300.0
const DAMAGE := 1
const ENEMY_LAYER := 2
const WORLD := preload("res://world.gd")

var direction := Vector2.RIGHT
var lifetime := 2.0


func _ready() -> void:
	add_to_group("projectiles")
	rotation = direction.angle()
	z_index = 1


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	var next_position := global_position + direction * SPEED * delta
	var space := get_world_2d().direct_space_state
	# Point overlap handles firing while standing inside an enemy.
	var overlap := PhysicsPointQueryParameters2D.new()
	overlap.position = global_position
	overlap.collision_mask = ENEMY_LAYER
	overlap.collide_with_areas = true
	overlap.collide_with_bodies = false
	var overlapping := space.intersect_point(overlap, 1)
	var hit: Dictionary = overlapping[0] if not overlapping.is_empty() else {}
	if hit.is_empty():
		# Sweep the complete step so fast shots cannot skip through a target.
		var query := PhysicsRayQueryParameters2D.create(global_position, next_position, ENEMY_LAYER)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		hit = space.intersect_ray(query)
	if not hit.is_empty():
		hit.collider.take_damage(DAMAGE)
		queue_free()
		return
	global_position = next_position
	lifetime -= delta
	if lifetime <= 0.0 or not WORLD.MAP_RECT.has_point(global_position):
		queue_free()


func _draw() -> void:
	# A small pixel-shaped magic bolt, with its tip pointing along travel.
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -2), Vector2(1, -2), Vector2(5, 0), Vector2(1, 2), Vector2(-10, 2)]), Color("e78a3b"))
	draw_rect(Rect2(-3, -1, 6, 2), Color("fff0ae"))

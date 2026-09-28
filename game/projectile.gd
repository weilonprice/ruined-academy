extends Node2D

const SPEED := 300.0
const ENEMY_LAYER := 2
const WORLD := preload("res://world.gd")
const EFFECT := preload("res://effect.gd")

var direction := Vector2.RIGHT
# Set by the caster from its stats.
var speed := SPEED
var damage := 10.0
var critical := false
var lifetime := 2.0
# Start of the next hit sweep; the launcher may set it behind the spawn point.
var sweep_from: Variant = null


func _ready() -> void:
	add_to_group("projectiles")
	rotation = direction.angle()
	z_index = 1
	# The fireball art points right, its head near the right edge; the head leads at the origin.
	var sprite := EFFECT.looping("firebolt", 12.0)
	sprite.position = Vector2(-12, 0)
	if critical:
		# Crits burn larger and whiter.
		sprite.scale = Vector2.ONE * 1.5
		sprite.position *= 1.5
		sprite.modulate = Color(1.4, 1.3, 1.1)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	var next_position := global_position + direction * speed * delta
	var space := get_world_2d().direct_space_state
	var start: Vector2 = sweep_from if sweep_from != null else global_position
	sweep_from = null
	# Point overlap handles firing while standing inside an enemy.
	var overlap := PhysicsPointQueryParameters2D.new()
	overlap.position = start
	overlap.collision_mask = ENEMY_LAYER
	overlap.collide_with_areas = true
	overlap.collide_with_bodies = false
	var overlapping := space.intersect_point(overlap, 1)
	var hit: Dictionary = overlapping[0] if not overlapping.is_empty() else {}
	if hit.is_empty():
		# Sweep the complete step so fast shots cannot skip through a target.
		var query := PhysicsRayQueryParameters2D.create(start, next_position, ENEMY_LAYER)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		hit = space.intersect_ray(query)
	if not hit.is_empty():
		hit.collider.take_damage(damage, critical)
		EFFECT.spawn(get_parent(), "fire_impact", start if not overlapping.is_empty() else hit.position, 20.0)
		queue_free()
		return
	global_position = next_position
	lifetime -= delta
	if lifetime <= 0.0 or not WORLD.MAP_RECT.has_point(global_position):
		queue_free()


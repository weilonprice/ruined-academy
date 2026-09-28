extends Node2D

# Wind Wave: a crescent of wind that flies forward and passes through enemies,
# hitting each one once and pushing it back, then thins out at the end of its range.

const EFFECT := preload("res://effect.gd")
const WORLD := preload("res://world.gd")
const SPEED := 240.0
const RANGE := 260.0
# Enemies whose centre comes this close to the wave's are hit.
const HIT_RADIUS := 28.0
const KNOCKBACK := 12.0
# The last stretch of its flight, over which the wave fades out.
const FADE_DISTANCE := 60.0

# Set by the caster before adding the wave to the scene.
var direction := Vector2.RIGHT
var damage_range := Vector2(8.0, 12.0)
var damage_scale := 1.0
var crit_chance := 5.0
var crit_multiplier := 1.5
var rng: RandomNumberGenerator
var hits: Array = []
var travelled := 0.0


func _ready() -> void:
	z_index = 1
	rotation = direction.angle()
	add_child(EFFECT.looping("wind_wave", 12.0))


func _physics_process(delta: float) -> void:
	var step := direction * SPEED * delta
	global_position += step
	travelled += step.length()
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if hits.any(func(hit: Dictionary) -> bool: return hit.enemy == enemy):
			continue
		if enemy.global_position.distance_to(global_position) > HIT_RADIUS:
			continue
		var critical := rng.randf() * 100.0 < crit_chance
		var damage := rng.randf_range(damage_range.x, damage_range.y) * damage_scale
		if critical:
			damage *= crit_multiplier
		enemy.take_damage(damage, critical)
		enemy.knock_back(direction * KNOCKBACK)
		hits.append({"enemy": enemy, "damage": damage, "critical": critical})
	modulate.a = clampf((RANGE - travelled) / FADE_DISTANCE, 0.0, 1.0)
	if travelled >= RANGE or not WORLD.MAP_RECT.has_point(global_position):
		queue_free()

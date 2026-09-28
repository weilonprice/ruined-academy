extends Node2D

# A caster's bolt. It flies straight and hurts the wizard on contact; dodge out of its path.
const SPEED := 170.0
const HIT_RADIUS := 14.0
const WORLD := preload("res://world.gd")
const EFFECT := preload("res://effect.gd")
# The fireball art is orange like the wizard's; hostile bolts burn ember red.
const EMBER_TINT := Color(1.0, 0.45, 0.4)

var direction := Vector2.RIGHT
var damage := 10.0
var damage_type := "fire"
var lifetime := 3.0


func _ready() -> void:
	add_to_group("hostile_projectiles")
	rotation = direction.angle()
	z_index = 1
	# The art points right with its head near the right edge; the head leads at the origin.
	var sprite := EFFECT.looping("ember_bolt", 12.0)
	sprite.position = Vector2(-11, 0)
	sprite.modulate = EMBER_TINT
	add_child(sprite)


func _physics_process(delta: float) -> void:
	rotation = direction.angle()
	var start := global_position
	var next_position := start + direction * SPEED * delta
	var player = get_tree().get_first_node_in_group("player")
	# Check the whole step against the wizard so a fast frame cannot skip past.
	if player != null and not player.dead:
		var closest := Geometry2D.get_closest_point_to_segment(player.global_position, start, next_position)
		if closest.distance_to(player.global_position) <= HIT_RADIUS:
			player.take_damage(damage, damage_type)
			EFFECT.spawn(get_parent(), "ember_impact", closest, 12.0)
			queue_free()
			return
	global_position = next_position
	lifetime -= delta
	if lifetime <= 0.0 or not WORLD.MAP_RECT.has_point(global_position):
		queue_free()


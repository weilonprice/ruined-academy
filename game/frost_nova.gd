extends Node2D

# Frost Nova: a ring of cold bursting out from the caster. Every enemy within
# the radius takes one cold hit and is chilled; the ring is the visual.

const RADIUS := 90.0
# Enemies whose edge the ring reaches count as inside.
const ENEMY_REACH := 12.0
const EXPAND_TIME := 0.22
const FADE_TIME := 0.18
const SHARDS := 14
const RING_COLOR := Color("9fe8ff")
const CORE_COLOR := Color("e8fbff")

# Set by the caster before adding the nova to the scene.
var damage_range := Vector2(12.0, 18.0)
var damage_scale := 1.0
var crit_chance := 5.0
var crit_multiplier := 1.5
var chill_time := 2.0
var rng: RandomNumberGenerator
var hits: Array = []
var progress := 0.0
var fade := 1.0


func _ready() -> void:
	z_index = 1
	hits = strike()
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, EXPAND_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "fade", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


# Hits every living enemy in reach once, each with its own damage and crit roll.
func strike() -> Array:
	var struck := []
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position) > RADIUS + ENEMY_REACH:
			continue
		var critical := rng.randf() * 100.0 < crit_chance
		var damage := rng.randf_range(damage_range.x, damage_range.y) * damage_scale
		if critical:
			damage *= crit_multiplier
		enemy.take_damage(damage, critical, chill_time)
		struck.append({"enemy": enemy, "damage": damage, "critical": critical})
	return struck


func _draw() -> void:
	var radius := lerpf(10.0, RADIUS, progress)
	var ring := RING_COLOR
	ring.a = 0.9 * fade
	var core := CORE_COLOR
	core.a = 0.8 * fade
	var haze := RING_COLOR
	haze.a = 0.12 * fade
	draw_circle(Vector2.ZERO, radius, haze)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring, 3.0)
	draw_arc(Vector2.ZERO, radius - 3.0, 0.0, TAU, 48, core, 1.0)
	# Ice shards riding the ring's edge, pointing outward.
	for index in range(SHARDS):
		var angle := TAU * index / SHARDS + progress * 0.4
		var out := Vector2.from_angle(angle)
		var side := out.orthogonal() * 2.0
		var tip := out * (radius + 5.0)
		var base := out * (radius - 3.0)
		draw_colored_polygon(PackedVector2Array([(base + side).round(), tip.round(), (base - side).round()]), core)

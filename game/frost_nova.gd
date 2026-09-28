extends Node2D

# Frost Nova: a ring of cold bursting out from the caster. Every enemy within
# the radius takes one cold hit and is chilled; the ice ring sprite is the visual.

# Base radius; passives can widen it.
const RADIUS := 90.0
# Enemies whose edge the ring reaches count as inside.
const ENEMY_REACH := 12.0
const EXPAND_TIME := 0.22
const FADE_TIME := 0.18
const EFFECT := preload("res://effect.gd")
# Distance from the centre of the ring art to its outer shard tips, in art pixels.
const ART_RADIUS := 50.0

# Set by the caster before adding the nova to the scene.
var damage_range := Vector2(12.0, 18.0)
var damage_scale := 1.0
var crit_chance := 5.0
var crit_multiplier := 1.5
var chill_time := 2.0
var radius := RADIUS
var rng: RandomNumberGenerator
var hits: Array = []
var progress := 0.0
var fade := 1.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	z_index = 1
	hits = strike()
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = EFFECT.frames("frost_nova", 8.0, false)
	add_child(sprite)
	sprite.play()
	_process(0.0)
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, EXPAND_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "fade", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)


# The ring grows from the caster out to the nova's radius, then fades.
func _process(_delta: float) -> void:
	sprite.scale = Vector2.ONE * lerpf(10.0, radius, progress) / ART_RADIUS
	sprite.modulate.a = fade


# Hits every living enemy in reach once, each with its own damage and crit roll.
func strike() -> Array:
	var struck := []
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position) > radius + ENEMY_REACH:
			continue
		var critical := rng.randf() * 100.0 < crit_chance
		var damage := rng.randf_range(damage_range.x, damage_range.y) * damage_scale
		if critical:
			damage *= crit_multiplier
		enemy.take_damage(damage, critical, chill_time)
		struck.append({"enemy": enemy, "damage": damage, "critical": critical})
	return struck


extends Area2D

const MAX_HEALTH := 30.0
const ANIMATIONS := preload("res://animation_library.gd")
const WORLD := preload("res://world.gd")
const HOSTILE_BOLT_SCRIPT := preload("res://enemy_projectile.gd")
const LOOT := preload("res://loot.gd")
# Enemies have four facings; the index follows the angle, clockwise from east.
const DIRECTIONS := ["east", "south", "west", "north"]
const DEATH_FADE := 0.6
# Enemies notice the wizard within this distance, or when shot.
const AGGRO_RADIUS := 220.0
# How far past its reach a melee swing still connects when it lands.
const REACH_SLACK := 12.0
# Enemies closer than this push apart so they don't stack.
const SPACING := 30.0
# Chilled enemies move, animate, and recover from attacks at this fraction of their speed.
const CHILL_SLOW := 0.7
const CHILL_TINT := Color(0.72, 0.9, 1.35)
# Per kind: movement, attack clip, the frame the blow lands on, and cooldown after an attack.
# A ranged kind holds around its reach and fires a bolt instead of striking.
const KINDS := {
	"skitter": {"speed": 85.0, "reach": 30.0, "damage": 8.0, "damage_type": "physical", "cooldown": 1.2, "ranged": false,
		"attack": "attack", "hit_frame": 2, "speeds": {"idle": 1.1, "move": 12.0, "attack": 10.0}},
	"scholar": {"speed": 45.0, "reach": 170.0, "damage": 10.0, "damage_type": "fire", "cooldown": 2.5, "ranged": true,
		"attack": "cast", "hit_frame": 2, "speeds": {"idle": 1.1, "move": 8.0, "cast": 8.0}},
	"sentinel": {"speed": 38.0, "reach": 38.0, "damage": 16.0, "damage_type": "physical", "cooldown": 2.0, "ranged": false,
		"attack": "attack", "hit_frame": 2, "speeds": {"idle": 1.1, "move": 7.0, "attack": 6.0}},
}

# Folder under res://assets/enemies holding this enemy's frames, and its KINDS entry.
@export var kind := "skitter"
# When off, the enemy only turns to watch the wizard: a training dummy.
@export var ai_enabled := true
var health := MAX_HEALTH
var facing := "south"
var aggro := false
var attacking := false
var attack_landed := false
var cooldown_left := 0.0
var hurting := false
var dying := false
var hit_flash: Tween
var chilled_left := 0.0
var stats: Dictionary
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("enemies")
	stats = KINDS[kind]
	var speeds: Dictionary = stats.speeds.duplicate()
	speeds.merge({"hurt": 10.0, "death": 8.0})
	sprite.sprite_frames = ANIMATIONS.build("res://assets/enemies/" + kind, DIRECTIONS, speeds, [stats.attack, "hurt", "death"])
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	_face(_player())
	_play("idle")


func _physics_process(delta: float) -> void:
	if dying:
		return
	_update_chill(delta)
	if hurting or attacking:
		return
	var pace := speed_factor()
	cooldown_left = maxf(0.0, cooldown_left - delta * pace)
	var player = _player()
	_face(player)
	if player == null or player.dead or not ai_enabled:
		_play("idle")
		return
	var offset: Vector2 = player.global_position - global_position
	var distance := offset.length()
	if not aggro and distance > AGGRO_RADIUS:
		_play("idle")
		return
	aggro = true
	var velocity := Vector2.ZERO
	if distance > stats.reach:
		velocity = offset / distance * stats.speed
	elif stats.ranged and distance < stats.reach * 0.6:
		# Casters back off when the wizard closes in.
		velocity = -offset / distance * stats.speed
	if distance <= stats.reach + REACH_SLACK and cooldown_left <= 0.0:
		_start_attack()
		return
	velocity += _separation() * stats.speed
	position += velocity * pace * delta
	position = position.clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
	_play("move" if not velocity.is_zero_approx() else "idle")


# Takes a hit; a chill (in seconds) slows the enemy, and a longer chill replaces a shorter one.
func take_damage(amount: float, critical := false, chill := 0.0) -> void:
	if health <= 0.0 or amount <= 0.0:
		return
	if chill > 0.0:
		chilled_left = maxf(chilled_left, chill)
		_update_chill(0.0)
	health = maxf(0.0, health - amount)
	aggro = true
	# A hit interrupts an attack before its blow lands.
	attacking = false
	queue_redraw()
	if health <= 0.0:
		# Stop being a target at once; the body stays for the death animation.
		dying = true
		collision_layer = 0
		remove_from_group("enemies")
		_play("death")
		# Deferred: this can run inside the bolt's physics query.
		LOOT.drop_for.call_deferred(kind, global_position, get_parent())
		return
	hurting = true
	_play("hurt")
	sprite.set_frame_and_progress(0, 0.0)
	if hit_flash:
		hit_flash.kill()
	# Critical hits flash white-hot.
	sprite.self_modulate = Color(2.4, 2.2, 2.0) if critical else Color(1.8, 1.3, 1.3)
	hit_flash = create_tween()
	hit_flash.tween_property(sprite, "self_modulate", Color.WHITE, 0.12)


func is_chilled() -> bool:
	return chilled_left > 0.0


func speed_factor() -> float:
	return CHILL_SLOW if is_chilled() else 1.0


func _update_chill(delta: float) -> void:
	if chilled_left > 0.0:
		chilled_left = maxf(0.0, chilled_left - delta)
	sprite.speed_scale = speed_factor()
	var tint := CHILL_TINT if is_chilled() else Color.WHITE
	# Keep the current alpha: the death fade animates it.
	modulate = Color(tint, modulate.a)


func _start_attack() -> void:
	attacking = true
	attack_landed = false
	_play(stats.attack)
	sprite.set_frame_and_progress(0, 0.0)


# The blow lands on the clip's hit frame, so there is a windup to react to.
func _on_frame_changed() -> void:
	if not attacking or attack_landed or sprite.frame != stats.hit_frame:
		return
	attack_landed = true
	var player = _player()
	if player == null or player.dead:
		return
	if stats.ranged:
		var bolt := Node2D.new()
		bolt.set_script(HOSTILE_BOLT_SCRIPT)
		bolt.damage = stats.damage
		bolt.damage_type = stats.damage_type
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -12)
		bolt.direction = bolt.global_position.direction_to(player.global_position)
	elif global_position.distance_to(player.global_position) <= stats.reach + REACH_SLACK:
		player.take_damage(stats.damage, stats.damage_type)


func _on_animation_finished() -> void:
	if dying:
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, DEATH_FADE)
		fade.tween_callback(queue_free)
	elif attacking or hurting:
		if attacking:
			cooldown_left = stats.cooldown
		attacking = false
		hurting = false
		# Turn to the wizard now, so idle never plays a stale facing.
		_face(_player())
		_play("idle")


func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other: Node2D in get_tree().get_nodes_in_group("enemies"):
		var away := global_position - other.global_position
		if other != self and away.length() < SPACING and not away.is_zero_approx():
			push += away.normalized() * (1.0 - away.length() / SPACING)
	return push


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _face(player: Node2D) -> void:
	if player == null:
		return
	var offset := player.global_position - global_position
	if not offset.is_zero_approx():
		facing = ANIMATIONS.facing_toward(offset, DIRECTIONS)


func _play(action: String) -> void:
	var animation := "%s_%s" % [action, facing]
	if sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)


func _draw() -> void:
	if 0.0 < health and health < MAX_HEALTH:
		draw_rect(Rect2(-16, -35, 32, 4), Color("181c24"))
		draw_rect(Rect2(-15, -34, 30.0 * health / MAX_HEALTH, 2), Color("d66765"))

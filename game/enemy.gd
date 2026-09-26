extends Area2D

const MAX_HEALTH := 3
const ANIMATIONS := preload("res://animation_library.gd")
# Enemies have four facings; the index follows the angle, clockwise from east.
const DIRECTIONS := ["east", "south", "west", "north"]
const ANIMATION_SPEEDS := {"idle": 1.1, "hurt": 10.0, "death": 8.0}
const DEATH_FADE := 0.6

# Folder under res://assets/enemies holding this enemy's frames.
@export var kind := "skitter"
var health := MAX_HEALTH
var facing := "south"
var hurting := false
var dying := false
var hit_flash: Tween
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("enemies")
	sprite.sprite_frames = ANIMATIONS.build("res://assets/enemies/" + kind, DIRECTIONS, ANIMATION_SPEEDS, ["hurt", "death"])
	sprite.animation_finished.connect(_on_animation_finished)
	_face_player()
	_play("idle")


func _process(_delta: float) -> void:
	if hurting or dying:
		return
	var previous := facing
	_face_player()
	if facing != previous:
		_play("idle")


func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	queue_redraw()
	if health == 0:
		# Stop being a target at once; the body stays for the death animation.
		dying = true
		collision_layer = 0
		remove_from_group("enemies")
		_play("death")
		return
	hurting = true
	_play("hurt")
	sprite.set_frame_and_progress(0, 0.0)
	if hit_flash:
		hit_flash.kill()
	sprite.self_modulate = Color(1.8, 1.3, 1.3)
	hit_flash = create_tween()
	hit_flash.tween_property(sprite, "self_modulate", Color.WHITE, 0.12)


func _on_animation_finished() -> void:
	if dying:
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, DEATH_FADE)
		fade.tween_callback(queue_free)
	elif hurting:
		hurting = false
		_play("idle")


func _face_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
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
	if 0 < health and health < MAX_HEALTH:
		draw_rect(Rect2(-16, -35, 32, 4), Color("181c24"))
		draw_rect(Rect2(-15, -34, 30.0 * health / MAX_HEALTH, 2), Color("d66765"))

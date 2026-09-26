extends Node2D

const SPEED := 110.0
const PROJECTILE_SCRIPT := preload("res://projectile.gd")
const WORLD := preload("res://world.gd")
const ANIMATIONS := preload("res://animation_library.gd")
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
# Where the staff's orb sits in each facing, relative to the sprite centre; bolts launch from it.
const STAFF_TIPS := {
	"east": Vector2(7, -18), "south-east": Vector2(-9, -17), "south": Vector2(-21, -20), "south-west": Vector2(-19, -22),
	"west": Vector2(-9, -24), "north-west": Vector2(8, -24), "north": Vector2(20, -22), "north-east": Vector2(20, -19),
}
const ANIMATION_SPEEDS := {"idle": 1.1, "move": 16.0, "cast": 14.0, "dodge": 20.0}
const DODGE_SPEED := 340.0
const DODGE_TIME := 0.2
const DODGE_COOLDOWN := 0.5
const AFTERIMAGE_INTERVAL := 0.04
const AFTERIMAGE_FADE := 0.25

var facing := "south"
var casting := false
var dodge_direction := Vector2.ZERO
var dodge_time_left := 0.0
var dodge_cooldown_left := 0.0
var afterimage_time_left := 0.0
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = ANIMATIONS.build("res://assets/wizard", DIRECTIONS, ANIMATION_SPEEDS, ["cast", "dodge"])
	sprite.animation_finished.connect(func() -> void: casting = false)
	_play("idle")


func _physics_process(delta: float) -> void:
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	if is_dodging():
		_dodge_step(delta)
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += movement * SPEED * delta
	position = position.clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
	# A cast finishes facing its aim; movement continues underneath it.
	if casting:
		return
	if movement != Vector2.ZERO:
		var direction_index := posmod(roundi(movement.angle() / (PI / 4.0)), 8)
		facing = DIRECTIONS[direction_index]
		_play("move")
	else:
		_play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge", false, true):
		dodge()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_dodging():
		shoot_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func shoot_at(target: Vector2) -> Node2D:
	var aim := target - global_position
	if aim.is_zero_approx():
		return null
	facing = DIRECTIONS[posmod(roundi(aim.angle() / (PI / 4.0)), 8)]
	var tip: Vector2 = global_position + STAFF_TIPS[facing]
	# Aim from the tip so the bolt still flies through the clicked point.
	var flight := target - tip
	var projectile := Node2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.direction = flight.normalized() if not flight.is_zero_approx() else aim.normalized()
	get_parent().add_child(projectile)
	projectile.global_position = tip
	# The first hit check sweeps from the body, so an enemy between the wizard and the tip is still hit.
	projectile.sweep_from = global_position
	casting = true
	_play("cast")
	sprite.set_frame_and_progress(0, 0.0)
	return projectile


func is_dodging() -> bool:
	return dodge_time_left > 0.0


# Dashes toward the held movement keys, or the facing when standing still.
func dodge() -> bool:
	if is_dodging() or dodge_cooldown_left > 0.0:
		return false
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(DIRECTIONS.find(facing) * PI / 4.0)
	dodge_direction = direction.normalized()
	facing = DIRECTIONS[posmod(roundi(dodge_direction.angle() / (PI / 4.0)), 8)]
	dodge_time_left = DODGE_TIME
	dodge_cooldown_left = DODGE_TIME + DODGE_COOLDOWN
	afterimage_time_left = 0.0
	casting = false
	_play("dodge")
	sprite.set_frame_and_progress(0, 0.0)
	return true


func _dodge_step(delta: float) -> void:
	var step := minf(delta, dodge_time_left)
	dodge_time_left -= step
	if is_zero_approx(dodge_time_left):
		dodge_time_left = 0.0
	position += dodge_direction * DODGE_SPEED * step
	position = position.clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
	afterimage_time_left -= step
	if afterimage_time_left <= 0.0:
		afterimage_time_left = AFTERIMAGE_INTERVAL
		_spawn_afterimage()


# A fading, tinted copy of the current frame left behind along the dash.
func _spawn_afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.texture_filter = sprite.texture_filter
	ghost.modulate = Color(0.55, 0.8, 1.0, 0.55)
	# Just before the wizard in the tree: above the ground, beneath the wizard.
	get_parent().add_child(ghost)
	get_parent().move_child(ghost, get_index())
	ghost.global_position = sprite.global_position
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, AFTERIMAGE_FADE)
	fade.tween_callback(ghost.queue_free)


func _play(action: String) -> void:
	var animation := "%s_%s" % [action, facing]
	if sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)

extends Node2D

const SPEED := 110.0
const PROJECTILE_SCRIPT := preload("res://projectile.gd")
const WORLD := preload("res://world.gd")
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var facing := "south"
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction: String in DIRECTIONS:
		var rotation_path := "res://assets/wizard/rotations/%s.png" % direction
		if not ResourceLoader.exists(rotation_path):
			continue
		var rotation := load(rotation_path) as Texture2D
		for action: String in ["idle", "move"]:
			var animation := "%s_%s" % [action, direction]
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 10.0 if action == "move" else 5.0)
			var folder := "res://assets/wizard/%s/%s" % [action, direction]
			if DirAccess.dir_exists_absolute(folder):
				for file: String in DirAccess.get_files_at(folder):
					if file.ends_with(".png"):
						frames.add_frame(animation, load(folder.path_join(file)))
			if frames.get_frame_count(animation) == 0:
				frames.add_frame(animation, rotation)
	sprite.sprite_frames = frames
	_play("idle")


func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += movement * SPEED * delta
	position = position.clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
	if movement != Vector2.ZERO:
		var direction_index := posmod(roundi(movement.angle() / (PI / 4.0)), 8)
		facing = DIRECTIONS[direction_index]
		_play("move")
	else:
		_play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func shoot_at(target: Vector2) -> Node2D:
	var aim := target - global_position
	if aim.is_zero_approx():
		return null
	var projectile := Node2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.direction = aim.normalized()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	facing = DIRECTIONS[posmod(roundi(aim.angle() / (PI / 4.0)), 8)]
	_play("idle")
	return projectile


func _play(action: String) -> void:
	var animation := "%s_%s" % [action, facing]
	if sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)

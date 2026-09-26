extends AnimatedSprite2D

const ANIMATIONS := preload("res://animation_library.gd")

# Folder under res://assets/props holding this prop's looping frames.
@export var kind := "candle"
@export var fps := 8.0


func _ready() -> void:
	sprite_frames = SpriteFrames.new()
	sprite_frames.set_animation_speed("default", fps)
	for texture in ANIMATIONS.folder_frames("res://assets/props/" + kind):
		sprite_frames.add_frame("default", texture)
	# Start each copy at a different point so a row of props doesn't flicker in unison.
	play("default")
	if sprite_frames.get_frame_count("default") > 0:
		set_frame_and_progress(randi() % sprite_frames.get_frame_count("default"), randf())

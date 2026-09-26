extends Node2D

const ANIMATIONS := preload("res://animation_library.gd")
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
const ANIMATION_SPEEDS := {"idle": 1.1}

# Folder under res://assets/npcs holding this character's frames.
@export var kind := "caretaker"
var facing := "south"
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = ANIMATIONS.build("res://assets/npcs/" + kind, DIRECTIONS, ANIMATION_SPEEDS, [])
	_process(0.0)


# Idles in place, turning to watch the wizard.
func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and not player.global_position.is_equal_approx(global_position):
		facing = ANIMATIONS.facing_toward(player.global_position - global_position, DIRECTIONS)
	var animation := "idle_" + facing
	if sprite.animation != animation and sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)

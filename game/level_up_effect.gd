extends Node2D

# A burst of gold and cyan sparkles around the wizard on a new level.

const GOLD := Color("f2c14e")
const EFFECT := preload("res://effect.gd")
const TIME := 1.0
const RISE := 24.0

var progress := 0.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	z_index = 1
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = EFFECT.frames("level_up", 7.0, false)
	# The burst art is small; twice its size surrounds the wizard.
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	sprite.play()
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(queue_free)


func _process(_delta: float) -> void:
	# Rises from the wizard's chest; stays bright most of the way, then fades out.
	sprite.position = Vector2(0, -20 - progress * RISE).round()
	sprite.modulate.a = 1.0 - progress * progress

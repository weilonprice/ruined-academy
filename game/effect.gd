extends Node2D

# Sprite effects from res://assets/effects/<name>/*.png. A spawned effect plays
# its frames once, fading out over the clip, then frees itself; looping clips
# (bolts, chill) are plain AnimatedSprite2D children made by looping().

const ANIMATIONS := preload("res://animation_library.gd")
const ROOT := "res://assets/effects/"

static var cache := {}


# The clip for an effect, built once and shared.
static func frames(effect: String, fps: float, loop: bool) -> SpriteFrames:
	var key := "%s@%s@%s" % [effect, fps, loop]
	if not cache.has(key):
		var clip := SpriteFrames.new()
		clip.set_animation_speed("default", fps)
		clip.set_animation_loop("default", loop)
		for texture in ANIMATIONS.folder_frames(ROOT + effect):
			clip.add_frame("default", texture)
		cache[key] = clip
	return cache[key]


# A looping sprite for a parent to carry, already playing.
static func looping(effect: String, fps: float) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames(effect, fps, true)
	sprite.play()
	return sprite


# Plays an effect once at a point in the parent, then frees it.
static func spawn(parent: Node, effect: String, at: Vector2, fps := 16.0, size := 1.0) -> Node2D:
	var node: Node2D = new()
	node.z_index = 1
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames(effect, fps, false)
	node.add_child(sprite)
	node.scale = Vector2.ONE * size
	parent.add_child(node)
	node.global_position = at
	sprite.animation_finished.connect(node.queue_free)
	sprite.play()
	# The generated clips end abruptly, so fade over the last half.
	var length := sprite.sprite_frames.get_frame_count("default") / fps
	var tween := node.create_tween()
	tween.tween_interval(length * 0.5)
	tween.tween_property(node, "modulate:a", 0.0, length * 0.5)
	return node

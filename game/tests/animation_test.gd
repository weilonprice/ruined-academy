extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Wizard")
	var sprite: AnimatedSprite2D = player.get_node("Sprite")
	var frames := sprite.sprite_frames
	for direction in player.DIRECTIONS:
		assert(frames.get_frame_count("idle_" + direction) == 4, "Idle uses the generated 4-frame clip")
		assert(frames.get_frame_count("move_" + direction) == 8, "Walk uses the generated 8-frame clip")
		assert(frames.get_frame_count("cast_" + direction) == 4, "Cast uses the generated 4-frame clip")
		assert(frames.get_animation_loop("move_" + direction) and not frames.get_animation_loop("cast_" + direction))
	await process_frame
	assert(sprite.animation == &"idle_south")

	# Casting faces the aim, overrides walking until done, then walking resumes.
	Input.action_press("move_right")
	await physics_step()
	assert(sprite.animation == &"move_east")
	player.shoot_at(player.global_position + Vector2(0, -100))
	assert(player.casting and sprite.animation == &"cast_north" and sprite.frame == 0)
	await physics_step()
	assert(sprite.animation == &"cast_north", "Walking must not interrupt a cast")
	for frame in range(240):
		await process_frame
		if not player.casting:
			break
	assert(not player.casting, "Cast must finish")
	await physics_step()
	assert(sprite.animation == &"move_east")
	Input.action_release("move_right")
	await physics_step()
	assert(sprite.animation == &"idle_east")

	# A new shot restarts the cast from its first frame.
	player.shoot_at(player.global_position + Vector2(100, 0))
	await process_frame
	await process_frame
	player.shoot_at(player.global_position + Vector2(-100, 0))
	assert(sprite.animation == &"cast_west" and sprite.frame == 0)
	for projectile in get_nodes_in_group("projectiles"):
		projectile.queue_free()
	print("PASS: idle/walk/cast clips in 8 directions; cast faces aim, overrides walk, restarts per shot, returns to walk/idle")
	scene.queue_free()
	quit()


# physics_frame fires before nodes process, so wait two to observe one update.
func physics_step() -> void:
	await physics_frame
	await physics_frame

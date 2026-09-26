extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Wizard")
	# These checks are about the wizard; keep enemies from joining in.
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
	var sprite: AnimatedSprite2D = player.get_node("Sprite")
	var frames := sprite.sprite_frames
	for direction in player.DIRECTIONS:
		assert(frames.get_frame_count("idle_" + direction) == 2, "Idle uses the 2-frame breathing loop")
		assert(frames.get_frame_count("move_" + direction) == 8, "Walk uses the generated 8-frame clip")
		assert(frames.get_frame_count("cast_" + direction) == 4, "Cast uses the generated 4-frame clip")
		assert(frames.get_frame_count("dodge_" + direction) == 4 and not frames.get_animation_loop("dodge_" + direction), "Dodge plays a 4-frame clip once")
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

	# A dodge cancels a cast and plays the dodge clip toward the dash.
	player.shoot_at(player.global_position + Vector2(100, 0))
	player.facing = "north"
	assert(player.dodge())
	assert(not player.casting and sprite.animation == &"dodge_north" and sprite.frame == 0)
	for frame in range(60):
		await physics_frame
		if not player.is_dodging():
			break
	await physics_step()
	assert(sprite.animation == &"idle_north")
	player.dodge_cooldown_left = 0.0

	# A new shot restarts the cast from its first frame.
	player.shoot_at(player.global_position + Vector2(100, 0))
	await process_frame
	await process_frame
	player.shoot_at(player.global_position + Vector2(-100, 0))
	assert(sprite.animation == &"cast_west" and sprite.frame == 0)
	for projectile in get_nodes_in_group("projectiles"):
		projectile.queue_free()

	# Each enemy kind has breathing idle, hurt, and death clips in four facings.
	for kind in ["Skitter", "Scholar", "Sentinel"]:
		var enemy_frames: SpriteFrames = scene.get_node(kind + "/Sprite").sprite_frames
		for direction in ["south", "east", "north", "west"]:
			assert(enemy_frames.get_frame_count("idle_" + direction) == 2, kind + " breathing idle")
			assert(enemy_frames.get_frame_count("hurt_" + direction) == 4, kind + " hurt clip")
			assert(enemy_frames.get_frame_count("death_" + direction) == 4, kind + " death clip")
			assert(not enemy_frames.get_animation_loop("death_" + direction))
	# Enemies turn to face the wizard.
	# A fresh enemy, clear of the bolts fired above.
	var enemy = load("res://enemy.tscn").instantiate()
	enemy.kind = "scholar"
	enemy.ai_enabled = false
	enemy.position = Vector2(300, 800)
	scene.add_child(enemy)
	var enemy_sprite: AnimatedSprite2D = enemy.get_node("Sprite")
	player.position = enemy.position + Vector2(0, 200)
	await process_step()
	assert(enemy_sprite.animation == &"idle_south")
	player.position = enemy.position + Vector2(-200, 0)
	await process_step()
	assert(enemy_sprite.animation == &"idle_west")
	# A hit plays hurt once, holding the facing, then returns to idle.
	enemy.take_damage(1)
	assert(enemy.hurting and enemy_sprite.animation == &"hurt_west")
	player.position = enemy.position + Vector2(200, 0)
	await process_step()
	assert(enemy_sprite.animation == &"hurt_west", "Hurt must not be interrupted by turning")
	for frame in range(120):
		await process_frame
		if not enemy.hurting:
			break
	await process_frame
	assert(not enemy.hurting and enemy_sprite.animation == &"idle_east")
	# The killing hit plays death, then the body fades and despawns.
	enemy.take_damage(2)
	assert(enemy.dying and enemy_sprite.animation == &"death_east")
	for frame in range(300):
		await process_frame
		if not is_instance_valid(enemy):
			break
	assert(not is_instance_valid(enemy), "Dead enemy must despawn")
	# NPCs breathe in 8 facings and watch the wizard; candles flicker.
	for kind in ["Caretaker", "Artificer"]:
		var npc = scene.get_node(kind)
		var npc_sprite: AnimatedSprite2D = npc.get_node("Sprite")
		for direction in player.DIRECTIONS:
			assert(npc_sprite.sprite_frames.get_frame_count("idle_" + direction) == 2, kind + " breathing idle")
		player.position = npc.position + Vector2(0, -150)
		await process_step()
		assert(npc_sprite.animation == &"idle_north" and npc_sprite.is_playing())
		player.position = npc.position + Vector2(150, 150)
		await process_step()
		assert(npc_sprite.animation == &"idle_south-east")
	for index in range(1, 5):
		var candle: AnimatedSprite2D = scene.get_node("Candle%d" % index)
		assert(candle.sprite_frames.get_frame_count("default") == 5 and candle.is_playing(), "Candles flicker")
	assert(scene.y_sort_enabled, "Characters and props overlap by depth")
	print("PASS: wizard idle/walk/cast/dodge in 8 directions, cast faces aim and overrides walk, dodge cancels cast; enemy idle/hurt/death in 4 directions, enemies face wizard, hurt returns to idle, death then despawn; NPC idles watch the wizard; candles flicker")
	scene.queue_free()
	quit()


# physics_frame and process_frame fire before nodes process, so wait two to observe one update.
func process_step() -> void:
	await process_frame
	await process_frame


func physics_step() -> void:
	await physics_frame
	await physics_frame

extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	var enemies := get_nodes_in_group("enemies")
	assert(enemies.size() == 3, "Scene must contain exactly three enemies")
	var starts: Array[Vector2] = []
	for enemy in enemies:
		starts.append(enemy.position)
	for i in range(10):
		await physics_frame
	for i in range(3):
		assert(enemies[i].position == starts[i], "Enemies must stay stationary")

	# A press creates one shot; release and right-click create none.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	assert(get_nodes_in_group("projectiles").size() == 1)
	click.pressed = false
	player._unhandled_input(click)
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	player._unhandled_input(click)
	assert(get_nodes_in_group("projectiles").size() == 1)
	get_nodes_in_group("projectiles")[0].queue_free()
	await process_frame
	assert(player.shoot_at(player.global_position) == null, "Zero-length aim should not create a stuck shot")

	for target in enemies:
		for hit in range(3):
			var shot: Node2D = player.shoot_at(target.global_position)
			assert(shot.global_position.is_equal_approx(player.global_position + player.STAFF_TIPS[player.facing]), "Shots launch from the staff tip")
			assert(shot.direction.is_equal_approx(shot.global_position.direction_to(target.global_position)), "Shots fly through the clicked point")
			# Use actual physics updates to exercise collision, damage, and cleanup together.
			for frame in range(120):
				await physics_frame
				if not is_instance_valid(shot):
					break
			assert(not is_instance_valid(shot), "Shot must disappear on hit")
			if hit < 2:
				assert(is_instance_valid(target), "Nonlethal damage must preserve the enemy")
				assert(target.health == 2 - hit, "A projectile must damage only once")
			else:
				assert(target.dying and target.collision_layer == 0 and not target.is_in_group("enemies"), "A killed enemy stops being a target at once")
	assert(get_nodes_in_group("enemies").is_empty())
	# Bodies stay for the death animation and fade, then despawn.
	for frame in range(300):
		await process_frame
		if not enemies.any(func(e) -> bool: return is_instance_valid(e)):
			break
	assert(not enemies.any(func(e) -> bool: return is_instance_valid(e)), "Enemy must despawn after its death animation")

	# A large frame step must hit the nearest target instead of tunneling through it.
	var enemy_scene: PackedScene = load("res://enemy.tscn")
	var near_target = enemy_scene.instantiate()
	var far_target = enemy_scene.instantiate()
	scene.add_child(near_target)
	scene.add_child(far_target)
	near_target.position = Vector2(880, 480)
	far_target.position = Vector2(960, 480)
	await physics_frame
	await physics_frame
	var fast_shot: Node2D = player.shoot_at(far_target.global_position)
	fast_shot.set_physics_process(false)
	fast_shot._physics_process(1.0)
	assert(near_target.health == 2 and far_target.health == 3)
	await process_frame
	assert(not is_instance_valid(fast_shot))

	player.position = near_target.position
	var overlapping_shot: Node2D = player.shoot_at(far_target.global_position)
	overlapping_shot.set_physics_process(false)
	overlapping_shot._physics_process(0.016)
	assert(near_target.health == 1, "An overlapping target must take damage")
	await process_frame

	player.position = Vector2(800, 900)
	var missed_shot: Node2D = player.shoot_at(Vector2(800, 1000))
	missed_shot.set_physics_process(false)
	missed_shot._physics_process(1.0)
	await process_frame
	assert(not is_instance_valid(missed_shot), "Missed shots must be removed outside the map")
	print("PASS: 3 stationary enemies; left click only; staff-tip launch; mouse-target aim; damage once per shot; zero-health death animation then despawn; swept nearest hit; overlap hit; missed-shot cleanup")
	scene.queue_free()
	quit()

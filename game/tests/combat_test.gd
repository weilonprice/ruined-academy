extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Wizard")
	# A private save file, so the tests never touch the player's own gear.
	var inventory = root.get_node("Inventory")
	inventory.use_save_path("user://test_inventory.json")
	inventory.clear()
	# These checks are about the wizard; keep enemies from joining in.
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
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
	ready_cast(player)
	assert(player.shoot_at(player.global_position) == null, "Zero-length aim should not create a stuck shot")

	for target in enemies:
		for hit in range(20):
			ready_cast(player)
			var before: float = target.health
			var shot: Node2D = player.shoot_at(target.global_position)
			var damage: float = shot.damage
			assert(shot.global_position.is_equal_approx(player.global_position + player.STAFF_TIPS[player.facing]), "Shots launch from the staff tip")
			assert(shot.direction.is_equal_approx(shot.global_position.direction_to(target.global_position)), "Shots fly through the clicked point")
			# Use actual physics updates to exercise collision, damage, and cleanup together.
			for frame in range(120):
				await physics_frame
				if not is_instance_valid(shot):
					break
			assert(not is_instance_valid(shot), "Shot must disappear on hit")
			if before > damage:
				assert(is_instance_valid(target) and not target.dying, "Nonlethal damage must preserve the enemy")
				assert(is_equal_approx(target.health, before - damage), "A projectile must damage only once")
			else:
				assert(target.dying and target.collision_layer == 0 and not target.is_in_group("enemies"), "A killed enemy stops being a target at once")
				break
		assert(target.dying, "Enough shots kill an enemy")
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
	near_target.ai_enabled = false
	far_target.ai_enabled = false
	scene.add_child(near_target)
	scene.add_child(far_target)
	near_target.position = Vector2(880, 480)
	far_target.position = Vector2(960, 480)
	await physics_frame
	await physics_frame
	ready_cast(player)
	var fast_shot: Node2D = player.shoot_at(far_target.global_position)
	fast_shot.set_physics_process(false)
	fast_shot._physics_process(1.0)
	assert(is_equal_approx(near_target.health, near_target.MAX_HEALTH - fast_shot.damage) and far_target.health == far_target.MAX_HEALTH)
	await process_frame
	assert(not is_instance_valid(fast_shot))

	player.position = near_target.position
	ready_cast(player)
	var near_before: float = near_target.health
	var overlapping_shot: Node2D = player.shoot_at(far_target.global_position)
	overlapping_shot.set_physics_process(false)
	overlapping_shot._physics_process(0.016)
	assert(near_target.health < near_before, "An overlapping target must take damage")
	await process_frame

	player.position = Vector2(800, 900)
	ready_cast(player)
	var missed_shot: Node2D = player.shoot_at(Vector2(800, 1000))
	missed_shot.set_physics_process(false)
	missed_shot._physics_process(1.0)
	await process_frame
	assert(not is_instance_valid(missed_shot), "Missed shots must be removed outside the map")
	print("PASS: 3 stationary enemies; left click only; staff-tip launch; mouse-target aim; rolled damage once per shot; zero-health death animation then despawn; swept nearest hit; overlap hit; missed-shot cleanup")
	scene.queue_free()
	DirAccess.remove_absolute("user://test_inventory.json")
	quit()


# Skips the cast cooldown and refills mana, so each check fires on demand.
func ready_cast(player) -> void:
	player.cast_ready_in = 0.0
	player.mana = player.max_mana

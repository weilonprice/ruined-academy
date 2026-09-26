extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	var origin := Vector2(800, 480)
	for entry in [["move_up", KEY_W, Vector2.UP], ["move_left", KEY_A, Vector2.LEFT], ["move_down", KEY_S, Vector2.DOWN], ["move_right", KEY_D, Vector2.RIGHT]]:
		assert(InputMap.action_get_events(entry[0])[0].physical_keycode == entry[1])
		player.position = origin
		Input.action_press(entry[0])
		player._physics_process(0.5)
		Input.action_release(entry[0])
		assert(player.position.is_equal_approx(origin + entry[2] * 55.0))
	player.position = origin
	Input.action_press("move_up")
	Input.action_press("move_right")
	player._physics_process(0.5)
	assert(is_equal_approx(player.position.distance_to(origin), 55.0))
	Input.action_release("move_up")
	Input.action_release("move_right")
	var stopped: Vector2 = player.position
	player._physics_process(0.5)
	assert(player.position == stopped)
	for action in ["move_up", "move_left", "move_down", "move_right"]:
		Input.action_press(action)
		player._physics_process(100.0)
		Input.action_release(action)
		assert(player.position.x >= 32 and player.position.x <= 1568)
		assert(player.position.y >= 32 and player.position.y <= 928)

	# Space dodges: a fixed dash toward held keys, or the facing when still.
	assert(InputMap.action_get_events("dodge")[0].physical_keycode == KEY_SPACE)
	var dash: float = player.DODGE_SPEED * player.DODGE_TIME
	player.position = origin
	player.facing = "south"
	assert(player.dodge())
	assert(not player.dodge(), "No second dodge mid-dash")
	for step in range(10):
		player._physics_process(0.05)
	assert(player.position.is_equal_approx(origin + Vector2.DOWN * dash), "Standing dodge follows the facing")
	assert(not player.is_dodging())
	assert(not player.dodge(), "Cooldown blocks an immediate dodge")
	player._physics_process(player.DODGE_COOLDOWN)
	player.position = origin
	Input.action_press("move_up")
	Input.action_press("move_left")
	assert(player.dodge())
	# Movement keys do not steer or add to a dash in progress.
	for step in range(10):
		player._physics_process(0.05)
	Input.action_release("move_up")
	Input.action_release("move_left")
	var dashed: Vector2 = player.position - origin
	assert(is_equal_approx(dashed.length(), dash + player.SPEED * (0.5 - player.DODGE_TIME)), "Dash length, then walking resumes")
	assert(player.facing == "north-west")
	await process_frame
	assert(get_nodes_in_group("projectiles").is_empty())
	var ghosts := scene.get_children().filter(func(n: Node) -> bool: return n is Sprite2D)
	assert(ghosts.size() >= 4, "Dashes leave afterimages")
	for frame in range(60):
		await process_frame
	assert(scene.get_children().filter(func(n: Node) -> bool: return n is Sprite2D).is_empty(), "Afterimages fade and free")
	player._physics_process(player.DODGE_COOLDOWN)
	player.position = Vector2(40, 480)
	player.facing = "west"
	player.dodge()
	player._physics_process(1.0)
	assert(player.position.x >= 32, "Dodges stay inside the map")
	print("PASS: WASD bindings, four directions, equal diagonal speed, release stops, map bounds; Space dodge dash, facing fallback, cooldown, afterimages, bounds")
	scene.queue_free()
	quit()

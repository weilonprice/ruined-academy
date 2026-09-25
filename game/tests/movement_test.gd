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
	print("PASS: WASD bindings, four directions, equal diagonal speed, release stops, map bounds")
	scene.queue_free()
	quit()

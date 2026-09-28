extends SceneTree

const GROUND := preload("res://village_ground.gd")
const TRAVEL := preload("res://travel.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.get_node("Inventory").use_save_path("user://test_inventory.json")
	root.get_node("Character").use_save_path("user://test_village_character.json")
	root.get_node("Character").reset()
	var village: Node = load("res://village.tscn").instantiate()
	root.add_child(village)
	current_scene = village
	await process_frame

	# The village has the wizard, the HUD, its ground, its scenery, and six villagers.
	var player = get_first_node_in_group("player")
	check(player != null and player.get_parent() == village, "The wizard is in the village")
	check(village.get_node_or_null("HUD") != null and village.get_node_or_null("Ground") != null)
	var scenery := village.get_children().filter(func(node: Node) -> bool: return node.get("kind") != null and node.has_method("footprint_rect"))
	check(scenery.size() >= 70, "The village is furnished")
	check(scenery.all(func(piece: Node) -> bool: return piece.get_child(0).texture != null), "Every piece has its art")
	var villagers := ["Blacksmith", "Farmer", "Villager", "Militia", "Archer", "Lumberjack"]
	for name in villagers:
		var npc = village.get_node_or_null(name)
		check(npc != null and npc.sprite.sprite_frames.get_frame_count("idle_south") == 2, name + " breathes")

	# Ground tiles follow the corner points: all dirt on the road, all grass away from it, a blend at the edge.
	check(GROUND.tile_for(Vector2i(12, 3)) == 0, "Road is dirt")
	check(GROUND.tile_for(Vector2i(5, 2)) == 15, "Meadow is grass")
	check(GROUND.tile_for(Vector2i(11, 3)) == 10, "West edge of the road: grass on the left corners")

	# Buildings block the wizard's feet; he slides along them and walks freely elsewhere.
	var tavern: Rect2 = village.get_node("Tavern1").footprint_rect()
	player.position = Vector2(tavern.get_center().x, tavern.end.y + 20.0)
	Input.action_press("move_up")
	for step in range(30):
		player._physics_process(0.05)
		check(not tavern.has_point(player.position + player.FEET), "Feet never enter the tavern")
	Input.action_release("move_up")
	check(player.position.y + player.FEET.y >= tavern.end.y - 0.01, "Stopped at the tavern wall")
	player.position = Vector2(tavern.get_center().x, tavern.end.y + 2.0) - player.FEET
	Input.action_press("move_up")
	Input.action_press("move_right")
	var before: Vector2 = player.position
	player._physics_process(0.1)
	Input.action_release("move_up")
	Input.action_release("move_right")
	check(player.position.x > before.x and is_equal_approx(player.position.y, before.y), "Slides along the wall")
	player.position = Vector2(800, 600)
	Input.action_press("move_up")
	player._physics_process(0.2)
	Input.action_release("move_up")
	check(is_equal_approx(player.position.y, 600 - player.SPEED * 0.2), "Open road does not slow him")

	# The south road leads to the academy, and he arrives with the life and flask charges he left with.
	check(TRAVEL.carried.is_empty())
	player.health = 50.0
	player.flask_charges[0] = 10
	var exit: Node2D = village.get_node("ToAcademy")
	player.global_position = exit.global_position
	var academy := await arrival()
	check(academy != null and academy.scene_file_path == "res://main.tscn", "Road south leads to the academy")
	if academy != null:
		var wizard = academy.get_node("Wizard")
		check(wizard.position == Vector2(1480, 490), "Arrives at the east road end")
		check(is_equal_approx(wizard.health, 50.0) and wizard.flask_charges[0] == 10, "Keeps his life and flask charges")
		check(TRAVEL.carried.is_empty(), "Nothing left over for the next map")
		# And back along the east road.
		wizard.global_position = academy.get_node("ToVillage").global_position
		var back := await arrival()
		check(back != null and back.scene_file_path == "res://village.tscn", "East road leads to the village")
		if back != null:
			check(back.get_node("Wizard").position == Vector2(800, 880), "Arrives at the south road")
	finish("village scene with 6 villagers and furnished grounds; road tiles from corner points; buildings block and slide; roads carry the wizard between maps with his life and flasks")


# Waits for the current scene to change, and returns the new one.
func arrival() -> Node:
	var leaving := current_scene
	for frame in range(30):
		await physics_frame
		if current_scene != leaving and current_scene != null:
			await process_frame
			return current_scene
	return null


func check(condition: bool, message := "") -> void:
	if not condition:
		var caller: Dictionary = get_stack()[1] if get_stack().size() > 1 else {}
		failures.append("%s:%s %s" % [caller.get("function", "?"), caller.get("line", "?"), message])
		push_error("FAIL " + failures[-1])


# Prints PASS only if nothing failed, and exits non-zero otherwise.
func finish(summary: String) -> void:
	if failures.is_empty():
		print("PASS: " + summary)
		quit()
	else:
		print("FAIL: %d check(s) failed" % failures.size())
		for failure in failures:
			print("  " + failure)
		quit(1)

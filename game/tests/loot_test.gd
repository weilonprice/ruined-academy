extends SceneTree

const DB := preload("res://items/item_database.gd")
const ITEM := preload("res://items/item.gd")
const LOOT := preload("res://loot.gd")
const WORLD := preload("res://world.gd")
const SAVE := "user://test_inventory.json"

var failures: Array[String] = []
var inventory


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	inventory = root.get_node("Inventory")
	inventory.use_save_path(SAVE)
	inventory.clear()
	check_drop_tables()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false

	# A dying enemy drops its loot around where it fell.
	LOOT.rng.seed = 1
	var sentinel = scene.get_node("Sentinel")
	var fell_at: Vector2 = sentinel.global_position
	sentinel.take_damage(999.0)
	await settle()
	var drops := get_nodes_in_group("ground_items")
	check(drops.size() >= 1, "A sentinel always drops something")
	for drop in drops:
		check(drop.landed and drop.global_position.distance_to(fell_at) <= LOOT.SCATTER * 2.0 + 0.5, "Drops land near the body")
		check(WORLD.WALK_BOUNDS.has_point(drop.global_position), "Drops land inside the map")
		check(drop.item.item_level == WORLD.AREA_LEVEL + LOOT.TABLES.sentinel.level_bonus)
	await clear_ground()

	# Several drops from one spot spread out, and their labels never overlap.
	var origin := Vector2(800, 600)
	for rarity in [1, 1, 2, 1, 2, 1]:
		LOOT.spawn(make_item("copper_ring", rarity), origin, scene)
	await settle()
	var spots: Array = get_nodes_in_group("ground_items").map(func(node: Node2D) -> Vector2: return node.global_position)
	var close_pairs := 0
	for i in range(spots.size()):
		for j in range(i + 1, spots.size()):
			if spots[i].distance_to(spots[j]) < LOOT.SPACING:
				close_pairs += 1
	check(close_pairs <= 1, "Drops spread apart (%d close pairs)" % close_pairs)
	var rects: Array = get_nodes_in_group("ground_items").map(func(node: Node2D) -> Rect2: return node.label.get_global_rect())
	for i in range(rects.size()):
		for j in range(i + 1, rects.size()):
			check(not rects[i].intersects(rects[j]), "Labels stack instead of overlapping")
	await clear_ground()

	# Normal items show their label only while Alt is held; better items always do.
	var plain = LOOT.spawn(make_item("rope_belt", DB.RARITY_NORMAL), Vector2(700, 700), scene)
	var magic = LOOT.spawn(make_item("rope_belt", DB.RARITY_MAGIC), Vector2(900, 700), scene)
	var rare = LOOT.spawn(make_item("rope_belt", DB.RARITY_RARE), Vector2(1000, 700), scene)
	await settle()
	check(not plain.label.visible and magic.label.visible and rare.label.visible)
	Input.action_press("show_labels")
	await process_frame
	check(plain.label.visible, "Alt shows every label")
	Input.action_release("show_labels")
	await process_frame
	check(not plain.label.visible)
	check(InputMap.action_get_events("show_labels")[0].physical_keycode == KEY_ALT)
	await clear_ground()

	# In reach: clicking the label picks the item up at once.
	player.position = Vector2(400, 700)
	var near = LOOT.spawn(make_item("copper_ring", DB.RARITY_MAGIC), Vector2(420, 700), scene)
	await settle()
	player.position = near.global_position + Vector2(20, 0)
	click_label(near)
	await process_frame
	check(not is_instance_valid(near) and inventory.backpack.size() == 1, "A click in reach picks the item up")

	# Out of reach: the wizard walks over and picks it up on arrival.
	var far = LOOT.spawn(make_item("ruby_ring", DB.RARITY_MAGIC), Vector2(650, 700), scene)
	await settle()
	var far_spot: Vector2 = far.global_position
	player.position = far_spot + Vector2(-200, 0)
	click_label(far)
	check(player.pickup_target == far, "A far click starts a walk")
	for step in range(120):
		player._physics_process(1.0 / 60.0)
		if not is_instance_valid(far) or far.is_queued_for_deletion():
			break
	await process_frame
	check(not is_instance_valid(far) and inventory.backpack.size() == 2, "The wizard walks over and picks it up")
	check(player.global_position.distance_to(far_spot) <= player.PICKUP_RANGE + 1.0, "It stops once in reach")

	# Movement keys cancel the walk.
	var other = LOOT.spawn(make_item("topaz_ring", DB.RARITY_MAGIC), Vector2(900, 700), scene)
	await settle()
	click_label(other)
	Input.action_press("move_up")
	player._physics_process(1.0 / 60.0)
	Input.action_release("move_up")
	check(player.pickup_target == null and is_instance_valid(other), "Moving cancels the walk")

	# A full backpack leaves the item on the ground with a message.
	while inventory.add_item(make_item("copper_ring", DB.RARITY_NORMAL)):
		pass
	player.position = other.global_position
	click_label(other)
	await process_frame
	check(is_instance_valid(other) and not other.is_queued_for_deletion(), "No room: the item stays")
	check(scene.get_node("HUD/Message").text == "Inventory full")
	inventory.clear()
	await clear_ground()

	# Clicking the world with an item on the cursor drops it at the wizard's feet, without casting.
	var carried = make_item("student_robe", DB.RARITY_RARE)
	inventory.add_item(carried)
	inventory.pick_up(carried)
	player.cast_ready_in = 0.0
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	await settle()
	var dropped := get_nodes_in_group("ground_items")
	check(inventory.held == null and dropped.size() == 1 and dropped[0].item == carried, "The carried item drops to the ground")
	check(dropped[0].global_position.distance_to(player.global_position) <= LOOT.SCATTER * 2.0 + 0.5)
	check(get_nodes_in_group("projectiles").is_empty(), "Dropping does not cast")
	await clear_ground()

	# F5 brings the enemies back for more drops.
	var before := get_nodes_in_group("enemies").size()
	scene.get_node("Debug").respawn_enemies()
	check(get_nodes_in_group("enemies").size() == before + 3)

	scene.queue_free()
	inventory.clear()
	DirAccess.remove_absolute(SAVE)
	finish("sentinel always drops, drops land near the body inside the map at the right item level; drop odds per enemy; drops spread and labels stack; Alt shows normal labels; click picks up in reach, walks over when far, movement cancels, full backpack keeps the item; clicking the world drops a carried item without casting; F5 respawns enemies")


func check_drop_tables() -> void:
	LOOT.rng.seed = 42
	var counts := {"skitter": [0, 0, 0], "sentinel": [0, 0, 0]}
	var good := {"skitter": 0, "sentinel": 0}
	var items := {"skitter": 0, "sentinel": 0}
	for kind in counts:
		for roll in range(2000):
			var drops: Array = LOOT.roll_drops(kind)
			counts[kind][drops.size()] += 1
			for item in drops:
				items[kind] += 1
				if item.rarity >= DB.RARITY_RARE:
					good[kind] += 1
				check(item.item_level == WORLD.AREA_LEVEL + LOOT.TABLES[kind].level_bonus)
	check(counts.sentinel[0] == 0, "Sentinels always drop")
	check(counts.skitter[0] > 500 and counts.skitter[0] < 1000, "Skitters drop nothing about 34%% of the time: %s" % [counts.skitter])
	check(float(good.sentinel) / items.sentinel > 2.0 * good.skitter / items.skitter, "Sentinels drop more rares")


func click_label(ground_item) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	ground_item._on_gui_input(click)


# Lets pop-out tweens finish.
func settle() -> void:
	# Headless frames outrun real time, so wait on the clock rather than a frame count.
	await create_timer(LOOT.GROUND_ITEM.POP_TIME + 0.2).timeout
	await process_frame
	await process_frame


func clear_ground() -> void:
	for node in get_nodes_in_group("ground_items"):
		node.queue_free()
	await process_frame


func make_item(base_id: String, rarity: int):
	var item = ITEM.new()
	item.base_id = base_id
	item.rarity = rarity
	if rarity >= DB.RARITY_RARE:
		item.name = "Test Band"
	return item


# Records a failed expectation; unlike assert, the run carries on and reports every failure at the end.
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

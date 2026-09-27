extends SceneTree

const DB := preload("res://items/item_database.gd")
const ITEM := preload("res://items/item.gd")
const SAVE := "user://test_inventory.json"

var inventory


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	inventory = root.get_node("Inventory")
	inventory.use_save_path(SAVE)
	check_cursor_actions()
	await check_screen()
	for base_id in DB.BASES:
		check(ResourceLoader.exists("res://assets/icons/%s.png" % DB.BASES[base_id].icon), "Every base has an icon: " + base_id)
	DirAccess.remove_absolute(SAVE)
	finish("pick up, drop, swap onto one item, blocked by two, equip swaps, quick equip/unequip, stow, carried item saved; screen toggles with I and Esc, clicks map to slots and cells, drops centre on the cursor, Shift+click quick moves, no casting while carrying (a world click drops the item), closing stows or stays open when full; tooltip and stat comparison; an icon for every base")


func check_cursor_actions() -> void:
	inventory.clear()
	var staff = make_item("apprentice_staff")
	var ring = make_item("copper_ring")
	var robe = make_item("student_robe")
	inventory.place(staff, Vector2i(0, 0))
	inventory.place(ring, Vector2i(4, 0))
	inventory.place(robe, Vector2i(6, 0))
	# Pick up, then drop somewhere free.
	check(inventory.pick_up(staff) and inventory.held == staff and inventory.item_at(Vector2i(0, 0)) == null)
	check(not inventory.pick_up(ring), "One item on the cursor at a time")
	check(not inventory.drop_held(Vector2i(9, 0)), "Drops must stay inside the grid")
	check(inventory.drop_held(Vector2i(2, 1)) and inventory.held == null and inventory.cell_of(staff) == Vector2i(2, 1))
	# Dropping onto exactly one item swaps: the ring lands where the robe was, and the robe is carried.
	inventory.pick_up(ring)
	check(inventory.drop_held(Vector2i(6, 1)) and inventory.held == robe and inventory.cell_of(ring) == Vector2i(6, 1))
	# The robe (2x3) at (1,0) would cover the staff at (2,1): one item, so they swap.
	check(inventory.drop_held(Vector2i(1, 0)) and inventory.held == staff and inventory.cell_of(robe) == Vector2i(1, 0))
	check(inventory.drop_held(Vector2i(8, 0)) and inventory.held == null)
	# A 2x3 robe dropped at (5,0) would cover the ring at (6,1) and the staff at (8,0): two items, refused.
	var second_robe = make_item("student_robe")
	inventory.place(second_robe, Vector2i(3, 2))
	inventory.pick_up(second_robe)
	inventory.place(make_item("copper_ring"), Vector2i(5, 0))
	check(not inventory.drop_held(Vector2i(5, 0)), "Covering two items blocks the drop")
	check(inventory.held == second_robe)
	check(inventory.drop_held(Vector2i(3, 2)) and inventory.held == null)

	# Equipment: dropping into a slot equips and carries what was there.
	inventory.clear()
	var old_ring = make_item("ruby_ring")
	var new_ring = make_item("topaz_ring")
	inventory.equip(old_ring, "ring_left")
	inventory.place(new_ring, Vector2i(0, 0))
	inventory.pick_up(new_ring)
	check(not inventory.drop_held_in_slot("helmet"), "Items only go in fitting slots")
	check(inventory.drop_held_in_slot("ring_left") and inventory.held == old_ring and inventory.equipment.ring_left == new_ring)
	check(inventory.drop_held_in_slot("ring_right") and inventory.held == null)
	check(inventory.pick_up_equipped("ring_right") and inventory.held == old_ring and not inventory.equipment.has("ring_right"))
	inventory.drop_held(Vector2i(5, 2))

	# Shift+click: equip from the backpack (the old item takes its place) and unequip to the backpack.
	inventory.clear()
	var worn = make_item("student_robe")
	var better = make_item("warded_robe")
	inventory.equip(worn, "body")
	inventory.place(better, Vector2i(3, 1))
	check(inventory.quick_equip(better) and inventory.equipment.body == better and inventory.cell_of(worn) == Vector2i(3, 1))
	check(inventory.quick_unequip("body") and not inventory.equipment.has("body") and inventory.cell_of(better).x >= 0)

	# A carried item is saved, and stowing puts it back in the backpack.
	inventory.pick_up(worn)
	inventory.load_save()
	check(inventory.held != null and inventory.held.base_id == "student_robe", "The carried item survives a reload")
	check(inventory.stow_held() and inventory.held == null and inventory.backpack.size() == 2)
	inventory.clear()


func check_screen() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.get_node("Wizard")
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
	var panel = scene.get_node("HUD/InventoryPanel")
	var tooltip = scene.get_node("HUD/Tooltip")
	check(not panel.visible)
	press("inventory")
	check(panel.visible, "I opens the inventory")
	check(panel.size.x == panel.WIDTH and panel.get_global_rect().end.x == root.get_visible_rect().size.x, "The screen sits on the right edge")
	var camera: Camera2D = player.get_node("Camera")
	await create_timer(panel.CAMERA_SHIFT_TIME + 0.1).timeout
	check(camera.offset.x == panel.WIDTH / 2.0 / camera.zoom.x, "The camera shifts so the wizard stays in view")

	# Clicks land on slots and cells.
	var staff = make_item("apprentice_staff", [["spell_damage", 20]])
	var ring = make_item("copper_ring")
	inventory.place(staff, Vector2i(0, 0))
	inventory.place(ring, Vector2i(5, 2))
	var staff_center: Vector2 = panel.item_rect(staff, Vector2i(0, 0)).get_center()
	check(panel.cell_at(staff_center) == Vector2i(0, 1) or panel.cell_at(staff_center) == Vector2i(1, 2) or panel.cell_at(staff_center).x in [0, 1])
	check(panel.slot_at(panel.SLOT_RECTS.weapon.get_center()) == "weapon" and panel.slot_at(Vector2(2, 2)) == "")
	panel.click(staff_center)
	check(inventory.held == staff)
	# Drops centre the item on the cursor and stay inside the grid.
	var corner: Vector2 = panel.GRID_ORIGIN + Vector2(inventory.COLUMNS, inventory.ROWS) * panel.CELL - Vector2(2, 2)
	check(panel.drop_cell(corner) == Vector2i(inventory.COLUMNS - 2, inventory.ROWS - 4))
	panel.click(panel.SLOT_RECTS.weapon.get_center())
	check(inventory.equipment.weapon == staff and inventory.held == null, "Clicking a slot equips the carried item")
	check(player.stats.spell_damage > 0.0, "Equipping updates the wizard")
	panel.click(panel.SLOT_RECTS.weapon.get_center(), true)
	check(not inventory.equipment.has("weapon") and inventory.cell_of(staff).x >= 0, "Shift+click unequips to the backpack")
	panel.click(panel.item_rect(staff, inventory.cell_of(staff)).get_center(), true)
	check(inventory.equipment.weapon == staff, "Shift+click equips from the backpack")

	# No casting while carrying an item.
	panel.click(panel.item_rect(ring, Vector2i(5, 2)).get_center())
	check(inventory.held == ring)
	player.cast_ready_in = 0.0
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	check(get_nodes_in_group("projectiles").is_empty(), "No casting while carrying an item")
	# The world click dropped the ring at the wizard's feet; take it back up and carry it again.
	var on_ground := get_nodes_in_group("ground_items").filter(func(node: Node) -> bool: return node.item == ring)
	check(inventory.held == null and on_ground.size() == 1, "A world click drops the carried item")
	if not on_ground.is_empty():
		on_ground[0].pick_up()
	inventory.pick_up(ring)

	# Closing stows the carried item; with a full backpack the screen stays open.
	press("ui_cancel")
	check(not panel.visible and inventory.held == null and inventory.backpack.any(func(entry: Dictionary) -> bool: return entry.item == ring))
	await create_timer(panel.CAMERA_SHIFT_TIME + 0.1).timeout
	check(camera.offset == Vector2.ZERO, "Closing recentres the camera")
	press("inventory")
	inventory.pick_up(ring)
	while inventory.add_item(make_item("copper_ring")):
		pass
	press("inventory")
	check(panel.visible and inventory.held == ring, "With no room, closing keeps the screen open")
	inventory.clear()

	# Hovering shows the tooltip, with how the item would change stats.
	var belt = make_item("rope_belt", [["life", 30], ["fire_res", 20]])
	var worn_belt = make_item("scholars_sash", [["life", 10]])
	inventory.equip(worn_belt, "belt")
	inventory.place(belt, Vector2i(0, 0))
	var lines: Array = panel.comparison(belt)
	var texts := lines.map(func(line: Array) -> String: return line[0])
	check("+20 maximum Life" in texts and "+20% Fire Resistance" in texts, "Comparison: %s" % [texts])
	check(lines[0][1] == Color("7fd67f"))
	check(panel.comparison(worn_belt).is_empty(), "Equipped items get no comparison")
	# Hovering maps to the item under the cursor; the tooltip lists it with the comparison.
	check(panel.item_at_position(panel.item_rect(belt, Vector2i(0, 0)).get_center()) == belt)
	check(panel.item_at_position(panel.SLOT_RECTS.belt.get_center()) == worn_belt)
	check(panel.item_at_position(Vector2(2, 2)) == null)
	tooltip.show_item(belt, panel.comparison(belt))
	var shown := tooltip.get_node("Lines").get_children().filter(func(node: Node) -> bool: return node is Label).map(func(label: Label) -> String: return label.text)
	check(shown[0] == belt.display_name() and "If equipped:" in shown and "+20 maximum Life" in shown, "Tooltip: %s" % [shown])
	tooltip.place_near(Vector2(630, 390), Vector2(640, 400))
	check(Rect2(Vector2.ZERO, Vector2(640, 400)).encloses(Rect2(tooltip.position, tooltip.get_combined_minimum_size())), "The tooltip stays on screen")
	panel.close()
	check(not tooltip.visible)
	scene.queue_free()
	inventory.clear()


func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	root.push_input(event)


func make_item(base_id: String, stat_mods := []):
	var item = ITEM.new()
	item.base_id = base_id
	item.rarity = DB.RARITY_MAGIC if not stat_mods.is_empty() else DB.RARITY_NORMAL
	for pair in stat_mods:
		item.mods.append({"kind": "unique", "stat": pair[0], "value": pair[1], "affix": "", "tier": 0})
	return item


var failures: Array[String] = []


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

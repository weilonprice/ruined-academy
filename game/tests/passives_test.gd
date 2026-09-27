extends SceneTree

const PASSIVES := preload("res://passives.gd")
const STATS := preload("res://stats.gd")
const NOVA := preload("res://frost_nova.gd")
const SAVE := "user://test_passives.json"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var character = root.get_node("Character")
	var inventory = root.get_node("Inventory")
	inventory.use_save_path("user://test_inventory.json")
	inventory.clear()
	character.use_save_path(SAVE)
	character.reset()

	# Five passives; each links back to the start.
	check(PASSIVES.NODES.size() == 5)
	check(PASSIVES.connected(PASSIVES.NODES.keys()), "The whole tree links to the start")

	# One point per level past the first; nothing to spend at level 1.
	check(character.points_available() == 0 and not character.allocate("vitality"), "No points at level 1")
	character.add_experience(40 + 121)
	check(character.level == 3 and character.points_available() == 2)

	# Only nodes linked to the start or an allocated node can be taken.
	check(not character.can_allocate("spell_mastery") and not character.allocate("keen_mind"), "Unlinked nodes are locked")
	check(character.allocate("deep_reserves") and character.points_available() == 1)
	check(not character.allocate("deep_reserves"), "No node twice")
	check(character.allocate("spell_mastery") and character.points_available() == 0)
	check(not character.allocate("vitality"), "No points left")

	# Refunds are free but can't strand other passives.
	check(not character.can_refund("deep_reserves"), "Refunding would strand Spell Mastery")
	check(character.refund("spell_mastery") and character.points_available() == 1)
	check(character.allocate("spell_mastery"))
	character.add_experience(232)
	check(character.allocate("vitality"))
	check(character.can_refund("deep_reserves"), "With Vitality allocated, Spell Mastery stays linked")
	check(not character.refund("keen_mind"), "Nothing to refund")

	# Allocations save with the level; a save claiming more nodes than points, or stranded nodes, is trimmed.
	var saved: Array = character.passives.duplicate()
	character.load_save()
	check(character.passives == saved, "Passives survive a reload")
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "level": 2, "experience": 0, "passives": ["vitality", "deep_reserves", "spell_mastery"]}))
	file.close()
	character.load_save()
	check(character.passives == ["vitality"], "Only as many passives as the level allows")
	file = FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "level": 5, "experience": 0, "passives": ["keen_mind", "bogus"]}))
	file.close()
	character.load_save()
	check(character.passives.is_empty(), "Stranded or unknown passives are dropped")

	# Each passive's stats.
	var base := STATS.compute([], 1)
	var vitality := STATS.compute([], 1, ["vitality"])
	check(vitality.max_life == base.max_life + 20 and vitality.life_regen == 1.0)
	var reserves := STATS.compute([], 1, ["deep_reserves"])
	check(reserves.max_mana == base.max_mana + 20 and is_equal_approx(reserves.mana_regen, base.mana_regen * 1.2))
	check(STATS.compute([], 1, ["spell_mastery"]).spell_damage == 15.0)
	var keen := STATS.compute([], 1, ["keen_mind"])
	check(is_equal_approx(keen.crit_chance, base.crit_chance * 1.5) and keen.cast_speed == 8.0)
	var frost := STATS.compute([], 1, ["frostweaving"])
	check(frost.nova_area == 30.0 and frost.nova_chill == 1.0)

	# In play: passives feed the wizard, and Frostweaving widens and lengthens Frost Nova.
	character.reset()
	for level in range(1, 5):
		character.add_experience(character.experience_to_next(level))
	check(character.level == 5)
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	character.allocate("vitality")
	check(player.max_health == STATS.compute([], 5, ["vitality"]).max_life, "Allocating updates the wizard at once")
	character.allocate("spell_mastery")
	character.allocate("frostweaving")
	var edge: float = NOVA.RADIUS * 1.2
	var target = load("res://enemy.tscn").instantiate()
	target.kind = "sentinel"
	target.position = player.position + Vector2(edge, 0)
	scene.add_child(target)
	await process_frame
	player.cast_ready_in = 0.0
	player.mana = player.max_mana
	var nova = player.cast_nova(player.global_position)
	check(is_equal_approx(nova.radius, NOVA.RADIUS * 1.3), "Frostweaving widens the nova")
	check(nova.hits.size() == 1, "It reaches an enemy past the base radius")
	check(is_equal_approx(target.chilled_left, player.NOVA_CHILL_TIME + 1.0), "Chill lasts a second longer")
	character.refund("frostweaving")
	check(player.stats.nova_area == 0.0, "Refunding removes it")

	# The tree screen: P opens it, clicks allocate and refund, hover explains, Esc closes before pausing.
	var tree = scene.get_node("HUD/PassiveTree")
	var pause_menu = scene.get_node("HUD/PauseMenu")
	check(InputMap.action_get_events("passive_tree")[0].physical_keycode == KEY_P)
	press("passive_tree")
	check(tree.visible, "P opens the tree")
	check(tree.node_at(tree.node_center("keen_mind")) == "keen_mind" and tree.node_at(tree.panel_rect().position) == "")
	check(tree.hint("keen_mind") == "Click to allocate")
	click(tree, tree.node_center("keen_mind"), MOUSE_BUTTON_LEFT)
	check("keen_mind" in character.passives, "Clicking allocates")
	check(tree.hint("vitality") == "Other passives depend on this")
	click(tree, tree.node_center("deep_reserves"), MOUSE_BUTTON_LEFT)
	check(character.points_available() == 0 and tree.hint("frostweaving") == "No points: gain a level")
	click(tree, tree.node_center("keen_mind"), MOUSE_BUTTON_RIGHT)
	check("keen_mind" not in character.passives, "Right-clicking refunds")
	check(tree.hint("frostweaving") == "Click to allocate")
	press("pause")
	check(not tree.visible and not paused and not pause_menu.visible, "Esc closes the tree before pausing")

	scene.queue_free()
	inventory.clear()
	character.reset()
	DirAccess.remove_absolute(SAVE)
	DirAccess.remove_absolute("user://test_inventory.json")
	finish("five linked passives; one point per level; only linked nodes; no repeats or overspending; refunds can't strand nodes; save, reload, and trimming bad saves; each passive's stats; allocation updates the wizard; Frostweaving widens Frost Nova and lengthens chill; P opens the tree, click allocates, right-click refunds, hints explain, Esc closes it before pausing")


func click(control: Control, at: Vector2, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	control._gui_input(event)


# Sends an action press through the viewport, as a key press would.
func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	root.push_input(event)


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

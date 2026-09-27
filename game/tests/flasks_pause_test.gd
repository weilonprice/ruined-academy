extends SceneTree

const SAVE := "user://test_inventory.json"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var inventory = root.get_node("Inventory")
	inventory.use_save_path(SAVE)
	inventory.clear()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
	var life: Dictionary = player.FLASKS[0]
	var mana: Dictionary = player.FLASKS[1]

	# Flasks start full; keys 1 and 2 drink them.
	check(player.flask_charges == [life.max_charges, mana.max_charges], "Flasks start full")
	check(InputMap.action_get_events("flask_1")[0].physical_keycode == KEY_1 and InputMap.action_get_events("flask_2")[0].physical_keycode == KEY_2)
	player.take_damage(70.0)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	player._unhandled_input(key)
	check(player.flask_charges[0] == life.max_charges - life.per_use and player.flask_time_left[0] == life.duration, "1 drinks the life flask")

	# Recovery runs over the flask's duration, then stops.
	player._physics_process(life.duration / 2.0)
	check(is_equal_approx(player.health, 30.0 + life.amount / 2.0), "Half the time, half the life (%.1f)" % player.health)
	check(not player.drink_flask(0), "No second drink while it runs")
	player._physics_process(life.duration)
	check(is_equal_approx(player.health, 30.0 + life.amount) and player.flask_time_left[0] == 0.0, "The full amount, then it stops (%.1f)" % player.health)
	player._physics_process(1.0)
	check(is_equal_approx(player.health, 30.0 + life.amount), "No more after it ends")

	# Recovery never goes past the maximum.
	player.health = player.max_health - 5.0
	check(player.drink_flask(0))
	player._physics_process(life.duration)
	check(player.health == player.max_health)

	# The mana flask restores mana on 2.
	player.mana = 0.0
	key.physical_keycode = KEY_2
	player._unhandled_input(key)
	player._physics_process(mana.duration)
	var regen: float = player.stats.mana_regen * mana.duration
	check(is_equal_approx(player.mana, mana.amount + regen), "2 drinks the mana flask (%.1f)" % player.mana)

	# Out of charges: no drink. Kills refill every flask, capped at the maximum.
	player.flask_charges[0] = life.per_use - 1
	check(not player.drink_flask(0), "Not enough charges")
	var charges_before: Array = player.flask_charges.duplicate()
	var victim = load("res://enemy.tscn").instantiate()
	victim.kind = "skitter"
	victim.ai_enabled = false
	victim.position = Vector2(300, 800)
	scene.add_child(victim)
	await process_frame
	victim.take_damage(999.0)
	var gain: int = victim.stats.flask_charges
	check(player.flask_charges[0] == charges_before[0] + gain and player.flask_charges[1] == mini(mana.max_charges, charges_before[1] + gain), "A kill refills flask charges")
	player.gain_flask_charges(1000)
	check(player.flask_charges == [life.max_charges, mana.max_charges], "Charges cap at the maximum")
	check(scene.get_node("HUD/FlaskBar") != null)

	var pause_menu = scene.get_node("HUD/PauseMenu")
	var inventory_panel = scene.get_node("HUD/InventoryPanel")

	# Esc pauses and shows the menu; Resume or Esc again resumes.
	check(InputMap.action_get_events("pause")[0].physical_keycode == KEY_ESCAPE)
	press("pause")
	check(paused and pause_menu.visible, "Esc pauses")
	check(pause_menu.resume_button.has_focus(), "Resume is focused")
	var frozen: float = player.health
	player.set_physics_process(true)
	player.take_damage(10.0)
	frozen = player.health
	for frame in range(10):
		await process_frame
	check(player.health == frozen, "Nothing runs while paused")
	pause_menu.resume_button.pressed.emit()
	check(not paused and not pause_menu.visible, "Resume unpauses")
	press("pause")
	press("pause")
	check(not paused and not pause_menu.visible, "Esc again resumes")
	check(root.get_node("Display").process_mode == Node.PROCESS_MODE_ALWAYS, "Fullscreen works while paused")
	check(pause_menu.quit_button.pressed.is_connected(pause_menu.quit_game), "Quit is wired up")

	# With the inventory open, Esc closes it instead of pausing.
	inventory_panel.toggle()
	press("pause")
	check(not paused and not pause_menu.visible and not inventory_panel.visible, "Esc closes the inventory first")

	# No drinking once fallen.
	player.flask_charges[0] = life.max_charges
	player.take_damage(9999.0)
	check(not player.drink_flask(0), "No flasks once fallen")

	scene.queue_free()
	inventory.clear()
	DirAccess.remove_absolute(SAVE)
	finish("flasks start full, 1 and 2 drink them, recovery runs over time and stops at the full amount and the maximum, no redrink while running, charges gate drinks, kills refill charges capped at the maximum; Esc pauses with Resume focused, nothing runs while paused, Resume and Esc resume, fullscreen still works, Quit wired, Esc closes the inventory first; no flasks once fallen")


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

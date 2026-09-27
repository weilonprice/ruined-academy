extends SceneTree

const DB := preload("res://items/item_database.gd")
const ITEM := preload("res://items/item.gd")
const NOVA := preload("res://frost_nova.gd")
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
		enemy.queue_free()
	await process_frame

	# Right-click casts Frost Nova: mana, cast time, and the cast animation facing the cursor.
	var near_east = spawn(scene, player.position + Vector2(60, 0))
	var near_south = spawn(scene, player.position + Vector2(0, NOVA.RADIUS + NOVA.ENEMY_REACH - 1.0))
	var outside = spawn(scene, player.position + Vector2(-(NOVA.RADIUS + NOVA.ENEMY_REACH + 10.0), 0))
	await process_frame
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	player._unhandled_input(right_click)
	var novas := scene.get_children().filter(func(node: Node) -> bool: return node.get_script() == NOVA)
	check(novas.size() == 1, "Right-click casts Frost Nova")
	check(player.mana == player.max_mana - player.NOVA_MANA_COST, "It costs its mana")
	check(is_equal_approx(player.cast_ready_in, player.NOVA_CAST_TIME), "It takes its cast time")
	check(player.casting and String(player.sprite.animation).begins_with("cast_"))
	check(get_nodes_in_group("projectiles").is_empty(), "No bolt")

	# Every enemy in reach is hit once and chilled; one out of reach is untouched.
	var hits: Array = novas[0].hits
	check(hits.size() == 2 and hits.any(func(hit: Dictionary) -> bool: return hit.enemy == near_east) and hits.any(func(hit: Dictionary) -> bool: return hit.enemy == near_south))
	for hit in hits:
		var expected: float = hit.enemy.MAX_HEALTH - hit.damage
		check(is_equal_approx(hit.enemy.health, expected), "One hit each")
		check(hit.damage >= player.NOVA_DAMAGE.x and hit.damage <= player.NOVA_DAMAGE.y * 1.5)
		check(hit.enemy.is_chilled() and is_equal_approx(hit.enemy.sprite.speed_scale, hit.enemy.CHILL_SLOW), "Hit enemies are chilled")
		check(hit.enemy.aggro, "A hit wakes the enemy")
	check(outside.health == outside.MAX_HEALTH and not outside.is_chilled(), "Out of reach: untouched")

	# Casting waits for the last cast, and needs mana.
	check(player.cast_nova(player.global_position) == null, "No recast before the cast time passes")
	player.cast_ready_in = 0.0
	player.mana = player.NOVA_MANA_COST - 1.0
	check(player.cast_nova(player.global_position) == null, "No cast without mana")
	check(player.shoot_at(player.global_position + Vector2(50, 0)) != null, "The bolt still casts on the mana left")

	# Chill slows movement and attacks, then wears off.
	var runner = spawn(scene, Vector2(300, 800))
	var chilled = spawn(scene, Vector2(300, 860))
	runner.aggro = true
	chilled.aggro = true
	player.position = Vector2(700, 830)
	chilled.take_damage(1.0, false, 10.0)
	chilled.hurting = false
	var start_runner: Vector2 = runner.position
	var start_chilled: Vector2 = chilled.position
	for step in range(30):
		runner._physics_process(1.0 / 60.0)
		chilled._physics_process(1.0 / 60.0)
	var ratio: float = (chilled.position - start_chilled).length() / (runner.position - start_runner).length()
	check(is_equal_approx(snappedf(ratio, 0.01), runner.CHILL_SLOW), "Chilled enemies move at 70%% speed (%.2f)" % ratio)
	chilled._physics_process(20.0)
	check(not chilled.is_chilled() and chilled.sprite.speed_scale == 1.0 and chilled.modulate.b == 1.0, "Chill wears off")

	# Gear scales the nova: spell damage, crits, and cast speed.
	var staff = ITEM.new()
	staff.base_id = "apprentice_staff"
	staff.rarity = DB.RARITY_MAGIC
	for pair in [["spell_damage", 100], ["crit_chance", 1900], ["cast_speed", 50]]:
		staff.mods.append({"kind": "unique", "stat": pair[0], "value": pair[1], "affix": "", "tier": 0})
	inventory.equip(staff, "weapon")
	for node in get_nodes_in_group("enemies"):
		node.queue_free()
	await process_frame
	var target = spawn(scene, player.position + Vector2(40, 0))
	await process_frame
	player.cast_ready_in = 0.0
	player.mana = player.max_mana
	var boosted = player.cast_nova(player.global_position)
	check(is_equal_approx(player.cast_ready_in, player.NOVA_CAST_TIME / 1.5), "Cast speed shortens the cast")
	check(boosted.hits.size() == 1 and boosted.hits[0].critical, "Crit chance applies")
	var damage: float = boosted.hits[0].damage
	check(damage >= player.NOVA_DAMAGE.x * 2.0 * 1.5 - 0.01 and damage <= player.NOVA_DAMAGE.y * 2.0 * 1.5 + 0.01, "Spell damage and crits scale it (%.1f)" % damage)
	check(target.dying, "A lethal nova kills")

	# The ring fades and frees itself; the skill bar shows both skills and dims what can't be cast.
	await create_timer(NOVA.EXPAND_TIME + NOVA.FADE_TIME + 0.1).timeout
	check(scene.get_children().filter(func(node: Node) -> bool: return node.get_script() == NOVA).is_empty(), "The nova effect cleans up")
	var bar = scene.get_node("HUD/SkillBar")
	check(bar.skills().map(func(skill: Array) -> String: return skill[0]) == ["LMB", "RMB"])
	player.mana = player.NOVA_MANA_COST - 1.0
	check(bar.usable(player.BOLT_MANA_COST) and not bar.usable(player.NOVA_MANA_COST), "Dims a skill without enough mana")

	# No nova while carrying an item or dead.
	player.cast_ready_in = 0.0
	player.mana = player.max_mana
	var carried = ITEM.new()
	carried.base_id = "copper_ring"
	inventory.add_item(carried)
	inventory.pick_up(carried)
	player._unhandled_input(right_click)
	check(player.mana == player.max_mana, "No nova while carrying an item")
	inventory.stow_held()
	player.take_damage(9999.0)
	check(player.cast_nova(player.global_position) == null, "No nova once fallen")

	scene.queue_free()
	inventory.clear()
	DirAccess.remove_absolute(SAVE)
	finish("right-click casts Frost Nova for its mana and cast time; hits each enemy in reach once and chills it, misses those outside; waits for the cast and needs mana; chill slows movement to 70% and wears off; spell damage, crits, and cast speed apply; the effect cleans up; skill bar shows LMB/RMB and dims unaffordable skills; no nova while carrying or fallen")


func spawn(scene: Node, at: Vector2):
	var enemy = load("res://enemy.tscn").instantiate()
	enemy.kind = "sentinel"
	enemy.position = at
	scene.add_child(enemy)
	return enemy


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

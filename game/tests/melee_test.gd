extends SceneTree

const ITEM := preload("res://items/item.gd")
const EFFECT := preload("res://effect.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var inventory = root.get_node("Inventory")
	inventory.use_save_path("user://test_inventory.json")
	inventory.clear()
	var character = root.get_node("Character")
	character.use_save_path("user://test_melee_character.json")
	character.reset()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	player.position = Vector2(800, 480)

	# Left-click swings Wind Slash toward the cursor: it hits enemies in reach inside the arc, and no one else.
	var ahead = spawn(scene, player.position + Vector2(50, 0))
	var edge = spawn(scene, player.position + Vector2(40, 0).rotated(deg_to_rad(55)))
	var behind = spawn(scene, player.position + Vector2(-45, 0))
	var far = spawn(scene, player.position + Vector2(player.SLASH_REACH + 20.0, 0))
	await process_frame
	var mana_before: float = player.mana
	var hits = player.slash_at(player.position + Vector2(100, 0))
	check(hits != null and hits.size() == 2, "Hits the two enemies in front, in reach")
	check(hits.any(func(hit: Dictionary) -> bool: return hit.enemy == ahead) and hits.any(func(hit: Dictionary) -> bool: return hit.enemy == edge))
	check(behind.health == behind.MAX_HEALTH and far.health == far.MAX_HEALTH, "Misses behind and out of reach")
	for hit in hits:
		check(is_equal_approx(hit.enemy.health, hit.enemy.MAX_HEALTH - hit.damage), "One hit each")
		check(hit.damage >= player.SLASH_DAMAGE.x and hit.damage <= player.SLASH_DAMAGE.y * 1.5)
	check(player.mana == mana_before, "Costs no mana")
	check(player.facing == "east" and player.casting and player.sprite.animation == "slash_east", "Plays the slash facing the cursor")
	check(player.sprite.sprite_frames.get_frame_count("slash_east") == 6, "Six-frame slash")
	check(is_equal_approx(player.cast_ready_in, player.SLASH_TIME), "Takes its swing time")
	check(player.slash_at(player.position + Vector2(100, 0)) == null, "No second swing before the first finishes")
	var winds := scene.get_children().filter(func(node: Node) -> bool: return node.get_script() == EFFECT)
	check(winds.size() == 1 and is_equal_approx(winds[0].rotation, 0.0), "Throws a wind crescent along the aim")

	# Spell damage raises it, as a magic attack. Full health first: a kill would level up and recompute stats mid-swing.
	player.cast_ready_in = 0.0
	ahead.health = ahead.MAX_HEALTH
	edge.health = edge.MAX_HEALTH
	player.stats.spell_damage = 100.0
	player.stats.crit_chance = 0.0
	var boosted = player.slash_at(player.position + Vector2(100, 0))
	check(boosted.all(func(hit: Dictionary) -> bool: return hit.damage >= player.SLASH_DAMAGE.x * 2.0), "Spell damage doubles it")
	player.refresh_stats()

	# The left mouse button is the slash; with an item on the cursor it drops the item instead.
	player.cast_ready_in = 0.0
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	check(player.sprite.animation.begins_with("slash_") and get_nodes_in_group("projectiles").is_empty(), "Left-click slashes, no bolt")
	player.cast_ready_in = 0.0
	var carried = ITEM.new()
	carried.base_id = "copper_ring"
	inventory.add_item(carried)
	inventory.pick_up(carried)
	player._unhandled_input(click)
	check(inventory.held == null and player.cast_ready_in == 0.0, "Drops the carried item, no swing")

	# No swing once fallen.
	player.take_damage(10000.0)
	check(player.slash_at(player.position + Vector2(100, 0)) == null, "No slash once fallen")
	finish("left-click Wind Slash hits enemies in reach inside a 120-degree arc toward the cursor and no others; free, one swing per swing time, six-frame slash facing the aim, wind crescent along the aim; spell damage raises it; drops a carried item instead; none once fallen")


func spawn(scene: Node, at: Vector2):
	var enemy = load("res://enemy.tscn").instantiate()
	enemy.kind = "sentinel"
	enemy.ai_enabled = false
	enemy.position = at
	scene.add_child(enemy)
	return enemy


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

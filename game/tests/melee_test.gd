extends SceneTree

const ITEM := preload("res://items/item.gd")
const EFFECT := preload("res://effect.gd")
const GENERATOR := preload("res://items/item_generator.gd")

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

	# Left-click swings Wind Slash toward the cursor; the blade lands a moment later, hitting enemies in reach inside the arc, and no one else.
	var ahead = spawn(scene, player.position + Vector2(50, 0))
	var edge = spawn(scene, player.position + Vector2(40, 0).rotated(deg_to_rad(55)))
	var behind = spawn(scene, player.position + Vector2(-45, 0))
	var far = spawn(scene, player.position + Vector2(player.SLASH_REACH + 20.0, 0))
	await process_frame
	var mana_before: float = player.mana
	var ahead_start: Vector2 = ahead.position
	check(player.slash_at(player.position + Vector2(100, 0)), "Swings")
	check(player.facing == "east" and player.casting and player.sprite.animation == "slash_east", "Plays the slash facing the cursor")
	check(player.sprite.sprite_frames.get_frame_count("slash_east") == 6, "Six-frame slash")
	check(is_equal_approx(player.cast_ready_in, player.SLASH_TIME), "Takes its swing time")
	check(ahead.health == ahead.MAX_HEALTH, "Nothing is hit until the blade comes round")
	player._physics_process(player.SLASH_HIT_DELAY / 2.0)
	check(ahead.health == ahead.MAX_HEALTH, "Still not at half the delay")
	player._physics_process(player.SLASH_HIT_DELAY / 2.0 + 0.001)
	var hits: Array = player.last_slash_hits
	check(hits.size() == 2, "Hits the two enemies in front, in reach")
	check(hits.any(func(hit: Dictionary) -> bool: return hit.enemy == ahead) and hits.any(func(hit: Dictionary) -> bool: return hit.enemy == edge))
	check(behind.health == behind.MAX_HEALTH and far.health == far.MAX_HEALTH, "Misses behind and out of reach")
	for hit in hits:
		check(is_equal_approx(hit.enemy.health, hit.enemy.MAX_HEALTH - hit.damage), "One hit each")
		check(hit.damage >= player.SLASH_DAMAGE.x and hit.damage <= player.SLASH_DAMAGE.y * 1.5)
	check(player.mana >= mana_before, "Costs no mana")
	check(player.slash_at(player.position + Vector2(100, 0)) == false, "No second swing before the first finishes")
	var winds := scene.get_children().filter(func(node: Node) -> bool: return node.get_script() == EFFECT)
	check(winds.size() == 1 and is_equal_approx(winds[0].rotation, 0.0), "Throws a wind crescent along the aim")

	# A connecting swing freezes the action for a moment, and pushes the enemies back.
	check(is_equal_approx(Engine.time_scale, player.HIT_STOP_SCALE), "Hit-stop on contact")
	await create_timer(player.HIT_STOP + 0.05, true, false, true).timeout
	check(Engine.time_scale == 1.0, "Then time runs again")
	for frame in range(20):
		await physics_frame
	check(ahead.position.x > ahead_start.x + player.SLASH_KNOCKBACK * 0.9, "Knocked back away from the wizard")

	# Dodging out of a swing abandons it before the blade lands.
	player.cast_ready_in = 0.0
	ahead.health = ahead.MAX_HEALTH
	player.dodge_cooldown_left = 0.0
	check(player.slash_at(ahead.position))
	check(player.dodge())
	player.dodge_time_left = 0.0
	player._physics_process(player.SLASH_HIT_DELAY + 0.01)
	check(ahead.health == ahead.MAX_HEALTH, "A dodge cancels the swing")
	player.position = Vector2(800, 480)

	# Spell damage and wind damage raise it, as a magic attack. Full health first: a kill would level up and recompute stats mid-swing.
	player.cast_ready_in = 0.0
	ahead.health = ahead.MAX_HEALTH
	edge.health = edge.MAX_HEALTH
	ahead.position = player.position + Vector2(50, 0)
	player.stats.spell_damage = 50.0
	player.stats.wind_damage = 50.0
	player.stats.crit_chance = 0.0
	player.slash_at(player.position + Vector2(100, 0))
	player._physics_process(player.SLASH_HIT_DELAY + 0.001)
	var boosted: Array = player.last_slash_hits
	check(not boosted.is_empty() and boosted.all(func(hit: Dictionary) -> bool: return hit.damage >= player.SLASH_DAMAGE.x * 2.0), "Spell and wind damage together double it")
	await create_timer(player.HIT_STOP + 0.05, true, false, true).timeout
	player.refresh_stats()

	# 2 sends a Wind Wave: it flies forward through enemies in its path, hitting each once, for its mana.
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	player.position = Vector2(700, 480)
	player.cast_ready_in = 0.0
	player.mana = player.max_mana
	var near = spawn(scene, player.position + Vector2(110, 0))
	var further = spawn(scene, player.position + Vector2(200, 10))
	var aside = spawn(scene, player.position + Vector2(120, 70))
	var beyond = spawn(scene, player.position + Vector2(player.WIND_WAVE_SCRIPT.RANGE + 80.0, 0))
	await process_frame
	check(InputMap.action_get_events("skill_2")[0].physical_keycode == KEY_2, "Wind Wave is on 2")
	var wave = player.wave_at(player.position + Vector2(300, 0))
	check(wave != null and player.mana == player.max_mana - player.WAVE_MANA_COST, "It costs its mana")
	check(player.sprite.animation == "slash_east", "Swung like the slash")
	for frame in range(120):
		await physics_frame
		if not is_instance_valid(wave):
			break
	check(not is_instance_valid(wave), "The wave thins out at the end of its range")
	check(near.health < near.MAX_HEALTH and further.health < further.MAX_HEALTH, "Hits every enemy in its path")
	check(aside.health == aside.MAX_HEALTH and beyond.health == beyond.MAX_HEALTH, "Misses enemies off its path and past its range")
	check(near.MAX_HEALTH - near.health <= player.WAVE_DAMAGE.y * 1.5, "Each once")
	player.cast_ready_in = 0.0
	player.mana = player.WAVE_MANA_COST - 1.0
	check(player.wave_at(player.position + Vector2(300, 0)) == null, "No wave without mana")
	player.mana = player.max_mana

	# Swords are off-hand gear that raise wind damage.
	var sword = GENERATOR.roll_base("short_sword", 1, 0, RandomNumberGenerator.new())
	check(sword.fits_slot("offhand") and sword.size() == Vector2i(1, 3), "An off-hand sword")
	var wind: int = sword.stats().get("wind_damage", 0)
	check(wind >= 10 and wind <= 15, "Its implicit rolls wind damage")
	var before_scale: float = player._wind_scale()
	inventory.equip(sword, "offhand")
	check(player.stats.wind_damage == wind and is_equal_approx(player._wind_scale(), before_scale + wind / 100.0), "Equipped, it raises the wind skills")
	check(ResourceLoader.exists("res://assets/icons/windblade.png") and GENERATOR.roll_base("windblade", 15, 0, RandomNumberGenerator.new()).stats().get("wind_damage", 0) >= 20, "The Windblade rolls more")
	inventory.unequip("offhand")

	# The left mouse button is the slash; with an item on the cursor it drops the item instead.
	player.cast_ready_in = 0.0
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	check(player.sprite.animation.begins_with("slash_") and get_nodes_in_group("projectiles").is_empty(), "Left-click slashes, no bolt")
	player.cast_ready_in = 0.0
	player.slash_hit_in = 0.0
	var carried = ITEM.new()
	carried.base_id = "copper_ring"
	inventory.add_item(carried)
	inventory.pick_up(carried)
	player._unhandled_input(click)
	check(inventory.held == null and player.cast_ready_in == 0.0, "Drops the carried item, no swing")

	# No swing or wave once fallen.
	player.take_damage(10000.0)
	check(player.slash_at(player.position + Vector2(100, 0)) == false, "No slash once fallen")
	check(player.wave_at(player.position + Vector2(100, 0)) == null, "No wave once fallen")
	Engine.time_scale = 1.0
	finish("left-click Wind Slash lands as the blade comes round, hitting enemies in reach inside a 120-degree arc and no others; free, one per swing time, six-frame slash, wind crescent along the aim; hit-stop and knockback on contact; a dodge cancels it; spell and wind damage raise it; 2 sends a piercing Wind Wave for mana that hits each enemy in its path once; swords are off-hand gear raising wind damage; drops a carried item instead; none once fallen")


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

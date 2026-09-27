extends SceneTree

const STATS := preload("res://stats.gd")
const SAVE := "user://test_character_saves.json"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var character = root.get_node("Character")
	var inventory = root.get_node("Inventory")
	inventory.use_save_path("user://test_inventory.json")
	inventory.clear()

	# Test runs never touch a real save.
	check(character.save_path == character.TEST_SAVE_PATH and character.level == 1 and character.experience == 0, "Tests start at level 1 on a throwaway save")

	# Each level needs more experience than the last.
	check(character.experience_to_next(1) == 40 and character.experience_to_next(2) == 121)
	for level in range(1, character.MAX_LEVEL):
		check(character.experience_to_next(level + 1) > character.experience_to_next(level))

	# Experience carries over, and one big gain can cover several levels.
	character.use_save_path(SAVE)
	character.reset()
	check(character.add_experience(30) == 0 and character.level == 1 and character.experience == 30)
	check(is_equal_approx(character.progress(), 30.0 / 40.0))
	check(character.add_experience(15) == 1 and character.level == 2 and character.experience == 5, "Leftover experience carries over")
	var levels: Array = []
	character.leveled_up.connect(func(level: int) -> void: levels.append(level))
	check(character.add_experience(121 + 232) == 2 and character.level == 4 and character.experience == 5, "One gain can cover several levels")
	check(levels == [4], "One level-up signal per gain, with the new level")
	check(character.add_experience(0) == 0 and character.add_experience(-5) == 0 and character.experience == 5)

	# The level caps at the maximum.
	character.add_experience(10000000)
	check(character.level == character.MAX_LEVEL and character.experience == 0 and character.progress() == 1.0, "Levels cap at %d" % character.MAX_LEVEL)
	check(character.add_experience(100) == 0)

	# Level and experience save and reload.
	character.reset()
	character.add_experience(200)
	var saved := [character.level, character.experience]
	character.load_save()
	check([character.level, character.experience] == saved, "Level and experience survive a reload")
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	character.load_save()
	check(character.level == 1 and character.experience == 0, "A damaged save starts fresh")

	# Levels grow life, mana, and spell damage.
	var base := STATS.compute([], 1)
	var level_5 := STATS.compute([], 5)
	check(level_5.max_life == base.max_life + 4 * STATS.LIFE_PER_LEVEL)
	check(level_5.max_mana == base.max_mana + 4 * STATS.MANA_PER_LEVEL)
	check(level_5.spell_damage == base.spell_damage + 4 * STATS.SPELL_DAMAGE_PER_LEVEL)
	check(STATS.compute([]) == base, "Level 1 is the default")

	# In play: kills grant experience; a level-up grows stats and refills life and mana.
	character.reset()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
	var skitter = scene.get_node("Skitter")
	skitter.take_damage(999.0)
	check(character.experience == skitter.stats.experience, "A kill grants its experience")
	player.take_damage(50.0)
	player.mana = 10.0
	var sentinel = scene.get_node("Sentinel")
	sentinel.take_damage(999.0)
	check(character.level == 2, "Enough kills level up")
	check(player.max_health == STATS.BASE_LIFE + STATS.LIFE_PER_LEVEL and player.health == player.max_health, "Level 2: more life, refilled")
	check(player.max_mana == STATS.BASE_MANA + STATS.MANA_PER_LEVEL and player.mana == player.max_mana, "Level 2: more mana, refilled")
	check(player.stats.spell_damage == STATS.SPELL_DAMAGE_PER_LEVEL)
	check(scene.get_node("HUD/Message").text == "Level 2", "A level-up message shows")
	check(scene.get_children().any(func(node: Node) -> bool: return node.get_script() == player.LEVEL_UP_SCRIPT), "The level-up effect plays")

	# The HUD shows the level and progress; the character sheet spells it out.
	check(scene.get_node("HUD/ExperienceBar") != null)
	var panel = scene.get_node("HUD/CharacterPanel")
	panel.show()
	panel.refresh()
	check("Level 2" in panel.text.text and "XP %d / %d" % [character.experience, character.experience_to_next(2)] in panel.text.text, "The character sheet shows level and XP")

	# F6 grants exactly one level.
	var before: int = character.level
	scene.get_node("Debug").grant_level()
	check(character.level == before + 1 and character.experience == 0, "F6 grants a level")

	# No experience is lost when the wizard falls.
	var kept := [character.level, character.experience]
	player.take_damage(99999.0)
	check([character.level, character.experience] == kept, "Falling costs no experience")

	scene.queue_free()
	inventory.clear()
	DirAccess.remove_absolute(SAVE)
	DirAccess.remove_absolute("user://test_inventory.json")
	finish("tests use a throwaway save; rising experience curve; carry-over and multi-level gains; one signal per gain; max level cap; save, reload, damaged save; life, mana, and spell damage grow per level; kills grant experience; level-up refills life and mana with a message and effect; character sheet shows level and XP; F6 grants a level; no loss on death")


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

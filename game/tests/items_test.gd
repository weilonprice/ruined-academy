extends SceneTree

const DB := preload("res://items/item_database.gd")
const ITEM := preload("res://items/item.gd")
const GENERATOR := preload("res://items/item_generator.gd")
const STATS := preload("res://stats.gd")
const SAVE := "user://test_inventory.json"


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	check_generator()
	check_stats()
	var inventory = root.get_node("Inventory")
	inventory.use_save_path(SAVE)
	check_inventory(inventory)
	await check_player(inventory)
	DirAccess.remove_absolute(SAVE)
	print("PASS: rarity rules, affix counts, tiers by item level, base levels, no duplicate affixes, names, uniques, JSON round trip; stat totals, caps, armour and resistance; grid placement, equip slots, save and reload; wizard life/mana from gear, mana cost, cast speed, projectile speed, spell damage, crits, mitigation, regen; F3 debug roll; gear survives a restart")
	quit()


func check_generator() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var counts := [0, 0, 0, 0]
	for item_level in [1, 15, 30]:
		for index in range(1500):
			var item = GENERATOR.roll(item_level, rng)
			counts[item.rarity] += 1
			assert(item.required_level() <= item_level or item.rarity == DB.RARITY_UNIQUE, "Bases respect item level")
			var prefixes: int = item.affixes("prefix").size()
			var suffixes: int = item.affixes("suffix").size()
			match item.rarity:
				DB.RARITY_NORMAL:
					assert(prefixes + suffixes == 0)
					assert(item.display_name() == item.base().name)
				DB.RARITY_MAGIC:
					assert(prefixes <= 1 and suffixes <= 1 and prefixes + suffixes >= 1, "Magic: 1-2 affixes")
					assert(item.base().name in item.display_name())
				DB.RARITY_RARE:
					assert(prefixes <= 3 and suffixes <= 3 and prefixes + suffixes >= 3, "Rare: 3-6 affixes")
					assert(item.name.split(" ").size() == 2, "Rares get a two-word name")
			var seen := {}
			for mod in item.mods:
				if mod.kind in ["prefix", "suffix"]:
					assert(not seen.has(mod.affix), "No affix twice")
					seen[mod.affix] = true
					var affix: Dictionary = DB.AFFIXES[mod.affix]
					var tier: Array = affix.tiers[mod.tier]
					assert(affix.kind == mod.kind)
					assert(tier[0] <= item_level, "Tiers respect item level")
					assert(tier[1] <= mod.value and mod.value <= tier[2], "Values stay in their tier")
					assert(affix.tags.any(func(tag: String) -> bool: return tag in item.base().tags), "Affixes fit the base")
				elif mod.kind == "implicit":
					var implicit: Array = item.base().implicit
					assert(implicit[1] <= mod.value and mod.value <= implicit[2])
			# Every item survives a save round trip.
			var restored = ITEM.from_dict(JSON.parse_string(JSON.stringify(item.to_dict())))
			assert(restored.to_dict() == item.to_dict(), "JSON round trip keeps the item")
			assert(restored.describe() == item.describe())
	var total := float(counts.reduce(func(a: int, b: int) -> int: return a + b))
	assert(counts[0] / total > 0.5 and counts[1] / total > 0.25 and counts[2] > 0 and counts[3] > 0, "Rarity odds roughly follow the weights: %s" % [counts])
	# Uniques above the item level fall back to rare.
	assert(GENERATOR.roll(1, rng, DB.RARITY_UNIQUE).rarity == DB.RARITY_RARE)
	var mantle = GENERATOR.make_unique("headmasters_mantle", 20)
	assert(mantle.display_name() == "The Headmaster's Mantle" and mantle.stats().spell_damage == 15 and mantle.stats().armour == 52)
	var lines: Array = mantle.describe()
	assert(lines[0][0] == "The Headmaster's Mantle" and lines[1][0] == "Student Robe")
	assert(lines.any(func(line: Array) -> bool: return line[0] == "15% increased Spell Damage"))
	assert(lines[-1][0] == DB.UNIQUES.headmasters_mantle.flavour)


func check_stats() -> void:
	var base := STATS.compute([])
	assert(base.max_life == 100.0 and base.max_mana == 60.0 and base.crit_chance == 5.0 and base.mana_regen == 6.0)
	var ring = make_item("ruby_ring", [["fire_res", 60], ["crit_chance", 100], ["mana_regen", 50]])
	var belt = make_item("rope_belt", [["life", 40], ["fire_res", 30], ["cold_res", 20]])
	var totals := STATS.compute([ring, belt])
	assert(totals.max_life == 140.0)
	assert(totals.fire_res == 75.0, "Resistances cap at 75%")
	assert(totals.cold_res == 20.0)
	assert(totals.crit_chance == 10.0, "100% increased crit chance doubles the base")
	assert(totals.mana_regen == 9.0)
	# Armour: reduction = armour / (armour + 10 * damage).
	var armoured := {"armour": 100.0}
	assert(is_equal_approx(STATS.mitigate(10.0, "physical", armoured), 5.0))
	assert(is_equal_approx(STATS.mitigate(40.0, "physical", armoured), 32.0), "Big hits get through armour more")
	assert(is_equal_approx(STATS.mitigate(10.0, "physical", {"armour": 1e9}), 1.0), "Armour caps at 90%")
	assert(is_equal_approx(STATS.mitigate(10.0, "fire", totals), 2.5))
	assert(is_equal_approx(STATS.mitigate(10.0, "lightning", totals), 10.0))


func check_inventory(inventory) -> void:
	inventory.clear()
	var staff = make_item("apprentice_staff", [])
	var ring = make_item("copper_ring", [])
	# Items fill each column top to bottom, left to right.
	assert(inventory.add_item(staff) and inventory.backpack[0].cell == Vector2i(0, 0))
	assert(inventory.add_item(ring) and inventory.backpack[1].cell == Vector2i(0, 4))
	assert(inventory.item_at(Vector2i(1, 3)) == staff and inventory.item_at(Vector2i(0, 4)) == ring)
	assert(inventory.item_at(Vector2i(2, 0)) == null)
	assert(not inventory.can_place(make_item("student_robe", []), Vector2i(1, 0)), "Items cannot overlap")
	assert(not inventory.can_place(make_item("student_robe", []), Vector2i(9, 0)), "Items stay inside the grid")
	assert(inventory.can_place(staff, Vector2i(1, 0), staff), "An item may overlap itself when moved")
	var added := 2
	while inventory.add_item(make_item("student_robe", [])):
		added += 1
	# 2x3 robes fit in 4 of the remaining 2-column pairs.
	assert(added == 6 and not inventory.add_item(make_item("student_robe", [])), "A full backpack refuses items")
	assert(inventory.remove(ring) and inventory.item_at(Vector2i(0, 4)) == null)
	# Equipment: rings fill left then right; wrong slots are refused by fits_slot.
	var left = make_item("ruby_ring", [["life", 10]])
	var right = make_item("topaz_ring", [])
	assert(inventory.slot_for(left) == "ring_left")
	inventory.equip(left, "ring_left")
	assert(inventory.slot_for(right) == "ring_right")
	inventory.equip(right, "ring_right")
	assert(not staff.fits_slot("helmet") and staff.fits_slot("weapon"))
	var replaced = inventory.equip(make_item("sapphire_ring", []), "ring_left")
	assert(replaced == left)
	assert(inventory.unequip("ring_right") == right and not inventory.equipment.has("ring_right"))
	# Everything saves and reloads.
	var before := snapshot(inventory)
	inventory.load_save()
	assert(snapshot(inventory) == before, "The save reloads the same gear")
	# A damaged save is ignored rather than crashing.
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	inventory.load_save()
	assert(inventory.equipment.is_empty() and inventory.backpack.is_empty())
	inventory.clear()


func check_player(inventory) -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Wizard")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.ai_enabled = false
	await process_frame
	assert(player.max_health == 100.0 and player.health == 100.0 and player.mana == 60.0)

	# Casting spends mana and waits for the cast time.
	var shot = player.shoot_at(player.global_position + Vector2(100, 0))
	assert(shot != null and player.mana == 55.0)
	assert(player.shoot_at(player.global_position + Vector2(100, 0)) == null, "No second cast before the first finishes")
	assert(is_equal_approx(player.cast_ready_in, 0.25))
	assert(shot.damage >= 8.0 and shot.damage <= 18.0 and shot.speed == 300.0)
	player.cast_ready_in = 0.0
	player.mana = 4.0
	assert(player.shoot_at(player.global_position + Vector2(100, 0)) == null, "No cast without mana")

	# Gear feeds the wizard's stats as soon as it is equipped.
	var staff = make_item("apprentice_staff", [["spell_damage", 100], ["cast_speed", 100], ["projectile_speed", 50], ["crit_chance", 1900]])
	var robe = make_item("student_robe", [["life", 50], ["mana", 40], ["armour", 88], ["fire_res", 50]])
	inventory.equip(staff, "weapon")
	inventory.equip(robe, "body")
	assert(player.max_health == 150.0 and player.health == 100.0, "More max life does not heal")
	assert(player.max_mana == 100.0)
	assert(player.stats.armour == 100.0)
	player.cast_ready_in = 0.0
	player.mana = player.max_mana
	player.rng.seed = 3
	shot = player.shoot_at(player.global_position + Vector2(100, 0))
	assert(is_equal_approx(player.cast_ready_in, 0.125), "+100% cast speed halves the cast time")
	assert(shot.speed == 450.0)
	assert(shot.critical, "100% crit chance always crits")
	assert(shot.damage >= 8.0 * 2.0 * 1.5 and shot.damage <= 12.0 * 2.0 * 1.5, "Spell damage and crits scale the bolt")
	assert(player.sprite.speed_scale == 2.0, "The cast animation speeds up too")

	# Armour and resistance reduce hits; regeneration refills.
	player.take_damage(10.0, "physical")
	assert(is_equal_approx(player.health, 95.0))
	player.take_damage(10.0, "fire")
	assert(is_equal_approx(player.health, 90.0))
	inventory.equip(make_item("rope_belt", [["life_regen", 4]]), "belt")
	player.mana = 10.0
	player._physics_process(1.0)
	assert(is_equal_approx(player.health, 94.0) and is_equal_approx(player.mana, 16.0))
	# Removing gear caps life and mana to the new maximums.
	inventory.unequip("body")
	assert(player.max_health == 100.0 and player.health == 94.0 and player.max_mana == 60.0 and player.mana == 16.0)

	# F3 rolls a random item and equips it; what it replaces goes to the backpack.
	inventory.clear()
	var rolled = scene.get_node("Debug").roll_and_equip()
	var slot: String = inventory.slot_for(rolled)
	assert(inventory.equipment.values().has(rolled))
	var first = rolled
	for attempt in range(40):
		rolled = scene.get_node("Debug").roll_and_equip()
		if rolled.base().slot == first.base().slot and first.base().slot != "ring":
			break
	if rolled.base().slot == first.base().slot and first.base().slot != "ring":
		assert(inventory.backpack.any(func(entry: Dictionary) -> bool: return entry.item == first), "The replaced item goes to the backpack")
	assert(scene.get_node("HUD/Message").visible)

	# Gear lives outside the scene, so it survives a restart.
	var kept := snapshot(inventory)
	scene.queue_free()
	await process_frame
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(snapshot(inventory) == kept)
	var fresh = scene.get_node("Wizard")
	assert(fresh.stats == STATS.compute(inventory.equipped_items()) and fresh.health == fresh.max_health)
	scene.queue_free()
	inventory.clear()


func make_item(base_id: String, stat_mods: Array):
	var item = ITEM.new()
	item.base_id = base_id
	item.rarity = DB.RARITY_MAGIC if not stat_mods.is_empty() else DB.RARITY_NORMAL
	for pair in stat_mods:
		item.mods.append({"kind": "unique", "stat": pair[0], "value": pair[1], "affix": "", "tier": 0})
	return item


func snapshot(inventory) -> Dictionary:
	var equipped := {}
	for slot in inventory.equipment:
		equipped[slot] = inventory.equipment[slot].to_dict()
	var bag: Array = inventory.backpack.map(func(entry: Dictionary) -> Array: return [entry.item.to_dict(), entry.cell])
	return {"equipment": equipped, "backpack": bag}

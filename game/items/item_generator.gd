extends RefCounted

# Rolls random items. Pass a seeded RandomNumberGenerator for repeatable results.

const DB := preload("res://items/item_database.gd")
const ITEM := preload("res://items/item.gd")

# Relative odds of each rarity for ordinary drops.
const DROP_WEIGHTS := [60.0, 32.0, 7.5, 0.5]


# A random item of a random (or given) rarity, from bases the item level allows.
static func roll(item_level: int, rng: RandomNumberGenerator, rarity := -1, weights := DROP_WEIGHTS):
	if rarity < 0:
		rarity = rng.rand_weighted(PackedFloat32Array(weights))
	if rarity == DB.RARITY_UNIQUE:
		var uniques := DB.UNIQUES.keys().filter(func(id: String) -> bool: return DB.UNIQUES[id].level <= item_level)
		if not uniques.is_empty():
			return make_unique(uniques[rng.randi() % uniques.size()], item_level)
		rarity = DB.RARITY_RARE
	var bases := DB.BASES.keys().filter(func(id: String) -> bool: return DB.BASES[id].level <= item_level)
	return roll_base(bases[rng.randi() % bases.size()], item_level, rarity, rng)


static func roll_base(base_id: String, item_level: int, rarity: int, rng: RandomNumberGenerator):
	var item = ITEM.new()
	item.base_id = base_id
	item.rarity = rarity
	item.item_level = item_level
	var base: Dictionary = DB.BASES[base_id]
	if base.has("implicit"):
		item.mods.append({"kind": "implicit", "stat": base.implicit[0],
			"value": rng.randi_range(base.implicit[1], base.implicit[2]), "affix": "", "tier": 0})
	match rarity:
		DB.RARITY_MAGIC:
			# One or two affixes: a prefix, a suffix, or both.
			var shape := rng.randi_range(0, 2)
			if shape != 1:
				_add_affix(item, "prefix", rng)
			if shape != 0:
				_add_affix(item, "suffix", rng)
		DB.RARITY_RARE:
			var count := rng.randi_range(3, 6)
			for index in range(count):
				# Alternate so both sides fill; a side with no room or no options is skipped.
				var kind := "prefix" if index % 2 == 0 else "suffix"
				if not _add_affix(item, kind, rng):
					_add_affix(item, "suffix" if kind == "prefix" else "prefix", rng)
			var seconds: Array = DB.RARE_SECOND[base.slot]
			item.name = "%s %s" % [DB.RARE_FIRST[rng.randi() % DB.RARE_FIRST.size()], seconds[rng.randi() % seconds.size()]]
	return item


static func make_unique(unique_id: String, item_level: int):
	var unique: Dictionary = DB.UNIQUES[unique_id]
	var item = ITEM.new()
	item.base_id = unique.base
	item.rarity = DB.RARITY_UNIQUE
	item.item_level = item_level
	item.name = unique.name
	item.unique_id = unique_id
	for pair in unique.mods:
		item.mods.append({"kind": "unique", "stat": pair[0], "value": pair[1], "affix": "", "tier": 0})
	return item


# Adds one affix of the kind if the item has room and an unused affix fits its base.
static func _add_affix(item, kind: String, rng: RandomNumberGenerator) -> bool:
	var limit := 1 if item.rarity == DB.RARITY_MAGIC else 3
	if item.affixes(kind).size() >= limit:
		return false
	var taken: Array = item.mods.map(func(mod: Dictionary) -> String: return mod.affix)
	var tags: Array = item.base().tags
	var options := DB.AFFIXES.keys().filter(func(id: String) -> bool:
		var affix: Dictionary = DB.AFFIXES[id]
		return affix.kind == kind and id not in taken and affix.tags.any(func(tag: String) -> bool: return tag in tags))
	if options.is_empty():
		return false
	var affix_id: String = options[rng.randi() % options.size()]
	var tiers: Array = DB.AFFIXES[affix_id].tiers
	var allowed := range(tiers.size()).filter(func(index: int) -> bool: return tiers[index][0] <= item.item_level)
	var tier: int = allowed[rng.randi() % allowed.size()]
	item.mods.append({"kind": kind, "stat": DB.AFFIXES[affix_id].stat,
		"value": rng.randi_range(tiers[tier][1], tiers[tier][2]), "affix": affix_id, "tier": tier})
	return true

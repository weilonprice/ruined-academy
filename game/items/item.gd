extends RefCounted

# One item: a base type, a rarity, an item level, and its rolled mods.
# Each mod is {"kind": implicit|prefix|suffix|unique, "stat", "value", "affix", "tier"}.

const DB := preload("res://items/item_database.gd")
const MUTED := Color("7f7f7f")
const PROPERTY := Color("c8c8c8")
const MOD := Color("8888ff")
const FLAVOUR := Color("af6025")

var base_id := ""
var rarity := DB.RARITY_NORMAL
var item_level := 1
# Rare and unique items carry their own name; others derive it from base and affixes.
var name := ""
var unique_id := ""
var mods: Array[Dictionary] = []


func base() -> Dictionary:
	return DB.BASES[base_id]


func size() -> Vector2i:
	return base().size


func fits_slot(slot: String) -> bool:
	var kind: String = base().slot
	return slot == kind or (kind == "ring" and slot.begins_with("ring_"))


func required_level() -> int:
	if unique_id != "":
		return DB.UNIQUES[unique_id].level
	return base().level


# Every stat this item grants: base properties plus all mods.
func stats() -> Dictionary:
	var totals: Dictionary = base().get("properties", {}).duplicate()
	for mod in mods:
		totals[mod.stat] = totals.get(mod.stat, 0) + mod.value
	return totals


func affixes(kind: String) -> Array[Dictionary]:
	return mods.filter(func(mod: Dictionary) -> bool: return mod.kind == kind)


func display_name() -> String:
	if rarity == DB.RARITY_MAGIC:
		var words: Array[String] = []
		for mod in affixes("prefix"):
			words.append(tier_name(mod))
		words.append(base().name)
		for mod in affixes("suffix"):
			words.append(tier_name(mod))
		return " ".join(words)
	if name != "":
		return name
	return base().name


func color() -> Color:
	return DB.RARITY_COLORS[rarity]


# Tooltip lines as [text, color]; a line of "" is a divider.
func describe() -> Array:
	var lines: Array = [[display_name(), color()]]
	if rarity >= DB.RARITY_RARE:
		lines.append([base().name, color()])
	lines.append(["", MUTED])
	var properties: Dictionary = base().get("properties", {})
	for stat in properties:
		lines.append(["%s: %d" % [stat.capitalize(), properties[stat]], PROPERTY])
	lines.append(["Item Level: %d" % item_level, MUTED])
	lines.append(["Requires Level %d" % required_level(), MUTED])
	var implicits := affixes("implicit")
	if not implicits.is_empty():
		lines.append(["", MUTED])
		for mod in implicits:
			lines.append([stat_line(mod), MOD])
	var explicit := mods.filter(func(mod: Dictionary) -> bool: return mod.kind != "implicit")
	if not explicit.is_empty():
		lines.append(["", MUTED])
		for mod in explicit:
			lines.append([stat_line(mod), MOD])
	if unique_id != "":
		lines.append(["", MUTED])
		lines.append([DB.UNIQUES[unique_id].flavour, FLAVOUR])
	return lines


func to_dict() -> Dictionary:
	return {"base": base_id, "rarity": rarity, "item_level": item_level, "name": name,
		"unique": unique_id, "mods": mods.duplicate(true)}


static func from_dict(data: Dictionary):
	var item = load("res://items/item.gd").new()
	item.base_id = data.base
	item.rarity = int(data.rarity)
	item.item_level = int(data.item_level)
	item.name = data.get("name", "")
	item.unique_id = data.get("unique", "")
	for mod: Dictionary in data.mods:
		var restored := mod.duplicate()
		# JSON reads every number back as a float.
		restored.value = int(mod.value)
		restored.tier = int(mod.get("tier", 0))
		item.mods.append(restored)
	return item


static func stat_line(mod: Dictionary) -> String:
	return DB.STAT_TEXT[mod.stat] % mod.value


static func tier_name(mod: Dictionary) -> String:
	return DB.AFFIXES[mod.affix].tiers[mod.tier][3]

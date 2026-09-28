extends RefCounted

# Character stats: base values plus everything equipped, and the damage maths.

const BASE_LIFE := 100.0
const BASE_MANA := 60.0
const BASE_MANA_REGEN := 6.0
const BASE_CRIT_CHANCE := 5.0
const CRIT_MULTIPLIER := 1.5
const MAX_RESISTANCE := 75.0
const MAX_ARMOUR_REDUCTION := 0.9
# Armour's reduction shrinks as hits grow: armour / (armour + ARMOUR_SCALE * damage).
const ARMOUR_SCALE := 10.0
const DAMAGE_TYPES := ["physical", "fire", "cold", "lightning"]
# Each level past the first adds this much.
const LIFE_PER_LEVEL := 8.0
const MANA_PER_LEVEL := 4.0
const SPELL_DAMAGE_PER_LEVEL := 2.0
const PASSIVES := preload("res://passives.gd")


# Final stats from the wizard's level, equipped items, and allocated passives.
static func compute(items: Array, level := 1, passives := []) -> Dictionary:
	var growth := level - 1
	var sums: Dictionary = PASSIVES.stats(passives)
	for item in items:
		var item_stats: Dictionary = item.stats()
		for stat in item_stats:
			sums[stat] = sums.get(stat, 0) + item_stats[stat]
	return {
		"max_life": BASE_LIFE + LIFE_PER_LEVEL * growth + sums.get("life", 0),
		"life_regen": float(sums.get("life_regen", 0)),
		"armour": float(sums.get("armour", 0)),
		"max_mana": BASE_MANA + MANA_PER_LEVEL * growth + sums.get("mana", 0),
		"mana_regen": BASE_MANA_REGEN * (1.0 + sums.get("mana_regen", 0) / 100.0),
		"spell_damage": SPELL_DAMAGE_PER_LEVEL * growth + sums.get("spell_damage", 0),
		# Adds to spell damage for the wind skills, Wind Slash and Wind Wave.
		"wind_damage": float(sums.get("wind_damage", 0)),
		"cast_speed": float(sums.get("cast_speed", 0)),
		"projectile_speed": float(sums.get("projectile_speed", 0)),
		"crit_chance": BASE_CRIT_CHANCE * (1.0 + sums.get("crit_chance", 0) / 100.0),
		"fire_res": minf(MAX_RESISTANCE, sums.get("fire_res", 0)),
		"cold_res": minf(MAX_RESISTANCE, sums.get("cold_res", 0)),
		"lightning_res": minf(MAX_RESISTANCE, sums.get("lightning_res", 0)),
		"nova_area": float(sums.get("nova_area", 0)),
		"nova_chill": float(sums.get("nova_chill", 0)),
	}


# Damage left after armour (physical) or resistance (elemental).
static func mitigate(damage: float, damage_type: String, stats: Dictionary) -> float:
	if damage <= 0.0:
		return 0.0
	if damage_type == "physical":
		var armour: float = stats.armour
		var reduction := minf(MAX_ARMOUR_REDUCTION, armour / (armour + ARMOUR_SCALE * damage))
		return damage * (1.0 - reduction)
	var resistance: float = stats.get(damage_type + "_res", 0.0)
	return damage * (1.0 - resistance / 100.0)

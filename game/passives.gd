extends RefCounted

# The passive tree: nodes, what each grants, where it sits, and how they link.
# A node can be allocated once it links to START or to an allocated node.

const START := "start"
# Stats use the same names as item stats, plus two for Frost Nova:
# nova_area (% increased radius) and nova_chill (extra seconds of chill).
const NODES := {
	"vitality": {"name": "Vitality", "icon": "heart", "position": Vector2(-70, -40),
		"stats": {"life": 20, "life_regen": 1}, "text": ["+20 to maximum Life", "Regenerate 1 Life per second"]},
	"deep_reserves": {"name": "Deep Reserves", "icon": "droplet", "position": Vector2(-70, 40),
		"stats": {"mana": 20, "mana_regen": 20}, "text": ["+20 to maximum Mana", "20% increased Mana Regeneration Rate"]},
	"spell_mastery": {"name": "Spell Mastery", "icon": "burst", "position": Vector2(10, 0),
		"stats": {"spell_damage": 15}, "text": ["15% increased Spell Damage"]},
	"frostweaving": {"name": "Frostweaving", "icon": "snowflake", "position": Vector2(90, -40),
		"stats": {"nova_area": 30, "nova_chill": 1}, "text": ["Frost Nova has 30% increased radius", "Frost Nova chills for 1 second longer"]},
	"keen_mind": {"name": "Keen Mind", "icon": "eye", "position": Vector2(90, 40),
		"stats": {"crit_chance": 50, "cast_speed": 8}, "text": ["50% increased Critical Strike Chance", "8% increased Cast Speed"]},
}
const START_POSITION := Vector2(-140, 0)
# Undirected links between nodes.
const LINKS := [
	[START, "vitality"], [START, "deep_reserves"],
	["vitality", "spell_mastery"], ["deep_reserves", "spell_mastery"],
	["spell_mastery", "frostweaving"], ["spell_mastery", "keen_mind"],
]


static func neighbours(id: String) -> Array:
	var found := []
	for link in LINKS:
		if link[0] == id:
			found.append(link[1])
		elif link[1] == id:
			found.append(link[0])
	return found


static func position_of(id: String) -> Vector2:
	return START_POSITION if id == START else NODES[id].position


# Whether every allocated node still links back to START through allocated nodes.
static func connected(allocated: Array) -> bool:
	var reached := {START: true}
	var frontier := [START]
	while not frontier.is_empty():
		var current: String = frontier.pop_back()
		for next in neighbours(current):
			if next in allocated and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return allocated.all(func(id: String) -> bool: return reached.has(id))


# Every stat the allocated nodes grant, summed.
static func stats(allocated: Array) -> Dictionary:
	var totals := {}
	for id in allocated:
		var granted: Dictionary = NODES[id].stats
		for stat in granted:
			totals[stat] = totals.get(stat, 0) + granted[stat]
	return totals

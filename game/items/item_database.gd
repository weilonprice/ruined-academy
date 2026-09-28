extends RefCounted

# Static item data: base types, affixes, uniques, and rare-name words.

const RARITY_NORMAL := 0
const RARITY_MAGIC := 1
const RARITY_RARE := 2
const RARITY_UNIQUE := 3
const RARITY_NAMES := ["Normal", "Magic", "Rare", "Unique"]
const RARITY_COLORS := [Color("c8c8c8"), Color("8888ff"), Color("ffff77"), Color("af6025")]

# Equipment slots, in panel order. Ring bases fit either ring slot.
const SLOTS := ["weapon", "offhand", "helmet", "body", "gloves", "boots", "belt", "amulet", "ring_left", "ring_right"]

# How each stat reads on a tooltip.
const STAT_TEXT := {
	"life": "+%d to maximum Life",
	"life_regen": "Regenerate %d Life per second",
	"armour": "+%d to Armour",
	"mana": "+%d to maximum Mana",
	"mana_regen": "%d%% increased Mana Regeneration Rate",
	"spell_damage": "%d%% increased Spell Damage",
	"wind_damage": "%d%% increased Wind Damage",
	"cast_speed": "%d%% increased Cast Speed",
	"projectile_speed": "%d%% increased Projectile Speed",
	"crit_chance": "%d%% increased Critical Strike Chance for Spells",
	"fire_res": "+%d%% to Fire Resistance",
	"cold_res": "+%d%% to Cold Resistance",
	"lightning_res": "+%d%% to Lightning Resistance",
}

# Base types. size is in backpack cells; properties are fixed base values (armour);
# the implicit rolls once in its range. tags decide which affixes can appear.
const BASES := {
	"apprentice_staff": {"name": "Apprentice Staff", "slot": "weapon", "size": Vector2i(2, 4), "level": 1,
		"implicit": ["spell_damage", 8, 12], "tags": ["weapon"], "icon": "apprentice_staff"},
	"ember_staff": {"name": "Ember Staff", "slot": "weapon", "size": Vector2i(2, 4), "level": 12,
		"implicit": ["spell_damage", 14, 18], "tags": ["weapon"], "icon": "ember_staff"},
	"rime_staff": {"name": "Rime Staff", "slot": "weapon", "size": Vector2i(2, 4), "level": 22,
		"implicit": ["crit_chance", 20, 25], "tags": ["weapon"], "icon": "rime_staff"},
	# Swords go in the off hand: the wizard swings one in his free hand while the staff stays in the other.
	"short_sword": {"name": "Short Sword", "slot": "offhand", "size": Vector2i(1, 3), "level": 1,
		"implicit": ["wind_damage", 10, 15], "tags": ["offhand", "sword"], "icon": "short_sword"},
	"windblade": {"name": "Windblade", "slot": "offhand", "size": Vector2i(1, 3), "level": 15,
		"implicit": ["wind_damage", 20, 30], "tags": ["offhand", "sword"], "icon": "windblade"},
	"copper_focus": {"name": "Copper Focus", "slot": "offhand", "size": Vector2i(2, 2), "level": 1,
		"implicit": ["mana", 10, 15], "tags": ["offhand"], "icon": "copper_focus"},
	"quartz_focus": {"name": "Quartz Focus", "slot": "offhand", "size": Vector2i(2, 2), "level": 15,
		"implicit": ["cast_speed", 5, 8], "tags": ["offhand"], "icon": "quartz_focus"},
	"scholars_hood": {"name": "Scholar's Hood", "slot": "helmet", "size": Vector2i(2, 2), "level": 1,
		"properties": {"armour": 8}, "tags": ["armour"], "icon": "scholars_hood"},
	"warden_helm": {"name": "Warden Helm", "slot": "helmet", "size": Vector2i(2, 2), "level": 15,
		"properties": {"armour": 20}, "tags": ["armour"], "icon": "warden_helm"},
	"student_robe": {"name": "Student Robe", "slot": "body", "size": Vector2i(2, 3), "level": 1,
		"properties": {"armour": 12}, "implicit": ["mana", 8, 12], "tags": ["armour"], "icon": "student_robe"},
	"warded_robe": {"name": "Warded Robe", "slot": "body", "size": Vector2i(2, 3), "level": 12,
		"properties": {"armour": 30}, "tags": ["armour"], "icon": "warded_robe"},
	"ashweave_robe": {"name": "Ashweave Robe", "slot": "body", "size": Vector2i(2, 3), "level": 25,
		"properties": {"armour": 45}, "implicit": ["fire_res", 8, 12], "tags": ["armour"], "icon": "ashweave_robe"},
	"cloth_wraps": {"name": "Cloth Wraps", "slot": "gloves", "size": Vector2i(2, 2), "level": 1,
		"properties": {"armour": 5}, "tags": ["armour", "gloves"], "icon": "cloth_wraps"},
	"bronze_gauntlets": {"name": "Bronze Gauntlets", "slot": "gloves", "size": Vector2i(2, 2), "level": 14,
		"properties": {"armour": 14}, "tags": ["armour", "gloves"], "icon": "bronze_gauntlets"},
	"worn_sandals": {"name": "Worn Sandals", "slot": "boots", "size": Vector2i(2, 2), "level": 1,
		"properties": {"armour": 5}, "tags": ["armour"], "icon": "worn_sandals"},
	"bronze_greaves": {"name": "Bronze Greaves", "slot": "boots", "size": Vector2i(2, 2), "level": 14,
		"properties": {"armour": 14}, "tags": ["armour"], "icon": "bronze_greaves"},
	"rope_belt": {"name": "Rope Belt", "slot": "belt", "size": Vector2i(2, 1), "level": 1,
		"implicit": ["life", 10, 20], "tags": ["belt"], "icon": "rope_belt"},
	"scholars_sash": {"name": "Scholar's Sash", "slot": "belt", "size": Vector2i(2, 1), "level": 10,
		"implicit": ["mana", 10, 20], "tags": ["belt"], "icon": "scholars_sash"},
	"copper_amulet": {"name": "Copper Amulet", "slot": "amulet", "size": Vector2i(1, 1), "level": 1,
		"implicit": ["life_regen", 1, 2], "tags": ["jewellery", "amulet"], "icon": "copper_amulet"},
	"quartz_amulet": {"name": "Quartz Amulet", "slot": "amulet", "size": Vector2i(1, 1), "level": 12,
		"implicit": ["mana_regen", 20, 30], "tags": ["jewellery", "amulet"], "icon": "quartz_amulet"},
	"copper_ring": {"name": "Copper Ring", "slot": "ring", "size": Vector2i(1, 1), "level": 1,
		"implicit": ["life_regen", 1, 1], "tags": ["jewellery"], "icon": "copper_ring"},
	"ruby_ring": {"name": "Ruby Ring", "slot": "ring", "size": Vector2i(1, 1), "level": 8,
		"implicit": ["fire_res", 10, 15], "tags": ["jewellery"], "icon": "ruby_ring"},
	"sapphire_ring": {"name": "Sapphire Ring", "slot": "ring", "size": Vector2i(1, 1), "level": 8,
		"implicit": ["cold_res", 10, 15], "tags": ["jewellery"], "icon": "sapphire_ring"},
	"topaz_ring": {"name": "Topaz Ring", "slot": "ring", "size": Vector2i(1, 1), "level": 8,
		"implicit": ["lightning_res", 10, 15], "tags": ["jewellery"], "icon": "topaz_ring"},
}

# Affixes. Each tier is [minimum item level, min value, max value, name]; an item
# rolls from the tiers its level allows. An affix appears on a base sharing a tag.
const AFFIXES := {
	"life": {"kind": "prefix", "stat": "life", "tags": ["armour", "belt", "jewellery"],
		"tiers": [[1, 10, 19, "Hale"], [10, 20, 29, "Hearty"], [20, 30, 39, "Stalwart"], [35, 40, 49, "Unyielding"]]},
	"armour": {"kind": "prefix", "stat": "armour", "tags": ["armour"],
		"tiers": [[1, 10, 25, "Riveted"], [12, 26, 50, "Plated"], [25, 51, 90, "Bulwark"]]},
	"mana": {"kind": "prefix", "stat": "mana", "tags": ["weapon", "offhand", "armour", "belt", "jewellery"],
		"tiers": [[1, 10, 19, "Glinting"], [12, 20, 29, "Lucid"], [25, 30, 44, "Brimming"]]},
	"spell_damage": {"kind": "prefix", "stat": "spell_damage", "tags": ["weapon", "offhand", "amulet"],
		"tiers": [[1, 5, 9, "Novice's"], [8, 10, 19, "Adept's"], [18, 20, 29, "Scholar's"], [30, 30, 39, "Archmage's"]]},
	"wind_damage": {"kind": "prefix", "stat": "wind_damage", "tags": ["sword", "gloves"],
		"tiers": [[1, 10, 19, "Gusting"], [12, 20, 29, "Howling"], [25, 30, 39, "Tempest's"]]},
	"life_regen": {"kind": "suffix", "stat": "life_regen", "tags": ["armour", "belt", "jewellery"],
		"tiers": [[1, 1, 2, "of Mending"], [12, 3, 4, "of Renewal"], [25, 5, 6, "of Vigour"]]},
	"mana_regen": {"kind": "suffix", "stat": "mana_regen", "tags": ["weapon", "offhand", "jewellery"],
		"tiers": [[1, 10, 19, "of Focus"], [12, 20, 29, "of Clarity"], [25, 30, 40, "of Insight"]]},
	"cast_speed": {"kind": "suffix", "stat": "cast_speed", "tags": ["weapon", "offhand", "jewellery", "gloves"],
		"tiers": [[1, 3, 5, "of Swift Hands"], [12, 6, 9, "of Deft Casting"], [25, 10, 13, "of the Adept"]]},
	"projectile_speed": {"kind": "suffix", "stat": "projectile_speed", "tags": ["weapon", "offhand"],
		"tiers": [[1, 10, 19, "of Flight"], [15, 20, 29, "of Soaring"]]},
	"crit_chance": {"kind": "suffix", "stat": "crit_chance", "tags": ["weapon", "offhand", "amulet"],
		"tiers": [[1, 10, 19, "of Menace"], [12, 20, 29, "of Ruin"], [25, 30, 39, "of Calamity"]]},
	"fire_res": {"kind": "suffix", "stat": "fire_res", "tags": ["armour", "belt", "jewellery", "offhand"],
		"tiers": [[1, 6, 11, "of Embers"], [10, 12, 17, "of Cinders"], [20, 18, 23, "of the Kiln"], [30, 24, 29, "of the Furnace"]]},
	"cold_res": {"kind": "suffix", "stat": "cold_res", "tags": ["armour", "belt", "jewellery", "offhand"],
		"tiers": [[1, 6, 11, "of Frost"], [10, 12, 17, "of Rime"], [20, 18, 23, "of the Glacier"], [30, 24, 29, "of Deep Winter"]]},
	"lightning_res": {"kind": "suffix", "stat": "lightning_res", "tags": ["armour", "belt", "jewellery", "offhand"],
		"tiers": [[1, 6, 11, "of Sparks"], [10, 12, 17, "of the Squall"], [20, 18, 23, "of the Tempest"], [30, 24, 29, "of Thunder"]]},
}

# Hand-made items with fixed stats.
const UNIQUES := {
	"headmasters_mantle": {"name": "The Headmaster's Mantle", "base": "student_robe", "level": 10,
		"mods": [["armour", 40], ["mana", 30], ["spell_damage", 15], ["fire_res", 20], ["cast_speed", 10]],
		"flavour": "The last ward he wove still holds."},
	"emberlink": {"name": "Emberlink", "base": "copper_ring", "level": 5,
		"mods": [["crit_chance", 30], ["fire_res", 15], ["life", 20]],
		"flavour": "A spark kept is a spark owed."},
}

# Rare names: a first word, then a word that fits the slot.
const RARE_FIRST := ["Ash", "Bleak", "Dusk", "Grim", "Hollow", "Rune", "Vigil", "Wraith", "Storm", "Bone", "Ember", "Gloom", "Oath", "Pale"]
const RARE_SECOND := {
	"weapon": ["Branch", "Spire", "Rod", "Call"],
	"offhand": ["Gaze", "Lantern", "Idol"],
	"helmet": ["Cowl", "Crown", "Veil"],
	"body": ["Shroud", "Mantle", "Vestment"],
	"gloves": ["Grasp", "Touch", "Hold"],
	"boots": ["Stride", "Tread", "March"],
	"belt": ["Cord", "Clasp", "Girdle"],
	"amulet": ["Charm", "Locket", "Torc"],
	"ring": ["Loop", "Band", "Coil"],
}

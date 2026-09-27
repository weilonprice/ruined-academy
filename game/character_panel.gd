extends PanelContainer

# The character sheet (C): equipped items and the stats they add up to.

const DB := preload("res://items/item_database.gd")
const SLOT_NAMES := {"weapon": "Weapon", "offhand": "Off-hand", "helmet": "Helmet", "body": "Body",
	"gloves": "Gloves", "boots": "Boots", "belt": "Belt", "amulet": "Amulet", "ring_left": "Ring", "ring_right": "Ring"}
const MUTED := "7f7f7f"

@onready var text: RichTextLabel = $Text


func _ready() -> void:
	hide()
	Inventory.changed.connect(refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_panel", false, true):
		visible = not visible
		refresh()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if not visible:
		return
	var player = get_tree().get_first_node_in_group("player")
	var lines: Array[String] = ["[b]Equipment[/b]"]
	for slot: String in DB.SLOTS:
		var item = Inventory.equipment.get(slot)
		var shown := "[color=#%s]%s[/color]" % [item.color().to_html(false), item.display_name()] if item else "[color=#%s]-[/color]" % MUTED
		lines.append("%s: %s" % [SLOT_NAMES[slot], shown])
	if player != null:
		var stats: Dictionary = player.stats
		lines.append("")
		lines.append("[b]Character[/b]")
		lines.append("Life: %d   Regen: %d/s" % [stats.max_life, stats.life_regen])
		lines.append("Mana: %d   Regen: %.1f/s" % [stats.max_mana, stats.mana_regen])
		lines.append("Armour: %d" % stats.armour)
		lines.append("Spell damage: +%d%%" % stats.spell_damage)
		lines.append("Cast speed: +%d%%" % stats.cast_speed)
		lines.append("Projectile speed: +%d%%" % stats.projectile_speed)
		lines.append("Crit chance: %.1f%%" % stats.crit_chance)
		lines.append("Resist: [color=#d66765]%d%%[/color] [color=#7fb3e0]%d%%[/color] [color=#e0d06a]%d%%[/color]" % [stats.fire_res, stats.cold_res, stats.lightning_res])
	text.text = "\n".join(lines)

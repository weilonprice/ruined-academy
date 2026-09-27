extends Node

# The wizard's level and experience. An autoload, so it survives scene
# reloads, and saved to its own file like the inventory.

signal changed
signal leveled_up(level: int)

const MAX_LEVEL := 50
const PASSIVES := preload("res://passives.gd")
const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://character.json"
# Test scripts run as their own main loop; they get a throwaway file so they never touch a real save.
const TEST_SAVE_PATH := "user://test_character.json"

var save_path := DEFAULT_SAVE_PATH
var level := 1
# Experience earned toward the next level.
var experience := 0
# Allocated passive nodes; each level past the first gives one point.
var passives: Array[String] = []


func _ready() -> void:
	if Engine.get_main_loop().get_script() != null:
		save_path = TEST_SAVE_PATH
		reset()
	else:
		load_save()


# Experience needed to go from this level to the next; each level needs more.
static func experience_to_next(from_level: int) -> int:
	return roundi(40.0 * pow(from_level, 1.6))


func progress() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	return float(experience) / experience_to_next(level)


# Adds experience, levelling up as many times as it covers. Returns the levels gained.
func add_experience(amount: int) -> int:
	if amount <= 0 or level >= MAX_LEVEL:
		return 0
	experience += amount
	var gained := 0
	while level < MAX_LEVEL and experience >= experience_to_next(level):
		experience -= experience_to_next(level)
		level += 1
		gained += 1
	if level >= MAX_LEVEL:
		experience = 0
	save()
	changed.emit()
	if gained > 0:
		leveled_up.emit(level)
	return gained


func points_available() -> int:
	return level - 1 - passives.size()


func can_allocate(id: String) -> bool:
	if id in passives or not PASSIVES.NODES.has(id) or points_available() <= 0:
		return false
	return PASSIVES.neighbours(id).any(func(next: String) -> bool: return next == PASSIVES.START or next in passives)


func allocate(id: String) -> bool:
	if not can_allocate(id):
		return false
	passives.append(id)
	save()
	changed.emit()
	return true


# A node can be refunded if everything else still links back to the start without it.
func can_refund(id: String) -> bool:
	if id not in passives:
		return false
	var rest := passives.filter(func(other: String) -> bool: return other != id)
	return PASSIVES.connected(rest)


func refund(id: String) -> bool:
	if not can_refund(id):
		return false
	passives.erase(id)
	save()
	changed.emit()
	return true


func reset() -> void:
	level = 1
	experience = 0
	passives.clear()
	save()
	changed.emit()


func use_save_path(path: String) -> void:
	save_path = path
	load_save()


func save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save character to %s" % save_path)
		return
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "level": level, "experience": experience, "passives": passives}, "\t"))


func load_save() -> void:
	level = 1
	experience = 0
	passives.clear()
	if FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary and int(data.get("version", 0)) == SAVE_VERSION:
			level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
			experience = maxi(0, int(data.get("experience", 0)))
			# Keep only known nodes, within the points the level allows, still linked to the start.
			for id in data.get("passives", []):
				if PASSIVES.NODES.has(id) and id not in passives and passives.size() < level - 1:
					passives.append(id)
			if not PASSIVES.connected(passives):
				passives.clear()
		else:
			push_warning("Ignoring unreadable character save at %s" % save_path)
	changed.emit()

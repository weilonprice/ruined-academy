extends Node

# The wizard's level and experience. An autoload, so it survives scene
# reloads, and saved to its own file like the inventory.

signal changed
signal leveled_up(level: int)

const MAX_LEVEL := 50
const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://character.json"
# Test scripts run as their own main loop; they get a throwaway file so they never touch a real save.
const TEST_SAVE_PATH := "user://test_character.json"

var save_path := DEFAULT_SAVE_PATH
var level := 1
# Experience earned toward the next level.
var experience := 0


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


func reset() -> void:
	level = 1
	experience = 0
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
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "level": level, "experience": experience}, "\t"))


func load_save() -> void:
	level = 1
	experience = 0
	if FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary and int(data.get("version", 0)) == SAVE_VERSION:
			level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
			experience = maxi(0, int(data.get("experience", 0)))
		else:
			push_warning("Ignoring unreadable character save at %s" % save_path)
	changed.emit()

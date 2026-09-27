extends Control

# Esc pauses the game and offers Resume or Quit; Esc again resumes.
# While the inventory or passive tree is open, Esc closes it instead.

@onready var resume_button: Button = $Center/Box/Resume
@onready var quit_button: Button = $Center/Box/Quit


func _ready() -> void:
	# Keeps running while the rest of the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(resume)
	quit_button.pressed.connect(quit_game)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause", false, true):
		return
	# Esc closes an open screen first; only then does it pause.
	for screen in ["InventoryPanel", "PassiveTree"]:
		var node := get_parent().get_node_or_null(screen)
		if not visible and node != null and node.visible:
			return
	get_viewport().set_input_as_handled()
	if visible:
		resume()
	else:
		pause()


func pause() -> void:
	get_tree().paused = true
	show()
	resume_button.grab_focus()


func resume() -> void:
	get_tree().paused = false
	hide()


func quit_game() -> void:
	get_tree().quit()

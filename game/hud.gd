extends CanvasLayer

# Wizard health bar, and the message shown when the wizard falls.
const BAR := Rect2(8, 8, 104, 10)

var health := 1
var max_health := 1
@onready var bar: Control = $Bar
@onready var fallen: Label = $Fallen


func _ready() -> void:
	bar.draw.connect(_draw_bar)
	fallen.hide()
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.died.connect(fallen.show)
		_on_health_changed(player.health, player.MAX_HEALTH)


func _on_health_changed(new_health: int, new_max: int) -> void:
	health = new_health
	max_health = new_max
	bar.queue_redraw()


func _draw_bar() -> void:
	bar.draw_rect(BAR, Color("181c24"))
	var inner := BAR.grow(-2)
	bar.draw_rect(Rect2(inner.position, Vector2(inner.size.x * health / max_health, inner.size.y)), Color("d66765"))
	# Notches every health point keep damage readable at a glance.
	for point in range(1, max_health):
		var x := inner.position.x + inner.size.x * point / max_health
		bar.draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color("181c24"))

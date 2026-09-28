extends Node2D

# A road's end that leads to another map. Walking into the area loads the
# destination scene; the wizard appears there at arrive_at with the life,
# mana and flask charges he left with.

@export_file("*.tscn") var destination := ""
@export var size := Vector2(160, 40)
@export var arrive_at := Vector2.ZERO

# What the next map's wizard picks up in arrive(); empty when not travelling.
static var carried := {}


func area() -> Rect2:
	return Rect2(global_position - size / 2.0, size)


func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead or not area().has_point(player.global_position):
		return
	carried = {"position": arrive_at, "health": player.health, "mana": player.mana,
		"flask_charges": player.flask_charges.duplicate()}
	set_physics_process(false)
	get_tree().change_scene_to_file.call_deferred(destination)


# Places a newly loaded wizard where the road brought him, as he left the last map.
static func arrive(player: Node2D) -> void:
	if carried.is_empty():
		return
	player.position = carried.position
	player.health = minf(carried.health, player.max_health)
	player.mana = minf(carried.mana, player.max_mana)
	player.flask_charges = carried.flask_charges
	carried = {}

extends RefCounted

# What enemies drop, and spawning items onto the ground.

const DB := preload("res://items/item_database.gd")
const GENERATOR := preload("res://items/item_generator.gd")
const GROUND_ITEM := preload("res://ground_item.gd")
const WORLD := preload("res://world.gd")

# Per enemy kind: chances of dropping a first and a second item, rarity odds
# (normal, magic, rare, unique), and item levels above the area's.
const TABLES := {
	"skitter": {"chances": [0.6, 0.15], "weights": [60.0, 32.0, 7.5, 0.5], "level_bonus": 0},
	"scholar": {"chances": [0.6, 0.15], "weights": [60.0, 32.0, 7.5, 0.5], "level_bonus": 0},
	"sentinel": {"chances": [1.0, 0.4], "weights": [35.0, 42.0, 20.0, 3.0], "level_bonus": 5},
}
# Drops land this far from where the enemy fell, spread so labels don't pile up.
const SCATTER := 36.0
const SPACING := 26.0
const ATTEMPTS := 30

static var rng := RandomNumberGenerator.new()


# The items an enemy of this kind drops; may be empty.
static func roll_drops(kind: String) -> Array:
	var table: Dictionary = TABLES[kind]
	var drops := []
	for chance: float in table.chances:
		if rng.randf() < chance:
			drops.append(GENERATOR.roll(WORLD.AREA_LEVEL + table.level_bonus, rng, -1, table.weights))
	return drops


static func drop_for(kind: String, origin: Vector2, parent: Node) -> Array:
	var spawned := []
	for item in roll_drops(kind):
		spawned.append(spawn(item, origin, parent))
	return spawned


# Puts an item on the ground: it pops out of the origin and lands at a nearby free spot.
static func spawn(item, origin: Vector2, parent: Node) -> Node2D:
	var ground := Node2D.new()
	ground.set_script(GROUND_ITEM)
	ground.item = item
	ground.origin = origin
	ground.landing = landing_spot(origin, parent)
	parent.add_child(ground)
	return ground


# A spot near the origin, inside the walkable map, away from other drops where
# possible. A crowded spot widens the search, up to twice the scatter.
static func landing_spot(origin: Vector2, parent: Node) -> Vector2:
	var taken: Array = parent.get_tree().get_nodes_in_group("ground_items").filter(func(node: Node2D) -> bool: return not node.is_queued_for_deletion()).map(func(node: Node2D) -> Vector2: return node.landing)
	var best := origin
	var best_gap := -1.0
	for attempt in range(ATTEMPTS):
		var reach := SCATTER * (1.0 + float(attempt) / ATTEMPTS)
		var spot := (origin + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.3, 1.0) * reach).clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
		var gap := INF
		for other: Vector2 in taken:
			gap = minf(gap, spot.distance_to(other))
		if gap >= SPACING:
			return spot
		if gap > best_gap:
			best = spot
			best_gap = gap
	return best

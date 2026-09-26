extends SceneTree

var scene: Node
var player
var timed_out := false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Wizard")
	# The wizard stands still unless a check moves it.
	player.set_physics_process(false)
	var hud = scene.get_node("HUD")
	assert(player.health == player.MAX_HEALTH and hud.health == player.MAX_HEALTH)

	# Enemies wait at the north edge until the wizard comes near.
	var starts := {}
	for enemy in get_nodes_in_group("enemies"):
		starts[enemy] = enemy.position
	for frame in range(30):
		await physics_frame
	for enemy in starts:
		assert(enemy.position == starts[enemy] and not enemy.aggro, "Enemies idle beyond aggro range")
		enemy.queue_free()
	await process_frame

	# A skitter notices, chases, and claws when in reach.
	var skitter = spawn("skitter", Vector2(150, 0))
	var chased := false
	for frame in range(240):
		await physics_frame
		chased = chased or skitter.sprite.animation == &"move_west"
		if skitter.attacking:
			break
	assert(chased and skitter.aggro, "Skitter chases the wizard")
	assert(skitter.attacking and skitter.sprite.animation == &"attack_west")
	assert(player.global_position.distance_to(skitter.global_position) <= skitter.stats.reach + skitter.REACH_SLACK)
	await wait_until(func() -> bool: return skitter.attack_landed)
	assert(player.health == player.MAX_HEALTH - 1, "A landed claw deals 1")
	assert(hud.health == player.health, "The health bar follows")
	assert(player.hurting and player.sprite.animation == &"hurt_south", "The wizard flinches")
	await wait_until(func() -> bool: return not player.hurting)
	assert(player.sprite.animation == &"hurt_south" or not player.sprite.is_playing())

	# Stepping out of reach during the windup makes the blow miss.
	await wait_until(func() -> bool: return skitter.attacking)
	var before: int = player.health
	player.position += Vector2(-120, 0)
	await wait_until(func() -> bool: return not skitter.attacking)
	assert(player.health == before, "A blow misses a wizard who left its reach")

	# Hitting an enemy mid-windup cancels its attack.
	await wait_until(func() -> bool: return skitter.attacking)
	skitter.take_damage(1)
	assert(not skitter.attacking and skitter.hurting)
	skitter.queue_free()
	await process_frame

	# A sentinel's punch deals 2.
	player.position = Vector2(800, 480)
	var sentinel = spawn("sentinel", Vector2(0, 40))
	before = player.health
	await wait_until(func() -> bool: return sentinel.attack_landed, 600)
	assert(player.health == before - 2, "A sentinel punch deals 2")
	sentinel.queue_free()
	await process_frame

	# A scholar keeps its distance and throws bolts.
	var scholar = spawn("scholar", Vector2(0, -160))
	before = player.health
	await wait_until(func() -> bool: return scholar.attack_landed)
	assert(scholar.sprite.animation == &"cast_south")
	assert(get_nodes_in_group("hostile_projectiles").size() == 1, "The cast throws a bolt")
	await wait_until(func() -> bool: return get_nodes_in_group("hostile_projectiles").is_empty())
	assert(player.health == before - 1, "The bolt hits for 1")
	# A bolt can be sidestepped.
	await wait_until(func() -> bool: return scholar.attack_landed and scholar.attacking, 600)
	before = player.health
	var dodged_bolt = get_nodes_in_group("hostile_projectiles")[0]
	player.position += Vector2(80, 0)
	# Only this bolt counts; the scholar may throw another before it expires.
	await wait_until(func() -> bool: return not is_instance_valid(dodged_bolt) or dodged_bolt.global_position.y > player.global_position.y + 40, 600)
	assert(player.health == before, "A sidestepped bolt misses")
	# Casters back away from a wizard who closes in.
	await wait_until(func() -> bool: return not scholar.attacking)
	player.position = scholar.position + Vector2(0, 50)
	for frame in range(30):
		await physics_frame
	assert(player.global_position.distance_to(scholar.global_position) > 55, "The scholar retreats")
	scholar.queue_free()
	await process_frame

	# Shooting a distant enemy wakes it.
	player.position = Vector2(800, 480)
	var far = spawn("skitter", Vector2(-400, 0))
	await physics_step()
	assert(not far.aggro)
	far.take_damage(1)
	assert(far.aggro)
	await wait_until(func() -> bool: return not far.hurting)
	var gap: float = player.global_position.distance_to(far.global_position)
	for frame in range(20):
		await physics_frame
	assert(player.global_position.distance_to(far.global_position) < gap, "A shot enemy closes in")

	# At zero health the wizard falls and the game waits for a restart.
	player.take_damage(player.health)
	assert(player.dead and player.health == 0 and player.sprite.animation == &"death_" + player.facing)
	assert(hud.fallen.visible and hud.health == 0)
	assert(not player.dodge() and player.shoot_at(player.global_position + Vector2(50, 0)) == null)
	player.take_damage(1)
	assert(player.health == 0)
	await wait_until(func() -> bool: return not far.attacking and not far.hurting)
	var resting: Vector2 = far.position
	for frame in range(90):
		await physics_frame
	assert(not far.attacking and far.position == resting, "Enemies stand down once the wizard falls")
	assert(InputMap.action_get_events("restart")[0].physical_keycode == KEY_R)
	assert(not timed_out, "Every wait must finish in time")
	print("PASS: enemies idle until near; chase; melee lands on the hit frame and misses if you step away; hits cancel attacks; sentinel deals 2; scholar casts dodgeable bolts and backs off; shots wake enemies; wizard hurt, health bar, death, restart prompt")
	scene.queue_free()
	quit()


func spawn(kind: String, offset: Vector2) -> Node:
	var enemy = load("res://enemy.tscn").instantiate()
	enemy.kind = kind
	enemy.position = player.position + offset
	scene.add_child(enemy)
	return enemy


func wait_until(condition: Callable, max_frames := 300) -> void:
	for frame in range(max_frames):
		if condition.call():
			return
		await physics_frame
	timed_out = timed_out or not condition.call()
	assert(not timed_out, "Timed out waiting")


func physics_step() -> void:
	await physics_frame
	await physics_frame

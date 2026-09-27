extends Node2D

signal health_changed(health: float, max_health: float)
signal mana_changed(mana: float, max_mana: float)
signal died

const SPEED := 110.0
const PROJECTILE_SCRIPT := preload("res://projectile.gd")
const STATS := preload("res://stats.gd")
# The bolt: mana per cast, damage range before modifiers, and the time between casts before cast speed.
const BOLT_MANA_COST := 5.0
const BOLT_DAMAGE := Vector2(8.0, 12.0)
const BASE_CAST_TIME := 0.25
const FROST_NOVA_SCRIPT := preload("res://frost_nova.gd")
# Frost Nova: a short-range burst of cold around the wizard that chills what it hits.
const NOVA_MANA_COST := 12.0
const NOVA_DAMAGE := Vector2(12.0, 18.0)
const NOVA_CAST_TIME := 0.45
const NOVA_CHILL_TIME := 2.0
const WORLD := preload("res://world.gd")
const ANIMATIONS := preload("res://animation_library.gd")
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
# Where the staff's orb sits in each facing, relative to the sprite centre; bolts launch from it.
const STAFF_TIPS := {
	"east": Vector2(7, -18), "south-east": Vector2(-9, -17), "south": Vector2(-21, -20), "south-west": Vector2(-19, -22),
	"west": Vector2(-9, -24), "north-west": Vector2(8, -24), "north": Vector2(20, -22), "north-east": Vector2(20, -19),
}
const ANIMATION_SPEEDS := {"idle": 1.1, "move": 16.0, "cast": 14.0, "dodge": 20.0, "hurt": 12.0, "death": 8.0}
const DODGE_SPEED := 340.0
const DODGE_TIME := 0.2
const DODGE_COOLDOWN := 0.5
const AFTERIMAGE_INTERVAL := 0.04
const AFTERIMAGE_FADE := 0.25
# How close the wizard must be to pick an item up; clicking one farther away walks over first.
const PICKUP_RANGE := 40.0
const LOOT := preload("res://loot.gd")

var facing := "south"
var casting := false
var hurting := false
var stats := STATS.compute([])
var max_health: float = stats.max_life
var health: float = max_health
var max_mana: float = stats.max_mana
var mana: float = max_mana
var cast_ready_in := 0.0
var dead := false
var rng := RandomNumberGenerator.new()
var dodge_direction := Vector2.ZERO
var dodge_time_left := 0.0
var dodge_cooldown_left := 0.0
var afterimage_time_left := 0.0
# A ground item being walked to; movement keys or a dodge cancel the walk.
var pickup_target: Node2D = null
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = ANIMATIONS.build("res://assets/wizard", DIRECTIONS, ANIMATION_SPEEDS, ["cast", "dodge", "hurt", "death"])
	sprite.animation_finished.connect(_on_animation_finished)
	Inventory.changed.connect(refresh_stats)
	refresh_stats()
	health = max_health
	mana = max_mana
	_play("idle")


# Re-reads equipped gear. Current life and mana keep their values, capped to the new maximums.
func refresh_stats() -> void:
	stats = STATS.compute(Inventory.equipped_items())
	max_health = stats.max_life
	max_mana = stats.max_mana
	health = minf(health, max_health)
	mana = minf(mana, max_mana)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_regenerate(delta)
	cast_ready_in = maxf(0.0, cast_ready_in - delta)
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	if is_dodging():
		_dodge_step(delta)
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement != Vector2.ZERO or not is_instance_valid(pickup_target):
		pickup_target = null
	else:
		movement = _walk_to_pickup()
	position += movement * SPEED * delta
	position = position.clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
	# A cast or a flinch finishes before walking resumes; movement continues underneath.
	if casting or hurting:
		return
	if movement != Vector2.ZERO:
		var direction_index := posmod(roundi(movement.angle() / (PI / 4.0)), 8)
		facing = DIRECTIONS[direction_index]
		_play("move")
	else:
		_play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		if event.is_action_pressed("restart", false, true):
			# Mark handled first: once reloading, this node has no viewport.
			get_viewport().set_input_as_handled()
			get_tree().reload_current_scene()
		return
	if event.is_action_pressed("dodge", false, true):
		dodge()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Clicking the world with an item on the cursor drops it at the wizard's feet instead of casting.
		if Inventory.held != null:
			drop_held_item()
		elif not is_dodging():
			shoot_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if Inventory.held == null and not is_dodging():
			cast_nova(get_global_mouse_position())
		get_viewport().set_input_as_handled()


# Casts a bolt toward the target, if the last cast has finished and there is mana for it.
func shoot_at(target: Vector2) -> Node2D:
	var aim := target - global_position
	if aim.is_zero_approx() or not _begin_cast(BOLT_MANA_COST, BASE_CAST_TIME, aim):
		return null
	var tip: Vector2 = global_position + STAFF_TIPS[facing]
	# Aim from the tip so the bolt still flies through the clicked point.
	var flight := target - tip
	var projectile := Node2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.direction = flight.normalized() if not flight.is_zero_approx() else aim.normalized()
	projectile.speed = projectile.SPEED * (1.0 + stats.projectile_speed / 100.0)
	projectile.damage = rng.randf_range(BOLT_DAMAGE.x, BOLT_DAMAGE.y) * (1.0 + stats.spell_damage / 100.0)
	projectile.critical = rng.randf() * 100.0 < stats.crit_chance
	if projectile.critical:
		projectile.damage *= STATS.CRIT_MULTIPLIER
	get_parent().add_child(projectile)
	projectile.global_position = tip
	# The first hit check sweeps from the body, so an enemy between the wizard and the tip is still hit.
	projectile.sweep_from = global_position
	return projectile


# Casts Frost Nova around the wizard, turning toward the cursor for the cast.
func cast_nova(toward: Vector2) -> Node2D:
	if not _begin_cast(NOVA_MANA_COST, NOVA_CAST_TIME, toward - global_position):
		return null
	var nova := Node2D.new()
	nova.set_script(FROST_NOVA_SCRIPT)
	nova.damage_range = NOVA_DAMAGE
	nova.damage_scale = 1.0 + stats.spell_damage / 100.0
	nova.crit_chance = stats.crit_chance
	nova.crit_multiplier = STATS.CRIT_MULTIPLIER
	nova.chill_time = NOVA_CHILL_TIME
	nova.rng = rng
	nova.position = position
	get_parent().add_child(nova)
	return nova


# Starts a spell if the last cast has finished and there is mana: spends it,
# sets the wait before the next cast (shortened by cast speed), and plays the cast.
func _begin_cast(mana_cost: float, cast_time: float, aim: Vector2) -> bool:
	if dead or cast_ready_in > 0.0 or mana < mana_cost:
		return false
	mana -= mana_cost
	mana_changed.emit(mana, max_mana)
	var cast_rate: float = 1.0 + stats.cast_speed / 100.0
	cast_ready_in = cast_time / cast_rate
	if not aim.is_zero_approx():
		facing = DIRECTIONS[posmod(roundi(aim.angle() / (PI / 4.0)), 8)]
	casting = true
	hurting = false
	_play("cast")
	# Faster casting plays the cast animation faster too.
	sprite.speed_scale = cast_rate
	sprite.set_frame_and_progress(0, 0.0)
	return true


# Takes a hit of a damage type; armour reduces physical hits, resistances the elements.
func take_damage(amount: float, damage_type := "physical") -> void:
	if dead or amount <= 0.0:
		return
	health = maxf(0.0, health - STATS.mitigate(amount, damage_type, stats))
	health_changed.emit(health, max_health)
	casting = false
	if health <= 0.0:
		dead = true
		hurting = false
		dodge_time_left = 0.0
		_play("death")
		died.emit()
		return
	# A dash keeps its own animation; the hit still counts.
	if is_dodging():
		return
	hurting = true
	_play("hurt")
	sprite.set_frame_and_progress(0, 0.0)


func _on_animation_finished() -> void:
	if not dead:
		casting = false
		hurting = false


func _regenerate(delta: float) -> void:
	if health < max_health and stats.life_regen > 0.0:
		health = minf(max_health, health + stats.life_regen * delta)
		health_changed.emit(health, max_health)
	if mana < max_mana:
		mana = minf(max_mana, mana + stats.mana_regen * delta)
		mana_changed.emit(mana, max_mana)


# Picks the item up now if it is in reach; otherwise walks to it first.
func walk_to_pick_up(ground_item: Node2D) -> void:
	if dead:
		return
	if global_position.distance_to(ground_item.global_position) <= PICKUP_RANGE:
		pickup_target = null
		ground_item.pick_up()
	else:
		pickup_target = ground_item


# The movement toward the item being walked to, picking it up on arrival.
func _walk_to_pickup() -> Vector2:
	var offset := pickup_target.global_position - global_position
	if offset.length() <= PICKUP_RANGE:
		var target := pickup_target
		pickup_target = null
		target.pick_up()
		return Vector2.ZERO
	return offset.normalized()


func drop_held_item() -> void:
	LOOT.spawn(Inventory.take_held(), global_position, get_parent())


func is_dodging() -> bool:
	return dodge_time_left > 0.0


# Dashes toward the held movement keys, or the facing when standing still.
func dodge() -> bool:
	if dead or is_dodging() or dodge_cooldown_left > 0.0:
		return false
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(DIRECTIONS.find(facing) * PI / 4.0)
	dodge_direction = direction.normalized()
	facing = DIRECTIONS[posmod(roundi(dodge_direction.angle() / (PI / 4.0)), 8)]
	dodge_time_left = DODGE_TIME
	dodge_cooldown_left = DODGE_TIME + DODGE_COOLDOWN
	afterimage_time_left = 0.0
	pickup_target = null
	casting = false
	hurting = false
	_play("dodge")
	sprite.set_frame_and_progress(0, 0.0)
	return true


func _dodge_step(delta: float) -> void:
	var step := minf(delta, dodge_time_left)
	dodge_time_left -= step
	if is_zero_approx(dodge_time_left):
		dodge_time_left = 0.0
	position += dodge_direction * DODGE_SPEED * step
	position = position.clamp(WORLD.WALK_BOUNDS.position, WORLD.WALK_BOUNDS.end)
	afterimage_time_left -= step
	if afterimage_time_left <= 0.0:
		afterimage_time_left = AFTERIMAGE_INTERVAL
		_spawn_afterimage()


# A fading, tinted copy of the current frame left behind along the dash.
func _spawn_afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.texture_filter = sprite.texture_filter
	ghost.modulate = Color(0.55, 0.8, 1.0, 0.55)
	# Just before the wizard in the tree: above the ground, beneath the wizard.
	get_parent().add_child(ghost)
	get_parent().move_child(ghost, get_index())
	ghost.global_position = sprite.global_position
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, AFTERIMAGE_FADE)
	fade.tween_callback(ghost.queue_free)


func _play(action: String) -> void:
	var animation := "%s_%s" % [action, facing]
	if sprite.sprite_frames.has_animation(animation):
		if action != "cast":
			sprite.speed_scale = 1.0
		sprite.play(animation)

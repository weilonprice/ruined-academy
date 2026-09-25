extends Area2D

const MAX_HEALTH := 3
var health := MAX_HEALTH
var hit_flash: Tween


func _ready() -> void:
	add_to_group("enemies")


func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	if health == 0:
		collision_layer = 0
		queue_free()
		return
	if hit_flash:
		hit_flash.kill()
	$Sprite.self_modulate = Color(1.8, 1.3, 1.3)
	hit_flash = create_tween()
	hit_flash.tween_property($Sprite, "self_modulate", Color.WHITE, 0.12)
	queue_redraw()


func _draw() -> void:
	if health < MAX_HEALTH:
		draw_rect(Rect2(-16, -35, 32, 4), Color("181c24"))
		draw_rect(Rect2(-15, -34, 30.0 * health / MAX_HEALTH, 2), Color("d66765"))

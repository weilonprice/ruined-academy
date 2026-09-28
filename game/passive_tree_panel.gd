extends Control

# The passive tree (P). Click a node to allocate it, right-click to refund it.
# A node's rim shows its state: gold when allocated, pulsing when it can be
# taken, grey when locked. The strip at the bottom describes the hovered node.

const PASSIVES := preload("res://passives.gd")
const PANEL := Vector2(360, 240)
# Where START_POSITION's origin sits inside the panel.
const TREE_ORIGIN := Vector2(180, 108)
const NODE_RADIUS := 14.0
const START_RADIUS := 8.0
const BACKGROUND := Color("15181f")
const BORDER := Color("5a4a33")
const GOLD := Color("f2c14e")
const OPEN := Color("9fe8ff")
const LOCKED := Color("4a4f5a")
const LINK_DIM := Color("2b303b")
const TEXT := Color("d8d8d8")
const MUTED := Color("8a8f99")
# Generated art for a node lives at ICON_ROOT/<id>.png; nodes without one draw a simple symbol.
const ICON_ROOT := "res://assets/passives/"
const ICON_COLORS := {"heart": Color("d66765"), "droplet": Color("5b7fd6"), "burst": Color("e78a3b"),
	"snowflake": Color("9fe8ff"), "eye": Color("e8e0a0")}

var font := ThemeDB.fallback_font
var pulse := 0.0


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	Character.changed.connect(queue_redraw)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("passive_tree", false, true) or (visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"))):
		visible = not visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if visible:
		pulse += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var id := node_at(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT and id != "":
			Character.allocate(id)
		elif event.button_index == MOUSE_BUTTON_RIGHT and id != "":
			Character.refund(id)
		accept_event()


func panel_rect() -> Rect2:
	return Rect2((size - PANEL) / 2.0, PANEL)


func node_center(id: String) -> Vector2:
	return panel_rect().position + TREE_ORIGIN + PASSIVES.position_of(id)


# The node under a point in this control, or "".
func node_at(at: Vector2) -> String:
	for id in PASSIVES.NODES:
		if node_center(id).distance_to(at) <= NODE_RADIUS + 2.0:
			return id
	return ""


func _draw() -> void:
	var panel := panel_rect()
	draw_rect(panel, BACKGROUND)
	draw_rect(panel, BORDER, false, 1.0)
	draw_string(font, panel.position + Vector2(10, 18), "Passive Tree", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	var points: int = Character.points_available()
	draw_string(font, panel.position + Vector2(10, 18), "%d point%s to spend" % [points, "" if points == 1 else "s"], HORIZONTAL_ALIGNMENT_RIGHT, PANEL.x - 20, 10, GOLD if points > 0 else MUTED)
	for link in PASSIVES.LINKS:
		var lit: bool = (link[0] == PASSIVES.START or link[0] in Character.passives) and link[1] in Character.passives
		draw_line(node_center(link[0]), node_center(link[1]), GOLD if lit else LINK_DIM, 2.0 if lit else 1.0)
	draw_circle(node_center(PASSIVES.START), START_RADIUS, GOLD)
	draw_circle(node_center(PASSIVES.START), START_RADIUS - 3.0, BACKGROUND)
	var hovered := node_at(get_local_mouse_position())
	for id in PASSIVES.NODES:
		_draw_node(id, id == hovered)
	_draw_info(hovered)


func _draw_node(id: String, hovered: bool) -> void:
	var center := node_center(id)
	var allocated: bool = id in Character.passives
	var rim := LOCKED
	if allocated:
		rim = GOLD
	elif Character.can_allocate(id):
		rim = OPEN.lerp(Color.WHITE, 0.5 + 0.5 * sin(pulse * 5.0))
	draw_circle(center, NODE_RADIUS, Color("0d0f14"))
	draw_arc(center, NODE_RADIUS, 0.0, TAU, 32, rim, 3.0 if hovered else 2.0)
	var icon_path := ICON_ROOT + id + ".png"
	if ResourceLoader.exists(icon_path):
		var texture: Texture2D = load(icon_path)
		draw_texture(texture, (center - texture.get_size() / 2.0).round(), Color.WHITE if allocated else Color(0.5, 0.5, 0.55))
		return
	var color: Color = ICON_COLORS[PASSIVES.NODES[id].icon]
	if not allocated:
		color = color.darkened(0.45)
	call("_icon_" + PASSIVES.NODES[id].icon, center, color)


func _draw_info(id: String) -> void:
	var panel := panel_rect()
	var top := panel.position.y + PANEL.y - 58.0
	draw_line(Vector2(panel.position.x + 8, top), Vector2(panel.end.x - 8, top), LINK_DIM)
	if id == "":
		draw_string(font, Vector2(panel.position.x + 10, top + 16), "Hover a passive to see what it grants.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
		return
	var node: Dictionary = PASSIVES.NODES[id]
	draw_string(font, Vector2(panel.position.x + 10, top + 15), node.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD)
	for index in range(node.text.size()):
		draw_string(font, Vector2(panel.position.x + 10, top + 28 + index * 11), node.text[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8888ff"))
	draw_string(font, Vector2(panel.position.x + 10, top + 15), hint(id), HORIZONTAL_ALIGNMENT_RIGHT, PANEL.x - 20, 10, MUTED)


# What clicking the node would do, or why it can't.
func hint(id: String) -> String:
	if id in Character.passives:
		return "Right-click to refund" if Character.can_refund(id) else "Other passives depend on this"
	if Character.can_allocate(id):
		return "Click to allocate"
	if Character.points_available() <= 0:
		return "No points: gain a level"
	return "Allocate a linked passive first"


func _icon_heart(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(-3, -2), 4.0, color)
	draw_circle(center + Vector2(3, -2), 4.0, color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-7, -1), center + Vector2(7, -1), center + Vector2(0, 7)]), color)


func _icon_droplet(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0, 2), 5.0, color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-5, 1), center + Vector2(0, -8), center + Vector2(5, 1)]), color)


func _icon_burst(center: Vector2, color: Color) -> void:
	for index in range(8):
		var out := Vector2.from_angle(TAU * index / 8.0)
		draw_line(center + out * 2.0, center + out * (8.0 if index % 2 == 0 else 5.0), color, 2.0)
	draw_circle(center, 3.0, color)


func _icon_snowflake(center: Vector2, color: Color) -> void:
	for index in range(3):
		var out := Vector2.from_angle(PI * index / 3.0 + PI / 2.0) * 8.0
		draw_line(center - out, center + out, color, 2.0)
	draw_circle(center, 2.0, color)


func _icon_eye(center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-8, 0), center + Vector2(0, -5), center + Vector2(8, 0), center + Vector2(0, 5)]), color)
	draw_circle(center, 3.0, Color("0d0f14"))
	draw_circle(center, 1.5, color)

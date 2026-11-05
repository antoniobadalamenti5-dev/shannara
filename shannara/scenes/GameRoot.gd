# GameRoot - scena principale
# Mostra SOLO la mappa, niente player né nemici
extends Node2D

const TILE_SIZE: int = 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 20

const COLOR_FLOOR := Color(0.20, 0.24, 0.20)
const COLOR_WALL := Color(0.45, 0.38, 0.30)
const COLOR_BRIDGE := Color(0.55, 0.45, 0.25)
const COLOR_SPIKE := Color(0.55, 0.20, 0.20)
const COLOR_GRID_LINE := Color(0, 0, 0, 0.25)
const COLOR_ELEV_UP := Color(0.30, 0.45, 0.30)
const COLOR_ELEV_DOWN := Color(0.15, 0.18, 0.30)

var _turn_label: Label

func _ready() -> void:
	print("[GameRoot] pronto - tiles %dx%d" % [GRID_WIDTH, GRID_HEIGHT])
	_add_turn_label()
	_add_camera()

func _add_turn_label() -> void:
	# CanvasLayer = coordinate schermo, non di mondo: la Label resta visibile
	# qualunque sia la posizione/zoom della Camera2D.
	var layer := CanvasLayer.new()
	layer.name = "UILayer"
	layer.layer = 10
	add_child(layer)
	_turn_label = Label.new()
	_turn_label.name = "TurnLabel"
	_turn_label.text = "Turno: 0"
	_turn_label.position = Vector2(8, 8)
	_turn_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_turn_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_turn_label.add_theme_constant_override("outline_size", 4)
	_turn_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(_turn_label)

func _add_camera() -> void:
	var cam = $Camera2D if has_node("Camera2D") else null
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		add_child(cam)
	cam.position = Vector2(GRID_WIDTH * TILE_SIZE / 2.0, GRID_HEIGHT * TILE_SIZE / 2.0)
	cam.zoom = Vector2(1.2, 1.2)
	cam.make_current()

func _draw() -> void:
	var gs = GridSystem
	if gs == null:
		return
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			_draw_cell(gs, x, y)

func _draw_cell(gs, x: int, y: int) -> void:
	var cell = gs.get_cell_at(x, y, 0)
	if cell == null:
		return
	var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), _cell_color(cell), true)
	draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_GRID_LINE, false, 1.0)

func _cell_color(cell) -> Color:
	match cell.terrain_type:
		3: return COLOR_WALL
		2: return COLOR_SPIKE
		1: return COLOR_BRIDGE
		_:
			if cell.elevation > 0: return COLOR_ELEV_UP
			elif cell.elevation < 0: return COLOR_ELEV_DOWN
			return COLOR_FLOOR

func _process(_delta: float) -> void:
	queue_redraw()
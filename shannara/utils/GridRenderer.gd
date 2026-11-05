# GridRenderer - disegna la griglia 20x20 del bioma corrente
# Legge le celle da GridSystem e le rende come quadrati colorati

extends Node2D

const TILE_SIZE: int = 32
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 20

const COLOR_FLOOR := Color(0.20, 0.24, 0.20)
const COLOR_WALL := Color(0.45, 0.38, 0.30)
const COLOR_BRIDGE := Color(0.55, 0.45, 0.25)
const COLOR_SPIKE := Color(0.55, 0.20, 0.20)
const COLOR_GRID_LINE := Color(0, 0, 0, 0.25)
const COLOR_ELEV_UP := Color(0.30, 0.45, 0.30)
const COLOR_ELEV_DOWN := Color(0.15, 0.18, 0.30)
const COLOR_PLAYER := Color(0.0, 0.8, 1.0, 0.9)
const COLOR_HIGHLIGHT := Color(1.0, 1.0, 0.0, 0.5)

@export var player_node: Node2D = null
@export var show_actors: bool = true

func _ready() -> void:
	print("[GridRenderer] _ready() chiamato, z_index=", z_index)

func _draw() -> void:
	var gs = get_node_or_null("/root/GridSystem")
	if gs == null:
		push_warning("[GridRenderer] GridSystem non trovato")
		return

	for y in range(gs.GRID_HEIGHT):
		for x in range(gs.GRID_WIDTH):
			_draw_cell(gs, x, y)

	# Disegna outline della griglia
	_draw_grid_outline(gs)

	# Evidenzia cella iniziale player
	_highlight_cell(5, 5)

func _draw_cell(gs, x: int, y: int) -> void:
	var cell = gs.get_cell_at(x, y, 0)
	if cell == null:
		return

	var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	var rect := Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE))
	draw_rect(rect, _cell_color(cell), true)
	draw_rect(rect, COLOR_GRID_LINE, false, 1.0)

func _draw_grid_outline(gs) -> void:
	# Outline perimetrale (bianco)
	var line_color = Color(1, 1, 1, 0.8)
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, GRID_HEIGHT * TILE_SIZE), line_color, 1)
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * TILE_SIZE), Vector2(GRID_WIDTH * TILE_SIZE, y * TILE_SIZE), line_color, 1)

func _highlight_cell(x: int, y: int) -> void:
	# Evidenzia la cella di partenza con un contorno giallo
	var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	var rect := Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE))
	draw_rect(rect, COLOR_HIGHLIGHT, false, 2.0)

func _cell_color(cell) -> Color:
	match cell.terrain_type:
		GridCell.TERRAIN_WALL:
			return COLOR_WALL
		GridCell.TERRAIN_BRIDGE:
			return COLOR_BRIDGE
		GridCell.TERRAIN_SPIKE:
			return COLOR_SPIKE
		_:
			if cell.elevation > 0:
				return COLOR_ELEV_UP
			elif cell.elevation < 0:
				return COLOR_ELEV_DOWN
			return COLOR_FLOOR

func _process(_delta: float) -> void:
	queue_redraw()

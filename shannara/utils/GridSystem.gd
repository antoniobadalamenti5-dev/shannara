# GridSystem singleton for 3D coordinate management
# Manages the dungeon grid with elevation levels

class_name GridSystem
extends Node

signal move_requested(cell_x, cell_y, elevation_from, elevation_to)
signal attack_requested(attacker_x, attacker_y, target_x, target_y)

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 20
const MAX_ELEVATION: int = 2

var grid: Array = []  # [y][x][elevation] -> GridCell

func _ready() -> void:
	_initialize_grid()

func _initialize_grid() -> void:
	for y in range(GRID_HEIGHT):
		var row := []
		for x in range(GRID_WIDTH):
			var elevation_row := []
			for z in range(MAX_ELEVATION + 1):  # 0, 1, 2
				var cell := GridCell.new()
				cell.x = x
				cell.y = y
				cell.elevation = z - 1  # -1, 0, 1
				elevation_row.append(cell)
			row.append(elevation_row)
		grid.append(row)

func get_cell_at(x: int, y: int, elevation: int) -> GridCell:
	if x < 0 or y < 0 or x >= GRID_WIDTH or y >= GRID_HEIGHT:
		return null
	if elevation < -1 or elevation > 1:
		return null
	return grid[y][x][elevation + 1]  # offset for -1 base

func is_cell_walkable(x: int, y: int, elevation: int) -> bool:
	var cell := get_cell_at(x, y, elevation)
	if cell == null:
		return false
	return cell.walkable and cell.occupant == null

func set_occupant(x: int, y: int, elevation: int, occupant: Node) -> void:
	var cell := get_cell_at(x, y, elevation)
	if cell != null:
		cell.occupant = occupant

func place_terrain(x: int, y: int, elevation: int, terrain_type: int) -> void:
	var cell := get_cell_at(x, y, elevation)
	if cell != null:
		cell.terrain_type = terrain_type
		if terrain_type == TerrainType.WALL:
			cell.walkable = false

func can_move_to(from_x: int, from_y: int, from_elev: int, to_x: int, to_y: int, to_elev: int) -> bool:
	if not is_cell_walkable(to_x, to_y, to_elev):
		return false
	# Check elevation transition rules
	if from_elev != to_elev:
		# Can only change elevation at stairs/bridge cells
		return true
	return true
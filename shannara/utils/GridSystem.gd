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

func get_neighbors(x: int, y: int, elevation: int) -> Array:
	"""Returns list of walkable neighboring cells [x, y, elevation] format"""
	var neighbors := []
	# 4-directional movement
	var directions := [
		Vector2i(0, -1),  # up
		Vector2i(0, 1),   # down
		Vector2i(-1, 0),  # left
		Vector2i(1, 0)    # right
	]

	for dir in directions:
		var nx := x + dir.x
		var ny := y + dir.y
		if is_cell_walkable(nx, ny, elevation):
			neighbors.append([nx, ny, elevation])
		# Check elevation transitions (stairs/bridges)
		if is_cell_walkable(nx, ny, elevation + 1):
			neighbors.append([nx, ny, elevation + 1])
		if is_cell_walkable(nx, ny, elevation - 1):
			neighbors.append([nx, ny, elevation - 1])

	return neighbors

func find_path(start_x: int, start_y: int, start_elev: int, target_x: int, target_y: int, target_elev: int) -> Array:
	"""Simple A* pathfinding on grid with elevation support. Returns array of [x, y, elevation] positions or empty if no path"""
	if not is_cell_walkable(target_x, target_y, target_elev):
		return []

	var open_set := []
	var closed_set := {}
	var came_from := {}

	var start_hash := "%d,%d,%d" % [start_x, start_y, start_elev]
	open_set.append([0, start_x, start_y, start_elev])
	came_from[start_hash] = null

	while open_set.size() > 0:
		open_set.sort()
		var current := open_set.pop_front()
		var current_f := current[0]
		var current_x := current[1]
		var current_y := current[2]
		var current_elev := current[3]

		var current_key := "%d,%d,%d" % [current_x, current_y, current_elev]

		if current_x == target_x and current_y == target_y and current_elev == target_elev:
			# Reconstruct path
			var path := []
			var key := current_key
			while key != null:
				var parts := key.split(",")
				path.push_front([int(parts[0]), int(parts[1]), int(parts[2])])
				key = came_from[key]
			return path

		closed_set[current_key] = true

		# Check neighbors
		var neighbors := get_neighbors(current_x, current_y, current_elev)
		for neighbor in neighbors:
			var nx := neighbor[0]
			var ny := neighbor[1]
			var ne := neighbor[2]
			var neighbor_key := "%d,%d,%d" % [nx, ny, ne]

			if closed_set.has(neighbor_key):
				continue

			var g_score := 0
			# Simple distance heuristic
			var g_cost := abs(nx - target_x) + abs(ny - target_y) + abs(ne - target_elev)
			var f_score := g_cost

			var in_open := false
			for i in open_set:
				if i[1] == nx and i[2] == ny and i[3] == ne:
					in_open = true
					if f_score < i[0]:
						i[0] = f_score
					break

			if not in_open:
				open_set.append([f_score, nx, ny, ne])
				came_from[neighbor_key] = current_key

	return []  # No path found
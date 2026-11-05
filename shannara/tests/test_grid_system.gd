# test_grid_system.gd - Unit tests for GridSystem singleton
# Tests grid initialization, cell access, walkability, pathfinding

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] GridSystem")

	# Get GridSystem instance (works in headless and scene mode)
	var grid_system = get_node("/root/GridSystem")

	# Test constants
	assert_eq(grid_system.GRID_WIDTH, 20, "GRID_WIDTH=20")
	assert_eq(grid_system.GRID_HEIGHT, 20, "GRID_HEIGHT=20")
	assert_eq(grid_system.MAX_ELEVATION, 2, "MAX_ELEVATION=2")

	# Test grid initialization
	var test_cell: GridCell = grid_system.get_cell_at(0, 0, 0)
	assert_not_null(test_cell, "get_cell_at(0,0,0) returns cell")
	assert_eq(test_cell.x, 0, "cell.x=0")
	assert_eq(test_cell.y, 0, "cell.y=0")
	assert_eq(test_cell.elevation, 0, "cell.elevation=0")

	# Test out of bounds
	assert_null(grid_system.get_cell_at(-1, 0, 0), "oob negative x returns null")
	assert_null(grid_system.get_cell_at(0, -1, 0), "oob negative y returns null")
	assert_null(grid_system.get_cell_at(20, 0, 0), "oob x>=GRID_WIDTH returns null")
	assert_null(grid_system.get_cell_at(0, 20, 0), "oob y>=GRID_HEIGHT returns null")

	# Test invalid elevation
	assert_null(grid_system.get_cell_at(0, 0, -2), "elevation<-1 returns null")
	assert_null(grid_system.get_cell_at(0, 0, 2), "elevation>1 returns null")

	# Test cell walkability
	assert_true(grid_system.is_cell_walkable(5, 5, 0), "center cell walkable")
	assert_false(grid_system.is_cell_walkable(0, 0, 0), "perimeter wall not walkable")

	# Test set_occupant
	var test_player: Player = Player.new()
	test_player.grid_x = 10
	test_player.grid_y = 10
	test_player.grid_elevation = 0
	grid_system.set_occupant(10, 10, 0, test_player)

	var occupied_cell: GridCell = grid_system.get_cell_at(10, 10, 0)
	assert_true(occupied_cell.occupant is Player, "occupant is Player")

	# Cella occupata non è calpestabile
	assert_false(grid_system.is_cell_walkable(10, 10, 0), "occupied cell not walkable")

	# Test clearing occupant
	grid_system.set_occupant(10, 10, 0, null)
	occupied_cell = grid_system.get_cell_at(10, 10, 0)
	assert_null(occupied_cell.occupant, "occupant cleared")

	test_player.free()

	# Test can_move_to
	assert_true(grid_system.can_move_to(5, 5, 0, 6, 5, 0), "can_move_to adjacent cell")
	assert_false(grid_system.can_move_to(5, 5, 0, 7, 5, 0), "can_move_to rejects 2-cell jump")
	assert_false(grid_system.can_move_to(5, 5, 0, 6, 6, 0), "can_move_to rejects diagonal")

	# Test get_neighbors
	var neighbors: Array = grid_system.get_neighbors(5, 5, 0)
	assert_gte(neighbors.size(), 4, "neighbors returns at least 4 directions")

	# Test find_path: start e target calpestabili, percorso minimo
	var path: Array = grid_system.find_path(2, 2, 0, 8, 2, 0)
	assert_true(path.size() > 0, "find_path returns path")
	if path.size() > 0:
		assert_eq(path[0], [2, 2, 0], "path starts at start")
		assert_eq(path[path.size() - 1], [8, 2, 0], "path ends at target")
		# Su griglia non pesata BFS dà il cammino minimo: 6 passi + il nodo di start
		assert_eq(path.size(), 7, "path is shortest (6 steps + start)")

		# Ogni passo del percorso deve essere una mossa legale
		var legal_steps := true
		for i in range(path.size() - 1):
			var a: Array = path[i]
			var b: Array = path[i + 1]
			if not grid_system.can_move_to(a[0], a[1], a[2], b[0], b[1], b[2]):
				legal_steps = false
				break
		assert_true(legal_steps, "every path step is a legal move")

	# Target fuori mappa -> []
	assert_eq(grid_system.find_path(2, 2, 0, 99, 99, 0).size(), 0, "find_path to oob target returns []")

	# Target muro: irraggiungibile -> []
	assert_eq(grid_system.find_path(2, 2, 0, 0, 0, 0).size(), 0, "find_path to wall returns []")

	print_results()

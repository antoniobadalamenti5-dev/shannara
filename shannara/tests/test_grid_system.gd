# Test per GridSystem
# Verifica gestione griglia 3D con coordinate e transizioni elevazione

func test_grid_system_initialization() -> void:
	assert_not_null(GridSystem, "GridSystem should be initialized")
	assert_gt(GridSystem.GRID_WIDTH, 0, "GRID_WIDTH should be positive")
	assert_gt(GridSystem.GRID_HEIGHT, 0, "GRID_HEIGHT should be positive")
	assert_eq(GridSystem.MAX_ELEVATION, 2, "MAX_ELEVATION should be 2")

func test_get_cell_at_valid() -> void:
	var cell := GridSystem.get_cell_at(0, 0, 0)
	assert_not_null(cell, "Should return cell at valid coordinates")
	assert_eq(cell.x, 0, "Cell x should be 0")
	assert_eq(cell.y, 0, "Cell y should be 0")
	assert_eq(cell.elevation, 0, "Cell at (0,0,0) should have elevation 0")

func test_get_cell_at_elevation_offsets() -> void:
	var cell_m1 := GridSystem.get_cell_at(5, 5, -1)
	var cell_0 := GridSystem.get_cell_at(5, 5, 0)
	var cell_1 := GridSystem.get_cell_at(5, 5, 1)

	assert_not_null(cell_m1, "Elevation -1 should be valid")
	assert_not_null(cell_0, "Elevation 0 should be valid")
	assert_not_null(cell_1, "Elevation 1 should be valid")
	assert_eq(cell_m1.elevation, -1)
	assert_eq(cell_0.elevation, 0)
	assert_eq(cell_1.elevation, 1)

func test_get_cell_at_out_of_bounds() -> void:
	var cell := GridSystem.get_cell_at(-1, 0, 0)
	assert_null(cell, "Should return null for negative x")

	cell = GridSystem.get_cell_at(0, -1, 0)
	assert_null(cell, "Should return null for negative y")

	cell = GridSystem.get_cell_at(GridSystem.GRID_WIDTH + 10, 0, 0)
	assert_null(cell, "Should return null for x beyond grid")

	cell = GridSystem.get_cell_at(0, GridSystem.GRID_HEIGHT + 10, 0)
	assert_null(cell, "Should return null for y beyond grid")

func test_is_cell_walkable_default() -> void:
	assert_true(GridSystem.is_cell_walkable(0, 0, 0), "Default cell (0,0,0) should be walkable")

func test_place_terrain_creates_wall() -> void:
	GridSystem.place_terrain(1, 1, 0, TerrainType.WALL)
	assert_false(GridSystem.is_cell_walkable(1, 1, 0), "WALL cell should not be walkable")

func test_set_occupant_and_clear() -> void:
	var actor := preload("res://actors/Player.gd").new()
	actor.name = "TestActor"

	GridSystem.set_occupant(10, 10, 0, actor)
	var cell := GridSystem.get_cell_at(10, 10, 0)
	assert_not_null(cell.occupant, "Occupant should be set")
	assert_eq(cell.occupant, actor, "Occupant should be the actor")

	GridSystem.set_occupant(10, 10, 0, null)
	cell = GridSystem.get_cell_at(10, 10, 0)
	assert_null(cell.occupant, "Occupant should be cleared")

func test_find_path_simple() -> void:
	var path := GridSystem.find_path(0, 0, 0, 5, 5, 0)
	assert_true(path.size() > 0, "Should find path from (0,0,0) to (5,5,0)")
	assert_eq(path[0][0], 0, "Path should start at x=0")
	assert_eq(path[0][1], 0, "Path should start at y=0")
	assert_eq(path[path.size()-1][0], 5, "Path should end at x=5")
	assert_eq(path[path.size()-1][1], 5, "Path should end at y=5")

func test_find_path_blocked() -> void:
	GridSystem.place_terrain(5, 5, 0, TerrainType.WALL)
	var path := GridSystem.find_path(0, 0, 0, 10, 10, 0)
	assert_true(path.size() == 0, "Should return empty path to blocked destination")

func test_get_neighbors_cardinal() -> void:
	var neighbors := GridSystem.get_neighbors(5, 5, 0)
	assert_eq(neighbors.size(), 4, "Should have 4 cardinal neighbors")

	var has_up := false
	var has_down := false
	var has_left := false
	var has_right := false

	for n in neighbors:
		if n[0] == 5 and n[1] == 4: has_up = true
		if n[0] == 5 and n[1] == 6: has_down = true
		if n[0] == 4 and n[1] == 5: has_left = true
		if n[0] == 6 and n[1] == 5: has_right = true

	assert_true(has_up, "Should have neighbor above")
	assert_true(has_down, "Should have neighbor below")
	assert_true(has_left, "Should have neighbor left")
	assert_true(has_right, "Should have neighbor right")

func test_elevation_transition_from_neighbor() -> void:
	# Stairs at (5,5,0) should allow elevation change
	var stairs_cell := GridSystem.get_cell_at(5, 5, 0)
	stairs_cell.terrain_type = TerrainType.BRIDGE  # Act as stairs

	var neighbors := GridSystem.get_neighbors(5, 5, 0)
	var has_elevation := false
	for n in neighbors:
		if n[2] != 0:  # different elevation
			has_elevation = true

	assert_true(has_elevation, "Should have elevation transition neighbors")
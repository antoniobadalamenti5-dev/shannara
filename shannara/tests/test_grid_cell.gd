# Test per GridCell e TerrainType
# Verifica creazione, tipi terreno e valori elevazione

func test_grid_cell_creation() -> void:
	var cell := GridCell.new()
	assert_not_null(cell, "GridCell should not be null")
	assert_eq(cell.x, 0, "Default x should be 0")
	assert_eq(cell.y, 0, "Default y should be 0")
	assert_eq(cell.elevation, 0, "Default elevation should be 0")
	assert_eq(cell.walkable, true, "Default walkable should be true")
	assert_is(cell.occupant, Null, "Default occupant should be null")

func test_terrain_type_enum_values() -> void:
	assert_eq(TerrainType.FLOOR, 0, "FLOOR should equal 0")
	assert_eq(TerrainType.BRIDGE, 1, "BRIDGE should equal 1")
	assert_eq(TerrainType.SPIKE, 2, "SPIKE should equal 2")
	assert_eq(TerrainType.WALL, 3, "WALL should equal 3")

func test_elevation_clamp() -> void:
	var cell := GridCell.new()
	# Test elevation clamping within valid range
	cell.elevation = -1  # fossato
	assert_eq(cell.elevation, -1, "Elevation -1 should be valid")
	cell.elevation = 0   # piano
	assert_eq(cell.elevation, 0, "Elevation 0 should be valid")
	cell.elevation = 1   # altezza
	assert_eq(cell.elevation, 1, "Elevation 1 should be valid")

func test_grid_cell_factory() -> void:
	var cell1 := GridCell.new().grid_cell_factory(5, 10, 0)
	assert_eq(cell1.x, 5, "Factory should set x")
	assert_eq(cell1.y, 10, "Factory should set y")
	assert_eq(cell1.elevation, 0, "Factory should set elevation")

	var cell2 := GridCell.new().grid_cell_factory(3, 7, 1)
	assert_eq(cell2.x, 3)
	assert_eq(cell2.y, 7)
	assert_eq(cell2.elevation, 1, "Factory should set elevation to 1")

	var cell3 := GridCell.new().grid_cell_factory(3, 7, 5)
	assert_eq(cell3.elevation, 1, "Factory should clamp elevation to 1")

func test_terrain_type_modification() -> void:
	var cell := GridCell.new()
	cell.terrain_type = TerrainType.WALL
	assert_eq(cell.terrain_type, TerrainType.WALL, "Should be able to set terrain type")

	cell.terrain_type = TerrainType.SPIKE
	assert_eq(cell.terrain_type, TerrainType.SPIKE, "Should update terrain type")
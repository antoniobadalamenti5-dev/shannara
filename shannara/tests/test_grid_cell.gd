# test_grid_cell.gd - Unit tests for GridCell resource
# Tests x, y, elevation, walkable, occupant, terrain_type properties

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] GridCell")

	# Test instantiation
	var cell: GridCell = GridCell.new()
	# Per le sottoclassi di Resource, get_class() restituisce la classe base
	# Usare 'is' per verificare il tipo runtime
	assert_true(cell is GridCell, "GridCell.new() is GridCell")

	# Test default values
	assert_eq(cell.x, 0, "default x=0")
	assert_eq(cell.y, 0, "default y=0")
	assert_eq(cell.elevation, 0, "default elevation=0")
	assert_true(cell.walkable, "default walkable=true")
	assert_null(cell.occupant, "default occupant=null")
	assert_eq(cell.terrain_type, 0, "default terrain_type=FLOOR")

	# Test x, y assignment
	cell.x = 5
	cell.y = 10
	assert_eq(cell.x, 5, "x=5")
	assert_eq(cell.y, 10, "y=10")

	# Test elevation assignment
	cell.elevation = 1
	assert_eq(cell.elevation, 1, "elevation=1")

	cell.elevation = -1
	assert_eq(cell.elevation, -1, "elevation=-1")

	# Test elevation clamp via factory function
	var factory_cell: GridCell = GridCell.new().grid_cell_factory(0, 0, 5)
	assert_eq(factory_cell.elevation, 1, "factory clamps elevation <= 1")

	factory_cell = GridCell.new().grid_cell_factory(0, 0, -5)
	assert_eq(factory_cell.elevation, -1, "factory clamps elevation >= -1")

	# Test walkable toggle
	cell.walkable = false
	assert_false(cell.walkable, "walkable=false")

	cell.walkable = true
	assert_true(cell.walkable, "walkable=true")

	# Test occupant assignment
	var mock_occupant: Node = Node.new()
	mock_occupant.name = "TestOccupant"
	cell.occupant = mock_occupant
	assert_true(cell.occupant is Node, "occupant is Node")
	assert_eq(cell.occupant.name, "TestOccupant", "occupant name")

	mock_occupant.queue_free()

	print_results()
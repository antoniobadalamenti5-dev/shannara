# Test Setup and Teardown
# Prepares test environment for all unit tests

func _ready() -> void:
	# Called before any test
	pass

func _exit_tree() -> void:
	# Called after all tests complete
	pass

func setup_each_test() -> void:
	# Reset state before each test
	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	TurnManager.turn_count = 0

	# Clear grid occupants
	for y in range(GridSystem.GRID_HEIGHT):
		for x in range(GridSystem.GRID_WIDTH):
			for z in range(-1, 2):
				GridSystem.set_occupant(x, y, z, null)

	# Reset terrain
	for y in range(GridSystem.GRID_HEIGHT):
		for x in range(GridSystem.GRID_WIDTH):
			for z in range(-1, 2):
				var cell := GridSystem.get_cell_at(x, y, z)
				if cell != null:
					cell.terrain_type = TerrainType.FLOOR
					cell.walkable = true
					cell.occupant = null
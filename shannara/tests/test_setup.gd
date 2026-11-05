# test_setup.gd - Test setup and environment verification
# Tests that all systems initialize correctly

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Setup")

	# Get instances
	var grid_system = get_node("/root/GridSystem")
	var turn_manager = get_node("/root/TurnManager")
	var combat_resolver = get_node("/root/CombatResolver")
	var biome_system = get_node("/root/BiomeSystem")
	var item_database = get_node("/root/ItemDatabase")
	var inventory_system = get_node("/root/InventorySystem")

	# Test singletons exist
	assert_not_null(grid_system, "GridSystem autoload")
	assert_not_null(turn_manager, "TurnManager autoload")
	assert_not_null(combat_resolver, "CombatResolver autoload")
	assert_not_null(biome_system, "BiomeSystem autoload")
	assert_not_null(item_database, "ItemDatabase autoload")
	assert_not_null(inventory_system, "InventorySystem autoload")

	# Test GridSystem initialized
	var cell = grid_system.get_cell_at(0, 0, 0)
	assert_not_null(cell, "GridSystem grid initialized")

	# Test TurnManager has player reference
	assert_not_null(turn_manager, "TurnManager exists")

	# Test ItemDatabase loaded
	var item = item_database.get_item("healing_potion")
	assert_not_null(item, "healing_potion in ItemDatabase")

	# Test enums exist
	assert_eq(grid_system.GRID_WIDTH, 20, "GRID_WIDTH constant")
	assert_eq(grid_system.GRID_HEIGHT, 20, "GRID_HEIGHT constant")

	print_results()
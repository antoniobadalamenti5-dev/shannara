# test_biome.gd - Unit tests for BiomeSystem
# Tests biome transitions, completion, terrain types

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] BiomeSystem")

	# Get BiomeSystem instance
	var biome_system = get_node("/root/BiomeSystem")

	# Reset state
	biome_system.current_biome = 0
	biome_system.completed_biomes.clear()

	# Test initial state
	assert_eq(biome_system.current_biome, 0, "starts FOREST (0)")
	assert_eq(biome_system.completed_biomes.size(), 0, "completed_biomes empty")

	# Test biome names
	assert_eq(biome_system.get_biome_name(0), "Foresta", "FOREST name")
	assert_eq(biome_system.get_biome_name(1), "Caverna", "CAVE name")
	assert_eq(biome_system.get_biome_name(2), "Deserto", "DESERT name")
	assert_eq(biome_system.get_biome_name(3), "Ghiacciaio", "ICE name")
	assert_eq(biome_system.get_biome_name(4), "Palude", "SWAMP name")
	assert_eq(biome_system.get_biome_name(99), "Sconosciuto", "unknown name")

	# Test biome multipliers
	biome_system.current_biome = 0  # FOREST
	assert_eq(biome_system.get_biome_multiplier(), 1.0, "FOREST mult=1.0")

	biome_system.current_biome = 1  # CAVE
	assert_eq(biome_system.get_biome_multiplier(), 1.5, "CAVE mult=1.5")

	biome_system.current_biome = 2  # DESERT
	assert_eq(biome_system.get_biome_multiplier(), 2.0, "DESERT mult=2.0")

	biome_system.current_biome = 3  # ICE
	assert_eq(biome_system.get_biome_multiplier(), 2.5, "ICE mult=2.5")

	biome_system.current_biome = 4  # SWAMP
	assert_eq(biome_system.get_biome_multiplier(), 3.0, "SWAMP mult=3.0")

	# Test transition
	biome_system.current_biome = 0
	biome_system.completed_biomes.clear()

	biome_system.transition_to_next_biome()
	assert_eq(biome_system.current_biome, 1, "transition FOREST->CAVE")
	assert_eq(biome_system.completed_biomes.size(), 1, "biome added to completed")
	assert_eq(biome_system.completed_biomes[0], 0, "completed FOREST")

	# Test wrap-around (SWAMP -> FOREST)
	biome_system.current_biome = 4
	biome_system.completed_biomes.clear()
	biome_system.transition_to_next_biome()
	assert_eq(biome_system.current_biome, 0, "wrap-around SWAMP->FOREST")

	# Test generate_biome_map
	var map = biome_system.generate_biome_map(0)
	assert_true(map.has("biome_type"), "map has biome_type")
	assert_true(map.has("width"), "map has width")
	assert_true(map.has("height"), "map has height")
	assert_eq(map.biome_type, 0, "biome_type=FOREST")

	# Test check_biome_completion
	biome_system.current_biome = 0
	biome_system.forest_boundaries.clear()
	biome_system.forest_boundaries.append([5.0, 5.0, 0.0])  # Format [x, y, elevation]

	var completed: bool = biome_system.check_biome_completion(5, 5)
	assert_true(completed, "boundary reached")

	completed = biome_system.check_biome_completion(0, 0)
	assert_false(completed, "not at boundary")

	print_results()
# Test per BiomeSystem
# Verifica transizione biomi e generazione mappe

func test_biome_system_initialization() -> void:
	assert_eq(BiomeSystem.current_biome, BiomeSystem.BiomeType.FOREST, "Initial biome should be FOREST")
	assert_eq(BiomeSystem.completed_biomes.size(), 0, "No biomes completed at start")

func test_get_biome_name() -> void:
	assert_eq(BiomeSystem.get_biome_name(BiomeSystem.BiomeType.FOREST), "Foresta", "Forest name should be italiano")
	assert_eq(BiomeSystem.get_biome_name(BiomeSystem.BiomeType.CAVE), "Caverna", "Cave name should be italiano")
	assert_eq(BiomeSystem.get_biome_name(BiomeSystem.BiomeType.DESERT), "Deserto", "Desert name should be italiano")
	assert_eq(BiomeSystem.get_biome_name(BiomeSystem.BiomeType.ICE), "Ghiacciaio", "Ice name should be italiano")
	assert_eq(BiomeSystem.get_biome_name(BiomeSystem.BiomeType.SWAMP), "Palude", "Swamp name should be italiano")

func test_generate_biome_map() -> void:
	var map := BiomeSystem.generate_biome_map(BiomeSystem.BiomeType.CAVE)
	assert_not_null(map, "Should generate map dict")
	assert_eq(map.biome_type, BiomeSystem.BiomeType.CAVE, "Map biome type should match")
	assert_eq(map.width, 20, "Map width should be 20")
	assert_eq(map.height, 20, "Map height should be 20")

func test_get_biome_multiplier() -> void:
	var original_biome := BiomeSystem.current_biome

	BiomeSystem.current_biome = BiomeSystem.BiomeType.FOREST
	assert_eq(BiomeSystem.get_biome_multiplier(), 1.0, "Forest multiplier should be 1.0")

	BiomeSystem.current_biome = BiomeSystem.BiomeType.CAVE
	assert_eq(BiomeSystem.get_biome_multiplier(), 1.5, "Cave multiplier should be 1.5")

	BiomeSystem.current_biome = BiomeSystem.BiomeType.DESERT
	assert_eq(BiomeSystem.get_biome_multiplier(), 2.0, "Desert multiplier should be 2.0")

	BiomeSystem.current_biome = BiomeSystem.BiomeType.SWAMP
	assert_eq(BiomeSystem.get_biome_multiplier(), 3.0, "Swamp multiplier should be 3.0")

	BiomeSystem.current_biome = original_biome

func test_biome_completion_tracking() -> void:
	BiomeSystem.completed_biomes.clear()
	BiomeSystem.current_biome = BiomeSystem.BiomeType.FOREST

	# Simulate biome completion
	BiomeSystem.completed_biomes.append(BiomeSystem.BiomeType.FOREST)
	assert_eq(BiomeSystem.completed_biomes.size(), 1, "Should have 1 completed biome")
	assert_eq(BiomeSystem.completed_biomes[0], BiomeSystem.BiomeType.FOREST, "Completed biome should be FOREST")
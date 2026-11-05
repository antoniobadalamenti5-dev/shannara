# Test per ItemDatabase, InventorySystem e pickup items
# Verifica caricamento, aggiunta, rimozione e utilizzo

func test_item_database_load() -> void:
	var healing_potion := ItemDatabase.get_item("healing_potion")
	assert_not_null(healing_potion, "Should load healing_potion item")
	assert_eq(healing_potion.name, "Pozione Curativa", "Item name should match")
	assert_eq(healing_potion.type, "consumable", "Item type should be consumable")
	assert_eq(healing_potion.hp_restore, 15, "HP restore should be 15")

func test_item_database_get_all_items() -> void:
	var items := ItemDatabase.get_all_items()
	assert_not_null(items, "Should return items dictionary")
	assert_true(items.has("healing_potion"), "Should have healing_potion")
	assert_true(items.has("wooden_sword"), "Should have wooden_sword")

func test_item_database_nonexistent() -> void:
	var item := ItemDatabase.get_item("nonexistent_item")
	assert_eq(item.size(), 0, "Nonexistent item should return empty dict")

func test_inventory_add_single() -> void:
	InventorySystem.active_items.clear()
	InventorySystem.add_item("healing_potion", 1)
	assert_eq(InventorySystem.get_item_count("healing_potion"), 1, "Count should be 1")

func test_inventory_add_multiple() -> void:
	InventorySystem.active_items.clear()
	InventorySystem.add_item("healing_potion", 1)
	InventorySystem.add_item("healing_potion", 1)
	assert_eq(InventorySystem.get_item_count("healing_potion"), 2, "Count should be 2")

func test_inventory_has_item() -> void:
	InventorySystem.active_items.clear()
	InventorySystem.add_item("healing_potion", 2)
	assert_true(InventorySystem.has_item("healing_potion", 1), "Should have at least 1")
	assert_false(InventorySystem.has_item("healing_potion", 3), "Should not have 3")

func test_inventory_remove_item() -> void:
	InventorySystem.active_items.clear()
	InventorySystem.add_item("healing_potion", 3)
	var removed := InventorySystem.remove_item("healing_potion", 1)
	assert_true(removed, "Remove should succeed")
	assert_eq(InventorySystem.get_item_count("healing_potion"), 2, "Count should be 2")
	assert_false(InventorySystem.has_item("healing_potion", 3), "Should not have 3 anymore")

func test_inventory_remove_nonexistent() -> void:
	InventorySystem.active_items.clear()
	var removed := InventorySystem.remove_item("nonexistent_item", 1)
	assert_false(removed, "Removing nonexistent should fail")

func test_healing_potion_restore_hp() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5
	player.current_hp = 50  # Set to half HP

	var initial_hp := player.current_hp
	var restored := InventorySystem.use_item("healing_potion")

	assert_true(restored, "Use should succeed")
	assert_gt(player.current_hp, initial_hp, "HP should increase")
	assert_eq(player.current_hp, 65, "HP should be 65 (50 + 15)")

func test_healing_potion_consume_on_use() -> void:
	InventorySystem.active_items.clear()
	InventorySystem.add_item("healing_potion", 1)

	Player.new()  # Create player but not needed for this test
	InventorySystem.use_item("healing_potion")
	assert_false(InventorySystem.has_item("healing_potion", 1), "Potion should be consumed")

func test_pickup_consumes_turn() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 10
	player.grid_y = 10

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	var initial_turn_count := TurnManager.turn_count

	# Simulate pickup (1 action = 1 turn)
	TurnManager.consume_action()

	assert_eq(TurnManager.current_state, TurnManager.TurnState.ENEMY_TURN, "Should transition to enemy turn")
	assert_eq(TurnManager.turn_count, initial_turn_count + 1, "Turn count should increment")
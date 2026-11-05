# test_inventory.gd - Unit tests for InventorySystem
# Tests item management: add, remove, use, count

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] InventorySystem")

	# Get InventorySystem instance
	var inventory_system = get_node("/root/InventorySystem")

	# Reset inventory
	inventory_system.active_items.clear()

	# Test initial item
	inventory_system.add_item("healing_potion", 1)
	assert_true(inventory_system.has_item("healing_potion"), "starts with healing_potion")
	assert_eq(inventory_system.get_item_count("healing_potion"), 1, "count=1")

	# Test add_item
	inventory_system.add_item("healing_potion", 2)
	assert_eq(inventory_system.get_item_count("healing_potion"), 3, "count=3 after adding 2")

	# Test add_item new item
	inventory_system.add_item("mana_potion", 5)
	assert_eq(inventory_system.get_item_count("mana_potion"), 5, "new item count=5")

	# Test remove_item
	var removed: bool = inventory_system.remove_item("mana_potion", 2)
	assert_true(removed, "remove 2 mana_potion succeeds")
	assert_eq(inventory_system.get_item_count("mana_potion"), 3, "count=3 after removal")

	# Test remove_item not enough
	removed = inventory_system.remove_item("mana_potion", 10)
	assert_false(removed, "remove 10 when only 3 fails")
	assert_eq(inventory_system.get_item_count("mana_potion"), 3, "count unchanged")

	# Test remove_item non-existent
	removed = inventory_system.remove_item("nonexistent_item")
	assert_false(removed, "remove non-existent fails")

	# Test has_item
	assert_true(inventory_system.has_item("healing_potion", 1), "has 1 healing_potion")
	assert_true(inventory_system.has_item("healing_potion", 3), "has 3 healing_potion")
	assert_false(inventory_system.has_item("healing_potion", 4), "doesn't have 4 healing_potion")

	# Test empty after removal
	inventory_system.active_items.clear()
	inventory_system.add_item("test_item", 1)
	inventory_system.remove_item("test_item")
	assert_false(inventory_system.has_item("test_item"), "item removed completely")

	print_results()
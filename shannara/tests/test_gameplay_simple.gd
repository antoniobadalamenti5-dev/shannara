# test_gameplay_simple.gd - Simple end-to-end gameplay verification
# Run this test to verify: Player movement, attack, and enemy turn cycle

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Simple Gameplay Verification")

	var gs = get_node("/root/GridSystem")
	var tm = get_node("/root/TurnManager")
	var gm = get_node("/root/GameManager")

	# Reset
	tm.current_state = 0
	tm.turn_count = 0

	# Get player
	var player = tm.player
	assert_not_null(player, "player exists")

	# === TEST 1: Player Movement ===
	print("\n--- Player Movement Test ---")
	assert_true(player.can_act(), "player can act on player turn")

	# Move right
	var moved = player.move_direction(1, 0)
	assert_true(moved, "player moved right")
	assert_eq(player.grid_x, 6, "player at x=6 after move")

	# Verify enemy turn started
	assert_true(tm.is_enemy_turn(), "enemy turn started after player action")

	# === TEST 2: Enemy Action ===
	print("--- Enemy Turn Test ---")
	# Spawn a test slime
	var slime_scene = preload("res://scenes/Slime.tscn")
	var slime: Slime = slime_scene.instantiate()
	slime.grid_x = 7
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.position = Vector2((slime.grid_x + 0.5) * 32, (slime.grid_y + 0.5) * 32)
	var game_root = get_node("/root/GameRoot")
	game_root.add_child(slime)
	gs.set_occupant(slime.grid_x, slime.grid_y, 0, slime)

	# Process enemy turn
	print("Processing enemy turn...")
	tm._process_enemy_turn()
	assert_true(tm.is_player_turn(), "back to player turn after enemy turn")
	assert_eq(tm.turn_count, 1, "turn_count=1")

	# Cleanup
	gs.set_occupant(slime.grid_x, slime.grid_y, 0, null)
	game_root.remove_child(slime)
	slime.queue_free()

	# === TEST 3: Player Attack ===
	print("--- Player Attack Test ---")
	# Reset
	tm.current_state = 0
	tm.turn_count = 0
	player.grid_x = 14
	player.grid_y = 10
	gs.set_occupant(player.grid_x, player.grid_y, 0, player)

	# Spawn slime adjacent
	var test_slime: Slime = slime_scene.instantiate()
	test_slime.grid_x = 15  # Adjacent to player
	test_slime.grid_y = 10
	test_slime.current_hp = 20
	test_slime.position = Vector2((test_slime.grid_x + 0.5) * 32, (test_slime.grid_y + 0.5) * 32)
	game_root.add_child(test_slime)
	gs.set_occupant(test_slime.grid_x, test_slime.grid_y, 0, test_slime)

	# Player attacks
	assert_true(player.can_act(), "player can attack")
	var attacked = player.attack_direction(1, 0)  # Attack right (towards slime)
	assert_true(attacked, "player attacked successfully")

	# Enemy turn (slime counterattacks if alive)
	tm.is_enemy_turn()  # Should already be enemy turn
	if test_slime.is_alive():
		test_slime.take_action(player.grid_x, player.grid_y)

	tm.end_turn()
	assert_true(tm.is_player_turn(), "back to player turn")

	# Cleanup
	gs.set_occupant(test_slime.grid_x, test_slime.grid_y, 0, null)
	game_root.remove_child(test_slime)
	test_slime.queue_free()

	print("\n[SUCCESS] All gameplay tests passed!")
	print_results()
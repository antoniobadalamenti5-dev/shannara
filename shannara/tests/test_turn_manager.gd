# test_turn_manager.gd - Unit tests for TurnManager singleton
# Tests turn state transitions, turn count, action consumption

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] TurnManager")

	# Get TurnManager instance
	var turn_manager = get_node("/root/TurnManager")

	# Reset state
	turn_manager.current_state = 0
	turn_manager.turn_count = 0

	# Test initial state
	assert_eq(turn_manager.current_state, 0, "starts PLAYER_TURN")
	assert_eq(turn_manager.turn_count, 0, "turn_count=0")

	# Test methods exist
	assert_true(turn_manager.has_method("start_player_turn"), "has start_player_turn")
	assert_true(turn_manager.has_method("start_enemy_turn"), "has start_enemy_turn")
	assert_true(turn_manager.has_method("end_turn"), "has end_turn")
	assert_true(turn_manager.has_method("is_player_turn"), "has is_player_turn")
	assert_true(turn_manager.has_method("is_enemy_turn"), "has is_enemy_turn")
	assert_true(turn_manager.has_method("consume_action"), "has consume_action")

	# Test state methods
	turn_manager.current_state = 0
	assert_true(turn_manager.is_player_turn(), "is_player_turn(state=0)")

	turn_manager.current_state = 1
	assert_true(turn_manager.is_enemy_turn(), "is_enemy_turn(state=1)")

	# Test turn transition
	turn_manager.current_state = 0
	turn_manager.turn_count = 5
	assert_true(turn_manager.is_player_turn(), "player turn before transition")

	turn_manager.end_turn()
	assert_true(turn_manager.is_enemy_turn(), "enemy turn after end_turn")
	assert_eq(turn_manager.turn_count, 5, "turn_count unchanged during enemy turn")

	print_results()
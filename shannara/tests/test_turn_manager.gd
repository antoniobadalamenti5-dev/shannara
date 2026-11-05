# Test per TurnManager
# Verifica sistema turni deterministico Player -> Enemy -> Player

func test_turn_manager_initial_state() -> void:
	assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN, "Initial state should be PLAYER_TURN")
	assert_eq(TurnManager.turn_count, 0, "Initial turn count should be 0")

func test_start_player_turn() -> void:
	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
	TurnManager.turn_count = 10

	TurnManager.start_player_turn()
	assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN, "Should be in PLAYER_TURN")
	assert_eq(TurnManager.turn_count, 10, "Turn count should not reset")

func test_start_enemy_turn() -> void:
	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	TurnManager.start_enemy_turn()
	assert_eq(TurnManager.current_state, TurnManager.TurnState.ENEMY_TURN, "Should be in ENEMY_TURN")

func test_end_turn_player_to_enemy() -> void:
	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	TurnManager.end_turn()

	assert_eq(TurnManager.current_state, TurnManager.TurnState.ENEMY_TURN, "Should transition to ENEMY_TURN")
	assert_eq(TurnManager.turn_count, 0, "Turn count should not increment yet")

func test_end_turn_enemy_to_player() -> void:
	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
	TurnManager.turn_count = 5
	TurnManager.end_turn()

	assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN, "Should transition to PLAYER_TURN")
	assert_eq(TurnManager.turn_count, 6, "Turn count should increment")

func test_turn_order_complete_cycle() -> void:
	TurnManager.turn_count = 0
	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	# Player turn
	TurnManager.end_turn()
	assert_eq(TurnManager.current_state, TurnManager.TurnState.ENEMY_TURN)

	# Enemy turn
	TurnManager.end_turn()
	assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN)
	assert_eq(TurnManager.turn_count, 1, "First cycle complete")

func test_is_player_turn_helper() -> void:
	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	assert_true(TurnManager.is_player_turn(), "Should return true for player turn")

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
	assert_false(TurnManager.is_player_turn(), "Should return false for enemy turn")

func test_is_enemy_turn_helper() -> void:
	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
	assert_true(TurnManager.is_enemy_turn(), "Should return true for enemy turn")

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	assert_false(TurnManager.is_enemy_turn(), "Should return false for player turn")

func test_turn_start_signal_emitted() -> void:
	var signal_received := false
	TurnManager.connect("turn_start", func(state): signal_received = true)

	TurnManager.start_enemy_turn()
	assert_true(signal_received, "turn_start signal should be emitted")
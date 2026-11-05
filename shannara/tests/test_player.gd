# Test per Player actor
# Verifica movimento 4-direzioni e consumo turno

func test_player_creation() -> void:
	var player := Player.new()
	assert_not_null(player, "Player should not be null")
	assert_eq(player.max_hp, 100, "Player should have 100 max HP")
	assert_eq(player.current_hp, 100, "Player should start with full HP")

func test_player_can_act_on_player_turn() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	assert_true(player.can_act(), "Player should be able to act on player turn")

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
	assert_false(player.can_act(), "Player should not be able to act on enemy turn")

func test_player_move_direction_valid() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5
	player.grid_elevation = 0

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	# Move right
	var moved := player.move_direction(1, 0)
	assert_true(moved, "Should move right successfully")
	assert_eq(player.grid_x, 6, "X should increment")

func test_player_move_direction_blocked() -> void:
	var player := Player.new()
	player.name = "TestPlayer2"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5
	player.grid_elevation = 0

	# Place wall to block movement
	GridSystem.place_terrain(6, 5, 0, TerrainType.WALL)

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	var moved := player.move_direction(1, 0)
	assert_false(moved, "Should not move into wall")

func test_player_turn_consumed_by_movement() -> void:
	var player := Player.new()
	player.name = "TestPlayer3"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5

	var initial_turn_count := TurnManager.turn_count

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
	player.move_direction(1, 0)

	# Turn should now be in ENEMY_TURN (consumed)
	assert_eq(TurnManager.current_state, TurnManager.TurnState.ENEMY_TURN, "Player action should consume turn")

func test_player_move_out_of_bounds() -> void:
	var player := Player.new()
	player.name = "TestPlayer4"
	add_child(player)
	player.grid_x = 0
	player.grid_y = 0

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	var moved := player.move_direction(-1, 0)  # Move left from x=0
	assert_false(moved, "Should not move out of bounds")

func test_player_cannot_move_on_enemy_turn() -> void:
	var player := Player.new()
	player.name = "TestPlayer5"
	add_child(player)

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN

	var moved := player.move_direction(0, 1)
	assert_false(moved, "Should not move on enemy turn")

func test_player_move_to_elevation() -> void:
	var player := Player.new()
	player.name = "TestPlayer6"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5
	player.grid_elevation = 0

	# Set up stairs cell
	var stairs_cell := GridSystem.get_cell_at(5, 6, 1)
	stairs_cell.walkable = true
	stairs_cell.terrain_type = TerrainType.BRIDGE

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	var moved := player.move_to_elevation(1)
	assert_true(moved, "Should move to elevation 1")
	assert_eq(player.grid_elevation, 1, "Elevation should be 1")
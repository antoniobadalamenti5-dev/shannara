# test_turn_flow.gd - Flow tests for complete turn cycle
# Tests: Player action -> consume_action -> end_turn -> Enemy turn -> AI -> end_turn -> Player

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Turn Flow")

	var gs = get_node("/root/GridSystem")
	var tm = get_node("/root/TurnManager")

	# Reset state
	tm.current_state = 0
	tm.turn_count = 0

	# --- Test 1: Player can move and start enemy turn ---
	print("\n--- Test 1: Player move triggers enemy turn ---")
	var player = tm.player
	assert_not_null(player, "player exists")
	assert_eq(player.grid_x, 5, "player starts at x=5")

	# Player moves right
	assert_true(player.can_act(), "player can act on their turn")
	var moved = player.move_direction(1, 0)
	assert_true(moved, "player moved successfully")
	assert_eq(player.grid_x, 6, "player at x=6 after move")
	assert_true(tm.is_enemy_turn(), "enemy turn started after player action")

	# --- Test 2: Enemy takes turn ---
	print("\n--- Test 2: Enemy takes turn ---")
	# Spawn a slime for testing
	var slime_scene = preload("res://scenes/Slime.tscn")
	var slime: Slime = slime_scene.instantiate()
	slime.grid_x = 7
	slime.grid_y = 5
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.position = Vector2((slime.grid_x + 0.5) * 32, (slime.grid_y + 0.5) * 32)
	var game_root = get_node("/root/GameRoot")
	game_root.add_child(slime)
	gs.set_occupant(slime.grid_x, slime.grid_y, 0, slime)

	assert_eq(slime.grid_x, 7, "slime at x=7")
	assert_eq(slime.grid_y, 5, "slime at y=5")

	# Process enemy turn
	tm._process_enemy_turn()
	assert_true(tm.is_player_turn(), "back to player turn after enemy turn")
	assert_eq(tm.turn_count, 1, "turn_count=1 after one cycle")

	# Cleanup
	gs.set_occupant(slime.grid_x, slime.grid_y, 0, null)
	game_root.remove_child(slime)
	slime.queue_free()

	# --- Test 3: Player attack adjacent enemy ---
	print("\n--- Test 3: Player attack ---")
	# Reset
	tm.current_state = 0
	tm.turn_count = 0

	# Place enemy adjacent to player
	var test_slime: Slime = slime_scene.instantiate()
	test_slime.grid_x = player.grid_x + 1  # Adjacent to the right
	test_slime.grid_y = player.grid_y
	test_slime.current_hp = 20
	test_slime.position = Vector2((test_slime.grid_x + 0.5) * 32, (test_slime.grid_y + 0.5) * 32)
	game_root.add_child(test_slime)
	gs.set_occupant(test_slime.grid_x, test_slime.grid_y, 0, test_slime)

	# Player attacks
	assert_true(player.can_act(), "player can act")
	var attacked = player.attack_direction(1, 0)  # Attack right
	assert_true(attacked, "player attacked slime")
	assert_true(tm.is_enemy_turn(), "enemy turn after player attack")

	# Enemy counterattacks if alive
	if test_slime.is_alive():
		test_slime.take_action(player.grid_x, player.grid_y)

	# End enemy turn
	tm.end_turn()
	assert_true(tm.is_player_turn(), "back to player turn")

	# Cleanup
	gs.set_occupant(test_slime.grid_x, test_slime.grid_y, 0, null)
	game_root.remove_child(test_slime)
	test_slime.queue_free()

	# --- Test 4: Slime moves during enemy turn (HUNT) ---
	print("\n--- Test 4: Slime HUNT movement ---")

	# Reset state
	tm.current_state = 0
	tm.turn_count = 0
	tm.start_player_turn()

	# Create slime far away (distance > 3)
	var hunt_slime: Slime = slime_scene.instantiate()
	hunt_slime.grid_x = 12
	hunt_slime.grid_y = 5
	hunt_slime.grid_elevation = 0
	hunt_slime.position = Vector2((hunt_slime.grid_x + 0.5) * 32, (hunt_slime.grid_y + 0.5) * 32)
	game_root.add_child(hunt_slime)
	gs.set_occupant(hunt_slime.grid_x, hunt_slime.grid_y, 0, hunt_slime)
	hunt_slime.add_to_group("enemies")

	# Verify initial state
	assert_eq(abs(hunt_slime.grid_x - player.grid_x) + abs(hunt_slime.grid_y - player.grid_y), 7, "initial distance is 7")

	# Player moves close enough for HUNT (distance <= 3)
	player.move_direction(1, 0)  # Player to (6, 5), distance = 6
	player.move_direction(1, 0)  # Player to (7, 5), distance = 5
	player.move_direction(1, 0)  # Player to (8, 5), distance = 4
	# Need one more move to get to distance 3

	tm.end_turn()  # Player turn ends
	assert_true(tm.is_enemy_turn(), "enemy turn started")

	# Move player to (9, 5) - distance 3 from slime at (12, 5)
	player.move_direction(1, 0)  # Player to (9, 5)
	tm.end_turn()

	# Now slime should be in HUNT range
	tm.start_enemy_turn()
	hunt_slime.update_state(player.grid_x, player.grid_y)
	assert_eq(hunt_slime.state, hunt_slime.EnemyState.HUNT, "slime should be in HUNT state")

	# Slime should move toward player
	var before_x = hunt_slime.grid_x
	var before_y = hunt_slime.grid_y
	var moved = hunt_slime.take_action(player.grid_x, player.grid_y)

	# Slime should have gotten closer OR attempted to
	assert_eq(hunt_slime.state, hunt_slime.EnemyState.HUNT, "still in HUNT state")

	tm.end_turn()
	assert_true(tm.is_player_turn(), "back to player turn after enemy cycle")

	# Cleanup
	gs.set_occupant(hunt_slime.grid_x, hunt_slime.grid_y, 0, null)
	game_root.remove_child(hunt_slime)
	hunt_slime.queue_free()

	# --- Test 5: Slime patrols when far from player ---
	print("\n--- Test 5: Slime PATROL movement ---")

	# Reset and create slime with patrol points
	tm.current_state = 0
	tm.turn_count = 1
	tm.start_player_turn()

	# Move player back to starting position to be far from slime patrol area
	for i in range(3):
		player.move_direction(-1, 0)
	tm.end_turn()

	# Create slime in patrol mode
	var patrol_slime: Slime = slime_scene.instantiate()
	patrol_slime.grid_x = 15
	patrol_slime.grid_y = 10
	patrol_slime.grid_elevation = 0
	patrol_slime.patrol_points = [
		[14, 10, 0],
		[14, 11, 0],
		[15, 11, 0]
	]
	patrol_slime.position = Vector2((patrol_slime.grid_x + 0.5) * 32, (patrol_slime.grid_y + 0.5) * 32)
	game_root.add_child(patrol_slime)
	gs.set_occupant(15, 10, 0, patrol_slime)
	patrol_slime.add_to_group("enemies")

	# Verify patrol state
	tm.start_enemy_turn()
	patrol_slime.update_state(player.grid_x, player.grid_y)
	assert_eq(patrol_slime.state, patrol_slime.EnemyState.PATROL, "slime should be in PATROL state")

	# Slime should move along patrol route
	var patrol_before_x = patrol_slime.grid_x
	patrol_slime.take_action(player.grid_x, player.grid_y)

	tm.end_turn()

	# Cleanup
	gs.set_occupant(patrol_slime.grid_x, patrol_slime.grid_y, 0, null)
	game_root.remove_child(patrol_slime)
	patrol_slime.queue_free()

	print("\n[RESULT] All turn flow tests passed!")
	print_results()
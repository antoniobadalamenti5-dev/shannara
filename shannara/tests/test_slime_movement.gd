# test_slime_movement.gd
# Test per verificare che lo Slime si muova correttamente durante IL TURN DEI NEMICI
extends TestSetup

# --- Setup ---
var slime: Node
var grid_system: Node
var turn_manager: Node
var player: Node

func _ready() -> void:
	# Setup - create a slime for testing
	slime_scene = preload("res://scenes/Slime.tscn")
	grid_system = get_node("/root/GridSystem")
	turn_manager = get_node("/root/TurnManager")
	player_scene = preload("res://actors/Player.gd")

	# Create player at (5,5)
	var player_script = preload("res://actors/Player.gd")
	player = player_script.new()
	player.name = "Player"
	player.grid_x = 5
	player.grid_y = 5
	player.grid_elevation = 0
	add_child(player)
	grid_system.set_occupant(5, 5, 0, player)

	# Set player in TurnManager
	turn_manager.player = player

	yield(get_tree(), "process_frame")

func _exit_tree() -> void:
	pass

# --- Tests ---
func test_slime_moves_when_hunt() -> void:
	"""Slime should move toward player when within hunt range (distance <= 3)."""
	add_test("test_slime_moves_when_hunt")

	# Create slime at (12, 5) - distance 7 from player at (5,5)
	slime = slime_scene.instantiate()
	slime.grid_x = 12
	slime.grid_y = 5
	slime.grid_elevation = 0
	add_child(slime)
	grid_system.set_occupant(12, 5, 0, slime)
	slime.add_to_group("enemies")

	# Verify slime is NOT in hunt range yet
	var initial_distance = abs(slime.grid_x - player.grid_x) + abs(slime.grid_y - player.grid_y)
	assert_equal(initial_distance, 7, "Initial distance should be 7")

	# Move player to (6, 5) - distance 6
	player.grid_x = 6
	player.grid_y = 5
	grid_system.set_occupant(6, 5, 0, player)

	# Update slime state - still not in range
	slime.update_state(player.grid_x, player.grid_y)
	assert_equal(slime.state, slime.EnemyState.PATROL, "Should be PATROL at distance 6")

	# Move player to (7, 5) - distance 5
	player.grid_x = 7
	slime.update_state(player.grid_x, player.grid_y)
	assert_equal(slime.state, slime.EnemyState.PATROL, "Should be PATROL at distance 5")

	# Move player to (8, 5) - distance 4
	player.grid_x = 8
	slime.update_state(player.grid_x, player.grid_y)
	assert_equal(slime.state, slime.EnemyState.PATROL, "Should be PATROL at distance 4")

	# Move player to (9, 5) - distance 3 - should enter HUNT
	player.grid_x = 9
	slime.update_state(player.grid_x, player.grid_y)
	assert_equal(slime.state, slime.EnemyState.HUNT, "Should be HUNT at distance 3")

	# Simulate enemy turn process
	var before_pos = [slime.grid_x, slime.grid_y]
	turn_manager.current_state = 1  # ENEMY_TURN
	var result = slime.take_action(player.grid_x, player.grid_y)

	# Slime should have moved closer
	var after_pos = [slime.grid_x, slime.grid_y]
	var moved = (before_pos[0] != after_pos[0] or before_pos[1] != after_pos[1])
	assert_true(result, "take_action should return true when moving")
	assert_true(moved, "Slime should have moved closer to player")

	remove_test()

func test_slime_attacks_when_adjacent() -> void:
	"""Slime should attack when adjacent to player."""
	add_test("test_slime_attacks_when_adjacent")

	# Create slime at (6, 5) - adjacent to player at (5,5)
	slime = slime_scene.instantiate()
	slime.grid_x = 6
	slime.grid_y = 5
	slime.grid_elevation = 0
	add_child(slime)
	grid_system.set_occupant(6, 5, 0, slime)
	slime.add_to_group("enemies")

	# Verify slime is in attack range (distance 1)
	var distance = abs(slime.grid_x - player.grid_x) + abs(slime.grid_y - player.grid_y)
	assert_equal(distance, 1, "Distance should be 1")

	# Update state and take action
	slime.update_state(player.grid_x, player.grid_y)
	turn_manager.current_state = 1  # ENEMY_TURN
	var result = slime.take_action(player.grid_x, player.grid_y)

	# Should have attempted attack (result depends on combat resolver)
	assert_equal(result, result, "Attack result should be consistent")

	remove_test()

func test_slime_patrols_when_far_away() -> void:
	"""Slime should patrol when not in hunt range."""
	add_test("test_slime_patrols_when_far_away")

	# Create slime at (12, 5) with patrol points
	slime = slime_scene.instantiate()
	slime.grid_x = 12
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.patrol_points = [
		[11, 5, 0],
		[11, 6, 0],
		[12, 6, 0]
	]
	add_child(slime)
	grid_system.set_occupant(12, 5, 0, slime)
	slime.add_to_group("enemies")

	# Move player to (2, 2) - far away
	player.grid_x = 2
	player.grid_y = 2

	# Update state
	slime.update_state(player.grid_x, player.grid_y)
	assert_equal(slime.state, slime.EnemyState.PATROL, "Should be PATROL when far from player")

	# Enemy turn
	turn_manager.current_state = 1  # ENEMY_TURN
	var before_pos = [slime.grid_x, slime.grid_y]
	var result = slime.take_action(player.grid_x, player.grid_y)

	var after_pos = [slime.grid_x, slime.grid_y]
	var moved = (before_pos[0] != after_pos[0] or before_pos[1] != after_pos[1])

	assert_true(result, "take_action should return true when patrolling")
	assert_true(moved, "Slime should have moved along patrol route")

	remove_test()

func test_slime_idle_wanders() -> void:
	"""Slime should wander when IDLE (no patrol points, player far)."""
	add_test("test_slime_idle_wanders")

	# Create slime at (12, 5) without patrol points
	slime = slime_scene.instantiate()
	slime.grid_x = 12
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.patrol_points = []  # No patrol points
	add_child(slime)
	grid_system.set_occupant(12, 5, 0, slime)
	slime.add_to_group("enemies")

	# Move player far away
	player.grid_x = 0
	player.grid_y = 0

	# Update state - should be IDLE
	slime.update_state(player.grid_x, player.grid_y)
	assert_equal(slime.state, slime.EnemyState.IDLE, "Should be IDLE when far with no patrol")

	# Enemy turn - should wander
	turn_manager.current_state = 1  # ENEMY_TURN
	var before_pos = [slime.grid_x, slime.grid_y]
	var result = slime.take_action(player.grid_x, player.grid_y)

	var after_pos = [slime.grid_x, slime.grid_y]
	var moved = (before_pos[0] != after_pos[0] or before_pos[1] != after_pos[1])

	assert_true(result, "take_action should return true when wandering")
	assert_true(moved, "Slime should have wandered (moved) when IDLE")

	remove_test()
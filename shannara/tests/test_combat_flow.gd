# Test per combat flow end-to-end
# Verifica attacco player → enemy, enemy attack → player, morte nemico

func test_player_attack_adjacent_enemy() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5

	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 6
	enemy.grid_y = 5
	enemy.current_hp = 50

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	var result := CombatResolver.resolve_attack(player, enemy)
	assert_true(result.success, "Attack should succeed on adjacent enemy")
	assert_gt(result.damage, 0, "Damage should be positive")
	assert_lt(enemy.current_hp, 50, "Enemy HP should decrease")

func test_player_attack_dead_enemy() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5

	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 6
	enemy.grid_y = 5
	enemy.current_hp = 0  # Already dead

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	var result := CombatResolver.resolve_attack(player, enemy)
	assert_false(result.success, "Should not attack dead enemy")
	assert_true(result.target_killed, "target_killed should be true for dead target")

func test_enemy_attack_player() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5
	player.current_hp = 100

	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 6
	enemy.grid_y = 5
	enemy.current_hp = 50

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN

	var result := CombatResolver.resolve_attack(enemy, player)
	assert_true(result.success, "Enemy attack should succeed on adjacent player")
	assert_gt(result.damage, 0, "Damage should be positive")
	assert_lt(player.current_hp, 100, "Player HP should decrease")

func test_attack_not_adjacent_fails() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5

	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 10  # Too far
	enemy.grid_y = 10

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	var result := CombatResolver.resolve_attack(player, enemy)
	assert_false(result.success, "Attack should fail on non-adjacent enemy")
	assert_eq(result.damage, 0, "No damage should be dealt")

func test_enemy_death_removes_from_grid() -> void:
	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 5

	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 6
	enemy.grid_y = 5
	enemy.current_hp = 5

	# Set occupant on grid
	GridSystem.set_occupant(6, 5, 0, enemy)

	TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN

	# Deal enough damage to kill
	CombatResolver.resolve_attack(player, enemy)
	assert_false(enemy.is_alive(), "Enemy should be dead")
	assert_eq(enemy.current_hp, 0, "Enemy HP should be 0")

	# Verify grid occupant cleared
	var cell := GridSystem.get_cell_at(6, 5, 0)
	assert_null(cell.occupant, "Grid occupant should be cleared after death")
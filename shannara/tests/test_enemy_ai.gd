# Test per Enemy AI (Slime) e Boss (BossGolem)
# Verifica comportamenti HUNT, PATROL, ATTACK e fasi boss

func test_slime_creation() -> void:
	var slime := Slime.new()
	assert_not_null(slime, "Slime should not be null")
	assert_eq(slime.max_hp, 20, "Slime should have 20 max HP")
	assert_eq(slime.current_hp, 20, "Slime should start with full HP")

func test_slime_detection_range() -> void:
	var slime := Slime.new()
	slime.name = "TestSlime"
	add_child(slime)
	slime.grid_x = 10
	slime.grid_y = 10

	# Player at distance 2 (within hunt range of 3)
	var player := Player.new()
	player.name = "TestPlayer"
	player.grid_x = 12
	player.grid_y = 10
	add_child(player)

	slime.update_state(player.grid_x, player.grid_y)
	assert_eq(slime.state, Slime.EnemyState.HUNT, "Slime should HUNT when player within 3 tiles")

func test_slime_attack_adjacent() -> void:
	var slime := Slime.new()
	slime.name = "TestSlime"
	add_child(slime)
	slime.grid_x = 5
	slime.grid_y = 5

	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 6
	player.grid_y = 5
	player.current_hp = 100

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN

	var result := slime.take_action(player.grid_x, player.grid_y)
	assert_true(result, "Slime should attack when adjacent")
	assert_lt(player.current_hp, 100, "Player should take damage")

func test_boss_golem_creation() -> void:
	var golem := BossGolem.new()
	assert_not_null(golem, "BossGolem should not be null")
	assert_eq(golem.max_hp, 50, "Boss should have 50 max HP")
	assert_eq(golem.phase, 1, "Boss should start in phase 1")

func test_boss_golem_phase_transitions() -> void:
	var golem := BossGolem.new()
	golem.name = "TestBoss"
	add_child(golem)

	# Phase 1: HP 50-26
	assert_eq(golem.get_attack_damage(), 5, "Phase 1 damage should be 5")
	assert_eq(golem.get_movement_speed(), 1.0, "Phase 1 speed should be 1.0")

	# Damage to trigger phase 2 threshold
	golem.take_damage(26)  # HP becomes 24
	assert_eq(golem.phase, 2, "Should be in phase 2")
	assert_eq(golem.get_attack_damage(), 8, "Phase 2 damage should be 8")
	assert_eq(golem.get_movement_speed(), 1.2, "Phase 2 speed should be 1.2")

	# Damage to trigger phase 3 threshold
	golem.take_damage(10)  # HP becomes 14
	assert_eq(golem.phase, 3, "Should be in phase 3")
	assert_eq(golem.get_attack_damage(), 12, "Phase 3 damage should be 12")
	assert_eq(golem.get_movement_speed(), 1.4, "Phase 3 speed should be 1.4")

func test_boss_golem_attack() -> void:
	var golem := BossGolem.new()
	golem.name = "TestBoss"
	add_child(golem)
	golem.grid_x = 5
	golem.grid_y = 5
	golem.phase = 3

	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 6
	player.grid_y = 5
	player.current_hp = 100

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN

	var result := golem.take_action(player.grid_x, player.grid_y)
	assert_true(result, "Boss should attack in phase 3")
	assert_eq(player.current_hp, 88, "Player should take 12 damage (phase 3)")

func test_enemy_attack_player_adjacent() -> void:
	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 5
	enemy.grid_y = 5

	var player := Player.new()
	player.name = "TestPlayer"
	add_child(player)
	player.grid_x = 5
	player.grid_y = 6
	player.current_hp = 100

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN

	var result := enemy.take_action(player.grid_x, player.grid_y)
	assert_true(result, "Enemy should attack when adjacent to player")
	assert_lt(player.current_hp, 100, "Player should take damage from enemy")

func test_enemy_patrol_mode() -> void:
	var enemy := Enemy.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	enemy.grid_x = 10
	enemy.grid_y = 10
	enemy.patrol_points = [
		[10, 10, 0],
		[11, 10, 0],
		[11, 11, 0]
	]
	enemy.patrol_index = 0

	var player := Player.new()
	player.name = "TestPlayer"
	player.grid_x = 100  # Far away
	player.grid_y = 100

	TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN

	enemy.update_state(player.grid_x, player.grid_y)
	assert_eq(enemy.state, Enemy.EnemyState.PATROL, "Enemy should PATROL when player far")

	enemy.take_action(player.grid_x, player.grid_y)
	assert_eq(enemy.grid_x, 11, "Enemy should move to next patrol point")
	assert_eq(enemy.patrol_index, 1, "Patrol index should increment")
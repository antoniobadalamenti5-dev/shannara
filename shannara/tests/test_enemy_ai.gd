# test_enemy_ai.gd - Unit tests for Enemy AI behavior (Fase 3)
# Tests state machine thresholds, hunt pathing, patrol route, attack priority.
# Enum di riferimento (Enemy.gd): IDLE=0, PATROL=1, HUNT=2, ATTACK=3

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Enemy AI")

	var grid_system = get_node("/root/GridSystem")
	var turn_manager = get_node("/root/TurnManager")
	var tm_state_bak: int = turn_manager.current_state
	var tm_player_bak = turn_manager.player

	# Player di test nell'albero: occupa (10,10,0) e diventa tm.player
	var player: Player = Player.new()
	player.grid_x = 10
	player.grid_y = 10
	add_child(player)

	var enemy: Slime = Slime.new()
	enemy.grid_x = 10
	enemy.grid_y = 13
	add_child(enemy)
	grid_system.set_occupant(enemy.grid_x, enemy.grid_y, 0, enemy)
	assert_true(enemy.is_in_group("enemies"), "slime added to enemies group")
	assert_eq(enemy.max_hp, 20, "slime max_hp=20")

	# --- Soglie di rilevamento: Slime rileva entro 3 ---
	enemy.update_state(player.grid_x, player.grid_y)  # distanza 3
	assert_eq(enemy.state, Enemy.EnemyState.HUNT, "slime hunts at distance 3")

	enemy.grid_y = 14
	enemy.update_state(player.grid_x, player.grid_y)  # distanza 4
	assert_eq(enemy.state, Enemy.EnemyState.IDLE, "idle at distance 4 without patrol")

	enemy.patrol_points = [[10, 14, 0], [10, 16, 0]]
	enemy.update_state(player.grid_x, player.grid_y)
	assert_eq(enemy.state, Enemy.EnemyState.PATROL, "patrol when far with patrol points")
	enemy.patrol_points = []

	# --- Base Enemy: soglia 2 (il Slime è più sensibile) ---
	var base: Enemy = Enemy.new()
	base.grid_x = 10
	base.grid_y = 13
	add_child(base)
	base.update_state(player.grid_x, player.grid_y)  # distanza 3
	assert_eq(base.state, Enemy.EnemyState.IDLE, "base enemy idle at distance 3")
	base.grid_y = 12
	base.update_state(player.grid_x, player.grid_y)  # distanza 2
	assert_eq(base.state, Enemy.EnemyState.HUNT, "base enemy hunts at distance 2")

	# --- can_act vincolato allo stato del turno ---
	turn_manager.current_state = 0  # PLAYER_TURN
	assert_false(enemy.can_act(), "enemy cannot act on player turn")
	turn_manager.current_state = 1  # ENEMY_TURN
	assert_true(enemy.can_act(), "enemy can act on enemy turn")

	# --- Hunting: il nemico si avvicina di una cella per turno ---
	enemy.grid_y = 13
	grid_system.set_occupant(enemy.grid_x, enemy.grid_y, 0, enemy)
	turn_manager.current_state = 1
	assert_true(enemy.take_action(player.grid_x, player.grid_y), "hunt action taken")
	assert_eq(enemy.grid_y, 12, "slime stepped to (10,12) toward player")
	assert_null(grid_system.get_cell_at(10, 13, 0).occupant, "old cell vacated by slime")
	assert_true(grid_system.get_cell_at(10, 12, 0).occupant == enemy, "slime occupies new cell")

	# --- Priorità attacco: adiacente in ENEMY_TURN colpisce invece di muoversi ---
	# Dopo il primo passo la distanza è ancora 2: serve un secondo passo.
	assert_true(enemy.take_action(player.grid_x, player.grid_y), "second hunt step")
	assert_eq(enemy.grid_y, 11, "slime stepped to (10,11), now adjacent")

	var hp_before: int = player.current_hp
	assert_true(enemy.take_action(player.grid_x, player.grid_y), "adjacent slime acts")
	assert_eq(enemy.grid_y, 11, "slime did not move when adjacent")
	assert_eq(player.current_hp, hp_before - 1, "player took 1 damage (3 attack - 2 defense)")

	# --- Patrol: segue i punti di pattuglia quando il player è lontano ---
	var patroller: Slime = Slime.new()
	patroller.grid_x = 3
	patroller.grid_y = 15
	add_child(patroller)
	grid_system.set_occupant(3, 15, 0, patroller)
	patroller.patrol_points = [[3, 14, 0], [4, 14, 0]]
	patroller.patrol_index = 0
	turn_manager.current_state = 1
	assert_true(patroller.take_action(18, 18), "patrol action taken")
	assert_eq(patroller.grid_x, 3, "patroller moved to first point x")
	assert_eq(patroller.grid_y, 14, "patroller moved to first point y")
	assert_eq(patroller.patrol_index, 1, "patrol index advanced")
	assert_true(patroller.take_action(18, 18), "second patrol step taken")
	assert_eq(patroller.patrol_index, 0, "patrol index wrapped around")

	# --- Fuori ENEMY_TURN nessuna azione ---
	turn_manager.current_state = 0
	var frozen_y: int = patroller.grid_y
	assert_false(patroller.take_action(18, 18), "no action outside enemy turn")
	assert_eq(patroller.grid_y, frozen_y, "position unchanged outside enemy turn")

	# --- Pulizia: celle libere prima del free, stato TurnManager ripristinato ---
	for n in [player, enemy, base, patroller]:
		grid_system.set_occupant(n.grid_x, n.grid_y, n.grid_elevation, null)
		remove_child(n)
		n.free()
	turn_manager.player = tm_player_bak
	turn_manager.current_state = tm_state_bak

	print_results()

# test_turn_cycle.gd - End-to-end turn cycle test (Fase 3.3)
# Tests complete cycle: Player action -> consume_action -> end_turn -> Enemy turn -> AI -> end_turn -> Player
# Verifies GameRoot spawns enemy and enemy AI functions correctly

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Turn Cycle")

	var gs = get_node("/root/GridSystem")
	var tm = get_node("/root/TurnManager")
	var tm_state_bak: int = tm.current_state
	var tm_player_bak = tm.player

	# Reset
	tm.current_state = 0
	tm.turn_count = 0

	var slime: Slime = null

	# --- GameRoot.spawn -> Slime spawnato nel raggio di caccia a (8, 5, 0) ---
	var packed: PackedScene = load("res://scenes/GameRoot.tscn")
	assert_not_null(packed, "GameRoot.tscn loads")

	var game_root: Node = packed.instantiate()
	assert_not_null(game_root, "GameRoot.tscn instantiates")
	add_child(game_root)

	# Verifica che lo spawn sia avvenuto
	var slimes = get_tree().get_nodes_in_group("enemies")
	var initial_slime_count: int = slimes.size()
	assert_gt(initial_slime_count, 0, "at least one enemy spawned by GameRoot")

	# Trova lo slime istanziato
	for s in slimes:
		if s is Slime:
			slime = s
			break
	assert_not_null(slime, "found a Slime enemy")
	assert_eq(slime.grid_x, 8, "slime at x=8")
	assert_eq(slime.grid_y, 5, "slime at y=5")

	# --- Verifica turno player iniziale ---
	assert_true(tm.is_player_turn(), "starts with player turn")

	# --- Verifica ciclo base: Player action -> consume_action -> end_turn -> Enemy turn ---
	# Slime a (8,5), player a (5,5) - distanza 3, quindi caccia subito.

	# Verifica lo stato iniziale
	assert_eq(tm.current_state, 0, "initial state = PLAYER_TURN")
	assert_eq(tm.turn_count, 0, "initial turn_count = 0")

	# Player si muove (consuma azione)
	var player = tm.player
	assert_not_null(player, "player found in TurnManager")

	# Verifichiamo che il movimento sia possibile
	var can_move = gs.can_move_to(player.grid_x, player.grid_y, player.grid_elevation,
	                                player.grid_x + 1, player.grid_y, player.grid_elevation)
	assert_true(can_move, "player can move right")

	# Eseguiamo il movimento del player
	player.move_direction(1, 0)  # sposta a destra

	# Verifichiamo che il movimento sia avvenuto
	assert_eq(player.grid_x, 6, "player moved to x=6")

	# L'azione del player avvia il turno nemico. Eseguiamo il callback
	# differito direttamente, come unit test deterministico.
	assert_true(tm.is_enemy_turn(), "player action starts enemy turn")
	tm._process_enemy_turn()

	assert_true(tm.is_player_turn(), "back to player turn after enemy turn")
	assert_eq(tm.turn_count, 1, "turn_count=1 after one complete cycle")
	assert_eq([slime.grid_x, slime.grid_y], [7, 5], "slime moved toward player")

	# --- Combat Test: Player and Slime in adjacency ---
	# Teleport player next to slime for combat test
	gs.set_occupant(player.grid_x, player.grid_y, player.grid_elevation, null)
	gs.set_occupant(slime.grid_x, slime.grid_y, slime.grid_elevation, null)
	player.grid_x = 14
	player.grid_y = 10
	gs.set_occupant(14, 10, 0, player)
	slime.grid_x = 15
	slime.grid_y = 10
	gs.set_occupant(15, 10, 0, slime)

	assert_eq([player.grid_x, player.grid_y], [14, 10], "player teleported")
	assert_eq([slime.grid_x, slime.grid_y], [15, 10], "slime at (15,10)")

	# Player turn: attack the slime (attacca a est, dove è il nemico)
	player.attack_direction(1, 0)

	# Enemy turn: slime counterattacks (if still alive)
	if slime.is_alive():
		slime.take_action(player.grid_x, player.grid_y)

	# Chiudi l'enemy turn -> player turn
	tm.end_turn()

	assert_true(tm.is_player_turn(), "cycle continues to player turn after combat")

	# --- Pulizia ---
	for n in get_tree().get_nodes_in_group("enemies"):
		gs.set_occupant(n.grid_x, n.grid_y, n.grid_elevation, null)
		n.get_parent().remove_child(n)
		n.free()

	remove_child(game_root)
	game_root.free()

	tm.player = tm_player_bak
	tm.current_state = tm_state_bak

	print_results()
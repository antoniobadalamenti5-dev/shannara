# test_combat_integration.gd - Integration test for combat with real spawned enemies (Fase 3.4)
# Tests that player can attack real enemies spawned by GameRoot

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Combat Integration")

	var gs = get_node("/root/GridSystem")
	var tm = get_node("/root/TurnManager")
	var cm = get_node("/root/CombatResolver")
	var tm_state_bak: int = tm.current_state
	var tm_player_bak = tm.player

	# Reset
	tm.current_state = 0
	tm.turn_count = 0

	# --- Spawn GameRoot which includes Player and Slime enemy ---
	var packed: PackedScene = load("res://scenes/GameRoot.tscn")
	assert_not_null(packed, "GameRoot.tscn loads")

	var game_root: Node = packed.instantiate()
	assert_not_null(game_root, "GameRoot.tscn instantiates")
	add_child(game_root)
	var player = tm.player
	assert_not_null(player, "player registered with TurnManager")

	# Verify slime is in enemies group (this was the bug - _ready() needed)
	var enemies = get_tree().get_nodes_in_group("enemies")
	assert_gt(enemies.size(), 0, "enemies group has at least one enemy")

	var slime: Slime = null
	for e in enemies:
		if e is Slime:
			slime = e
			break
	assert_not_null(slime, "found Slime enemy")

	# Teleport slime adjacent to player for combat test
	gs.set_occupant(slime.grid_x, slime.grid_y, slime.grid_elevation, null)
	slime.grid_x = player.grid_x + 1  # right adjacent
	slime.grid_y = player.grid_y
	gs.set_occupant(slime.grid_x, slime.grid_y, slime.grid_elevation, slime)

	# Test: Player attack_direction to the right
	assert_eq(slime.grid_x, player.grid_x + 1, "slime is to the right of player")

	# Player attacks (in player turn)
	# L'attacco va eseguito durante il turno player e consuma il turno stesso.
	var result = player.attack_direction(1, 0)  # attack to the right
	assert_true(result, "attack_direction succeeds when enemy adjacent")

	# Enemy should still be alive (8 damage vs 20 HP)
	assert_true(slime.is_alive(), "slime survives player attack")

	# Esegui il turno nemico avviato dall'attacco.
	assert_true(tm.is_enemy_turn(), "now in enemy turn")
	var hp_before = player.current_hp
	tm._process_enemy_turn()
	assert_neq(player.current_hp, hp_before, "player took damage from slime")
	assert_true(tm.is_player_turn(), "back to player turn")

	# --- Pulizia ---
	for e in get_tree().get_nodes_in_group("enemies"):
		gs.set_occupant(e.grid_x, e.grid_y, e.grid_elevation, null)
		e.get_parent().remove_child(e)
		e.free()

	remove_child(game_root)
	game_root.free()

	tm.player = tm_player_bak
	tm.current_state = tm_state_bak

	print_results()
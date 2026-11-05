# test_combat_flow.gd - End-to-end combat flow tests (Fase 4)
# Tests complete combat sequences: player turn, enemy turn, resolution

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Combat Flow")

	var turn_manager = get_node("/root/TurnManager")
	var grid_system = get_node("/root/GridSystem")
	var combat_resolver = get_node("/root/CombatResolver")
	var tm_state_bak: int = turn_manager.current_state
	var tm_player_bak = turn_manager.player

	# Reset systems
	turn_manager.current_state = 0
	turn_manager.turn_count = 0

	# --- Combattimento completo: player attacca, slime contrattacca, ---
	# --- il player finisce il lavoro entro pochi turni.                ---
	var player: Player = Player.new()
	player.grid_x = 5
	player.grid_y = 5
	add_child(player)

	var slime: Slime = Slime.new()
	slime.grid_x = 6
	slime.grid_y = 5
	add_child(slime)
	grid_system.set_occupant(6, 5, 0, slime)
	slime.add_to_group("enemies")

	assert_true(turn_manager.is_player_turn(), "turn starts with player")

	# Turno player: primo colpo (8 danni su 20 HP -> sopravvive)
	var result = combat_resolver.resolve_attack(player, slime)
	assert_true(result.success, "player attack succeeds")
	assert_eq(result.damage, 8, "damage=10-2=8 (base defense=2)")
	assert_true(slime.is_alive(), "slime survives first hit (20-8=12)")
	assert_eq(slime.current_hp, 12, "slime hp=12 after first hit")

	# Turno enemy: slime adiacente contrattacca (3-2=1 danno)
	turn_manager.current_state = 1
	var hp_before: int = player.current_hp
	assert_true(slime.take_action(player.grid_x, player.grid_y), "slime acts on enemy turn")
	assert_eq(player.current_hp, hp_before - 1, "player took counterattack damage")

	# Turno player: altri due colpi chiudono (12-8=4, 4-8<=0)
	turn_manager.current_state = 0
	result = combat_resolver.resolve_attack(player, slime)
	assert_true(slime.is_alive(), "slime survives second hit (hp=4)")
	result = combat_resolver.resolve_attack(player, slime)
	assert_true(result.target_killed, "slime killed by third hit")
	assert_false(slime.is_alive(), "slime dead after player attacks")
	assert_null(grid_system.get_cell_at(6, 5, 0).occupant, "dead slime cleared from grid")

	# Turno enemy con solo nemici morti: nessuna azione, nessuna nuova ferita
	turn_manager.current_state = 1
	hp_before = player.current_hp
	assert_false(slime.can_act(), "dead slime cannot act")
	assert_eq(player.current_hp, hp_before, "dead enemy deals no damage")

	# --- Ciclo turni completo: end_turn alterna PLAYER/ENEMY e conta ---
	turn_manager.current_state = 0
	var turns_before: int = turn_manager.turn_count
	turn_manager.end_turn()
	assert_true(turn_manager.is_enemy_turn(), "end_turn -> enemy turn")
	turn_manager.current_state = 0  # ripara: end_turn da ENEMY chiude il giro
	turn_manager.turn_count = turns_before

	# --- Secondo combattimento: resolve_attack diretto ---
	var player2: Player = Player.new()
	player2.grid_x = 10
	player2.grid_y = 10
	add_child(player2)

	var slime2: Slime = Slime.new()
	slime2.grid_x = 11
	slime2.grid_y = 10
	add_child(slime2)
	grid_system.set_occupant(11, 10, 0, slime2)
	slime2.add_to_group("enemies")

	result = combat_resolver.resolve_attack(player2, slime2)
	assert_true(result.success, "second player attack succeeds")
	assert_eq(slime2.current_hp, 12, "slime2 hp=12 after hit")
	slime2.take_damage(12)
	result = combat_resolver.resolve_attack(player2, slime2)
	assert_true(result.target_killed, "slime2 dead")
	assert_eq(slime2.current_hp, 0, "slime2 hp=0")

	# --- Pulizia ordinata: celle libere prima del free ---
	for n in [player, slime, player2, slime2]:
		grid_system.set_occupant(n.grid_x, n.grid_y, n.grid_elevation, null)
		remove_child(n)
		n.free()
	turn_manager.player = tm_player_bak
	turn_manager.current_state = tm_state_bak

	print_results()

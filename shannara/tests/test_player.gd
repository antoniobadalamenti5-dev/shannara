# test_player.gd - Unit tests for Player actor
# Tests HP, position, grid registration, can_act

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Player")

	var turn_manager = get_node("/root/TurnManager")
	var grid_system = get_node("/root/GridSystem")
	var tm_state_bak: int = turn_manager.current_state
	var tm_player_bak = turn_manager.player

	# Dentro l'albero: _ready richiede i percorsi assoluti (/root/TurnManager)
	var p: Player = Player.new()
	add_child(p)
	assert_true(p is Player, "Player.new() is a Player")

	# Default HP
	assert_eq(p.max_hp, 100, "max_hp=100")
	assert_eq(p.current_hp, 100, "current_hp=100 on new")

	# Default position
	assert_eq(p.grid_x, 5, "grid_x=5")
	assert_eq(p.grid_y, 5, "grid_y=5")
	assert_eq(p.grid_elevation, 0, "grid_elevation=0")

	# Registrazione all'ingresso nell'albero (invariante griglia + TurnManager)
	assert_true(p.is_in_group("players"), "added to players group")
	assert_true(turn_manager.player == p, "TurnManager references the player")
	var spawn_cell: GridCell = grid_system.get_cell_at(5, 5, 0)
	assert_true(spawn_cell.occupant == p, "spawn cell registered on grid")

	# is_alive
	assert_true(p.is_alive(), "is_alive at full HP")

	# Damage
	p.take_damage(30)
	assert_eq(p.current_hp, 70, "hp after 30 damage")

	p.take_damage(70)
	assert_eq(p.current_hp, 0, "hp=0 after 70 damage")
	assert_false(p.is_alive(), "not alive at 0 hp")

	# Healing
	p.current_hp = 50
	p.heal(20)
	assert_eq(p.current_hp, 70, "hp after 20 heal")

	p.heal(999)
	assert_eq(p.current_hp, p.max_hp, "heal capped at max_hp")

	# Attack damage
	assert_eq(p.get_attack_damage(), 10, "attack_damage=10")

	# can_act (TurnManager lookup: il player deve essere nell'albero)
	turn_manager.current_state = 0  # PLAYER_TURN
	assert_true(p.can_act(), "can_act on player turn")

	turn_manager.current_state = 1  # ENEMY_TURN
	assert_false(p.can_act(), "cannot act on enemy turn")

	turn_manager.current_state = 0
	p.take_damage(999)
	assert_false(p.can_act(), "dead player cannot act")

	# Clean up: liberare la cella PRIMA del free (no dangling occupant)
	grid_system.set_occupant(p.grid_x, p.grid_y, p.grid_elevation, null)
	turn_manager.player = tm_player_bak
	turn_manager.current_state = tm_state_bak
	remove_child(p)
	p.free()

	print_results()

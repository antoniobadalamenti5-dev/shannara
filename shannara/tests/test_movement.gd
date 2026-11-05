# test_movement.gd - Unit tests for movement resolution (Task 2.2)
# Tests GridSystem.can_move_to validation and Player real movement via _attempt_move_to

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Movement")

	var grid_system = get_node("/root/GridSystem")
	var turn_manager = get_node("/root/TurnManager")

	# --- can_move_to: validazione di base ---
	assert_true(grid_system.can_move_to(5, 5, 0, 6, 5, 0), "can_move_to adjacent walkable")
	assert_false(grid_system.can_move_to(5, 5, 0, 99, 99, 0), "can_move_to out of bounds rejected")
	assert_false(grid_system.can_move_to(5, 5, 0, 5, 5, 5), "can_move_to invalid elevation rejected")
	assert_false(grid_system.can_move_to(5, 10, 0, 0, 10, 0), "can_move_to perimeter wall rejected")
	assert_false(grid_system.can_move_to(12, 5, 0, 13, 5, 0), "can_move_to spike cell rejected")
	assert_true(grid_system.can_move_to(12, 10, 0, 13, 10, 0), "can_move_to bridge over spikes allowed")

	# --- Movimento reale del Player (aggiunto all'albero: serve per gli autoload) ---
	var tm_state_bak: int = turn_manager.current_state
	turn_manager.current_state = 0  # PLAYER_TURN, così can_act() è true

	var player: Player = Player.new()
	add_child(player)  # _ready: si registra con TurnManager e con GridSystem

	assert_true(turn_manager.is_player_turn(), "player turn active after register")

	var spawn_cell: GridCell = grid_system.get_cell_at(player.grid_x, player.grid_y, player.grid_elevation)
	assert_true(spawn_cell.occupant == player, "player registered on spawn cell")

	# Passo legale: (5,5) -> (6,5)
	var moved: bool = player.move_direction(1, 0)
	assert_true(moved, "move_direction(1,0) succeeds")
	assert_eq(player.grid_x, 6, "grid_x advanced to 6")
	assert_eq(player.grid_y, 5, "grid_y unchanged")
	assert_eq(grid_system.get_cell_at(6, 5, 0).occupant, player, "new cell occupied by player")
	assert_null(grid_system.get_cell_at(5, 5, 0).occupant, "old cell vacated")
	assert_eq(player.position.x, (6 + 0.5) * 32, "world position synced after move")

	# Passo successivo (6,5) -> (6,4)
	assert_true(player.move_direction(0, -1), "move up succeeds")
	assert_eq(player.grid_y, 4, "grid_y advanced to 4")

	# Diagonale: mossa a 2 celle Manhattan, ora bloccata da can_move_to
	moved = player.move_direction(1, 1)
	assert_false(moved, "diagonal (1,1) rejected by validation")
	assert_eq(player.grid_x, 6, "failed move leaves grid_x unchanged")
	assert_eq(player.grid_y, 4, "failed move leaves grid_y unchanged")

	# Mossa contro il perimetro: muri x=19 / y=19
	_teleport(grid_system, player, 18, 18, 0)
	assert_false(player.move_direction(1, 1), "diagonal into corner wall rejected")
	assert_false(player.move_direction(1, 0), "move into perimeter wall rejected")
	assert_false(player.move_direction(0, 1), "move into perimeter wall (down) rejected")
	assert_eq(grid_system.get_cell_at(18, 18, 0).occupant, player, "player still on its cell after failed moves")

	# Fuori mappa diretto (angolo in alto a sinistra: muro, poi fuori)
	_teleport(grid_system, player, 1, 1, 0)
	# (0,1) è muro di perimetro
	assert_false(player.move_direction(-1, 0), "move into left perimeter wall rejected")

	# Pulizia: libera la cella occupata PRIMA di free() del player (no dangling)
	grid_system.set_occupant(player.grid_x, player.grid_y, player.grid_elevation, null)
	turn_manager.player = null
	turn_manager.current_state = tm_state_bak
	remove_child(player)
	player.free()

	print_results()

# Spostamento "di test": mantiene l'invariante occupant della griglia.
func _teleport(gs, p: Player, x: int, y: int, e: int) -> void:
	gs.set_occupant(p.grid_x, p.grid_y, p.grid_elevation, null)
	p.grid_x = x
	p.grid_y = y
	p.grid_elevation = e
	gs.set_occupant(x, y, e, p)

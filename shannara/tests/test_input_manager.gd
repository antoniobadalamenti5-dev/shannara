# test_input_manager.gd - Unit tests for InputManager (Task 2.4)
# Tests mode switching, key handling and single-emit attack targeting flow
# Copre anche il binding WASD e i tasti di quota Q/E.

extends TestSuite

var _move_log: Array = []
var _attack_log: Array = []
var _elev_log: Array = []
var _wait_count: int = 0

func run_tests() -> void:
	print("\n[TEST] InputManager")

	var input_manager = get_node("/root/InputManager")
	var turn_manager = get_node("/root/TurnManager")
	var tm_state_bak: int = turn_manager.current_state
	turn_manager.current_state = 0  # PLAYER_TURN

	# --- stato iniziale / costanti ---
	assert_eq(input_manager.input_mode, input_manager.MODE_MOVE, "initial mode = MODE_MOVE")
	assert_eq(input_manager.targeting_direction, Vector2i.ZERO, "initial targeting = ZERO")
	assert_eq(input_manager.MODE_MOVE, 0, "MODE_MOVE = 0")
	assert_eq(input_manager.MODE_TARGET_ATTACK, 1, "MODE_TARGET_ATTACK = 1")

	# --- set_input_mode / is_input_mode / nomi ---
	input_manager.set_input_mode(input_manager.MODE_TARGET_ATTACK)
	assert_true(input_manager.is_input_mode(input_manager.MODE_TARGET_ATTACK), "is_input_mode(ATTACK)")
	assert_false(input_manager.is_input_mode(input_manager.MODE_MOVE), "not in MOVE mode")
	assert_eq(input_manager.get_input_mode_name(), "Attack", "mode name Attack")
	input_manager.set_input_mode(input_manager.MODE_MOVE)
	assert_eq(input_manager.get_input_mode_name(), "Move", "mode name Move")

	# --- flusso chiave: sposta in MODE_MOVE ---
	_clear_logs()
	input_manager.move_requested.connect(_on_move)
	input_manager.attack_requested.connect(_on_attack)
	input_manager.wait_requested.connect(_on_wait)
	input_manager.elevation_requested.connect(_on_elevation)

	_press_key(input_manager, KEY_RIGHT)
	assert_eq(_move_log.size(), 1, "KEY_RIGHT emits exactly 1 move_requested")
	assert_eq(_move_log[0], Vector2i(1, 0), "KEY_RIGHT direction (1,0)")

	_press_key(input_manager, KEY_UP)
	assert_eq(_move_log[1], Vector2i(0, -1), "KEY_UP direction (0,-1)")
	_press_key(input_manager, KEY_DOWN)
	assert_eq(_move_log[2], Vector2i(0, 1), "KEY_DOWN direction (0,1)")
	_press_key(input_manager, KEY_LEFT)
	assert_eq(_move_log[3], Vector2i(-1, 0), "KEY_LEFT direction (-1,0)")

	# --- WASD: stesse direzioni delle frecce ---
	_clear_logs()
	_press_key(input_manager, KEY_W)
	assert_eq(_move_log.size(), 1, "KEY_W emits 1 move_requested")
	assert_eq(_move_log[0], Vector2i(0, -1), "KEY_W = up")
	_press_key(input_manager, KEY_S)
	assert_eq(_move_log[1], Vector2i(0, 1), "KEY_S = down")
	_press_key(input_manager, KEY_A)
	assert_eq(_move_log[2], Vector2i(-1, 0), "KEY_A = left (now movement, not attack)")
	assert_eq(_attack_log.size(), 0, "KEY_A in MOVE mode emits no attack")
	_press_key(input_manager, KEY_D)
	assert_eq(_move_log[3], Vector2i(1, 0), "KEY_D = right")

	# --- quota: Q giu, E su ---
	_clear_logs()
	_press_key(input_manager, KEY_Q)
	assert_eq(_elev_log.size(), 1, "KEY_Q emits 1 elevation_requested")
	assert_eq(_elev_log[0], -1, "KEY_Q delta -1 (down)")
	_press_key(input_manager, KEY_E)
	assert_eq(_elev_log[1], 1, "KEY_E delta +1 (up)")
	assert_eq(_move_log.size(), 0, "elevation keys emit no move")

	# --- flusso attacco: F entra in targeting SENZA emettere ---
	_clear_logs()
	_press_key(input_manager, KEY_F)
	assert_true(input_manager.is_input_mode(input_manager.MODE_TARGET_ATTACK), "F enters targeting")
	assert_eq(_attack_log.size(), 0, "entering targeting emits nothing (bug 4x fix)")

	# Frecce in targeting aggiornano la direzione, niente emit
	_press_key(input_manager, KEY_UP)
	assert_eq(input_manager.get_targeting_direction(), Vector2i(0, -1), "arrow sets targeting dir")
	assert_eq(_attack_log.size(), 0, "aiming emits nothing")
	assert_eq(_move_log.size(), 0, "aiming emits no move (targeting consumes arrows)")

	# WASD mira come le frecce
	_press_key(input_manager, KEY_D)
	assert_eq(input_manager.get_targeting_direction(), Vector2i(1, 0), "WASD sets targeting dir")

	# Conferma: UN solo attack_requested, poi ritorno a MODE_MOVE
	_press_key(input_manager, KEY_SPACE)
	assert_eq(_attack_log.size(), 1, "confirm emits exactly 1 attack_requested")
	assert_eq(_attack_log[0], Vector2i(1, 0), "attack direction is aimed dir")
	assert_true(input_manager.is_input_mode(input_manager.MODE_MOVE), "confirm returns to MODE_MOVE")

	# F conferma da solo (senza passare da SPAZIO)
	_press_key(input_manager, KEY_F)
	_press_key(input_manager, KEY_LEFT)
	_press_key(input_manager, KEY_F)
	assert_eq(_attack_log.size(), 2, "F confirms attack too")
	assert_eq(_attack_log[1], Vector2i(-1, 0), "F-confirm uses aimed dir")
	assert_true(input_manager.is_input_mode(input_manager.MODE_MOVE), "F-confirm returns to MODE_MOVE")

	# ESC annulla il targeting e azzera la direzione
	_press_key(input_manager, KEY_F)
	assert_true(input_manager.is_input_mode(input_manager.MODE_TARGET_ATTACK), "F re-enters targeting")
	_press_key(input_manager, KEY_ESCAPE)
	assert_true(input_manager.is_input_mode(input_manager.MODE_MOVE), "ESC cancels targeting")
	assert_eq(input_manager.get_targeting_direction(), Vector2i.ZERO, "cancel resets direction")

	# --- in MODE_MOVE lo spazio è wait, non attacco ---
	_clear_logs()
	_press_key(input_manager, KEY_SPACE)
	assert_eq(_wait_count, 1, "SPACE in MOVE mode emits wait_requested")
	assert_eq(_attack_log.size(), 0, "SPACE in MOVE mode emits no attack")

	# --- input ignorato fuori dal turno del player ---
	turn_manager.current_state = 1  # ENEMY_TURN
	_clear_logs()
	_press_key(input_manager, KEY_RIGHT)
	_press_key(input_manager, KEY_W)
	_press_key(input_manager, KEY_Q)
	_press_key(input_manager, KEY_E)
	_press_key(input_manager, KEY_F)
	assert_eq(_move_log.size(), 0, "move keys ignored during enemy turn")
	assert_eq(_elev_log.size(), 0, "elevation keys ignored during enemy turn")
	assert_eq(_attack_log.size(), 0, "attack key ignored during enemy turn")
	input_manager.set_input_mode(input_manager.MODE_MOVE)
	turn_manager.current_state = tm_state_bak

	input_manager.move_requested.disconnect(_on_move)
	input_manager.attack_requested.disconnect(_on_attack)
	input_manager.wait_requested.disconnect(_on_wait)
	input_manager.elevation_requested.disconnect(_on_elevation)
	input_manager.set_input_mode(input_manager.MODE_MOVE)

	print_results()

func _clear_logs() -> void:
	_move_log.clear()
	_attack_log.clear()
	_elev_log.clear()
	_wait_count = 0

func _press_key(im, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	im._handle_key_input(ev)

func _on_move(dir: Vector2i) -> void:
	_move_log.append(dir)

func _on_attack(dir: Vector2i) -> void:
	_attack_log.append(dir)

func _on_elevation(delta: int) -> void:
	_elev_log.append(delta)

func _on_wait() -> void:
	_wait_count += 1

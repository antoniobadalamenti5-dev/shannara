# test_input_manager.gd - Unit tests for InputManager (Task 2.4)
# Tests mode switching, key handling and single-emit attack targeting flow

extends TestSuite

var _move_log: Array = []
var _attack_log: Array = []
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
	_move_log.clear()
	_attack_log.clear()
	_wait_count = 0
	input_manager.move_requested.connect(_on_move)
	input_manager.attack_requested.connect(_on_attack)
	input_manager.wait_requested.connect(_on_wait)

	_press_key(input_manager, KEY_RIGHT)
	assert_eq(_move_log.size(), 1, "KEY_RIGHT emits exactly 1 move_requested")
	assert_eq(_move_log[0], Vector2i(1, 0), "KEY_RIGHT direction (1,0)")

	_press_key(input_manager, KEY_UP)
	assert_eq(_move_log[1], Vector2i(0, -1), "KEY_UP direction (0,-1)")
	_press_key(input_manager, KEY_DOWN)
	assert_eq(_move_log[2], Vector2i(0, 1), "KEY_DOWN direction (0,1)")
	_press_key(input_manager, KEY_LEFT)
	assert_eq(_move_log[3], Vector2i(-1, 0), "KEY_LEFT direction (-1,0)")

	# --- flusso attacco: A entra in targeting SENZA emettere ---
	_press_key(input_manager, KEY_A)
	assert_true(input_manager.is_input_mode(input_manager.MODE_TARGET_ATTACK), "A enters targeting")
	assert_eq(_attack_log.size(), 0, "entering targeting emits nothing (bug 4x fix)")

	# Frecce in targeting aggiornano la direzione, niente emit
	_press_key(input_manager, KEY_UP)
	assert_eq(input_manager.get_targeting_direction(), Vector2i(0, -1), "arrow sets targeting dir")
	assert_eq(_attack_log.size(), 0, "aiming emits nothing")

	# Conferma: UN solo attack_requested, poi ritorno a MODE_MOVE
	_press_key(input_manager, KEY_SPACE)
	assert_eq(_attack_log.size(), 1, "confirm emits exactly 1 attack_requested")
	assert_eq(_attack_log[0], Vector2i(0, -1), "attack direction is aimed dir")
	assert_true(input_manager.is_input_mode(input_manager.MODE_MOVE), "confirm returns to MODE_MOVE")

	# ESC annulla il targeting e azzera la direzione
	_press_key(input_manager, KEY_A)
	assert_true(input_manager.is_input_mode(input_manager.MODE_TARGET_ATTACK), "A re-enters targeting")
	_press_key(input_manager, KEY_ESCAPE)
	assert_true(input_manager.is_input_mode(input_manager.MODE_MOVE), "ESC cancels targeting")
	assert_eq(input_manager.get_targeting_direction(), Vector2i.ZERO, "cancel resets direction")

	# --- in MODE_MOVE lo spazio è wait, non attacco ---
	_wait_count = 0
	_attack_log.clear()
	_press_key(input_manager, KEY_SPACE)
	assert_eq(_wait_count, 1, "SPACE in MOVE mode emits wait_requested")
	assert_eq(_attack_log.size(), 0, "SPACE in MOVE mode emits no attack")

	# --- input ignorato fuori dal turno del player ---
	turn_manager.current_state = 1  # ENEMY_TURN
	_move_log.clear()
	_press_key(input_manager, KEY_RIGHT)
	assert_eq(_move_log.size(), 0, "keys ignored during enemy turn")
	turn_manager.current_state = tm_state_bak

	input_manager.move_requested.disconnect(_on_move)
	input_manager.attack_requested.disconnect(_on_attack)
	input_manager.wait_requested.disconnect(_on_wait)
	input_manager.set_input_mode(input_manager.MODE_MOVE)

	print_results()

func _press_key(im, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	im._handle_key_input(ev)

func _on_move(dir: Vector2i) -> void:
	_move_log.append(dir)

func _on_attack(dir: Vector2i) -> void:
	_attack_log.append(dir)

func _on_wait() -> void:
	_wait_count += 1

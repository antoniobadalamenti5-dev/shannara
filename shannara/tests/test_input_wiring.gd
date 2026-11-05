# test_input_wiring.gd - Task 2.4.3: l'input arrive davvero al Player.
# Percorre la catena completa istanziando la scena reale:
#   chiave -> InputManager -> GameRoot -> GameManager -> Player -> GridSystem
# I test di InputManager verificano gli INTENTI; qui si verifica che una
# pressione di tasto cambi la cella del player e che un muro la blocchi.

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] InputWiring")

	var gs = get_node("/root/GridSystem")
	var tm = get_node("/root/TurnManager")
	var im = get_node("/root/InputManager")

	var tm_state_bak: int = tm.current_state
	var tm_player_bak: Node = tm.player
	tm.current_state = 0  # PLAYER_TURN, altrimenti l'input è ignorato

	var scene: Node = _instantiate_scene()
	if scene == null:
		tm.current_state = tm_state_bak
		tm.player = tm_player_bak
		print_results()
		return

	var p = tm.player
	assert_true(p is Player, "scene player registered with TurnManager")
	assert_eq([p.grid_x, p.grid_y, p.grid_elevation], [5, 5, 0], "player starts at spawn 5,5,0")

	# --- Freccia Destra -> il player si muove a destra (criterio 2.4.3) ---
	_press(im, KEY_RIGHT)
	assert_eq([p.grid_x, p.grid_y], [6, 5], "KEY_RIGHT moved player right")
	assert_eq(gs.get_cell_at(6, 5, 0).occupant, p, "destination cell occupied")
	assert_null(gs.get_cell_at(5, 5, 0).occupant, "spawn cell vacated")

	# --- WASD: W = su, stessa strada delle frecce ---
	_press(im, KEY_W)
	assert_eq([p.grid_x, p.grid_y], [6, 4], "KEY_W moved player up")

	# --- A ora è movimento (sinistra), non più attacco ---
	_press(im, KEY_A)
	assert_eq([p.grid_x, p.grid_y], [5, 4], "KEY_A moved player left (movement, not attack)")

	# --- D = destra ---
	_press(im, KEY_D)
	assert_eq([p.grid_x, p.grid_y], [6, 4], "KEY_D moved player right")

	# --- Q/E changing elevation through the wiring ---
	_press(im, KEY_E)
	assert_eq(p.grid_elevation, 1, "KEY_E stepped up a level")
	_press(im, KEY_E)
	assert_eq(p.grid_elevation, 1, "second KEY_E blocked (no +2 support)")
	_press(im, KEY_Q)
	assert_eq(p.grid_elevation, 0, "KEY_Q stepped back down")

	# --- Freccia contro il muro di perimetro: nessun movimento (criterio 2.4.3) ---
	_teleport(gs, p, 1, 1, 0)
	_press(im, KEY_LEFT)
	assert_eq([p.grid_x, p.grid_y], [1, 1], "KEY_LEFT into perimeter wall: no movement")
	_press(im, KEY_UP)
	assert_eq([p.grid_x, p.grid_y], [1, 1], "KEY_UP into perimeter wall: no movement")
	assert_eq(gs.get_cell_at(1, 1, 0).occupant, p, "player still on its own cell")

	# --- Spuntoni: ingresso vietato anche se la cella è adiacente ---
	_teleport(gs, p, 12, 5, 0)
	_press(im, KEY_RIGHT)  # (13,5) è fossato con spuntoni a quota 0
	assert_eq([p.grid_x, p.grid_y], [12, 5], "stepping onto spikes rejected")

	# --- Il ponte a y=10 attraversa il fossato ---
	_teleport(gs, p, 12, 10, 0)
	_press(im, KEY_RIGHT)
	assert_eq([p.grid_x, p.grid_y], [13, 10], "bridge crossing accepted")

	# --- Fuori dal turno del player: la scena non deve reagire ---
	tm.current_state = 1  # ENEMY_TURN
	_press(im, KEY_RIGHT)
	assert_eq([p.grid_x, p.grid_y], [13, 10], "input ignored during enemy turn")
	tm.current_state = 0

	# --- L'HUD riporta cella e quota (feedback visibile dei tasti premuti) ---
	# L'HUD si rinfresca in _process: nei test i frame non scorrono tra un
	# _handle_key_input e l'altro, quindi se ne simula uno.
	scene._process(0.0)
	var label: Node = scene.get_node("UILayer/TurnLabel")
	assert_true(label.text.find("cella 13,10") >= 0, "HUD shows current cell: %s" % label.text)

	# Pulizia: liberare l'occupazione prima del free, ripristinare TurnManager.
	gs.set_occupant(p.grid_x, p.grid_y, p.grid_elevation, null)
	remove_child(scene)
	scene.free()
	tm.player = tm_player_bak
	tm.current_state = tm_state_bak
	im.set_input_mode(im.MODE_MOVE)

	print_results()

func _instantiate_scene() -> Node:
	var packed: PackedScene = load("res://scenes/GameRoot.tscn")
	assert_not_null(packed, "GameRoot.tscn loads")
	if packed == null:
		return null
	var scene: Node = packed.instantiate()
	assert_not_null(scene, "GameRoot.tscn instantiates")
	if scene == null:
		return null
	add_child(scene)  # _ready: si collega a /root/InputManager
	assert_true(scene.has_node("Player"), "scene contains the Player")
	return scene

func _press(im, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	im._handle_key_input(ev)

# Spostamento "di test": mantiene l'invariante occupant della griglia.
func _teleport(gs, p: Player, x: int, y: int, e: int) -> void:
	gs.set_occupant(p.grid_x, p.grid_y, p.grid_elevation, null)
	p.grid_x = x
	p.grid_y = y
	p.grid_elevation = e
	gs.set_occupant(x, y, e, p)

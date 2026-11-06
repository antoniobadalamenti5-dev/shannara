# GameRoot - scena principale
# Orchestratore: la mappa è disegnata da GridRenderer (nodo figlio),
# qui restano camera, HUD e il collegamento input -> azioni (Task 2.4).
#
# InputManager e GameManager sono autoload: non sono figli di questa scena,
# si raggiungono in /root. Il flusso è
#   InputManager (emette intento) -> qui -> GameManager.ProcessPlayerAction
#   -> Player.move_direction / attack_direction -> TurnManager.consume_action
# La convalida della mossa resta in GridSystem.can_move_to, unica fonte di verità.
extends Node2D

const TILE_SIZE: int = 32

var _turn_label: Label
var _input_manager: Node = null
var _game_manager: Node = null
var _last_message: String = ""

func _ready() -> void:
	print("[GameRoot] pronto - tiles %dx%d" % [GridSystem.GRID_WIDTH, GridSystem.GRID_HEIGHT])
	_add_turn_label()
	_add_camera()
	_connect_input()
	_spawn_initial_enemy()
	print("[GameRoot] _game_manager = %s" % _game_manager)
	if _game_manager != null:
		print("[GameRoot] Chiamo StartGame()")
		_game_manager.StartGame()
	else:
		print("[GameRoot] ERRORE: _game_manager è null!")

func _connect_input() -> void:
	_input_manager = get_node_or_null("/root/InputManager")
	_game_manager = get_node_or_null("/root/GameManager")
	if _input_manager == null:
		push_warning("[GameRoot] InputManager non trovato: nessun input in gioco")
		return
	# L'InputManager emette intenti; qui si decide come tradurli in azioni.
	_input_manager.move_requested.connect(_on_move_requested)
	_input_manager.attack_requested.connect(_on_attack_requested)
	_input_manager.wait_requested.connect(_on_wait_requested)
	_input_manager.elevation_requested.connect(_on_elevation_requested)
	_input_manager.inventory_requested.connect(_on_inventory_requested)
	_input_manager.biome_transition_requested.connect(_on_biome_transition_requested)
	print("[GameRoot] input collegato (frecce/WASD, Q/E quote, F attacco, SPAZIO attendi)")

func _on_move_requested(direction: Vector2i) -> void:
	_set_message(_call_action("move", direction.x, direction.y))

func _on_attack_requested(direction: Vector2i) -> void:
	_set_message(_call_action("attack", direction.x, direction.y))

func _on_wait_requested() -> void:
	# Nessun ProcessPlayerAction("wait") qui: l'InputManager ha già chiamato
	# consume_action() quando ha emesso wait_requested (vedi InputManager.gd).
	# Passare da GameManager vorrebbe dire consumare DUE volte lo stesso turno.
	_set_message("Hai atteso")

# Salita/discesa: passa direttamente al Player, che delega a can_move_to.
# GameManager non ha un ramo "elevation", e aggiungerlo ora duplicherebbe una
# strada che il Player già percorre.
func _on_elevation_requested(delta_elev: int) -> void:
	var p := _current_player()
	if p == null:
		_set_message("Nessun giocatore")
		return
	if p.move_to_elevation(delta_elev):
		_set_message("Quota %+d" % delta_elev)
	else:
		_set_message("Quota non raggiungibile")

func _on_inventory_requested() -> void:
	_set_message("Inventario: non ancora implementato")

func _on_biome_transition_requested() -> void:
	_set_message("Transizione bioma: non ancora implementata")

func _call_action(action_type: String, dx: int = 0, dy: int = 0) -> String:
	if _game_manager == null:
		return "GameManager non trovato"
	var result: Dictionary = _game_manager.ProcessPlayerAction(action_type, dx, dy)
	return String(result.get("message", ""))

func _current_player() -> Player:
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or tm.player == null:
		return null
	return tm.player as Player

func _set_message(msg: String) -> void:
	if msg != "":
		_last_message = msg

func _add_turn_label() -> void:
	# CanvasLayer = coordinate schermo, non di mondo: la Label resta visibile
	# qualunque sia la posizione/zoom della Camera2D.
	var layer := CanvasLayer.new()
	layer.name = "UILayer"
	layer.layer = 10
	add_child(layer)
	_turn_label = Label.new()
	_turn_label.name = "TurnLabel"
	_turn_label.text = _turn_text()
	_turn_label.position = Vector2(8, 8)
	_turn_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_turn_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_turn_label.add_theme_constant_override("outline_size", 4)
	_turn_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(_turn_label)

func _add_camera() -> void:
	var cam: Camera2D = $Camera2D if has_node("Camera2D") else null
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		add_child(cam)
	cam.position = Vector2(GridSystem.GRID_WIDTH * TILE_SIZE / 2.0, GridSystem.GRID_HEIGHT * TILE_SIZE / 2.0)
	# Zoom 1.0 = la griglia 20x20 (640px) sta intera nella finestra.
	cam.zoom = Vector2.ONE
	cam.make_current()

# HUD: turno, cella con quota (si vede Q/E in azione) e ultimo esito.
func _turn_text() -> String:
	var tm := get_node_or_null("/root/TurnManager")
	if tm == null:
		return "Turno: -"
	var who: String = "Player" if tm.is_player_turn() else "Nemici"
	var lines: Array[String] = ["Turno %d - %s" % [tm.turn_count, who]]
	lines.append("F: mira | frecce/WASD: muovi e mira | F/Spazio: attacca")
	var p := _current_player()
	if p != null:
		lines.append("cella %d,%d quota %+d" % [p.grid_x, p.grid_y, p.grid_elevation])
	if _last_message != "":
		lines.append(_last_message)
	return "\n".join(lines)

func _process(_delta: float) -> void:
	if _turn_label != null:
		_turn_label.text = _turn_text()

# Spawn iniziale: un nemico (Slime) a sinistra del player.
# Player spawn a (5,5), Slime a (12,5) = distanza 7.
# Dopo il primo movimento del player a destra, la distanza cala e lo Slime inizia HUNT.
func _spawn_initial_enemy() -> void:
	var slime_scene = preload("res://scenes/Slime.tscn")
	var slime: Slime = slime_scene.instantiate()
	slime.grid_x = 12  # Lontano dal player, inizialmente IDLE o PATROL
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.position = Vector2((slime.grid_x + 0.5) * TILE_SIZE, (slime.grid_y + 0.5) * TILE_SIZE)
	add_child(slime)

	# Registra l'occupazione della griglia
	var gs = get_node("/root/GridSystem")
	gs.set_occupant(slime.grid_x, slime.grid_y, slime.grid_elevation, slime)
	print("[GameRoot] Slime spawnato a (%d, %d, %d)" % [slime.grid_x, slime.grid_y, slime.grid_elevation])

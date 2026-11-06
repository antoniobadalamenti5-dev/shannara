# InputManager - Handles player keyboard input for dungeon crawler
#
# Controlli (Task 2.4):
#   movemento  : frecce OPPURE W A S D
#   quota      : Q = scendi di 1, E = sali di 1
#   attacco    : F entra in targeting; frecce/WASD mirano; F o SPAZIO confermano
#   attendi    : SPAZIO (in MODE_MOVE)
#   inventario : I
#   bioma/ESC  : ESC (annulla anche il targeting)
#
# A è stato liberato per il movimento WASD: la chiave d'attacco è ora F, che
# sostituisce il vecchio "A = targeting". Il flusso resta quello del fix 4x:
# entrare in targeting non emette nulla, la conferma emette UN attack_requested.

extends Node

signal move_requested(direction: Vector2i)
signal attack_requested(direction: Vector2i)
signal wait_requested()
signal inventory_requested()
signal biome_transition_requested()
signal elevation_requested(delta_elevation: int)

const MODE_MOVE: int = 0
const MODE_TARGET_ATTACK: int = 1

var input_mode: int = MODE_MOVE
var targeting_direction: Vector2i = Vector2i.ZERO

func _ready() -> void:
	set_input_mode(MODE_MOVE)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key_input(event)

func _handle_key_input(event: InputEventKey) -> void:
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager == null:
		print("[InputManager] WARNING: TurnManager non trovato")
		return
	if not turn_manager.is_player_turn():
		print("[InputManager] Ignorato input - non è il turno del giocatore (current_state=%s)" % turn_manager.current_state)
		return

	var key: int = event.keycode

	if input_mode == MODE_TARGET_ATTACK:
		_handle_targeting_input(key, turn_manager)
		return

	# Frecce e WASD convergono sulla stessa direzione: un solo emit per chiave.
	var dir := _movement_direction(key)
	if dir != Vector2i.ZERO:
		move_requested.emit(dir)
		return

	match key:
		KEY_F:
			_start_attack_targeting()
		KEY_Q:
			elevation_requested.emit(-1)
		KEY_E:
			elevation_requested.emit(1)
		KEY_I:
			inventory_requested.emit()
		KEY_SPACE:
			wait_requested.emit()
			turn_manager.consume_action()
		KEY_ESCAPE:
			biome_transition_requested.emit()

# In targeting: frecce/WASD = direzione, F/SPACE = conferma (1 solo emit), ESC = annulla.
func _handle_targeting_input(key: int, turn_manager) -> void:
	var dir := _movement_direction(key)
	if dir != Vector2i.ZERO:
		targeting_direction = dir
		return

	match key:
		KEY_F, KEY_SPACE:
			attack_requested.emit(targeting_direction)
			set_input_mode(MODE_MOVE)
		KEY_ESCAPE:
			cancel_targeting()

# Direzione ortogonale per le 8 chiavi di movimento, ZERO se chiave non di moto.
func _movement_direction(key: int) -> Vector2i:
	match key:
		KEY_UP, KEY_W:
			return Vector2i(0, -1)
		KEY_DOWN, KEY_S:
			return Vector2i(0, 1)
		KEY_LEFT, KEY_A:
			return Vector2i(-1, 0)
		KEY_RIGHT, KEY_D:
			return Vector2i(1, 0)
		_:
			return Vector2i.ZERO

func _start_attack_targeting() -> void:
	input_mode = MODE_TARGET_ATTACK
	# Direzione iniziale: fronte del player (default destra se sconosciuta).
	if targeting_direction == Vector2i.ZERO:
		targeting_direction = Vector2i(1, 0)

func cancel_targeting() -> void:
	targeting_direction = Vector2i.ZERO
	set_input_mode(MODE_MOVE)

func set_input_mode(mode: int) -> void:
	input_mode = mode

func is_input_mode(mode: int) -> bool:
	return input_mode == mode

func get_targeting_direction() -> Vector2i:
	return targeting_direction

func get_input_mode_name() -> String:
	match input_mode:
		MODE_MOVE:
			return "Move"
		MODE_TARGET_ATTACK:
			return "Attack"
		_:
			return "Unknown"

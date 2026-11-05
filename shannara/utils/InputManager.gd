# InputManager - Handles player keyboard input for dungeon crawler
# Arrow keys for movement, A for attack, I for inventory, Space for wait
#
# Flusso attacco (Task 2.4): A entra in modalità targeting senza emettere
# nulla; le frecce scelgono la direzione; SPACE (o A) conferma e emette UN
# solo attack_requested; ESC annulla. In MODE_MOVE, SPACE consume_action (wait).

extends Node

signal move_requested(direction: Vector2i)
signal attack_requested(direction: Vector2i)
signal wait_requested()
signal inventory_requested()
signal biome_transition_requested()

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
		return
	if not turn_manager.is_player_turn():
		return

	var key: int = event.keycode

	if input_mode == MODE_TARGET_ATTACK:
		_handle_targeting_input(key, turn_manager)
		return

	match key:
		KEY_UP:
			move_requested.emit(Vector2i(0, -1))
		KEY_DOWN:
			move_requested.emit(Vector2i(0, 1))
		KEY_LEFT:
			move_requested.emit(Vector2i(-1, 0))
		KEY_RIGHT:
			move_requested.emit(Vector2i(1, 0))
		KEY_A:
			_start_attack_targeting()
		KEY_I:
			inventory_requested.emit()
		KEY_SPACE:
			wait_requested.emit()
			turn_manager.consume_action()
		KEY_ESCAPE:
			biome_transition_requested.emit()

# In targeting: frecce = direzione, A/SPACE = conferma (1 solo emit), ESC = annulla.
func _handle_targeting_input(key: int, turn_manager) -> void:
	match key:
		KEY_UP:
			targeting_direction = Vector2i(0, -1)
		KEY_DOWN:
			targeting_direction = Vector2i(0, 1)
		KEY_LEFT:
			targeting_direction = Vector2i(-1, 0)
		KEY_RIGHT:
			targeting_direction = Vector2i(1, 0)
		KEY_A, KEY_SPACE:
			attack_requested.emit(targeting_direction)
			set_input_mode(MODE_MOVE)
		KEY_ESCAPE:
			cancel_targeting()

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

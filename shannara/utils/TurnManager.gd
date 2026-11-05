# TurnManager singleton with deterministic turn system
# Handles Player -> Enemy -> Player cycle, 1 action = 1 turn

class_name TurnManager
extends Node

enum TurnState { PLAYER_TURN, ENEMY_TURN }

var current_state: int = TurnState.PLAYER_TURN
var turn_count: int = 0
var grid_system: Node = null

signal turn_start(new_state: int)
signal turn_end()
signal action_consumed

func _ready() -> void:
	grid_system = get_tree().get_root().find_node("GridSystem", true, false)

func start_player_turn() -> void:
	current_state = TurnState.PLAYER_TURN
	turn_start.emit(TurnState.PLAYER_TURN)

func start_enemy_turn() -> void:
	current_state = TurnState.ENEMY_TURN
	turn_start.emit(TurnState.ENEMY_TURN)

func is_player_turn() -> bool:
	return current_state == TurnState.PLAYER_TURN

func is_enemy_turn() -> bool:
	return current_state == TurnState.ENEMY_TURN

func end_turn() -> void:
	if current_state == TurnState.PLAYER_TURN:
		start_enemy_turn()
	else:
		turn_count += 1
		start_player_turn()
	turn_end.emit()

func consume_action() -> void:
	action_consumed.emit()
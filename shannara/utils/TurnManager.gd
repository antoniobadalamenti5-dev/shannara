# TurnManager singleton with deterministic turn system
# Handles Player -> Enemy -> Player cycle, 1 action = 1 turn

class_name TurnManager
extends Node

enum TurnState { PLAYER_TURN, ENEMY_TURN }

var current_state: int = TurnState.PLAYER_TURN
var turn_count: int = 0
var grid_system: Node = null
var player: Node = null

signal turn_start(new_state: int)
signal turn_end()
signal action_consumed
signal enemy_turn_complete

func _ready() -> void:
	grid_system = get_tree().get_root().find_node("GridSystem", true, false)
	player = get_tree().get_root().find_node("Player", true, false)

func start_player_turn() -> void:
	current_state = TurnState.PLAYER_TURN
	turn_start.emit(TurnState.PLAYER_TURN)

func start_enemy_turn() -> void:
	current_state = TurnState.ENEMY_TURN
	turn_start.emit(TurnState.ENEMY_TURN)
	# Schedule enemy actions
	call_deferred("_process_enemy_turn")

func _process_enemy_turn() -> void:
	"""Process all enemy AI actions. Called after enemy turn starts."""
	if player == null:
		end_turn()
		return

	var enemies := get_tree().get_nodes_in_group("enemies")
	var enemies_array := enemies.duplicate()  # Avoid modification during iteration

	for enemy in enemies_array:
		if enemy != null and enemy.is_alive() == true and enemy.can_act() == true:
			enemy.take_action(player.grid_x, player.grid_y)

	# Signal completion and proceed to player turn
	enemy_turn_complete.emit()
	end_turn()

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
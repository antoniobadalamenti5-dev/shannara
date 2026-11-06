# TurnManager singleton with deterministic turn system
# Handles Player -> Enemy -> Player cycle, 1 action = 1 turn

extends Node

enum TurnState { PLAYER_TURN = 0, ENEMY_TURN = 1 }

var current_state: int = TurnState.PLAYER_TURN
var turn_count: int = 0
var grid_system: Node = null
var player: Node = null
var inventory_paused: bool = false  # When true, blocks enemy turn from starting

signal turn_start(new_state: int)
signal turn_end()
signal action_consumed
signal enemy_turn_complete
signal inventory_closed_for_turn()

func _ready() -> void:
	print("[TurnManager] _ready() called - initializing turn system")
	grid_system = get_node_or_null("/root/GridSystem")
	current_state = 1  # ENEMY_TURN, will be set to PLAYER_TURN by start_player_turn()
	turn_count = 0
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player = players[0]
	print("[TurnManager] _ready() done - current_state=%s, turn_count=%s" % [current_state, turn_count])

# Chiamato dal Player quando entra nell'albero: registro il riferimento.
func register_player(p: Node) -> void:
	player = p

func start_player_turn() -> void:
	print("[TurnManager] start_player_turn() - changing from state %s to PLAYER_TURN" % current_state)
	current_state = TurnState.PLAYER_TURN
	turn_start.emit(TurnState.PLAYER_TURN)

func start_enemy_turn() -> void:
	current_state = TurnState.ENEMY_TURN
	turn_start.emit(TurnState.ENEMY_TURN)
	# Schedule enemy actions
	call_deferred("_process_enemy_turn")

func _process_enemy_turn() -> void:
	"""Process all enemy AI actions. Called after enemy turn starts."""
	if not is_enemy_turn():
		return
	print("[TurnManager] _process_enemy_turn() - player=%s" % player)
	if player == null:
		print("[TurnManager] Player null, ending enemy turn")
		end_turn()
		return

	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	print("[TurnManager] Trovati %d nemici" % enemies.size())
	var enemies_array: Array = enemies.duplicate()  # Avoid modification during iteration

	for enemy in enemies_array:
		if enemy != null and enemy.is_alive() == true:
			print("[TurnManager] Nemico %s can_act=%s, invocazione take_action()" % [enemy.name, enemy.can_act()])
			if enemy.can_act():
				enemy.take_action(player.grid_x, player.grid_y)

	# Signal completion and proceed to player turn
	print("[TurnManager] Enemy turn complete, emitting enemy_turn_complete")
	enemy_turn_complete.emit()
	end_turn()

func is_player_turn() -> bool:
	return current_state == TurnState.PLAYER_TURN

func is_enemy_turn() -> bool:
	return current_state == TurnState.ENEMY_TURN

func end_turn() -> void:
	print("[TurnManager] end_turn() - current_state=%s, inventory_paused=%s" % [current_state, inventory_paused])
	if current_state == TurnState.PLAYER_TURN:
		# Se l'inventory è aperto, attendi che l'utente lo chiuda
		if inventory_paused:
			print("[TurnManager] Inventory aperto, attendo chiusura...")
			return
		print("[TurnManager] switching to ENEMY_TURN")
		start_enemy_turn()
	else:
		turn_count += 1
		print("[TurnManager] switching to PLAYER_TURN (turn_count=%s)" % turn_count)
		start_player_turn()
	turn_end.emit()

func consume_action() -> void:
	print("[TurnManager] consume_action() - current_state=%s, is_player_turn=%s" % [current_state, is_player_turn()])
	action_consumed.emit()
	print("[TurnManager] action_consumed signal emitted")
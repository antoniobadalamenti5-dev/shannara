# GameManager - Main game state orchestrator
# Coordinates turn flow, combat results, and game progression
# Uses autoload pattern compatible with Godot 4.7 Forward+ renderer

extends Node

const TURN_MANAGER_PATH := "/root/TurnManager"
const BIOOME_SYSTEM_PATH := "/root/BiomeSystem"

signal game_started()
signal turn_changed(is_player_turn: bool, turn_count: int)
signal combat_encounter(enemy_type: String, count: int)
signal player_stats_changed(current_hp: int, max_hp: int)
signal game_over(victory: bool)
signal level_transition(biome: int)

var is_game_running: bool = false
var player_ref: Node = null
var active_enemies: Array = []

@onready var turn_manager: Node = get_tree().root.get_node_or_null(TURN_MANAGER_PATH)
@onready var biome_system: Node = get_tree().root.get_node_or_null(BIOOME_SYSTEM_PATH)

func _ready() -> void:
	call_deferred("_post_init")

func _post_init() -> void:
	_connect_turn_manager_signals()

func _connect_turn_manager_signals() -> void:
	if turn_manager != null:
		turn_manager.connect("turn_start", Callable(self, "_on_turn_start"))
		turn_manager.connect("turn_end", Callable(self, "_on_turn_end"))
		turn_manager.connect("action_consumed", Callable(self, "_on_action_consumed"))

func _on_turn_start(new_state: int) -> void:
	if turn_manager == null:
		return
	var is_player_turn_val: bool = turn_manager.current_state == 0
	var tc: int
	if turn_manager.turn_count > 0:
		tc = turn_manager.turn_count
	else:
		tc = 1
	emit_signal("turn_changed", is_player_turn_val, tc)

func _on_turn_end() -> void:
	pass

func _on_action_consumed() -> void:
	pass

func _on_biome_changed(new_biome: int) -> void:
	emit_signal("level_transition", new_biome)

func StartGame() -> bool:
	if turn_manager != null:
		turn_manager.turn_count = 0
		turn_manager.start_player_turn()
	is_game_running = true
	emit_signal("game_started")
	_spawn_initial_encounters()
	return true

func _spawn_initial_encounters() -> void:
	if biome_system == null:
		return
	var biome: int = biome_system.current_biome
	var enemy_count: int = 1
	match biome:
		0:  # FOREST
			enemy_count = 1
		1:  # CAVE
			enemy_count = 2
		2:  # DESERT
			enemy_count = 3
		3:  # ICE
			enemy_count = 2
		4:  # SWAMP
			enemy_count = 3
		_:
			enemy_count = 2
	emit_signal("combat_encounter", "Slime", enemy_count)

func ProcessPlayerAction(action_type: String, dx: int = 0, dy: int = 0) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"message": "",
		"turn_consumed": false
	}
	if turn_manager == null or not (turn_manager.current_state == 0):
		result.message = "Non puoi agire ora"
		return result
	var player: Node = turn_manager.player
	if player == null or not (player is Player):
		result.message = "Nessun giocatore"
		return result
	var p: Player = player as Player
	match action_type:
		"move":
			result = _process_move(p, dx, dy)
		"attack":
			result = _process_attack(p, dx, dy)
		"wait":
			turn_manager.consume_action()
			result.success = true
			result.turn_consumed = true
			result.message = "HaiAttenduto"
		_:
			result.message = "Azione sconosciuta"
	return result

func _process_move(player: Player, dx: int, dy: int) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"message": "",
		"turn_consumed": false
	}
	var moved: bool = player.move_direction(dx, dy)
	if moved:
		result.success = true
		result.turn_consumed = true
		result.message = "Ti sei mosso"
	else:
		result.message = "Movimento non valido"
	return result

func _process_attack(player: Player, dx: int, dy: int) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"message": "",
		"turn_consumed": false,
		"enemy_killed": false
	}
	var attacked: bool = player.attack_direction(dx, dy)
	if attacked:
		result.success = true
		result.turn_consumed = true
		result.message = "Hai attaccato!"
	return result

func CheckVictoryConditions() -> bool:
	if turn_manager == null:
		return false
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var alive_enemies: int = 0
	for enemy in enemies:
		if enemy != null and enemy.is_alive():
			alive_enemies += 1
	return alive_enemies == 0

func CheckGameOver() -> bool:
	if turn_manager == null or turn_manager.player == null:
		return false
	var player: Node = turn_manager.player
	if not (player is Player):
		return false
	var p: Player = player as Player
	if not p.is_alive():
		emit_signal("game_over", false)
		return true
	if CheckVictoryConditions():
		emit_signal("game_over", true)
		return true
	return false

func HandleBiomeCompletion() -> void:
	if biome_system == null:
		return
	biome_system.completed_biomes.append(biome_system.current_biome)
	biome_system.transition_to_next_biome()

func GetGameState() -> Dictionary:
	var state: Dictionary = {
		"turn_count": 0,
		"is_player_turn": false,
		"player_hp": 0,
		"player_max_hp": 100,
		"biome": 0,
		"enemy_count": 0
	}
	if turn_manager != null:
		state.turn_count = turn_manager.turn_count
		state.is_player_turn = turn_manager.current_state == 0
	if turn_manager != null and turn_manager.player != null:
		var player: Node = turn_manager.player as Player
		if player != null:
			state.player_hp = player.current_hp
			state.player_max_hp = player.max_hp
	if biome_system != null:
		state.biome = biome_system.current_biome
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	state.enemy_count = enemies.size()
	return state
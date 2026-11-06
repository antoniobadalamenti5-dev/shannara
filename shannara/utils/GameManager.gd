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
	_connect_turn_manager_signals()

func _connect_turn_manager_signals() -> void:
	var tm = get_tree().root.get_node_or_null("/root/TurnManager")
	if tm == null:
		print("[GameManager] WARNING: TurnManager non trovato per la connettività dei segnali!")
		return
	print("[GameManager] Connettendo segnali a TurnManager")
	tm.connect("turn_start", Callable(self, "_on_turn_start"))
	tm.connect("turn_end", Callable(self, "_on_turn_end"))
	tm.connect("action_consumed", Callable(self, "_on_action_consumed"))
	print("[GameManager] Segnali connessi")

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

# Fine turno: il consumo dell'azione è ciò che chiude il turno del giocatore.
# Il vincolo is_player_turn() NON è decorativo: anche i nemici chiamano
# consume_action() in take_action(), e farli passare di qui ribalterebbe lo
# stato a PLAYER_TURN in mezzo alla fase nemica (il primo slime agirebbe e
# gli altri resterebbero fermi). La fase nemica si chiude da sola con
# TurnManager._process_enemy_turn() -> end_turn().
func _on_action_consumed() -> void:
	print("[GameManager] riceve action_consumed signal!")
	var tm = turn_manager
	if tm != null and tm.is_player_turn():
		print("[GameManager] chiama end_turn()")
		tm.end_turn()
	else:
		print("[GameManager] non è il turno del giocatore, ignoro")

func _on_biome_changed(new_biome: int) -> void:
	emit_signal("level_transition", new_biome)

func StartGame() -> bool:
	print("[GameManager] StartGame() chiamato")
	if turn_manager != null:
		turn_manager.turn_count = 0
		turn_manager.start_player_turn()
	else:
		print("[GameManager] WARNING: turn_manager è null!")
	is_game_running = true
	emit_signal("game_started")
	_spawn_initial_encounters()
	return true

func _spawn_initial_encounters() -> void:
	"""Spawn enemies and items defined by the current biome map."""
	if biome_system == null:
		return

	var biome_data: Dictionary = biome_system.generate_biome_map(biome_system.current_biome)
	var enemy_defs: Array = biome_data.get("enemies", [])
	var item_defs: Array = biome_data.get("items", [])

	var enemy_type_counts: Dictionary = {}
	for ed in enemy_defs:
		var enemy_type: String = ed.get("type", "Slime")
		enemy_type_counts[enemy_type] = enemy_type_counts.get(enemy_type, 0) + 1

	for enemy_type in enemy_type_counts:
		emit_signal("combat_encounter", enemy_type, enemy_type_counts[enemy_type])

	# Spawn enemies into the scene
	var enemy_scenes: Dictionary = {
		"Slime": "res://scenes/Slime.tscn",
		"BossGolem": "res://scenes/BossGolem.tscn"
	}
	for ed in enemy_defs:
		var enemy_type: String = ed.get("type", "Slime")
		var scene_path: String = enemy_scenes.get(enemy_type, "")
		if scene_path.is_empty():
			push_error("[GameManager] Unknown enemy type: %s" % enemy_type)
			continue
		var scene = load(scene_path)
		if scene == null:
			push_error("[GameManager] Could not load enemy scene: %s" % scene_path)
			continue
		var enemy = scene.instantiate()
		enemy.grid_x = ed.get("grid_x", 8)
		enemy.grid_y = ed.get("grid_y", 5)
		enemy.grid_elevation = ed.get("grid_elevation", 0)
		enemy.position = Vector2((enemy.grid_x + 0.5) * 32, (enemy.grid_y + 0.5) * 32)
		add_child(enemy)

		var grid_system = get_tree().root.get_node_or_null("/root/GridSystem")
		if grid_system != null:
			grid_system.set_occupant(enemy.grid_x, enemy.grid_y, enemy.grid_elevation, enemy)

	# Spawn items into the scene
	for id in item_defs:
		var item_type: String = id.get("type", "")
		if item_type == "healing_potion":
			var potion_scene = load("res://scenes/HealingPotion.tscn")
			if potion_scene != null:
				var potion = potion_scene.instantiate()
				potion.grid_x = id.get("grid_x", 6)
				potion.grid_y = id.get("grid_y", 8)
				potion.grid_elevation = id.get("grid_elevation", 0)
				potion.position = Vector2((potion.grid_x + 0.5) * 32, (potion.grid_y + 0.5) * 32)
				add_child(potion)

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
	else:
		result.message = "Nessun nemico adiacente in quella direzione"
	return result

func OpenInventory() -> Dictionary:
	"""Open inventory UI. Returns diagnostic info."""
	var result: Dictionary = {
		"success": true,
		"message": "Inventario aperto",
		"items": {}
	}
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system != null and inventory_system.has_method("active_items"):
		result.items = inventory_system.active_items
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
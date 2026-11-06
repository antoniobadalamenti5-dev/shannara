# Slime enemy class
# Basic dungeon enemy with Idle/Patrol/Hunt/Attack state machine
# Slime is a complete enemy implementation - does not extend a base class
# to avoid class_name resolution issues in Godot 4.7

extends Node2D

class_name Slime

# ---Enemy State Enum---
enum EnemyState { IDLE, PATROL, HUNT, ATTACK }

# ---State Management---
var state: int = EnemyState.IDLE
var patrol_points: Array = []
var patrol_index: int = 0

# ---HP and Position---
var max_hp: int = 20
var current_hp: int = 20
var grid_x: int = 10
var grid_y: int = 10
var grid_elevation: int = 0

func _ready() -> void:
	print("[Slime] _ready() - adding to enemies group")
	add_to_group("enemies")
	# Inizializza punti di pattugliamento (a sinistra del spawn)
	patrol_points = [
		[grid_x - 1, grid_y, 0],
		[grid_x - 1, grid_y + 1, 0],
		[grid_x, grid_y + 1, 0],
		[grid_x + 1, grid_y + 1, 0]
	]
	patrol_index = 0
	print("[Slime] posizione iniziale: (%s, %s)" % [grid_x, grid_y])

func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - abs(amount))
	if current_hp <= 0:
		# Rimuovi dalla griglia e distruggi il nemico
		var gs = get_node("/root/GridSystem")
		if gs != null:
			gs.set_occupant(grid_x, grid_y, grid_elevation, null)
		queue_free()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + abs(amount))

func is_connected_to_grid() -> bool:
	return true

# ---Turn-based Actions---
func can_act() -> bool:
	var tm = get_node("/root/TurnManager")
	if tm == null:
		return false
	return is_alive() and tm.current_state == 1  # ENEMY_TURN = 1

func take_action(target_x: int, target_y: int) -> bool:
	"""Execute slime action with attack priority when adjacent."""
	print("[Slime] take_action() richiesto da TurnManager, can_act=%s" % can_act())
	if not can_act():
		print("[Slime] can_act() = false, abortisco")
		return false

	# Aggiorna lo stato con la POSIZIONE ATTUALE del giocatore (non i parametri target)
	var turn_manager = get_node("/root/TurnManager")
	var player = turn_manager.player
	if player != null:
		update_state(player.grid_x, player.grid_y)
		target_x = player.grid_x  # Usa la posizione corrente
		target_y = player.grid_y
	else:
		update_state(0, 0)  # Fallback se nessun giocatore

	var state_name: String = "IDLE"
	match state:
		0: state_name = "IDLE"
		1: state_name = "PATROL"
		2: state_name = "HUNT"
		3: state_name = "ATTACK"
	print("[Slime] state=%s, distanza al player=%s" % [state_name, abs(grid_x - target_x) + abs(grid_y - target_y)])

	# Attack if adjacent to player
	if player != null and player.is_alive():
		var distance: int = abs(grid_x - player.grid_x) + abs(grid_y - player.grid_y)
		if distance <= 1 and grid_elevation == player.grid_elevation:
			print("[Slime] nemico adiacente, attacco!")
			return _attack_player()

	if state == EnemyState.HUNT:
		print("[Slime] stato HUNT, inizio caccia")
		return _hunt_action(target_x, target_y)
	elif state == EnemyState.PATROL:
		print("[Slime] stato PATROL")
		return _patrol_action()
	elif state == EnemyState.IDLE:
		# IDLE: esegui un piccolo movimento casuale per non rimanere fermo
		print("[Slime] stato IDLE, movimento casuale")
		return _wander_action()
	print("[Slime] nessun'azione possibile, stato=%s" % state_name)
	return false

func _wander_action() -> bool:
	"""Movimento casuale leggero quando non c'è nemico in range."""
	var dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	# Mescola le direzioni per randomizzare
	dirs.shuffle()
	for d in dirs:
		var new_x = grid_x + d.x
		var new_y = grid_y + d.y
		if new_x >= 0 and new_x < 20 and new_y >= 0 and new_y < 20:
			var grid_system = get_node("/root/GridSystem")
			if grid_system.is_cell_walkable(new_x, new_y, 0):
				var success = _attempt_move(new_x, new_y, 0)
				if success:
					return true
	return false

func update_state(player_x: int, player_y: int) -> void:
	"""Slime detects player within distance 3 (slightly less than base Enemy)."""
	var distance: int = abs(grid_x - player_x) + abs(grid_y - player_y)
	if distance <= 3:
		state = EnemyState.HUNT
	elif patrol_points.size() > 0:
		state = EnemyState.PATROL
	else:
		state = EnemyState.IDLE

func get_attack_damage() -> int:
	"""Base slime attack damage."""
	return 3

func _attack_player() -> bool:
	"""Slime attacks adjacent player."""
	var turn_manager = get_node("/root/TurnManager")
	var player = turn_manager.player
	if player == null or not player.is_alive():
		return false

	var combat_resolver = get_node("/root/CombatResolver")
	var result = combat_resolver.resolve_attack(self, player)
	if result.success:
		# NOTA: non si chiama consume_action() qui. Il turno nemico finisce
		# con end_turn() in TurnManager._process_enemy_turn().
		return true
	return false

func _hunt_action(target_x: int, target_y: int) -> bool:
	"""Move toward the player, one step along the shortest legal path."""
	var grid_system = get_node("/root/GridSystem")
	var path: Array = grid_system.find_path(grid_x, grid_y, grid_elevation, target_x, target_y, grid_elevation)
	if path.size() <= 1:
		path = _shortest_path_adjacent_to(grid_system, target_x, target_y)
	if path.size() > 1:
		var next_pos = path[1]
		var success = _attempt_move(next_pos[0], next_pos[1], next_pos[2])
		if success:
			return true
	return false

func _shortest_path_adjacent_to(gs, target_x: int, target_y: int) -> Array:
	var best: Array = []
	var dirs: Array = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for d in dirs:
		var candidate: Array = gs.find_path(grid_x, grid_y, grid_elevation, target_x + d.x, target_y + d.y, grid_elevation)
		if candidate.size() > 1 and (best.is_empty() or candidate.size() < best.size()):
			best = candidate
	return best

func _patrol_action() -> bool:
	"""Move along patrol route or wander randomly if no patrol points."""
	var target = null

	if patrol_points.size() > 0:
		target = patrol_points[patrol_index]
		print("[Slime] patrol: moving to (%d, %d)" % [target[0], target[1]])
	else:
		# Movimento casuale quando non c'è patrol - prova tutte le direzioni
		var dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		# Mescola le direzioni
		dirs.shuffle()
		for d in dirs:
			var new_x = grid_x + d.x
			var new_y = grid_y + d.y
			if new_x >= 0 and new_x < 20 and new_y >= 0 and new_y < 20:
				var grid_system = get_node("/root/GridSystem")
				if grid_system.is_cell_walkable(new_x, new_y, 0):
					target = [new_x, new_y, 0]
					print("[Slime] patrol: wandering to (%d, %d)" % [new_x, new_y])
					break

	if target != null:
		var success = _attempt_move(target[0], target[1], target[2])
		if patrol_points.size() > 0 and success:
			patrol_index = (patrol_index + 1) % patrol_points.size()
		return success
	print("[Slime] patrol: no valid move found")
	return false

func _attempt_move(target_x: int, target_y: int, target_elev: int) -> bool:
	"""Internal validation and execution of enemy movement."""
	var grid_system = get_node("/root/GridSystem")
	if target_x < 0 or target_y < 0 or target_x >= grid_system.GRID_WIDTH or target_y >= grid_system.GRID_HEIGHT:
		return false
	if not grid_system.is_cell_walkable(target_x, target_y, target_elev):
		return false
	grid_system.set_occupant(grid_x, grid_y, grid_elevation, null)
	grid_x = target_x
	grid_y = target_y
	grid_elevation = target_elev
	grid_system.set_occupant(target_x, target_y, target_elev, self)
	# Aggiorna la posizione visiva dello sprite
	position = Vector2((grid_x + 0.5) * 32, (grid_y + 0.5) * 32)
	return true
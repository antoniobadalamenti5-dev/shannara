# BossGolem enemy class
# Large enemy with 3 phases and escalating attack power
# BossGolem is a complete enemy implementation - does not extend a base class
# to avoid class_name resolution issues in Godot 4.7

extends Node2D

class_name BossGolem

# --- Enemy State Enum ---
enum EnemyState { IDLE, PATROL, HUNT, ATTACK }

# --- Boss-specific Properties ---
var phase: int = 1  # 1, 2, or 3
var phase_thresholds: Array = [50, 25]  # HP thresholds for phase transitions

# --- Signals ---
signal phase_changed(new_phase: int)

# --- State Management ---
var state: int = EnemyState.IDLE
var patrol_points: Array = []
var patrol_index: int = 0

# --- HP and Position ---
var max_hp: int = 50
var current_hp: int = 50
var grid_x: int = 15
var grid_y: int = 10
var grid_elevation: int = 0

func _init() -> void:
	state = EnemyState.IDLE

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	# Update phase based on current HP
	_update_phase()

func _update_phase() -> void:
	"""Check HP and transition phases."""
	var new_phase: int = 1
	if current_hp <= phase_thresholds[1]:
		new_phase = 3
	elif current_hp <= phase_thresholds[0]:
		new_phase = 2

	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)

# --- Health System ---
func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - abs(amount))
	_update_phase()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + abs(amount))

# --- Attack System ---
func get_attack_damage() -> int:
	"""Return attack damage based on current phase."""
	match phase:
		1:
			return 5
		2:
			return 8
		3:
			return 12
	return 5

func get_movement_speed() -> float:
	"""Return movement speed multiplier based on phase."""
	match phase:
		1:
			return 1.0
		2:
			return 1.2
		3:
			return 1.4
	return 1.0

func can_act() -> bool:
	var tm = get_node("/root/TurnManager")
	if tm == null:
		return false
	return is_alive() and tm.current_state == 1  # ENEMY_TURN = 1

# --- Turn-based Actions ---
func take_action(target_x: int, target_y: int) -> bool:
	"""Override to use phase-based behavior."""
	if not can_act():
		return false

	update_state(target_x, target_y)

	# Check if player is adjacent - attack first
	var turn_manager = get_node("/root/TurnManager")
	var player = turn_manager.player
	if player != null and player.is_alive():
		var distance: int = abs(grid_x - player.grid_x) + abs(grid_y - player.grid_y)
		if distance <= 1 and grid_elevation == player.grid_elevation:
			return _attack_player()

	if state == EnemyState.HUNT:
		return _hunt_action(target_x, target_y)
	elif state == EnemyState.PATROL:
		return _patrol_action()
	return false

func update_state(player_x: int, player_y: int) -> void:
	var distance: int = abs(grid_x - player_x) + abs(grid_y - player_y)
	if distance <= 2:
		state = EnemyState.HUNT
	elif patrol_points.size() > 0:
		state = EnemyState.PATROL
	else:
		state = EnemyState.IDLE

func _attack_player() -> bool:
	"""Override attack to use phase-based damage."""
	var turn_manager = get_node("/root/TurnManager")
	var player = turn_manager.player
	if player == null or not player.is_alive():
		return false

	# Check adjacency
	var distance: int = abs(grid_x - player.grid_x) + abs(grid_y - player.grid_y)
	if distance <= 1 and grid_elevation == player.grid_elevation:
		var damage: int = get_attack_damage()
		player.take_damage(damage)
		return true
	return false

func _hunt_action(target_x: int, target_y: int) -> bool:
	"""Move toward the player."""
	var grid_system = get_node("/root/GridSystem")
	var path: Array = grid_system.find_path(grid_x, grid_y, grid_elevation, target_x, target_y, grid_elevation)
	if path.size() <= 1:
		path = _shortest_path_adjacent_to(grid_system, target_x, target_y)
	if path.size() > 1:
		var next_pos = path[1]
		var success = _attempt_move(next_pos[0], next_pos[1], next_pos[2])
		return success
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
	"""Move along patrol route."""
	if patrol_points.size() == 0:
		return false
	var target = patrol_points[patrol_index]
	var success = _attempt_move(target[0], target[1], target[2])
	if success:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return true
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
	return true
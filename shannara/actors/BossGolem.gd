# BossGolem enemy class
# Large enemy with 3 phases and escalating attack power

class_name BossGolem
extends Enemy

var phase: int = 1  # 1, 2, or 3
var phase_thresholds: Array = [50, 25]  # HP thresholds for phase transitions

signal phase_changed(new_phase: int)

func _init() -> void:
	max_hp = 50
	current_hp = 50
	grid_x = 15
	grid_y = 10
	grid_elevation = 0
	state = EnemyState.IDLE

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	# Update phase based on current HP
	_update_phase()

func _update_phase() -> void:
	"""Check HP and transition phases."""
	var new_phase := 1
	if current_hp <= phase_thresholds[1]:
		new_phase = 3
	elif current_hp <= phase_thresholds[0]:
		new_phase = 2

	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)

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

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - abs(amount))
	_update_phase()

func _attack_player() -> bool:
	"""Override attack to use phase-based damage."""
	var player := TurnManager.player
	if player == null or not player.is_alive():
		return false

	# Check adjacency
	var distance := abs(grid_x - player.grid_x) + abs(grid_y - player.grid_y)
	if distance <= 1 and grid_elevation == player.grid_elevation:
		var damage := get_attack_damage()
		player.take_damage(damage)
		TurnManager.consume_action()
		return true
	return false

func take_action(target_x: int, target_y: int) -> bool:
	"""Override to use phase-based behavior."""
	if not can_act():
		return false

	update_state(target_x, target_y)

	# Check if player is adjacent - attack first
	var player := TurnManager.player
	if player != null and player.is_alive():
		var distance := abs(grid_x - player.grid_x) + abs(grid_y - player.grid_y)
		if distance <= 1 and grid_elevation == player.grid_elevation:
			return _attack_player()

	if state == EnemyState.HUNT:
		return _hunt_action(target_x, target_y)
	elif state == EnemyState.PATROL:
		return _patrol_action()
	return false

func _hunt_action(target_x: int, target_y: int) -> bool:
	"""Move toward player using A* pathfinding. Phase 3 attacks every turn."""
	var path := GridSystem.find_path(grid_x, grid_y, grid_elevation, target_x, target_y, grid_elevation)
	if path.size() > 1:
		var next_pos := path[1]
		var success := _attempt_move(next_pos[0], next_pos[1], next_pos[2])
		if success:
			TurnManager.consume_action()
			return true
	return false
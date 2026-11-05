# Enemy actor class
# Enemy character with 50 HP, can act during enemy turn
# Basic AI with patrol points and hunt behavior

class_name Enemy
extends ActorController

enum EnemyState { IDLE, PATROL, HUNT, ATTACK }

var state: int = EnemyState.IDLE
var patrol_points: Array = []
var patrol_index: int = 0

func _ready() -> void:
	add_to_group("enemies")

func _init() -> void:
	max_hp = 50
	current_hp = 50
	grid_x = 10
	grid_y = 10
	grid_elevation = 0

func can_act() -> bool:
	return is_alive() and TurnManager.is_enemy_turn()

func update_state(player_x: int, player_y: int) -> void:
	var distance := abs(grid_x - player_x) + abs(grid_y - player_y)
	if distance <= 2:
		state = EnemyState.HUNT
	elif patrol_points.size() > 0:
		state = EnemyState.PATROL
	else:
		state = EnemyState.IDLE

func take_action(target_x: int, target_y: int) -> bool:
	"""Execute enemy action (move or attack). Returns true if action taken."""
	if not can_act():
		return false

	# Update state based on player position
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

func _attack_player() -> bool:
	"""Attack the player if adjacent."""
	var player := TurnManager.player
	if player == null or not player.is_alive():
		return false

	var result := CombatResolver.resolve_attack(self, player)
	if result.success:
		TurnManager.consume_action()
		return true
	return false

func _hunt_action(target_x: int, target_y: int) -> bool:
	"""Move toward player position using A* pathfinding."""
	var path := GridSystem.find_path(grid_x, grid_y, grid_elevation, target_x, target_y, grid_elevation)
	if path.size() > 1:
		var next_pos := path[1]
		var success := _attempt_move(next_pos[0], next_pos[1], next_pos[2])
		if success:
			TurnManager.consume_action()
			return true
	return false

func _patrol_action() -> bool:
	"""Move along patrol route."""
	if patrol_points.size() == 0:
		return false

	var target := patrol_points[patrol_index]
	var success := _attempt_move(target[0], target[1], target[2])
	if success:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		TurnManager.consume_action()
		return true
	return false

func _attempt_move(target_x: int, target_y: int, target_elev: int) -> bool:
	"""Internal validation and execution of enemy movement."""
	if target_x < 0 or target_y < 0 or target_x >= GridSystem.GRID_WIDTH or target_y >= GridSystem.GRID_HEIGHT:
		return false
	if not GridSystem.is_cell_walkable(target_x, target_y, target_elev):
		return false

	GridSystem.set_occupant(grid_x, grid_y, grid_elevation, null)
	grid_x = target_x
	grid_y = target_y
	grid_elevation = target_elev
	GridSystem.set_occupant(target_x, target_y, target_elev, self)
	return true
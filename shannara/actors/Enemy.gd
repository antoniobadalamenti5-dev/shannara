# Enemy actor class
# Enemy character with 50 HP, can act during enemy turn
# Basic AI with patrol points and hunt behavior

extends Node2D
class_name Enemy

enum EnemyState { IDLE, PATROL, HUNT, ATTACK }

var state: int = EnemyState.IDLE
var patrol_points: Array = []
var patrol_index: int = 0

# HP and position state
var max_hp: int = 50
var current_hp: int = 50
var grid_x: int = 10
var grid_y: int = 10
var grid_elevation: int = 0

func _ready() -> void:
	add_to_group("enemies")

func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - abs(amount))

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + abs(amount))

func is_connected_to_grid() -> bool:
	return true

func can_act() -> bool:
	var tm = get_node("/root/TurnManager")
	if tm == null:
		return false
	return is_alive() and tm.current_state == 1  # ENEMY_TURN = 1

func update_state(player_x: int, player_y: int) -> void:
	var distance: int = abs(grid_x - player_x) + abs(grid_y - player_y)
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
	var tm = get_node("/root/TurnManager")
	var player = tm.player
	if player != null and player.is_alive():
		var distance = abs(grid_x - player.grid_x) + abs(grid_y - player.grid_y)
		if distance <= 1 and grid_elevation == player.grid_elevation:
			return _attack_player()
	if state == EnemyState.HUNT:
		return _hunt_action(target_x, target_y)
	elif state == EnemyState.PATROL:
		return _patrol_action()
	return false

func _attack_player() -> bool:
	"""Attack the player if adjacent."""
	print("[Enemy] _attack_player() - player.is_alive=%s" % (player != null and player.is_alive()))
	var tm = get_node("/root/TurnManager")
	var player = tm.player
	if player == null or not player.is_alive():
		return false
	var cr = get_node("/root/CombatResolver")
	var result = cr.resolve_attack(self, player)
	print("[Enemy] Risultato attacco: success=%s, damage=%s" % [result.success, result.damage])
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
		# La cella del player è occupata e quindi non calpestabile: si punta
		# alla cella libera più vicina adiacente al target.
		path = _shortest_path_adjacent_to(grid_system, target_x, target_y)
	if path.size() > 1:
		var next_pos = path[1]
		var success = _attempt_move(next_pos[0], next_pos[1], next_pos[2])
		if success:
			# NOTA: non si chiama consume_action() qui. Il turno nemico finisce
			# con end_turn() in TurnManager._process_enemy_turn().
			return true
	return false

# Cammino minimo verso una cella adiacente al target (il player occupa la
# propria cella, che find_path scarta come destinazione).
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
		# NOTA: non si chiama consume_action() qui. Il turno nemico finisce
		# con end_turn() in TurnManager._process_enemy_turn().
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
	# Aggiorna la posizione visiva (ereditata da classi figlie come Slime)
	if is_instance_valid(self):
		position = Vector2((grid_x + 0.5) * 32, (grid_y + 0.5) * 32)
	return true

func get_attack_damage() -> int:
	return 3  # Base slime attack damage
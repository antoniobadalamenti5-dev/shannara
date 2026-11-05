# Slime enemy class
# Basic dungeon enemy with Idle/Patrol/Hunt/Attack state machine

class_name Slime
extends Enemy

func _init() -> void:
	max_hp = 20
	current_hp = 20
	grid_elevation = 0
	state = EnemyState.IDLE

func get_attack_damage() -> int:
	"""Base slime attack damage."""
	return 3

func update_state(player_x: int, player_y: int) -> void:
	"""Slime detects player within distance 3 (slightly less than base Enemy)."""
	var distance := abs(grid_x - player_x) + abs(grid_y - player_y)
	if distance <= 3:
		state = EnemyState.HUNT
	elif patrol_points.size() > 0:
		state = EnemyState.PATROL
	else:
		state = EnemyState.IDLE

func take_action(target_x: int, target_y: int) -> bool:
	"""Execute slime action with attack priority when adjacent."""
	if not can_act():
		return false

	update_state(target_x, target_y)

	# Attack if adjacent to player
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
	"""Slime attacks adjacent player."""
	var player := TurnManager.player
	if player == null or not player.is_alive():
		return false

	var result := CombatResolver.resolve_attack(self, player)
	if result.success:
		TurnManager.consume_action()
		return true
	return false
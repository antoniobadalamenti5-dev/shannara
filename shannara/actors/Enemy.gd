# Enemy actor class
# Enemy character with 50 HP, can act during enemy turn

class_name Enemy
extends ActorController

enum EnemyState { IDLE, PATROL, HUNT, ATTACK }

var state: int = EnemyState.IDLE
var patrol_points: Array = []
var patrol_index: int = 0

func _init() -> void:
	max_hp = 50
	current_hp = 50

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
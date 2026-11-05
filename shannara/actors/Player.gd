# Player actor class
# Player character with 100 HP, can act during player turn
# Implements input-based movement with turn consumption

class_name Player
extends Node2D

const TILE_SIZE: int = 32

signal moved_to(x: int, y: int, elevation: int)
signal attacked(target_x: int, target_y: int, damage: int)

# HP and position state (previously from ActorController)
var max_hp: int = 100
var current_hp: int = 100
var grid_x: int = 5
var grid_y: int = 5
var grid_elevation: int = 0

func _ready() -> void:
	current_hp = max_hp
	sync_position()
	add_to_group("players")
	var tm = get_node_or_null("/root/TurnManager")
	if tm != null and tm.has_method("register_player"):
		tm.register_player(self)
	# Registra l'occupazione della cella di spawn (invariante griglia:
	# ogni attore vivo è l'occupante della propria cella).
	var gs = get_node_or_null("/root/GridSystem")
	if gs != null:
		gs.set_occupant(grid_x, grid_y, grid_elevation, self)

func sync_position() -> void:
	position = Vector2((grid_x + 0.5) * TILE_SIZE, (grid_y + 0.5) * TILE_SIZE)

func is_alive() -> bool:
	return current_hp > 0

func is_connected_to_grid() -> bool:
	return true

func can_act() -> bool:
	var tm = get_node("/root/TurnManager")
	if tm == null:
		return false
	return is_alive() and tm.current_state == 0  # PLAYER_TURN = 0

func move_direction(dx: int, dy: int) -> bool:
	"""Move player in 4-direction grid. Consumes 1 turn on success."""
	if not can_act():
		return false
	var target_x: int = grid_x + dx
	var target_y: int = grid_y + dy
	var target_elev: int = grid_elevation
	if _attempt_move_to(target_x, target_y, target_elev):
		var tm = get_node("/root/TurnManager")
		tm.consume_action()
		moved_to.emit(target_x, target_y, target_elev)
		return true
	return false

func move_to_elevation(delta_elev: int) -> bool:
	"""Move player up/down elevation (stairs/bridges). Consumes 1 turn."""
	if not can_act():
		return false
	var target_elev: int = grid_elevation + delta_elev
	if _attempt_move_to(grid_x, grid_y, target_elev):
		var tm = get_node("/root/TurnManager")
		tm.consume_action()
		moved_to.emit(grid_x, grid_y, target_elev)
		return true
	return false

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - abs(amount))

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + abs(amount))

func get_attack_damage() -> int:
	return 10  # Base player attack damage

func attack_direction(dx: int, dy: int) -> bool:
	"""Attack adjacent cell in direction. Consumes 1 turn on success."""
	if not can_act():
		return false
	var target_x: int = grid_x + dx
	var target_y: int = grid_y + dy
	var target_elev: int = grid_elevation
	# Find enemy at target position
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != null and enemy.is_alive() and enemy.grid_x == target_x and enemy.grid_y == target_y and enemy.grid_elevation == target_elev:
			var cr = get_node("/root/CombatResolver")
			var result: Dictionary = cr.resolve_attack(self, enemy)
			if result.success:
				var tm = get_node("/root/TurnManager")
				tm.consume_action()
				attacked.emit(target_x, target_y, result.damage)
				return true
	return false

func _attempt_move_to(target_x: int, target_y: int, target_elev: int) -> bool:
	"""Internal validation and execution of movement."""
	var grid_system = get_node("/root/GridSystem")
	# Unica fonte di verità per le regole: passo ortogonale di 1, delta quota <= 1,
	# cella di arrivo calpestabile e libera (Task 2.2/2.3).
	if not grid_system.can_move_to(grid_x, grid_y, grid_elevation, target_x, target_y, target_elev):
		return false
	grid_system.set_occupant(grid_x, grid_y, grid_elevation, null)
	grid_x = target_x
	grid_y = target_y
	grid_elevation = target_elev
	grid_system.set_occupant(target_x, target_y, target_elev, self)
	sync_position()
	return true
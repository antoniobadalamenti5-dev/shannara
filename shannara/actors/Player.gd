# Player actor class
# Player character with 100 HP, can act during player turn
# Implements input-based movement with turn consumption

class_name Player
extends ActorController

signal moved_to(x: int, y: int, elevation: int)

func _init() -> void:
	max_hp = 100
	current_hp = 100
	grid_x = 5
	grid_y = 5
	grid_elevation = 0

func can_act() -> bool:
	return is_alive() and TurnManager.is_player_turn()

func move_direction(dx: int, dy: int) -> bool:
	"""Move player in 4-direction grid. Consumes 1 turn on success."""
	if not can_act():
		return false

	var target_x := grid_x + dx
	var target_y := grid_y + dy
	var target_elev := grid_elevation

	if _attempt_move_to(target_x, target_y, target_elev):
		TurnManager.consume_action()
		moved_to.emit(target_x, target_y, target_elev)
		return true
	return false

func move_to_elevation(delta_elev: int) -> bool:
	"""Move player up/down elevation (stairs/bridges). Consumes 1 turn."""
	if not can_act():
		return false

	var target_elev := grid_elevation + delta_elev

	if _attempt_move_to(grid_x, grid_y, target_elev):
		TurnManager.consume_action()
		moved_to.emit(grid_x, grid_y, target_elev)
		return true
	return false

func _attempt_move_to(target_x: int, target_y: int, target_elev: int) -> bool:
	"""Internal validation and execution of movement."""
	if target_x < 0 or target_y < 0 or target_x >= GridSystem.GRID_WIDTH or target_y >= GridSystem.GRID_HEIGHT:
		return false
	if target_elev < -1 or target_elev > 1:
		return false
	if not GridSystem.is_cell_walkable(target_x, target_y, target_elev):
		return false

	GridSystem.set_occupant(grid_x, grid_y, grid_elevation, null)
	grid_x = target_x
	grid_y = target_y
	grid_elevation = target_elev
	GridSystem.set_occupant(target_x, target_y, target_elev, self)
	return true
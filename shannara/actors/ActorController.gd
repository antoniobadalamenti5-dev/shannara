# ActorController base class for player and enemy entities
# Handles HP, position, movement, and turn-based actions

extends Node2D

# Reference to singletons (lazily resolved via tree)
func _turn_manager() -> Node:
	return get_node_or_null("/root/TurnManager")

func _grid_system() -> Node:
	return get_node_or_null("/root/GridSystem")

@export var max_hp: int = 100
var current_hp: int = max_hp
var grid_x: int = 0
var grid_y: int = 0
var grid_elevation: int = 0

func _ready() -> void:
	current_hp = max_hp

	# Auto-add to appropriate group based on class
	if self is Player:
		add_to_group("players")
	elif self is Enemy:
		add_to_group("enemies")

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - abs(amount))

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + abs(amount))

func is_alive() -> bool:
	return current_hp > 0

func can_act() -> bool:
	var tm = _turn_manager()
	if tm == null:
		return false
	return is_alive() and tm.current_state == 0  # PLAYER_TURN = 0

func move_to(x: int, y: int, elevation: int) -> bool:
	var gs = _grid_system()
	if gs == null:
		return false
	if gs.is_cell_walkable(x, y, elevation):
		gs.set_occupant(grid_x, grid_y, grid_elevation, null)
		grid_x = x
		grid_y = y
		grid_elevation = elevation
		gs.set_occupant(x, y, elevation, self)
		return true
	return false
# ActorController base class for player and enemy entities
# Handles HP, position, movement, and turn-based actions

class_name ActorController
extends Node2D

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
	if TurnManager == null:
		return false
	return TurnManager.current_state == TurnManager.TurnState.PLAYER_TURN

func move_to(x: int, y: int, elevation: int) -> bool:
	if GridSystem.is_cell_walkable(x, y, elevation):
		GridSystem.set_occupant(grid_x, grid_y, grid_elevation, null)
		grid_x = x
		grid_y = y
		grid_elevation = elevation
		GridSystem.set_occupant(x, y, elevation, self)
		return true
	return false
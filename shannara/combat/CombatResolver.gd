# CombatResolver - Deterministic damage formulas and attack resolution
# Stateless utility for combat calculations

extends Node

const MIN_DAMAGE: int = 1
const MAX_DAMAGE: int = 999999
const BASE_DEFENSE: int = 2

# Calculate damage based on attacker power and defender defense
func calculate_damage(attacker_power: int, defender_defense: int, weapon_bonus: int = 0) -> int:
	var base_damage: int = attacker_power - defender_defense
	var total_damage: int = base_damage + weapon_bonus
	return clamp(total_damage, MIN_DAMAGE, MAX_DAMAGE)

# Resolve an attack between attacker and target
func resolve_attack(attacker: Node, target: Node) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"damage": 0,
		"target_killed": false
	}

	# Validate target
	if target == null:
		return result

	if target.has_method("is_alive") and not target.is_alive():
		result.target_killed = true
		return result

	# Check adjacency
	if not _check_adjacent(attacker, target):
		return result

	# Get attack power from attacker
	var attacker_power: int = 10
	if attacker.has_method("get_attack_damage"):
		attacker_power = attacker.get_attack_damage()

	result.success = true
	result.damage = calculate_damage(attacker_power, BASE_DEFENSE)

	# Apply damage to target
	if target.has_method("take_damage"):
		target.take_damage(result.damage)

	result.target_killed = not target.is_alive()

	# Clear grid occupant on death
	if result.target_killed and target.has_method("is_connected_to_grid"):
		var grid_system = get_node("/root/GridSystem")
		grid_system.set_occupant(target.grid_x, target.grid_y, target.grid_elevation, null)

	return result

# Check if two actors are adjacent (Manhattan distance <= 1)
func _check_adjacent(a1: Node, a2: Node) -> bool:
	if a1 == null or a2 == null:
		return false

	var x1: int = 0
	var y1: int = 0
	var x2: int = 0
	var y2: int = 0

	# Check if actors have position properties
	if a1.has_method("is_connected_to_grid"):
		x1 = a1.grid_x
		y1 = a1.grid_y
	else:
		return false

	if a2.has_method("is_connected_to_grid"):
		x2 = a2.grid_x
		y2 = a2.grid_y
	else:
		return false

	return abs(x1 - x2) + abs(y1 - y2) <= 1
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

	print("[CombatResolver] resolve_attack: %s attacca %s" % [attacker.name, target.name])

	# Validate target
	if target == null:
		print("[CombatResolver] Target null!")
		return result

	if target.has_method("is_alive") and not target.is_alive():
		print("[CombatResolver] Target non vivo!")
		result.target_killed = true
		return result

	# Check adjacency
	if not _check_adjacent(attacker, target):
		print("[CombatResolver] Non adiacente!")
		return result

	# Get attack power from attacker
	var attacker_power: int = 10
	if attacker.has_method("get_attack_damage"):
		attacker_power = attacker.get_attack_damage()
	print("[CombatResolver] Attacker power: %d" % attacker_power)

	result.success = true
	result.damage = calculate_damage(attacker_power, BASE_DEFENSE)
	print("[CombatResolver] Danno inflitto: %d" % result.damage)

	# Apply damage to target
	if target.has_method("take_damage"):
		target.take_damage(result.damage)

	result.target_killed = not target.is_alive()
	print("[CombatResolver] Target killed: %s, HP residuo: %d" % [result.target_killed, target.current_hp])

	# Clear grid occupant on death
	if result.target_killed and target.has_method("is_connected_to_grid"):
		var grid_system = get_node("/root/GridSystem")
		grid_system.set_occupant(target.grid_x, target.grid_y, target.grid_elevation, null)

	return result

# Check if two actors are adjacent (Manhattan distance <= 1)
func _check_adjacent(a1: Node, a2: Node) -> bool:
	if a1 == null or a2 == null:
		print("[CombatResolver] _check_adjacent: null actor")
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
		print("[CombatResolver] _check_adjacent: a1 no is_connected_to_grid")
		return false

	if a2.has_method("is_connected_to_grid"):
		x2 = a2.grid_x
		y2 = a2.grid_y
	else:
		print("[CombatResolver] _check_adjacent: a2 no is_connected_to_grid")
		return false

	var distance = abs(x1 - x2) + abs(y1 - y2)
	print("[CombatResolver] _check_adjacent: Player(%d,%d) vs %s(%d,%d) = %d" % [x1, y1, a2.name, x2, y2, distance])
	return distance <= 1
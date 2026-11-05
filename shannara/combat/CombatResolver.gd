# CombatResolver with deterministic damage formulas
# Stateless utility for combat calculations

class_name CombatResolver
extends Resource

const MIN_DAMAGE: int = 1
const MAX_DAMAGE: int = 999999

func calculate_damage(attacker_power: int, defender_defense: int, weapon_bonus: int = 0) -> int:
	var base_damage := attacker_power - defender_defense
	var total_damage := base_damage + weapon_bonus
	return clamp(total_damage, MIN_DAMAGE, MAX_DAMAGE)

func resolve_attack(attacker: ActorController, target: ActorController) -> Dictionary:
	var result := {
		"success": false,
		"damage": 0,
		"target_killed": false
	}

	if target == null or not target.is_alive():
		result.target_killed = true
		return result

	var is_adjacent := abs(attacker.grid_x - target.grid_x) + abs(attacker.grid_y - target.grid_y) <= 1
	if not is_adjacent:
		return result

	result.success = true
	result.damage = calculate_damage(10, 2)  # Base values
	target.take_damage(result.damage)

	result.target_killed = not target.is_alive()
	if result.target_killed:
		# Clear grid occupant on death
		GridSystem.set_occupant(target.grid_x, target.grid_y, target.grid_elevation, null)
	return result
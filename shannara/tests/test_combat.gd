# test_combat.gd - Unit tests for CombatResolver
# Tests damage calculation, attack resolution, adjacency checks

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] CombatResolver")

	var combat_resolver = get_node("/root/CombatResolver")
	var grid_system = get_node("/root/GridSystem")

	# --- calculate_damage: formula base ---
	var damage: int = combat_resolver.calculate_damage(10, 5)
	assert_eq(damage, 5, "10-5=5")

	damage = combat_resolver.calculate_damage(20, 8)
	assert_eq(damage, 12, "20-8=12")

	damage = combat_resolver.calculate_damage(5, 10)
	assert_eq(damage, 1, "negative clamped to MIN_DAMAGE=1")

	damage = combat_resolver.calculate_damage(100, 10)
	assert_eq(damage, 90, "100-10=90")

	# --- calculate_damage: bonus arma e cap ---
	damage = combat_resolver.calculate_damage(10, 5, 3)
	assert_eq(damage, 8, "(10-5)+3=8")

	damage = combat_resolver.calculate_damage(10, 5, 0)
	assert_eq(damage, 5, "no weapon bonus")

	damage = combat_resolver.calculate_damage(10, 5, 999999)
	assert_eq(damage, combat_resolver.MAX_DAMAGE, "damage capped at MAX_DAMAGE")

	# --- resolve_attack: attacco adiacente tra attori reali ---
	var player: Player = Player.new()
	player.grid_x = 5
	player.grid_y = 5

	var enemy: Enemy = Enemy.new()
	enemy.grid_x = 6
	enemy.grid_y = 5

	grid_system.set_occupant(5, 5, 0, player)
	grid_system.set_occupant(6, 5, 0, enemy)

	var result: Dictionary = combat_resolver.resolve_attack(player, enemy)
	assert_true(result.success, "adjacent attack succeeds")
	assert_eq(result.damage, 8, "damage=10-2=8 (base defense=2)")
	assert_eq(enemy.current_hp, 42, "enemy hp 50-8=42 after hit")
	assert_false(result.target_killed, "target survives first hit")
	assert_true(enemy.is_alive(), "enemy alive after hit")

	# --- Colpo finale: HP residui -> morte e rilascio della cella ---
	enemy.current_hp = 5
	result = combat_resolver.resolve_attack(player, enemy)
	assert_true(result.success, "finishing attack succeeds")
	assert_true(result.target_killed, "target_killed=true")
	assert_eq(enemy.current_hp, 0, "enemy hp=0 after kill")
	assert_false(enemy.is_alive(), "enemy dead after kill")
	assert_null(grid_system.get_cell_at(6, 5, 0).occupant, "dead enemy cleared from grid")

	# --- Attacco non adiacente respinto ---
	var far_enemy: Enemy = Enemy.new()
	far_enemy.grid_x = 10
	far_enemy.grid_y = 10
	result = combat_resolver.resolve_attack(player, far_enemy)
	assert_false(result.success, "far attack fails")
	assert_eq(result.damage, 0, "no damage on failed attack")

	# --- Target già morto: nessuna risoluzione ---
	result = combat_resolver.resolve_attack(player, enemy)
	assert_false(result.success, "attack on a corpse fails")
	assert_true(result.target_killed, "corpse reported as killed")

	# --- Target nullo ---
	result = combat_resolver.resolve_attack(player, null)
	assert_false(result.success, "null target fails safely")

	# --- Pulizia: celle libere, poi free (nod fuori albero) ---
	grid_system.set_occupant(5, 5, 0, null)
	player.free()
	enemy.free()
	far_enemy.free()

	print_results()

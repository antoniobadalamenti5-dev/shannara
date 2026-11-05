# Test per CombatResolver
# Verifica formule danno deterministiche

func test_calculate_damage_basic() -> void:
	var damage := CombatResolver.calculate_damage(10, 5)
	assert_eq(damage, 5, "10 power - 5 defense = 5 damage")

func test_calculate_damage_minimum_one() -> void:
	var damage := CombatResolver.calculate_damage(3, 10)
	assert_eq(damage, 1, "Damage should have minimum of 1")

func test_calculate_damage_with_weapon_bonus() -> void:
	var damage := CombatResolver.calculate_damage(10, 5, 3)
	assert_eq(damage, 8, "(10 - 5) + 3 = 8 damage")

func test_calculate_damage_negative_result_clamped() -> void:
	var damage := CombatResolver.calculate_damage(5, 15)
	assert_eq(damage, 1, "Negative damage should clamp to minimum 1")

func test_resolve_attack_adjacent() -> void:
	var attacker := ActorController.new()
	attacker.grid_x = 5
	attacker.grid_y = 5
	attacker.current_hp = 100

	var target := ActorController.new()
	target.grid_x = 6
	target.grid_y = 5
	target.current_hp = 50

	var result := CombatResolver.resolve_attack(attacker, target)
	assert_true(result.success, "Attack should succeed on adjacent target")
	assert_gt(result.damage, 0, "Damage should be positive")
	assert_eq(target.current_hp, 50 - result.damage, "Target HP should decrease")

func test_resolve_attack_not_adjacent() -> void:
	var attacker := ActorController.new()
	attacker.grid_x = 5
	attacker.grid_y = 5

	var target := ActorController.new()
	target.grid_x = 10  # Too far
	target.grid_y = 10

	var result := CombatResolver.resolve_attack(attacker, target)
	assert_false(result.success, "Attack should fail on non-adjacent target")
	assert_eq(result.damage, 0, "No damage should be dealt")

func test_resolve_attack_dead_target() -> void:
	var attacker := ActorController.new()
	attacker.grid_x = 5
	attacker.grid_y = 5

	var target := ActorController.new()
	target.grid_x = 6
	target.grid_y = 5
	target.current_hp = 0  # Already dead

	var result := CombatResolver.resolve_attack(attacker, target)
	assert_false(result.success, "Should not attack dead target")
	assert_true(result.target_killed, "target_killed should be true for dead target")

func test_damage_formula_deterministic() -> void:
	# Same inputs should always produce same output
	for i in range(10):
		var damage1 := CombatResolver.calculate_damage(15, 7, 2)
		var damage2 := CombatResolver.calculate_damage(15, 7, 2)
		assert_eq(damage1, damage2, "Damage should be deterministic")

func test_max_damage_cap() -> void:
	var damage := CombatResolver.calculate_damage(1000000, 0)
	assert_eq(damage, 999999, "Damage should have max cap of 999999")
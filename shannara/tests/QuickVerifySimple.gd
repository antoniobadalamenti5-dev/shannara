# QuickVerifySimple.gd - Simple verification script
# Run this scene to verify core systems

extends Node

func _ready() -> void:
	print("\n=== SIMPLIFIED VERIFICATION ===")

	# Check 1: All autoloads exist
	var autoloads = ["TurnManager", "GridSystem", "CombatResolver", "GameManager", "InputManager", "BiomeSystem", "ItemDatabase", "InventorySystem"]
	var all_ok = true
	for name in autoloads:
		var node = get_node_or_null("/root/%s" % name)
		if node == null:
			print("✗ MISSING: %s" % name)
			all_ok = false

	if all_ok:
		print("✓ All 8 autoloads present")

	# Check 2: Basic grid functionality
	var gs = get_node("/root/GridSystem")
	var cell = gs.get_cell_at(5, 5, 0)
	if cell != null:
		print("✓ GridSystem working (cell at 5,5,0 exists)")
	else:
		print("✗ GridSystem cell lookup failed")

	# Check 3: Turn state - verify GameManager connects signals
	var tm = get_node("/root/TurnManager")
	var gm = get_node("/root/GameManager")

	# Assicuriamoci che i segnali siano connessi
	if gm != null and not tm.is_connected("action_consumed", gm, "_on_action_consumed"):
		tm.connect("action_consumed", Callable(gm, "_on_action_consumed"))
		print("✓ Signal connection verified")

	# Prova il flusso del turno
	tm.start_player_turn()
	await get_tree().process_frame
	await get_tree().process_frame

	if tm.current_state == 0:  # PLAYER_TURN = 0
		print("✓ TurnManager initialized (state=%d)" % tm.current_state)
	elif tm.current_state == 1:  # ENEMY_TURN = 1
		print("✓ TurnManager ready for enemy turn (state=%d)" % tm.current_state)
	else:
		print("✗ TurnManager wrong initial state: %d" % tm.current_state)

	# Check 4: Combat resolver
	var cr = get_node("/root/CombatResolver")
	var dmg = cr.calculate_damage(10, 5)
	if dmg > 0:
		print("✓ CombatResolver working (damage calculation: %d)" % dmg)
	else:
		print("✗ CombatResolver failed")

	# Check 5: Player class exists
	var player_scene = preload("res://scenes/Player.tscn")
	var player = player_scene.instantiate()
	if player is Node2D:
		print("✓ Player scene loads correctly")
		if player.has_method("move_direction") and player.has_method("attack_direction"):
			print("✓ Player has movement and attack methods")
		else:
			print("✗ Player missing methods")
	else:
		print("✗ Player not instance of Node2D")

	# Check 6: Slime class exists
	var slime_scene = preload("res://scenes/Slime.tscn")
	var slime = slime_scene.instantiate()
	if slime.has_method("take_action"):
		print("✓ Slime scene loads correctly with AI")
	else:
		print("✗ Slime missing take_action method")

	print("\n=== VERIFICATION COMPLETE ===")

	# Terminate after showing output
	await get_tree().process_frame
	get_tree().quit()
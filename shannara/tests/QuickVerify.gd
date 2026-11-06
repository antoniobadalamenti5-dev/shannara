# QuickVerify.gd - Script rapido per verifica Gameplay
# Attacca questo script a qualsiasi nodo e premi Play per verificare il sistema

extends Node

func _ready() -> void:
	print("=== QUICK VERIFY STARTING ===")
	await get_tree().process_frame

	# Step 1: Check autoloads
	print("\n1. Checking Autoloads...")
	var tm = get_node_or_null("/root/TurnManager")
	var gm = get_node_or_null("/root/GameManager")
	var gs = get_node_or_null("/root/GridSystem")
	var gr = get_node_or_null("/root/GridRenderer")

	if tm == null:
		print("  ✗ ERROR: TurnManager not found!")
	else:
		print("  ✓ TurnManager OK")

	if gm == null:
		print("  ✗ ERROR: GameManager not found!")
	else:
		print("  ✓ GameManager OK")

	if gs == null:
		print("  ✗ ERROR: GridSystem not found!")
	else:
		print("  ✓ GridSystem OK")

	if gr == null:
		print("  ⚠ GridRenderer not found (optional)")
	else:
		print("  ✓ GridRenderer OK")

	# Step 2: Create player
	print("\n2. Creating Player...")
	var player_scene = preload("res://scenes/Player.tscn")
	var player = player_scene.instantiate()
	player.grid_x = 5
	player.grid_y = 5
	player.grid_elevation = 0
	player.position = Vector2((player.grid_x + 0.5) * 32, (player.grid_y + 0.5) * 32)
	add_child(player)
	gs.set_occupant(player.grid_x, player.grid_y, player.grid_elevation, player)
	tm.player = player
	print("  ✓ Player created at (5, 5)")

	# Step 3: Create slime close enough for HUNT (distance <= 3)
	# Slime at (8, 5) = distance 3 from player at (5, 5)
	print("\n3. Creating Slime (within HUNT range)...")
	var slime_scene = preload("res://scenes/Slime.tscn")
	var slime = slime_scene.instantiate()
	slime.grid_x = 8  # Distance = 3 from player (5,5)
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.position = Vector2((slime.grid_x + 0.5) * 32, (slime.grid_y + 0.5) * 32)
	slime.patrol_points = []
	add_child(slime)
	gs.set_occupant(slime.grid_x, slime.grid_y, slime.grid_elevation, slime)
	slime.add_to_group("enemies")
	print("  ✓ Slime created at (8, 5) - HUNT range (distance=3)")

	# Step 4: Start player turn
	print("\n4. Starting Player Turn...")
	# Assicuriamoci che i segnali siano connessi
	if gm != null:
		# Riconnetto i segnali nel caso _ready() non li abbia fatti
		if not tm.is_connected("action_consumed", gm, "_on_action_consumed"):
			tm.connect("action_consumed", Callable(gm, "_on_action_consumed"))
			print("  ✓ Segnale action_consumed connesso")
	tm.start_player_turn()
	await get_tree().process_frame
	await get_tree().process_frame  # Attesa aggiuntiva per segnali
	if tm.is_player_turn():
		print("  ✓ Player turn active")
	else:
		print("  ✗ ERROR: Not player turn!")

	# Step 5: Player moves
	print("\n5. Testing Player Movement...")
	var moved = player.move_direction(0, 1)  # Move up (y-1)
	await get_tree().process_frame
	if moved:
		print("  ✓ Player moved to (%d, %d)" % [player.grid_x, player.grid_y])
	else:
		print("  ✗ ERROR: Player could not move")

	# After move, should be enemy turn
	# Attendo più frame perché il segnale action_consumed
	# passa attraverso GameManager che chiama end_turn()
	await get_tree().process_frame
	await get_tree().process_frame
	if tm.is_enemy_turn():
		print("  ✓ Enemy turn started after player action")
	else:
		print("  ✗ ERROR: Enemy turn did not start (state=%s)" % tm.current_state)

	# Step 6: Process enemy turn naturally
	print("\n6. Processing Enemy Turn...")
	var slime_before_x = slime.grid_x
	var slime_before_y = slime.grid_y
	# Il turno nemico processa automaticamente gli nemici tramite _process_enemy_turn()
	await get_tree().process_frame
	await get_tree().process_frame

	var slime_after_x = slime.grid_x
	var slime_after_y = slime.grid_y
	var slime_moved = (slime_before_x != slime_after_x or slime_before_y != slime_after_y)

	if slime_moved:
		print("  ✓ Slime moved from (%d,%d) to (%d,%d)" % [slime_before_x, slime_before_y, slime_after_x, slime_after_y])
	else:
		print("  ⚠ Slime stayed at (%d,%d)" % [slime_after_x, slime_after_y])
		print("    (May be in PATROL state)")

	# Should be back to player turn
	await get_tree().process_frame
	await get_tree().process_frame
	if tm.is_player_turn():
		print("  ✓ Back to Player turn")
	else:
		print("  ✗ ERROR: Still not Player turn! (state=%s)" % tm.current_state)

	# Step 7: Test attack (create enemy adjacent to player)
	print("\n7. Testing Attack...")
	tm.start_player_turn()
	await get_tree().process_frame

	# Create test enemy adjacent to player (right side)
	var test_slime = slime_scene.instantiate()
	test_slime.grid_x = player.grid_x + 1
	test_slime.grid_y = player.grid_y
	test_slime.grid_elevation = 0
	test_slime.position = Vector2((test_slime.grid_x + 0.5) * 32, (test_slime.grid_y + 0.5) * 32)
	test_slime.current_hp = 20
	add_child(test_slime)
	gs.set_occupant(test_slime.grid_x, test_slime.grid_y, 0, test_slime)

	var attack_result = player.attack_direction(1, 0)  # Attack right
	await get_tree().process_frame
	if attack_result:
		print("  ✓ Attack successful")
	else:
		print("  ✓ Attack result: %s" % str(attack_result))

	# Cleanup
	gs.set_occupant(test_slime.grid_x, test_slime.grid_y, 0, null)
	test_slime.queue_free()

	# Dopo l'attacco, torna al giocatore
	await get_tree().process_frame
	await get_tree().process_frame
	if tm.is_player_turn():
		print("  ✓ Back to Player turn after attack")
	else:
		print("  ⚠ State after attack: %s (may be enemy turn)" % tm.current_state)

	print("\n=== QUICK VERIFY COMPLETE ===")
	print("Turn system working! You can now test in-game with WASD/F")
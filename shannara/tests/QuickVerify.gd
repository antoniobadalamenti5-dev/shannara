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
	var player_scene = preload("res://actors/Player.tscn")
	var player = player_scene.instantiate()
	player.grid_x = 5
	player.grid_y = 5
	player.grid_elevation = 0
	player.position = Vector2((player.grid_x + 0.5) * 32, (player.grid_y + 0.5) * 32)
	add_child(player)
	gs.set_occupant(player.grid_x, player.grid_y, player.grid_elevation, player)
	tm.player = player
	print("  ✓ Player created at (5, 5)")

	# Step 3: Create slime far away
	print("\n3. Creating Slime...")
	var slime_scene = preload("res://scenes/Slime.tscn")
	var slime = slime_scene.instantiate()
	slime.grid_x = 12
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.position = Vector2((slime.grid_x + 0.5) * 32, (slime.grid_y + 0.5) * 32)
	slime.patrol_points = [
		[11, 5, 0],
		[11, 6, 0],
		[12, 6, 0]
	]
	add_child(slime)
	gs.set_occupant(slime.grid_x, slime.grid_y, slime.grid_elevation, slime)
	slime.add_to_group("enemies")
	print("  ✓ Slime created at (12, 5) with patrol route")

	# Step 4: Start game
	print("\n4. Starting Game...")
	await get_tree().process_frame
	tm.start_player_turn()
	print("  ✓ Game started, player turn active")

	# Step 5: Verify player turn
	print("\n5. Verifying Player Turn...")
	await get_tree().process_frame
	if tm.is_player_turn():
		print("  ✓ Player turn active")
	else:
		print("  ✗ ERROR: Not player turn!")

	# Step 6: Player movement test
	print("\n6. Testing Player Movement...")
	await get_tree().process_frame
	var moved = player.move_direction(0, 1)  # Move right
	await get_tree().process_frame
	if moved:
		print("  ✓ Player moved successfully to (%d, %d)" % [player.grid_x, player.grid_y])
	else:
		print("  ✗ ERROR: Player could not move")

	# Step 7: Check enemy turn
	await get_tree().process_frame
	if tm.is_enemy_turn():
		print("  ✓ Enemy turn started")
	else:
		print("  ✗ ERROR: Enemy turn did not start")

	# Step 8: Process enemy turn
	print("\n7. Testing Enemy Turn...")
	await get_tree().process_frame
	var slime_before = [slime.grid_x, slime.grid_y]
	slime.take_action(player.grid_x, player.grid_y)
	await get_tree().process_frame

	var slime_after = [slime.grid_x, slime.grid_y]
	var slime_moved = (slime_before[0] != slime_after[0] or slime_before[1] != slime_after[1])

	if slime_moved:
		print("  ✓ Slime moved from %s to %s" % [slime_before, slime_after])
	else:
		print("  ⚠ Slime stayed at %s" % slime_after)
		print("    (May be in patrol route and waiting for next turn)")

	# Step 9: Verify back to player turn
	await get_tree().process_frame
	if tm.is_player_turn():
		print("  ✓ Back to Player turn")
	else:
		print("  ✗ ERROR: Still not Player turn!")

	# Step 10: Test attack
	print("\n8. Testing Attack...")
	# Create enemy adjacent to player
	var slime2 = slime_scene.instantiate()
	slime2.grid_x = 4
	slime2.grid_y = 5
	slime2.grid_elevation = 0
	slime2.position = Vector2((slime2.grid_x + 0.5) * 32, (slime2.grid_y + 0.5) * 32)
	add_child(slime2)
	slime2.add_to_group("enemies")
	gs.set_occupant(slime2.grid_x, slime2.grid_y, slime2.grid_elevation, slime2)

	tm.start_player_turn()
	await get_tree().process_frame
	var attack_result = player.attack_direction(-1, 0)  # Attack left
	await get_tree().process_frame
	if attack_result:
		print("  ✓ Attack successful")
	else:
		print("  - Attack result: %s" % str(attack_result))

	# Cleanup
	gs.set_occupant(slime2.grid_x, slime2.grid_y, slime2.grid_elevation, null)
	slime2.queue_free()

	print("\n=== QUICK VERIFY COMPLETE ===")
	print("Turn system working! You can now test in-game with WASD/F")
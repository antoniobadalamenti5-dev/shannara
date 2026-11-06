# run_slime_test.gd - Script per testare movimento Slime
# Da incollare in un nodo qualsiasi e premere Play

extends Node

func _ready() -> void:
	print("=== SLIME MOVEMENT TEST ===")
	await get_tree().process_frame

	# Setup
	var gs = get_node("/root/GridSystem")
	var tm = get_node("/root/TurnManager")
	var slime_scene = preload("res://scenes/Slime.tscn")
	var player_scene = preload("res://actors/Player.tscn")

	# Crea player
	var player = player_scene.instantiate()
	player.grid_x = 5
	player.grid_y = 5
	add_child(player)
	gs.set_occupant(5, 5, 0, player)
	tm.player = player

	# Crea slime
	var slime = slime_scene.instantiate()
	slime.grid_x = 12
	slime.grid_y = 5
	slime.grid_elevation = 0
	slime.patrol_points = [[11, 5, 0], [11, 6, 0], [12, 6, 0]]
	add_child(slime)
	gs.set_occupant(12, 5, 0, slime)
	slime.add_to_group("enemies")

	await get_tree().process_frame

	# Test 1: Slime inizialmente distante
	print("\nTest 1: Slime distante (distanza 7)")
	tm.start_player_turn()
	slime.update_state(player.grid_x, player.grid_y)
	print("  Stato slime: %s (IDLE=%d, PATROL=%d, HUNT=%d, ATTACK=%d)" %
		[slime.state, slime.EnemyState.IDLE, slime.EnemyState.PATROL, slime.EnemyState.HUNT, slime.EnemyState.ATTACK])

	# Test 2: Slime entra in HUNT
	print("\nTest 2: Slime entra in HUNT (dopo movimenti player)")
	for i in range(4):
		player.move_direction(1, 0)
		tm.end_turn()
		tm.start_enemy_turn()
		var dist = abs(slime.grid_x - player.grid_x) + abs(slime.grid_y - player.grid_y)
		print("  Move %d: player=(%d,%d), distanza=%d, slime in stato %s" %
			[i+1, player.grid_x, player.grid_y, dist, slime.state])
		tm.end_turn()

	# Test 3: Slime si muove
	print("\nTest 3: Slime si muove in HUNT")
	tm.start_enemy_turn()
	var before_x = slime.grid_x
	var before_y = slime.grid_y
	var moved = slime.take_action(player.grid_x, player.grid_y)
	print("  Prima: (%d, %d), Dopo: (%d, %d), Mosso: %s" %
		[before_x, before_y, slime.grid_x, slime.grid_y, moved])

	# Test 4: Attack
	print("\nTest 4: Attacco quando adiacente")
	tm.end_turn()
	tm.start_player_turn()
	while abs(slime.grid_x - player.grid_x) + abs(slime.grid_y - player.grid_y) > 1:
		player.move_direction(1, 0)
		tm.end_turn()
		tm.start_enemy_turn()

	print("  Ora adiacente! Player: (%d,%d), Slime: (%d,%d)" %
		[player.grid_x, player.grid_y, slime.grid_x, slime.grid_y])

	# Cleanup
	gs.set_occupant(player.grid_x, player.grid_y, 0, null)
	gs.set_occupant(slime.grid_x, slime.grid_y, 0, null)
	player.queue_free()
	slime.queue_free()

	print("\n=== TEST COMPLETE ===")
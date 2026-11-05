# test_elevation.gd - Unit tests for elevation system (Task 2.3)
# Tests elevation layers, transition rules, moat/bridge/plateau layout

extends TestSuite

func run_tests() -> void:
	print("\n[TEST] Elevation")

	var grid_system = get_node("/root/GridSystem")

	# --- Il campo elevation coincide con l'indice di layer (invariante 2.3) ---
	for elev in [-1, 0, 1]:
		var cell: GridCell = grid_system.get_cell_at(10, 10, elev)
		assert_not_null(cell, "layer %d exists" % elev)
		if cell != null:
			assert_eq(cell.elevation, elev, "layer %d cell.elevation matches index" % elev)

	# --- Default: solo il piano (0) è calpestabile, sotto/ sopra no ---
	assert_true(grid_system.is_cell_walkable(15, 15, 0), "floor default walkable")
	assert_false(grid_system.is_cell_walkable(15, 15, 1), "elev +1 not walkable unless placed")
	assert_false(grid_system.is_cell_walkable(15, 15, -1), "elev -1 not walkable unless placed")

	# --- Fossato a colonna x=13: fondo calpestabile, superficie spuntoni ---
	assert_true(grid_system.is_cell_walkable(13, 5, -1), "moat floor walkable")
	assert_false(grid_system.is_cell_walkable(13, 5, 0), "moat spikes not walkable")

	# --- Ponte a y=10 attraversa gli spuntoni ---
	assert_true(grid_system.is_cell_walkable(13, 10, 0), "bridge over moat walkable")

	# --- Piattaforma rialzata (x3..7, y3..7) attiva solo su layer 1 ---
	var plateau: GridCell = grid_system.get_cell_at(5, 5, 1)
	assert_not_null(plateau, "plateau layer exists")
	assert_true(plateau.walkable, "plateau walkable at +1")
	assert_true(grid_system.is_cell_walkable(5, 5, 0), "ground under plateau still walkable")

	# --- Regole di transizione quota ---
	assert_true(grid_system.can_move_to(5, 5, 0, 5, 5, 1), "step up in place (stairs) allowed")
	assert_true(grid_system.can_move_to(5, 5, 1, 5, 5, 0), "step down in place allowed")
	# Passo laterale CON cambio quota di 1 è ammesso (bordo piattaforma):
	assert_true(grid_system.can_move_to(2, 5, 0, 3, 5, 1), "side step with +1 elevation allowed")
	# Passo laterale SENZA supporto (cambio a vuoto) resta vincolato alla
	# calpestabilità della cella d'arrivo:
	assert_false(grid_system.can_move_to(10, 10, 0, 11, 10, 1), "side step to non-walkable +1 rejected")
	# Delta di 2 quote sempre vietato (-1 -> +1)
	assert_false(grid_system.can_move_to(13, 5, -1, 13, 5, 1), "2-level jump rejected")
	# Fossa -> piano adiacente via spuntoni? No (spuntoni non calpestabili),
	# ma il fondo fossa può risalire sul bordo:
	assert_true(grid_system.can_move_to(13, 5, -1, 12, 5, 0), "climb out of moat to side allowed")

	# --- get_neighbors rispetta i limiti di quota ---
	var neighbors: Array = grid_system.get_neighbors(13, 5, -1)  # sul fondo del fossato
	var saw_above: bool = false
	var saw_below: bool = false
	for n in neighbors:
		assert_gte(n[2], -1, "neighbor elevation >= -1")
		assert_lte(n[2], 1, "neighbor elevation <= 1")
		if n[2] == 1: saw_above = true
		if n[2] == -2: saw_below = true
	assert_false(saw_below, "no neighbors below -1")
	# Sopra il fondo c'è la cella a quota 0 con spuntoni: non deve comparire
	for n in neighbors:
		if n[0] == 13 and n[1] == 5:
			assert_neq(n[2], 0, "spikes above moat floor not in neighbors")

	# --- find_path usa le transizioni di quota: fondo fossato -> cima piattaforma ---
	var path: Array = grid_system.find_path(13, 5, -1, 5, 5, 1)
	assert_true(path.size() > 0, "cross-elevation path found")
	if path.size() > 0:
		assert_eq(path[0], [13, 5, -1], "path starts in moat")
		assert_eq(path[path.size() - 1], [5, 5, 1], "path ends on plateau")
		var ok := true
		for i in range(path.size() - 1):
			var a: Array = path[i]
			var b: Array = path[i + 1]
			if not grid_system.can_move_to(a[0], a[1], a[2], b[0], b[1], b[2]):
				ok = false
		assert_true(ok, "cross-elevation path uses only legal steps")

	print_results()

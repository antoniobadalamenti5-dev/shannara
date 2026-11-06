extends SceneTree

const TESTS: Array = [
	{"file": "res://tests/test_setup.gd", "name": "Setup", "phase": "phase1"},
	{"file": "res://tests/test_grid_cell.gd", "name": "GridCell", "phase": "phase2"},
	{"file": "res://tests/test_grid_system.gd", "name": "GridSystem", "phase": "phase2"},
	{"file": "res://tests/test_movement.gd", "name": "Movement", "phase": "phase2"},
	{"file": "res://tests/test_elevation.gd", "name": "Elevation", "phase": "phase2"},
	{"file": "res://tests/test_input_manager.gd", "name": "InputManager", "phase": "phase2"},
	{"file": "res://tests/test_input_wiring.gd", "name": "InputWiring", "phase": "phase2"},
	{"file": "res://tests/test_turn_manager.gd", "name": "TurnManager", "phase": "phase3"},
	{"file": "res://tests/test_player.gd", "name": "Player", "phase": "phase3"},
	{"file": "res://tests/test_enemy_ai.gd", "name": "EnemyAI", "phase": "phase3"},
	{"file": "res://tests/test_turn_cycle.gd", "name": "TurnCycle", "phase": "phase3"},
	{"file": "res://tests/test_turn_flow.gd", "name": "TurnFlow", "phase": "phase3"},
	{"file": "res://tests/test_gameplay_simple.gd", "name": "GameplaySimple", "phase": "phase3"},
	{"file": "res://tests/test_combat.gd", "name": "Combat", "phase": "phase4"},
	{"file": "res://tests/test_combat_flow.gd", "name": "CombatFlow", "phase": "phase4"},
	{"file": "res://tests/test_inventory.gd", "name": "Inventory", "phase": "phase5"},
	{"file": "res://tests/test_inventory_ui.gd", "name": "InventoryUI", "phase": "phase5"},
	{"file": "res://tests/test_biome.gd", "name": "Biome", "phase": "phase6"},
	{"file": "res://tests/test_combat_integration.gd", "name": "CombatIntegration", "phase": "phase4"},
]

var _filter: String = "all"
var _host: Node = null
var _summary: Array = []
var _totals := {"ran": 0, "passed": 0, "failed": 0}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_filter = args[0].to_lower()
	# Carica una scena vuota: senza un albero scene attivo i percorsi assoluti
	# get_node("/root/GridSystem") falliscono, e gli autoload non sono singleton
	# di Engine (sono script GDScript), quindi Engine.get_singleton non li vede.
	change_scene_to_file("res://tests/TestHost.tscn")


func _process(_delta: float) -> bool:
	if _host == null:
		_host = current_scene
		if _host == null:
			return false
	_run_suite()
	return true


func _run_suite() -> void:
	print("\n" + "=".repeat(64))
	print(" SHANNARA TEST SUITE   filtro=%s" % _filter)
	print("=".repeat(64))

	for t in TESTS:
		if _filter == "all" or t.phase == _filter:
			_run_one(t)

	_print_results()


# Contatori azzerati per file: così il "Results:" stampato dal test stesso
# riguarda solo quel file, e il riepilogo finale soma i parziali.
func _run_one(entry: Dictionary) -> void:
	print("\n---- %s ----" % entry.name)
	TestSuite.reset()

	var script = load(entry.file)
	if script == null:
		_record(entry.name, 0, 0, 1, "script non caricabile")
		return

	var instance = script.new()
	if instance == null:
		_record(entry.name, 0, 0, 1, "script.new() fallito")
		return

	instance.name = entry.name
	_host.add_child(instance)

	if instance.has_method("run_tests"):
		instance.run_tests()
	else:
		TestSuite.failed += 1
		print("  ✗ FAIL: run_tests() mancante")

	_host.remove_child(instance)
	instance.free()

	var res: Dictionary = TestSuite.get_results()
	_record(entry.name, res.total, res.passed, res.failed, "")


func _record(name: String, ran: int, passed: int, failed: int, note: String) -> void:
	_summary.append({"name": name, "ran": ran, "passed": passed, "failed": failed, "note": note})
	_totals.ran += ran
	_totals.passed += passed
	_totals.failed += failed


func _print_results() -> void:
	print("\n" + "=".repeat(64))
	print(" RIEPILOGO")
	print("=".repeat(64))
	var any_failed := false
	for row in _summary:
		if row.failed > 0:
			any_failed = true
		var status := "OK  " if row.failed == 0 else "FAIL"
		var line := " %s %-16s %3d/%3d" % [status, row.name, row.passed, row.ran]
		if row.note != "":
			line += "  <- %s" % row.note
		print(line)
	print("-".repeat(64))
	print(" TOTALI: %d passed, %d failed, %d assertions" % [_totals.passed, _totals.failed, _totals.ran])
	if any_failed:
		print(" ✗ TEST FALLITI")
	else:
		print(" ✓ TUTTI I TEST PASSED")
	print("=".repeat(64))

	quit(1 if _totals.failed > 0 else 0)

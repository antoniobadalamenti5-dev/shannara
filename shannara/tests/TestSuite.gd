# TestSuite.gd - Framework di asserzione per i test di Shannara
# Le asserzioni sono static: lo stato è condiviso e il runner lo azzera con reset().
# I test accedono agli autoload con get_node("/root/NomeAutoload"): funziona perché
# il runner (run_tests.gd) carica prima TestHost.tscn, rendendo attivo l'albero scene.

extends Node

class_name TestSuite

static var passed: int = 0
static var failed: int = 0
static var total: int = 0

static func reset() -> void:
	passed = 0
	failed = 0
	total = 0

static func assert_eq(actual, expected, msg: String = "") -> bool:
	total += 1
	if actual == expected:
		passed += 1
		if msg != "":
			print("  ✓ PASS: %s" % msg)
		return true
	else:
		failed += 1
		print("  ✗ FAIL: %s - Expected: %s, Got: %s" % [msg, expected, actual])
		return false

static func assert_true(cond: bool, msg: String = "") -> bool:
	return assert_eq(cond, true, msg)

static func assert_false(cond: bool, msg: String = "") -> bool:
	return assert_eq(cond, false, msg)

static func assert_not_null(val, msg: String = "") -> bool:
	return assert_eq(val != null, true, msg)

static func assert_null(val, msg: String = "") -> bool:
	return assert_eq(val, null, msg)

static func assert_is_type(obj: Object, type_name: String, msg: String = "") -> bool:
	if obj == null:
		return assert_false(true, msg + " (was null)")
	return assert_eq(obj.get_class(), type_name, msg)

static func assert_neq(actual, expected, msg: String = "") -> bool:
	total += 1
	if actual != expected:
		passed += 1
		if msg != "":
			print("  ✓ PASS: %s" % msg)
		return true
	else:
		failed += 1
		print("  ✗ FAIL: %s - Expected != %s, Got: %s" % [msg, expected, actual])
		return false

static func assert_lte(actual, expected, msg: String = "") -> bool:
	total += 1
	if actual <= expected:
		passed += 1
		if msg != "":
			print("  ✓ PASS: %s" % msg)
		return true
	else:
		failed += 1
		print("  ✗ FAIL: %s - Expected <= %s, Got: %s" % [msg, expected, actual])
		return false

static func assert_gte(actual, expected, msg: String = "") -> bool:
	total += 1
	if actual >= expected:
		passed += 1
		if msg != "":
			print("  ✓ PASS: %s" % msg)
		return true
	else:
		failed += 1
		print("  ✗ FAIL: %s - Expected >= %s, Got: %s" % [msg, expected, actual])
		return false

static func assert_gt(actual, expected, msg: String = "") -> bool:
	total += 1
	if actual > expected:
		passed += 1
		if msg != "":
			print("  ✓ PASS: %s" % msg)
		return true
	else:
		failed += 1
		print("  ✗ FAIL: %s - Expected > %s, Got: %s" % [msg, expected, actual])
		return false

static func print_results() -> void:
	"""Print test results summary for this test file"""
	var total_results = total
	var passed_results = passed
	var failed_results = failed
	var success_rate: float = (float(passed_results) / float(total_results) * 100.0) if total_results > 0 else 0.0
	print("  Results: %d/%d passed (%.1f%%)" % [passed_results, total_results, success_rate])

static func get_results() -> Dictionary:
	return {
		"passed": passed,
		"failed": failed,
		"total": total,
		"success": failed == 0
	}
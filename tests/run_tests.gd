extends SceneTree
## Headless CLI automated test runner for Godot 4.3.
## Usage: godot --headless --path . -s res://tests/run_tests.gd
## Runs the Milestone 1 contract suite and the Milestone 2 core-loop suite.
## Exit code 0 = all passed, 1 = any failure.

const CoreTestsScript = preload("res://tests/test_core_contracts.gd")
const M2TestsScript = preload("res://tests/test_m2.gd")

func _initialize() -> void:
	var suites := [
		["M1 core contracts", CoreTestsScript],
		["M2 core loop", M2TestsScript],
	]
	var total_passed: int = 0
	var total_failed: int = 0
	var all_failures: Array = []
	print("=== Territory Capture Headless Test Suite ===")
	for entry in suites:
		var suite = entry[1].new()
		var res: Dictionary = suite.run_all()
		print("[%s] Passed: %d | Failed: %d" % [entry[0], res["passed"], res["failed"]])
		total_passed += res["passed"]
		total_failed += res["failed"]
		for err in res["failures"]:
			all_failures.append("[%s] %s" % [entry[0], err])
	print("Total Passed: %d | Total Failed: %d" % [total_passed, total_failed])
	if total_failed > 0:
		for err in all_failures:
			print("  [FAIL] ", err)
		quit(1)
		return
	print("ALL TESTS PASSED.")
	quit(0)

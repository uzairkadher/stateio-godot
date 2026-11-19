extends SceneTree
## Headless CLI automated test runner for Godot 4.3.
## Usage: godot --headless --path . -s res://tests/run_tests.gd

const CoreTestsScript = preload("res://tests/test_core_contracts.gd")

func _initialize() -> void:
	print("=== Territory Capture (Milestone 1) Headless Test Suite ===")
	var suite := CoreTestsScript.new()
	var res: Dictionary = suite.run_all()
	print("Passed: %d | Failed: %d" % [res["passed"], res["failed"]])
	if res["failed"] > 0:
		for err in res["failures"]:
			print("  [FAIL] ", err)
		quit(1)
		return
	print("ALL TESTS PASSED.")
	quit(0)

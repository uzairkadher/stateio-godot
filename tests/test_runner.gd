extends SceneTree
## Headless Godot 4.3 CLI Test Runner.
## Run on desktop: godot --headless --path . -s res://tests/test_runner.gd

func _init() -> void:
	print("=== Frontier Command — Headless Test Suite ===")
	var suites := [
		["CoreContracts", Callable(TestCoreContracts, "run")],
		["MapLoader", Callable(TestMapLoader, "run")],
		["Population", Callable(TestPopulation, "run")],
		["TroopSending", Callable(TestTroopSending, "run")],
		["Movement", Callable(TestMovement, "run")],
		["CombatCapture", Callable(TestCombatCapture, "run")],
		["BotAI", Callable(TestBotAI, "run")],
		["SpecialMechanics", Callable(TestSpecialMechanics, "run")],
		["MatchLifecycle", Callable(TestMatchLifecycle, "run")],
		["SaveAndConfigs", Callable(TestSaveAndConfigs, "run")],
		["BotSoakScenarios", Callable(TestBotSoakScenarios, "run")],
	]

	var total_passed: int = 0
	var total_failed: int = 0
	for entry in suites:
		var name_str: String = entry[0]
		var fn: Callable = entry[1]
		var helper := TestHelpers.new()
		fn.call(helper)
		total_passed += helper.checks_passed
		total_failed += helper.failures.size()
		if helper.failures.is_empty():
			print("[PASS] %s (%d assertions)" % [name_str, helper.checks_passed])
		else:
			print("[FAIL] %s (%d passed, %d failed)" % [name_str, helper.checks_passed, helper.failures.size()])
			for f in helper.failures:
				print("   - " + f)

	print("=== Summary: %d passed, %d failed ===" % [total_passed, total_failed])
	quit(0 if total_failed == 0 else 1)

class_name TestHelpers
extends RefCounted
## Lightweight assertion & fixture utilities for headless Godot 4.3 unit/integration tests.

var failures: Array[String] = []
var checks_passed: int = 0

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		checks_passed += 1
	else:
		failures.append("ASSERT_TRUE FAILED: " + msg)

func assert_false(cond: bool, msg: String) -> void:
	assert_true(not cond, msg)

func assert_eq(actual, expected, msg: String) -> void:
	if actual == expected:
		checks_passed += 1
	else:
		failures.append("ASSERT_EQ FAILED (%s): expected=%s actual=%s" % [msg, str(expected), str(actual)])

func assert_near(actual: float, expected: float, tol: float, msg: String) -> void:
	if absf(actual - expected) <= tol:
		checks_passed += 1
	else:
		failures.append("ASSERT_NEAR FAILED (%s): expected=%.4f actual=%.4f" % [msg, expected, actual])

static func make_minimal_map(buildings: Array) -> Dictionary:
	return {
		"schema_version": 1,
		"map_id": "test_map",
		"display_name": "Test Arena",
		"stage_number": 1,
		"default_difficulty": "normal",
		"pixels_per_unit": 100.0,
		"grid_cell_size": 0.5,
		"camera": {"bounds": {"min_x": -5.0, "max_x": 5.0, "min_y": -5.0, "max_y": 5.0}},
		"buildings": buildings,
	}

static func make_engine_with_map(buildings: Array, difficulty: String = "normal") -> SimulationEngine:
	var eng := SimulationEngine.new()
	var gp := MapLoader.load_json_file("res://data/balance/gameplay_config.json")
	var mc := MapLoader.load_json_file("res://data/balance/mechanics_config.json")
	eng.configure(gp, mc)
	eng.load_match(make_minimal_map(buildings), difficulty)
	eng.start_immediately()
	return eng

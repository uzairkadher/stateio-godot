class_name TestMapLoader
extends RefCounted

static func run(t: TestHelpers) -> void:
	var paths: Array[String] = MapLoader.list_map_paths()
	t.assert_true(paths.size() >= 5, "At least 5 maps available in data/maps/")
	for p in paths:
		var m: Dictionary = MapLoader.load_map(p)
		t.assert_false(m.has("_error"), "Map loads cleanly: " + p)
		var states: Array[BuildingState] = MapLoader.build_states_from_map(m)
		t.assert_true(states.size() >= 10, "Map has >= 10 buildings: " + p)

	# Duplicate building ID must fail validation
	var invalid := TestHelpers.make_minimal_map([
		{"id": "dup", "position": {"x": 0, "y": 0}, "owner_id": 1, "initial_population": 10},
		{"id": "dup", "position": {"x": 2, "y": 0}, "owner_id": 2, "initial_population": 10},
	])
	var check := MapLoader.validate_map_dict(invalid)
	t.assert_false(check["ok"], "Duplicate building IDs fail validation")

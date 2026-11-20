class_name TestSaveAndConfigs
extends RefCounted

static func run(t: TestHelpers) -> void:
	var gp := MapLoader.load_json_file("res://data/balance/gameplay_config.json")
	var mc := MapLoader.load_json_file("res://data/balance/mechanics_config.json")
	var bp := MapLoader.load_json_file("res://data/bots/bot_presets.json")
	t.assert_false(gp.has("_error"), "gameplay_config.json parses")
	t.assert_false(mc.has("_error"), "mechanics_config.json parses")
	t.assert_false(bp.has("_error"), "bot_presets.json parses")
	t.assert_true(bp.get("presets", {}).has("easy"), "Easy preset exists")
	t.assert_true(bp.get("presets", {}).has("normal"), "Normal preset exists")
	t.assert_true(bp.get("presets", {}).has("hard"), "Hard preset exists")

	var sm := SaveManager.new("user://test_save_v1.json")
	sm.record_match_result("stage_01_savanna_basin", 1, true, 42.5, 8)
	t.assert_eq(int(sm.data["stats"]["wins"]), 1, "Win recorded")
	t.assert_eq(int(sm.data["progression"]["unlocked_stage"]), 2, "Stage 2 unlocked")

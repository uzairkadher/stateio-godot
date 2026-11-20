class_name TestTroopSending
extends RefCounted

static func run(t: TestHelpers) -> void:
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 1, "initial_population": 20, "population_cap": 50},
		{"id": "b1", "position": {"x": 5.0, "y": 0.0}, "owner_id": 2, "initial_population": 20, "population_cap": 50},
	])

	# 50% send
	var cmd50 := SendCommand.new(GameEnums.OwnerId.PLAYER, ["p1"], "b1", 0.5, "cmd_50")
	var res50 := eng.submit_command(cmd50)
	t.assert_true(res50["accepted"], "50% send accepted")
	t.assert_eq(res50["total_sent"], 10, "50% of 20 = 10")
	t.assert_eq(eng.state.get_building("p1").population, 10, "Source deducted once to 10")

	# Duplicate command ID must be rejected without re-deducting
	var dup := eng.submit_command(cmd50)
	t.assert_false(dup["accepted"], "Duplicate command_id rejected")
	t.assert_eq(eng.state.get_building("p1").population, 10, "No double deduction on duplicate")

	# 1% send sends minimum 1 unit
	var cmd1 := SendCommand.new(GameEnums.OwnerId.PLAYER, ["p1"], "b1", 0.01, "cmd_1")
	var res1 := eng.submit_command(cmd1)
	t.assert_eq(res1["total_sent"], 1, "1% sends at least 1 unit")
	t.assert_eq(eng.state.get_building("p1").population, 9, "Remaining pop = 9")

	# 100% send with duplicate source IDs in same command must deduct only once
	var cmd100 := SendCommand.new(GameEnums.OwnerId.PLAYER, ["p1", "p1"], "b1", 1.0, "cmd_100")
	var res100 := eng.submit_command(cmd100)
	t.assert_eq(res100["total_sent"], 9, "100% sends remaining 9 once")
	t.assert_eq(eng.state.get_building("p1").population, 0, "Source now 0")

	# Zero-population send rejected
	var cmd0 := SendCommand.new(GameEnums.OwnerId.PLAYER, ["p1"], "b1", 1.0, "cmd_0")
	var res0 := eng.submit_command(cmd0)
	t.assert_false(res0["accepted"], "Zero-pop send rejected")

	# Invalid ownership send rejected
	var bad_owner := SendCommand.new(GameEnums.OwnerId.PLAYER, ["b1"], "p1", 1.0, "cmd_bad")
	t.assert_false(eng.submit_command(bad_owner)["accepted"], "Cannot send from enemy building")

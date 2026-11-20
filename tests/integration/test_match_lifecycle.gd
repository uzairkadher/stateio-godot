class_name TestMatchLifecycle
extends RefCounted

static func run(t: TestHelpers) -> void:
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 1, "initial_population": 40},
		{"id": "b1", "position": {"x": 1.0, "y": 0.0}, "owner_id": 2, "initial_population": 5},
	])
	# Player eliminates last bot -> WIN
	eng.submit_command(SendCommand.new(GameEnums.OwnerId.PLAYER, ["p1"], "b1", 1.0, "win_cmd"))
	for _i in range(60):
		eng.step_fixed(0.05)
		if eng.state.phase == GameEnums.MatchPhase.ENDED:
			break
	t.assert_eq(eng.state.phase, GameEnums.MatchPhase.ENDED, "Match ended on elimination")
	t.assert_eq(eng.state.outcome, GameEnums.MatchOutcome.WIN, "Player achieved WIN")

	# Restart resets every state cleanly without leaks
	var restart_res := eng.restart_match()
	t.assert_true(restart_res["ok"], "Restart succeeded")
	eng.start_immediately()
	t.assert_eq(eng.state.phase, GameEnums.MatchPhase.PLAYING, "Restart returns to PLAYING")
	t.assert_eq(eng.state.outcome, GameEnums.MatchOutcome.NONE, "Outcome reset")
	t.assert_eq(eng.state.tick_count, 0, "Tick count reset to 0")
	t.assert_eq(eng.state.troop_groups.size(), 0, "Troop groups cleared")
	t.assert_eq(eng.state.get_building("b1").owner_id, GameEnums.OwnerId.BOT_1, "Bot ownership restored")

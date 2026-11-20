class_name TestBotAI
extends RefCounted

static func run(t: TestHelpers) -> void:
	var presets := MapLoader.load_json_file("res://data/bots/bot_presets.json")
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": -4.0, "y": 0.0}, "owner_id": 1, "initial_population": 20},
		{"id": "n1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 0, "initial_population": 5},
		{"id": "b1", "position": {"x": 3.0, "y": 0.0}, "owner_id": 2, "initial_population": 30},
	])
	var bots := BotController.new()
	bots.setup_bots(eng.state.active_factions, presets, "hard")

	var issued: int = 0
	for _i in range(40):
		eng.step_fixed(0.05)
		var cmds := bots.tick(eng.get_snapshot(), 0.05)
		for c in cmds:
			var res := eng.submit_command(c)
			t.assert_true(res["accepted"], "Bot only emits valid SendCommands")
			issued += 1
	t.assert_true(issued >= 1, "Bot expands/attacks instead of staying idle")

class_name TestBotSoakScenarios
extends RefCounted
## Reproducible headless soak test verifying Stage 1 simulation stability and determinism.

static func run(t: TestHelpers) -> void:
	var map_data := MapLoader.load_map("res://data/maps/stage_01_savanna_basin.json")
	var gp := MapLoader.load_json_file("res://data/balance/gameplay_config.json")
	var mc := MapLoader.load_json_file("res://data/balance/mechanics_config.json")
	var bp := MapLoader.load_json_file("res://data/bots/bot_presets.json")

	# Run two identical 10-second simulations and verify exact deterministic population match
	var snap_a := _run_short_sim(map_data, gp, mc, bp, 200)
	var snap_b := _run_short_sim(map_data, gp, mc, bp, 200)
	t.assert_eq(snap_a.tick_count, snap_b.tick_count, "Deterministic tick count")
	t.assert_eq(snap_a.faction_power, snap_b.faction_power, "Deterministic faction power after 200 ticks")

static func _run_short_sim(map_data: Dictionary, gp: Dictionary, mc: Dictionary, bp: Dictionary, ticks: int) -> SimSnapshot:
	var eng := SimulationEngine.new()
	eng.configure(gp, mc)
	eng.load_match(map_data, "normal")
	eng.start_immediately()
	var bots := BotController.new()
	bots.setup_bots(eng.state.active_factions, bp, "normal")
	for _i in range(ticks):
		eng.step_fixed(0.05)
		var cmds := bots.tick(eng.get_snapshot(), 0.05)
		for c in cmds:
			eng.submit_command(c)
	return eng.get_snapshot()

class_name TestCombatCapture
extends RefCounted

static func run(t: TestHelpers) -> void:
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 1, "initial_population": 30},
		{"id": "n1", "position": {"x": 1.0, "y": 0.0}, "owner_id": 0, "initial_population": 10},
		{"id": "b1", "position": {"x": 5.0, "y": 0.0}, "owner_id": 2, "initial_population": 25},
	])
	# Neutral capture (15 vs 10 -> player captures with 5 remaining)
	var g1 := TroopGroupState.new()
	g1.id = 1
	g1.owner_id = GameEnums.OwnerId.PLAYER
	g1.target_id = "n1"
	g1.amount = 15
	eng.combat_system.resolve_arrivals(eng.state, [g1])
	var n1: BuildingState = eng.state.get_building("n1")
	t.assert_eq(n1.owner_id, GameEnums.OwnerId.PLAYER, "Neutral captured by stronger force")
	t.assert_eq(n1.population, 5, "Surviving attackers = 5")

	# Defender wins on tie (25 vs 25 -> tie_goes_to_defender)
	var g2 := TroopGroupState.new()
	g2.id = 2
	g2.owner_id = GameEnums.OwnerId.PLAYER
	g2.target_id = "b1"
	g2.amount = 25
	eng.combat_system.resolve_arrivals(eng.state, [g2])
	var b1: BuildingState = eng.state.get_building("b1")
	t.assert_eq(b1.owner_id, GameEnums.OwnerId.BOT_1, "Tie keeps defender owner")
	t.assert_eq(b1.population, 0, "Zero pop after exact tie")

	# Simultaneous arrivals sorted deterministically by group id
	var sim_a := TroopGroupState.new()
	sim_a.id = 10
	sim_a.owner_id = GameEnums.OwnerId.PLAYER
	sim_a.target_id = "b1"
	sim_a.amount = 12
	var sim_b := TroopGroupState.new()
	sim_b.id = 11
	sim_b.owner_id = GameEnums.OwnerId.BOT_1
	sim_b.target_id = "b1"
	sim_b.amount = 4
	eng.combat_system.resolve_arrivals(eng.state, [sim_b, sim_a])
	t.assert_eq(b1.owner_id, GameEnums.OwnerId.PLAYER, "Deterministic ID order: ID 10 captures, ID 11 attacks down to 8")
	t.assert_eq(b1.population, 8, "12 - 4 = 8 remaining")

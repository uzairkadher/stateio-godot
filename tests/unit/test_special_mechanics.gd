class_name TestSpecialMechanics
extends RefCounted

static func run(t: TestHelpers) -> void:
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 1, "initial_population": 40, "mechanic_type": "propaganda"},
		{"id": "sh", "position": {"x": 2.0, "y": 0.0}, "owner_id": 2, "initial_population": 10, "mechanic_type": "shield"},
		{"id": "af", "position": {"x": 4.0, "y": 0.0}, "owner_id": 0, "initial_population": 5, "mechanic_type": "additional_fighters"},
		{"id": "sp", "position": {"x": 1.0, "y": 0.0}, "owner_id": 0, "initial_population": 5, "mechanic_type": "speed_zone"},
	])

	# Shield absorbs damage before population
	var sh: BuildingState = eng.state.get_building("sh")
	t.assert_near(sh.shield_hp, 50.0, 0.01, "Shield initialized to 50 HP")
	var after_dmg: float = eng.mechanics_system.modify_incoming_damage(eng.state, sh, GameEnums.OwnerId.PLAYER, 30.0)
	t.assert_near(after_dmg, 0.0, 0.01, "Shield absorbs 30 damage completely")
	t.assert_near(sh.shield_hp, 20.0, 0.01, "Shield reduced to 20 HP")

	# Propaganda boosts spawn rate by +50%
	var p1: BuildingState = eng.state.get_building("p1")
	var rate: float = eng.population_system.get_effective_spawn_rate(p1)
	t.assert_near(rate, 1.5, 0.05, "Propaganda boosts own spawn rate to 1.5/s")

	# Speed zone boosts movement speed by +50%
	var grp := TroopGroupState.new()
	grp.position = Vector2(1.0, 0.0)
	var spd_mult: float = eng.mechanics_system.get_speed_multiplier_for_group(eng.state, grp)
	t.assert_near(spd_mult, 1.5, 0.05, "Speed zone applies +50% multiplier")

	# Additional fighters awards +50 once on capture
	var af: BuildingState = eng.state.get_building("af")
	eng.mechanics_system.on_building_captured(eng.state, af, 0, GameEnums.OwnerId.PLAYER)
	t.assert_eq(af.population, 55, "Additional fighters adds +50 on first capture")
	eng.mechanics_system.on_building_captured(eng.state, af, 1, GameEnums.OwnerId.BOT_1)
	t.assert_eq(af.population, 55, "One-time additional fighters does not re-trigger")

	# Reinforcement activation & per-level limit
	var r1 := eng.request_reinforcement(GameEnums.OwnerId.PLAYER, "p1")
	t.assert_true(r1["ok"], "First reinforcement succeeds")
	var r2 := eng.request_reinforcement(GameEnums.OwnerId.PLAYER, "p1")
	t.assert_false(r2["ok"], "Second reinforcement blocked by max_requests_per_level=1")

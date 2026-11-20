class_name TestPopulation
extends RefCounted

static func run(t: TestHelpers) -> void:
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 1, "initial_population": 10, "population_cap": 15, "spawn_rate": 1.0},
		{"id": "n1", "position": {"x": 3.0, "y": 0.0}, "owner_id": 0, "initial_population": 5, "population_cap": 50, "spawn_rate": 1.0},
		{"id": "b1", "position": {"x": 6.0, "y": 0.0}, "owner_id": 2, "initial_population": 0, "population_cap": 50, "spawn_rate": 2.0, "upgrade_level": 2},
	])
	var p1: BuildingState = eng.state.get_building("p1")
	var n1: BuildingState = eng.state.get_building("n1")
	var b1: BuildingState = eng.state.get_building("b1")

	# Initial population & neutral non-growth
	t.assert_eq(p1.population, 10, "Initial player pop")
	for _i in range(60): # 3.0 seconds at 0.05s
		eng.step_fixed(0.05)
	t.assert_eq(p1.population, 13, "Player grows +3 in 3.0s at 1.0/s")
	t.assert_eq(n1.population, 5, "Neutral does not grow at 0.0/s")
	t.assert_true(b1.population >= 6, "Upgraded bot grows faster from 0 pop")

	# Cap enforcement
	for _i in range(100):
		eng.step_fixed(0.05)
	t.assert_eq(p1.population, 15, "Population respects soft cap 15")

	# Pause halts growth
	eng.set_paused(true)
	var before_pause: int = b1.population
	for _i in range(40):
		eng.step_fixed(0.05)
	t.assert_eq(b1.population, before_pause, "Pause stops growth")
	eng.set_paused(false)

	# Never negative on over-deduction
	var deducted: int = eng.population_system.deduct_population(n1, 999, true)
	t.assert_eq(deducted, 5, "Deduct capped to available pop")
	t.assert_eq(n1.population, 0, "Population never goes negative")
	t.assert_true(n1.block_timer > 0.0, "Deduction triggers 0.5s block timer")

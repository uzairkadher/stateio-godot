class_name TestMovement
extends RefCounted

static func run(t: TestHelpers) -> void:
	var eng := TestHelpers.make_engine_with_map([
		{"id": "p1", "position": {"x": 0.0, "y": 0.0}, "owner_id": 1, "initial_population": 10},
		{"id": "p2", "position": {"x": 3.5, "y": 0.0}, "owner_id": 1, "initial_population": 5},
		{"id": "b1", "position": {"x": 8.0, "y": 0.0}, "owner_id": 2, "initial_population": 10},
	])
	eng.submit_command(SendCommand.new(GameEnums.OwnerId.PLAYER, ["p1"], "p2", 0.5, "move_1"))
	t.assert_eq(eng.state.troop_groups.size(), 1, "One wave spawned immediately")
	var start_x: float = eng.state.troop_groups[0].position.x
	eng.step_fixed(0.25)
	t.assert_true(eng.state.troop_groups[0].position.x > start_x, "Group advances over time")

	# Run until arrival (~1.0s for 3.5u at 3.5 u/s)
	for _i in range(30):
		eng.step_fixed(0.05)
	t.assert_eq(eng.state.troop_groups.size(), 0, "Arrived group cleaned up")
	t.assert_true(eng.state.get_building("p2").population >= 10, "Friendly reinforcement arrived")

	# Invalid destination handling
	var orphan := TroopGroupState.new()
	orphan.id = 999
	orphan.owner_id = GameEnums.OwnerId.PLAYER
	orphan.target_id = "nonexistent_building"
	orphan.amount = 5
	eng.state.troop_groups.append(orphan)
	eng.step_fixed(0.05)
	t.assert_true(orphan.is_eliminated, "Group with invalid target eliminated safely")

extends RefCounted
## Automated unit tests for locked Milestone 1 src/core/ contracts.

const Enums = preload("res://src/core/enums.gd")
const EventBusScript = preload("res://src/core/event_bus.gd")
const GameStateManagerScript = preload("res://src/core/game_state_manager.gd")
const MatchStateScript = preload("res://src/core/match_state.gd")
const SendCommandScript = preload("res://src/core/send_command.gd")
const SimSnapshotScript = preload("res://src/core/sim_snapshot.gd")
const ConfigLoaderScript = preload("res://src/core/config_loader.gd")

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		failures.append(msg)
		push_error("FAIL: " + msg)

func run_all() -> Dictionary:
	_test_enums()
	_test_game_state_fsm_and_events()
	_test_send_command_validation()
	_test_match_state_and_snapshot_isolation()
	_test_config_loader()
	_test_core_layer_purity()
	return {"passed": passed, "failed": failed, "failures": failures}

func _test_enums() -> void:
	_assert_true(Enums.FactionId.NEUTRAL == 0, "FactionId.NEUTRAL must be 0")
	_assert_true(Enums.FactionId.PLAYER == 1, "FactionId.PLAYER must be 1")
	_assert_true(Enums.ObjectiveType.SKIRMISH == 10, "ObjectiveType.SKIRMISH must be 10")
	_assert_true(Enums.GameState.BOOT == 0, "GameState.BOOT must be 0")

func _test_game_state_fsm_and_events() -> void:
	var bus := EventBusScript.new()
	var seen: Array = []
	bus.match_state_changed.connect(func(o: int, n: int): seen.append([o, n]))
	var fsm := GameStateManagerScript.new(bus)

	_assert_true(fsm.current_state == Enums.GameState.BOOT, "FSM starts in BOOT")
	_assert_true(not fsm.transition_to(Enums.GameState.PLAYING), "BOOT -> PLAYING must be rejected")
	_assert_true(fsm.transition_to(Enums.GameState.PRE_START), "BOOT -> PRE_START allowed")
	_assert_true(fsm.transition_to(Enums.GameState.PLAYING), "PRE_START -> PLAYING allowed")
	_assert_true(fsm.is_simulation_active(), "Simulation active only in PLAYING")
	_assert_true(fsm.transition_to(Enums.GameState.PAUSED), "PLAYING -> PAUSED allowed")
	_assert_true(not fsm.is_simulation_active(), "Simulation inactive in PAUSED")
	_assert_true(fsm.transition_to(Enums.GameState.PLAYING), "PAUSED -> PLAYING allowed")
	_assert_true(fsm.transition_to(Enums.GameState.VICTORY), "PLAYING -> VICTORY allowed")
	_assert_true(seen.size() == 5, "EventBus must receive exactly 5 valid state transitions")

func _test_send_command_validation() -> void:
	var valid_cmd := SendCommandScript.new(Enums.FactionId.PLAYER, PackedInt32Array([1, 2]), 3, 0.5, 10)
	_assert_true(valid_cmd.is_valid(), "Valid multi-source command passes")

	var neutral_cmd := SendCommandScript.new(Enums.FactionId.NEUTRAL, PackedInt32Array([1]), 2, 1.0, 10)
	_assert_true(not neutral_cmd.is_valid(), "Neutral faction cannot issue SendCommand")

	var self_target := SendCommandScript.new(Enums.FactionId.PLAYER, PackedInt32Array([1, 2]), 2, 1.0, 10)
	_assert_true(not self_target.is_valid(), "Source matching target must be rejected")

	var empty_src := SendCommandScript.new(Enums.FactionId.PLAYER, PackedInt32Array(), 2, 1.0, 10)
	_assert_true(not empty_src.is_valid(), "Empty source list must be rejected")

func _test_match_state_and_snapshot_isolation() -> void:
	var state := MatchStateScript.new()
	state.reset("stage_01", Enums.ObjectiveType.SKIRMISH)
	var b1 := MatchStateScript.BuildingState.new()
	b1.id = 1
	b1.owner = Enums.FactionId.PLAYER
	b1.population = 15
	b1.position = Vector2(100.0, 200.0)
	state.add_building(b1)

	var snap := SimSnapshotScript.from_match_state(state)
	_assert_true(snap.buildings.size() == 1, "Snapshot contains 1 building")
	_assert_true(snap.get_faction_building_ids(Enums.FactionId.PLAYER).size() == 1, "Player owns 1 building")

	# Mutating copy returned by snapshot must NOT mutate MatchState
	var copy_dict := snap.get_building_copy(1)
	copy_dict["population"] = 999
	_assert_true(state.get_building(1).population == 15, "Snapshot mutation must not affect MatchState")

	state.reset("stage_02")
	_assert_true(state.buildings.is_empty(), "MatchState.reset clears all buildings")

func _test_config_loader() -> void:
	var cfg := ConfigLoaderScript.load_json_dict()
	_assert_true(ConfigLoaderScript.validate_gameplay_config(cfg), "gameplay_config.json schema is valid")
	_assert_true(int(cfg["sending"]["units_per_wave"]) == 5, "units_per_wave defaults to 5")
	_assert_true(is_equal_approx(float(cfg["population"]["block_population_seconds"]), 0.5), "block_population_seconds == 0.5")

func _test_core_layer_purity() -> void:
	var core_files := [
		"res://src/core/enums.gd",
		"res://src/core/event_bus.gd",
		"res://src/core/game_state_manager.gd",
		"res://src/core/match_state.gd",
		"res://src/core/send_command.gd",
		"res://src/core/sim_snapshot.gd",
		"res://src/core/config_loader.gd",
	]
	var forbidden := ["extends Node", "extends Control", "extends CanvasItem", "Sprite2D", "Camera2D", "Label"]
	for path in core_files:
		var f := FileAccess.open(path, FileAccess.READ)
		_assert_true(f != null, "Core file readable: " + path)
		if f != null:
			var txt := f.get_as_text()
			f.close()
			for tok in forbidden:
				_assert_true(txt.find(tok) == -1, "Core file %s must not reference %s" % [path, tok])

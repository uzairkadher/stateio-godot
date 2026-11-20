class_name TestCoreContracts
extends RefCounted

static func run(t: TestHelpers) -> void:
	# SendCommand validation
	var bad_neutral := SendCommand.new(GameEnums.OwnerId.NEUTRAL, ["b1"], "b2", 1.0)
	t.assert_false(bad_neutral.is_structurally_valid(), "Neutral cannot issue SendCommand")

	var bad_ratio := SendCommand.new(GameEnums.OwnerId.PLAYER, ["b1"], "b2", 0.0)
	t.assert_false(bad_ratio.is_structurally_valid(), "Zero ratio command invalid")

	var good_cmd := SendCommand.new(GameEnums.OwnerId.PLAYER, ["b1"], "b2", 0.5, "c1")
	t.assert_true(good_cmd.is_structurally_valid(), "Valid player SendCommand")

	# GameStateManager legal & illegal transitions
	var bus := EventBus.new()
	var gsm := GameStateManager.new(bus)
	var ms := MatchState.new()
	t.assert_false(gsm.transition_to(GameEnums.MatchPhase.ENDED, ms), "MENU -> ENDED must be rejected")
	t.assert_true(gsm.transition_to(GameEnums.MatchPhase.PRE_START, ms), "MENU -> PRE_START allowed")
	t.assert_true(gsm.transition_to(GameEnums.MatchPhase.PLAYING, ms), "PRE_START -> PLAYING allowed")
	t.assert_true(gsm.transition_to(GameEnums.MatchPhase.PAUSED, ms), "PLAYING -> PAUSED allowed")
	t.assert_true(ms.is_paused, "PAUSED sets MatchState.is_paused")
	t.assert_true(gsm.transition_to(GameEnums.MatchPhase.PLAYING, ms), "PAUSED -> PLAYING allowed")
	t.assert_false(ms.is_paused, "Resuming clears MatchState.is_paused")

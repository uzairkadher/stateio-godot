class_name GameStateManager
extends RefCounted
## Explicit finite-state machine guarding MatchPhase transitions.
## Enforces legal transitions: MENU <-> MAP_SELECT -> PRE_START -> PLAYING <-> PAUSED -> ENDED -> MENU/PRE_START.

var current_phase: int = GameEnums.MatchPhase.MENU
var event_bus: EventBus = null

const ALLOWED_TRANSITIONS: Dictionary = {
	GameEnums.MatchPhase.MENU: [
		GameEnums.MatchPhase.MAP_SELECT,
		GameEnums.MatchPhase.PRE_START,
	],
	GameEnums.MatchPhase.MAP_SELECT: [
		GameEnums.MatchPhase.MENU,
		GameEnums.MatchPhase.PRE_START,
	],
	GameEnums.MatchPhase.PRE_START: [
		GameEnums.MatchPhase.PLAYING,
		GameEnums.MatchPhase.MENU,
		GameEnums.MatchPhase.MAP_SELECT,
	],
	GameEnums.MatchPhase.PLAYING: [
		GameEnums.MatchPhase.PAUSED,
		GameEnums.MatchPhase.ENDED,
		GameEnums.MatchPhase.PRE_START,
		GameEnums.MatchPhase.MENU,
	],
	GameEnums.MatchPhase.PAUSED: [
		GameEnums.MatchPhase.PLAYING,
		GameEnums.MatchPhase.PRE_START,
		GameEnums.MatchPhase.MENU,
		GameEnums.MatchPhase.ENDED,
	],
	GameEnums.MatchPhase.ENDED: [
		GameEnums.MatchPhase.PRE_START,
		GameEnums.MatchPhase.MAP_SELECT,
		GameEnums.MatchPhase.MENU,
	],
}

func _init(p_event_bus: EventBus = null) -> void:
	event_bus = p_event_bus

func can_transition(to_phase: int) -> bool:
	if to_phase == current_phase:
		return true
	var allowed: Array = ALLOWED_TRANSITIONS.get(current_phase, [])
	return allowed.has(to_phase)

func transition_to(to_phase: int, match_state: MatchState = null) -> bool:
	if not can_transition(to_phase):
		return false
	var prev: int = current_phase
	current_phase = to_phase
	if match_state != null:
		match_state.phase = to_phase
		match_state.is_paused = (to_phase == GameEnums.MatchPhase.PAUSED)
	if event_bus != null and prev != to_phase:
		event_bus.emit_event("phase_changed", {"from": prev, "to": to_phase})
	return true

func force_reset(match_state: MatchState = null) -> void:
	var prev: int = current_phase
	current_phase = GameEnums.MatchPhase.MENU
	if match_state != null:
		match_state.phase = current_phase
		match_state.is_paused = false
	if event_bus != null and prev != current_phase:
		event_bus.emit_event("phase_changed", {"from": prev, "to": current_phase})

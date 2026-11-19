class_name GameStateManager
extends RefCounted
## Strict finite state machine governing match lifecycle transitions.
## Pure RefCounted — zero Godot Node or UI dependencies.

const Enums = preload("res://src/core/enums.gd")
const BusScript = preload("res://src/core/event_bus.gd")

const ALLOWED_TRANSITIONS := {
	Enums.GameState.BOOT: [Enums.GameState.MENU, Enums.GameState.PRE_START],
	Enums.GameState.MENU: [Enums.GameState.PRE_START],
	Enums.GameState.PRE_START: [Enums.GameState.PLAYING, Enums.GameState.MENU],
	Enums.GameState.PLAYING: [Enums.GameState.PAUSED, Enums.GameState.VICTORY, Enums.GameState.DEFEAT, Enums.GameState.PRE_START],
	Enums.GameState.PAUSED: [Enums.GameState.PLAYING, Enums.GameState.PRE_START, Enums.GameState.MENU],
	Enums.GameState.VICTORY: [Enums.GameState.PRE_START, Enums.GameState.MENU],
	Enums.GameState.DEFEAT: [Enums.GameState.PRE_START, Enums.GameState.MENU],
}

var current_state: int = Enums.GameState.BOOT
var _event_bus: BusScript

func _init(event_bus: BusScript = null) -> void:
	_event_bus = event_bus

func can_transition_to(next_state: int) -> bool:
	if next_state == current_state:
		return false
	var allowed: Array = ALLOWED_TRANSITIONS.get(current_state, [])
	return allowed.has(next_state)

func transition_to(next_state: int) -> bool:
	if not can_transition_to(next_state):
		return false
	var old_state: int = current_state
	current_state = next_state
	if _event_bus != null:
		_event_bus.emit_match_state_changed(old_state, next_state)
	return true

func is_simulation_active() -> bool:
	return current_state == Enums.GameState.PLAYING

func reset_to_boot() -> void:
	current_state = Enums.GameState.BOOT

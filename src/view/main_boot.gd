extends Node2D
## Milestone 1 minimal runnable boot scene.
## Verifies locked src/core/ contracts, config loading, and portrait framing.
## Intentionally contains ZERO combat, AI, map, or special-mechanic logic.

const Enums = preload("res://src/core/enums.gd")
const EventBusScript = preload("res://src/core/event_bus.gd")
const GameStateManagerScript = preload("res://src/core/game_state_manager.gd")
const MatchStateScript = preload("res://src/core/match_state.gd")
const SimSnapshotScript = preload("res://src/core/sim_snapshot.gd")
const ConfigLoaderScript = preload("res://src/core/config_loader.gd")

@onready var status_label: Label = $CanvasLayer/StatusLabel

var event_bus: EventBusScript
var state_manager: GameStateManagerScript
var match_state: MatchStateScript
var config: Dictionary = {}

func _ready() -> void:
	event_bus = EventBusScript.new()
	state_manager = GameStateManagerScript.new(event_bus)
	match_state = MatchStateScript.new()
	config = ConfigLoaderScript.load_json_dict()

	var cfg_ok := ConfigLoaderScript.validate_gameplay_config(config)
	var trans_ok := state_manager.transition_to(Enums.GameState.MENU)
	var snap := SimSnapshotScript.from_match_state(match_state)

	var summary := (
		"Territory Capture — Milestone 1 Scaffold\n"
		+ "Engine Pin: Godot 4.3.stable (GL Compatibility)\n"
		+ "Core Contracts: LOADED\n"
		+ "Config Valid: %s\n" % str(cfg_ok)
		+ "FSM State: MENU (transition ok=%s)\n" % str(trans_ok)
		+ "SimSnapshot Tick: %d | Buildings: %d" % [snap.tick_index, snap.buildings.size()]
	)
	if status_label != null:
		status_label.text = summary
	print("[MainBoot] ", summary.replace("\n", " | "))

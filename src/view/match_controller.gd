class_name MatchController
extends Node2D
## Scene-level coordinator linking SimulationEngine, BotController, MapCamera,
## BuildingView nodes, TroopRenderer, InputController, GameHUD, AudioManager, and SaveManager.

signal return_to_menu_requested
signal next_map_requested(next_stage_number: int)

var engine: SimulationEngine
var bot_controller: BotController
var save_manager: SaveManager
var audio_manager: AudioManager

var gameplay_config: Dictionary = {}
var mechanics_config: Dictionary = {}
var bot_presets: Dictionary = {}
var current_map_data: Dictionary = {}
var current_difficulty: String = "normal"
var pixels_per_unit: float = 100.0

var _camera: MapCamera = null
var _buildings_root: Node2D = null
var _building_views: Dictionary = {}  # building_id -> BuildingView
var _troop_renderer: TroopRenderer = null
var _input_controller: InputController = null
var _hud: GameHUD = null
var _result_recorded: bool = false

func _ready() -> void:
	engine = SimulationEngine.new()
	bot_controller = BotController.new()
	if save_manager == null:
		save_manager = SaveManager.new()
		save_manager.load_save()

	gameplay_config = MapLoader.load_json_file("res://data/balance/gameplay_config.json")
	mechanics_config = MapLoader.load_json_file("res://data/balance/mechanics_config.json")
	bot_presets = MapLoader.load_json_file("res://data/bots/bot_presets.json")
	engine.configure(gameplay_config, mechanics_config)

	_setup_scene_nodes()
	_bind_events()

func _setup_scene_nodes() -> void:
	_camera = MapCamera.new()
	_camera.enabled = true
	add_child(_camera)

	_buildings_root = Node2D.new()
	_buildings_root.name = "BuildingsRoot"
	add_child(_buildings_root)

	_troop_renderer = TroopRenderer.new()
	_troop_renderer.name = "TroopRenderer"
	add_child(_troop_renderer)

	_input_controller = InputController.new()
	_input_controller.name = "InputController"
	_input_controller.on_command_ready = Callable(self, "_on_player_command")
	_input_controller.on_selection_changed = Callable(self, "_on_selection_changed")
	add_child(_input_controller)

	var hud_scene: PackedScene = load("res://scenes/game_hud.tscn")
	if hud_scene != null:
		_hud = hud_scene.instantiate()
		add_child(_hud)
		_hud.pause_toggled.connect(_on_pause_toggled)
		_hud.restart_requested.connect(_on_restart_requested)
		_hud.menu_requested.connect(func() -> void: return_to_menu_requested.emit())
		_hud.send_ratio_changed.connect(_on_send_ratio_changed)
		_hud.reinforcement_requested.connect(_on_reinforcement_requested)
		_hud.next_stage_requested.connect(func() -> void:
			next_map_requested.emit(int(current_map_data.get("stage_number", 1)) + 1)
		)

func _bind_events() -> void:
	if audio_manager != null:
		audio_manager.bind_event_bus(engine.event_bus)
	engine.event_bus.subscribe("combat_resolved", func(p: Dictionary) -> void:
		var bid: String = str(p.get("building_id", ""))
		if _building_views.has(bid):
			var bv: BuildingView = _building_views[bid]
			bv.trigger_hit_shake()
		if p.has("position"):
			var col: Color = GameEnums.owner_color(int(p.get("attacker", 1)))
			_troop_renderer.add_burst(p["position"], col)
	)
	engine.event_bus.subscribe("mid_air_clash", func(p: Dictionary) -> void:
		if p.has("position"):
			_troop_renderer.add_burst(p["position"], Color(1.0, 0.85, 0.3, 1.0))
	)

func start_map(map_path: String, difficulty: String = "normal") -> bool:
	var map_data: Dictionary = MapLoader.load_map(map_path)
	if map_data.has("_error"):
		push_error(str(map_data["_error"]))
		return false
	return start_map_data(map_data, difficulty)

func start_map_data(map_data: Dictionary, difficulty: String = "normal") -> bool:
	current_map_data = map_data
	current_difficulty = difficulty
	_result_recorded = false
	pixels_per_unit = float(map_data.get("pixels_per_unit", 100.0))

	var res: Dictionary = engine.load_match(map_data, difficulty)
	if not res.get("ok", false):
		return false

	bot_controller.setup_bots(engine.state.active_factions, bot_presets, difficulty)
	_camera.configure_from_map(map_data)
	_rebuild_building_views()
	_input_controller.clear_selection()
	_sync_visuals()
	return true

func _rebuild_building_views() -> void:
	for child in _buildings_root.get_children():
		child.queue_free()
	_building_views.clear()

	var snap: SimSnapshot = engine.get_snapshot()
	for bid in snap.building_order:
		var bv := BuildingView.new()
		_buildings_root.add_child(bv)
		bv.sync_from_snapshot(snap.buildings[bid], pixels_per_unit)
		_building_views[bid] = bv

func _process(delta: float) -> void:
	if engine == null or current_map_data.is_empty():
		return
	if engine.state.phase == GameEnums.MatchPhase.PRE_START or engine.state.phase == GameEnums.MatchPhase.PLAYING:
		engine.advance_time(delta)
		var snap: SimSnapshot = engine.get_snapshot()
		var bot_cmds: Array[SendCommand] = bot_controller.tick(snap, delta)
		for cmd in bot_cmds:
			engine.submit_command(cmd)
		_sync_visuals()

	if engine.state.phase == GameEnums.MatchPhase.ENDED and not _result_recorded:
		_result_recorded = true
		var won: bool = (engine.state.outcome == GameEnums.MatchOutcome.WIN)
		var captures: int = int(engine.state.total_captures.get(GameEnums.OwnerId.PLAYER, 0))
		save_manager.record_match_result(
			engine.state.map_id,
			int(current_map_data.get("stage_number", 1)),
			won,
			engine.state.elapsed_time,
			captures
		)
		_sync_visuals()

func _sync_visuals() -> void:
	var snap: SimSnapshot = engine.get_snapshot()
	for bid in snap.building_order:
		if _building_views.has(bid):
			var bv: BuildingView = _building_views[bid]
			bv.sync_from_snapshot(snap.buildings[bid], pixels_per_unit)
	_troop_renderer.sync_from_snapshot(snap, pixels_per_unit)
	_input_controller.update_snapshot(snap, pixels_per_unit)
	if _hud != null:
		var rein_used: int = int(engine.state.reinforcement_requests_used.get(GameEnums.OwnerId.PLAYER, 0))
		_hud.update_from_snapshot(snap, rein_used == 0)

func _on_player_command(cmd: SendCommand) -> void:
	var res: Dictionary = engine.submit_command(cmd)
	if res.get("accepted", false):
		bot_controller.on_player_command_observed()

func _on_selection_changed(selected_ids: Array[String], hovered_target: String) -> void:
	for bid in _building_views.keys():
		var bv: BuildingView = _building_views[bid]
		bv.set_selected_visual(selected_ids.has(bid))
		bv.set_target_highlight(bid == hovered_target)

func _on_pause_toggled(paused: bool) -> void:
	engine.set_paused(paused)
	_sync_visuals()

func _on_restart_requested() -> void:
	start_map_data(current_map_data, current_difficulty)

func _on_send_ratio_changed(ratio: float) -> void:
	_input_controller.send_ratio = ratio

func _on_reinforcement_requested() -> void:
	var selected: Array[String] = _input_controller.get_selected_sources()
	var target_id: String = selected[0] if not selected.is_empty() else ""
	if target_id.is_empty():
		for bid in engine.state.building_order:
			var b: BuildingState = engine.state.buildings[bid]
			if b.owner_id == GameEnums.OwnerId.PLAYER:
				target_id = bid
				break
	if not target_id.is_empty():
		engine.request_reinforcement(GameEnums.OwnerId.PLAYER, target_id)
		_sync_visuals()

class_name SimulationEngine
extends RefCounted
## Headless deterministic simulation coordinator (M7).
## Owns MatchState and all single-authority simulation systems. Zero Node/UI dependencies.

var event_bus: EventBus
var state: MatchState
var state_manager: GameStateManager
var stat_pipeline: StatPipeline
var ownership_system: OwnershipSystem
var population_system: PopulationSystem
var path_cache: PathCache
var troop_send_system: TroopSendSystem
var movement_system: MovementSystem
var combat_system: CombatSystem
var mechanics_system: MechanicsSystem
var objective_system: ObjectiveSystem

var gameplay_config: Dictionary = {}
var mechanics_config: Dictionary = {}
var last_map_data: Dictionary = {}
var fixed_dt: float = 0.05
var countdown_seconds: float = 0.5
var _accumulator: float = 0.0

func _init() -> void:
	event_bus = EventBus.new()
	state = MatchState.new()
	state_manager = GameStateManager.new(event_bus)
	stat_pipeline = StatPipeline.new()
	ownership_system = OwnershipSystem.new(event_bus)
	population_system = PopulationSystem.new(event_bus, stat_pipeline)
	path_cache = PathCache.new()
	troop_send_system = TroopSendSystem.new(event_bus, population_system, path_cache)
	movement_system = MovementSystem.new(event_bus)
	combat_system = CombatSystem.new(event_bus, ownership_system, population_system)
	mechanics_system = MechanicsSystem.new(event_bus, stat_pipeline, population_system)
	objective_system = ObjectiveSystem.new()

func configure(p_gameplay_config: Dictionary, p_mechanics_config: Dictionary) -> void:
	gameplay_config = p_gameplay_config.duplicate(true)
	mechanics_config = p_mechanics_config.duplicate(true)
	var sim_cfg: Dictionary = gameplay_config.get("simulation", {})
	fixed_dt = maxf(0.01, float(sim_cfg.get("fixed_dt", 0.05)))
	countdown_seconds = maxf(0.0, float(sim_cfg.get("countdown_seconds", 0.5)))

	population_system.configure(gameplay_config)
	troop_send_system.configure(gameplay_config)
	movement_system.configure(gameplay_config)
	combat_system.configure(gameplay_config)
	mechanics_system.configure(mechanics_config)

func load_match(map_data: Dictionary, difficulty: String = "normal") -> Dictionary:
	var check: Dictionary = MapLoader.validate_map_dict(map_data)
	if not check.get("ok", false):
		return {"ok": false, "errors": check.get("errors", [])}

	last_map_data = map_data.duplicate(true)
	state.reset()
	stat_pipeline.clear()
	_accumulator = 0.0

	state.map_id = str(map_data.get("map_id", "unknown"))
	state.map_display_name = str(map_data.get("display_name", "Unnamed Map"))
	state.difficulty = difficulty
	state.countdown_remaining = countdown_seconds

	var hard_cap: int = int(gameplay_config.get("population", {}).get("default_hard_cap", 999))
	var b_list: Array[BuildingState] = MapLoader.build_states_from_map(map_data, hard_cap)
	var factions_seen: Dictionary = {}
	for b in b_list:
		state.buildings[b.id] = b
		state.building_order.append(b.id)
		if b.owner_id != GameEnums.OwnerId.NEUTRAL:
			factions_seen[b.owner_id] = true

	for fid in factions_seen.keys():
		state.active_factions.append(int(fid))
	state.active_factions.sort()

	var cell_size: float = float(map_data.get("grid_cell_size", 0.5))
	path_cache.build_for_buildings(state.buildings, state.building_order, cell_size)
	mechanics_system.initialize_for_match(state)

	state_manager.force_reset(state)
	state_manager.transition_to(GameEnums.MatchPhase.PRE_START, state)
	if countdown_seconds <= 0.0:
		state_manager.transition_to(GameEnums.MatchPhase.PLAYING, state)

	event_bus.emit_event("match_loaded", {
		"map_id": state.map_id,
		"difficulty": state.difficulty,
		"building_count": state.building_order.size(),
		"factions": state.active_factions.duplicate(),
	})
	return {"ok": true}

func start_immediately() -> void:
	if state.phase == GameEnums.MatchPhase.PRE_START:
		state.countdown_remaining = 0.0
		state_manager.transition_to(GameEnums.MatchPhase.PLAYING, state)

func restart_match() -> Dictionary:
	if last_map_data.is_empty():
		return {"ok": false, "errors": ["No previous map loaded"]}
	return load_match(last_map_data, state.difficulty)

func set_paused(paused: bool) -> bool:
	if paused and state.phase == GameEnums.MatchPhase.PLAYING:
		return state_manager.transition_to(GameEnums.MatchPhase.PAUSED, state)
	if not paused and state.phase == GameEnums.MatchPhase.PAUSED:
		return state_manager.transition_to(GameEnums.MatchPhase.PLAYING, state)
	return false

func submit_command(cmd: SendCommand) -> Dictionary:
	return troop_send_system.execute_command(state, cmd)

func request_reinforcement(owner_id: int, target_building_id: String) -> Dictionary:
	return mechanics_system.activate_reinforcement(state, owner_id, target_building_id)

func advance_time(delta: float) -> void:
	if delta <= 0.0 or state.is_paused:
		return
	if state.phase != GameEnums.MatchPhase.PRE_START and state.phase != GameEnums.MatchPhase.PLAYING:
		return
	_accumulator += delta
	while _accumulator >= fixed_dt:
		step_fixed(fixed_dt)
		_accumulator -= fixed_dt
		if state.phase == GameEnums.MatchPhase.ENDED:
			_accumulator = 0.0
			break

func step_fixed(dt: float) -> void:
	if dt <= 0.0 or state.is_paused:
		return

	if state.phase == GameEnums.MatchPhase.PRE_START:
		state.countdown_remaining = maxf(0.0, state.countdown_remaining - dt)
		if state.countdown_remaining <= 0.0:
			state_manager.transition_to(GameEnums.MatchPhase.PLAYING, state)
		return

	if state.phase != GameEnums.MatchPhase.PLAYING:
		return

	state.elapsed_time += dt
	state.tick_count += 1

	population_system.tick(state, dt)
	troop_send_system.tick(state, dt)
	mechanics_system.tick(state, dt)

	var speed_fn := Callable(mechanics_system, "get_speed_multiplier_for_group")
	var arrived: Array = movement_system.tick(state, dt, speed_fn)

	var dmg_fn := Callable(mechanics_system, "modify_incoming_damage")
	var cap_fn := Callable(mechanics_system, "on_building_captured")
	combat_system.resolve_arrivals(state, arrived, dmg_fn, cap_fn)

	var eval: Dictionary = objective_system.evaluate(state)
	var outcome: int = int(eval.get("outcome", GameEnums.MatchOutcome.NONE))
	if outcome != GameEnums.MatchOutcome.NONE:
		state.outcome = outcome
		state.winner_owner_id = int(eval.get("winner", GameEnums.OwnerId.NEUTRAL))
		state_manager.transition_to(GameEnums.MatchPhase.ENDED, state)
		event_bus.emit_event("match_ended", {
			"outcome": state.outcome,
			"winner": state.winner_owner_id,
			"elapsed_time": state.elapsed_time,
			"map_id": state.map_id,
		})

func get_snapshot() -> SimSnapshot:
	return SimSnapshot.build_from(state)

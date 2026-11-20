class_name TroopSendSystem
extends RefCounted
## Single-authority handler for SendCommand validation, source deduction, and burst wave spawning.
## Guarantees: never deducts troops twice, enforces MAX_GROUPS = 256, spawns 5/wave every 0.25s.

var event_bus: EventBus = null
var population_system: PopulationSystem = null
var path_cache: PathCache = null

var units_per_wave: int = 5
var burst_wave_interval: float = 0.25
var max_active_groups: int = 256
var base_speed: float = 3.5
var min_send_amount: int = 1
var leave_minimum_garrison: int = 0

func _init(
	p_event_bus: EventBus = null,
	p_population_system: PopulationSystem = null,
	p_path_cache: PathCache = null
) -> void:
	event_bus = p_event_bus
	population_system = p_population_system
	path_cache = p_path_cache

func configure(config: Dictionary) -> void:
	var send_cfg: Dictionary = config.get("troop_sending", {})
	units_per_wave = maxi(1, int(send_cfg.get("units_per_wave", 5)))
	burst_wave_interval = maxf(0.05, float(send_cfg.get("burst_wave_interval_seconds", 0.25)))
	max_active_groups = maxi(1, int(send_cfg.get("max_active_groups", 256)))
	min_send_amount = maxi(1, int(send_cfg.get("min_send_amount", 1)))
	leave_minimum_garrison = maxi(0, int(send_cfg.get("leave_minimum_garrison", 0)))
	var move_cfg: Dictionary = config.get("movement", {})
	base_speed = maxf(0.1, float(move_cfg.get("base_speed_units_per_sec", 3.5)))

func compute_send_amount(available_population: int, send_ratio: float) -> int:
	var usable: int = maxi(0, available_population - leave_minimum_garrison)
	if usable < min_send_amount or send_ratio <= 0.0:
		return 0
	var clamped_ratio: float = clampf(send_ratio, 0.0, 1.0)
	if clamped_ratio >= 0.9999:
		return usable
	var desired: int = int(floor(float(usable) * clamped_ratio))
	if desired < min_send_amount and usable >= min_send_amount:
		desired = min_send_amount
	return mini(usable, desired)

func execute_command(state: MatchState, cmd: SendCommand) -> Dictionary:
	if state == null or cmd == null:
		return {"accepted": false, "reason": "null_input", "total_sent": 0}
	if state.phase != GameEnums.MatchPhase.PLAYING or state.is_paused:
		return {"accepted": false, "reason": "match_not_active", "total_sent": 0}
	if not cmd.is_structurally_valid():
		return {"accepted": false, "reason": "invalid_command", "total_sent": 0}

	# Duplicate command ID guard
	if not cmd.command_id.is_empty():
		if state.processed_command_ids.has(cmd.command_id):
			return {"accepted": false, "reason": "duplicate_command", "total_sent": 0}

	var target: BuildingState = state.get_building(cmd.target_id)
	if target == null:
		return {"accepted": false, "reason": "invalid_target", "total_sent": 0}

	# Deduplicate source IDs so a single command can never deduct the same building twice
	var seen_sources: Dictionary = {}
	var total_sent: int = 0
	var accepted_sources: Array[String] = []

	for src_id in cmd.source_ids:
		if seen_sources.has(src_id):
			continue
		seen_sources[src_id] = true
		if src_id == cmd.target_id:
			continue
		var src: BuildingState = state.get_building(src_id)
		if src == null:
			continue
		if src.owner_id != cmd.owner_id:
			continue

		var to_send: int = compute_send_amount(src.population, cmd.send_ratio)
		if to_send <= 0:
			continue

		# Single-authority deduction right now so troops are never double-spent across waves
		var deducted: int = population_system.deduct_population(src, to_send, true)
		if deducted <= 0:
			continue

		total_sent += deducted
		accepted_sources.append(src_id)
		state.total_troops_sent[cmd.owner_id] = int(state.total_troops_sent.get(cmd.owner_id, 0)) + deducted

		# Spawn first burst immediately if under group cap, queue remainder
		var first_wave: int = mini(deducted, units_per_wave)
		var remainder: int = deducted - first_wave
		if state.troop_groups.size() < max_active_groups:
			_spawn_group(state, cmd.owner_id, src, target, first_wave)
		else:
			remainder = deducted

		if remainder > 0:
			state.pending_waves.append({
				"owner_id": cmd.owner_id,
				"source_id": src.id,
				"source_pos": src.position,
				"target_id": target.id,
				"remaining_amount": remainder,
				"timer": burst_wave_interval,
			})

	if total_sent <= 0:
		return {"accepted": false, "reason": "no_troops_dispatched", "total_sent": 0}

	if not cmd.command_id.is_empty():
		state.processed_command_ids[cmd.command_id] = true

	if event_bus != null:
		event_bus.emit_event("troops_sent", {
			"owner_id": cmd.owner_id,
			"source_ids": accepted_sources,
			"target_id": cmd.target_id,
			"total_sent": total_sent,
			"send_ratio": cmd.send_ratio,
		})

	return {"accepted": true, "reason": "ok", "total_sent": total_sent, "sources": accepted_sources}

func tick(state: MatchState, dt: float) -> void:
	if state == null or state.is_paused or dt <= 0.0:
		return
	if state.phase != GameEnums.MatchPhase.PLAYING:
		return

	for i in range(state.pending_waves.size() - 1, -1, -1):
		var wave: Dictionary = state.pending_waves[i]
		wave["timer"] = float(wave.get("timer", 0.0)) - dt
		if float(wave["timer"]) > 0.0:
			continue

		if state.troop_groups.size() >= max_active_groups:
			wave["timer"] = burst_wave_interval * 0.5
			continue

		var target: BuildingState = state.get_building(str(wave.get("target_id", "")))
		if target == null:
			state.pending_waves.remove_at(i)
			continue

		var src: BuildingState = state.get_building(str(wave.get("source_id", "")))
		var src_pos: Vector2 = src.position if src != null else wave.get("source_pos", Vector2.ZERO)
		var rem: int = int(wave.get("remaining_amount", 0))
		var batch: int = mini(rem, units_per_wave)
		if batch > 0:
			_spawn_group_from_pos(state, int(wave["owner_id"]), str(wave["source_id"]), src_pos, target, batch)
			wave["remaining_amount"] = rem - batch
			wave["timer"] = burst_wave_interval

		if int(wave["remaining_amount"]) <= 0:
			state.pending_waves.remove_at(i)

func _spawn_group(state: MatchState, owner_id: int, src: BuildingState, target: BuildingState, amount: int) -> TroopGroupState:
	return _spawn_group_from_pos(state, owner_id, src.id, src.position, target, amount)

func _spawn_group_from_pos(
	state: MatchState,
	owner_id: int,
	source_id: String,
	source_pos: Vector2,
	target: BuildingState,
	amount: int
) -> TroopGroupState:
	var grp := TroopGroupState.new()
	grp.id = state.next_group_id
	state.next_group_id += 1
	grp.owner_id = owner_id
	grp.source_id = source_id
	grp.target_id = target.id
	grp.amount = amount
	grp.position = source_pos
	grp.base_speed = base_speed
	grp.current_speed = base_speed
	if path_cache != null:
		grp.waypoints = path_cache.get_route(source_id, target.id, source_pos, target.position)
	else:
		grp.waypoints.assign([source_pos, target.position])
	grp.current_waypoint_index = 1 if grp.waypoints.size() > 1 else 0
	grp.total_route_length = PathCache.compute_route_length(grp.waypoints)
	if grp.waypoints.size() > 1:
		var dir: Vector2 = grp.waypoints[1] - source_pos
		grp.direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
	state.troop_groups.append(grp)
	return grp

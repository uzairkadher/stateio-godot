class_name BotController
extends RefCounted
## Manages all AI bot factions in a match (M6).
## Reads immutable SimSnapshot and emits identical SendCommand structs into SimulationEngine.

var configs: Dictionary = {}        # owner_id -> BotConfig
var decision_timers: Dictionary = {} # owner_id -> float
var cooldown_timers: Dictionary = {} # owner_id -> float
var idle_timers: Dictionary = {}     # owner_id -> float
var reaction_timers: Dictionary = {} # owner_id -> float
var _cmd_seq: int = 1

func setup_bots(active_factions: Array[int], presets_json: Dictionary, difficulty: String = "normal") -> void:
	reset()
	for fid in active_factions:
		if fid == GameEnums.OwnerId.NEUTRAL or fid == GameEnums.OwnerId.PLAYER:
			continue
		var cfg: BotConfig = BotConfig.load_preset(presets_json, difficulty)
		configs[fid] = cfg
		# Stagger initial decision timers deterministically by owner_id
		decision_timers[fid] = 0.35 + float(fid - 2) * 0.25
		cooldown_timers[fid] = 0.0
		idle_timers[fid] = 0.0
		reaction_timers[fid] = 0.0

func reset() -> void:
	configs.clear()
	decision_timers.clear()
	cooldown_timers.clear()
	idle_timers.clear()
	reaction_timers.clear()
	_cmd_seq = 1

func on_player_command_observed() -> void:
	for fid in configs.keys():
		var cfg: BotConfig = configs[fid]
		reaction_timers[fid] = cfg.reaction_delay_sec

func tick(snapshot: SimSnapshot, dt: float) -> Array[SendCommand]:
	var commands: Array[SendCommand] = []
	if snapshot == null or snapshot.is_paused or dt <= 0.0:
		return commands
	if snapshot.phase != GameEnums.MatchPhase.PLAYING:
		return commands

	var bot_ids: Array = configs.keys()
	bot_ids.sort()
	for fid in bot_ids:
		var owner_id: int = int(fid)
		if int(snapshot.faction_buildings.get(owner_id, 0)) <= 0:
			continue
		var cfg: BotConfig = configs[owner_id]
		decision_timers[owner_id] = float(decision_timers[owner_id]) - dt
		cooldown_timers[owner_id] = maxf(0.0, float(cooldown_timers[owner_id]) - dt)
		idle_timers[owner_id] = float(idle_timers[owner_id]) + dt

		var reactive_trigger: bool = false
		if float(reaction_timers.get(owner_id, 0.0)) > 0.0:
			reaction_timers[owner_id] = float(reaction_timers[owner_id]) - dt
			if float(reaction_timers[owner_id]) <= 0.0:
				reactive_trigger = true

		if float(cooldown_timers[owner_id]) > 0.0:
			continue
		if float(decision_timers[owner_id]) > 0.0 and not reactive_trigger:
			continue

		decision_timers[owner_id] = cfg.decision_interval_sec
		var force_idle: bool = float(idle_timers[owner_id]) >= cfg.idle_timeout_sec
		var plan: Dictionary = TargetEvaluator.evaluate_best_action(snapshot, owner_id, cfg, force_idle)
		if plan.is_empty():
			continue

		var src_arr: Array[String] = [str(plan["source_id"])]
		var cmd_id := "bot_%d_%d" % [owner_id, _cmd_seq]
		_cmd_seq += 1
		var cmd := SendCommand.new(
			owner_id,
			src_arr,
			str(plan["target_id"]),
			float(plan["send_ratio"]),
			cmd_id,
			snapshot.elapsed_time
		)
		commands.append(cmd)
		cooldown_timers[owner_id] = cfg.command_cooldown_sec
		idle_timers[owner_id] = 0.0

	return commands

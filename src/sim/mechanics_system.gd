class_name MechanicsSystem
extends RefCounted
## Modular special buildings & mechanics lifecycle manager (M8).
## Supports: Shield, Hard Shield, Turret, Speed Zone, Slow Zone, Propaganda,
## Additional Fighters, and Reinforcement. All independently configurable and toggleable.

var event_bus: EventBus = null
var stat_pipeline: StatPipeline = null
var population_system: PopulationSystem = null
var config: Dictionary = {}

func _init(
	p_event_bus: EventBus = null,
	p_stat_pipeline: StatPipeline = null,
	p_population_system: PopulationSystem = null
) -> void:
	event_bus = p_event_bus
	stat_pipeline = p_stat_pipeline
	population_system = p_population_system

func configure(mechanics_config: Dictionary) -> void:
	config = mechanics_config.get("mechanics", mechanics_config).duplicate(true)

func is_mechanic_enabled(mech_type: int) -> bool:
	var key: String = GameEnums.mechanic_to_string(mech_type)
	if key.is_empty():
		return false
	var entry: Dictionary = config.get(key, {})
	return bool(entry.get("enabled", true))

func set_mechanic_enabled(mech_type: int, enabled: bool) -> void:
	var key: String = GameEnums.mechanic_to_string(mech_type)
	if key.is_empty():
		return
	if not config.has(key):
		config[key] = {}
	config[key]["enabled"] = enabled

func initialize_for_match(state: MatchState) -> void:
	state.mechanics.clear()
	state.mechanic_order.clear()
	if stat_pipeline != null:
		stat_pipeline.clear()

	for bid in state.building_order:
		var b: BuildingState = state.buildings[bid]
		if b.mechanic_type == GameEnums.SpecialMechanicType.NONE:
			continue
		register_building_mechanic(state, b, b.mechanic_type)

	_recompute_propaganda_auras(state)

func register_building_mechanic(state: MatchState, b: BuildingState, mech_type: int) -> SpecialMechanicState:
	var key: String = GameEnums.mechanic_to_string(mech_type)
	var cfg: Dictionary = config.get(key, {})
	var m := SpecialMechanicState.new()
	m.id = "mech_%s_%s" % [b.id, key]
	m.mechanic_type = mech_type
	m.building_id = b.id
	m.owner_id = b.owner_id
	m.position = b.position
	m.is_enabled = bool(cfg.get("enabled", true))
	m.is_active = m.is_enabled
	m.duration_total = maxf(0.0, float(cfg.get("duration_seconds", 0.0)))
	m.duration_remaining = m.duration_total
	m.cooldown_total = maxf(0.0, float(cfg.get("cooldown_seconds", 0.0)))
	m.cooldown_remaining = 0.0
	m.zone_radius = maxf(0.25, float(cfg.get("zone_radius_units", 1.0)))
	m.impact_percentage = float(cfg.get("impact_percentage", 0.0))
	m.max_stacks = maxi(1, int(cfg.get("max_stacks", 1)))
	m.work_for_neutrals = bool(cfg.get("work_for_neutrals", true))
	m.work_when_pop_zero = bool(cfg.get("work_when_pop_zero", true))

	if mech_type == GameEnums.SpecialMechanicType.SHIELD or mech_type == GameEnums.SpecialMechanicType.HARD_SHIELD:
		m.max_shield_hp = maxf(0.0, float(cfg.get("shield_amount", 50.0)))
		m.shield_hp = m.max_shield_hp if m.is_enabled else 0.0
		b.max_shield_hp = m.max_shield_hp
		b.shield_hp = m.shield_hp

	state.mechanics[m.id] = m
	if not state.mechanic_order.has(m.id):
		state.mechanic_order.append(m.id)
	return m

func activate_reinforcement(state: MatchState, owner_id: int, target_building_id: String) -> Dictionary:
	if state == null or state.phase != GameEnums.MatchPhase.PLAYING or state.is_paused:
		return {"ok": false, "reason": "match_not_active"}
	if not is_mechanic_enabled(GameEnums.SpecialMechanicType.REINFORCEMENT):
		return {"ok": false, "reason": "disabled"}
	var cfg: Dictionary = config.get("reinforcement", {})
	var max_req: int = maxi(1, int(cfg.get("max_requests_per_level", 1)))
	var used: int = int(state.reinforcement_requests_used.get(owner_id, 0))
	if used >= max_req:
		return {"ok": false, "reason": "limit_reached"}
	var target: BuildingState = state.get_building(target_building_id)
	if target == null or target.owner_id != owner_id:
		return {"ok": false, "reason": "invalid_target"}

	var amount: int = maxi(1, int(cfg.get("fighters_limit", 20)))
	var dur: float = maxf(0.5, float(cfg.get("occupy_duration_seconds", 5.0)))
	var cd: float = maxf(0.0, float(cfg.get("cooldown_seconds", 25.0)))

	var m := SpecialMechanicState.new()
	m.id = "mech_reinforce_%d_%d" % [owner_id, state.tick_count]
	m.mechanic_type = GameEnums.SpecialMechanicType.REINFORCEMENT
	m.building_id = target.id
	m.owner_id = owner_id
	m.position = target.position
	m.is_enabled = true
	m.is_active = true
	m.duration_total = dur
	m.duration_remaining = dur
	m.cooldown_total = cd
	m.cooldown_remaining = cd
	m.zone_radius = float(cfg.get("out_radius_units", 3.0))

	state.mechanics[m.id] = m
	state.mechanic_order.append(m.id)
	state.reinforcement_requests_used[owner_id] = used + 1

	if population_system != null:
		population_system.add_population(target, amount, true)

	if event_bus != null:
		event_bus.emit_event("mechanic_activated", {
			"mechanic_id": m.id,
			"mechanic_type": m.mechanic_type,
			"building_id": target.id,
			"owner_id": owner_id,
			"amount": amount,
		})
	return {"ok": true, "mechanic_id": m.id, "added": amount}

func tick(state: MatchState, dt: float) -> void:
	if state == null or state.is_paused or dt <= 0.0:
		return
	if state.phase != GameEnums.MatchPhase.PLAYING:
		return

	for i in range(state.mechanic_order.size() - 1, -1, -1):
		var mid: String = state.mechanic_order[i]
		var m: SpecialMechanicState = state.mechanics[mid]
		var b: BuildingState = state.get_building(m.building_id)
		if b != null:
			m.owner_id = b.owner_id
			m.position = b.position

		if m.beam_flash_timer > 0.0:
			m.beam_flash_timer = maxf(0.0, m.beam_flash_timer - dt)

		# Timed duration expiry
		if m.duration_total > 0.0 and m.is_active:
			m.duration_remaining = maxf(0.0, m.duration_remaining - dt)
			if m.duration_remaining <= 0.0:
				m.is_active = false
				if event_bus != null:
					event_bus.emit_event("mechanic_expired", {
						"mechanic_id": m.id,
						"mechanic_type": m.mechanic_type,
						"building_id": m.building_id,
					})

		# Cooldown handling (e.g., shield recharge after depletion)
		if not m.is_active and m.cooldown_remaining > 0.0:
			m.cooldown_remaining = maxf(0.0, m.cooldown_remaining - dt)
			if m.cooldown_remaining <= 0.0 and m.is_enabled:
				if m.mechanic_type == GameEnums.SpecialMechanicType.SHIELD or m.mechanic_type == GameEnums.SpecialMechanicType.HARD_SHIELD:
					m.shield_hp = m.max_shield_hp
					m.is_active = true
					if b != null:
						b.shield_hp = m.shield_hp

		if not _can_mechanic_operate(m, b):
			continue

		if m.mechanic_type == GameEnums.SpecialMechanicType.TURRET:
			_tick_turret(state, m, dt)

	_recompute_propaganda_auras(state)

func modify_incoming_damage(state: MatchState, target: BuildingState, attacker_owner: int, raw_damage: float) -> float:
	if target == null or raw_damage <= 0.0:
		return raw_damage
	var remaining_dmg: float = raw_damage
	for mid in state.mechanic_order:
		var m: SpecialMechanicState = state.mechanics[mid]
		if m.building_id != target.id:
			continue
		if m.mechanic_type != GameEnums.SpecialMechanicType.SHIELD and m.mechanic_type != GameEnums.SpecialMechanicType.HARD_SHIELD:
			continue
		if not _can_mechanic_operate(m, target) or m.shield_hp <= 0.0:
			continue
		var absorbed: float = minf(m.shield_hp, remaining_dmg)
		m.shield_hp = maxf(0.0, m.shield_hp - absorbed)
		remaining_dmg = maxf(0.0, remaining_dmg - absorbed)
		target.shield_hp = m.shield_hp
		if m.shield_hp <= 0.0:
			m.is_active = false
			m.cooldown_remaining = m.cooldown_total
		if event_bus != null:
			event_bus.emit_event("shield_absorbed", {
				"building_id": target.id,
				"attacker": attacker_owner,
				"absorbed": absorbed,
				"shield_remaining": m.shield_hp,
			})
		if remaining_dmg <= 0.0:
			break
	return remaining_dmg

func on_building_captured(state: MatchState, target: BuildingState, _prev_owner: int, new_owner: int) -> void:
	for mid in state.mechanic_order:
		var m: SpecialMechanicState = state.mechanics[mid]
		if m.building_id != target.id:
			continue
		m.owner_id = new_owner
		if m.mechanic_type == GameEnums.SpecialMechanicType.ADDITIONAL_FIGHTERS:
			if not m.is_enabled or m.triggered_once:
				continue
			if new_owner == GameEnums.OwnerId.NEUTRAL:
				continue
			var cfg: Dictionary = config.get("additional_fighters", {})
			var bonus: int = maxi(1, int(cfg.get("bonus_fighters_amount", 50)))
			m.triggered_once = bool(cfg.get("one_time_per_match", true))
			m.is_active = not m.triggered_once
			if population_system != null:
				population_system.add_population(target, bonus, true)
			if event_bus != null:
				event_bus.emit_event("mechanic_activated", {
					"mechanic_id": m.id,
					"mechanic_type": m.mechanic_type,
					"building_id": target.id,
					"owner_id": new_owner,
					"bonus_fighters": bonus,
				})
	_recompute_propaganda_auras(state)

func get_speed_multiplier_for_group(state: MatchState, grp: TroopGroupState) -> float:
	var speed_bonus_pct: float = 0.0
	var slow_penalty_pct: float = 0.0
	var speed_stacks: int = 0
	var slow_stacks: int = 0

	for mid in state.mechanic_order:
		var m: SpecialMechanicState = state.mechanics[mid]
		if not m.is_enabled or not m.is_active:
			continue
		if m.mechanic_type != GameEnums.SpecialMechanicType.SPEED_ZONE and m.mechanic_type != GameEnums.SpecialMechanicType.SLOW_ZONE:
			continue
		if grp.position.distance_to(m.position) <= m.zone_radius:
			if m.mechanic_type == GameEnums.SpecialMechanicType.SPEED_ZONE and speed_stacks < m.max_stacks:
				speed_bonus_pct += m.impact_percentage
				speed_stacks += 1
			elif m.mechanic_type == GameEnums.SpecialMechanicType.SLOW_ZONE and slow_stacks < m.max_stacks:
				slow_penalty_pct += m.impact_percentage
				slow_stacks += 1

	var mult: float = 1.0 + (speed_bonus_pct + slow_penalty_pct) / 100.0
	return clampf(mult, 0.25, 2.5)

func _tick_turret(state: MatchState, m: SpecialMechanicState, dt: float) -> void:
	var cfg: Dictionary = config.get("turret", {})
	var cycle: float = maxf(0.05, float(cfg.get("cooldown_seconds", 0.25)))
	var dmg: int = maxi(1, int(cfg.get("damage_per_shot", 1)))
	m.turret_timer -= dt
	if m.turret_timer > 0.0:
		return

	var closest: TroopGroupState = null
	var closest_dist_sq: float = m.zone_radius * m.zone_radius
	for g in state.troop_groups:
		var grp: TroopGroupState = g
		if grp.is_eliminated or grp.is_arrived or grp.amount <= 0:
			continue
		if grp.owner_id == m.owner_id:
			continue
		var d_sq: float = m.position.distance_squared_to(grp.position)
		if d_sq <= closest_dist_sq:
			closest_dist_sq = d_sq
			closest = grp

	if closest != null:
		var killed: int = mini(closest.amount, dmg)
		closest.amount -= killed
		state.total_troops_lost[closest.owner_id] = int(state.total_troops_lost.get(closest.owner_id, 0)) + killed
		if closest.amount <= 0:
			closest.is_eliminated = true
		m.turret_timer = cycle
		m.last_target_pos = closest.position
		m.beam_flash_timer = float(cfg.get("shooting_ray_duration", 0.05))
		if event_bus != null:
			event_bus.emit_event("turret_fired", {
				"building_id": m.building_id,
				"from": m.position,
				"to": closest.position,
				"killed": killed,
			})

func _recompute_propaganda_auras(state: MatchState) -> void:
	if stat_pipeline == null:
		return
	for mid in state.mechanic_order:
		var m: SpecialMechanicState = state.mechanics[mid]
		if m.mechanic_type != GameEnums.SpecialMechanicType.PROPAGANDA:
			continue
		stat_pipeline.remove_all_from_source(m.id)
		var src_b: BuildingState = state.get_building(m.building_id)
		if not _can_mechanic_operate(m, src_b):
			continue
		for bid in state.building_order:
			var b: BuildingState = state.buildings[bid]
			if b.owner_id != m.owner_id or b.owner_id == GameEnums.OwnerId.NEUTRAL:
				continue
			if b.position.distance_to(m.position) <= m.zone_radius:
				stat_pipeline.add_modifier(
					b.id,
					GameEnums.StatType.SPAWN_RATE,
					m.id,
					GameEnums.StatOperation.MULTIPLY_BASE,
					m.impact_percentage / 100.0
				)

func _can_mechanic_operate(m: SpecialMechanicState, b: BuildingState) -> bool:
	if not m.is_enabled or not m.is_active:
		return false
	if b == null:
		return false
	if b.owner_id == GameEnums.OwnerId.NEUTRAL and not m.work_for_neutrals:
		return false
	if b.population <= 0 and not m.work_when_pop_zero:
		return false
	return true

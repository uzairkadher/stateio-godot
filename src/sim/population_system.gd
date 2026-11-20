class_name PopulationSystem
extends RefCounted
## Single-authority mutator for building population growth, caps, block timers, and deductions.
## Pure fixed-dt math: never depends on rendering frame rate and never allows negative population.

var event_bus: EventBus = null
var stat_pipeline: StatPipeline = null

var base_spawn_rate_per_sec: float = 1.0
var neutral_spawn_rate_per_sec: float = 0.0
var block_population_seconds: float = 0.5
var upgrade_spawn_bonus_per_level: float = 0.25
var upgrade_cap_bonus_per_level: int = 15

func _init(p_event_bus: EventBus = null, p_stat_pipeline: StatPipeline = null) -> void:
	event_bus = p_event_bus
	stat_pipeline = p_stat_pipeline

func configure(config: Dictionary) -> void:
	var pop_cfg: Dictionary = config.get("population", {})
	base_spawn_rate_per_sec = maxf(0.0, float(pop_cfg.get("base_spawn_rate_per_sec", 1.0)))
	neutral_spawn_rate_per_sec = maxf(0.0, float(pop_cfg.get("neutral_spawn_rate_per_sec", 0.0)))
	block_population_seconds = maxf(0.0, float(pop_cfg.get("block_population_seconds", 0.5)))
	upgrade_spawn_bonus_per_level = maxf(0.0, float(pop_cfg.get("upgrade_spawn_bonus_per_level", 0.25)))
	upgrade_cap_bonus_per_level = maxi(0, int(pop_cfg.get("upgrade_cap_bonus_per_level", 15)))

func tick(state: MatchState, dt: float) -> void:
	if state == null or state.is_paused or dt <= 0.0:
		return
	if state.phase != GameEnums.MatchPhase.PLAYING:
		return

	for bid in state.building_order:
		var b: BuildingState = state.buildings[bid]
		if b.block_timer > 0.0:
			b.block_timer = maxf(0.0, b.block_timer - dt)
			continue
		if b.production_lock_count > 0:
			continue

		var effective_cap: int = get_effective_cap(b)
		if b.population >= effective_cap:
			b.population_accumulator = 0.0
			continue

		var rate: float = get_effective_spawn_rate(b)
		if rate <= 0.0:
			continue

		b.population_accumulator += rate * dt
		if b.population_accumulator >= 1.0:
			var gained: int = int(floor(b.population_accumulator))
			b.population_accumulator -= float(gained)
			var prev_pop: int = b.population
			b.population = mini(effective_cap, b.population + gained)
			if b.population != prev_pop and event_bus != null:
				event_bus.emit_event("population_changed", {
					"building_id": b.id,
					"previous": prev_pop,
					"current": b.population,
					"reason": "growth",
				})

func get_effective_spawn_rate(b: BuildingState) -> float:
	var raw_base: float = neutral_spawn_rate_per_sec if b.owner_id == GameEnums.OwnerId.NEUTRAL else (b.base_spawn_rate * base_spawn_rate_per_sec)
	if raw_base <= 0.0:
		return 0.0
	var upgrade_mult: float = 1.0 + float(maxi(0, b.upgrade_level - 1)) * upgrade_spawn_bonus_per_level
	var base_with_upgrade: float = raw_base * upgrade_mult
	if stat_pipeline != null:
		return stat_pipeline.evaluate(b.id, GameEnums.StatType.SPAWN_RATE, base_with_upgrade)
	return base_with_upgrade

func get_effective_cap(b: BuildingState) -> int:
	var base_cap: float = float(b.population_cap + maxi(0, b.upgrade_level - 1) * upgrade_cap_bonus_per_level)
	if stat_pipeline != null:
		base_cap = stat_pipeline.evaluate(b.id, GameEnums.StatType.POPULATION_CAP, base_cap)
	return clampi(int(round(base_cap)), 1, b.hard_cap)

func block_production(b: BuildingState, custom_duration: float = -1.0) -> void:
	if b == null:
		return
	var dur: float = block_population_seconds if custom_duration < 0.0 else custom_duration
	b.block_timer = maxf(b.block_timer, dur)

func deduct_population(b: BuildingState, amount: int, apply_block: bool = true) -> int:
	if b == null or amount <= 0:
		return 0
	var prev: int = b.population
	var actual: int = mini(b.population, amount)
	b.population = maxi(0, b.population - actual)
	if apply_block and actual > 0:
		block_production(b)
	if actual > 0 and event_bus != null:
		event_bus.emit_event("population_changed", {
			"building_id": b.id,
			"previous": prev,
			"current": b.population,
			"reason": "deduct",
		})
	return actual

func add_population(b: BuildingState, amount: int, allow_above_soft_cap: bool = true) -> int:
	if b == null or amount <= 0:
		return 0
	var prev: int = b.population
	var limit: int = b.hard_cap if allow_above_soft_cap else get_effective_cap(b)
	b.population = clampi(b.population + amount, 0, limit)
	var added: int = b.population - prev
	if added > 0 and event_bus != null:
		event_bus.emit_event("population_changed", {
			"building_id": b.id,
			"previous": prev,
			"current": b.population,
			"reason": "add",
		})
	return added

func set_population_clamped(b: BuildingState, new_value: int) -> void:
	if b == null:
		return
	var prev: int = b.population
	b.population = clampi(new_value, 0, b.hard_cap)
	if b.population != prev and event_bus != null:
		event_bus.emit_event("population_changed", {
			"building_id": b.id,
			"previous": prev,
			"current": b.population,
			"reason": "set",
		})

class_name CombatSystem
extends RefCounted
## Deterministic arrival combat & building capture resolution.
## Handles friendly reinforcement, neutral/enemy attacks, shield/defense modifiers,
## simultaneous multi-attacker arrivals (sorted by group ID), and zero-population edge cases.

var event_bus: EventBus = null
var ownership_system: OwnershipSystem = null
var population_system: PopulationSystem = null

var attack_damage_multiplier: float = 1.0
var defense_damage_multiplier: float = 1.0
var tie_goes_to_defender: bool = true

func _init(
	p_event_bus: EventBus = null,
	p_ownership_system: OwnershipSystem = null,
	p_population_system: PopulationSystem = null
) -> void:
	event_bus = p_event_bus
	ownership_system = p_ownership_system
	population_system = p_population_system

func configure(config: Dictionary) -> void:
	var c: Dictionary = config.get("combat", {})
	attack_damage_multiplier = maxf(0.1, float(c.get("attack_damage_multiplier", 1.0)))
	defense_damage_multiplier = maxf(0.1, float(c.get("defense_damage_multiplier", 1.0)))
	tie_goes_to_defender = bool(c.get("tie_goes_to_defender", true))

func resolve_arrivals(
	state: MatchState,
	arrived_groups: Array,
	damage_modifier_fn: Callable = Callable(),
	on_capture_fn: Callable = Callable()
) -> void:
	if state == null or arrived_groups.is_empty():
		return

	# Sort deterministically by troop group ID so simultaneous arrivals produce identical results
	var sorted_groups: Array = arrived_groups.duplicate()
	sorted_groups.sort_custom(func(a: TroopGroupState, b: TroopGroupState) -> bool: return a.id < b.id)

	for g in sorted_groups:
		var grp: TroopGroupState = g
		if grp.is_eliminated or grp.amount <= 0:
			continue
		var target: BuildingState = state.get_building(grp.target_id)
		if target == null:
			grp.is_eliminated = true
			continue
		_resolve_single_arrival(state, target, grp, damage_modifier_fn, on_capture_fn)
		grp.is_eliminated = true

	# Compact inactive troop groups cleanly
	for i in range(state.troop_groups.size() - 1, -1, -1):
		var grp: TroopGroupState = state.troop_groups[i]
		if grp.is_eliminated or grp.is_arrived or grp.amount <= 0:
			state.troop_groups.remove_at(i)

func _resolve_single_arrival(
	state: MatchState,
	target: BuildingState,
	grp: TroopGroupState,
	damage_modifier_fn: Callable,
	on_capture_fn: Callable
) -> void:
	# Case 1: Friendly reinforcement (handles owner changes mid-travel automatically)
	if target.owner_id == grp.owner_id:
		var added: int = population_system.add_population(target, grp.amount, true)
		if event_bus != null:
			event_bus.emit_event("reinforcement_received", {
				"building_id": target.id,
				"owner_id": grp.owner_id,
				"amount": added,
			})
		return

	# Case 2: Neutral or enemy attack
	var raw_damage: float = float(grp.amount) * attack_damage_multiplier / defense_damage_multiplier
	var effective_damage: float = raw_damage
	if damage_modifier_fn.is_valid():
		effective_damage = maxf(0.0, float(damage_modifier_fn.call(state, target, grp.owner_id, raw_damage)))

	population_system.block_production(target)

	# Apply fractional damage buffer
	var total_dmg: float = effective_damage + target.fractional_damage
	var int_dmg: int = int(floor(total_dmg))
	target.fractional_damage = total_dmg - float(int_dmg)

	if int_dmg <= 0:
		state.total_troops_lost[grp.owner_id] = int(state.total_troops_lost.get(grp.owner_id, 0)) + grp.amount
		if event_bus != null:
			event_bus.emit_event("combat_resolved", {
				"building_id": target.id,
				"attacker": grp.owner_id,
				"defender": target.owner_id,
				"captured": false,
				"remaining_population": target.population,
			})
		return

	var prev_owner: int = target.owner_id
	var defender_pop: int = target.population
	var remaining: int = defender_pop - int_dmg

	var captured: bool = false
	if remaining < 0:
		captured = true
	elif remaining == 0 and not tie_goes_to_defender:
		captured = true

	if captured:
		var attacker_losses: int = mini(grp.amount, defender_pop)
		state.total_troops_lost[grp.owner_id] = int(state.total_troops_lost.get(grp.owner_id, 0)) + attacker_losses
		state.total_troops_lost[prev_owner] = int(state.total_troops_lost.get(prev_owner, 0)) + defender_pop
		var surviving_attackers: int = maxi(0, -remaining)
		ownership_system.change_owner_by_occupy(state, target, grp.owner_id)
		population_system.set_population_clamped(target, surviving_attackers)
		if on_capture_fn.is_valid():
			on_capture_fn.call(state, target, prev_owner, grp.owner_id)
	else:
		state.total_troops_lost[grp.owner_id] = int(state.total_troops_lost.get(grp.owner_id, 0)) + grp.amount
		state.total_troops_lost[prev_owner] = int(state.total_troops_lost.get(prev_owner, 0)) + mini(defender_pop, int_dmg)
		population_system.set_population_clamped(target, maxi(0, remaining))

	if event_bus != null:
		event_bus.emit_event("combat_resolved", {
			"building_id": target.id,
			"attacker": grp.owner_id,
			"defender": prev_owner,
			"captured": captured,
			"remaining_population": target.population,
			"position": target.position,
		})

class_name EventBus
extends RefCounted
## Locked cross-layer event contract.
## Instantiated per match/app context (not a global Node autoload) so headless
## unit tests can create isolated EventBus instances with zero leaked state.

signal match_state_changed(old_state: int, new_state: int)
signal stage_loaded(stage_id: String)
signal building_owner_changed(building_id: int, old_owner: int, new_owner: int)
signal population_changed(building_id: int, new_population: int)
signal troop_group_dispatched(group_id: int, owner: int, source_id: int, target_id: int, total_amount: int)
signal fighter_arrived(fighter_id: int, target_building_id: int, owner: int, amount: int)
signal combat_hit(building_id: int, attacker_owner: int, damage: float)
signal building_captured(building_id: int, new_owner: int, previous_owner: int, remaining_troops: int)
signal objective_resolved(outcome: int)
signal settings_changed(key: String, value: Variant)

func emit_match_state_changed(old_state: int, new_state: int) -> void:
	match_state_changed.emit(old_state, new_state)

func emit_stage_loaded(stage_id: String) -> void:
	stage_loaded.emit(stage_id)

func emit_building_owner_changed(building_id: int, old_owner: int, new_owner: int) -> void:
	building_owner_changed.emit(building_id, old_owner, new_owner)

func emit_population_changed(building_id: int, new_population: int) -> void:
	population_changed.emit(building_id, new_population)

func emit_troop_group_dispatched(group_id: int, owner: int, source_id: int, target_id: int, total_amount: int) -> void:
	troop_group_dispatched.emit(group_id, owner, source_id, target_id, total_amount)

func emit_fighter_arrived(fighter_id: int, target_building_id: int, owner: int, amount: int) -> void:
	fighter_arrived.emit(fighter_id, target_building_id, owner, amount)

func emit_combat_hit(building_id: int, attacker_owner: int, damage: float) -> void:
	combat_hit.emit(building_id, attacker_owner, damage)

func emit_building_captured(building_id: int, new_owner: int, previous_owner: int, remaining_troops: int) -> void:
	building_captured.emit(building_id, new_owner, previous_owner, remaining_troops)

func emit_objective_resolved(outcome: int) -> void:
	objective_resolved.emit(outcome)

func emit_settings_changed(key: String, value: Variant) -> void:
	settings_changed.emit(key, value)

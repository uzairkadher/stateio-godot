class_name OwnershipSystem
extends RefCounted
## Single-authority mutator for BuildingState.owner_id.
## All owner changes route through this system so events and telemetry stay consistent.

var event_bus: EventBus = null

func _init(p_event_bus: EventBus = null) -> void:
	event_bus = p_event_bus

func set_start_owner(building: BuildingState, owner_id: int) -> void:
	if building == null:
		return
	building.owner_id = owner_id

func change_owner_by_occupy(state: MatchState, building: BuildingState, new_owner_id: int) -> void:
	if building == null:
		return
	var prev_owner: int = building.owner_id
	if prev_owner == new_owner_id:
		return
	building.owner_id = new_owner_id
	building.is_selected = false
	building.population_accumulator = 0.0
	building.fractional_damage = 0.0
	if state != null:
		state.total_captures[new_owner_id] = int(state.total_captures.get(new_owner_id, 0)) + 1
	if event_bus != null:
		event_bus.emit_event("owner_changed", {
			"building_id": building.id,
			"previous_owner": prev_owner,
			"new_owner": new_owner_id,
			"position": building.position,
		})

func neutralize(state: MatchState, building: BuildingState) -> void:
	change_owner_by_occupy(state, building, GameEnums.OwnerId.NEUTRAL)

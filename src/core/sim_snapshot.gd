class_name SimSnapshot
extends RefCounted
## Read-only deep-copied snapshot of MatchState for Bot AI and HUD consumers.
## Guarantees AI and presentation layers cannot mutate simulation state directly.

const MatchStateScript = preload("res://src/core/match_state.gd")

var active_stage_id: String = ""
var objective_type: int = 0
var tick_index: int = 0
var elapsed_time: float = 0.0
var buildings: Dictionary = {}  # int -> Dictionary (deep copy)
var fighters: Array = []        # Array[Dictionary] (deep copy)

static func from_match_state(state: MatchStateScript) -> SimSnapshot:
	var snap := SimSnapshot.new()
	if state == null:
		return snap
	snap.active_stage_id = state.active_stage_id
	snap.objective_type = state.objective_type
	snap.tick_index = state.tick_index
	snap.elapsed_time = state.elapsed_time
	for bid in state.buildings.keys():
		var b = state.buildings[bid]
		snap.buildings[bid] = b.to_dict()
	for fid in state.fighters.keys():
		var f = state.fighters[fid]
		if f.is_alive:
			snap.fighters.append(f.to_dict())
	return snap

func get_building_copy(building_id: int) -> Dictionary:
	if not buildings.has(building_id):
		return {}
	return (buildings[building_id] as Dictionary).duplicate(true)

func get_faction_building_ids(faction: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	for bid in buildings.keys():
		if buildings[bid]["owner"] == faction:
			result.append(int(bid))
	return result
